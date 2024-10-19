{$I COMPILER.INC}
unit UndoStk;

interface

uses
  AplObj,
  Lists;

type
  PUndoStack = ^TUndoStack;
  PUndoItem = ^TUndoItem;
  PUndoAction = ^TUndoAction;
  PUndoActionList = ^TUndoActionList;
  PUndoEventProc = ^TUndoEventProc;

  TUndoEventProc = procedure(ASender: PObject; AItem: PUndoItem);

  TUndoAction = object(TObject)
  private
  public
    ActionType: word;
    OnUndo: PUndoEventProc;
    OnRedo: PUndoEventProc;
    constructor Create(AActionType: word; ACode: word);
    constructor CreateEvents(AActionType: word; ACode: word; AOnUndo, AOnRedo: PUndoEventProc);
    procedure Init; virtual;
  end;

  TUndoItem = object(TObject)
  private
  public
    Code: word;
    ActionType: word;
    Data: pointer;
    constructor Create(AActionType: word; ACode: word);
    constructor CreateData(AActionType: word; ACode: word; AData: pointer);
    procedure Init; virtual;
  end;

  TUndoActionList = object(TList)
  private
  public
    procedure Init; virtual;
    function Add(AItem: PUndoAction): integer;
    function GetItem(AIndex: integer): PUndoAction;
    function GetItemByType(AActionType: word): PUndoAction;
    function IndexOf(AAction: PUndoAction): integer;
    function IndexOfType(AActionType: word): integer;
    function HasType(AActionType: word): boolean;
    procedure SetItem(AIndex: integer; AAction: PUndoAction);
    procedure Insert(AIndex: integer; AAction: PUndoAction);
  end;

  TUndoStack = object(TObjectStack)
  private
  public
    RedoIndex: integer;
    Actions: PUndoActionList;
    destructor Free; virtual;
    procedure Init; virtual;
    function Add(AItem: PUndoItem): integer;
    function GetItem(AIndex: integer): PUndoItem;
    function IndexOf(AItem: PUndoItem): integer;
    procedure SetItem(AIndex: integer; AItem: PUndoItem);
    procedure Insert(AIndex: integer; AItem: PUndoItem);
    function Push(AItem: PUndoItem): integer;
    function Pop: PUndoItem;
    function Peek: PUndoItem;
  end;

implementation

procedure TUndoStack.Init;
begin
  inherited Init;
  RedoIndex := -1;
  Actions := New(PUndoActionList, Create);
end;

destructor TUndoStack.Free;
begin
  FreeAndNil(Actions);
  inherited Free;
end;

function TUndoStack.Add(AItem: PUndoItem): integer;
begin
  Add := inherited Add(AItem);
end;

function TUndoStack.GetItem(AIndex: integer): PUndoItem;
begin
  GetItem := PUndoItem(inherited GetItem(AIndex));
end;

function TUndoStack.IndexOf(AItem: PUndoItem): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TUndoStack.SetItem(AIndex: integer; AItem: PUndoItem);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TUndoStack.Insert(AIndex: integer; AItem: PUndoItem);
begin
  inherited Insert(AIndex, AItem);
end;

function TUndoStack.Push(AItem: PUndoItem): integer;
begin
  Push := inherited Push(AItem);
end;

function TUndoStack.Pop: PUndoItem;
begin
  Pop := PUndoItem(inherited Pop);
end;

function TUndoStack.Peek: PUndoItem;
begin
  Peek := PUndoItem(inherited Peek);
end;

procedure TUndoItem.Init;
begin
  inherited Init;
end;

constructor TUndoItem.Create(AActionType: word; ACode: word);
begin
  inherited Create;
  ActionType := AActionType;
  Code := ACode;
end;

constructor TUndoItem.CreateData(AActionType: word; ACode: word; AData: pointer);
begin
  Create(AActionType, ACode);
  Data := AData;
end;

procedure TUndoActionList.Init;
begin
  inherited Init;
end;

function TUndoActionList.Add(AItem: PUndoAction): integer;
var
  index: integer;
  item: PUndoAction;
begin
  if HasType(AItem^.ActionType) then begin
    index := IndexOfType(AItem^.ActionType);
    item := GetItem(index);
    FreeAndNil(item);
    SetItem(index, AItem);
  end;
  Add := inherited Add(AItem);
end;

function TUndoActionList.GetItem(AIndex: integer): PUndoAction;
begin
  GetItem := PUndoAction(inherited GetItem(AIndex));
end;

function TUndoActionList.IndexOf(AAction: PUndoAction): integer;
begin
  IndexOf := inherited IndexOf(AAction);
end;

procedure TUndoActionList.SetItem(AIndex: integer; AAction: PUndoAction);
begin
  inherited SetItem(AIndex, AAction);
end;

procedure TUndoActionList.Insert(AIndex: integer; AAction: PUndoAction);
begin
  inherited Insert(AIndex, AAction);
end;

function TUndoActionList.HasType(AActionType: word): boolean;
begin
  HasType := IndexOfType(AActionType) >= 0;
end;

function TUndoActionList.IndexOfType(AActionType: word): integer;
var
  index: integer;
begin
  for index := 0 to Count - 1 do
    if GetItem(index)^.ActionType = AActionType then begin
      IndexOfType := index;
      exit;
    end;
  IndexOfType := -1;
end;

function TUndoActionList.GetItemByType(AActionType: word): PUndoAction;
var
  index: integer;
begin
  GetItemByType := nil;
  index := IndexOfType(AActionType);
  if index >= 0 then
    GetItemByType := GetItem(index);
end;

constructor TUndoAction.Create(AActionType: word; ACode: word);
begin
  inherited Create;
  ActionType := AActionType;
end;

constructor TUndoAction.CreateEvents(AActionType: word; ACode: word; AOnUndo, AOnRedo: PUndoEventProc);
begin
  Create(AActionType, ACode);
  OnUndo := AOnUndo;
  OnRedo := AOnRedo;
end;

procedure TUndoAction.Init;
begin
  inherited Init;
  OnUndo := nil;
  OnRedo := nil;
  ActionType := 0;
end;

begin
end.