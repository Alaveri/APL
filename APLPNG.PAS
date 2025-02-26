{$I COMPILER.INC}
unit AplPng;

interface

uses
  AplConst,
  AplObj,
  AplImage,
  AplStr,
  AplTypes,
  AplUtils,
  AplCrc,
  Lists,
  Streams,
  Strings,
  ZInflate;

type
  PPngManager = ^TPngManager;
  PPngChunkList = ^TPngChunkList;
  PPngChunk = ^TPngChunk;

  TPngChunkTypeArray = array[0..3] of char;
  TPngSignature = array[0..7] of byte;
  TPngBitDepths = set of byte;

  TPngColorType = (
    ctGrayscale,
    ctRgb,
    ctPalette,
    ctGrayscaleAlpha,
    ctRgba
  );

  TPngCompressionMethod = (
    Deflate
  );

  TPngFilterMethod = (
    Adaptive
  );

  TPngInterlaceMethod = (
    None,
    Adam7
  );

  TPngChunk = object(TObject)
  private
  public
    Length: longint;
    ChunkType: TPngChunkTypeArray;
    Data: PMemoryStream;
    Crc: longint;
    constructor Create(AChunkType: TPngChunkTypeArray; ALength: longint);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TPngRgbColor = record
    Red: byte;
    Green: byte;
    Blue: byte;
  end;

  TPngHeader = record
    Width: longint;
    Height: longint;
    BitDepth: byte;
    ColorType: TPngColorType;
    CompressionMethod: TPngCompressionMethod;
    FilterMethod: TPngFilterMethod;
    InterlaceMethod: TPngInterlaceMethod;
  end;

  TPngManager = object(TStatusObject)
  private
    FChunkList: PPngChunkList;
    FDataSize: longint;
    FWidth, FHeight, FBpp: word;
    function BitsPerPixel(AColorType: TPngColorType; ABitDepth: byte): byte;
    function ReadHeader(AStream: PStream; var AHeader: TPngHeader): boolean;
    function ReadChunks(AStream: PStream): boolean;
    function ProcessChunk(AChunk: PPngChunk): boolean;
    function ProcessHeaderChunk(AChunk: PPngChunk): boolean;
    function ProcessPaletteChunk(AChunk: PPngChunk): boolean;
    function ProcessDataChunk(AChunk: PPngChunk): boolean;
    function ProcessChunks: boolean;
  public
    constructor Create;
    destructor Free; virtual;
    procedure Init; virtual;
    function ImportPngFile(const AFilename: string): PAplImage;
    function ImportPngStream(AStream: PStream): PAplImage;
    function TryImportPngFile(const AFilename: string; var AImage: PAplImage): boolean;
    function TryImportPngStream(AStream: PStream; var AImage: PAplImage): boolean;
  end;

  TPngChunkList = object(TObjectList)
  private
  public
    function Add(AItem: PPngChunk): integer;
    function GetItem(AIndex: integer): PPngChunk;
    function IndexOf(AItem: PPngChunk): integer;
    procedure SetItem(AIndex: integer; AItem: PPngChunk);
    procedure Insert(AIndex: integer; AItem: PPngChunk);
    procedure RemoveItem(AItem: PPngChunk);
  end;

const
  PngSignature: TPngSignature = (137, 80, 78, 71, 13, 10, 26, 10);
  EndChunk: TPngChunkTypeArray = 'IEND';
  HeaderChunk: TPngChunkTypeArray = 'IHDR';
  PaletteChunk: TPngChunkTypeArray = 'PLTE';
  DataChunk: TPngChunkTypeArray = 'IDAT';
  TransparencyChunk: TPngChunkTypeArray = 'tRNS';
  ChromaticityChunk: TPngChunkTypeArray = 'cHRM';
  GammaChunk: TPngChunkTypeArray = 'gAMA';
  IccProfileChunk: TPngChunkTypeArray = 'iCCP';
  SignificantBitsChunk: TPngChunkTypeArray = 'sBIT';
  StandardRgbColorSpaceChunk: TPngChunkTypeArray = 'sRGB';
  BackgroundChunk: TPngChunkTypeArray = 'bKGD';
  HistogramChunk: TPngChunkTypeArray = 'hIST';
  TextChunk: TPngChunkTypeArray = 'tEXt';
  CompressedTextChunk: TPngChunkTypeArray = 'zTXt';
  TimeChunk: TPngChunkTypeArray = 'tIME';
  PhysicalPixelDimensionsChunk: TPngChunkTypeArray = 'pHYs';
  SuggestedPaletteChunk: TPngChunkTypeArray = 'sPLT';
  InternationalTextChunk: TPngChunkTypeArray = 'iTXt';

  AllowedBitDepths: array[TPngColorType] of TPngBitDepths = (
    [1, 2, 4, 8, 16],
    [8, 16],
    [1, 2, 4, 8],
    [8, 16],
    [8, 16]
  );

