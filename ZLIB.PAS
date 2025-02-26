{$I COMPILER.INC}
unit ZLib;

interface

uses
  AplConst,
  AplObj,
  AplStr,
  AplTypes,
  Aplutils,
  AplMath,
  Lists,
  GzIo,
  Compress,
  Streams,
  Strings;

type
  PZLib = ^TZLib;

  TZlib = object(TCompressor)
  private
  public
    function CompressStream(ASource, ADest: PStream; ALength: longint): longint; virtual;
    procedure Init; virtual;
    procedure DecompressStream(ASource, ADest: PStream; AOriginalSize: longint); virtual;
  end;

implementation

procedure TZlib.Init;
begin
  inherited Init;
end;

function TZlib.CompressStream(ASource, ADest: PStream; ALength: longint): longint;
var
  level: integer;
  zStream: gzFile;
  readBytes, bytesWritten, remaining: longint;
  buffer: PByte;
  start: longint;
begin
  GetMem(buffer, 4096);
  start := ADest^.Position;
  case CompressionLevel of
    clLow: level := 1;
    clMedium: level := 6;
    clHigh: level := 9;
  end;
  remaining := ALength;
  zStream := gzopenstream(ADest, 'w' + IntToStr(level), false);
  while remaining > 0 do begin
    readBytes := MinL(4096, remaining);
    ASource^.Read(buffer, readBytes);
    if CheckReRaise(ASource) then
      break;
    bytesWritten := gzwrite(zStream, buffer, 4096);
    if bytesWritten = 0 then
      break;
    if bytesWritten < 0 then begin
      Raise(ecStreamWriteError);
      break;
    end;
    Dec(remaining, readBytes);
  end;
  CompressStream := ADest^.Position - start;
  gzclose(zStream);
  FreeMem(buffer, 4096);
end;

procedure TZlib.DecompressStream(ASource, ADest: PStream; AOriginalSize: longint);
var
  zStream: gzFile;
  buffer: PByte;
  bytesRead, total, bytes, remaining: longint;
begin
  GetMem(buffer, 4096);
  zStream := gzopenstream(ASource, 'r', false);
  bytesRead := 0;
  total := 0;
  remaining := AOriginalSize;
  while remaining > 0 do begin
    bytes := MinL(4096, remaining);
    bytesRead := gzread(zStream, buffer, bytes);
    if bytesRead = 0 then
      break;
    if bytesRead < 0 then begin
      Raise(ecStreamReadError);
      break;
    end;
    Inc(total, bytesRead);
    Dec(remaining, bytesRead);
    ADest^.Write(buffer, bytesRead);
    if CheckReRaise(ADest) then
      break;
  end;
  gzclose(zStream);
  FreeMem(buffer, 4096);
end;

var
  PreviousExitProc: PProc;

procedure Finalize;
begin
  ExitProc := PreviousExitProc;
end;

begin
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
