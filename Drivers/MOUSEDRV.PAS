{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit MouseDrv;

interface

uses
  Objects,
  Collects;

const
  SetCursorPositionCode = $04;

type
  PMouseDriver = ^TMouseDriver;
  PMouseState = ^TMouseState;

  TButtonState =
  (
    bsLeft,
    bsRight
  );

  TButtonStates = set of TButtonState;

  TMouseState = object(TObject)
  private
  public
    X, Y: integer;
    ButtonState: TButtonStates;
    Visible: boolean;
    procedure Init; virtual;
    function Moved(AState: TMouseState): boolean; virtual;
    function Equals(AState: TMouseState): boolean;
    procedure Assign(var ASource: TObject); virtual;
    destructor Free; virtual;
  end;

  TMouseDriver = object(TObject)
  private
  public
    State: PMouseState;
    StateStack: PStack;
    UseSystemCursor: boolean;
    XDiv, YDiv: integer;
    function GetTypeName: string; virtual;
    procedure Init; virtual;
    procedure ShowMouse; virtual;
    procedure HideMouse; virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure GetMouseState(var AState: TMouseState); virtual;
    procedure InitMouseCursor; virtual;
    procedure SetMouseResolution(AWidth, AHeight: word); virtual;
    procedure SetMousePosition(APx, APy: word); virtual;
    destructor Free; virtual;
  end;

var
  Mouse: TMouseDriver;

implementation

uses
  Dos,
  DosConst;

const
  MouseCursor: array[0..31] of word =
  (
    $7FFF,
    $3FFF,
    $1FFF,
    $0FFF,
    $07FF,
    $03FF,
    $3FFF,
    $7FFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,

    $0000,
    $0000,
    $4000,
    $6000,
    $7000,
    $4000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000

{
      0111111111111111
      0011111111111111
      0001111111111111
      0000111111111111
      0000011111111111
      0000001111111111
      0011111111111111
      0111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111

      0000000000000000
      0000000000000000
      0100000000000000
      0110000000000000
      0111000000000000
      0100000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
    }
  );

procedure TMouseState.Init;
begin
  inherited Init;
  X := 0;
  Y := 0;
  ButtonState := [];
  Visible := false;
end;

destructor TMouseState.Free;
begin
end;

procedure TMouseState.Assign(var ASource: TObject);
var
  state: PMouseState;
begin
  state := PMouseState(@ASource);
  X := state^.X;
  Y := state^.Y;
  ButtonState := state^.ButtonState;
  Visible := state^.Visible;
end;

function TMouseState.Equals(AState: TMouseState): boolean;
begin
  Equals := (AState.X = X) and (AState.Y = Y) and (AState.ButtonState = ButtonState);
end;

function TMouseState.Moved(AState: TMouseState): boolean;
begin
  Moved := (AState.X <> X) or (AState.Y <> Y);
end;

procedure TMouseDriver.InitMouseCursor;
var
  segm, offs: word;
begin
  segm := Seg(MouseCursor);
  offs := Ofs(MouseCursor);
  asm
    mov   AX, 09h
    mov   BX, 0
    mov   CX, 0
    mov   ES, [segm]
    mov   DX, [offs]
    int   33h
  end;
end;

destructor TMouseDriver.Free;
begin
  StateStack^.DisposeObjects := true;
  Dispose(StateStack, Free);
  Dispose(State, Free);
  inherited Free;
end;

procedure TMouseDriver.Init;
var
  success: boolean;
  result: word;
begin
  inherited Init;
  success := false;
  asm
    mov  AX, 0
    int  33h
    mov  [result], AX
  end;
  success := result = $FFFF;
  State := New(PMouseState, Create);
  if success then
    InitMouseCursor;
  StateStack := New(PStack, Create);
  UseSystemCursor := false;
  XDiv := 0;
  YDiv := 0;
end;

function TMouseDriver.GetTypeName: string;
begin
  GetTypeName := 'TMouseDriver';
end;

procedure TMouseDriver.ShowMouse;
begin;
  State^.Visible := true;
  if (not UseSystemCursor) then exit;
  asm
    mov   AX, 1
    int   33h
  end;
end;

procedure TMouseDriver.HideMouse;
begin;
  State^.Visible := false;
  if (not UseSystemCursor) then exit;
  asm
    mov   AX, 2
    int   33h
  end;
end;

procedure TMouseDriver.PushState;
var
  newState: PMouseState;
begin
  newState := New(PMouseState, Create);
  newState^.Assign(State^);
  StateStack^.Push(newState);
end;

procedure TMouseDriver.PopState;
var
  oldState: PMouseState;
begin
  oldState := PMouseState(StateStack^.Pop);
  if oldState = nil then
    exit;
  State^.Assign(oldState^);
  Dispose(oldState, Free);
  if state^.Visible then
    ShowMouse
  else
    HideMouse;
end;

procedure TMouseDriver.SetMouseResolution(AWidth, AHeight: word);
begin
  Dec(AWidth, 1);
  Dec(AHeight, 1);
  asm
    push si
    mov ax, 0
    int 33h
    mov ax, 10h
    mov cx, [AWidth]
    mov dx, [AHeight]
    mov si, 0
    mov di, 0
    int 33h
    mov ax, 07h
    mov cx, 0
    mov dx, [AWidth]
    int 33h
    mov ax, 08h
    mov cx, 0
    mov dx, [AHeight]
    int 33h
    pop si
  end;
end;

procedure TMouseDriver.SetMousePosition(APx, APy: word);
begin
  asm
    mov   ax, 04h
    mov   cx, [APx]
    mov   dx, [APy]
    int   33h
  end;
end;

procedure TMouseDriver.GetMouseState(var AState: TMouseState);
var
  reg: Registers;
  x, y, status: word;
begin
  FillChar(reg, SizeOf(reg), 0);
  AState.Create;
  asm
    mov   AX, 3
    int   33h
    mov   [x], CX
    mov   [y], DX
    mov   [status], BX
  end;
  AState.X := x shr XDiv;
  AState.Y := y shr YDiv;
  AState.Visible := State^.Visible;
  if (status and $01 > 0) then
    Include(AState.ButtonState, bsLeft);
  if (status and $02 > 0) then
    Include(AState.ButtonState, bsRight);
  State^.X := AState.X;
  State^.Y := AState.Y;
  State^.ButtonState := AState.ButtonState;
end;

end.