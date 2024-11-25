{$I COMPILER.INC}
unit Lists;

interface

uses
  AplObj,
  AplConst,
  AplTypes,
  AplUtils,
  AplMath,
  AplStr,
  Strings;

const
  ListBufferSize = $FFF8 div SizeOf(Pointer);
  DefaultListSize = 4;

type
  PObjectList = ^TObjectList;
  PList = ^TList;
  PLinkedObjectList = ^TLinkedObjectList;
  PStack = ^TStack;
  PObjectStack = ^TStack;
  PQueue = ^TQueue;
  PStringList = ^TStringList;
  PSortFunc = ^TSortFunc;
  PComparer = ^TComparer;
  PListBuffer = ^TListBuffer;
  PListNode = ^TListNode;
  PListProc = ^TListProc;
  PIdentifiableList = ^TIdentifiableList;
  PIdentifiableListProc = ^TIdentifiableListProc;
  PObjectListProc = ^TObjectListProc;
  PStringListProc = ^TStringListProc;

  TSortFunc = procedure(AList: PList; AComparer: TComparer);
  TListBuffer = array[0..ListBufferSize] of pointer;
  TListProc = procedure(ASender: PObject; AItem: pointer);
  TObjectListProc = procedure(ASender: PObject; AItem: PObject);
  TStringListProc = procedure(ASender: PObject; AItem: PChar);
  TIdentifiableListProc = procedure(ASender: PObject; AItem: PIdentifiable);
  TListGrowFunc = function(AMin: integer): integer;

  TList = object(TStatusObject)
  private
    FSorted: boolean;
    FComparer: TComparer;
    FCapacity: integer;
    function GetSortedIndex(AItem: pointer): integer;
    procedure QuickSort(AComparer: TComparer; ALowIndex, AHighIndex: integer);
  public
    Count: integer;
    Items: PListBuffer;
    constructor CreateCapacity(ACapacity: integer);
    constructor CreateSorted(AComparer: TComparer);
    constructor CreateSortedCapacity(AComparer: TComparer; ACapacity: integer);
    destructor Free; virtual;
    procedure Init; virtual;
    function AddPtr(AItem: pointer): integer; virtual;
    function Add(AItem: pointer): integer;
    function Sorted: boolean;
    function GetPtr(AIndex: integer): pointer; virtual;
    function GetItem(AIndex: integer): pointer;
    function IndexOfPtr(AItem: pointer): integer; virtual;
    function IndexOf(AItem: pointer): integer;
    function BinarySearchUsing(AComparer: TComparer; var AValue): integer; virtual;
    function BinarySearch(var AValue): integer; virtual;
    function Capacity: integer;
    function Grow(AMin: integer): integer; virtual;
    function GrowUsing(AGrowFunc: TListGrowFunc; AMin: integer): integer; virtual;
    procedure ForEach(AProc: PListProc); virtual;
    procedure SetComparer(AComparer: TComparer); virtual;
    procedure Swap(AIndex1, AIndex2: integer); virtual;
    procedure SetPtr(AIndex: integer; AItem: pointer); virtual;
    procedure SetItem(AIndex: integer; AItem: pointer);
    procedure Sort; virtual;
    procedure SetCapacity(ACapacity: integer); virtual;
    procedure CustomSort(AComparer: TComparer; ASortFunc: TSortFunc); virtual;
    procedure InsertPtr(AIndex: integer; AItem: pointer); virtual;
    procedure Insert(AIndex: integer; AItem: pointer);
    procedure Delete(AIndex: integer); virtual;
    procedure DeletePtr(AItem: pointer); virtual;
    procedure DeleteItem(AItem: pointer);
    procedure Clear; virtual;
  end;

  TListNode = record
    Item: pointer;
    Next: PListNode;
  end;

  TLinkedList = object(TObject)
  private
    FHead: PListNode;
    FTail: PListNode;
    function SortedMerge(AComparer: TComparer; AItem1: PListNode; AItem2: PListNode): PListNode;
    procedure MergeSort(AComparer: TComparer; var AHead: PListNode);
    procedure FrontBackSplit(ASource: PListNode; var Afront, ABack: PListNode);
    procedure FreeNode(ANode: PListNode); virtual;
  public
    Count: longint;
    destructor Free; virtual;
    procedure Init; virtual;
    function Add(AItem: pointer): PListNode;
    function GetItem(AIndex: longint): pointer;
    function GetNode(AIndex: longint): PListNode;
    function IndexOf(AItem: pointer): longint;
    procedure Swap(var AItem1, AItem2: PListNode);
    procedure SetItem(AIndex: longint; AItem: pointer);
    procedure Sort(AComparer: TComparer); virtual;
    procedure Insert(AIndex: longint; AItem: pointer);
    procedure Delete(AIndex: longint);
    procedure Clear; virtual;
  end;

  TObjectList = object(TList)
  private
  public
    DisposeObjects: boolean;
    procedure Init; virtual;
    function Add(AItem: PObject): integer;
    function GetItem(AIndex: integer): PObject;
    function IndexOf(AItem: PObject): integer;
    procedure SetItem(AIndex: integer; AItem: PObject);
    procedure Insert(AIndex: integer; AItem: PObject);
    procedure Remove(AIndex: integer); virtual;
    procedure RemoveItem(AItem: PObject);
    procedure Delete(AIndex: integer); virtual;
    procedure Clear; virtual;
    destructor Free; virtual;
  end;

  TLinkedObjectList = object(TLinkedList)
  public
    DisposeObjects: boolean;
    procedure Init; virtual;
    function Add(AItem: PObject): PListNode;
    function GetItem(AIndex: longint): PObject;
    procedure SetItem(AIndex: longint; AItem: PObject);
    function IndexOf(AItem: PObject): longint;
    procedure Insert(AIndex: longint; AItem: PObject);
    procedure FreeNode(ANode: PListNode); virtual;
  end;

  TStack = object(TList)
  private
  public
    procedure Init; virtual;
    function Push(AItem: pointer): integer;
    function Pop: pointer;
    function Peek: pointer;
  end;

  TObjectStack = object(TObjectList)
  private
  public
    procedure Init; virtual;
    function Push(AObject: PObject): integer;
    function Pop: PObject;
    function Peek: PObject;
  end;

  TQueue = object(TList)
  private
  public
    procedure Init; virtual;
    function Enq(AItem: pointer): integer;
    function Deq: pointer;
  end;

  TObjectQueue = object(TObjectList)
  private
  public
    procedure Init; virtual;
    function Enq(AObject: PObject): integer;
    function Deq: PObject;
  end;

  TStringList = object(TList)
  public
    DisposeStrings: boolean;
    function AddString(const AString: string): integer;
    function GetItem(AIndex: integer): PChar;
    function GetString(AIndex: integer): string;
    procedure Insert(AIndex: integer; AItem: PChar);
    procedure InsertString(AIndex: integer; const AString: string);
    procedure Clear; virtual;
    procedure Delete(AIndex: integer); virtual;
    procedure Init; virtual;
  end;

  TIdentifiableList = object(TObjectList)
  private
  public
    function GetItemById(const AId: string): PIdentifiable;
    function GetItem(AIndex: integer): PIdentifiable;
    function IndexOfId(const AId: string): integer; virtual;
    function Add(AItem: PIdentifiable): integer;
    function IndexOf(AItem: PIdentifiable): integer;
    procedure SetItem(AIndex: integer; AItem: PIdentifiable);
    procedure Insert(AIndex: integer; AItem: PIdentifiable);
  end;

  TStringComparer = object(TObject)
  private
  public
    function CaseSensitive: PComparer;
    function CaseInsensitive: PComparer;
  end;

