{$I COMPILER.INC}
unit MemDrv;

interface

uses
  AplConst,
  AplObj,
  AplStr,
  AplTypes,
  AplMath,
  Lists,
  Strings;

const
  EmsPageSize = 16384;

type
  PMemoryDriver = ^TMemoryDriver;
  PEmsPhysPage = ^TEmsPhysPage;
  PEmsPhysPages = ^TEmsPhysPages;
  PEmsHandles = ^word;
  PEmsPageMap = ^TEmsPageMap;
  PEmsPageMaps = ^TEmsPageMaps;
  PMemoryReference = ^TMemoryReference;
  PConventionalReference = ^TConventionalReference;
  PEmsReference = ^TEmsReference;
  PMemoryReferenceList = ^TMemoryReferenceList;
  PMemoryAllocErrorProc = ^TMemoryAllocErrorProc;

  TMemoryAllocErrorProc = function(ASize: word): boolean;

  TEmsPhysPage = record
    Segm: word;
    PageNumber: word;
  end;

  TEmsPageMap = record
    LogPageNumber: word;
    PhysPageNumber: word;
  end;

  TMemoryReference = object(TObject)
  private
    FPtr: pointer;
  public
    function IsEms: boolean; virtual;
    function Size: longint; virtual;
    procedure Init; virtual;
  end;

  TConventionalReference = object(TMemoryReference)
  private
    FSize: word;
  public
    constructor Create(ASize: word);
    constructor CreatePtr(APtr: pointer; ASize: word);
    destructor Free; virtual;
    function Ptr: PByte;
    function Size: longint; virtual;
    function IsEms: boolean; virtual;
    procedure Init; virtual;
  end;

  TEmsReference = object(TMemoryReference)
  private
    FSize: longint;
  public
    constructor Create(ASize: longint);
    constructor CreateHandle(AHandle, APages: word; ASize: longint);
    destructor Free; virtual;
    destructor FreePreserve; virtual;
    function Handle: word;
    function Pages: word;
    function Size: longint; virtual;
    function IsEms: boolean; virtual;
    procedure Init; virtual;
    procedure SetHandle(AHandle, APages: word);
  end;

  TMemoryReferenceList = object(TObjectList)
  private
  public
    function Add(AItem: PMemoryReference): integer;
    function GetItem(AIndex: integer): PMemoryReference;
    function IndexOf(AItem: PMemoryReference): integer;
    procedure SetItem(AIndex: integer; AItem: PMemoryReference);
    procedure Insert(AIndex: integer; AItem: PMemoryReference);
    procedure RemoveItem(AItem: PMemoryReference);
  end;

  TEmsPhysPages = array[0..MaxVarSize div SizeOf(TEmsPhysPage)] of TEmsPhysPage;
  TEmsPageMaps = array[0..MaxVarSize div SizeOf(TEmsPageMap)] of TEmsPageMap;

  TMemoryDriver = object(TStatusObject)
  private
    FEmsSupported: boolean;
    FPageFrameSeg: word;
    FPhysPageSeg: word;
    FPhysPages: PEmsPhysPages;
    FPhysCount: word;
    FCurrentHandle: word;
    FCurrentPage: integer;
    FTransaction: PMemoryReferenceList;
    function InitEms: boolean;
    function CheckForEmm: boolean;
    function GetPageFrameSegment(var ASegment: word): byte;
    function CheckEmsStatus(AStatus: byte): boolean;
    function GetPhysEntryCount: word;
    function GetPhysEntries: PEmsPhysPages;
    function GetPhysPageSeg(AEntries: PEmsPhysPages; APage: word): word;
  public
    OnAllocError: PMemoryAllocErrorProc;
    function EmsSupported: boolean;
    function EmsSeg: word;
    function PhysPageSeg: word;
    function PhysPages: PEmsPhysPages;
    function PhysPageCount: word;
    function EmsAllocate(ACount: word): word;
    function CreateReference(AEms: boolean; ASize: longint): PMemoryReference;
    function CreateBufferReference(APtr: pointer; ASize: word): PMemoryReference;
    function CurrentHandle: word;
    function CurrentPage: integer;
    function EmsDeallocate(AHandle: word): byte;
    procedure SetCurrentPage(AReference: PEmsReference; APage: word);
    procedure BeginTransaction;
    procedure RollbackTransaction;
    procedure CommitTransaction;
    procedure GetPageCount(var ATotal, AUnallocated: word);
    procedure Init; virtual;
    destructor Free; virtual;
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

