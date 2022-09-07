{$ifndef fpc}
{$ifdef debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$else}
  {$A-,B-,D-,E+,F+,G+,I-,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$endif}
{$endif}

unit Collects;

interface

uses
  Consts,
  Common,
  Strings,
  Objects;

type
  TPredicate = function(item: pointer; var value): boolean;

  TCollection = object(TBaseObject)
  private
    fBuffer: pointer;
    fCapacity: integer;
  public
    Count: integer;
    { Constructors/Destructors and Initialization }
    constructor CreateCapacity(initialCapacity: integer);
    destructor Destroy; virtual;
    procedure Init; virtual;

    { Properties }
    function Capacity: integer; virtual;

    { Modification Functions }
    function Add(item: pointer): integer;
    procedure Delete(index: integer);
    procedure Clear; virtual;

    { Misc Functions }
    function ToString: ShortString; virtual;
    function GetTypeName: ShortString; virtual;
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
    function GetTypeName: ShortString; virtual;
  end;
  PNamedObjectList = ^TNamedObjectList;
  TNamedObjectList = object(TList)
  private
  public
    DisposeObjects: boolean;
    destructor Destroy; virtual;
    procedure Init; virtual;
    function ToString: ShortString; virtual;
    function GetItem(const index: integer): PNamedObject;
    function GetItemByName(const aName: ShortString): PNamedObject;
    function IndexOfName(const aName: ShortString): integer; virtual;
    function Add(const item: PNamedObject): integer;
    function GetTypeName: ShortString; virtual;
    procedure Insert(const index: integer; const item: PNamedObject);
    procedure Delete(const index: integer);
    procedure Clear; virtual;
  end;
  PStack = ^TStack;
  TStack = object(TNamedObjectList)
  private
  public
    procedure Init; virtual;
    function Push(obj: PNamedObject): integer;
    function Pop: PNamedObject;
    function GetTypeName: ShortString; virtual;
  end;
  PWideStringList = ^TWideStringList;
  TWideStringList = object(TList)
    procedure Init; virtual;
    function ToString: ShortString; virtual;
    function GetItem(index: integer): PWideString;
    function IndexOf(item: PWideString): integer;
    function Add(item: PWideString): integer;
    procedure Insert(index: integer; item: PWideString);
    function GetTypeName: ShortString; virtual;
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
  fBuffer:= nil;
  fCapacity := 0;
end;

destructor TCollection.Destroy;
begin
  if (fBuffer <> nil) then FreeMem(fBuffer, fCapacity * SizeOf(Pointer));
  inherited Destroy;
end;

function TCollection.GetTypeName: ShortString;
begin
  GetTypeName := 'TCollection';
end;

procedure TCollection.SetCapacity(cap: integer);
var
  newBuffer: pointer;
  max: word;
  dataSize: word;
  error: TErr;
begin
  if (fCapacity = cap) then exit;
  dataSize := cap * SizeOf(Pointer);
  GetMem(newBuffer, dataSize);
  if (newBuffer = nil) then
  begin
    if (OnAllocationError <> nil) then
      TAllocationError(OnAllocationError^)(error);
    exit;
  end;
  FillChar(newBuffer^, dataSize, 0);
  if (fCapacity > 0) and (fBuffer <> nil) then
  begin
    if (cap > fCapacity) then
      Move(fBuffer^, newBuffer^, fCapacity * SizeOf(pointer))
    else
      Move(fBuffer^, NewBuffer^, cap * SizeOf(pointer));
    FreeMem(fBuffer, fCapacity * SizeOf(pointer));
  end;
  fBuffer := newBuffer;
  fCapacity := cap;
  if Count > fCapacity then
    Count := fCapacity;
end;

function TCollection.Capacity: integer;
begin
  Capacity := fCapacity;
end;

function TCollection.Add(item: pointer): integer;
var
  newCap: word;
  itemLoc: PPointer;
  index: integer;
begin
  if (Count + 1 > fCapacity) then
  begin
    newCap := fCapacity * 2;
    SetCapacity(newCap);
  end;
  index := Count;
  itemLoc := pointer(LongInt(fBuffer) + 4 * index);
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
    itemLoc := pointer(LongInt(fBuffer) + locIndex * 4);
    Move(pointer(LongInt(itemLoc) + 4)^, itemLoc^, 4);
  end;
  Dec(Count);
end;

procedure TCollection.Clear;
begin
  FreeMem(fBuffer, fCapacity *  SizeOf(pointer));
  Count := 0;
  fBuffer := nil;
  fCapacity := 0;
  SetCapacity(DefaultListCapacity);
end;

function TCollection.ToString: ShortString;
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

function TList.GetTypeName: ShortString;
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
  itemLoc := Pointer(LongInt(fBuffer) + 4 * index);
  Move(itemLoc^, item, 4);
end;

function TList.GetItem(index: integer): pointer;
var
  itemLoc: pointer;
  ptr: pointer;