var
  TStringCompare: TStringComparer;

function DefaultListGrow(AMin: integer): integer; far;

implementation

function StringCompare(AItem1, AItem2: pointer): integer; far;
var
  str1: PChar;
  str2: PChar;
begin
  str1 := PChar(AItem1);
  str2 := PChar(AItem2);
  StringCompare := StrComp(str1, str2);
end;

function CaseInsensitiveStringCompare(AItem1, AItem2: pointer): integer; far;
var
  str1: PChar;
  str2: PChar;
begin
  str1 := PChar(AItem1);
  str2 := PChar(AItem2);
  CaseInsensitiveStringCompare := StrIComp(str1, str2);
end;

function TStringComparer.CaseSensitive: PComparer;
begin
  CaseSensitive := @StringCompare;
end;

function TStringComparer.CaseInsensitive: PComparer;
begin
  CaseInsensitive := @CaseInsensitiveStringCompare;
end;

destructor TList.Free;
begin
  Clear;
  if Assigned(Items) then
    FreeMem(Items, FCapacity * PointerSize);
  inherited Free;
end;

function DefaultListGrow(AMin: integer): integer;
var
  newCapacity: integer;
begin
  newCapacity := 0;
  while newCapacity < AMin do begin
    if newCapacity > 64 then
      newCapacity := (newCapacity * 3) div 2
    else if newCapacity > 8 then
      Inc(newCapacity, 16)
    else
      Inc(newCapacity, 4);
  end;
  newCapacity := Min(newCapacity, ListBufferSize);
  DefaultListGrow := newCapacity;