implementation

uses
  Streams,
  Dos;

const
  EmsInt = $67;

  EmsStatus: byte = $40;
  EmsGetPageFrameAddress = $41;
  EmsGetUnallocatedPages = $42;
  EmsAllocatePages = $43;
  EmsDealloc = $45;
  EmsMapPage = $44;
  EmsGetPhysEntryArray = $5800;
  EmsGetNumPhysEntries = $5801;

  EmsSuccess = 0;
  EmsSoftwareError = $80;
  EmsHardwareError = $81;
  EmsHandleNotFound = $83;
  EmsNotSupported = $84;
  EmsAllHandlesUsed = $85;
  EmsContextError = $86;
  EmsNotEnoughPages = $87;
  EmsNotEnoughUnallocated = $88;
  EmsZeroPages = $89;
  EmsLogPageOutOfRange = $8A;
  EmsPhysPageOutOfRange = $8B;
  EmsInvalidParam = $8F;

function OnHeapError(Size: word): integer; far;
var
  minSize: longint;
begin
  if Size = 0 then
    exit;

  { Default to return nil on error }
  OnHeapError := 1;
(*
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
  end;*)

  { Flag as now available and retry }
 { OnHeapError := 2;}
end;

function TMemoryReference.IsEms: boolean;
begin
  IsEms := false;
end;

function TMemoryReference.Size: longint;
begin
  Abstract;
end;

procedure TMemoryReference.Init;
begin
  inherited Init;
  FPtr := nil;
end;

constructor TConventionalReference.Create(ASize: word);
begin
  inherited Create;
  FSize := ASize;
end;

constructor TConventionalReference.CreatePtr(APtr: pointer; ASize: word);
begin
  Create(ASize);
  FPtr := APtr;
end;

function TConventionalReference.Ptr: PByte;
begin
  Ptr := FPtr;
end;

function TConventionalReference.Size: longint;
begin
  Size := FSize;
end;

function TConventionalReference.IsEms: boolean;
begin
  IsEms := false;
end;

procedure TConventionalReference.Init;
begin
  inherited Init;
  FSize := 0;
end;

destructor TConventionalReference.Free;
begin
  if Assigned(FPtr) and (FSize > 0) then
    FreeMem(FPtr, FSize);
  inherited Free;
end;

constructor TEmsReference.Create(ASize: longint);
begin
  inherited Create;
  FPtr := pointer(0);
  FSize := ASize;
end;

constructor TEmsReference.CreateHandle(AHandle, APages: word; ASize: longint);
var
  value: longint;
begin
  Create(ASize);
  value := longint(AHandle) shl 16;
  value := value or APages;
  FPtr := pointer(value);
end;

destructor TEmsReference.Free;
begin
  if longint(FPtr) > 0 then
    Memory.EmsDeallocate(Handle);
  inherited Free;
end;

destructor TEmsReference.FreePreserve;
begin
  inherited Free;
end;

function TEmsReference.Handle: word;
begin
  Handle := word(longint(FPtr) shr 16);
end;

function TEmsReference.Pages: word;
begin
  Pages := word(longint(FPtr) and $FFFF);
end;

function TEmsReference.Size: longint;
begin
  Size := FSize;
end;

function TEmsReference.IsEms: boolean;
begin
  IsEms := true;
end;

procedure TEmsReference.Init;
begin
  inherited Init;
  FSize := 0;
end;

procedure TEmsReference.SetHandle(AHandle, APages: word);
begin
  FPtr := pointer(longint(AHandle) shl 16 or APages);
