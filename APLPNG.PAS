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
  ZLib,
  Compress,
  Lists,
  Palettes,
  Streams,
  Strings;

type
  PPngManager = ^TPngManager;
  PPngChunkList = ^TPngChunkList;
  PPngChunk = ^TPngChunk;
  PPngHeader = ^TPngHeader;
  PPngRgbColor = ^TPngRgbColor;

  TPngChunkTypeArray = array[0..3] of char;
  TPngSignature = array[0..7] of byte;
  TPngBitDepths = set of byte;

  TPngColorType = (
    ctNone,
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
    FBufferPtr: PByte;
    function ReadAndCheckSignature(AStream: PStream): boolean;
    function BitsPerPixel(AColorType: TPngColorType; ABitDepth: byte): byte;
    function ReadChunks(AStream: PStream): boolean;
    function ProcessChunk(AChunk: PPngChunk; AImage: PAplImage): boolean;
    function ProcessHeaderChunk(AChunk: PPngChunk): PAplImage;
    function ProcessPaletteChunk(AChunk: PPngChunk; AImage: PAplImage): boolean;
    function ProcessChunks: PAplImage;
    procedure ProcessDataChunks(AImage: PAplImage);
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
    [],
    [1, 2, 4, 8, 16],
    [8, 16],
    [1, 2, 4, 8],
    [8, 16],
    [8, 16]
  );

var
  TPng: TPngManager;

implementation

constructor TPngManager.Create;
begin
  inherited Create;
  FBufferPtr := nil;
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

function TPngManager.ProcessHeaderChunk(AChunk: PPngChunk): PAplImage;
var
  header: TPngHeader;
  result: PAplImage;
  bpp: byte;
begin
  AChunk^.Data^.Seek(0, soFromBeginning);
  AChunk^.Data^.Read(@header, SizeOf(header));
  header.Width := ReverseEndian(header.Width);
  header.Height := ReverseEndian(header.Height);
  if not (header.BitDepth in AllowedBitDepths[header.ColorType]) then begin
    Raise(ecInvalidPngBitDepth);
    exit;
  end;
  bpp := BitsPerPixel(header.ColorType, header.BitDepth);
  if longint(header.Width) * header.Height * (bpp div 8) > MaxVarSize then
    result := New(PAplStreamImage, CreateDimsBpp(header.Width, header.Height, bpp))
  else begin
    result := New(PAplBufferImage, CreateDimsBpp(header.Width, header.Height, bpp));
    FBufferPtr := PAplBufferImage(result)^.Buffer;
  end;
  if NilPtr(result, ecNotEnoughMemory) then
    exit;
  ProcessHeaderChunk := result;
end;

function TPngManager.ProcessPaletteChunk(AChunk: PPngChunk; AImage: PAplImage): boolean;
var
  palette: PRgbPalette;
  index, count: integer;
  colorPtr: PPngRgbColor;
  rgbColor: TRgbColor;
begin
  palette := New(PRgbPalette, Create(pfApl));
  if NilPtr(palette, ecNotEnoughMemory) then begin
    ProcessPaletteChunk := false;
    exit;
  end;
  count := AChunk^.Length div SizeOf(TPngRgbColor);
  palette^.SetCount(count);
  if CheckReRaise(palette) then begin
    FreeAndNil(palette);
    ProcessPaletteChunk := false;
    exit;
  end;
  ProcessPaletteChunk := true;
  colorPtr := AChunk^.Data^.BufferPointer;
  for index := 0 to count - 1 do begin
    rgbColor.Red := colorPtr^.Red;
    rgbColor.Green := colorPtr^.Green;
    rgbColor.Blue := colorPtr^.Blue;
    palette^.SetColor(index, rgbColor);
    Inc(colorPtr);
  end;
  AImage^.SetPalette(palette);
end;

procedure TPngManager.ProcessDataChunks(AImage: PAplImage);
var
  dest: PMemoryStream;
  data: PMemoryStream;
  size, compressedSize: longint;
  compressor: PCompressor;
  index: integer;
  chunk: PPngChunk;
  method: byte;
  flags: byte;
