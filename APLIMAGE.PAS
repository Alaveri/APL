{$I COMPILER.INC}
unit AplImage;

interface

uses
  AplTypes,
  AplConst,
  AplObj,
  Compress,
  Palettes,
  Common,
  Streams,
  Errors;

const
  AplImageIdentifier = 'APLIMG';
  AplImageExtension = 'APG';
  AplImageMajorVersion = 1;
  AplImageMinorVersion = 0;

type
  PAplImage = ^TAplImage;
  PAplImageReader = ^TAplImageReader;
  PAplImageWriter = ^TAplImageWriter;

  TAplImageCompression = (
    icNone,
    icLzw,
    icGif
  );

  TAplImageCompressionManager = object(TStatusObject)
  private
  public
    function GetCompressor(const ACompression: TAplImageCompression;
      const ALevel: TAplCompressionLevel): PCompressor;
  end;

  TAplImageHeader = record
    Identifier: array[0..5] of char;
    MajorVersion: byte;
    MinorVersion: byte;
    Width: word;
    Height: word;
    Bpp: byte;
    Compression: TAplImageCompression;
    CompressionLevel: TAplCompressionLevel;
    BitPlanes: byte;
    BlockSize: word;
    ImageCount: word;
    HasPalette: boolean;
    ExtendedData: boolean;
  end;

  TAplImageReader = object(TStatusObject)
  private
    FStream: PStream;
    FCompressor: PCompressor;
  public
    constructor Create(const AStream: PStream; ACompressor: PCompressor);
    procedure Init; virtual;
    procedure ReadHeader(var AHeader: TAplImageHeader); virtual;
    procedure SetCompressionLevel(ALevel: TAplCompressionLevel); virtual;
    function ReadPalette: PRgbPalette; virtual;
    function ReadImageData: PMemoryStream; virtual;
    destructor Free; virtual;
  end;

  TAplImageWriter = object(TStatusObject)
  private
    FStream: PStream;
    FCompressor: PCompressor;
  public
    constructor Create(const AStream: PStream; ACompressor: PCompressor);
    procedure WriteHeader(const AHeader: TAplImageHeader); virtual;
    procedure WritePalette(const APalette: PRgbPalette); virtual;
    procedure WriteImageData(AImageData: PMemoryStream); virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TAplImage = object(TStatusObject)
  private
    FReader: PAplImageReader;
    FWriter: PAplImageWriter;
    FBuffers: PMemoryStreamList;
    FWidth: integer;
    FHeight: integer;
    FSize: integer;
    FBpp: byte;
    FBitPlanes: byte;
    FFreeBuffers: boolean;
    FPalette: PRgbPalette;
    FBlockSize: word;
    FCompression: TAplImageCompression;
    FCompressionLevel: TAplCompressionLevel;
  public
    constructor CreateSize(const AWidth, AHeight: integer);
    constructor CreateSizeBpp(const AWidth, AHeight: integer; ABpp: byte);
    constructor CreateSizeBppPlanes(const AWidth, AHeight: integer; ABpp, APlanes: byte);
    constructor CreateStream(const AStream: PStream);
    constructor CreateFile(const AFileName: string);
    constructor CreateBuffer(const ABuffer: pointer; const AWidth, AHeight: integer; ABpp, APlanes: byte);
    function Palette: PRgbPalette;
    function Buffer: PMemoryStream;
    function Buffers: PMemoryStreamList;
    function BufferAt(const AIndex: integer): PMemoryStream;
    function PixelPtr(const AX, AY: integer): PByte;
    function PixelPtrAt(const AIndex, AX, AY: integer): PByte;
    function Compression: TAplImageCompression;
    function CompressionLevel: TAplCompressionLevel;
    procedure SetCompression(const ACompression: TAplImageCompression; const ALevel: TAplCompressionLevel);
    procedure GetHeader(var AHeader: TAplImageHeader); virtual;
    procedure SetHeader(const AHeader: TAplImageHeader); virtual;
    procedure LoadFromStream(const AStream: PStream); virtual;
    procedure LoadFromFile(const AFileName: string); virtual;
    procedure SaveToStream(const AStream: PStream); virtual;
    procedure SaveToFile(const AFileName: string); virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

