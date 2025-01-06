{$I COMPILER.INC}
unit MemDrv;

interface

uses
  AplTypes,
  AplObj,
  AplConst,
  AplUtils,
  AplMath,
  Lists;

type
  PReferenceList = ^TReferenceList;
  PReference = ^TReference;
  PXmsMoveRecord = ^TXmsMoveRecord;
  PMemoryDriver = ^TMemoryDriver;
  PMemoryAllocErrorProc = ^TMemoryAllocErrorProc;
  PBuffer = ^TBuffer;

  TMemoryAllocErrorProc = function(ASize: word): boolean;

  TReferenceList = object(TList)
  private
  public
    destructor Free; virtual;
    function GetItem(AIndex: integer): PReference;
    function Add(AItem: PReference): integer;
    function IndexOf(AItem: PReference): integer;
    procedure SetItem(AIndex: integer; AItem: PReference);
    procedure Insert(AIndex: integer; AItem: PReference);
  end;

  TReferenceType = (rtConventional, rtXms, rtEms, rtFile);

  TReference = record
    Size: word;
    case ReferenceType: TReferenceType of
      rtXms, rtEms: (Handle: word; Unused: word);
      rtConventional: (Ptr: pointer);
      rtFile: (Offset: longint);
  end;

  TXmsMoveRecord = record
    Length: longint;
    case boolean of
      true: (
        Unused1: word;
        SourcePointer: pointer;
        DestHandle: word;
        DestOffset: longint
      );
      false: (
        SourceHandle: word;
        SourceOffset: longint;
        Unused2: word;
        DestPointer: pointer
      );
  end;

  TMemoryDriver = object(TStatusObject)
  private
    FXmsSupported: boolean;
    FReferences: PReferenceList;
    FCurrentReference: PReference;
    FXmsVersion: real;
    FTransactionReferences: PReferenceList;
    function IsXmsSupported: boolean;
    function GetXmsControlFunction: pointer;
    function XmsAlloc(ASize: word): word;
    procedure XmsDealloc(AHandle: word);
    procedure MoveReference(var AMoveRecord: TXmsMoveRecord);
    procedure MoveToConventional(AReference: PReference);
    procedure PurgeConventional(ASize: longint);
  public
    OnAllocError: PMemoryAllocErrorProc;
    constructor Create;
    destructor Free; virtual;
    function XmsSupported: boolean;
    function XmsMaxAvail: longint;
    function XmsVersion: real;
    function References: PReferenceList;
    function CurrentReference: PReference;
    function ReferencePointer(AReference: PReference): pointer;
    function Alloc(ASize: word): Preference;
    function CreateReference(ABuffer: pointer; ASize: word): PReference;
    procedure InitXms;
    procedure Init; virtual;
    procedure SetCurrentReference(AReference: PReference);
    procedure Dealloc(var AReference: PReference);
    procedure BeginAllocTransaction;
    procedure CommitAllocTransaction;
    procedure RollbackAllocTransaction;
    procedure FreeReference(AReference: PReference);
    procedure FreeReferencePreserve(AReference: PReference);
    procedure Fill(AReference: PReference; AByte: byte);
    {$IFDEF debug}
    procedure DebugFreeHandles;
    procedure DebugWriteHandles(ANewHandle: word);
    {$ENDIF}
  end;

  TBuffer = object(TStatusObject)
  private
    procedure SetDataSize(ASize: word; AClear, APreserve: boolean);
  public
    Data: PByte;
    Size: word;
    constructor Create;
    constructor CreateSize(var ASize: word);
    constructor CreateClear(var ASize: word);
    function AsString: PChar;
    procedure SetSize(ASize: word; AClear: boolean);
    procedure SetSizePreserve(ASize: word; AClear: boolean);
    procedure SetByte(APos: word; AByte: byte);
    procedure SetChar(APos: word; AChar: char);
    procedure Move(AFrom, ATo, ALength: word);
    procedure FreeData;
    procedure Clear;
    procedure FillByte(AByte: byte; ASize: word);
    procedure FillChar(AChar: char; ASize: word);
    procedure FillAllByte(AByte: word);
    procedure FillAllChar(AChar: char);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

var
  Memory: TMemoryDriver;
  OutOfMemoryException: PException;

implementation

uses
  AplStr;

var
  PreviousExitProc: PProc;
  XmsControl: pointer;
  MoveRecord: TXmsMoveRecord;

const
  HiWord = 1;
  LoWord = 2;
  DebugFilename = 'XmsDebug.bin';

