{$I COMPILER.INC}
unit AplTypes;

interface

uses
  Objects,
  MouseDrv;

type
  TModalResult =
  (
    mrNone,
    mrYes,
    mrNo,
    mrOk,
    mrCancel,
    mrHelp
  );

type
  PEvent = ^TEvent;
  PKeyEvent = ^TKeyEvent;
  PMouseEvent = ^TMouseEvent;
  PEventProc = ^TEventProc;
  PMouseEventProc = ^TMouseEventProc;
  PKeyEventProc = ^TKeyEventProc;

  TEvent = object(TObject)
  private
  public
    Handled: boolean;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TKeyEvent = object(TEvent)
  private
  public
    Key: word;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TMouseEvent = object(TEvent)
  private
  public
    X: integer;
    Y: integer;
    NewMouseState: TMouseState;
    OldMouseState: TMouseState;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear; virtual;
  end;

  TEventProc = procedure(ASender: PObject; var AEvent: TEvent);
  TMouseEventProc = procedure(ASender: PObject; var AEvent: TMouseEvent);
  TKeyEventProc = procedure(ASender: PObject; var AEvent: TKeyEvent);

implementation

procedure TEvent.Init;
begin
  inherited Init;
  Handled := false;
end;

procedure TEvent.Assign(var ASource: TObject);
var
  source: PEvent;
begin
  inherited Assign(ASource);
  source := PEvent(@ASource);
  Handled := source^.Handled;
end;

procedure TEvent.Clear;
begin
  Handled := false;
end;

procedure TMouseEvent.Init;
begin
  inherited Init;
  NewMouseState.Create;
  OldMouseState.Create;
  Clear;
end;

procedure TMouseEvent.Assign(var ASource: TObject);
var
  source: PMouseEvent;
begin
  inherited Assign(ASource);
  source := PMouseEvent(@ASource);
  NewMouseState.Assign(source^.NewMouseState);
  OldMouseState.Assign(source^.OldMouseState);
  X := source^.X;
  Y := source^.Y;
end;

procedure TMouseEvent.Clear;
begin
  inherited Clear;
  OldMouseState.Clear;
  NewMouseState.Clear;
  X := 0;
  Y := 0;
end;

procedure TKeyEvent.Init;
begin
  inherited Init;
  Key := 0;
end;

procedure TKeyEvent.Assign(var ASource: TObject);
var
  source: PKeyEvent;
begin
  inherited Assign(ASource);
  source := PKeyEvent(@ASource);
  Key := source^.Key;
end;

procedure TKeyEvent.Clear;
begin
  inherited Clear;
  Key := 0;
end;

end.