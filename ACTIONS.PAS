{$I COMPILER.INC}
unit Actions;

interface

uses
  AplObj,
  AplTypes,
  AplStr,
  MouseDrv,
  AplMath,
  AplUtils,
  Lists;

type
  PAction = ^TAction;
  PActionList = ^TActionList;
  PActionExecuteEventProc = ^TActionExecuteEventProc;
  PActionEvent = ^TActionEvent;

  TAction = object(TObject)
  private
  public
    ActionId: word;
    Text: PChar;
    HelpText: PChar;
    ShortcutDisplayName: PChar;
    Shortcut: word;
    ParentList: PActionList;
    Enabled: boolean;
    OnExecute: PActionExecuteEventProc;
    ModalResult: TModalResult;
    OnUpdate: PEventProc;
    constructor Create(AActionId: word; AText: string; AShortcut: word);
    constructor CreateEmpty;
    procedure SetHelpText(AHelpText: string); virtual;
    procedure Execute(ASender: PObject); virtual;
    procedure SetText(AText: string); virtual;
    destructor Free; virtual;
    procedure Init; virtual;
  end;

  TActionList = object(TObjectList)
  public
    function NewAction(AActionId: integer; AText: string; AShortcut: word): PAction;
    function GetItem(AIndex: integer): PAction;
    function GetActionById(AActionId: integer): PAction;
    function Add(AItem: pointer): integer; virtual;
    procedure Execute(ASender: PObject; AActionId: integer);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TActionEvent = object(TEvent)
  private
  public
    Action: PAction;
    function ActionId: integer;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TActionExecuteEventProc = procedure(var AEvent: TActionEvent);

implementation

uses
  Strings,
  Dos;

constructor TAction.Create(AActionId: word; AText: string; AShortcut: word);
begin
  inherited Create;
  Text := TString.New(AText);
  Shortcut := AShortcut;
  ActionId := AActionId;
end;

constructor TAction.CreateEmpty;
begin
  inherited Create;
end;

procedure TAction.Init;
begin
  inherited Init;
  Text := nil;
  HelpText := nil;
  ShortcutDisplayName := nil;
  Shortcut := 0;
  ParentList := nil;
  ActionId := 0;
  Enabled := true;
  OnExecute := nil;
  ModalResult := mrNone;
end;

procedure TAction.Execute(ASender: PObject);
var
  event: TActionEvent;
begin
  if not Assigned(OnExecute) then
    exit;
  event.Create;
  event.Action := @self;
  event.Sender := ASender;
  TEventProc(OnExecute)(event);
end;

destructor TAction.Free;
begin
  TString.Free(Text);
  TString.Free(ShortcutDisplayName);
  TString.Free(HelpText);
  inherited Free;
end;

procedure TAction.SetHelpText(AHelpText: string);
begin
  TString.AssignString(HelpText, AHelpText);
end;

procedure TAction.SetText(AText: string);
begin
  TString.AssignString(Text, AText);
end;

function TActionList.NewAction(AActionId: integer; AText: string;
  AShortcut: word): PAction;
var
  action: PAction;
begin
  action := New(PAction, Create(AActionId, AText, AShortcut));
  action^.ParentList := @Self;
  action^.ActionId := AActionId;
  Add(action);
  NewAction := action;
end;

function TActionList.GetItem(AIndex: integer): PAction;
begin
  GetItem := PAction(inherited GetItem(AIndex));
end;

function TActionList.Add(AItem: pointer): integer;
begin
  Add := inherited Add(AItem);
  PAction(AItem)^.ParentList := @self;
end;

function TActionList.GetActionById(AActionId: integer): PAction;
var
  index: integer;
  action: PAction;
begin
  GetActionByid := nil;
  for index := 0 to Count - 1 do begin
    action := GetItem(index);
    if action^.ActionId = AActionId then begin
      GetActionById := action;
      exit;
    end;
  end;
end;

procedure TActionList.Execute(ASender: PObject; AActionId: integer);
var
  action: PAction;
begin
  action := GetActionById(AActionId);
  if Assigned(action) then
    action^.Execute(ASender);
end;

procedure TActionList.Init;
begin
  inherited Init;
end;

destructor TActionList.Free;
begin
  inherited Free;
end;

procedure TActionEvent.Clear;
begin
  inherited Clear;
  Action := nil;
end;

procedure TActionEvent.Assign(var ASource: TObject);
var
  source: PActionEvent;
begin
  inherited Assign(ASource);
  source := PActionEvent(@ASource);
  Action := source^.Action;
end;

function TActionEvent.ActionId: integer;
begin
  ActionId := -1;
  if Assigned(Action) then
    ActionId := Action^.ActionId;
end;

end.