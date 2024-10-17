{$I COMPILER.INC}
unit Compress;

interface

uses
  AplTypes,
  Errors,
  Streams,
  Common;

type
  PCompressor = ^TCompressor;
  PCompressProgressProc = ^TCompressProgressProc;

  TCompressProgressProc = procedure(ASender: PCompressor; AMax, ACurrent: longint);

  TCompressor = object(TStatusObject)
  private
    FReadBufferSize: word;
    FWriteBufferSize: word;
    FSource, FDest: PStream;
    FWriteSize, FReadSize: word;
    FReadPos, FWritePos: word;
    FReadBitCounter: shortint;
    FWriteBitCounter: shortint;
    FReadBitBuffer: longint;
    FWriteBitBuffer: longint;
    FReadBuffer, FWriteBuffer: PByte;
    FReadPtr, FWritePtr: PByte;
    FProgressCounter: word;
    procedure SetBufferSize(AReadBufferSize, AWriteBufferSize: word);
  public
    OnProgress: PCompressProgressProc;
    Source, Dest: PStream;
    ProgressIncrement: word;
    ReadTotal, WriteTotal: longint;
    constructor CreateBufferSize(AReadBufferSize, AWriteBufferSize: word);
    constructor Create;
    function CompressStream(ASource, ADest: PStream; ALength: longint): longint; virtual;
    function ReadByte: byte;
    function ReadBits(ABitCount: shortint): word;
    function FlushWriteBuffer: boolean;
    function GetOriginalSize(ASource: PStream): longint; virtual;
    procedure WriteBits(ANum: word; ABitCount: shortint);
    procedure WriteByte(AByte: byte);
    procedure EndWriteBits;
    procedure DecompressStream(ASource, ADest: PStream; AOriginalSize: longint); virtual;
    procedure Init; virtual;
    procedure InitCompression; virtual;
    procedure UpdateProgress(const AMax, ACurrent: longint);
    destructor Free; virtual;
  end;

implementation

uses
  MemDrv;

const
  DefaultProgressIncrement = 4096;
  DefaultBufferSize = 4096;

procedure TCompressor.SetBufferSize(AReadBufferSize, AWriteBufferSize: word);
begin
  FReadBufferSize := AReadBufferSize;
  FWriteBufferSize := AWriteBufferSize;
  GetMem(FReadBuffer, FReadBufferSize);
  GetMem(FWriteBuffer, FWriteBufferSize);
end;

constructor TCompressor.Create;
begin
  inherited Create;
  SetBufferSize(DefaultBufferSize, DefaultBufferSize);
end;

constructor TCompressor.CreateBufferSize(AReadBufferSize, AWriteBufferSize: word);
begin
  inherited Create;
  SetBufferSize(AReadBufferSize, AWriteBufferSize);
end;

procedure TCompressor.Init;
begin
  inherited Init;
  OnProgress := nil;
  FWriteSize := 0;
  FReadSize := 0;
  ReadTotal := 0;
  WriteTotal := 0;
  FReadPos := MaxVarSize;
  FWritePos := 0;
  FReadPtr := nil;
  FWritePtr := nil;
  Source := nil;
  Dest := nil;
  FReadBitCounter := 0;
  FWriteBitCounter := 0;
  FReadBitBuffer := 0;
  FWriteBitBuffer := 0;
  FReadBuffer := nil;
  FWriteBuffer := nil;
  ProgressIncrement := DefaultProgressIncrement;
end;

function TCompressor.GetOriginalSize(ASource: PStream): longint;
begin
  GetOriginalSize := 0;
end;

procedure TCompressor.WriteByte(AByte: byte);
var
  written: longint;
begin
  if FWritePos >= FWriteSize then begin
    written := Dest^.Write(FWriteBuffer, FWriteSize);
    if written = 0 then begin
      Raise(ecWritePastStreamEnd);
      exit;
    end;
    if Dest^.HasException then begin
      Raise(Dest^.Exception^.Code);
      Dest^.ClearException;
      exit;
    end;
    FWritePos := 0;
    FWritePtr := FWriteBuffer;
    FWriteSize := written;
  end;
  FWritePtr^ := AByte;
  Inc(WriteTotal);
  Inc(FWritePtr);
  Inc(FWritePos);
end;

procedure TCompressor.EndWriteBits;
var
  aByte: byte;
  written: word;
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
  FlushWriteBuffer;
  if Assigned(OnProgress) and (ReadTotal mod ProgressIncrement = 0) then
    TCompressProgressProc(OnProgress)(@self, Source^.Size, ReadTotal);
end;

function TCompressor.ReadByte: byte;
var
  bytesRead: longint;
begin
  if (FReadPos = MaxVarSize) or (FReadPos >= FReadSize) then begin
    bytesRead := Source^.Read(FReadBuffer, FReadBufferSize);
    if bytesRead = 0 then begin
      Raise(ecReadPastStreamEnd);
      exit;
    end;
    if Source^.HasException then begin
      Raise(Source^.Exception^.Code);
      Source^.ClearException;
      exit;
    end;
    FReadPos := 0;
    FReadPtr := FReadBuffer;
    FReadSize := bytesRead;
  end;
  ReadByte := FReadPtr^;
  Inc(ReadTotal);
  Inc(FReadPtr);
  Inc(FReadPos);
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

procedure TCompressor.UpdateProgress(const AMax, ACurrent: longint);
begin
  if (ACurrent >= AMax) or (FProgressCounter >= ProgressIncrement) then begin
    if Assigned(OnProgress) then
      TCompressProgressProc(OnProgress)(@self, AMax, ACurrent);
    FProgressCounter := 0;
    exit;
  end;
  Inc(FProgressCounter);
end;

function TCompressor.FlushWriteBuffer: boolean;
var
  written: word;
begin
  FlushWriteBuffer := true;
  if Dest^.HasException or HasException or (FWritePos < 1) then begin
    FlushWriteBuffer := false;
    exit;
  end;
  if FWritePos > 0 then begin
    written := Dest^.Write(FWriteBuffer, FWritePos);
    if written = 0 then begin
      Raise(ecWritePastStreamEnd);
      FlushWriteBuffer := false;
      exit;
    end;
  end;
  if Dest^.HasException then begin
    Raise(Dest^.Exception^.Code);
    Dest^.ClearException;
    FlushWriteBuffer := false;
  end;
end;

destructor TCompressor.Free;
begin
  if Assigned(FReadBuffer) then begin
    FreeMem(FReadBuffer, FReadBufferSize);
    FReadBuffer := nil;
  end;
  if Assigned(FWriteBuffer) then begin
    FreeMem(FWriteBuffer, FWriteBufferSize);
    FWriteBuffer := nil;
  end;
  inherited Free;
end;

procedure TCompressor.InitCompression;
begin
  FReadPos := MaxVarSize;
  FWritePos := 0;
  WriteTotal := 0;
  ReadTotal := 0;
  FWritePtr := FWriteBuffer;
  FWriteSize := FWriteBufferSize;
  FReadSize := FReadBufferSize;
  FWriteBitBuffer := 0;
  FReadBitCounter := 0;
  FWriteBitCounter := 0;
  FReadBitBuffer := 0;
  FReadPtr := FReadBuffer;
  FProgressCounter := 0;
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

end.