begin
  compressedSize := 0;
  for index := 0 to FChunkList^.Count - 1 do begin
    chunk := FChunkList^.GetItem(index);
    if not Equal(chunk^.ChunkType, DataChunk, SizeOf(TPngChunkTypeArray)) then
      continue;
    Inc(compressedSize, chunk^.Length);
  end;
  data := New(PMemoryStream, Create(compressedSize));
  if NilPtr(data, ecNotEnoughMemory) then
    exit;
  size := longint(AImage^.Width) * AImage^.Height * AImage^.Bpp div 8;
  for index := 0 to FChunkList^.Count - 1 do begin
    chunk := FChunkList^.GetItem(index);
    if not Equal(chunk^.ChunkType, DataChunk, SizeOf(TPngChunkTypeArray)) then
      continue;
    chunk^.Data^.Seek(0, soFromBeginning);
    method := chunk^.data^.ReadByte and 15;
    flags := chunk^.data^.ReadByte;
    chunk^.Data^.WriteToStream(data, chunk^.Data^.Size - 2);
  end;
  data^.Seek(0, soFromBeginning);
  dest := New(PMemoryStream, Create(size + 1));
  if NilPtr(dest, ecNotEnoughMemory) then
    exit;
  compressor := TCompression.GetCompressor(acZLib, clHigh);
  if NilPtr(compressor, ecNotEnoughMemory) then begin
    FreeAndNil(dest);
    FreeAndNil(data);
    exit;
  end;

  compressor^.DecompressStream(data, dest, size);
  dest^.Seek(1, soFromBeginning);
  Dec(size);
  CheckReRaise(data);
  CheckReRaise(dest);
  CheckReRaise(compressor);
  FreeAndNil(data);
  if not HasException then begin
    if AImage^.IsBufferImage then begin
      dest^.Write(FBufferPtr, size);
      Inc(FBufferPtr, size);
    end
    else begin
      PAplStreamImage(AImage)^.Buffer^.ReadFromStream(dest, size);
    end;
  end;
  FreeAndNil(compressor);
  FreeAndNil(dest);
end;

function TPngManager.ProcessChunk(AChunk: PPngChunk; AImage: PAplImage): boolean;
begin
  ProcessChunk := true;
  if Equal(AChunk^.ChunkType, PaletteChunk, SizeOf(TPngChunkTypeArray)) then
    ProcessChunk := ProcessPaletteChunk(AChunk, AImage);
end;

function TPngManager.ProcessChunks: PAplImage;
var
  index: integer;
  chunk: PPngChunk;
  useStream: boolean;
  result: PAplImage;
begin
  ProcessChunks := nil;
  if FChunkList^.Count = 0 then begin
    Raise(ecPngNoChunks);
    exit;
  end;
  chunk := FChunkList^.GetItem(0);
  if not Equal(chunk^.ChunkType, HeaderChunk, SizeOf(TPngChunkTypeArray)) then begin
    Raise(ecPngNoHeaderChunk);
    exit;
  end;
  result := ProcessHeaderChunk(chunk);
  if not Assigned(result) then
    exit;
  for index := 1 to FChunkList^.Count - 1 do begin
    chunk := FChunkList^.GetItem(index);
    if not ProcessChunk(chunk, result) then
      exit;
  end;
  ProcessDataChunks(result);
  if HasException then
    FreeAndNil(result);
  ProcessChunks := result;
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
  dataCrc: TCrc;
begin
  ReadChunks := false;
  FChunkList^.Clear;
  while true do begin
    length := ReverseEndian(AStream^.ReadLong);
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
    if CheckReRaise(AStream) then begin
      FreeAndNil(chunk);
      exit;
    end;

    InitCrc(dataCrc);
    UpdateCrc(dataCrc, chunkType, SizeOf(TPngChunkTypeArray));
    UpdateCrcStream(dataCrc, chunk^.Data, length);
    dataCrc := FinalizeCrc(dataCrc);

    chunk^.Crc := ReverseEndian(AStream^.ReadLong);
    if CheckReRaise(AStream) then begin
      FreeAndNil(chunk);
      exit;
    end;
    if chunk^.Crc <> dataCrc then begin
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

function TPngManager.ReadAndCheckSignature(AStream: PStream): boolean;
var
  signature: TPngSignature;
begin
  ReadAndCheckSignature := false;
  AStream^.Read(@signature, SizeOf(signature));
  if CheckReRaise(AStream) then
    exit;
  if not Equal(signature, PngSignature, SizeOf(TPngSignature)) then begin
    Raise(ecInvalidPngSignature);
    exit;
  end;
  ReadAndCheckSignature := true;
end;


function TPngManager.ImportPngStream(AStream: PStream): PAplImage;
var
  header: TPngHeader;
  result: PAplImage;
begin
  FBufferPtr := nil;
  ImportPngStream := nil;
  if not ReadAndCheckSignature(AStream) then
    exit;
  if not ReadChunks(AStream) then
    exit;
  ImportPngStream := ProcessChunks;
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

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  TPng.Free;
end;

begin
  PreviousExitProc := ExitProc;
  TPng.Create;
  ExitProc := @Finalize;
end.
