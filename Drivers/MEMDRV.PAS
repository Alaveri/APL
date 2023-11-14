{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit MemDrv;

interface

uses
  Objects,
  Except,
  Common,
  Collects,
  Dos;

const
  MaxVarSize = $FFF0;

type
  PReferenceList = ^TReferenceList;
  PReference = ^TReference;

  TReferenceList = object(TList)
    destructor Free; virtual;
    function GetItem(AIndex: integer): PReference;
    function IndexOf(AItem: PReference): integer;
    function Add(AItem: PReference): integer;
    procedure Clear; virtual;
    procedure Insert(AIndex: integer; AItem: PReference);
  end;

  TReference = record
    Size: word;
    case Xms: boolean of
      true: (Handle: word; Unused: word);
      false: (Ptr: Pointer);
  end;

  PXmsMoveRecord = ^TXmsMoveRecord;
  TXmsMoveRecord = record
    Length: longint;
    case boolean of
      true: (Unused1: word; SourcePointer: pointer; DestHandle: word; DestOffset: longint);
      false: (SourceHandle: word; SourceOffset: longint; Unused2: word; DestPointer: pointer);
  end;

  PMemoryDriver = ^TMemoryDriver;
  TMemoryDriver = object(TExceptionObject)
  private
    FXmsSupported: boolean;
    FReferences: PReferenceList;
    FCurrentReference: PReference;
    FXmsEnabled: boolean;
    FXmsVersion: real;
    FTransactionReferences: PReferenceList;
    function GetXmsControlFunction: pointer;
    function XmsAlloc(ASize: word): word;
    procedure XmsDealloc(AHandle: word);
    procedure MoveReference(AMoveRecord: PXmsMoveRecord);
    procedure MoveToConventional(AReference: PReference);
    procedure PurgeConventional(ASize: longint);
  public
    constructor Create;
    destructor Free; virtual;
    function XmsSupported: boolean;
    function XmsEnabled: boolean;
    function XmsMaxAvail: longint;
    function XmsVersion: real;
    function References: PReferenceList;
    function CurrentReference: PReference;
    function ReferencePointer(AReference: PReference): pointer;
    function Alloc(ASize: word): Preference;
    procedure InitXms;
    procedure Init; virtual;
    procedure SetCurrentReference(AReference: PReference);
    procedure Dealloc(var AReference: PReference);
    procedure BeginAllocTransaction;
    procedure CommitAllocTransaction;
    procedure RollbackAllocTransaction;
    procedure FreeReference(AReference: PReference);
    procedure Fill(AReference: PReference; AByte: byte);
    {$IFDEF debug}
    procedure DebugFreeHandles;
    procedure DebugWriteHandles(ANewHandle: word);
    {$ENDIF}
  end;

var
  Memory: TMemoryDriver;
  OutOfMemoryException: PException;
  XmsControl: pointer;
  MoveRecord: TXmsMoveRecord;

implementation

const
  HiWord = 1;
  LoWord = 2;
  DebugFilename = 'XmsDebug.bin';

var
  MemoryInitialized: boolean;


function OnHeapError(ASize: word): integer;
var
  minSize: longint;
begin
  { Default to return nil on error }
  OnHeapError := 1;
  if ASize = 0 then begin
    OnHeapError := 2;
    exit;
  end;

  { Return nil if Memory driver is not initialized }
  if not MemoryInitialized then
    exit;

  { Purge conventional references until there is ASize avail + enough space
  for at least 1 reference to be swapped }
  minSize := longint(ASize) + MaxVarSize + SizeOf(TReference);
  Memory.PurgeConventional(minSize);

  { If enough could not be purged, return nil }
  if System.MaxAvail < minSize then
    exit;

  { Flag as now available and retry }
  OnHeapError := 2;
end;

constructor TMemoryDriver.Create;
begin
  inherited Create;
end;

{$IFDEF debug}
{ If compiling in debug mode, this writes XMS handles to a file called
XmsDebug.bin as they are allocated, so if the program crashes or is reset
while debugging, XMS handles will be deallocated on startup by reading the
handles from the file }
procedure TMemoryDriver.DebugWriteHandles(ANewHandle: word);
var
  index: integer;
  reference: PReference;
  debugFile: Text;
begin
  {$I-}
  System.Assign(debugFile, DebugFilename);
  Rewrite(debugFile);
  for index := 0 to FReferences^.Count - 1 do begin
    reference := FReferences^.GetItem(index);
    if not reference^.Xms then
      continue;
    WriteLn(debugFile, WordToStr(reference^.Handle));
  end;
  WriteLn(debugFile, WordToStr(ANewHandle));
  Close(debugFile);
  {$I+}
end;
{$ENDIF}

{$IFDEF debug}
{ If compiling in Debug mode, this reads previously allocated XMS handles
from a file called XmsDebug.bin and deallocates them.  That way if the program
crashes or is reset during debugging and the Memory.Free wasn't called to
deallocate XMS handles, this will deallocate them on startup }
procedure TMemoryDriver.DebugFreeHandles;
var
  debugFile: Text;
  handleStr: string;
  handle: word;
  code: integer;
begin
  if not FileExists(debugFilename) then
    exit;
  if not XmsSupported then
    exit;

  XmsControl := GetXmsControlFunction;
  if XmsControl = nil then
    exit;

  System.Assign(debugFile, debugFilename);
  {$I-}
  Reset(debugFile);
  while not Eof(debugFile) do begin
    ReadLn(debugFile, handleStr);
    if IOResult <> 0 then
      continue;
    Val(handleStr, handle, code);

    if code <> 0 then
      continue;
    XmsDealloc(handle);
  end;
  System.Close(debugFile);
  {$I+}
end;
{$ENDIF}

function TMemoryDriver.References: PReferenceList;
begin
  References := FReferences;
end;

function TMemoryDriver.XmsEnabled: boolean;
begin
  XmsEnabled := FXmsEnabled;
end;

function TMemoryDriver.XmsSupported: boolean;
var
  reg: Registers;
  result: byte;
begin
  asm
    mov ax, 4300h
    int 2Fh
    mov [result], al
  end;
  XmsSupported := result = $80;
end;

procedure TMemoryDriver.InitXms;
var
  version: word;
  code: integer;
  hex: string;
  kbytes: word;
begin
  FXmsEnabled := false;
  FXmsSupported := XmsSupported;
  if not XmsSupported then
    exit;

  XmsControl := GetXmsControlFunction;
  if XmsControl = nil then
    exit;

  {$IFDEF debug}
  DebugFreeHandles;
  {$ENDIF}

  XmsControl := GetXmsControlFunction;
  asm
    { Get XMS version }
    mov ah, 00h
    call [XmsControl]
    mov [version], ax
  end;

  FXmsEnabled := true;
  hex := Copy(IntToHex(version),  3, 3);
  Val(hex, FXmsVersion, code);
  FXmsVersion := FXmsVersion / 100;
end;

function TMemoryDriver.GetXmsControlFunction: pointer;
var
  result: pointer;
begin
  asm
    push es
    mov ax, 4310h
    int 2Fh
    mov word ptr [result], bx
    mov word ptr [result + 2], es
    pop es
  end;
  GetXmsControlFunction := result;
end;

function TMemoryDriver.CurrentReference: PReference;
begin
  CurrentReference := FCurrentReference;
end;

procedure TMemoryDriver.MoveReference(AMoveRecord: PXmsMoveRecord);
var
  result: word;
  xmsError: byte;
begin
  asm
    push ds
    push si
    lds si, AMoveRecord
    mov ah, 0Bh
    call [XmsControl]
    mov [result], ax
    mov [xmsError], bl
    pop si
    pop ds
  end;
  if result <> 1 then
    Raise(ecXmsError);
end;

procedure TMemoryDriver.PurgeConventional(ASize: longint);
var
  index: integer;
  current: PReference;
  xmsHandle: word;
begin
  { If there is no XMS available or there are no references to move, then error }
  if (FReferences^.Count = 0) or not XmsEnabled then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  index := 0;

  { Swap any conentional references to XMS until there is enough available
  or there are no more references that cna be moved }
  while (index < FReferences^.Count) and (System.MaxAvail < ASize) do begin
    current := FReferences^.GetItem(index);
    Inc(index);
    if current^.Xms then
      continue;
    xmsHandle := XmsAlloc(current^.Size);

    { If no handle returned, then XMS does not have enough space, so error }
    if xmsHandle = 0 then begin
      Raise(ecNotEnoughMemory);
      exit;
    end;

    FillChar(MoveRecord, SizeOf(TXmsMoveRecord), 0);
    with moveRecord do begin
      Length := current^.Size;
      SourcePointer := current^.Ptr;
      DestHandle := xmsHandle;
    end;
    MoveReference(@MoveRecord);

    { If there was an exception thrown during the move, then error }
    if HasException then
      exit;
    FreeMem(current^.Ptr, current^.Size);
    current^.Ptr := nil;
    current^.Xms := true;
    current^.Handle := xmsHandle;
  end;
end;

procedure TMemoryDriver.MoveToConventional(AReference: PReference);
var
  ptr: pointer;
begin
  PurgeConventional(AReference^.Size);

  GetMem(ptr, AReference^.Size);
  if ptr = nil then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;

  FillChar(MoveRecord, SizeOf(TXmsMoveRecord), 0);
  with moveRecord do begin
    Length := AReference^.Size;
    SourceHandle := AReference^.Handle;
    DestPointer := ptr;
  end;

  MoveReference(@MoveRecord);
  if HasException then begin
    FreeMem(ptr, AReference^.Size);
    exit;
  end;

  XmsDealloc(AReference^.Handle);
  AReference^.Ptr := ptr;
  AReference^.Xms := false;
  FCurrentReference := AReference;
end;

function TMemoryDriver.XmsMaxAvail: longint;
var
  kbytes: word;
begin
  XmsMaxAvail := 0;
  if not FXmsSupported then
    exit;
  asm
    mov ah, 08h
    call [XmsControl]
    mov [kbytes], dx
  end;
  XmsMaxAvail := longint(kbytes) * 1024;
end;

procedure TMemoryDriver.SetCurrentReference(AReference: PReference);
begin
  if FCurrentReference = AReference then
    exit;
  FCurrentReference := AReference;
  if not AReference^.Xms then
    exit;
  MoveToConventional(AReference);
end;

function TMemoryDriver.ReferencePointer(AReference: PReference): pointer;
begin
  SetCurrentReference(AReference);
  if HasException then
    exit;
  ReferencePointer := AReference^.Ptr;
end;

function TMemoryDriver.XmsAlloc(ASize: word): word;
var
  xmsResult: word;
  xmsError: byte;
  xmsSize: word;
  xmsHandle: word;
begin
  XmsAlloc := 0;
  xmsSize := ASize div 1024;
  xmsHandle := 0;
  xmsResult := 0;
  xmsError := 0;
  if (ASize mod 1024 > 0) then
    Inc(xmsSize, 1);
  asm
    mov ah, 09h
    mov dx, [xmsSize]
    call [XmsControl]
    mov [xmsResult], ax
    mov [xmsHandle], dx
    mov [xmsError], bl
  end;
  if (xmsError > 0) or (xmsResult = 0) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  {$IFDEF debug}
  DebugWriteHandles(xmsHandle);
  {$ENDIF}
  XmsAlloc := xmsHandle;
end;

procedure TMemoryDriver.XmsDealloc(AHandle: word);
begin
  asm
    mov ah, 0Ah
    mov dx, [AHandle]
    call [XmsControl]
  end;
end;

function TMemoryDriver.Alloc(ASize: word): PReference;
var
  reference: PReference;
  ptr: pointer;
begin
  if ASize = 0 then begin
    Raise(ecInvalidAllocSize);
    exit;
  end;
  reference := New(PReference);
  if reference = nil then begin
    Raise(ecNotEnoughMemory);
    Alloc := nil;
    exit;
  end;
  reference^.Size := ASize;
  reference^.Ptr := nil;
  if ASize <= System.MaxAvail then begin
    GetMem(ptr, ASize);
    if ptr = nil then begin
      Raise(ecNotEnoughMemory);
      exit;
    end;
    reference^.Ptr := ptr;
    reference^.Size := ASize;
    reference^.Xms := false;
  end
  else if FXmsEnabled and (ASize <= XmsMaxAvail) then begin
    reference^.Handle := XmsAlloc(ASize);
    if reference^.Handle = 0 then begin
      Raise(ecNotEnoughMemory);
      Dispose(reference);
      Alloc := nil;
      exit;
    end;
    reference^.Size := ASize;
    reference^.Xms := true;
  end
  else begin
    Raise(ecNotEnoughMemory);
    Dispose(reference);
    Alloc := nil;
    exit;
  end;
  FReferences^.Add(reference);
  if (FTransactionReferences <> nil) then
    FTransactionReferences^.Add(reference);
  Alloc := reference;
end;

procedure TMemoryDriver.FreeReference(AReference: PReference);
var
  xmsResult: word;
  xmsError: byte;
  xmsHandle: word;
  index: integer;
begin
  if AReference = nil then
    exit;
  index := FReferences^.IndexOf(AReference);
  if (index < 0) or (index > FReferences^.Count - 1) then
    exit;
  if AReference^.Xms then
    XmsDealloc(AReference^.Handle)
  else
    FreeMem(AReference^.Ptr, AReference^.Size);
  Dispose(AReference);
  FReferences^.Delete(index);
end;

procedure TMemoryDriver.Dealloc(var AReference: PReference);
begin
  FreeReference(AReference);
  AReference := nil;
end;

function TMemoryDriver.XmsVersion: real;
begin
  XmsVersion := FXmsVersion;
end;

destructor TMemoryDriver.Free;
var
  handle: word;
begin
  FreeAndNil(OutOfMemoryException);
  while FReferences^.Count > 0 do
    FreeReference(FReferences^.GetItem(0));
  inherited Free;
end;

procedure TMemoryDriver.BeginAllocTransaction;
begin
  FTransactionReferences := New(PReferenceList, Create);
end;

procedure TMemoryDriver.Fill(AReference: PReference; AByte: byte);
var
  ptr: PByte;
begin
  ptr := ReferencePointer(AReference);
  FillByteLarge(ptr, AReference^.Size, AByte);
end;

procedure TMemoryDriver.CommitAllocTransaction;
begin
  FreeAndNil(FTransactionReferences);
end;

procedure TMemoryDriver.RollbackAllocTransaction;
var
  current: PReference;
begin
  if FTransactionReferences = nil then
    exit;
  while (FTransactionReferences^.Count > 0) do begin
    current := FReferences^.GetItem(0);
    FreeReference(current);
    FTransactionReferences^.Delete(0);
  end;
  Dispose(FTransactionReferences, Free);
end;

procedure TMemoryDriver.Init;
var
  reference: PReference;
  size: word;
begin
  inherited Init;
  OutOfMemoryException := New(PException, Create(ecNotEnoughMemory));
  { references are always sorted by Xms flag and Offset ascending }
  FReferences := New(PReferenceList, Create);
  FCurrentReference := nil;
  FXmsSupported := false;
  FXmsVersion := 0;
  FTransactionReferences := nil;
  HeapError := @OnHeapError;
  XmsControl := nil;
  InitXms;
  MemoryInitialized := true;
end;

procedure TReferenceList.Clear;
begin
  while Count > 0 do
    Delete(0);
end;

destructor TReferenceList.Free;
begin
  inherited Free;
end;

function TReferenceList.GetItem(AIndex: integer): PReference;
begin
  GetItem := TList.GetItem(AIndex);
end;

function TReferenceList.IndexOf(AItem: PReference): integer;
begin
  IndexOf := TList.IndexOf(AItem);
end;

function TReferenceList.Add(AItem: PReference): integer;
begin
  Add := TList.Add(AItem);
end;

procedure TReferenceList.Insert(AIndex: integer; AItem: PReference);
begin
  TList.Insert(AIndex, AItem);
end;

begin
  MemoryInitialized := false;
end.