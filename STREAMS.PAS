{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Streams;

interface

uses
  {$IFDEF DOS}
  Dos,
  {$ENDIF}
  Objects,
  Errors,
  Common,
  Lists,
  MemDrv;

type
  PStream = ^TStream;
  PMemoryStream = ^TMemoryStream;
  PFileStream = ^TFileStream;
  PStreamReader = ^TStreamReader;
  PTextReader = ^TTextReader;

  TSeekOrigin =
  (
    soFromBeginning,
    soFromEnd,
    soFromPosition
  );

  TStreamStatus =
  (
    ssOk,
    ssError,
    ssEndOfStream
  );

  TStream = object(TExceptionObject)
  private
    FStatus: TStreamStatus;
    FClosed: boolean;
  public
    Position: longint;
    Size: longint;
    destructor Free; virtual;
    function Status: TStreamStatus; virtual;
    function EndOfStream: boolean; virtual;
    function CanRead: boolean; virtual;
    function CanWrite: boolean; virtual;
    function CanSeek: boolean; virtual;
    function Read(ABuffer: PByte; ACount: longint): longint; virtual;
    function ReadByte: byte; virtual;
    function ReadInteger: integer; virtual;
    function ReadWord: word; virtual;
    function ReadLong: longint; virtual;
    function ReadString: string; virtual;
    function Write(ABuffer: PByte; ACount: longint): longint; virtual;
    function Seek(AOffset: longint; AOrigin: TSeekOrigin): longint; virtual;
    function WriteToStream(AStream: PStream; ACount: longint): longint; virtual;
    function ReadFromStream(AStream: PStream; ACount: longint): longint; virtual;
    procedure Init; virtual;
    procedure Close; virtual;
    procedure WriteByte(AValue: byte); virtual;
    procedure WriteInteger(AValue: integer); virtual;
    procedure WriteWord(AValue: word); virtual;
    procedure WriteLong(AValue: longint); virtual;
    procedure WriteString(const AString: string); virtual;
  end;

  TMemoryStream = object(TStream)
  private
    FReferences: PReferenceList;
  public
    constructor Create(ASize: longint);
    destructor Free; virtual;
    function Read(ABuffer: PByte; ACount: longint): longint; virtual;
    function Write(ABuffer: PByte; ACount: longint): longint; virtual;
    function WriteToStream(AStream: PStream; ACount: longint): longint; virtual;
    function ReadFromStream(AStream: PStream; ACount: longint): longint; virtual;
    function CanRead: boolean; virtual;
    function CanWrite: boolean; virtual;
    function CanSeek: boolean; virtual;
    function Fill(ACount: longint; AByte: byte): longint; virtual;
    procedure Init; virtual;
  end;

  TFileStreamMode =
  (
    fmRead,
    fmWrite,
    fmReadWrite
  );

  TFileStream = object(TStream)
  private
    FMode: TFileStreamMode;
    FFile: file;
    FOpen: boolean;
    FFilename: string;
    function CheckRead: boolean;
    function CheckWrite: boolean;
  public
    BufferSize: word;
    constructor Create(AFilename: string; AMode: TFileStreamMode);
    constructor CreateBufferSize(AFilename: string; AMode: TFileStreamMode; ABufferSize: word);
    destructor Done; virtual;
    function Read(ABuffer: PByte; ACount: longint): longint; virtual;
    function ReadByte: byte; virtual;
    function ReadInteger: integer; virtual;
    function ReadWord: word; virtual;
    function ReadLong: longint; virtual;
    function Write(ABuffer: PByte; ACount: longint): longint; virtual;
    function WriteToStream(AStream: PStream; ACount: longint): longint; virtual;
    function ReadFromStream(AStream: PStream; ACount: longint): longint; virtual;
    function CanRead: boolean; virtual;
    function CanWrite: boolean; virtual;
    function CanSeek: boolean; virtual;
    function Seek(AOffset: longint; AOrigin: TSeekOrigin): longint; virtual;
    procedure Init; virtual;
    procedure Open; virtual;
    procedure Close; virtual;
    procedure WriteByte(AValue: byte); virtual;
    procedure WriteInteger(AValue: integer); virtual;
    procedure WriteWord(AValue: word); virtual;
    procedure WriteLong(AValue: longint); virtual;
  end;

  TStreamReader = object(TExceptionObject)
  private
    FStream: PStream;
  public
    constructor Create(AStream: PStream);
    destructor Free; virtual;
    procedure Init; virtual;
  end;

  TTextReader = object(TStreamReader)
  private
  public
    procedure Init; virtual;
    destructor Free; virtual;
    function ReadLine: string;
    function ReadAllLines: PStringList;
  end;

implementation

const
  DefaultFileStreamBufferSize = 4096;

destructor TStream.Free;
begin
  Close;
  inherited Free;
end;

function TStream.Status: TStreamStatus;
begin
  Status := status;
end;

function TStream.EndOfStream: boolean;
begin
  EndOfStream := Position >= Size;
end;

function TStream.CanRead: boolean;
begin
  CanRead := true;
end;

function TStream.CanWrite: boolean;
begin
  CanWrite := true;
end;

function TStream.CanSeek: boolean;
begin
  CanSeek := true;
end;

function TStream.Read(ABuffer: PByte; ACount: longint): longint;
begin
end;

function TStream.Write(ABuffer: PByte; ACount: longint): longint;
begin
end;

function TStream.Seek(AOffset: longint; AOrigin: TSeekOrigin): longint;
var
  newPos: longint;
begin
  if not CanSeek then
    Raise(ecStreamSeekNotSupported);
  if HasException then
    exit;
  case AOrigin of
    soFromBeginning: begin
      newPos := AOffset;
    end;
    soFromEnd: begin
      newPos := Size - AOffset - 1;
    end;
    soFromPosition: begin
      newPos := Position + AOffset;
    end;
  end;
  Position := MinLong(MaxLong(0, newPos), Size);
end;

function TStream.ReadByte: byte;
var
  aNum: byte;
begin
  aNum := 0;
  Read(@aNum, SizeOf(byte));
  ReadByte := aNum;
end;

function TStream.ReadInteger: integer;
var
  aNum: integer;
begin
  aNum := 0;
  Read(@aNum, SizeOf(integer));
  ReadInteger := aNum;
end;

function TStream.ReadLong: longint;
var
  aNum: longint;
begin
  aNum := 0;
  Read(@aNum, SizeOf(longint));
  ReadLong := aNum;
end;

function TStream.ReadWord: word;
var
  aNum: word;
begin
  aNum := 0;
  Read(@aNum, SizeOf(word));
  ReadWord := aNum;
end;

function TStream.WriteToStream(AStream: PStream; ACount: longint): longint;
begin
end;

function TStream.ReadFromStream(AStream: PStream; ACount: longint): longint;
begin
end;

procedure TStream.Init;
begin
  inherited Init;
  Position := 0;
  FStatus := ssEndOfStream;
  Size := 0;
  FClosed := true;
end;

procedure TStream.Close;
begin
  FClosed := true;
end;

procedure TStream.WriteByte(AValue: byte);
begin
  Write(@AValue, SizeOf(byte));
end;

function TStream.ReadString: string;
var
  len: byte;
  result: string;
begin
  result := '';
  len := ReadByte;
  if HasException then
    exit;
  Read(@result[1], len);
  if HasException then
    exit;
  result[0] := Chr(len);
  ReadString := result;
end;

procedure TStream.WriteString(const AString: string);
begin
  Write(@AString, Length(AString) + 1);
end;

procedure TStream.WriteInteger(AValue: integer);
begin
  Write(@AValue, SizeOf(integer));
end;

procedure TStream.WriteWord(AValue: word);
begin
  Write(@AValue, SizeOf(word));
end;

procedure TStream.WriteLong(AValue: longint);
begin
  Write(@AValue, SizeOf(longint));
end;

constructor TMemoryStream.Create(ASize: longint);
var
  reference: PReference;
  total: longint;
  refSize: longint;
begin
  inherited Create;
  FStatus := ssOk;
  Memory.BeginAllocTransaction;
  total := ASize;
  while total > 0 do begin
    refSize := MinLong(total, MaxVarSize);
    reference := Memory.Alloc(refSize);
    if Memory.HasException then begin
      Raise(Memory.Exception^.Code);
      Memory.ClearException;
      Memory.RollbackAllocTransaction;
      FReferences^.Clear;
      exit;
    end;
    FReferences^.Add(reference);
    Dec(total, refSize);
  end;
  Size := ASize;
  Memory.CommitAllocTransaction;
end;

destructor TMemoryStream.Free;
var
  index: integer;
  reference: PReference;
begin
  for index := FReferences^.Count - 1 downto 0 do begin
    reference := FReferences^.GetItem(index);
    Memory.DeAlloc(reference);
  end;
  FreeAndNil(FReferences);
  inherited Free;
end;

function TMemoryStream.Read(ABuffer: PByte; ACount: longint): longint;
var
  bytesRead: longint;
  index: integer;
  offset: longint;
  reference: PReference;
  readSize: longint;
  ptr: PByte;
begin
  if HasException then
    exit;
  Read := 0;
  bytesRead := 0;
  while bytesRead < ACount do begin
    index := Position div MaxVarSize;
    if index = -1 then
      break;
    offset := Position mod MaxVarSize;
    reference := FReferences^.GetItem(index);
    readSize := MinLong(reference^.Size - offset, ACount - bytesRead);
    if readSize <= 0 then
      break;
    ptr := Memory.ReferencePointer(reference);
    Inc(ptr, offset);
    Move(ptr^, ABuffer^, readSize);
    Inc(ABuffer, readSize);
    Inc(bytesRead, readSize);
    Inc(Position, readSize);
  end;
  Read := bytesRead;
end;

function TMemoryStream.Fill(ACount: longint; AByte: byte): longint;
var
  index: integer;
  written: longint;
  reference: PReference;
  offset: longint;
  writeSize: word;
  ptr: PByte;
begin
  if HasException then
    exit;
  Fill := 0;
  written := 0;
  while written < ACount do begin
    index := Position div MaxVarSize;
    if index > FReferences^.Count - 1 then
      break;
    offset := Position mod MaxVarSize;
    reference := FReferences^.GetItem(index);
    writeSize := MinLong(reference^.Size - offset, ACount - written);
    if writeSize <= 0 then
      exit;
    ptr := Memory.ReferencePointer(reference);
    Inc(ptr, offset);
    System.FillChar(ptr^, writeSize, AByte);
    Inc(written, writeSize);
    Inc(Position, writeSize);
  end;
  Fill := written;
end;

function TMemoryStream.Write(ABuffer: PByte; ACount: longint): longint;
var
  index: integer;
  written: longint;
  reference: PReference;
  offset: longint;
  writeSize: longint;
  ptr: PByte;
begin
  if HasException then
    exit;
  Write := 0;
  written := 0;
  while written < ACount do begin
    index := Position div MaxVarSize;
    if index > FReferences^.Count - 1  then
      break;
    offset := Position mod MaxVarSize;
    reference := FReferences^.GetItem(index);
    writeSize := MinLong(reference^.Size - offset, ACount - written);
    if writeSize <= 0 then
      break;
    ptr := Memory.ReferencePointer(reference);
    Inc(ptr, offset);
    Move(ABuffer^, ptr^, writeSize);
    Inc(ABuffer, writeSize);
    Inc(written, writeSize);
    Inc(Position, writeSize);
  end;
  Write := written;
end;

function TMemoryStream.WriteToStream(AStream: PStream; ACount: longint): longint;
var
  index: integer;
  refWritten: word;
  bytesWritten, total: longint;
  reference: PReference;
  offset: longint;
  writeSize: longint;
  ptr, destPtr: PByte;
begin
  if HasException then
    exit;
  WriteToStream := 0;
  total := 0;
  while total < ACount do begin
    index := Position div MaxVarSize;
    if index > FReferences^.Count - 1 then
      break;
    offset := Position mod MaxVarSize;
    reference := FReferences^.GetItem(index);
    writeSize := MinLong(reference^.Size - offset, ACount - total);
    if writeSize <= 0 then
      break;
    ptr := Memory.ReferencePointer(reference);
    Inc(ptr, offset);
    bytesWritten := AStream^.Write(ptr, writeSize);
    if bytesWritten = 0 then
      exit;
    Inc(total, bytesWritten);
    Inc(Position, bytesWritten);
  end;
  WriteToStream := total;
end;

function TMemoryStream.ReadFromStream(AStream: PStream; ACount: longint): longint;
begin
  ReadFromStream := AStream^.WriteToStream(@self, ACount);
end;

procedure TMemoryStream.Init;
begin
  inherited Init;
  FReferences := New(PReferenceList, Create);
end;

function TMemoryStream.CanRead: boolean;
begin
  CanRead := true;
end;

function TMemoryStream.CanWrite: boolean;
begin
  CanWrite := true;
end;

function TMemoryStream.CanSeek: boolean;
begin
  CanSeek := true;
end;

constructor TFileStream.Create(AFilename: string; AMode: TFileStreamMode);
begin
  CreateBufferSize(AFilename, AMode, DefaultFileStreamBufferSize);
end;

constructor TFileStream.CreateBufferSize(AFilename: string; AMode: TFileStreamMode; ABufferSize: word);
begin
  FMode := AMode;
  FFilename := AFilename;
  BufferSize := ABufferSize;
  Init;
end;

procedure TFileStream.Init;
begin
  inherited init;
  BufferSize := DefaultFileStreamBufferSize;
  FOpen := false;
  Open;
end;

destructor TFileStream.Done;
begin
  Close;
end;

function TFileStream.Read(ABuffer: PByte; ACount: longint): longint;
var
  bytesRead: word;
  total: longint;
begin
  Read := 0;
  if (ACount <= 0) or not CheckRead then
    exit;
  total := 0;
  while total < ACount do begin
    {$I-}
    if Eof(FFile) then
      break;
    BlockRead(FFile, ABuffer^, MinLong(ACount, MaxVarSize), bytesRead);
    {$I+}
    if IOResult <> 0 then begin
      Raise(ecStreamReadError);
      exit;
    end;
    if bytesRead = 0 then
      break;
    Inc(ABuffer, bytesRead);
    Inc(total, bytesRead);
    Inc(Position, bytesRead);
  end;
  Read := total;
end;

function TFileStream.Write(ABuffer: PByte; ACount: longint): longint;
var
  bytesWritten: word;
  bufferPtr: PByte;
  total: longint;
begin
  Write := 0;
  if (ACount <= 0) or not CheckWrite then
    exit;
  total := 0;
  bufferPtr := ABuffer;
  while total < ACount do begin
    Seek(Position, soFromBeginning);
    {$I-}
    BlockWrite(FFile, ABuffer^, MinLong(ACount, MaxVarSize), bytesWritten);
    {$I+}
    if IOResult <> 0 then begin
      Raise(ecStreamReadError);
      exit;
    end;
    if bytesWritten = 0 then
      break;
    Inc(ABuffer, bytesWritten);
    Inc(total, bytesWritten);
    Inc(Position, bytesWritten);
    Inc(Size, bytesWritten);
  end;
  Write := total;
end;

function TFileStream.ReadByte: byte;
var
  aNum: byte;
begin
  if not CheckRead then
    exit;
  aNum := 0;
  inherited Read(@aNum, SizeOf(byte));
  ReadByte := aNum;
end;

function TFileStream.ReadInteger: integer;
var
  aNum: integer;
begin
  if not CheckRead then
    exit;
  aNum := 0;
  Read(@aNum, SizeOf(integer));
  ReadInteger := aNum;
end;

function TFileStream.ReadWord: word;
var
  aNum: word;
begin
  if not CheckRead then
    exit;
  aNum := 0;
  inherited Read(@aNum, SizeOf(word));
  ReadWord := aNum;
end;

function TFileStream.ReadLong: longint;
var
  aNum: longint;
begin
  if not CheckRead then
    exit;
  inherited Read(@aNum, SizeOf(longint));
  ReadLong := aNum;
end;

function TFileStream.WriteToStream(AStream: PStream; ACount: longint): longint;
var
  bytesWritten, bytesRead: word;
  buffer: PByte;
  total: longint;
begin
  WriteToStream := 0;
  if (ACount <= 0) or (not CheckRead) then
    exit;
  total := 0;
  GetMem(buffer, BufferSize);
  while total < ACount do begin
    {$I-}
    Seek(Position, soFromBeginning);
    bytesRead := Read(buffer, BufferSize);
    if bytesRead = 0 then
      break;
    {$I+}
    if IOResult <> 0 then begin
      Raise(ecStreamReadError);
      break;
    end;
    bytesWritten := AStream^.Write(buffer, bytesRead);
    if bytesWritten = 0 then
      break;
    Inc(total, bytesWritten);
  end;
  FreeMem(buffer, BufferSize);
  WriteToStream := total;
end;

function TFileStream.ReadFromStream(AStream: PStream; ACount: longint): longint;
begin
  ReadFromStream := AStream^.WriteToStream(@self, ACount);
end;

function TFileStream.CanRead: boolean;
begin
  CanRead := NoException and ((FMode = fmRead) or (FMode = fmReadWrite));
end;

function TFileStream.CanWrite: boolean;
begin
  CanWrite := NoException and ((FMode = fmWrite) or (FMode = fmReadWrite));
end;

function TFileStream.CanSeek: boolean;
begin
  CanSeek := true;
end;

procedure TFileStream.WriteByte(AValue: byte);
begin
  if not CheckWrite then
    exit;
  Write(@AValue, SizeOf(byte));
end;

procedure TFileStream.WriteInteger(AValue: integer);
begin
  if not CheckWrite then
    exit;
  Write(@AValue, SizeOf(integer));
end;

procedure TFileStream.WriteWord(AValue: word);
begin
  if not CheckWrite then
    exit;
  Write(@AValue, SizeOf(word));
end;

procedure TFileStream.WriteLong(AValue: longint);
begin
  if not CheckWrite then
    exit;
  Write(@AValue, SizeOf(longint));
end;

function TFileStream.Seek(AOffset: longint; AOrigin: TSeekOrigin): longint;
begin
  inherited Seek(AOffset, AOrigin);
  if HasException then
    exit;
  {$I+}
  System.Seek(FFile, Position);
  if (IOResult <> 0) then
    Raise(ecStreamSeekError);
  {$I-}
end;

procedure TFileStream.Open;
begin
  if FOpen then
     exit;
  FOpen := true;
  {$I-}
  if FileExists(FFilename) then begin
    System.Assign(FFile, FFilename);
    case FMode of
      fmRead, fmReadWrite: begin
        Reset(FFile, 1);
        Size := FileSize(FFile);
      end;
      fmWrite: Rewrite(FFile, 1);
    end;
  end
  else begin
    System.Assign(FFile, FFilename);
    case FMode of
      fmRead, fmReadWrite: Raise(ecFileNotFound);
      fmWrite: Rewrite(FFile, 1);
    end;
  end;
  if IOResult <> 0 then
    Raise(ecStreamWriteError);
  {$I+}

  if HasException then
    FOpen := false;
end;

procedure TFileStream.Close;
begin
  {$I-}
  if FOpen then
    System.Close(FFile);
  if IOResult <> 0 then
    Raise(ecStreamCloseError);
  {$I+}
end;

function TFileStream.CheckRead: boolean;
begin
  CheckRead := true;
  if not CanRead then begin
    Raise(ecStreamReadNotSupported);
    CheckRead := false;
  end;
end;

function TFileStream.CheckWrite: boolean;
begin
  CheckWrite := true;
  if not CanWrite then begin
    Raise(ecStreamWriteNotSupported);
    CheckWrite := false;
  end;
end;

constructor TStreamReader.Create(AStream: PStream);
begin
  inherited Create;
  FStream := AStream;
end;

destructor TStreamReader.Free;
begin
  inherited Free;
end;

procedure TStreamReader.Init;
begin
  inherited Init;
  FStream := nil;
end;

procedure TTextReader.Init;
begin
  inherited Init;
end;

destructor TTextReader.Free;
begin
  inherited Free;
end;

function TTextReader.ReadLine: string;
var
  ch: char;
  line: string;
  charIndex : integer;
begin
  {TODO: this}
  FillChar(line, SizeOf(Byte), 0);
  charIndex := 1;
  while FStream^.EndOfStream do begin
    if charIndex > High(byte) then
      break;
    ch := Chr(FStream^.ReadByte);
    if ch = #13 then begin

    end;
    Inc(charIndex);
  end;
  line[0] := Chr(charIndex - 1);
end;

function TTextReader.ReadAllLines: PStringList;
begin
end;

begin
end.