end;

function TList.GrowUsing(AGrowFunc: TListGrowFunc; AMin: integer): integer;
var
  newCapacity: integer;
begin
  newCapacity := AGrowFunc(AMin);
  if newCapacity < AMin then begin
    Raise(ecListCapacityOverflow);
    exit;
  end;
  SetCapacity(newCapacity);
  GrowUsing := newCapacity;
end;

function TList.Grow(AMin: integer): integer;
begin
  Grow := GrowUsing(DefaultListGrow, AMin);
end;

procedure TList.SetCapacity(ACapacity: integer);
var
  newBuffer: pointer;
  max: word;
  dataSize: longint;
begin
  if FCapacity = ACapacity then
    exit;
  if ACapacity > ListBufferSize then begin
    Raise(ecListCapacityOverflow);
    exit;
  end;
  dataSize := longint(ACapacity) * PointerSize;
  if longint(dataSize) > MaxVarSize then begin
    dataSize := MaxVarSize;
    ACapacity := MaxVarSize div PointerSize;
  end;
  if not Assigned(Items) then begin
    GetMem(Items, dataSize);
    if not Assigned(Items) then begin
      Raise(ecNotEnoughMemory);
      exit;
    end;
    FCapacity := ACapacity;
    exit;
  end;
  GetMem(newBuffer, dataSize);
  if not Assigned(newBuffer) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  if FCapacity > 0 then begin
    if ACapacity > FCapacity then
      dataSize := FCapacity * PointerSize;
    Move(Items^, newBuffer^, dataSize);
    FreeMem(Items, FCapacity * PointerSize);
  end;
  Items := newBuffer;
  FCapacity := ACapacity;
  if Count > FCapacity then
    Count := FCapacity;
end;

function TList.Capacity: integer;
begin
  Capacity := FCapacity;
end;

function TList.Add(AItem: pointer): integer;
begin
  Add := AddPtr(AItem);
end;

function TList.AddPtr(AItem: pointer): integer;
var
  ptr: PPointer;
  index: integer;
begin
  if Count + 1 > FCapacity then begin
    Grow(Count + 1);
    if HasException then
      exit;
  end;
  index := Count;
  if FSorted then
    index := GetSortedIndex(AItem);
  if index = Count then begin
    Items^[index] := AItem;
    Inc(Count);
  end
  else
    Insert(index, AItem);
  AddPtr := index;
end;

procedure TList.Clear;
begin
  while Count > 0 do
    Delete(0);
  if Assigned(Items) then
    FreeMem(Items, FCapacity *  PointerSize);
  Count := 0;
  Items := nil;
  FCapacity := 0;
end;

procedure TList.Swap(AIndex1, AIndex2: integer);
var
  temp: pointer;
begin
  temp := GetItem(AIndex1);
  SetItem(AIndex1, GetItem(AIndex2));
  SetItem(AIndex2, temp);
end;

procedure TList.QuickSort(AComparer: TComparer; ALowIndex, AHighIndex: integer);
var
  low, high: integer;
  pivot: integer;
begin
  if Count < 2 then
    exit;
  while ALowIndex < AHighIndex do begin
    if AHighIndex - ALowIndex = 1 then begin
      if AComparer(GetItem(ALowIndex), GetItem(AHighIndex)) > 0 then
        Swap(ALowIndex, AHighIndex);
      break;
    end;
    low := ALowIndex;
    high := AHighIndex;
    pivot := (ALowIndex + AHighIndex) shr 1;
    repeat
      while (low <> pivot) and (AComparer(GetItem(low), GetItem(pivot)) < 0) do
        Inc(low);
      while (high <> pivot) and (AComparer(GetItem(high), GetItem(pivot)) > 0) do
        Dec(high);
      if low <= high then begin
        if low <> high then
          Swap(low, high);
        if pivot = low then
          pivot := high
        else if pivot = high then
          pivot := low;
        Inc(low);
        Dec(high)
      end;
    until low > high;
    if (high - ALowIndex) > (AHighIndex - low) then begin
      if low < AHighIndex then
        QuickSort(AComparer, low, AHighIndex);
      AHighIndex := high;
    end
    else begin
      if ALowIndex < high then
        QuickSort(AComparer, ALowIndex, high);
      ALowIndex := low;
    end;
  end;