end;

function TMemoryDriver.CheckEmsStatus(AStatus: byte): boolean;
begin
  CheckEmsStatus := false;
  case AStatus of
    EmsSuccess: CheckEmsStatus := true;
    EmsNotSupported: Raise(ecEmsFunctionNotSupported);
    EmsSoftwareError: Raise(ecEmsSoftwareError);
    EmsHardwareError: Raise(ecEmsHardwareError);
    EmsAllHandlesUsed, EmsNotEnoughPages, EmsNotEnoughUnallocated: Raise(ecNotEnoughMemory);
    EmsZeroPages: Raise(ecEmsZeroPages);
    EmsInvalidParam: Raise(ecEmsInvalidParam);
    EmsLogPageOutOfRange: Raise(ecEmsLogPageOutOfRange);
    EmsPhysPageOutOfRange: Raise(ecEmsPhysPageOutOfRange);
    else Raise(ecEmsUnknownError);
  end;
end;

function TMemoryDriver.CheckForEmm: boolean;
const
  asciiDeviceName: array[1..8] of char = 'EMMXXXX0';
var
  result: boolean;
begin
  asm
    push ds
    mov ax, 3567h
    int 21h
    mov cx, 8
    mov si, offset asciiDeviceName
    mov di, 0Ah
    cld
    rep cmpsb
    jne @error
  @ok:
    pop ds
    mov result, 1
    jmp @end
  @error:
    pop ds
    mov result, 0
  @end:
  end;
end;

function TMemoryDriver.InitEms: boolean;
var
  emmPresent: boolean;
  result: byte;
begin
  FEmsSupported := false;
  InitEms := false;
  if not CheckForEmm then
    exit;
  asm
    mov ah, EmsStatus
    int EmsInt
    mov result, ah
  end;
  if not CheckEmsStatus(result) then
    exit;
  result := GetPageFrameSegment(FPageFrameSeg);
  if not CheckEmsStatus(result) then
    exit;
  FPhysPages := GetPhysEntries;
  if HasException then
    exit;
  FEmsSupported := true;
  InitEms := true;
end;

function TMemoryDriver.GetPageFrameSegment(var ASegment: word): byte;
var
  segm: word;
  result: byte;
begin
  ASegment := 0;
  asm
    mov ah, EmsGetPageFrameAddress
    int EmsInt
    mov result, ah
    mov segm, bx
  end;
  if result = 0 then
    ASegment := segm;
  GetPageFrameSegment := result;
end;

function TMemoryDriver.EmsSupported: boolean;
begin
  EmsSupported := FEmsSupported;
end;

function TMemoryDriver.PhysPageSeg: word;
begin
  PhysPageSeg := FPhysPageSeg;
end;

function TMemoryDriver.EmsSeg: word;
begin
  EmsSeg := FPageFrameSeg;
end;

procedure TMemoryDriver.GetPageCount(var ATotal, AUnallocated: word);
var
  total, unallocated: word;
  result: byte;
begin
  ATotal := 0;
  AUnallocated := 0;
  if HasException or not FEmsSupported then
    exit;
  asm
    mov ah, EmsGetUnallocatedPages
    int EmsInt
    mov result, ah
    mov unallocated, bx
    mov total, dx
  end;
  if CheckEmsStatus(result) then begin
    ATotal := total;
    AUnallocated := unallocated;
  end;
end;

function TMemoryDriver.GetPhysEntryCount: word;
var
  result: byte;
  count: word;
begin
  GetPhysEntryCount := 0;
  if HasException then
    exit;
  asm
    mov ax, EmsGetNumPhysEntries
    int EmsInt
    mov result, ah
    mov count, cx
  end;
  if CheckEmsStatus(result) then
    GetPhysEntryCount := count;
end;

function TMemoryDriver.GetPhysPageSeg(AEntries: PEmsPhysPages; APage: word): word;
var
  index: integer;
