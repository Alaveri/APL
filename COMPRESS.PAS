{$I COMPILER.INC}
unit Compress;

interface

uses
  AplObj,
  AplTypes,
  AplConst,
  AplMath,
  Streams,
  AplUtils;

type
  PCompressor = ^TCompressor;
  PNonCompressor = ^TNonCompressor;
  PCompressProgressProc = ^TCompressProgressProc;

  TAplCompression = (
    acNone,
    acLzw,
    acZLib,
    acGif
  );

  TCompressionLevel = (
    clLow,
    clMedium,
    clHigh
  );

  TCompressProgressProc = procedure(var AEvent: TProgressEvent);

  TCompressor = object(TStatusObject)
  private
    FSource, FDest: PStream;
    FWriteSize, FReadSize: word;
    FReadBitCounter: shortint;
    FWriteBitCounter: shortint;
    FReadBitBuffer: longint;
    FWriteBitBuffer: longint;
    FProgressCounter: longint;
    FWriteByteBuffer: PBufferArray;
    FReadByteBuffer: PBufferArray;
    FReadByteIndex: word;
    FWriteByteIndex: word;
    FReadByteBufferSize: word;
    FWriteByteBufferSize: word;
  public
    OnProgress: PCompressProgressProc;
    Source, Dest: PStream;
    ProgressIncrement: word;
    ReadTotal, WriteTotal: longint;
    CompressionLevel: TCompressionLevel;
    Start: longint;
    constructor Create;
    function CompressStream(ASource, ADest: PStream; ALength: longint): longint; virtual;
    function CompressFromBuffer(ASource: pointer; ADest: PStream; ALength: word): longint;
    function ReadByte: byte;
    function ReadBits(ABitCount: shortint): word;
    function ReadByteBufferSize: word;
    function WriteByteBufferSize: word;
    function FlushWriteBuffer: boolean; virtual;
    procedure SetWriteByteBufferSize(ASize: word);
    procedure SetReadByteBufferSize(ASize: word);
    procedure WriteBits(ANum: word; ABitCount: shortint);
    procedure WriteByte(AByte: byte);
    procedure EndWriteBits; virtual;
    procedure EndCompression; virtual;
    procedure EndDecompression; virtual;
    procedure FreeBuffers; virtual;
    procedure DecompressStream(ASource, ADest: PStream; AOriginalSize: longint); virtual;
    procedure DecompressToBuffer(ASource: PStream; ADest: pointer; AOriginalSize: word);
    procedure Init; virtual;
    procedure InitCompression; virtual;
    procedure UpdateProgress(const AMax, ACurrent: longint);
    procedure SetCompressionLevel(ALevel: TCompressionLevel); virtual;
    destructor Free; virtual;
  end;

  TNonCompressor = object(TCompressor)
    function CompressStream(ASource, ADest: PStream; ALength: longint): longint; virtual;
    function GetOriginalSize(ASource: PStream): longint; virtual;
    procedure DecompressStream(ASource, ADest: PStream; AOriginalSize: longint); virtual;
  end;

  TCompressionManager = object(TStatusObject)
  private
  public
    function GetCompressor(const ACompression: TAplCompression;
      const ALevel: TCompressionLevel): PCompressor;
  end;

var
  TCompression: TCompressionManager;

implementation

uses
  Lzw;
{  ZLib;}

const
  DefaultProgressIncrement = 4096;
  DefaultByteBufferSize = 4096;

constructor TCompressor.Create;
begin
  inherited Create;
end;

procedure TCompressor.Init;
begin
  inherited Init;
  OnProgress := nil;
  FWriteSize := 0;
  FReadSize := 0;
  ReadTotal := 0;
  WriteTotal := 0;
  Source := nil;
  Dest := nil;
  FWriteByteBuffer := nil;
  FReadByteBuffer := nil;
  CompressionLevel := clHigh;
  FReadBitCounter := 0;
  FWriteBitCounter := 0;
  FReadBitBuffer := 0;
  FWriteBitBuffer := 0;
  FWriteByteIndex := 0;
  FReadByteIndex := 0;
  ProgressIncrement := DefaultProgressIncrement;
  FReadByteBufferSize := DefaultByteBufferSize;
  FWriteByteBufferSize := DefaultByteBufferSize;
end;

procedure TCompressor.WriteByte(AByte: byte);
begin
  if FWriteByteIndex >= FWriteSize then begin
    FWriteSize := Dest^.Write(FWriteByteBuffer, FWriteByteIndex);
    if FWriteSize = 0 then begin
      Raise(ecWritePastStreamEnd);
      exit;
    end;
    FWriteByteIndex := 0;
    if CheckReraise(Dest) then
      exit;
  end;
  FWriteByteBuffer^[FWriteByteIndex] := AByte;
  Inc(WriteTotal);
  Inc(FWriteByteIndex);