var
  AplImageCompressionManager: TAplImageCompressionManager;

implementation

uses
  Lzw;

procedure TAplImage.Init;
begin
  inherited Init;
  FReader := nil;
  FWriter := nil;
  FBuffers := New(PMemoryStreamList, Create);
  FWidth := 0;
  FHeight := 0;
  FBpp := 8;
  FSize := 0;
  FBitPlanes := 1;
  FPalette := nil;
  FFreeBuffers := true;
  FCompression := icLzw;
  FCompressionLevel := clHigh;
  FBlockSize := 0;
end;

destructor TAplImage.Free;
begin
  if FFreeBuffers and Assigned(FBuffers) then
    FreeAndNil(FBuffers);
  if Assigned(FReader) then
    FreeAndNil(FReader);
  if Assigned(FWriter) then
    FreeAndNil(FWriter);
  inherited Free;
end;

constructor TAplImage.CreateSize(const AWidth, AHeight: integer);
begin
  CreateSizeBpp(AWidth, AHeight, 8);
end;

constructor TAplImage.CreateSizeBpp(const AWidth, AHeight: integer; ABpp: Byte);
begin
  CreateSizeBppPlanes(AWidth, AHeight, ABpp, 1);
end;

constructor TAplImage.CreateSizeBppPlanes(const AWidth, AHeight: integer; ABpp, APlanes: Byte);
begin
  inherited Create;
  FBpp := ABpp;
  FBitPlanes := APlanes;
  FWidth := AWidth;
  FHeight := AHeight;
  FSize := FWidth * FHeight * FBpp;
  FBuffers^.Add(New(PMemoryStream, Create(FSize)));
end;

constructor TAplImage.CreateBuffer(const ABuffer: pointer; const AWidth, AHeight: integer; ABpp, APlanes: Byte);
begin
  CreateSizeBppPlanes(AWidth, AHeight, ABpp, APlanes);
  FBuffers^.Add(New(PMemoryStream, CreateBuffer(ABuffer, FSize)));
end;

function TAplImage.PixelPtrAt(const AIndex, AX, AY: integer): PByte;
var
  result: PByte;
begin
  result := FBuffers^.Items^[AIndex];
  if FBitPlanes = 1 then
    Inc(result, (AY * FWidth + AX) * FBpp)
  else
    Inc(result, (AY div FBitPlanes * FWidth + AX mod FBitPlanes) * FBpp);
  PixelPtrAt := result;
end;

function TAplImage.PixelPtr(const AX, AY: integer): PByte;
begin
  PixelPtr := PixelPtrAt(0, AX, AY);
end;

function TAplImage.Buffers: PMemoryStreamList;
begin
  Buffers := FBuffers;
end;

function TAplImage.BufferAt(const AIndex: integer): PMemoryStream;
begin
  BufferAt := FBuffers^.Items^[AIndex];
end;

function TAplImage.Buffer: PMemoryStream;
begin
  Buffer := BufferAt(0);
end;

constructor TAplImage.CreateStream(const AStream: PStream);
begin
  inherited Create;
  LoadFromStream(AStream);
end;

constructor TAplImage.CreateFile(const AFileName: string);
begin
  inherited Create;
  LoadFromFile(AFileName);
end;

procedure TAplImage.LoadFromStream(const AStream: PStream);
var
  header: TAplImageHeader;
  image: PMemoryStream;
  compressor: PCompressor;
  index: integer;