end;

constructor TList.CreateSorted(AComparer: TComparer);
begin
  inherited Create;
  FComparer := AComparer;
  FSorted := true;
end;

constructor TList.CreateSortedCapacity(AComparer: TComparer; ACapacity: integer);
begin
  inherited Create;
  FComparer := AComparer;
  FSorted := true;
  SetCapacity(ACapacity);
end;

constructor TList.CreateCapacity(ACapacity: integer);
begin
  inherited Create;
  SetCapacity(ACapacity);
end;

procedure TList.SetComparer(AComparer: TComparer);
begin
  FComparer := AComparer;
  Sort;
end;

procedure TList.Init;
begin
  inherited Init;
  FSorted := false;
  FComparer := nil;
  Items := nil;
  FCapacity := 0;
  Count := 0;
end;

function TList.Sorted: boolean;
begin
  Sorted := FSorted;
end;

function TList.GetItem(AIndex: integer): pointer;
begin
  GetItem := GetPtr(AIndex);
end;

function TList.GetPtr(AIndex: integer): pointer;
begin
  GetPtr := nil;
  if (AIndex < 0) or (AIndex > Count - 1) then begin
    Raise(ecIndexOutOfBounds);
    exit;
  end;
  GetPtr := Items^[AIndex];
end;

procedure TList.SetPtr(AIndex: integer; AItem: pointer);
begin
  if (AIndex < 0) or (AIndex > Count - 1) then begin
    Raise(ecIndexOutOfBounds);
    exit;
  end;
  Items^[AIndex] := AItem;
end;

procedure TList.SetItem(AIndex: integer; AItem: pointer);
begin
  SetPtr(AIndex, AItem);
end;

procedure TList.InsertPtr(AIndex: integer; AItem: pointer);
begin
  Insert(AIndex, AItem);
end;

procedure TList.Delete(AIndex: integer);
var
  ptr, next: PPointer;
begin
  if (AIndex < 0) or (AIndex > Count - 1) then begin
    Raise(ecIndexOutOfBounds);
    exit;
  end;
  ptr := pointer(Items);
  Inc(ptr, AIndex);
  next := ptr;
  Inc(next);
  Move(next^, ptr^, (Count - AIndex - 1) * PointerSize);
  Dec(Count);
end;

procedure TList.DeleteItem(AItem: pointer);
begin
  DeletePtr(AItem);
end;

procedure TList.DeletePtr(AItem: pointer);
var
  index: integer;
begin
  index := IndexOfPtr(AItem);
  if index >= 0 then
    Delete(index);
end;

function TList.IndexOf(AItem: pointer): integer;
begin
  IndexOf := IndexOfPtr(AItem);
end;

function TList.IndexOfPtr(AItem: pointer): integer;
var
  index: integer;
  current: pointer;
begin
  IndexOfPtr := -1;
  if Count = 0 then
    exit;
  index := 0;
  repeat
    current := GetPtr(index);
    if AItem = current then begin
      IndexOfPtr := index;
      break;
    end;
    Inc(index);
  until index > Count - 1;
end;

procedure TList.CustomSort(AComparer: TComparer; ASortFunc: TSortFunc);
begin
  if Count < 2 then exit;
  ASortFunc(@self, AComparer);
end;

procedure TList.Sort;
begin
  if Count < 2 then
    exit;
  QuickSort(FComparer, 0, Count - 1);
end;

function TList.GetSortedIndex(AItem: pointer): integer;
var
  result: integer;
begin
  result := BinarySearch(AItem);
  if result < 0 then
    result := -result - 1;
  GetSortedIndex := result;
end;

procedure TList.Insert(AIndex: integer; AItem: pointer);
var
  ptr, next: PPointer;
begin
  if (AIndex < 0) or (AIndex > Count - 1) then begin
    Raise(ecIndexOutOfBounds);
    exit;
  end;
  if Count + 1 > FCapacity then begin
    Grow(Count + 1);
    if HasException then
      exit;
  end;
  if AIndex > Count - 1 then begin
    Add(AItem);
    exit;
  end;
    ptr := pointer(Items);
  Inc(ptr, AIndex);
  next := ptr;
  Inc(next);
  Move(ptr^, next^, (longint(Count) - AIndex) * PointerSize);
  ptr^ := AItem;
  Inc(Count);