var
  PngManager: TPngManager;

implementation

constructor TPngManager.Create;
begin
  inherited Create;
end;

destructor TPngManager.Free;
begin
  FChunkList^.Clear;
  FreeAndNil(FChunkList);
  inherited Free;
end;

procedure TPngManager.Init;
begin
  inherited Init;
  FChunkList := New(PPngChunkList, Create);
  FDataSize := 0;
  FWidth := 0;
  FHeight := 0;
  FBpp := 0;
end;

function TPngManager.BitsPerPixel(AColorType: TPngColorType; ABitDepth: byte): byte;
begin
  case AColorType of
    ctGrayscale: BitsPerPixel := ABitDepth;
    ctRgb: BitsPerPixel := 3 * ABitDepth;
    ctPalette: BitsPerPixel := ABitDepth;
    ctGrayscaleAlpha: BitsPerPixel := 2 * ABitDepth;
    ctRgba: BitsPerPixel := 4 * ABitDepth;
    else BitsPerPixel := 0;
  end;
end;

function TPngManager.ProcessHeaderChunk(AChunk: PPngChunk): boolean;
begin
end;

function TPngManager.ProcessPaletteChunk(AChunk: PPngChunk): boolean;
begin
end;

function TPngManager.ProcessDataChunk(AChunk: PPngChunk): boolean;
begin
  FDataSize := AChunk^.Length;
end;

function TPngManager.ProcessChunk(AChunk: PPngChunk): boolean;
begin
  ProcessChunk := false;
  if Equal(AChunk^.ChunkType, HeaderChunk, SizeOf(TPngChunkTypeArray)) then
    ProcessChunk := ProcessHeaderChunk(AChunk)
  else if Equal(AChunk^.ChunkType, PaletteChunk, SizeOf(TPngChunkTypeArray)) then
    ProcessChunk := ProcessPaletteChunk(AChunk)
  else if Equal(AChunk^.ChunkType, DataChunk, SizeOf(TPngChunkTypeArray)) then
    ProcessChunk := ProcessDataChunk(AChunk);
end;

function TPngManager.ProcessChunks: boolean;
var
  index: integer;
  chunk: PPngChunk;
  useStream: boolean;
begin
  ProcessChunks := false;
  if FChunkList^.Count = 0 then begin
    Raise(ecPngNoChunks);
    exit;
  end;
  chunk := FChunkList^.GetItem(0);
  if not Equal(chunk^.ChunkType, HeaderChunk, SizeOf(TPngChunkTypeArray)) then begin
    Raise(ecPngNoHeaderChunk);
    exit;
  end;
  for index := 0 to FChunkList^.Count - 1 do begin
    chunk := FChunkList^.GetItem(index);
    if not ProcessChunk(chunk) then
      exit;
  end;
  ProcessChunks := true;
end;

function TPngManager.ImportPngFile(const AFilename: string): PAplImage;
var
  stream: PFileStream;
begin
  ImportPngFile := nil;
  if not FileExists(AFilename) then begin
    Raise(ecFileNotFound);
    exit;
  end;
  stream := New(PFileStream, Create(AFileName, fmRead));
  if not CheckReRaise(stream) then
    ImportPngFile := ImportPngStream(stream);
  CheckReRaise(stream);
  FreeAndNil(stream);
end;

function TPngManager.ReadChunks(AStream: PStream): boolean;
var
  chunk: PPngChunk;
  chunkType: TPngChunkTypeArray;
  anyDataChunks, anyPaletteChunks: boolean;
  index: integer;
  length: longint;
  crc: TCrc;
