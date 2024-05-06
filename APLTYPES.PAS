{$I COMPILER.INC}
unit AplTypes;

interface

uses
  AplObj;

type

  PWord = ^word;
  PPointer = ^pointer;
  PBoolean = ^boolean;
  PProc = ^TProc;
  PByte = ^byte;
  PByteArray = ^TByteArray;
  PInteger = ^integer;
  PLongint = ^longint;

  Int64 = comp;

  TProc = procedure;
  TBit = (bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7);
  TBits = set of TBit;
  TBit16 = (
    wbit0,
    wbit1,
    wbit2,
    wbit3,
    wbit4,
    wbit5,
    wbit6,
    wbit7,
    wbit8,
    wbit9,
    wbit10,
    wbit11,
    wbit12,
    wbit13,
    wbit14,
    wbit15
  );
  TBits16 = set of TBit16;
  THexString = string[9];
  TByteArray = array[byte] of byte;
  TCharSet = set of char;

  TLongLowHigh = record
    Low: word;
    High: word;
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

type
  PEvent = ^TEvent;
  PKeyEvent = ^TKeyEvent;
  PMouseEvent = ^TMouseEvent;
  PEventProc = ^TEventProc;
  PMouseEventProc = ^TMouseEventProc;
  PKeyEventProc = ^TKeyEventProc;
  PMouseState = ^TMouseState;

  TButtonState =
  (
    bsLeft,
    bsRight
  );

  TButtonStates = set of TButtonState;

  TMouseState = object(TObject)
  public
    X: integer;
    Y: integer;
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
  ButtonState := source^.ButtonState;
  WheelCounter := source^.WheelCounter;
  Visible := source^.Visible;
end;

procedure TMouseState.Clear;
begin
  X := 0;
  Y := 0;
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