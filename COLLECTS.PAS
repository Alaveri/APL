{$I COMPILER.INC}
unit Collects;

interface

uses
  Consts,
  Utils,
  Strings,
  StrUtils,
  Objects;

type

  TCollection = object(TObject)
  private
    _buffer: pointer;
    _capacity: integer;
  public
    Count: integer;
    { Constructors/Destructors and Initialization }
    constructor CreateCapacity(initialCapacity: integer);
    destructor Done; virtual;
    procedure Init; virtual;

    { Properties }
    function Capacity: integer; virtual;

    { Modification Functions }
    function Add(item: pointer): integer;
    procedure Delete(index: integer);
    procedure Clear; virtual;

    { Misc Functions }
    function ToString: string; virtual;
    function GetTypeName: string; virtual;
    procedure SetCapacity(cap: integer);
  end;
  PList = ^TList;
  TList = object(TCollection)
  private
    _sorted: boolean;
    _comparer: TComparer;
  public
    { Constructors/Destructors and Initialization }
    constructor CreateSorted(comparer: TComparer);
    procedure Init; virtual;

    { Modification Functions }
    function Add(item: pointer): integer;

    { Sorting Functions }
    function GetSortedIndex(item: pointer): integer; virtual;
    procedure Sort(comparer: TComparer); virtual;
    function Sorted: boolean; virtual;

    { Index-Based Functions }
    function GetItem(index: integer): pointer;
    procedure SetItem(index: integer; item: pointer);
    function IndexOf(item: pointer): integer;
    procedure Insert(index: integer; item: pointer);

    { Misc Functions }
    function Where(predicate: TPredicate; var value): PList;
    function GetTypeName: string; virtual;
  end;
  PObjectList = ^TObjectList;
  TObjectList = object(TList)
  private
  public
    DisposeObjects: boolean;
    destructor Done; virtual;
    procedure Init; virtual;
    function ToString: string; virtual;
    function GetItem(index: integer): PObject;
    function GetItemById(idToFind: string): PObject;
    function IndexOf(item: PObject): integer;
    function IndexOfId(idToFind: string): integer; virtual;
    function Add(item: PObject): integer;
    function GetTypeName: string; virtual;
    procedure Insert(index: integer; item: PObject);
    procedure Delete(index: integer);
    procedure Clear; virtual;
  end;
  PStack = ^TStack;
  TStack = object(TObjectList)
  private
  public
    procedure Init; virtual;
    function Push(obj: PObject): integer;
    function Pop: PObject;
    function GetTypeName: string; virtual;
  end;
  PStringList = ^TStringList;
  TStringList = object(TList)
    procedure Init; virtual;
    function ToString: string; virtual;
    function GetItem(index: integer): PChar;
    function IndexOf(item: PChar): integer;
    function Add(item: PChar): integer;
    procedure Insert(index: integer; item: PChar);
    function GetTypeName: string; virtual;
  end;

implementation

constructor TCollection.CreateCapacity(initialCapacity: integer);
begin
  Init;
  SetCapacity(initialCapacity);
end;

procedure TCollection.Init;
begin
  inherited Init;
  Count := 0;
  _buffer:= nil;
  _capacity := 0;
end;

destructor TCollection.Done;
begin
  if (_buffer <> nil) then FreeMem(_buffer, _capacity * SizeOf(Pointer));
  inherited Done;
end;

function TCollection.GetTypeName;
begin
  GetTypeName := 'TCollection';
end;

procedure TCollection.SetCapacity(cap: integer);
var
  newBuffer: pointer;
  max: word;
  dataSize: word;
  error: TError;
begin
  if (_capacity = cap) then exit;
  dataSize := cap * SizeOf(Pointer);
  GetMem(newBuffer, dataSize);
  if (newBuffer = nil) then
  begin
    if (OnAllocationError <> nil) then
      TAllocationError(OnAllocationError^)(error);
    exit;
  end;
  FillChar(newBuffer^, dataSize, 0);
  if (_capacity > 0) and (_buffer <> nil) then
  begin
    if (cap > _capacity) then
      Move(_buffer^, newBuffer^, _capacity * SizeOf(pointer))
    else
      Move(_buffer^, NewBuffer^, cap * SizeOf(pointer));
    FreeMem(_buffer, _capacity * SizeOf(pointer));
  end;
  _buffer := newBuffer;
  _capacity := cap;
  if Count > _capacity then
    Count := _capacity;
end;

function TCollection.Capacity: integer;
begin
  Capacity := _capacity;
end;

function TCollection.Add(item: pointer): integer;
var
  newCap: word;
  itemLoc: PPointer;
  index: integer;
