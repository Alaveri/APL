{$I COMPILER.INC}
unit Images;

interface

uses
  AplObj,
  Errors,
  Lists,
  Common,
  AplConst,
  Drawing,
  Streams,
  Lzw,
  AplTypes,
  GraphDrv;

const
  ImageVersionMajor = 1;
  ImageVersionMinor = 0;
  ImageIdentifier: string3 = 'IMG';

type
  PImage = ^TImage;
  PImageList = ^TImageList;

  TImageCompression = (
    icNone,
    icLzw
  );

  TImageHeader = record
    Identifier: array[0..2] of byte;
    MajorVersion: byte;
    MinorVersion: byte;
    Width, Height: word;
    Compression: TImageCompression;
    Bpp: byte;
    Reserved: array[0..4] of byte;
  end;

  TImage = object(TExceptionObject)
  private
    FHeader: TImageHeader;
    procedure InitHeader;
    procedure SaveToStreamLzw(ADest: PStream);
    procedure SaveToStreamRaw(ADest: PStream);
    procedure ReadHeader(ASource: PStream; var AHeader: TImageHeader);
    procedure WriteHeader(ADest: PStream);
  public
    Buffer: PMemoryStream;
    constructor Create;
    constructor CreateSize(AWidth, AHeight: word; ABpp: byte);
    function Width: word; virtual;
    function Height: word; virtual;
    function Compression: TImageCompression; virtual;
    procedure GetImage(AX, AY, AWidth, AHeight: longint); virtual;
    procedure GetImageRect(ARect: TRect); virtual;
    procedure GetImageSection(ASourceRect, ADestRect: TRect); virtual;
    procedure DrawImage(AX, AY: longint); virtual;
    procedure DrawImageT(AX, AY: longint); virtual;
    procedure DrawImageSection(ASourceRect, ADestRect: TRect); virtual;
    procedure DrawImageSectionT(ASourceRect, ADestRect: TRect); virtual;
    procedure LoadFromStream(ASource: PStream); virtual;
    procedure SaveToStream(ADest: PStream); virtual;
    procedure LoadFromFile(AFilename: string); virtual;
    procedure SaveToFile(AFilename: string); virtual;
    procedure SetCompression(ACompression: TImageCompression); virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TImageList = object(TObjectList)
  private
  public
    function GetItem(AIndex: integer): PImage;
  end;

implementation

constructor TImage.Create;
begin
  inherited Create;
end;

constructor TImage.CreateSize(AWidth, AHeight: word; ABpp: byte);
var
  bytes: byte;
begin
  Create;
  FHeader.Bpp := ABpp;
  if ABpp <> 8 then begin
    Raise(ecImageBppNotSupported);
    exit;
  end;
  if ABpp > 1 then
    bytes := ABpp div 8;
  Buffer := New(PMemoryStream, Create(AWidth * AHeight * bytes));
  if not Assigned(Buffer) or Buffer^.HasException then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  Buffer^.Fill(Buffer^.Size, 0);
  FHeader.Width := AWidth;
  FHeader.Height := AHeight;
end;

destructor TImage.Free;
begin
  FreeAndNil(Buffer);
  inherited Free;
end;

procedure TImage.InitHeader;
begin
  FillChar(FHeader, SizeOf(FHeader), 0);
  Move(ImageIdentifier[1], FHeader.Identifier, 3);
  FHeader.MajorVersion := ImageVersionMajor;
  FHeader.MinorVersion := ImageVersionMinor;
  FHeader.Width := 0;
  FHeader.Height := 0;
  FHeader.Compression := icLzw;
  FHeader.Bpp := 8;
  Buffer := nil;
end;

procedure TImage.Init;
begin
  inherited Init;
  InitHeader;
end;

procedure TImage.GetImage(AX, AY, AWidth, AHeight: longint);
var
  bytes: byte;
begin
  if Assigned(Buffer) then begin
    if (AWidth <> FHeader.Width) or (AHeight <> FHeader.Height) then
      FreeAndNil(Buffer);
  end;
  if not Assigned(Buffer) then begin
    bytes := FHeader.Bpp div 8;
    Buffer := New(PMemoryStream, Create(AWidth * AHeight * bytes));
    if not Assigned(Buffer) or Buffer^.HasException then begin
      Raise(ecNotEnoughMemory);
      exit;
    end;
  end;
  Buffer^.Seek(0, soFromBeginning);
  Graph^.GetImageStream(AX, AY, AWidth, AHeight, Buffer);
  FHeader.Width := AWidth;
  FHeader.Height := AHeight;
end;

procedure TImage.GetImageRect(ARect: TRect);
begin
  GetImage(ARect.X, ARect.Y, ARect.Width, ARect.Height);
end;

procedure TImage.GetImageSection(ASourceRect, ADestRect: TRect);
begin
end;

procedure TImage.DrawImage(AX, AY: longint);
begin
  Buffer^.Seek(0, soFromBeginning);
  Graph^.DrawImageStream(AX, AY, FHeader.Width, FHeader.Height, Buffer);