begin
  if not Assigned(FReader) then begin
    compressor := AplImageCompressionManager.GetCompressor(FCompression, FCompressionLevel);
    if IsNilPtr(compressor, ecNotEnoughMemory) then
      exit;
    FReader := New(PAplImageReader, Create(AStream, compressor));
    if IsNilPtr(FReader, ecNotEnoughMemory) then
      exit;
  end;
  FreeAndNil(FPalette);
  FreeAndNil(FBuffers);
  FReader^.ReadHeader(header);
  if CheckReraise(FReader) then
    exit;
  if header.Identifier <> AplImageIdentifier then begin
    Raise(ecInvalidImage);
    exit;
  end;
  if (header.MajorVersion > AplImageMajorVersion) or
    ((header.MajorVersion = AplImageMajorVersion) and (header.MinorVersion > AplImageMinorVersion)) then begin
    Raise(ecImageVersionNotSupported);
    exit;
  end;
  FReader^.SetCompressionLevel(FCompressionLevel);
  SetHeader(header);
  if header.HasPalette then
    FPalette := FReader^.ReadPalette;
  for index := 0 to header.ImageCount - 1 do begin
    image := FReader^.ReadImageData;
    if CheckReraise(image) then
      exit;
    FBuffers^.Add(image);
  end;
end;

procedure TAplImage.LoadFromFile(const AFileName: string);
var
  stream: PStream;
begin
  stream := New(PFileStream, Create(AFileName, fmRead));
  if IsNilPtr(stream, ecNotEnoughMemory) then
    exit;
  LoadFromStream(stream);
  CheckReraise(stream);
  FreeAndNil(stream);
end;

procedure TAplImage.SaveToStream(const AStream: PStream);
var
  index: integer;
  header: TAplImageHeader;
  compressor: PCompressor;
begin
  if not Assigned(FWriter) then begin
    compressor := AplImageCompressionManager.GetCompressor(FCompression, FCompressionLevel);
    if IsNilPtr(compressor, ecNotEnoughMemory) then
      exit;
    FWriter := New(PAplImageWriter, Create(AStream, compressor));
    if IsNilPtr(FWriter, ecNotEnoughMemory) then
      exit;
  end;

  GetHeader(header);
  FWriter^.WriteHeader(header);
  if header.HasPalette then
    FWriter^.WritePalette(FPalette);
  for index := 0 to FBuffers^.Count - 1 do
    FWriter^.WriteImageData(FBuffers^.Items^[index]);
  if FWriter^.HasException then
    Raise(FWriter^.Exception^.Code);
end;

procedure TAplImage.SaveToFile(const AFileName: string);
var
  stream: PStream;
begin
  stream := New(PFileStream, Create(AFileName, fmWrite));
  if stream^.HasException then
    Raise(stream^.Exception^.Code);
  SaveToStream(stream);
  CheckReraise(stream);
  FreeAndNil(stream);
end;

procedure TAplImage.SetCompression(const ACompression: TAplImageCompression; const ALevel: TAplCompressionLevel);
begin
  FCompression := ACompression;
  FCompressionLevel := ALevel;
end;

function TAplImage.Compression: TAplImageCompression;
begin
  Compression := FCompression;
end;

function TAplImage.CompressionLevel: TAplCompressionLevel;
begin
  CompressionLevel := FCompressionLevel;
end;

procedure TAplImage.GetHeader(var AHeader: TAplImageHeader);
begin
  AHeader.Identifier := AplImageIdentifier;
  AHeader.MajorVersion := AplImageMajorVersion;
  AHeader.MinorVersion := AplImageMinorVersion;
  AHeader.Width := FWidth;
  AHeader.Height := FHeight;
  AHeader.Bpp := FBpp;
  AHeader.Compression := FCompression;
  AHeader.CompressionLevel := FCompressionLevel;
  AHeader.BitPlanes := FBitPlanes;
  AHeader.BlockSize := 0;
  AHeader.ImageCount := FBuffers^.Count;
  AHeader.HasPalette := Assigned(FPalette);
  AHeader.ExtendedData := false;
end;

procedure TAplImage.SetHeader(const AHeader: TAplImageHeader);
begin
  FWidth := AHeader.Width;
  FHeight := AHeader.Height;
  FBpp := AHeader.Bpp;
  FBitPlanes := AHeader.BitPlanes;
  FSize := FWidth * FHeight * FBpp;
  FBlockSize := AHeader.BlockSize;
  FCompression := AHeader.Compression;
  FCompressionLevel := AHeader.CompressionLevel;
end;

function TAplImage.Palette: PRgbPalette;
begin
  Palette := FPalette;