begin
  GetPhysPageSeg := 0;
  for index := 0 to FPhysCount - 1 do begin
    if AEntries^[index].PageNumber = APage then begin
      GetPhysPageSeg := AEntries^[index].Segm;
      exit;
    end;
  end;
end;

function TMemoryDriver.GetPhysEntries: PEmsPhysPages;
var
  result: byte;
  entries: PEmsPhysPages;
  count: word;
begin
  GetPhysEntries := nil;
  FPhysCount := 0;
  FPhysPageSeg := 0;
  count := GetPhysEntryCount;
  if HasException then
    exit;
  GetMem(entries, SizeOf(TEmsPhysPage) * count);
  if entries = nil then
    exit;
  asm
    mov ax, EmsGetPhysEntryArray
    les di, entries
    int EmsInt
    mov result, ah
  end;
  if CheckEmsStatus(result) then begin
    GetPhysEntries := entries;
    FPhysCount := count;
    FPhysPageSeg := GetPhysPageSeg(entries, 0);
  end
  else
    FreeMem(entries, SizeOf(TEmsPhysPage) * count);
end;

function TMemoryDriver.PhysPages: PEmsPhysPages;
begin
  PhysPages := nil;
  if HasException or not FEmsSupported then
    exit;
  PhysPages := FPhysPages;
end;

function TMemoryDriver.PhysPageCount: word;
begin
  PhysPageCount := 0;
  if HasException or not FEmsSupported then
    exit;
  PhysPageCount := FPhysCount;
end;

function TMemoryDriver.EmsAllocate(ACount: word): word;
var
  handle, total, unallocated: word;
  result: byte;
begin
  EmsAllocate := 0;
  if HasException or not FEmsSupported then
    exit;
  GetPageCount(total, unallocated);
  if HasException or (unallocated < ACount) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  asm
    mov ah, EmsAllocatePages
    mov bx, ACount
    int EmsInt
    mov result, ah
    mov handle, dx
  end;
  if not CheckEmsStatus(result) then
    exit;
  EmsAllocate := handle;
end;

function TMemoryDriver.EmsDeallocate(AHandle: word): byte;
var
  result: byte;
begin
  if HasException or not FEmsSupported then
    exit;
  asm
    mov ah, EmsDealloc
    mov dx, AHandle
    int EmsInt
    mov result, ah
  end;
  EmsDeallocate := result;
  if CheckEmsStatus(result) then
    exit;
end;

procedure TMemoryDriver.SetCurrentPage(AReference: PEmsReference; APage: word);
var
  handle: word;
  page: word;
  result: byte;
begin
  handle := AReference^.Handle;
  if APage >= AReference^.Pages then
    Raise(ecEmsLogPageOutOfRange);
  if HasException or not FEmsSupported then
    exit;
  if (FCurrentHandle = handle) and (APage = FCurrentPage) then
    exit;
  page := APage;
  asm
    mov ah, EmsMapPage
    xor al, al
    mov bx, page
    mov dx, handle
    int EmsInt
    mov result, ah
  end;
  if not CheckEmsStatus(result) then
    exit;
  FCurrentPage := page;
  FCurrentHandle := handle;
end;

procedure TMemoryDriver.Init;
begin
  inherited Init;
  HeapError := @OnHeapError;
  OnAllocError := nil;
  FPageFrameSeg := 0;
  FPhysPageSeg := 0;
  FPhysPages := nil;
  FPhysCount := 0;
  FCurrentHandle := 0;
  FCurrentPage := -1;
  FTransaction := nil;
  InitEms;
end;

function TMemoryDriver.CurrentHandle: word;
begin
  CurrentHandle := FCurrentHandle;
end;

function TMemoryDriver.CurrentPage: integer;
begin
  CurrentPage := FCurrentPage;
end;

function TMemoryDriver.CreateBufferReference(APtr: pointer; ASize: word): PMemoryReference;
var
  reference: PConventionalReference;
  ptr: PByte;