end;

procedure TImage.DrawImageT(AX, AY: longint);
begin
  Buffer^.Seek(0, soFromBeginning);
  Graph^.DrawImageStreamT(AX, AY, FHeader.Width, FHeader.Height, Buffer);
end;

procedure TImage.DrawImageSection(ASourceRect, ADestRect: TRect);
begin
end;

procedure TImage.DrawImageSectionT(ASourceRect, ADestRect: TRect);
begin
end;

procedure TImage.LoadFromStream(ASource: PStream);
var
  header: TImageHeader;
  identifier: string3;
  bytes: byte;
  lzw: TLzw;
begin
  ReadHeader(ASource, header);
  if ASource^.HasException then begin
    Raise(ASource^.Exception^.Code);
    exit;
  end;
  Move(header.Identifier, identifier[1], 3);
  identifier[0] := #3;
  if identifier <> ImageIdentifier then begin
    Raise(ecInvalidImage);
    exit;
  end;
  if header.Bpp <> 8 then begin
    Raise(ecImageBppNotSupported);
    exit;
  end;
  if (header.MajorVersion > ImageVersionMajor)
    or ((header.MajorVersion = ImageVersionMajor)
      and (header.MinorVersion > ImageVersionMinor)) then begin
    Raise(ecImageVersionNotSupported);
    exit;
  end;
  FHeader := header;
  if FHeader.Bpp > 1 then
    bytes := FHeader.Bpp div 8;
  if Assigned(Buffer) then
    FreeAndNil(Buffer);
  Buffer := New(PMemoryStream, Create(FHeader.Width * FHeader.Height * bytes));
  if not Assigned(Buffer) or Buffer^.HasException then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  case FHeader.Compression of
    icNone: begin
      Buffer^.ReadFromStream(ASource, Buffer^.Size);
      if Buffer^.HasException then begin
        Raise(Buffer^.Exception^.Code);
        exit;
      end;
    end;
    icLzw: begin
      lzw.Create;
      lzw.DecompressStream(ASource, Buffer);
      Buffer^.Seek(0, soFromBeginning);
      if Lzw.HasException then
        Raise(Lzw.Exception^.Code);
      if ASource^.HasException then
        Raise(ASource^.Exception^.Code);
      if Buffer^.HasException then
        Raise(Buffer^.Exception^.Code);
      lzw.Free;
    end
    else begin
      Raise(ecImageCompressionNotSupported);
      exit;
    end;
  end;
end;

procedure TImage.SaveToStream(ADest: PStream);
begin
  WriteHeader(ADest);
  case FHeader.Compression of
    icNone: SaveToStreamRaw(ADest);
    icLzw: SaveToStreamLzw(ADest);
  end;
end;

procedure TImage.LoadFromFile(AFilename: string);
var
  fileStream: TFileStream;
begin
  fileStream.Create(AFilename, fmRead);
  LoadFromStream(@fileStream);
  filestream.Free;
end;

procedure TImage.ReadHeader(ASource: PStream; var AHeader: TImageHeader);
begin
  ASource^.Read(@AHeader, SizeOf(TImageHeader));
end;

procedure TImage.WriteHeader(ADest: PStream);
begin
  ADest^.Write(@FHeader, SizeOf(FHeader));
end;

procedure TImage.SaveToFile(AFilename: string);
var
  fileStream: TFileStream;
begin
  fileStream.Create(AFilename, fmWrite);
  SaveToStream(@fileStream);
  if fileStream.HasException then
    Raise(fileStream.Exception^.Code);
  if Buffer^.HasException then
    Raise(Buffer^.Exception^.Code);
  fileStream.Free;
end;

procedure TImage.SaveToStreamLzw(ADest: PStream);
var
  lzw: TLzw;
begin
  Buffer^.Seek(0, soFromBeginning);
  if ADest^.HasException then begin
    Raise(ADest^.Exception^.Code);
    exit;
  end;
  Lzw.Create;
  Lzw.CompressStream(Buffer, ADest, Buffer^.Size);
  if Lzw.HasException then
    Raise(Lzw.Exception^.Code);
  Lzw.Free;
end;

procedure TImage.SaveToStreamRaw(ADest: PStream);
begin
  Buffer^.Seek(0, soFromBeginning);
  Buffer^.WriteToStream(ADest, Buffer^.Size);
  if Buffer^.HasException then
    Raise(Buffer^.Exception^.Code);
end;

function TImage.Width: word;
begin
  Width := FHeader.Width;
end;

function TImage.Height: word;
begin
  Height := FHeader.Height;
end;

procedure TImage.SetCompression(ACompression: TImageCompression);
begin
  FHeader.Compression := ACompression;
end;

function TImage.Compression: TImageCompression;
begin
  Compression := FHeader.Compression;
end;

function TImageList.GetItem(AIndex: integer): PImage;
begin
  GetItem := PImage(inherited GetItem(AIndex));
end;

end.