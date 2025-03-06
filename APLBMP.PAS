{$I COMPILER.INC}
unit AplBmp;

interface

uses
  AplConst,
  AplObj,
  AplStr,
  AplTypes,
  AplImage,
  AplUtils,
  Palettes,
  Streams,
  Lists,
  Strings;

type
  TBmpIdentifier = array[0..1] of byte;

const
  BmpIdentifier: TBmpIdentifier = ($42, $4D);

type
  PBmpManager = ^TBmpManager;
  PBmpFileHeader = ^TBmpFileHeader;
  PBmpV5Header = ^TBmpV5Header;

  TBmpFileHeader = record
    Identifier: TBmpIdentifier;
    FileSize: longint;
    Reserved: longint;
    DataOffset: longint;
  end;

  TBmpV5Header = record
    Width: longint;
    Height: longint;
    Planes: word;
    BitsPerPixel: word;
    Compression: longint;
    ImageSize: longint;
    XResolution: longint;
    YResolution: longint;
    ColorsUsed: longint;
    ImportantColors: longint;
    RedMask: longint;
    GreenMask: longint;
    BlueMask: longint;
    AlphaMask: longint;
    CsType: longint;
    Endpoints: array[0..8] of longint;
    GammaRed: longint;
    GammaGreen: longint;
    GammaBlue: longint;
    Intent: longint;
    ProfileData: longint;
    ProfileSize: longint;
    Reserved: longint;
  end;

  TBmpRgba = record
    Blue: byte;
    Green: byte;
    Red: byte;
    Alpha: byte;
  end;

  TBmpManager = object(TStatusObject)
  private
    function ReadPalette(AStream: PStream; AColorsUsed: longint): PRgbPalette;
    function ReadPixels(AStream: PStream; const AHeader: TBmpV5Header; AImage: PAplStreamImage): boolean;
  public
    constructor Create;
    destructor Free; virtual;
    procedure Init; virtual;
    function ImportBmpFile(const AFilename: string): PAplImage;
    function ImportBmpStream(AStream: PStream): PAplImage;
    function TryImportBmpFile(const AFilename: string; var AImage: PAplImage): boolean;
    function TryImportBmpStream(AStream: PStream; var AImage: PAplImage): boolean;
  end;

var
  TBmp: TBmpManager;

implementation

constructor TBmpManager.Create;
begin
  inherited Create;
end;

destructor TBmpManager.Free;
begin
  inherited Free;
end;

procedure TBmpManager.Init;
begin
  inherited Init;
end;

function TBmpManager.ImportBmpFile(const AFilename: string): PAplImage;
var
  stream: TFileStream;
begin
  stream.Create(AFilename, fmRead);
  ImportBmpFile := ImportBmpStream(@stream);
  stream.Free;
end;

function TBmpManager.ReadPalette(AStream: PStream; AColorsUsed: longint): PRgbPalette;
var
  index: integer;
  result: PRgbPalette;
  color: TBmpRgba;
  rgbColor: TRgbColor;
begin
  result := New(PRgbPalette, Create(pfApl));
  result^.SetCount(AColorsUsed);
  for index := 0 to AColorsUsed - 1 do begin
    AStream^.Read(@color, sizeof(TBmpRgba));
    rgbColor.Red := color.Red;
    rgbColor.Green := color.Green;
    rgbColor.Blue := color.Blue;
    result^.SetColor(index, rgbColor);
    if CheckReraise(AStream) then begin
      FreeAndNil(result);
      exit;
    end;
  end;
  ReadPalette := result;
end;

function TBmpManager.ReadPixels(AStream: PStream; const AHeader: TBmpV5Header; AImage: PAplStreamImage): boolean;
var
  index: longint;
  color: byte;
  rowSize: longint;
  rowData: PByte;
begin
  ReadPixels := true;
  rowSize := (AHeader.BitsPerPixel * AHeader.Width div 8 + 3) and $FFFFFFFC;
  GetMem(rowData, rowSize);
  if NilPtr(rowData, ecNotEnoughMemory) then begin
    ReadPixels := false;
    exit;
  end;
  for index := AHeader.Height - 1 downto 0 do begin
    AStream^.Read(rowData, rowSize);
    if CheckReraise(AStream) then begin
      FreeMem(rowData, rowSize);
      ReadPixels := false;
      exit;
    end;
    AImage^.Buffer^.Seek(index * AHeader.Width * AHeader.BitsPerPixel div 8, soFromBeginning);
    AImage^.Buffer^.Write(rowData, AHeader.Width * AHeader.BitsPerPixel div 8);
  end;
  AImage^.Buffer^.Seek(0, soFromBeginning);
  FreeMem(rowData, rowSize);
end;

function TBmpManager.ImportBmpStream(AStream: PStream): PAplImage;
var
  fileHeader: TBmpFileHeader;
  header: TBmpV5Header;
  headerSize: longint;
  result: PAplStreamImage;
  start: longint;
begin
  ImportBmpStream := nil;
  start := AStream^.Position;
  AStream^.Read(@fileHeader, sizeof(TBmpFileHeader));
  if CheckReraise(AStream) then exit;
  if not Equal(fileHeader.Identifier, BmpIdentifier, sizeof(TBmpIdentifier)) then begin
    Raise(ecInvalidBmpSignature);
    exit;
  end;
  headerSize := AStream^.ReadLong;
  if CheckReraise(AStream) then exit;
  FillChar(header, sizeof(TBmpV5Header), 0);
  AStream^.Read(@header, headerSize - SizeOf(longint));
  if CheckReraise(AStream) then begin
    exit;
  end;
  if headerSize >= 40 then begin
    if header.Compression <> 0 then begin
      Raise(ecUnsupportedBmpCompression);
      exit;
    end;
  end;
  if (start + fileHeader.DataOffset + header.ImageSize > AStream^.Size) then begin
    Raise(ecInvalidBmpSize);
    exit;
  end;
  result := New(PAplStreamImage, CreateDimsBpp(header.Width, header.Height, header.BitsPerPixel));
  if NilPtr(result, ecNotEnoughMemory) then
    exit;
  if header.BitsPerPixel <= 8 then begin
    result^.SetPalette(ReadPalette(AStream, header.ColorsUsed));
    if result^.Palette = nil then begin
      FreeAndNil(result);
      exit;
    end;
  end;
  AStream^.Seek(start + fileHeader.DataOffset, soFromBeginning);
  if not ReadPixels(AStream, header, result) then
    FreeAndNil(result);
  ImportBmpStream := result;
end;

function TBmpManager.TryImportBmpFile(const AFilename: string; var AImage: PAplImage): boolean;
begin
  TryImportBmpFile := true;
  AImage := ImportBmpFile(AFilename);
  CheckReraise(AImage);
  if HasException then begin
    FreeAndNil(AImage);
    ClearException;
    TryImportBmpFile := false;
  end;
end;

function TBmpManager.TryImportBmpStream(AStream: PStream; var AImage: PAplImage): boolean;
begin
  TryImportBmpStream   := true;
  AImage := ImportBmpStream(AStream);
  CheckReraise(AImage);
  if HasException then begin
    FreeAndNil(AImage);
    ClearException;
    TryImportBmpStream := false;
  end;
end;

var
  PreviousExitProc: PProc;

procedure Finalize;
begin
  ExitProc := PreviousExitProc;
  TBmp.Free;
end;

begin
  PreviousExitProc := ExitProc;
  TBmp.Create;
  ExitProc := @Finalize;
end.
