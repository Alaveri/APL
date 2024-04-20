{$I COMPILER.INC}
unit Lists;

interface

uses
  {$IFDEF DOS}
  Strings,
  {$ENDIF}
  AplConst,
  Common,
  Errors,
  StrUtils,
  Objects;

const
  ListBufferSize = $FFF8 div 4;
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
  PCollection = ^TCollection;
  PListBuffer = ^TListBuffer;
  PListNode = ^TListNode;

  TSortFunc = procedure(AList: PList; AComparer: TComparer);
  TListBuffer = array[0..ListBufferSize] of pointer;

  TCollection = object(TExceptionObject)
  private
    FCapacity: integer;
    FBuffer: PListBuffer;
    procedure Grow;
  public
    Count: integer;
    constructor CreateCapacity(ACapacity: integer);
    destructor Free; virtual;
    function Capacity: integer; virtual;
    function Add(AItem: pointer): integer;
    procedure SetCapacity(ACapacity: integer);
    procedure Init; virtual;
    procedure Clear; virtual;
  end;

  TList = object(TCollection)
  private
    FSorted: boolean;
    FComparer: TComparer;
    function GetSortedIndex(AItem: pointer): integer;
    procedure QuickSort(AComparer: TComparer; ALowIndex, AHighIndex: integer);
  public
    constructor CreateSorted(AComparer: TComparer);
    procedure Init; virtual;
    function Add(AItem: pointer): integer;
    function Sorted: boolean; virtual;
    function GetItem(AIndex: integer): pointer;
    function SetItem(AIndex: integer; AItem: pointer): boolean;
    function IndexOf(AItem: pointer): integer;
    procedure SetComparer(AComparer: TComparer);
    procedure Swap(AIndex1, AIndex2: integer);
    procedure Sort(AComparer: TComparer); virtual;
    procedure CustomSort(AComparer: TComparer; ASortFunc: TSortFunc);
    procedure Insert(AIndex: integer; AItem: pointer);
    procedure Delete(AIndex: integer);
  end;

  TListNode = record
    Item: pointer;
    Next: PListNode;
  end;

  TLinkedList = object(TObject)
  private
    FHead: PListNode;
    FTail: PListNode;
    function GetSortedIndex(AItem: pointer): longint;
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
    function SetItem(AIndex: longint; AItem: pointer): boolean;
    function IndexOf(AItem: pointer): longint;
    procedure Swap(var AItem1, AItem2: PListNode);
    procedure Sort(AComparer: TComparer); virtual;
    procedure Insert(AIndex: longint; AItem: pointer);
    procedure Delete(AIndex: longint);
    procedure Clear;
  end;

  TObjectList = object(TList)
  private
  public
    DisposeObjects: boolean;
    destructor Free; virtual;
    function IndexOf(AItem: PObject): integer;
    function Add(AItem: PObject): integer;
    function AddRange(AList: PObjectList; ACopy: boolean): integer; virtual;
    function GetItem(AIndex: integer): PObject;
    function SetItem(AIndex: integer; AItem: PObject): boolean;
    function GetNewObject: PObject; virtual;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PObject);
    procedure Delete(AIndex: integer);
    procedure Clear; virtual;
  end;

  TLinkedObjectList = object(TLinkedList)
  public
    DisposeObjects: boolean;
    procedure Init; virtual;
    function Add(AItem: PObject): PListNode;
    function GetItem(AIndex: longint): PObject;
    function SetItem(AIndex: longint; AItem: PObject): boolean;
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


  TQueue = object(TObjectList)
  private
  public
    procedure Init; virtual;
    function Enqueue(AObject: PObject): integer;
    function Dequeue: PObject;
  end;

  TStringList = object(TList)
  public
    DisposeStrings: boolean;
    destructor Free; virtual;
    function IndexOf(AItem: PChar): integer;
    function Add(AItem: PChar): integer;
    function AddString(const AString: string): integer;
    function GetItem(AIndex: integer): PChar;
    function GetString(AIndex: integer): string;
    procedure Clear; virtual;
    procedure SortStrings;
    procedure Delete(AIndex: integer);
    procedure Insert(AIndex: integer; AItem: PChar);
    procedure Init; virtual;
  end;

  TIdentifiableList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PIdentifiable): integer;
    function Add(AItem: PIdentifiable): integer;
    function GetItemById(const AId: string): PIdentifiable;
    function GetItem(AIndex: integer): PIdentifiable;
    function IndexOfId(const AId: string): integer;
    procedure Insert(AIndex: integer; AItem: PIdentifiable);
  end;

  THeirarchy = object(TObject)
  private
  public
  end;

  TStringComparer = object(TObject)
  private
  public
    function CaseSensitive: PComparer;
    function CaseInsensitive: PComparer;
  end;