end;

procedure TList.ForEach(AProc: PListProc);
var
  index: integer;
begin
  for index := 0 to Count - 1 do
    TListProc(AProc)(@self, GetItem(index));
end;

function TList.BinarySearch(var AValue): integer;
begin
  BinarySearch := BinarySearchUsing(FComparer, AValue);
end;

function TList.BinarySearchUsing(AComparer: TComparer; var AValue): integer;
var
  compared: integer;
  upper, lower, middle: integer;
  item2: pointer;
begin
  lower := 0;
  upper := Count - 1;
  while lower <= upper do begin
    middle := lower + (upper - lower) shr 1;
    item2 := GetItem(middle);
    compared := AComparer(item2, pointer(AValue));
    if compared = 0 then begin
      BinarySearchUsing := middle;
      exit;
    end;
    if compared < 0 then
      lower := middle + 1
    else if compared > 0 then
      upper := middle - 1;
  end;
  BinarySearchUsing := -(lower + 1);
end;

procedure TObjectList.Init;
begin
  inherited Init;
  DisposeObjects := true;
end;

function TObjectList.Add(AItem: PObject): integer;
begin
  Add := inherited Add(AItem);
end;

function TObjectList.IndexOf(AItem: PObject): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TObjectList.SetItem(AIndex: integer; AItem: PObject);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TObjectList.Insert(AIndex: integer; AItem: PObject);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TObjectList.Delete(AIndex: integer);
var
  obj: PObject;
begin
  if (AIndex < 0) or (AIndex > Count - 1) then begin
    Raise(ecIndexOutOfBounds);
    exit;
  end;
  obj := GetItem(AIndex);
  if DisposeObjects then
    FreeAndNil(obj);
  inherited Delete(AIndex);
end;

procedure TObjectList.Remove(AIndex: integer);
begin
  inherited Delete(AIndex);
end;

procedure TObjectList.RemoveItem(AItem: PObject);
var
  index: integer;
begin
  index := IndexOf(AItem);
  if index >= 0 then
    Remove(index);
end;

destructor TObjectList.Free;
begin
  Clear;
  inherited Free;
end;

procedure TObjectList.Clear;
begin
  if DisposeObjects then begin
    while Count > 0 do
      Delete(0);
  end;
  inherited Clear;
end;

function TObjectList.GetItem(AIndex: integer): PObject;
begin
  GetItem := inherited GetItem(AIndex);
end;

procedure TQueue.Init;
begin
  inherited Init;
end;

function TQueue.Enq(AItem: pointer): integer;
begin
  Enq := Add(AItem);
end;

function TQueue.Deq: pointer;
begin
  Deq := nil;
  if Count = 0 then
    exit;
  Deq := GetItem(0);
  Delete(0);
end;

procedure TObjectQueue.Init;
begin
  inherited Init;
  DisposeObjects := false;
end;

function TObjectQueue.Enq(AObject: PObject): integer;
begin
  Enq := Add(AObject);
end;

function TObjectQueue.Deq: PObject;
begin
  Deq := nil;
  if Count = 0 then
    exit;
  Deq := GetItem(0);
  Delete(0);
end;

procedure TObjectStack.Init;
begin
  inherited Init;
  DisposeObjects := false;
end;

function TObjectStack.Push(AObject: PObject): integer;
begin
  Push := Add(AObject);
end;

function TObjectStack.Pop: PObject;
var
  result: PObject;
begin
  result := Peek;
  Pop := result;
  if (Count = 0) or not Assigned(result) then
    exit;
  Delete(Count - 1);
end;

function TObjectStack.Peek: PObject;
begin
  Peek := nil;
  if Count = 0 then
    exit;
  Peek := GetItem(Count - 1);
end;

procedure TStack.Init;
begin
  inherited Init;
end;

function TStack.Push(AItem: pointer): integer;
begin
  Push := Add(AItem);
end;

function TStack.Pop: pointer;
var
  result: pointer;
begin
  result := Peek;
  Pop := result;
  if (Count = 0) or not Assigned(result) then
    exit;
  Delete(Count - 1);
end;

