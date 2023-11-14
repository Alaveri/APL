{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Collects;

interface

uses
  Consts,
  Common,
  Except,
  Strings,
  StrUtils,
  Objects;

type
  PObjectList = ^TObjectList;
  PList = ^TList;
  PStack = ^TStack;
  PStringList = ^TStringList;
  PSortFunc = ^TSortFunc;
  PComperer = ^TComparer;
  PCollection = ^TCollection;

  TSortFunc = procedure(AList: PList; AComparer: TComparer);

  TCollection = object(TExceptionObject)
  private
    FBuffer: PPointer;
    FCapacity: integer;
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
    procedure QuickSort(AComparer: TComparer; ALowIndex, AHighIndex: integer);
  public
    constructor CreateSorted(AComparer: TComparer);
    procedure Init; virtual;
    function Add(AItem: pointer): integer;
    function GetSortedIndex(AItem: pointer): integer; virtual;
    function Sorted: boolean; virtual;
    function GetItem(AIndex: integer): pointer;
    function SetItem(AIndex: integer; AItem: pointer): boolean;
    function IndexOf(AItem: pointer): integer;
    function Where(APredicate: TPredicate; var AValue): PList;
    procedure Swap(AIndex1, AIndex2: integer);
    procedure Sort(AComparer: TComparer); virtual;
    procedure CustomSort(AComparer: TComparer; ASortFunc: TSortFunc);
    procedure Insert(AIndex: integer; AItem: pointer);
    procedure Delete(AIndex: integer);
  end;

  TObjectList = object(TList)
  private
  public
    DisposeObjects: boolean;
    destructor Free; virtual;
    procedure Init; virtual;
    function GetItem(AIndex: integer): PObject;
    function IndexOf(AItem: PObject): integer;
    function Add(AItem: PObject): integer;
    procedure Insert(AIndex: integer; AItem: PObject);
    procedure Delete(AIndex: integer);
    procedure Clear; virtual;
  end;

  TStack = object(TObjectList)
  private
  public
    procedure Init; virtual;
    function Push(AObject: PObject): integer;
    function Pop: PObject;
  end;

  TStringList = object(TList)
  public
    DisposeStrings: boolean;
    destructor Free; virtual;
    function GetItem(AIndex: integer): PChar;
    function IndexOf(AItem: PChar): integer;
    function Add(AItem: PChar): integer;
    function AddShortString(const AString: string): integer;
    procedure Clear; virtual;
    procedure SortStrings;
    procedure Delete(AIndex: integer);
    procedure Insert(AIndex: integer; AItem: PChar);
    procedure Init; virtual;
  end;

  TIdentifiableList = object(TObjectList)
  private
  public
    function GetItem(AIndex: integer): PIdentifiable;
    function IndexOf(AItem: PIdentifiable): integer;
    function Add(AItem: PIdentifiable): integer;
    function GetItemById(const AId: string): PIdentifiable;
    function IndexOfId(const AId: string): integer;
    procedure Insert(AIndex: integer; AItem: PIdentifiable);
  end;


function StringCompare(AItem1, AItem2: pointer): integer; far;

implementation

uses
  MemDrv;

function StringCompare(AItem1, AItem2: pointer): integer;
var
  str1: PChar;
  str2: PChar;
begin
  str1 := PChar(AItem1);
  str2 := PChar(AItem2);
  StringCompare := StrComp(str1, str2);
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
  FBuffer:= nil;
  FCapacity := 0;
end;

destructor TCollection.Free;
begin
  if FBuffer <> nil then
    FreeMem(FBuffer, longint(FCapacity) * PointerSize);
  inherited Free;
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
  if ACapacity * PointerSize > MaxVarSize then begin
    Raise(ecCollectionCapacityOverflow);
    exit;
  end;
  dataSize := longint(ACapacity) * PointerSize;
  if longint(dataSize) > MaxVarSize then begin
    dataSize := MaxVarSize;
    ACapacity := MaxVarSize div PointerSize;
  end;
  if FBuffer = nil then begin
    GetMem(FBuffer, dataSize);
    if FBuffer = nil then
      Raise(ecNotEnoughMemory)
    else
      FCapacity := ACapacity;
    exit;
  end;
  GetMem(newBuffer, dataSize);
  if newBuffer = nil then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  if FCapacity > 0 then begin
    if ACapacity > FCapacity then
      Move(FBuffer^, newBuffer^, longint(FCapacity) * PointerSize)
    else
      Move(FBuffer^, newBuffer^, dataSize);
    FreeMem(FBuffer, longint(FCapacity) * PointerSize);
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
var
  itemLoc: PPointer;
  index: integer;
begin
  if Count + 1 > FCapacity then begin
    Grow;
    if HasException then
      exit;
  end;
  index := Count;
  itemLoc := FBuffer;
  Inc(itemLoc, index);
  Inc(Count);
  itemLoc^ := AItem;
  Add := index;
end;

procedure TCollection.Clear;
begin
  if (FBuffer <> nil) and (FCapacity > 0) then
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
  if (Count < 2 ) then
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

function TList.SetItem(AIndex: integer; AItem: pointer): boolean;
var
  ptr: PPointer;
begin
  SetItem := true;
  if (AIndex < 0) or (AIndex > Count - 1) then begin
    SetItem := false;
    exit;
  end;
  ptr := FBuffer;
  Inc(ptr, AIndex);
  Move(AItem, ptr^, PointerSize);
end;

function TList.GetItem(AIndex: integer): pointer;
var
  ptr: PPointer;
  result: pointer;
begin
  if (AIndex < 0) or (AIndex > Count - 1) then begin
    GetItem := nil;
    exit;
  end;
  ptr := FBuffer;
  Inc(ptr, AIndex);
  Move(ptr^, result, PointerSize);
  GetItem := result;
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
  if FSorted then begin
    index := GetSortedIndex(AItem);
  end;
  if (index = Count) then begin
    ptr := FBuffer;
    Inc(ptr, index);
    Inc(Count);
    ptr^ := AItem;
  end
  else
    Insert(index, AItem);
  Add := index;
end;

function TList.IndexOf(AItem: pointer): integer;
var
  index: integer;
  current: pointer;
  ptr: PPointer;
begin
  IndexOf := -1;
  if Count = 0 then
    exit;
  index := 0;
  repeat
    ptr := FBuffer;
    Inc(ptr, index);
    current := ptr^;
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
  ptr, nextPtr: PPointer;
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
  ptr := FBuffer;
  Inc(ptr, AIndex);
  nextPtr := Ptr;
  Inc(nextPtr);
  Move(ptr^, nextPtr^, (longint(Count) - AIndex) * PointerSize);
  Inc(Count);
  ptr^ := AItem;
end;

procedure TList.Delete(AIndex: integer);
var
  ptr: PPointer;
  nextPtr: PPointer;
  locIndex: LongInt;
begin
  if (AIndex < 0) or (AIndex > Count - 1) then
    exit;
  ptr := FBuffer;
  Inc(ptr, AIndex);
  nextPtr := ptr;
  Inc(nextPtr);
  Move(nextPtr^, ptr^, (longint(Count) - AIndex - 1) * PointerSize);
  Dec(Count);
end;

function TList.Where(APredicate: TPredicate; var AValue): PList;
var
  result: PList;
  index: integer;
  item: pointer;
begin
  result := New(PList, Create);
  Where := result;
  if (Count = 0) then
    exit;
  for index := 0 to Count - 1 do begin
    item := GetItem(index);
    if APredicate(item, AValue) then
      result^.Add(item);
  end;
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

function TObjectList.GetItem(AIndex: integer): PObject;
begin
  GetItem := TList.GetItem(AIndex);
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
    Dispose(obj, Free);
  TList.Delete(AIndex);
end;

procedure TObjectList.Clear;
begin
  if Count = 0 then
    exit;
  if DisposeObjects then begin
    while Count > 0 do
      Delete(0);
  end;
end;

procedure TStack.Init;
begin
  inherited Init;
  DisposeObjects := false;
end;

function TStack.Push(AObject: PObject): integer;
begin
  Push := Add(AObject);
end;

function TStack.Pop: PObject;
begin
  Pop := nil;
  if Count = 0 then
    exit;
  Pop := GetItem(Count - 1);
  Delete(Count - 1);
end;

procedure TStringList.Init;
begin
  inherited Init;
  DisposeStrings := true;
end;

function TStringList.GetItem(AIndex: integer): PChar;
begin
  GetItem := TList.GetItem(AIndex);
end;

function TStringList.IndexOf(AItem: PChar): integer;
begin
  IndexOf := TList.IndexOf(AItem);
end;

function TStringList.Add(AItem: PChar): integer;
begin
  Add := inherited Add(AItem);
end;

function TStringList.AddShortString(const AString: string): integer;
var
  largeString: PChar;
begin
  largeString := NewLargeString(AString);
  AddShortString := inherited Add(largeString);
end;

procedure TStringList.Insert(AIndex: integer; AItem: PChar);
begin
  TList.Insert(AIndex, AItem);
end;

procedure TStringList.Delete(AIndex: integer);
var
  st: PChar;
begin
  if (Count = 0) then exit;
  st := GetItem(AIndex);
  if (DisposeStrings) then
    DisposeLargeString(st);
  inherited Delete(AIndex);
end;

procedure TStringList.SortStrings;
begin
  Sort(StringCompare);
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

function TIdentifiableList.GetItem(AIndex: integer): PIdentifiable;
begin
  GetItem := PIdentifiable(inherited GetItem(AIndex));
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

function TIdentifiableList.IndexOfId(const AId: string): integer;
var
  index: integer;
begin
  IndexOfId := -1;
  if Count = 0 then
    exit;
  for index := 0 to Count - 1 do begin
    if LowerCase(AId) = LowerCase(StrPas(GetItem(index)^.Id)) then begin
      IndexOfId := index;
      break;
    end;
  end;
end;

procedure TIdentifiableList.Insert(AIndex: integer; AItem: PIdentifiable);
begin
  inherited Insert(AIndex, AItem);
end;

end.