function OnHeapError(Size: word): integer; far;
var
  minSize: longint;
begin
  if Size = 0 then
    exit;

  { Default to return nil on error }
  OnHeapError := 1;

  { Purge conventional references until there is enough space }
  Memory.PurgeConventional(Size);

  { If enough could not be purged, try custom OnAllocError function.  If this
  returns false, then return 1 for "nil on error", otherwise clear
  error and retry. }
  if (System.MaxAvail < Size) or (Memory.HasException) then begin
    if Assigned(Memory.OnAllocError) and TMemoryAllocErrorProc(Memory.OnAllocError)(Size) then
      Memory.ClearException
    else
      exit;
  end;

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
    if not (reference^.ReferenceType = rtXms) then
      continue;
    WriteLn(debugFile, IntToStr(reference^.Handle));
  end;
  WriteLn(debugFile, IntToStr(ANewHandle));
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
  if not FXmsSupported then
    exit;

  XmsControl := GetXmsControlFunction;
  if not Assigned(XmsControl) then
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

function TMemoryDriver.XmsSupported: boolean;
begin
  XmsSupported := FXmsSupported;
end;

function TMemoryDriver.IsXmsSupported: boolean;
var
  result: byte;
begin
  asm
    mov ax, 4300h
    int 2Fh
    mov [result], al
  end;
  IsXmsSupported := result = $80;
end;

procedure TMemoryDriver.InitXms;
var
  version: word;
  code: integer;
  hex: string;
  kbytes: word;
begin
  FXmsSupported := IsXmsSupported;
  if not FXmsSupported then
    exit;

  XmsControl := GetXmsControlFunction;
  if not Assigned(XmsControl) then
    exit;

  {$IFDEF debug}
  DebugFreeHandles;
  {$ENDIF}

  asm
    { Get XMS version }
    mov ah, 00h
    call [XmsControl]
    mov [version], ax
  end;

  hex := Copy(IntToHex(version), 3, 3);
  Val(hex, FXmsVersion, code);
  FXmsVersion := FXmsVersion / 100;
end;

function TMemoryDriver.GetXmsControlFunction: pointer;
var
  result: pointer;
begin
  asm
    mov ax, 4310h
    int 2Fh
    mov word ptr [result], bx
    mov word ptr [result + 2], es
  end;
  GetXmsControlFunction := result;
end;

function TMemoryDriver.CurrentReference: PReference;
begin
  CurrentReference := FCurrentReference;
end;

procedure TMemoryDriver.MoveReference(var AMoveRecord: TXmsMoveRecord);
var
  result: word;
  xmsError: byte;
begin
  asm
    mov si, offset AMoveRecord
    mov ah, 0Bh
    call [XmsControl]
    mov [result], ax
    mov [xmsError], bl
  end;
  if result <> 0 then
    Raise(ecXmsError);
end;

procedure TMemoryDriver.PurgeConventional(ASize: longint);
var
  index: integer;
  current: PReference;
  xmsHandle: word;
begin
  { If there is no XMS available or there are no references to move, then error }
  if (FReferences^.Count = 0) or not FXmsSupported then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  index := 0;

  { Swap any conventional references to XMS until there is enough available
  or there are no more references that can be moved }
  while (index < FReferences^.Count) and (System.MaxAvail < ASize) do begin
    current := FReferences^.GetItem(index);
    Inc(index);
    if current^.ReferenceType = rtXms then
      continue;
    xmsHandle := XmsAlloc(current^.Size);

    { If no handle returned, then XMS does not have enough space, so error }
    if xmsHandle = 0 then begin
      Raise(ecNotEnoughMemory);
      exit;
    end;

    FillChar(MoveRecord, SizeOf(TXmsMoveRecord), 0);
    MoveRecord.Length := current^.Size;
    MoveRecord.SourceHandle := 0;
    MoveRecord.SourcePointer := current^.Ptr;
    MoveRecord.DestHandle := xmsHandle;
    MoveReference(MoveRecord);

    { If there was an exception thrown during the move, then error }
    if HasException then
      exit;
    FreeMem(current^.Ptr, current^.Size);
    current^.Ptr := nil;
    current^.ReferenceType := rtXms;
    current^.Handle := xmsHandle;
  end;
end;

procedure TMemoryDriver.MoveToConventional(AReference: PReference);
var
  ptr: pointer;