var
  TStringCompare: TStringComparer;

implementation

uses
  MemDrv;

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

constructor TCollection.CreateCapacity(ACapacity: integer);
begin
  inherited Create;
  SetCapacity(ACapacity);
end;

procedure TCollection.Init;
begin
  inherited Init;
  Count := 0;
  FBuffer := nil;
  FCapacity := 0;
end;

destructor TCollection.Free;
begin
  if Assigned(FBuffer) then
    FreeMem(FBuffer, FCapacity * PointerSize);
  inherited Free;
end;

function TObjectList.GetNewObject: PObject;
begin
  GetNewObject := New(PObject, Create);
end;

function TObjectList.AddRange(AList: PObjectList; ACopy: boolean): integer;
var
  index: integer;
  obj: PObject;
begin
  for index := 0 to Count - 1 do begin
    if not ACopy then
      AList^.Add(GetItem(index))
    else begin
      obj := GetNewObject;
      obj^.Assign(GetItem(index)^);
      AList^.Add(obj);
    end;
  end;
end;

procedure TCollection.Grow;
var
  newCapacity: integer;
begin
  if FCapacity >= 64 then
    newCapacity := (FCapacity * 3) div 2
  else if FCapacity >= 8 then
    newCapacity := FCapacity + 16
  else
    newCapacity := FCapacity + 4;
  SetCapacity(newCapacity);
end;

procedure TCollection.SetCapacity(ACapacity: integer);
var
  newBuffer: pointer;
  max: word;
  dataSize: longint;
  error: TException;
begin
  if FCapacity = ACapacity then
    exit;
  if ACapacity > ListBufferSize then begin
    Raise(ecCollectionCapacityOverflow);
    exit;
  end;
  dataSize := longint(ACapacity) * PointerSize;
  if longint(dataSize) > MaxVarSize then begin
    dataSize := MaxVarSize;
    ACapacity := MaxVarSize div PointerSize;
  end;
  if not Assigned(FBuffer) then begin
    GetMem(FBuffer, dataSize);
    if not Assigned(FBuffer) then begin
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
    Move(FBuffer^, newBuffer^, dataSize);
    FreeMem(FBuffer, FCapacity * PointerSize);
  end;
  FBuffer := newBuffer;
  FCapacity := ACapacity;
  if Count > FCapacity then
    Count := FCapacity;
end;

function TCollection.Capacity: integer;
begin
  Capacity := FCapacity;
end;

function TCollection.Add(AItem: pointer): integer;
begin
  if Count + 1 > FCapacity then begin
    Grow;
    if HasException then
      exit;
  end;
  FBuffer^[Count] := AItem;
  Add := Count;
  Inc(Count);
end;

procedure TCollection.Clear;
begin
  if Assigned(FBuffer) then
    FreeMem(FBuffer, FCapacity *  PointerSize);
  Count := 0;
  FBuffer := nil;
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
    if (AHighIndex - ALowIndex) = 1 then begin
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

procedure TList.SetComparer(AComparer: TComparer);
begin
  FComparer := AComparer;
  Sort(FComparer);
end;

procedure TList.Init;
begin
  inherited Init;
  FSorted := false;
  FComparer := nil;
end;

function TList.Sorted: boolean;
begin
  Sorted := FSorted;
end;

function TList.Add(AItem: pointer): integer;
var
  ptr: PPointer;
  index: integer;
begin
  if Count + 1 > FCapacity then begin
    Grow;
    if HasException then
      exit;
  end;
  index := Count;
  if FSorted then
    index := GetSortedIndex(AItem);
  if index = Count then begin
    FBuffer^[index] := AItem;
    Inc(Count);
  end
  else
    Insert(index, AItem);
  Add := index;
end;

function TList.GetItem(AIndex: integer): pointer;
begin
  GetItem := nil;
  if (AIndex < 0) or (AIndex > Count - 1) then
    exit;
  GetItem := FBuffer^[AIndex];
end;

function TList.SetItem(AIndex: integer; AItem: pointer): boolean;
begin
  SetItem := true;
  if (AIndex < 0) or (AIndex > Count - 1) then begin
    SetItem := false;
    exit;
  end;
  FBuffer^[AIndex] := AItem;
end;

function TList.IndexOf(AItem: pointer): integer;
var
  index: integer;
  current: pointer;
begin
  IndexOf := -1;
  if Count = 0 then
    exit;
  index := 0;
  repeat
    current := GetItem(index);
    if AItem = current then begin
      IndexOf := index;
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

procedure TList.Sort(AComparer: TComparer);
begin
  if Count < 2 then exit;
  QuickSort(AComparer, 0, Count - 1);
end;

function TList.GetSortedIndex(AItem: pointer): integer;
var
  compared: integer;
  upper, lower, middle: integer;
  item2: pointer;