function TStack.Peek: pointer;
begin
  Peek := nil;
  if Count = 0 then
    exit;
  Peek := GetItem(Count - 1);
end;

procedure TStringList.Init;
begin
  inherited Init;
  FComparer := TStringCompare.CaseInsensitive^;
  DisposeStrings := true;
end;

function TStringList.GetString(AIndex: integer): string;
var
  result: PChar;
begin
  result := GetItem(AIndex);
  GetString := StrPas(result);
end;

function TStringList.AddString(const AString: string): integer;
begin
  AddString := inherited Add(TString.New(AString));
end;

procedure TStringList.InsertString(AIndex: integer; const AString: string);
begin
  Insert(AIndex, TString.New(AString));
end;

procedure TStringList.Insert(AIndex: integer; AItem: PChar);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TStringList.Delete(AIndex: integer);
var
  st: PChar;
begin
  if Count = 0 then
    exit;
  st := GetItem(AIndex);
  if DisposeStrings then
    TString.Free(st);
  inherited Delete(AIndex);
end;

function TStringList.GetItem(AIndex: integer): PChar;
begin
  GetItem := inherited GetItem(AIndex);
end;

procedure TStringList.Clear;
begin
  if DisposeStrings then
    while Count > 0 do
      Delete(0);
  inherited Clear;
end;

function TIdentifiableList.GetItemById(const AId: string): PIdentifiable;
var
  index: integer;
begin
  GetItemById := nil;
  index := IndexOfId(AId);
  if index < 0 then
    exit;
  GetItemById := GetItem(index);
end;

function TIdentifiableList.GetItem(AIndex: integer): PIdentifiable;
begin
  GetItem := PIdentifiable(inherited GetItem(AIndex));
end;

function TIdentifiableList.IndexOfId(const AId: string): integer;
var
  index: integer;
  item: PIdentifiable;
begin
  IndexOfId := -1;
  if Count = 0 then
    exit;
  for index := 0 to Count - 1 do begin
    item := GetItem(index);
    if LowerCase(AId) = LowerCase(StrPas(item^.Id)) then begin
      IndexOfId := index;
      break;
    end;
  end;
end;

function TIdentifiableList.Add(AItem: PIdentifiable): integer;
begin
  Add := inherited Add(AItem);
end;

function TIdentifiableList.IndexOf(AItem: PIdentifiable): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TIdentifiableList.SetItem(AIndex: integer; AItem: PIdentifiable);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TIdentifiableList.Insert(AIndex: integer; AItem: PIdentifiable);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TLinkedList.Init;
begin
  inherited Init;
  FHead := nil;
  FTail := nil;
  Count := 0;
end;

function TLinkedList.Add(AItem: pointer): PListNode;
var
  node: PListNode;
begin
  node := New(PListNode);
  node^.Item := AItem;
  node^.Next := nil;
  Add := node;
  Inc(Count);
  if not Assigned(FHead) then begin
    FHead := node;
    FTail := node;
    exit;
  end;
  FTail^.Next := node;
  FTail := node;
end;

function TLinkedList.GetNode(AIndex: longint): PListNode;
var
  index: longint;
  current: PListNode;
begin
  GetNode := nil;
  if (AIndex < 0) or (AIndex > Count - 1) then
    exit;
  index := -1;
  current := FHead;
  while Assigned(current) do begin
    Inc(index);
    if index = AIndex then
      break;
    current := current^.Next;
  end;
  GetNode := current;
end;

function TLinkedList.GetItem(AIndex: longint): pointer;
var
  node: PListNode;
begin
  GetItem := nil;
  node := GetNode(AIndex);
  if not Assigned(node) then
    exit;
  GetItem := node^.Item;
end;

procedure TLinkedList.SetItem(AIndex: longint; AItem: pointer);
var
  node: PListNode;
begin
  node := GetNode(AIndex);
  if Assigned(node) then
    node^.Item := AItem;
end;

function TLinkedList.IndexOf(AItem: pointer): longint;
var
  index: longint;
  current: PListNode;
begin
  IndexOf := -1;
  if not Assigned(FHead) then
    exit;
  index := 0;
  current := FHead;
  while current^.Item <> AItem do begin
    if not Assigned(current^.Next) then begin
      IndexOf := -1;
      exit;
    end;
    Inc(index);
    current := current^.Next;
  end;
  IndexOf := index;
end;

procedure TLinkedList.Swap(var AItem1, AItem2: PListNode);
var
  temp: pointer;
