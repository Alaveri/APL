{$I COMPILER.INC}
unit AplTypes;

interface

uses
  AplObj,
  AplConst;

type
  PProc = ^TProc;
  PPointer = ^pointer;
  PBoolean = ^boolean;
  PByte = ^byte;
  PShort = ^shortint;
  PInt = ^integer;
  PUInt = ^word;
  PWord = ^word;
  PLong = ^longint;
  PByteArray = ^TByteArray;
  PBufferArray = ^TBufferArray;
  PEvent = ^TEvent;
  PKeyEvent = ^TKeyEvent;
  PMouseEvent = ^TMouseEvent;
  PEventProc = ^TEventProc;
  PMouseEventProc = ^TMouseEventProc;
  PKeyEventProc = ^TKeyEventProc;
  PMouseState = ^TMouseState;

  short = shortint;
  long = longint;
  uint = word;
  int = integer;

  TProc = procedure;
  THexString = string[9];
  TByteArray = array[byte] of byte;
  TBufferArray = array[0..MaxVarSize] of byte;
  TCharSet = set of char;

  TButtonState =
  (
    bsLeft,
    bsRight
  );

  TButtonStates = set of TButtonState;

  TMouseState = object(TObject)
  private
  public
    X: integer;
    Y: integer;
    RawX: integer;
    RawY: integer;
    ButtonState: TButtonStates;
    Visible: boolean;
    WheelCounter: shortint;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure Clear;
    function Equals(const AState: TMouseState): boolean;
    function Moved(const AState: TMouseState): boolean;
  end;

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

  TModalResult =
  (
    mrNone,
    mrYes,
    mrNo,
    mrOk,
    mrCancel,
    mrHelp
  );

  TEventProc = procedure(ASender: PObject; var AEvent: TEvent);
  TMouseEventProc = procedure(ASender: PObject; var AEvent: TMouseEvent);
  TKeyEventProc = procedure(ASender: PObject; var AEvent: TKeyEvent);

var
  NumberSeparator: char;
  WhiteSpaceChars: TCharSet;

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

procedure TMouseState.Init;
begin
  inherited Init;
  Clear;
end;

procedure TMouseState.Assign(var ASource: TObject);
var
  source: PMouseState;
begin
  inherited Assign(ASource);
  source := PMouseState(@ASource);
  X := source^.X;
  Y := source^.Y;
  RawX := source^.RawX;
  RawY := source^.RawY;
  ButtonState := source^.ButtonState;
  WheelCounter := source^.WheelCounter;
  Visible := source^.Visible;
end;

procedure TMouseState.Clear;
begin
  X := 0;
  Y := 0;
  RawX := 0;
  RawY := 0;
  ButtonState := [];
  WheelCounter := 0;
  Visible := false;
end;

function TMouseState.Equals(const AState: TMouseState): boolean;
begin
  Equals :=
    (AState.X = X)
    and (AState.Y = Y)
    and (AState.WheelCounter = WheelCounter)
    and (AState.ButtonState = ButtonState);
end;

function TMouseState.Moved(const AState: TMouseState): boolean;
begin
  Moved := (X <> AState.X) or (Y <> AState.Y);
end;

end.