begin
  CreateBufferReference := nil;
  reference := New(PConventionalReference, CreatePtr(APtr, ASize));
  if NilPtr(reference, ecNotEnoughMemory) then
    exit;
  CreateBufferReference := reference;
end;

function TMemoryDriver.CreateReference(AEms: boolean; ASize: longint): PMemoryReference;
var
  reference: PMemoryReference;
  pages, handle: word;
begin
  CreateReference := nil;
  if (ASize > MaxVarSize) and not (AEms) then begin
    Raise(ecInvalidAllocSize);
    exit;
  end;
  if AEms then begin
    reference := New(PEmsReference, Create(ASize));
    if NilPtr(reference, ecNotEnoughMemory) then
      exit;
    pages := ASize div EmsPageSize;
    if pages mod EmsPageSize > 0 then
      Inc(pages);
    handle := EmsAllocate(pages);
    if HasException then begin
      FreeAndNil(reference);
      exit;
    end;
    PEmsReference(reference)^.SetHandle(handle, pages);
  end
  else begin
    reference := New(PConventionalReference, Create(ASize));
    if NilPtr(reference, ecNotEnoughMemory) then
      exit;
    GetMem(reference^.FPtr, ASize);
    if NilPtr(reference^.FPtr, ecNotEnoughMemory) then begin
      FreeAndNil(reference);
      exit;
    end;
  end;
  CreateReference := reference;
end;

procedure TMemoryDriver.BeginTransaction;
begin
  FTransaction := New(PMemoryReferenceList, Create);
  if NilPtr(FTransaction, ecNotEnoughMemory) then
    exit;
  FTransaction^.DisposeObjects := false;
end;

procedure TMemoryDriver.RollbackTransaction;
var
  reference: PMemoryReference;
begin
  if not Assigned(FTransaction) then
    exit;
  while FTransaction^.Count > 0 do begin
    reference := FTransaction^.GetItem(0);
    FreeAndNil(reference);
    FTransaction^.Delete(0);
  end;
  FreeAndNil(FTransaction);
end;

procedure TMemoryDriver.CommitTransaction;
begin
  FreeAndNil(FTransaction);
end;

destructor TMemoryDriver.Free;
begin
  if Assigned(FPhysPages) then
    FreeMem(FPhysPages, SizeOf(TEmsPhysPage) * FPhysCount);
  FreeAndNil(FTransaction);
  inherited Free;
end;

function TMemoryReferenceList.Add(AItem: PMemoryReference): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TMemoryReferenceList.RemoveItem(AItem: PMemoryReference);
var
  index: integer;
begin
  index := inherited IndexOf(AItem);
  inherited Delete(index);
end;

function TMemoryReferenceList.GetItem(AIndex: integer): PMemoryReference;
begin
  GetItem := PMemoryReference(inherited GetItem(AIndex));
end;

function TMemoryReferenceList.IndexOf(AItem: PMemoryReference): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TMemoryReferenceList.SetItem(AIndex: integer; AItem: PMemoryReference);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TMemoryReferenceList.Insert(AIndex: integer; AItem: PMemoryReference);
begin
  inherited Insert(AIndex, AItem);
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

var
  PreviousExitProc: PProc;
{$IFDEF debug}
  handle: byte;
  total, unallocated: word;
{$ENDIF}

procedure Finalize; far;
begin
  Memory.Free;
  ExitProc := PreviousExitProc;
end;

procedure Initialize; far;
{$IFDEF debug}
var
  result: byte;
  stream: TFileStream;
  handle: word;
{$ENDIF}
begin
  Memory.Create;
  {$IFDEF debug}
  stream.Create('emsalloc.bin', fmRead);
  if not stream.HasException then begin
    handle := stream.ReadWord;
    result := Memory.EmsDeallocate(handle);
  end;
  stream.Free;
  Memory.ClearException;
  Memory.GetPageCount(total, unallocated);
  WriteLn('Total Pages Available: ',
    total, ', Unallocated: Pages ', unallocated);
  {$ENDIF}
end;

begin
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
  Initialize;
end.