begin
  if (Count + 1 > _capacity) then
  begin
    newCap := _capacity * 2;
    SetCapacity(newCap);
  end;
  index := Count;
  itemLoc := pointer(LongInt(_buffer) + 4 * index);
  Inc(Count);
  itemLoc^ := item;
end;

procedure TCollection.Delete(index: integer);
var
  newCap: LongInt;
  itemLoc: pointer;
  locIndex: LongInt;
begin
  for locIndex := index to Count - 1  do
  begin
    itemLoc := pointer(LongInt(_buffer) + locIndex * 4);
    Move(pointer(LongInt(itemLoc) + 4)^, itemLoc^, 4);
  end;
  Dec(Count);
end;

procedure TCollection.Clear;
begin
  FreeMem(_buffer, _capacity *  SizeOf(pointer));
  Count := 0;
  _buffer := nil;
  _capacity := 0;
  SetCapacity(DefaultListCapacity);
end;

function TCollection.ToString: string;
begin
  ToString := 'TCollection';
end;

constructor TList.CreateSorted(comparer: TComparer);
begin
  Init;
  _comparer := comparer;
  _sorted := true;
  SetCapacity(DefaultListCapacity);
end;

procedure TList.Init;
begin
  inherited Init;
  _sorted := false;
  _comparer := nil;
end;

function TList.GetTypeName;
begin
  GetTypeName := 'TList';
end;


function TList.Sorted: boolean;
begin
  Sorted := _sorted;
end;

procedure TList.SetItem(index: integer; item: pointer);
var
  itemLoc: pointer;
begin
  itemLoc := Pointer(LongInt(_buffer) + 4 * index);
  Move(itemLoc^, item, 4);
end;

function TList.GetItem(index: integer): pointer;
var
  itemLoc: pointer;
  result: pointer;
begin
  if (index < 0) or (index > Count) then
  begin
    GetItem := nil;
    Exit;
  end;
  itemLoc := Pointer(LongInt(_buffer) + 4 * index);
  Move(itemLoc^, result, 4);
  GetItem := result;
end;

function TList.Add(item: pointer): integer;
var
  newCap: word;
  itemLoc: PPointer;
  index: integer;
begin
  if (_capacity = 0) then SetCapacity(DefaultListCapacity);
  if (Count + 1 > _capacity) then
  begin
    newCap := _capacity * 2;
    SetCapacity(newCap);
  end;
  index := Count;
  if (_sorted) then
  begin
    index := GetSortedIndex(item);
  end;
  if (index = Count) then
  begin
    itemLoc := pointer(LongInt(_buffer) + 4 * index);
    Inc(Count);
    itemLoc^ := item;
  end
  else
    Insert(index, item);
end;

function TList.IndexOf(item: pointer): integer;
var
  index: integer;
  current: pointer;
  itemLoc: PPointer;
begin
  IndexOf := -1;
  if (Count = 0) then
    Exit;
  index := 0;
  repeat
    if (index > Count) then
      break;
    itemLoc := pointer(LongInt(_buffer) + 4 * index);
    current := itemLoc^;
    if (item = current) then
    begin
      IndexOf := index;
      break;
    end;
    Inc(index);
  until false;
end;

procedure TList.Sort(comparer: TComparer);
  procedure QuickSort(lowIndex, highIndex: integer);
  var
    low, high: integer;
    pivot, temp, lowItem, highItem: pointer;
  begin
    low := lowIndex;
    high := highIndex;
    lowItem := GetItem(lowIndex);
    highItem := GetItem(highIndex);
    pivot := GetItem((lowIndex + highIndex) div 2);
    repeat
      while comparer(lowItem, pivot) < 0 do
        Inc(low) ;
      while comparer(highItem, pivot) > 0 do
        Dec(high);
      if low <= high then
      begin
        temp := GetItem(low);
        SetItem(low, GetItem(high));
        SetItem(high, temp);
        Inc(low) ;
        Dec(high) ;
      end;
    until low > high;
    if high > lowIndex then
      QuickSort(lowIndex, high);
    if low < high then
      QuickSort(low, highIndex);
  end;
begin
  if (Count = 0) then exit;
  QuickSort(0, Count - 1);
end;

function TList.GetSortedIndex(item: pointer): integer;
var
  compared: integer;
  upper, lower, middle: integer;
  item2: pointer;