end;

procedure TCompressor.EndWriteBits;
var
  aByte: byte;
  written: word;
  event: TProgressEvent;
begin
  if HasException then
    exit;
  if FWriteBitCounter > 0 then begin
    aByte := FWriteBitBuffer;
    WriteByte(aByte);
    if HasException then
      exit;
    FWriteBitBuffer := 0;
    FWriteBitCounter := 0;
  end;
  if Assigned(OnProgress) and (ReadTotal mod ProgressIncrement = 0) then begin
    event.Create;
    event.Max := Source^.Size;
    event.Current := ReadTotal;
    event.Sender := @self;
    TCompressProgressProc(OnProgress)(event);
  end;
end;

function TCompressor.FlushWriteBuffer: boolean;
var
  written: word;
begin
  FlushWriteBuffer := true;
  if Dest^.HasException or HasException or (FWriteByteIndex < 1) then begin
    FlushWriteBuffer := false;
    exit;
  end;
  written := Dest^.Write(FWriteByteBuffer, FWriteByteIndex);
  if written = 0 then begin
    Raise(ecWritePastStreamEnd);
    FlushWriteBuffer := false;
    exit;
  end;
  if Dest^.HasException then begin
    Raise(Dest^.Exception^.Code);
    Dest^.ClearException;
    FlushWriteBuffer := false;
  end;
end;

function TCompressor.ReadByte: byte;
var
  current: byte;
  byteCount: longint;
begin
  if FReadByteIndex >= FReadSize then begin
    FReadSize := Source^.Read(FReadByteBuffer, FReadByteBufferSize);
    if FReadSize = 0 then begin
      Raise(ecReadPastStreamEnd);
      exit;
    end;
    if CheckReraise(Source) then
      exit;
    FReadByteIndex := 0;
  end;
  current := FReadByteBuffer^[FReadByteIndex];
  Inc(ReadTotal);
  Inc(FReadByteIndex);
  ReadByte := current;
end;

procedure TCompressor.WriteBits(ANum: word; ABitCount: shortint);
var
  aByte: byte;
begin
  FWriteBitBuffer := FWriteBitBuffer or (longint(ANum) shl FWriteBitCounter);
  Inc(FWriteBitCounter, ABitCount);
  while FWriteBitCounter >= 8 do begin
    aByte := byte(FWriteBitBuffer and $FF);
    WriteByte(aByte);
    FWriteBitBuffer := FWriteBitBuffer shr 8;
    Dec(FWriteBitCounter, 8);
  end;
end;

function TCompressor.ReadBits(ABitCount: shortint): word;
var
  readResult: word;
  bytesRead: word;
begin
  while FReadBitCounter < ABitCount do begin
    readResult := ReadByte;
    FReadBitBuffer := FReadBitBuffer or (readResult shl FReadBitCounter);
    Inc(FReadBitCounter, 8);
  end;
  ReadBits := word(FReadBitBuffer and ((1 shl longint(ABitCount)) - 1));
  FReadBitBuffer := FReadBitBuffer shr ABitCount;
  Dec(FReadBitCounter, ABitCount);
end;

function TCompressor.ReadByteBufferSize: word;
begin
  ReadByteBufferSize := FReadByteBufferSize;
end;

function TCompressor.WriteByteBufferSize: word;
begin
  WriteByteBufferSize := FWriteByteBufferSize;
end;

procedure TCompressor.SetWriteByteBufferSize(ASize: word);
begin
  if Assigned(FWriteByteBuffer) then
    FreeMem(FWriteByteBuffer, FWriteByteBufferSize);
  FWriteByteBufferSize := ASize;
  FWriteByteBuffer := nil;
end;

procedure TCompressor.SetReadByteBufferSize(ASize: word);
begin
  if Assigned(FReadByteBuffer) then
    FreeMem(FReadByteBuffer, FReadByteBufferSize);
  FReadByteBufferSize := ASize;
  FReadByteBuffer := nil;
end;

procedure TCompressor.EndCompression;
begin
  FlushWriteBuffer;
  FreeBuffers;
end;

procedure TCompressor.EndDecompression;
begin
  FlushWriteBuffer;
  FreeBuffers;
  Source^.Seek(Start + ReadTotal + 1, soFromBeginning);
end;

procedure TCompressor.FreeBuffers;
begin
  if Assigned(FWriteByteBuffer) then
    FreeMem(FWriteByteBuffer, FWriteByteBufferSize);
  if Assigned(FReadByteBuffer) then
    FreeMem(FReadByteBuffer, FReadByteBufferSize);
  FWriteByteBuffer := nil;
  FReadByteBuffer := nil;
end;

procedure TCompressor.UpdateProgress(const AMax, ACurrent: longint);
var
  event: TProgressEvent;