begin
  PurgeConventional(AReference^.Size);
  if HasException then
    exit;

  GetMem(ptr, AReference^.Size);
  if not Assigned(ptr) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;

  FillChar(MoveRecord, SizeOf(TXmsMoveRecord), 0);
  MoveRecord.Length := AReference^.Size;
  MoveRecord.SourceHandle := AReference^.Handle;
  MoveRecord.DestPointer := ptr;

  MoveReference(MoveRecord);
  if HasException then begin
    FreeMem(ptr, AReference^.Size);
    exit;
  end;

  XmsDealloc(AReference^.Handle);
  AReference^.Ptr := ptr;
  AReference^.ReferenceType := rtConventional;
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
  if not (AReference^.ReferenceType = rtXms) then
    exit;
  MoveToConventional(AReference);
end;

function TMemoryDriver.ReferencePointer(AReference: PReference): pointer;
begin
  ReferencePointer := nil;
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

function TMemoryDriver.CreateReference(ABuffer: pointer; ASize: word): PReference;
var
  reference: PReference;
begin
  reference := New(PReference);
  if not Assigned(reference) then begin
    Raise(ecNotEnoughMemory);
    CreateReference := nil;
    exit;
  end;
  reference^.Size := ASize;
  reference^.Ptr := ABuffer;
  reference^.ReferenceType := rtConventional;
  FReferences^.Add(reference);
  CreateReference := reference;
end;

function TMemoryDriver.Alloc(ASize: word): PReference;
var
  reference: PReference;
  ptr: pointer;
begin
  Alloc := nil;
  if ASize = 0 then begin
    Raise(ecInvalidAllocSize);
    exit;
  end;
  reference := New(PReference);
  if not Assigned(reference) then begin
    Raise(ecNotEnoughMemory);
    Alloc := nil;
    exit;
  end;
  reference^.Size := ASize;
  reference^.Ptr := nil;
  if ASize <= System.MaxAvail then begin
    GetMem(ptr, ASize);
    if not Assigned(ptr) then begin
      Raise(ecNotEnoughMemory);
      exit;
    end;
    reference^.Ptr := ptr;
    reference^.Size := ASize;
    reference^.ReferenceType := rtConventional
  end
  else if FXmsSupported and (ASize <= XmsMaxAvail) then begin
    reference^.Handle := XmsAlloc(ASize);
    if reference^.Handle = 0 then begin
      Raise(ecNotEnoughMemory);
      Dispose(reference);
      Alloc := nil;
      exit;
    end;
    reference^.Size := ASize;
    reference^.ReferenceType := rtXms;
  end
  else begin
    Raise(ecNotEnoughMemory);
    Dispose(reference);
    Alloc := nil;
    exit;
  end;
  FReferences^.Add(reference);
  if Assigned(FTransactionReferences) then
    FTransactionReferences^.Add(reference);
  Alloc := reference;
end;

procedure TMemoryDriver.FreeReferencePreserve(AReference: PReference);
var
  index: integer;
begin
  if not Assigned(AReference) then
    exit;
  index := FReferences^.IndexOf(AReference);
  if AReference^.ReferenceType = rtXms then
    MoveToConventional(AReference);
  Dispose(AReference);
  if index < 0 then
    exit;
  FReferences^.Delete(index);
end;

procedure TMemoryDriver.FreeReference(AReference: PReference);
var
  xmsResult: word;
  xmsError: byte;
  xmsHandle: word;
  index: integer;
begin
  if not Assigned(AReference) then
    exit;
  index := FReferences^.IndexOf(AReference);
  if AReference^.ReferenceType = rtXms then
    XmsDealloc(AReference^.Handle)
  else
    FreeMem(AReference^.Ptr, AReference^.Size);
  Dispose(AReference);
  if index < 0 then
    exit;
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
  FreeAndNil(FReferences);
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
  FillChar(ptr, AReference^.Size, AByte);
end;

procedure TMemoryDriver.CommitAllocTransaction;
begin
  FreeAndNil(FTransactionReferences);
end;

procedure TMemoryDriver.RollbackAllocTransaction;
var
  current: PReference;
begin
  if not Assigned(FTransactionReferences) then
    exit;
  while (FTransactionReferences^.Count > 0) do begin
    current := FTransactionReferences^.GetItem(0);
    FreeReference(current);
    FTransactionReferences^.Delete(0);
  end;
  FreeAndNil(FTransactionReferences);
end;

procedure TMemoryDriver.Init;
var
  reference: PReference;
  size: word;
