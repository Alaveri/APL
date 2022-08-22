{$I COMPILER.INC}
unit Streams;

interface

uses
  Dos,
  Objects,
  Utils,
  TPAlloc,
  MemDrv;

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
    function Write(buffer: PByte; count: longint): longint; virtual;
    function FillChar(count: longint; ch: char): longint; virtual;
    function Seek(offset: longint; origin: TSeekOrigin): longint; virtual;
    function ReadByte: byte; virtual;
    function WriteToStream(stream: TStream; count: longint): longint; virtual;
    function ReadFromStream(stream: TStream; count: longint): longint; virtual;
    procedure Init; virtual;
    procedure Close; virtual;
    procedure Flush; virtual;
    procedure SetLength(newLength: longint); virtual;
    procedure WriteByte; virtual;
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
    function WriteToStream(stream: TStream; count: longint): longint; virtual;
    function ReadFromStream(stream: TStream; count: longint): longint; virtual;
    function GetTypeName: string; virtual;
    function CanRead: boolean; virtual;
    function CanWrite: boolean; virtual;
    function CanSeek: boolean; virtual;
    procedure Init; virtual;
    procedure SetLength(newLength: longint); virtual;
    procedure WriteByte; virtual;
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

procedure TStream.SetLength(newLength: longint);
begin
end;

procedure TStream.WriteByte;
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

procedure TMemoryStream.SetLength(newLength: longint);
begin
end;

procedure TMemoryStream.WriteByte;
begin
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


begin
end.