begin
  ReadChunks := false;
  FChunkList^.Clear;
  while true do begin
    length := AStream^.ReadLong;
    AStream^.Read(@chunkType, SizeOf(TPngChunkTypeArray));
    if CheckReRaise(AStream) then
      exit;
    chunk := New(PPngChunk, Create(chunkType, length));
    if NilPtr(chunk, ecNotEnoughMemory) then
      exit;
    if NilPtr(chunk^.Data, ecNotEnoughMemory) then begin
      FreeAndNil(chunk);
      exit;
    end;
    chunk^.Data^.ReadFromStream(AStream, length);
    chunk^.Data^.Seek(0, soFromBeginning);

    InitCrc(crc);
    UpdateCrc(crc, length, SizeOf(longint));
    UpdateCrc(crc, chunkType, SizeOf(TPngChunkTypeArray));
    UpdateCrcStream(crc, chunk^.Data, length);
    crc := FinalizeCrc(crc);

    chunk^.Data^.Seek(0, soFromBeginning);
    if CheckReRaise(AStream) then begin
      FreeAndNil(chunk);
      exit;
    end;
    chunk^.Crc := AStream^.ReadLong;
    if CheckReRaise(AStream) then begin
      FreeAndNil(chunk);
      exit;
    end;
    if chunk^.Crc <> crc then begin
      Raise(ecPngCrcError);
      FreeAndNil(chunk);
      exit;
    end;
    FChunkList^.Add(chunk);
    if Equal(chunkType, EndChunk, SizeOf(TPngChunkTypeArray)) then
      break;
  end;
  anyDataChunks := false;
  anyPaletteChunks := false;
  for index := 0 to FChunkList^.Count - 1 do begin
    chunk := FChunkList^.GetItem(index);
    if Equal(chunk^.ChunkType, DataChunk, SizeOf(TPngChunkTypeArray)) then
      anyDataChunks := true;
    if Equal(chunk^.ChunkType, PaletteChunk, SizeOf(TPngChunkTypeArray)) then
      anyPaletteChunks := true;
  end;
  if not anyDataChunks then begin
    Raise(ecPngNoDataChunks);
    exit;
  end;
  if not anyPaletteChunks then begin
    Raise(ecPngNoPaletteChunks);
    exit;
  end;
  ReadChunks := true;
end;

function TPngManager.ReadHeader(AStream: PStream; var AHeader: TPngHeader): boolean;
var
  signature: TPngSignature;
begin
  ReadHeader := false;
  FillChar(AHeader, SizeOf(AHeader), 0);
  AStream^.Read(@signature, SizeOf(signature));
  if CheckReRaise(AStream) then
    exit;
  if Equal(signature, PngSignature, SizeOf(TPngSignature)) then begin
    Raise(ecInvalidPngSignature);
    exit;
  end;
  AStream^.Read(@AHeader, SizeOf(AHeader));
  if CheckReRaise(AStream) then
    exit;
  if not (AHeader.BitDepth in AllowedBitDepths[AHeader.ColorType]) then begin
    Raise(ecInvalidPngBitDepth);
    exit;
  end;
  ReadHeader := true;
end;

function TPngManager.ImportPngStream(AStream: PStream): PAplImage;
var
  header: TPngHeader;
  result: boolean;
  image: PAplImage;
begin
  ImportPngStream := nil;
  FDataSize := 0;
  FWidth := 0;
  FHeight := 0;
  if not ReadHeader(AStream, header) then
    exit;
  if not ReadChunks(AStream) then
    exit;
  result := ProcessChunks;
  if not Result then
    exit;
  if FWidth * FHeight * FBpp > MaxVarSize then
    image := New(PAplStreamImage, CreateDimsBpp(FWidth, FHeight, FBpp))
  else
    image := New(PAplBufferImage, CreateDimsBpp(FWidth, FHeight, FBpp));
end;

function TPngManager.TryImportPngFile(const AFilename: string; var AImage: PAplImage): boolean;
begin
  TryImportPngFile := true;
  AImage := ImportPngFile(AFilename);
  if HasException then begin
    TryImportPngFile := false;
    AImage := nil;
    ClearException;
  end;
end;

function TPngManager.TryImportPngStream(AStream: PStream; var AImage: PAplImage): boolean;
begin
  TryImportPngStream := true;
  AImage := ImportPngStream(AStream);
  if HasException then begin
    TryImportPngStream := false;
    AImage := nil;
    ClearException;
  end;
end;

function TPngChunkList.Add(AItem: PPngChunk): integer;
begin
  Add := inherited Add(AItem);
end;

function TPngChunkList.GetItem(AIndex: integer): PPngChunk;
begin
  GetItem := PPngChunk(inherited GetItem(AIndex));
end;

function TPngChunkList.IndexOf(AItem: PPngChunk): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TPngChunkList.SetItem(AIndex: integer; AItem: PPngChunk);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TPngChunkList.Insert(AIndex: integer; AItem: PPngChunk);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TPngChunkList.RemoveItem(AItem: PPngChunk);
begin
  inherited RemoveItem(AItem);
end;

constructor TPngChunk.Create(AChunkType: TPngChunkTypeArray; ALength: longint);
begin
  inherited Create;
  Length := ALength;
  ChunkType := AChunkType;
  Data := New(PMemoryStream, Create(ALength));
end;

procedure TPngChunk.Init;
begin
  inherited Init;
  Data := nil;
  Length := 0;
  FillChar(ChunkType, SizeOf(ChunkType), 0);
  Crc := 0;
end;

destructor TPngChunk.Free;
begin
  FreeAndNil(Data);
  inherited Free;
end;

var
  PreviousExitProc: PProc;

procedure Finalize;
begin
  ExitProc := PreviousExitProc;
  PngManager.Free;
end;

begin
  PreviousExitProc := ExitProc;
  PngManager.Create;
  ExitProc := @Finalize;
end.
