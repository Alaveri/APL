{$I COMPILER.INC}
unit Actions;

interface

uses
  AplObj,
  MouseDrv,
  StrUtils,
  AplTypes,
  VTypes,
  Common,
  Lists;

type
  PAction = ^TAction;
  PActionUpdateProc = ^TActionUpdateProc;
  PActionList = ^TActionList;
  PActionExecuteProc = ^TActionExecuteProc;

  TActionUpdateProc = procedure(ASender: PObject; AAction: PAction; AActionId: integer);
  TActionExecuteProc = procedure(ASender: PObject; AAction: PAction);

  TAction = object(TObject)
  private
  public
    ActionId: integer;
    Text: PChar;
    HelpText: PChar;
    ShortcutDisplayName: PChar;
    Shortcut: word;
    ParentList: PActionList;
    Enabled: boolean;
    OnExecute: PActionExecuteProc;
    ModalResult: TModalResult;
    Owner: PObject;
    OnUpdate: PActionUpdateProc;
    constructor Create(AActionId: integer; AText: string; AShortcut: word);
    constructor CreateEmpty;
    procedure SetHelpText(AHelpText: string); virtual;
    procedure SetText(AText: string); virtual;
    destructor Free; virtual;
    procedure Init; virtual;
  end;

  TActionList = object(TObjectList)
  public
    function NewAction(AActionId: integer; AText: string; AShortcut: word): PAction;
    function GetItem(AIndex: integer): PAction;
    function GetActionById(AActionId: integer): PAction;
    function GetHelpMaxWidth(AControl: pointer): integer;
    function Add(AItem: pointer): integer; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  Controls;

constructor TAction.Create(AActionId: integer; AText: string; AShortcut: word);
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
  ActionId := -1;
  Enabled := true;
  OnExecute := nil;
  ModalResult := mrNone;
  Owner := nil;
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
  TString.Assign(HelpText, AHelpText);
end;

procedure TAction.SetText(AText: string);
begin
  TString.Assign(Text, AText);
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

function TActionList.GetHelpMaxWidth(AControl: pointer): integer;
var
  index: integer;
  maxWidth: word;
  action: PAction;
  txt: string;
  control: PControl;
begin
  maxWidth := 0;
  for index := 0 to Count - 1 do begin
    action := GetItem(index);
    if not Assigned(action^.HelpText) then
      continue;
    txt := StrPas(action^.HelpText);
    control := PControl(AControl);
    maxWidth := MaxWord(control^.TrueTextWidth(txt), maxWidth);
  end;
  GetHelpMaxWidth := maxWidth;
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

procedure TActionList.Init;
begin
  inherited Init;
end;

destructor TActionList.Free;
begin
  inherited Free;
end;

end.