begin
  if (index < 0) or (index > Count) then
  begin
    GetItem := nil;
    Exit;
  end;
  itemLoc := Pointer(LongInt(fBuffer) + 4 * index);
  Move(itemLoc^, ptr, 4);
  GetItem := result;
end;

function TList.Add(item: pointer): integer;
var
  newCap: word;
  itemLoc: PPointer;
  index: integer;
begin
  if (fCapacity = 0) then SetCapacity(DefaultListCapacity);
  if (Count + 1 > fCapacity) then
  begin
    newCap := fCapacity * 2;
    SetCapacity(newCap);
  end;
  index := Count;
  if (_sorted) then
  begin
    index := GetSortedIndex(item);
  end;
  if (index = Count) then
  begin
    itemLoc := pointer(LongInt(fBuffer) + 4 * index);
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
    itemLoc := pointer(LongInt(fBuffer) + 4 * index);
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
  if (fCapacity = 0) then SetCapacity(DefaultListCapacity);
  if (Count + 1 > fCapacity) then
  begin
    newCap := fCapacity * 2;
    SetCapacity(newCap);
  end;
  for locIndex := Count - 1 downto index do
  begin
    {$ifdef fpc}
    itemLoc := pointer(Cardinal(fBuffer) + locIndex * 4);
    Move(itemLoc^, pointer(Cardinal(itemLoc) + 4)^, 4);
    {$else}
    itemLoc := pointer(LongInt(fBuffer) + locIndex * 4);
    Move(itemLoc^, pointer(LongInt(itemLoc) + 4)^, 4);
    {$endif}
  end;
  Inc(Count);
  itemLoc^ := item;
end;

function TList.Where(predicate: TPredicate; var value): PList;
var
  list: PList;
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

procedure TNamedObjectList.Init;
begin
  TList.Init;
  DisposeObjects := true;
end;

function TNamedObjectList.GetTypeName: ShortString;
begin
  GetTypeName := 'TNamedObjectList';
end;

destructor TNamedObjectList.Destroy;
var
  index: integer;
  item: PNamedObject;
begin;
  if DisposeObjects then
  begin
    for index := 0 to Count - 1 do
    begin;
      item := GetItem(index);
      Dispose(item, Destroy);
    end;
  end;
  inherited Destroy;
end;

function TNamedObjectList.ToString: ShortString;
begin
  ToString := 'TNamedObjectList';
end;

function TNamedObjectList.GetItem(const index: integer): PNamedObject;
begin
  GetItem := TList.GetItem(index);
end;

function TNamedObjectList.IndexOfName(const aName: ShortString): integer;
var
  index: integer;
begin
  IndexOfName := -1;
  for index := 0 to Count - 1 do
  begin
    if  (aName = GetItem(index)^.Name) then begin
      IndexOfName := index;
      break;
    end;
  end;
end;

function TNamedObjectList.GetItemByName(const aName: ShortString): PNamedObject;
var
  index: integer;
begin
  GetItemByName := nil;
  index := IndexOfName(aName);
  if (index >= 0) then GetItemByName := GetItem(index);
end;

function TNamedObjectList.Add(const item: PNamedObject): integer;
begin
  Add := TList.Add(item);
end;

procedure TNamedObjectList.Insert(const index: integer; const item: PNamedObject);
begin
  TList.Insert(index, item);
end;

procedure TNamedObjectList.Delete(const index: integer);
var
  obj: PNamedObject;
begin
  if (Count = 0) then exit;
  obj := GetItem(index);
  if (DisposeObjects) then
    Dispose(obj);
  TList.Delete(index);
end;

procedure TNamedObjectList.Clear;
var
  index: integer;
  item: PNamedObject;
begin
  if (DisposeObjects) and (Count > 0) then
  begin
    for index := 0 to Count - 1 do
    begin
    Dispose(GetItem(index), Destroy);
    end;
  end;
  TList.Clear;
end;

procedure TStack.Init;
begin
  TNamedObjectList.Init;
  DisposeObjects := false;
end;

function TStack.GetTypeName: ShortString;
begin
  GetTypeName := 'TStack';
end;

function TStack.Push(obj: PNamedObject): integer;
begin
  Push := Add(obj);
end;

function TStack.Pop: PNamedObject;
begin
  Pop := nil;
  if (Count = 0) then exit;
  Pop := GetItem(Count - 1);
  Delete(Count - 1);
end;

procedure TWideStringList.Init;
begin
  TList.Init;
end;

function TWideStringList.GetTypeName: ShortString;
begin
  GetTypeName := 'TWideStringList';
end;


function TWideStringList.ToString: ShortString;
begin
  ToString := GetTypeName;
end;

function TWideStringList.GetItem(index: integer): PWideString;
begin
  GetItem := TList.GetItem(index);
end;

function TWideStringList.IndexOf(item: PWideString): integer;
begin
  IndexOf := TList.IndexOf(item);
end;

function TWideStringList.Add(item: PWideString): integer;
begin
  TList.Add(item);
end;

procedure TWideStringList.Insert(index: integer; item: PWideString);
begin
  TList.Insert(index, item);
end;

end.
