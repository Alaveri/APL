{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Streams;

interface

uses
  Dos,
  Objects,
  Common,
  TPAlloc,
  MemDrv;

const
  DefaultFileStreamBufferSize: word = 4096;

type
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

  PStream = ^TStream;
  TStream = object(TObject)
  private
    _status: TStreamStatus;
    _length: longint;
    _closed: boolean;
  public
    Position: longint;
    Error: TError;
    destructor Done; virtual;
    function Length: longint; virtual;
    function Status: TStreamStatus; virtual;
    function EndOfStream: boolean; virtual;
    function CanRead: boolean; virtual;
    function CanWrite: boolean; virtual;
    function CanSeek: boolean; virtual;
    function Read(buffer: PByte; count: longint): longint; virtual;
    function ReadByte: byte; virtual;
    function ReadInteger: integer; virtual;
    function ReadWord: word; virtual;
    function Write(buffer: PByte; count: longint): longint; virtual;
    function FillChar(count: longint; ch: char): longint; virtual;
    function Seek(offset: longint; origin: TSeekOrigin): longint; virtual;
    function WriteToStream(stream: TStream; count: longint): longint; virtual;
    function ReadFromStream(stream: TStream; count: longint): longint; virtual;
    procedure Init; virtual;
    procedure Close; virtual;
    procedure Flush; virtual;
    procedure WriteByte(value: byte); virtual;
    procedure WriteInteger(value: integer); virtual;
    procedure WriteWord(value: word); virtual;
    function GetTypeName: string; virtual;
  end;

  PMemoryStream = ^TMemoryStream;
  TMemoryStream = object(TStream)
  private
    _references: PReferenceList;
  public
    constructor Create(size: longint);
    destructor Done; virtual;
    function Read(buffer: PByte; count: longint): longint; virtual;
    function Write(buffer: PByte; count: longint): longint; virtual;
    function FillChar(count: longint; ch: char): longint; virtual;
    function ReadByte: byte; virtual;
    function ReadInteger: integer; virtual;
    function ReadWord: word; virtual;
    function WriteToStream(stream: TStream; count: longint): longint; virtual;
    function ReadFromStream(stream: TStream; count: longint): longint; virtual;
    function GetTypeName: string; virtual;
    function CanRead: boolean; virtual;
    function CanWrite: boolean; virtual;
    function CanSeek: boolean; virtual;
    procedure Init; virtual;
    procedure WriteByte(value: byte); virtual;
    procedure WriteInteger(value: integer); virtual;
    procedure WriteWord(value: word); virtual;
  end;

  TFileStreamMode =
  (
    fmRead,
    fmWrite,
    fmReadWrite
  );

  PFileStream = ^TFileStream;
  TFileStream = object(TStream)
  private
    _mode: TFileStreamMode;
    _file: file;
    _open: boolean;
    _buffer: PByte;
    _bufferPos: word;
    _filename: string;
    _bufferSize: word;
    function CheckOpen: boolean;
    function CheckRead: boolean;
    function CheckWrite: boolean;
  public
    constructor Create(filename: string; mode: TFileStreamMode);
    constructor CreateBufferSize(filename: string; mode: TFileStreamMode; bufferSize: word);
    destructor Done; virtual;
    function Read(buffer: PByte; count: longint): longint; virtual;
    function Write(buffer: PByte; count: longint): longint; virtual;
    function FillChar(count: longint; ch: char): longint; virtual;
    function ReadByte: byte; virtual;
    function ReadInteger: integer; virtual;
    function ReadWord: word; virtual;
    function WriteToStream(stream: TStream; count: longint): longint; virtual;
    function ReadFromStream(stream: TStream; count: longint): longint; virtual;
    function GetTypeName: string; virtual;
    function CanRead: boolean; virtual;
    function CanWrite: boolean; virtual;
    function CanSeek: boolean; virtual;
    function Seek(offset: longint; origin: TSeekOrigin): longint; virtual;
    procedure Init; virtual;
    procedure Flush; virtual;
    procedure WriteByte(value: byte); virtual;
    procedure WriteInteger(value: integer); virtual;
    procedure WriteWord(value: word); virtual;
    procedure Open; virtual;
    procedure Close; virtual;
  end;


implementation

destructor TStream.Done;
begin
  Close;
end;

function TStream.Length: longint;
begin
  Length := _length;
end;

function TStream.Status: TStreamStatus;
begin
  Status := status;
end;

function TStream.EndOfStream: boolean;
begin
  EndOfStream := Position > _length;
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

function TStream.Read(buffer: PByte; count: longint): longint;
begin
end;

function TStream.Write(buffer: PByte; count: longint): longint;
begin
end;

function TStream.FillChar(count: longint; ch: char): longint;
begin
end;

function TStream.Seek(offset: longint; origin: TSeekOrigin): longint;
var
  newPos: longint;
begin
  case origin of
    soFromBeginning: begin
      newPos := offset;
    end;
    soFromEnd: begin
      newPos := length - offset - 1;
    end;
    soFromPosition: begin
      newPos := Position + offset;
    end;
  end;
  Position := MinL(MaxL(0, newPos), length);
end;

function TStream.ReadByte: byte;
begin
end;

function TStream.ReadInteger: integer;
begin
end;

function TStream.ReadWord: word;
begin
end;

function TStream.WriteToStream(stream: TStream; count: longint): longint;
begin
end;

function TStream.ReadFromStream(stream: TStream; count: longint): longint;
begin
end;

procedure TStream.Init;
begin
  inherited Init;
  ClearError(Error);
  Position := 0;
  _status := ssEndOfStream;
  _length := 0;
  _closed := true;
end;

function TStream.GetTypeName;
begin
  GetTypeName := 'TStream';
end;

procedure TStream.Close;
begin
  Flush;
  _closed := true;
end;

procedure TStream.Flush;
begin
end;

procedure TStream.WriteByte(value: byte);
begin
end;

procedure TStream.WriteInteger(value: integer);
begin
end;

procedure TStream.WriteWord(value: word);
begin
end;

constructor TMemoryStream.Create(size: longint);
var
  index: integer;
  reference: PReference;
  allocated: longint;
  MaxVarSizeSize: longint;
  blocks: longint;
  ptr: pointer;
  blockSize: longint;
begin
  Init;
  _status := ssOk;
  ClearError(error);
  Memory^.BeginAllocTransaction;
  blocks := size div MaxVarSize + 1;
  allocated := 0;
  for index := 0 to blocks - 1 do begin
    blockSize := MaxVarSize;
    if (size - allocated) < MaxVarSize then begin
      blockSize := size - allocated;
    end;
    Memory^.Alloc(reference, blockSize);
    Inc(_length, blockSize);
    Inc(allocated, blockSize);
    _references^.Add(reference);
    if (Memory^.Error.ErrorCode <> ecNone) then begin
      Memory^.RollbackAllocTransaction;
      error := Memory^.Error;
      exit;
    end;
  end;
  Memory^.CommitAllocTransaction;
  for index := 0 to blocks - 1 do begin
    reference :=_references^.GetItem(index);
    ptr := Memory^.ReferencePointer(reference);
    FillCharLarge(ptr^, reference^.Size, 0);
  end;
end;

destructor TMemoryStream.Done;
var
  index: integer;
  reference: PReference;
begin
  for index := _references^.Count - 1 downto 0 do begin
    reference := _references^.GetItem(index);
    Memory^.DeAlloc(reference);
  end;
  Dispose(_references, Done);
end;

function TMemoryStream.Read(buffer: PByte; count: longint): longint;
var
  bytesRead: longint;
  index: integer;
  referencePos: longint;
  reference: PReference;
  readSize: longint;
  ptr: PByte;
begin
  if (Position >= _length) then begin
    CreateError(Error, ecReadPastStreamEnd, esWarning);
    Read := 0;
    exit;
  end;

  bytesRead := 0;
  while (bytesRead < count) do begin
    index := Position div MaxVarSize;
    referencePos := Position mod MaxVarSize;
    reference := _references^.GetItem(index);
    readSize := MinL(reference^.Size - referencePos, count - bytesRead);
    if (Position + readSize > _length) then begin
      CreateError(Error, ecReadPastStreamEnd, esWarning);
      readSize := _length - Position;
      Read := bytesRead + readSize;
      exit;
    end;
    ptr := Memory^.ReferencePointer(reference);
    Inc(ptr, referencePos);
    Move(ptr^, buffer^, readSize);
    Inc(buffer, readSize);
    Inc(bytesRead, readSize);
    Inc(Position, readSize);
    if (Position > _length) then begin
      CreateError(Error, ecReadPastStreamEnd, esWarning);
      break;
    end;
  end;
  Read := bytesRead;
end;

function TMemoryStream.FillChar(count: longint; ch: char): longint;
var
  index: integer;
  written: longint;
  reference: PReference;
  referencePos: longint;
  writeSize: longint;
  ptr: PByte;
begin
  if (Position >= _length) then begin
    CreateError(Error, ecWritePastStreamEnd, esWarning);
    exit;
  end;

  written := 0;
  while (written < count) do begin
    index := Position div MaxVarSize;
    referencePos := Position mod MaxVarSize;
    reference := _references^.GetItem(index);
    writeSize := MinL(reference^.Size - referencePos, count - written);
    if (Position + writeSize >= _length) then begin
      CreateError(Error, ecWritePastStreamEnd, esWarning);
      writeSize := _length - Position;
    end;
    ptr := Memory^.ReferencePointer(reference);
    Inc(ptr, referencePos);
    System.FillChar(ch, ptr^, writeSize);
    Inc(written, writeSize);
    Inc(Position, writeSize);
    if (Position > _length) then begin
      CreateError(Error, ecWritePastStreamEnd, esWarning);
      break;
    end;
  end;
  FillChar := written;
end;

function TMemoryStream.Write(buffer: PByte; count: longint): longint;
var
  index: integer;
  written: longint;
  reference: PReference;
  referencePos: longint;
  writeSize: longint;
  ptr: PByte;
begin
  if (Position >= _length) then begin
    CreateError(Error, ecWritePastStreamEnd, esWarning);
    exit;
  end;

  written := 0;
  while (written < count) do begin
    index := Position div MaxVarSize;
    referencePos := Position mod MaxVarSize;
    reference := _references^.GetItem(index);
    writeSize := MinL(reference^.Size - referencePos, count - written);
    if (Position + writeSize > _length) then begin
      CreateError(Error, ecWritePastStreamEnd, esWarning);
      writeSize := _length - Position;
    end;
    ptr := Memory^.ReferencePointer(reference);
    Inc(ptr, referencePos);
    Move(buffer^, ptr^, writeSize);
    Inc(buffer, writeSize);
    Inc(written, writeSize);
    Inc(Position, writeSize);
    if (Position > _length) then begin
      CreateError(Error, ecWritePastStreamEnd, esWarning);
      break;
    end;
  end;
  Write := written;
end;

function TMemoryStream.ReadByte: byte;
var
  index, referencePos: longint;
  reference: PReference;
  ptr: PByte;
begin
  ReadByte := 0;
  if (Position >= _length) then begin
    CreateError(Error, ecReadPastStreamEnd, esWarning);
    exit;
  end;

  index := Position div MaxVarSize;
  referencePos := Position mod MaxVarSize;
  reference := _references^.GetItem(index);
  ptr := Memory^.ReferencePointer(reference);
  Inc(ptr, referencePos);
  Inc(Position);
  ReadByte := ptr^;
end;

function TMemoryStream.ReadInteger: integer;
var
  buffer: integer;
begin
  Read(@buffer, 2);
  if (Error.ErrorCode <> ecNone) then
    ReadInteger := 0
  else
    ReadInteger := buffer;
end;

function TMemoryStream.ReadWord: word;
var
  buffer: word;
begin
  Read(@buffer, 2);
  if (Error.ErrorCode <> ecNone) then
    ReadWord := 0
  else
    ReadWord := buffer;
end;

function TMemoryStream.WriteToStream(stream: TStream; count: longint): longint;
begin
end;

function TMemoryStream.ReadFromStream(stream: TStream; count: longint): longint;
begin
end;

procedure TMemoryStream.Init;
begin
  inherited Init;
  _references := New(PReferenceList, Create);
end;

procedure TMemoryStream.WriteByte(value: byte);
var
  index, referencePos: longint;
  reference: PReference;
  ptr: PByte;
begin
  if (Position >= _length) then begin
    CreateError(Error, ecWritePastStreamEnd, esWarning);
    exit;
  end;

  index := Position div MaxVarSize;
  referencePos := Position mod MaxVarSize;
  reference := _references^.GetItem(index);
  ptr := Memory^.ReferencePointer(reference);
  Inc(ptr, referencePos);
  Inc(Position);
  ptr^ := value;
end;

procedure TMemoryStream.WriteInteger(value: integer);
begin
  Write(@value, 2);
end;

procedure TMemoryStream.WriteWord(value: word);
begin
  Write(@value, 2);
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

function TMemoryStream.GetTypeName;
begin
  GetTypeName := 'TMemoryStream';
end;

constructor TFileStream.Create(filename: string; mode: TFileStreamMode);
begin
  _mode := mode;
  _open := false;
  GetMem(_buffer, DefaultFileStreamBufferSize);
  _bufferSize := DefaultFileStreamBufferSize;
  _bufferPos := 0;
  _filename := filename;
  Open;
end;

constructor TFileStream.CreateBufferSize(filename: string; mode: TFileStreamMode; bufferSize: word);
begin
  _mode := mode;
  _open := false;
  GetMem(_buffer, bufferSize);
  _bufferSize := bufferSize;
  _bufferPos := 0;
  _filename := filename;
  Open;
end;

destructor TFileStream.Done;
begin
  if (_buffer <> nil) then
    FreeMem(_buffer, _bufferSize);
end;

function TFileStream.Read(buffer: PByte; count: longint): longint;
begin
  if (not CheckOpen) then exit;
  if (not CheckRead) then exit;
end;

function TFileStream.Write(buffer: PByte; count: longint): longint;
begin
  if (not CheckOpen) then exit;
  if (not CheckWrite) then exit;
end;

function TFileStream.FillChar(count: longint; ch: char): longint;
begin
  if (not CheckOpen) then exit;
end;

function TFileStream.ReadByte: byte;
begin
  if (not CheckOpen) then exit;
  if (not CheckRead) then exit;
end;

function TFileStream.ReadInteger: integer;
begin
  if (not CheckOpen) then exit;
  if (not CheckRead) then exit;
end;

function TFileStream.ReadWord: word;
begin
  if (not CheckOpen) then exit;
  if (not CheckRead) then exit;
end;

function TFileStream.WriteToStream(stream: TStream; count: longint): longint;
begin
  if (not CheckOpen) then exit;
  if (not CheckWrite) then exit;
end;

function TFileStream.ReadFromStream(stream: TStream; count: longint): longint;
begin
  if (not CheckOpen) then exit;
  if (not CheckRead) then exit;
end;

function TFileStream.GetTypeName: string;
begin
  GetTypeName := 'TFileStream';
end;

function TFileStream.CanRead: boolean;
begin
  CanRead := (_mode = fmRead) or (_mode = fmReadWrite);
end;

function TFileStream.CanWrite: boolean;
begin
  CanWrite := (_mode = fmWrite) or (_mode = fmReadWrite);
end;

function TFileStream.CanSeek: boolean;
begin
  CanSeek := true;
end;

procedure TFileStream.Init;
begin
  inherited init;
  _mode := fmReadWrite;
  _open := false;
  _buffer := nil;
  _bufferPos := 0;
  _filename := '';
end;

procedure TFileStream.Flush;
begin
end;

procedure TFileStream.WriteByte(value: byte);
begin
  if (not CheckOpen) then exit;
  if (not CheckWrite) then exit;
end;

procedure TFileStream.WriteInteger(value: integer);
begin
  if (not CheckOpen) then exit;
  if (not CheckWrite) then exit;
end;

procedure TFileStream.WriteWord(value: word);
begin
  if (not CheckOpen) then exit;
  if (not CheckWrite) then exit;
end;

function TFileStream.Seek(offset: longint; origin: TSeekOrigin): longint;
begin
  inherited Seek(offset, origin);
  {$I+}
  System.Seek(_file, Position);
  if (IOResult <> 0) then
    CreateError(Error, ecStreamSeekError, esError);
  {$I-}
end;

procedure TFileStream.Open;
begin
  if (_open) then exit;
  Assign(_file, _filename);
  {$I-}
  if (FileExists(_filename)) then begin
    case _mode of
      fmRead, fmReadWrite: begin
        Reset(_file, 1);
        _length := FileSize(_file);
      end;
      fmWrite: Rewrite(_file, 1);
    end;
  end
  else begin
    case _mode of
      fmRead, fmReadWrite: CreateError(Error, ecFileNotFound, esError);
      fmWrite: Rewrite(_file, 1);
    end;
  end;
  if (IOResult <> 0) then
    CreateError(Error, ecStreamWriteError, esError);
  if (Error.ErrorCode = ecNone) then
    _open := true;
  {$I+}
end;

procedure TFileStream.Close;
begin
  {$I-}
  if (_open) then
    System.Close(_file);
  {$I+}
  if (IOResult <> 0 ) then
    CreateError(error, ecStreamCloseError, esError);
end;

function TFileStream.CheckOpen: boolean;
begin
  CheckOpen := true;
  if (not _open) then begin
    CreateError(Error, ecStreamNotOpen, esError);
    CheckOpen := false;
  end;
end;

function TFileStream.CheckRead: boolean;
begin
  CheckRead := true;
  if (not CanRead) then begin
    CreateError(Error, ecStreamReadNotSupported, esError);
    CheckRead := false;
  end;
end;

function TFileStream.CheckWrite: boolean;
begin
  CheckWrite := true;
  if (not CanWrite) then begin
    CreateError(Error, ecStreamWriteNotSupported, esError);
    CheckWrite := false;
  end;
end;

begin
end.