begin
  temp := AItem1^.Item;
  AItem1^.Item := AItem2^.Item;
  AItem2^.Item := temp;
end;

procedure TLinkedList.Sort(AComparer: TComparer);
begin
  MergeSort(AComparer, FHead);
end;

procedure TLinkedList.Insert(AIndex: longint; AItem: pointer);
var
  prev, item, newNode: PListNode;
  head: PListNode;
begin
  AIndex := MaxL(AIndex, 0);
  if AIndex >= Count then begin
    FTail := Add(AItem);
    exit;
  end;
  Inc(Count);
  newNode := New(PListNode);
  newNode^.Next := nil;
  newNode^.Item := AItem;
  if AIndex = 0 then begin
    head := FHead;
    FHead := newNode;
    FHead^.Next := head;
    exit;
  end;
  prev := GetNode(AIndex - 1);
  prev^.Next := newNode;
end;

procedure TLinkedList.Delete(AIndex: longint);
var
  prev, item: PListNode;
begin
  if (AIndex < 0) or (AIndex > Count - 1) then
    exit;
  Dec(Count);
  if AIndex = 0 then begin
    if Assigned(FHead) then begin
      if FHead = FTail then
        FTail := nil;
      item := FHead;
      FHead := item^.Next;
      FreeNode(item);
    end;
    exit;
  end;
  prev := GetNode(AIndex - 1);
  item := prev^.Next;
  prev^.Next := item^.Next;
  FreeNode(item);
end;

procedure TLinkedList.MergeSort(AComparer: TComparer; var AHead: PListNode);
var
  head, item1, item2: PListNode;
begin
  head := AHead;
  if (not Assigned(head)) or (not Assigned(head^.Next)) then
      exit;
  FrontBackSplit(head, item1, item2);
  MergeSort(AComparer, item1);
  MergeSort(AComparer, item2);
  AHead := SortedMerge(AComparer, item1, item2);
end;

procedure TLinkedList.FrontBackSplit(ASource: PListNode; var Afront, ABack: PListNode);
var
  fast, slow: PListNode;
begin
  slow := ASource;
  fast := ASource^.Next;
  while Assigned(fast) do begin
    fast := fast^.Next;
    if Assigned(fast) then begin
      slow := slow^.Next;
      fast := fast^.Next;
    end;
  end;
  AFront := ASource;
  ABack := slow^.Next;
  slow^.Next := nil;
end;

function TLinkedList.SortedMerge(AComparer: TComparer; AItem1: PListNode; AItem2: PListNode): PListNode;
var
  result: PListNode;
begin
  result := nil;

  if not Assigned(AItem1) then begin
    SortedMerge := AItem2;
    exit;
  end
  else if not Assigned(AItem2) then begin
    SortedMerge := AItem1;
    exit;
  end;

  if AComparer(AItem1^.Item, AItem2^.Item) <= 0 then begin
    result := AItem1;
    result^.Next := SortedMerge(AComparer, AItem1^.Next, AItem2);
  end
  else begin
    result := AItem2;
    result^.Next := SortedMerge(AComparer, AItem1, AItem2^.Next);
  end;

  SortedMerge := result;
end;

procedure TLinkedList.FreeNode(ANode: PListNode);
begin
  Dispose(ANode);
end;

destructor TLinkedList.Free;
begin
  Clear;
  inherited Free;
end;

procedure TLinkedList.Clear;
begin
  while Count > 0 do
    Delete(0);
end;

procedure TLinkedObjectList.Init;
begin
  inherited Init;
  DisposeObjects := true;
end;

function TLinkedObjectList.Add(AItem: PObject): PListNode;
begin
  Add := inherited Add(AItem);
end;

function TLinkedObjectList.GetItem(AIndex: longint): PObject;
begin
  GetItem := inherited GetItem(AIndex);
end;

procedure TLinkedObjectList.SetItem(AIndex: longint; AItem: PObject);
begin
  inherited SetItem(AIndex, AItem);
end;

function TLinkedObjectList.IndexOf(AItem: PObject): longint;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TLinkedObjectList.Insert(AIndex: longint; AItem: PObject);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TLinkedObjectList.FreeNode(ANode: PListNode);
begin
  if DisposeObjects then
    FreeAndNil(ANode^.Item);
  inherited FreeNode(ANode);
end;

begin
  TStringCompare.Create;
end.