begin
  GetSortedIndex := 0;
  if (Count = 0) then exit;
  if (Count = 1) then
  begin
    if (TComparer(_comparer)(item, GetItem(0)) < 0) then
      GetSortedIndex := 0
    else
      GetSortedIndex := 1;
  end;
  upper := Count;
  lower := 0;
  repeat
    middle := (upper + lower) div 2;
    item2 := GetItem(middle);
    compared := TComparer(_comparer)(item, item2);
    if (compared < 0) then
      lower := middle
    else if (compared > 0) then
      upper := middle
    else
    begin
      middle := upper;
      break;
    end;
  until (upper = lower);
  GetSortedIndex := middle;
end;

procedure TList.Insert(index: integer; item: pointer);
var
  newCap: integer;
  itemLoc: PPointer;
  locIndex: integer;
begin
  if (_capacity = 0) then SetCapacity(DefaultListCapacity);
  if (Count + 1 > _capacity) then
  begin
    newCap := _capacity * 2;
    SetCapacity(newCap);
  end;
  for locIndex := Count - 1 downto index do
  begin
    itemLoc := pointer(LongInt(_buffer) + locIndex * 4);
    Move(itemLoc^, pointer(LongInt(itemLoc) + 4)^, 4);
  end;
  Inc(Count);
  itemLoc^ := item;
end;

function TList.Where(predicate: TPredicate; var value): PList;
var
  result: PList;
  index: integer;
  item: pointer;
begin
  result := New(PList, Create);
  Where := result;
  if (Count = 0) then exit;
  for index := 0 to Count - 1 do
  begin
    item := GetItem(index);
    if predicate(item, value) then
      result^.Add(item);
  end;
end;

procedure TObjectList.Init;
begin
  TList.Init;
  DisposeObjects := true;
end;

function TObjectList.GetTypeName;
begin
  GetTypeName := 'TObjectList';
end;

destructor TObjectList.Done;
var
  index: integer;
  item: PObject;
begin;
  if DisposeObjects then
  begin
    for index := 0 to Count - 1 do
    begin;
      item := GetItem(index);
      Dispose(item, Done);
    end;
  end;
  inherited Done;
end;

function TObjectList.ToString: string;
begin
  ToString := 'TObjectList';
end;

function TObjectList.GetItem(index: integer): PObject;
begin
  GetItem := TList.GetItem(index);
end;

function TObjectList.IndexOf(item: PObject): integer;
begin
  IndexOf := TList.IndexOf(item);
end;

function TObjectList.IndexOfId(idToFind: string): integer;
var
  index, len: integer;
  largeId: PChar;
begin
  IndexOfId := -1;
  for index := 0 to Count - 1 do
  begin
    largeId := GetItem(index)^.Id;
    if LargeShortCompare(idToFind, largeId) then begin
      IndexOfId := index;
      break;
    end;
  end;
end;

function TObjectList.GetItemById(idToFind: string): PObject;
var
  index: integer;
begin
  GetItemById := nil;
  index := IndexOfId(idToFind);
  if (index >= 0) then GetItemById := GetItem(index);
end;

function TObjectList.Add(item: PObject): integer;
begin
  Add := TList.Add(item);
end;

procedure TObjectList.Insert(index: integer; item: PObject);
begin
  TList.Insert(index, item);
end;

procedure TObjectList.Delete(index: integer);
var
  obj: PObject;
begin
  if (Count = 0) then exit;
  obj := GetItem(index);
  if (DisposeObjects) then
    Dispose(obj);
  TList.Delete(index);
end;

procedure TObjectList.Clear;
var
  index: integer;
  item: PObject;
begin
  if (DisposeObjects) and (Count > 0) then
  begin
    for index := 0 to Count - 1 do
    begin
    Dispose(GetItem(index), Done);
    end;
  end;
  TList.Clear;
end;

procedure TStack.Init;
begin
  TObjectList.Init;
  DisposeObjects := false;
end;

function TStack.GetTypeName;
begin
  GetTypeName := 'TStack';
end;

function TStack.Push(obj: PObject): integer;
begin
  Push := Add(obj);
end;

function TStack.Pop: PObject;
begin
  Pop := nil;
  if (Count = 0) then exit;
  Pop := GetItem(Count - 1);
  Delete(Count - 1);
end;

procedure TStringList.Init;
begin
  TList.Init;
end;

function TStringList.GetTypeName;
begin
  GetTypeName := 'TStringList';
end;


function TStringList.ToString: string;
begin
  ToString := GetTypeName;
end;

function TStringList.GetItem(index: integer): PChar;
begin
  GetItem := TList.GetItem(index);
end;

function TStringList.IndexOf(item: PChar): integer;
begin
  IndexOf := TList.IndexOf(item);
end;

function TStringList.Add(item: PChar): integer;
begin
  TList.Add(item);
end;

procedure TStringList.Insert(index: integer; item: PChar);
begin
  TList.Insert(index, item);
end;

end.