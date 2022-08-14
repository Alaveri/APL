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
    _position: longint;
    _status: TStreamStatus;
    _length: longint;
    _canRead, _canWrite, _canSeek: boolean;
    _closed: boolean;
  public
    Error: TError;
    destructor Done; virtual;
    function Position: longint; virtual;
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
    procedure Init; virtual;
    procedure SetLength(newLength: longint); virtual;
    procedure WriteByte; virtual;
  end;

implementation

destructor TStream.Done;
begin
  Close;
end;

function TStream.Position: longint;
begin
  Position := _position;
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
  EndOfStream := _position > _length;
end;

function TStream.CanRead: boolean;
begin
  CanRead := _canRead;
end;

function TStream.CanWrite: boolean;
begin
  CanWrite := _canWrite;
end;

function TStream.CanSeek: boolean;
begin
  CanSeek := _canSeek;
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
      newPos := _position + offset;
    end;
  end;
  _position := MinL(MaxL(0, newPos), length - 1);
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
  _position := 0;
  _status := ssEndOfStream;
  _length := 0;
  _canRead := false;
  _canWrite := false;
  _canSeek := false;
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
  for index := _references^.Count downto 0 do begin
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
  if (_position >= _length - 1) then begin
    CreateError(Error, ecReadPastStreamEnd, esWarning);
    exit;
  end;

  bytesRead := 0;
  while (bytesRead < count) do begin
    index := _position div MaxVarSize;
    referencePos := _position mod MaxVarSize;
    reference := _references^.GetItem(index);
    readSize := MinL(reference^.Size - referencePos, count - bytesRead);
    if (_position + readSize > _length - 1) then begin
      CreateError(Error, ecReadPastStreamEnd, esWarning);
      readSize := _length - _position;
    end;
    ptr := Memory^.ReferencePointer(reference);
    Inc(ptr, referencePos);
    Move(ptr^, buffer^, readSize);
    Inc(buffer, readSize);
    Inc(bytesRead, readSize);
    Inc(_position, readSize);
    if (_position > _length - 1) then begin
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
  if (_position >= _length - 1) then begin
    CreateError(Error, ecWritePastStreamEnd, esWarning);
    exit;
  end;

  written := 0;
  while (written < count) do begin
    index := _position div MaxVarSize;
    referencePos := _position mod MaxVarSize;
    reference := _references^.GetItem(index);
    writeSize := MinL(reference^.Size - referencePos, count - written);
    if (_position + writeSize > _length - 1) then begin
      CreateError(Error, ecWritePastStreamEnd, esWarning);
      writeSize := _length - _position;
    end;
    ptr := Memory^.ReferencePointer(reference);
    Inc(ptr, referencePos);
    System.FillChar(ch, ptr^, writeSize);
    Inc(written, writeSize);
    Inc(_position, writeSize);
    if (_position > _length - 1) then begin
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
  if (_position >= _length - 1) then begin
    CreateError(Error, ecWritePastStreamEnd, esWarning);
    exit;
  end;

  written := 0;
  while (written < count) do begin
    index := _position div MaxVarSize;
    referencePos := _position mod MaxVarSize;
    reference := _references^.GetItem(index);
    writeSize := MinL(reference^.Size - referencePos, count - written);
    if (_position + writeSize > _length - 1) then begin
      CreateError(Error, ecWritePastStreamEnd, esWarning);
      writeSize := _length - _position;
    end;
    ptr := Memory^.ReferencePointer(reference);
    Inc(ptr, referencePos);
    Move(buffer^, ptr^, writeSize);
    Inc(buffer, writeSize);
    Inc(written, writeSize);
    Inc(_position, writeSize);
    if (_position > _length - 1) then begin
      CreateError(Error, ecWritePastStreamEnd, esWarning);
      break;
    end;
  end;
  Write := written;
end;

function TMemoryStream.ReadByte: byte;
begin
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

function TMemoryStream.GetTypeName;
begin
  GetTypeName := 'TMemoryStream';
end;


begin
end.