begin
  GetSortedIndex := 0;
  if Count = 0 then
    exit;
  lower := 0;
  upper := Count - 1;
  while lower <= upper do begin
    middle := lower + (upper - lower) shr 1;
    item2 := GetItem(middle);
    compared := FComparer(item2, AItem);
    if compared = 0 then begin
      GetSortedIndex := middle;
      exit;
    end;
    if compared < 0 then
      lower := middle + 1
    else if compared > 0 then
      upper := middle - 1;
  end;
  GetSortedIndex := lower;
end;

procedure TList.Insert(AIndex: integer; AItem: pointer);
var
  ptr, next: PPointer;
begin
  if Count + 1 > FCapacity then begin
    Grow;
    if HasException then
      exit;
  end;
  if AIndex > Count - 1 then begin
    Add(AItem);
    exit;
  end;
  ptr := pointer(FBuffer);
  Inc(ptr, AIndex);
  next := ptr;
  Inc(next);
  Move(ptr^, next^, (longint(Count) - AIndex) * PointerSize);
  ptr^ := AItem;
  Inc(Count);
end;

procedure TList.Delete(AIndex: integer);
var
  ptr, next: PPointer;
begin
  if (AIndex < 0) or (AIndex > Count - 1) then
    exit;
  ptr := pointer(FBuffer);
  Inc(ptr, AIndex);
  next := ptr;
  Inc(next);
  Move(next^, ptr^, (Count - AIndex - 1) * PointerSize);
  Dec(Count);
end;

procedure TObjectList.Init;
begin
  inherited Init;
  DisposeObjects := true;
end;

destructor TObjectList.Free;
begin;
  Clear;
  inherited Free;
end;

function TObjectList.IndexOf(AItem: PObject): integer;
begin
  IndexOf := TList.IndexOf(AItem);
end;

function TObjectList.Add(AItem: PObject): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TObjectList.Insert(AIndex: integer; AItem: PObject);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TObjectList.Delete(AIndex: integer);
var
  obj: PObject;
begin
  if (AIndex < 0) or (AIndex > Count - 1) then
    exit;
  obj := GetItem(AIndex);
  if DisposeObjects then
    FreeAndNil(obj);
  inherited Delete(AIndex);
end;

procedure TObjectList.Clear;
begin
  if DisposeObjects then
    while Count > 0 do
      Delete(0);
  inherited Clear;
end;

function TObjectList.SetItem(AIndex: integer; AItem: PObject): boolean;
begin
  SetItem := inherited SetItem(AIndex, AItem);
end;

function TObjectList.GetItem(AIndex: integer): PObject;
begin
  GetItem := inherited GetItem(AIndex);
end;

procedure TQueue.Init;
begin
  inherited Init;
  DisposeObjects := false;
end;

function TQueue.Enqueue(AObject: PObject): integer;
begin
  Add(AObject);
end;

function TQueue.Dequeue: PObject;
begin
  Dequeue := nil;
  if Count = 0 then
    exit;
  Dequeue := GetItem(0);
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
  DisposeStrings := true;
end;

function TStringList.IndexOf(AItem: PChar): integer;
begin
  IndexOf := TList.IndexOf(AItem);
end;

function TStringList.Add(AItem: PChar): integer;
begin
  Add := inherited Add(AItem);
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

procedure TStringList.Insert(AIndex: integer; AItem: PChar);
begin
  TList.Insert(AIndex, AItem);
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

procedure TStringList.SortStrings;
begin
  Sort(TStringCompare.CaseInsensitive^);
end;

procedure TStringList.Clear;
begin
  if DisposeStrings then
    while Count > 0 do
      Delete(0);
  inherited Clear;
end;

destructor TStringList.Free;
begin;
  Clear;
  inherited Free;
end;

function TIdentifiableList.IndexOf(AItem: PIdentifiable): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TIdentifiableList.Add(AItem: PIdentifiable): integer;
begin
  Add := inherited Add(AItem);
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

procedure TIdentifiableList.Insert(AIndex: integer; AItem: PIdentifiable);
begin
  inherited Insert(AIndex, AItem);
end;

function TLinkedList.GetSortedIndex(AItem: pointer): longint;
begin
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

function TLinkedList.SetItem(AIndex: longint; AItem: pointer): boolean;
var
  node: PListNode;
begin
  SetItem := false;
  node := GetNode(AIndex);
  if Assigned(node) then begin
    SetItem := true;
    node^.Item := AItem;
  end;
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
  AIndex := MaxLong(AIndex, 0);
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

function TLinkedObjectList.SetItem(AIndex: longint; AItem: PObject): boolean;
begin
  SetItem := inherited SetItem(AIndex, AItem);
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