begin
  inherited Init;
  HeapError := @OnHeapError;
  OutOfMemoryException := New(PException, Create(ecNotEnoughMemory));
  FReferences := New(PReferenceList, Create);
  FCurrentReference := nil;
  FXmsSupported := false;
  FXmsVersion := 0;
  FTransactionReferences := nil;
  XmsControl := nil;
  InitXms;
end;

destructor TReferenceList.Free;
begin
  inherited Free;
end;

function TReferenceList.GetItem(AIndex: integer): PReference;
begin
  GetItem := PReference(Inherited GetItem(AIndex));
end;

function TReferenceList.Add(AItem: PReference): integer;
begin
  Add := Inherited Add(AItem);
end;

function TReferenceList.IndexOf(AItem: PReference): integer;
begin
  IndexOf := Inherited IndexOf(AItem);
end;

procedure TReferenceList.SetItem(AIndex: integer; AItem: PReference);
begin
  Inherited SetItem(AIndex, AItem);
end;

procedure TReferenceList.Insert(AIndex: integer; AItem: PReference);
begin
  Inherited Insert(AIndex, AItem);
end;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  Memory.Free;
end;

constructor TBuffer.Create;
begin
  inherited Create;
  Data := nil;
  Size := 0;
end;

constructor TBuffer.CreateSize(var ASize: word);
begin
  Create;
  SetSize(ASize, false);
end;

constructor TBuffer.CreateClear(var ASize: word);
begin
  SetSize(ASize, true);
end;

function TBuffer.AsString: PChar;
begin
  AsString := PChar(Data);
end;

procedure TBuffer.SetSize(ASize: word; AClear: boolean);
begin
  SetDataSize(ASize, AClear, false);
end;

procedure TBuffer.SetSizePreserve(ASize: word; AClear: boolean);
begin
  SetDataSize(ASize, AClear, true);
end;

procedure TBuffer.SetDataSize(ASize: word; AClear, APreserve: boolean);
var
  newData: PByte;
  ptr: PByte;
begin
  if ASize > MaxVarSize then begin
    Raise(ecInvalidAllocSize);
    exit;
  end;
  GetMem(newData, ASize);
  if newData = nil then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  if Data = nil then begin
    Data := newData;
    Size := ASize;
    exit;
  end;
  if ASize > Size then begin
    if APreserve then begin
      System.Move(Data^, newData^, Size);
      if AClear then begin
        ptr := newData;
        Inc(ptr, Size);
        System.FillChar(ptr^, ASize - Size, 0);
      end;
    end
    else begin
      if AClear then
        System.FillChar(newData^, ASize, 0);
    end;
  end else begin
    if APreserve then
      System.Move(Data^, newData^, ASize)
    else begin
      if AClear then
        System.FillChar(newData^, ASize, 0);
    end;
  end;
  FreeMem(Data, Size);
  Data := newData;
  Size := ASize;
end;

procedure TBuffer.FreeData;
begin
  if Size > 0 then
    FreeMem(Data, Size);
  Size := 0;
  Data := nil;
end;

procedure TBuffer.Clear;
begin
  if Size > 0 then
    System.FillChar(Data^, Size, 0);
end;

procedure TBuffer.FillByte(AByte: byte; ASize: word);
begin
  if (ASize = 0) or (ASize = 0) then
    exit;
  ASize := MinW(ASize, Size);
  System.FillChar(Data^, ASize, AByte);
end;

procedure TBuffer.FillChar(AChar: char; ASize: word);
begin
  FillByte(byte(AChar), ASize);
end;

procedure TBuffer.FillAllByte(AByte: word);
begin
  FillByte(AByte, Size);
end;

procedure TBuffer.FillAllChar(AChar: char);
begin
  FillChar(AChar, Size);
end;

procedure TBuffer.SetByte(APos: word; AByte: byte);
begin
  if APos > Size - 1 then
    exit;
  AsString[APos] := char(AByte);
end;

procedure TBuffer.Move(AFrom, ATo, ALength: word);
var
  ptr: PChar;
begin
  ptr := AsString;
  System.Move(ptr[AFrom], ptr[ATo], ALength);
end;

procedure TBuffer.SetChar(APos: word; AChar: char);
begin
  SetByte(APos, Ord(AChar));
end;

procedure TBuffer.Init;
begin
  inherited Init;
  Data := nil;
end;

destructor TBuffer.Free;
begin
  FreeData;
  inherited Free;
end;

begin
  Memory.Create;
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.