begin
  if (ACurrent >= AMax) or (FProgressCounter >= ProgressIncrement) then begin
    if Assigned(OnProgress) then begin
      event.Create;
      event.Max := AMax;
      event.Current := ACurrent;
      event.Sender := @self;
      TCompressProgressProc(OnProgress)(event);
    end;
    FProgressCounter := 0;
    exit;
  end;
  Inc(FProgressCounter);
end;

destructor TCompressor.Free;
begin
  FreeBuffers;
  inherited Free;
end;

procedure TCompressor.InitCompression;
begin
  if not Assigned(FWriteByteBuffer) then begin
    GetMem(FWriteByteBuffer, FWriteByteBufferSize);
    if NilPtr(FWriteByteBuffer, ecNotEnoughMemory) then
      exit;
  end;
  if not Assigned(FReadByteBuffer) then begin
    GetMem(FReadByteBuffer, FReadByteBufferSize);
    if NilPtr(FReadByteBuffer, ecNotEnoughMemory) then begin
      FreeMem(FWriteByteBuffer, FReadByteBufferSize);
      exit;
    end;
  end;
  WriteTotal := 0;
  ReadTotal := 0;
  FWriteBitBuffer := 0;
  FReadBitCounter := 0;
  FWriteBitCounter := 0;
  FWriteSize := FWriteByteBufferSize;
  FReadSize := 0;
  FReadBitBuffer := 0;
  FProgressCounter := 0;
  FWriteByteIndex := 0;
  FReadByteIndex := 0;
end;

function TCompressor.CompressFromBuffer(ASource: pointer; ADest: PStream; ALength: word): longint;
var
  sourceStream: PMemoryStream;
begin
  CompressFromBuffer := 0;
  sourceStream := New(PMemoryStream, CreateBuffer(ASource, ALength));
  if NilPtr(sourceStream, ecNotEnoughMemory) then
    exit;
  sourceStream^.FreeBuffers := false;
  CompressFromBuffer := CompressStream(sourceStream, ADest, ALength);
  CheckReRaise(ADest);
  CheckReRaise(sourceStream);
  FreeAndNil(sourceStream);
end;

procedure TCompressor.DecompressToBuffer(ASource: PStream; ADest: pointer; AOriginalSize: word);
var
  destStream: PMemoryStream;
begin
  destStream := New(PMemoryStream, CreateBuffer(ADest, AOriginalSize));
  if NilPtr(destStream, ecNotEnoughMemory) then
    exit;
  destStream^.FreeBuffers := false;
  DecompressStream(ASource, destStream, AOriginalSize);
  CheckReRaise(ASource);
  CheckReRaise(destStream);
  FreeAndNil(destStream);
end;

function TCompressor.CompressStream(ASource, ADest: PStream; ALength: longint): longint;
begin
  InitCompression;
  Source := ASource;
  Dest := ADest;
  CompressStream := 0;
end;

procedure TCompressor.DecompressStream(ASource, ADest: PStream; AOriginalSize: longint);
begin
  Source := ASource;
  Dest := ADest;
  InitCompression;
end;

procedure TCompressor.SetCompressionLevel(ALevel: TCompressionLevel);
begin
  CompressionLevel := ALevel;
end;

function TNonCompressor.CompressStream(ASource, ADest: PStream; ALength: longint): longint;
begin
  ASource^.WriteToStream(ADest, ALength);
  CompressStream := ALength;
end;

function TNonCompressor.GetOriginalSize(ASource: PStream): longint;
begin
  GetOriginalSize := ASource^.Size;
end;

procedure TNonCompressor.DecompressStream(ASource, ADest: PStream; AOriginalSize: longint);
begin
  ASource^.WriteToStream(ADest, AOriginalSize);
end;

function TCompressionManager.GetCompressor(const ACompression: TAplCompression;
  const ALevel: TCompressionLevel): PCompressor;
var
  result: PCompressor;
  bitSize: byte;
begin
  case ACompression of
    acNone:
      result := New(PNonCompressor, Create);
    acLzw: begin
      bitSize := LzwCompressionBitSize[ALevel];
      result := New(PLzw, CreateBitSize(bitSize));
      PLzw(result)^.SetLzwCodesProc := @SetLzwCodes;
    end;
    acZLib: begin
{      result := New(PZlib, Create);
      result^.AddTotalToStream := false;}
    end;
    acGif: begin
      result := New(PLzw, CreateBitSize(13));
      PLzw(result)^.SetLzwCodesProc := @SetGifLzwCodes;
    end;
    else
      result := nil;
  end;
  GetCompressor := result;
end;

var
  PreviousExitProc: PProc;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  TCompression.Free;
end;

begin
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
  TCompression.Create;
end.