end;

constructor TAplImageReader.Create(const AStream: PStream; ACompressor: PCompressor);
begin
  inherited Create;
  FStream := AStream;
  FCompressor := ACompressor;
end;

procedure TAplImageReader.Init;
begin
  inherited Init;
  FStream := nil;
  FCompressor := nil;
end;

destructor TAplImageReader.Free;
begin
  inherited Free;
end;

procedure TAplImageReader.ReadHeader(var AHeader: TAplImageHeader);
begin
  if HasException then
    exit;
end;

function TAplImageReader.ReadPalette: PRgbPalette;
begin
  ReadPalette := nil;
  if HasException then
    exit;
end;

procedure TAplImageReader.SetCompressionLevel(ALevel: TAplCompressionLevel);
begin
  FCompressor^.SetCompressionLevel(ALevel);
end;

function TAplImageReader.ReadImageData: PMemoryStream;
var
  size: longint;
  result: PMemoryStream;
begin
  ReadImageData := nil;
  if HasException then
    exit;
  if not Assigned(FCompressor) then begin
    Raise(ecCompressorNotSpecified);
    exit;
  end;
  size := FStream^.ReadLong;
  result := New(PMemoryStream, Create(size));
  if IsNilPtr(result, ecNotEnoughMemory) then
    exit;
  if Assigned(FCompressor) then
    FCompressor^.DecompressStream(FStream, result, size)
  else
    result^.ReadFromStream(FStream, size);
  ReadImageData := result;
end;

procedure TAplImageWriter.Init;
begin
  inherited Init;
  FStream := nil;
  FCompressor := nil;
end;

constructor TAplImageWriter.Create(const AStream: PStream; ACompressor: PCompressor);
begin
  inherited Create;
  FStream := AStream;
  FCompressor := ACompressor;
end;

procedure TAplImageWriter.WriteHeader(const AHeader: TAplImageHeader);
begin
  if HasException then
    exit;
  FStream^.Write(@AHeader, SizeOf(AHeader));
end;

procedure TAplImageWriter.WritePalette(const APalette: PRgbPalette);
var
  writer: TAplPaletteWriter;
begin
  if HasException then
    exit;
  writer.Create(FStream);
  writer.WritePalette(APalette^.Colors);
  if writer.HasException then
    Raise(writer.Exception^.Code);
  writer.Free;
end;

procedure TAplImageWriter.WriteImageData(AImageData: PMemoryStream);
var
  index: integer;
  size: longint;
begin
  if HasException then
    exit;
  if not Assigned(FCompressor) then begin
    Raise(ecCompressorNotSpecified);
    exit;
  end;
  if not Assigned(AImageData) then begin
    Raise(ecInvalidImage);
    exit;
  end;
  AImageData^.Seek(0, soFromBeginning);
  size := AImageData^.Size;
  FStream^.Write(@size, SizeOf(size));
  if Assigned(FCompressor) then
    size := FCompressor^.CompressStream(AImageData, FStream, AImageData^.Size)
  else
    AImageData^.WriteToStream(FStream, AImageData^.Size);
end;

destructor TAplImageWriter.Free;
begin
  inherited Free;
end;

function TAplImageCompressionManager.GetCompressor(const ACompression: TAplImageCompression;
  const ALevel: TAplCompressionLevel): PCompressor;
var
  result: PCompressor;
  bitSize: byte;
begin
  case ACompression of
    icNone:
      result := New(PNonCompressor, Create);
    icLzw: begin
      bitSize := LzwCompressionBitSize[ALevel];
      result := New(PLzw, CreateBitSize(bitSize));
      PLzw(result)^.SetLzwCodesProc := @SetAplLzwCodes;
      result^.AddTotalToStream := false;
    end;
    icGif: begin
      result := New(PLzw, CreateBitSize(13));
      PLzw(result)^.SetLzwCodesProc := @SetGifLzwCodes;
      result^.AddTotalToStream := false;
    end;
    else
      result := nil;
  end;
  GetCompressor := result;
end;

begin
  AplImageCompressionManager.Create;
end.