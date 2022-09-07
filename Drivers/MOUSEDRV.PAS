{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I-,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit MouseDrv;

interface

uses
  Objects,
  Collects;

const
  InitMouseCode = $00;
  ShowMouseCode = $01;
  HideMouseCode = $02;
  GetMouseStatusCode = $03;
  SetCursorPositionCode = $04;

type
  TButtonState =
  (
    bsLeft,
    bsRight
  );
  TButtonStates = set of TButtonState;
  PMouseState = ^TMouseState;
  TMouseState = object(TAssignable)
  private
  public
    X, Y: integer;
    ButtonState: TButtonStates;
    Visible: boolean;
    procedure Init; virtual;
    function Moved(state: TMouseState): boolean; virtual;
    function Equals(state: TMouseState): boolean;
    procedure Assign(var source: TAssignable); virtual;
    function GetTypeName: ShortString; virtual;
    destructor Done; virtual;
  end;
  PMouseDriver = ^TMouseDriver;
  TMouseDriver = object(TBaseObject)
  private
  public
    State: PMouseState;
    StateStack: PStack;
    function GetTypeName: ShortString; virtual;
    procedure Init; virtual;
    procedure ShowMouse; virtual;
    procedure HideMouse; virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure GetMouseState(var currentState: TMouseState); virtual;
    procedure InitMouseCursor; virtual;
    procedure SetMouseResolution(width, height: word); virtual;
    procedure SetMousePosition(x, y: word); virtual;
    destructor Destroy; virtual;
  end;

var
  MouseDriver: PMouseDriver;

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

destructor TMouseState.Done;
begin
end;

procedure TMouseState.Assign(var source: TAssignable);
var
  state: PMouseState;
begin
  state := PMouseState(@source);
  X := state^.X;
  Y := state^.Y;
  ButtonState := state^.ButtonState;
  Visible := state^.Visible;
end;

function TMouseState.GetTypeName: ShortString;
begin
  GetTypeName := 'TMouseState';
end;

function TMouseState.Equals(state: TMouseState): boolean;
begin
  Equals := (state.X = X) and (state.Y = Y) and (state.ButtonState = ButtonState);
end;

function TMouseState.Moved(state: TMouseState): boolean;
begin
  Moved := (state.X <> X) or (state.Y <> Y);
end;

procedure TMouseDriver.InitMouseCursor;
{$ifdef fpc}
begin
end;
{$else}
var
  reg: Registers;
begin
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := $09;
  reg.BX := 0;
  reg.CX := 0;
  reg.ES := Seg(MouseCursor);
  reg.DX := Ofs(MouseCursor);
  Intr($33, reg);
end;
{$endif}

destructor TMouseDriver.Destroy;
begin
  Dispose(StateStack, Destroy);
  Dispose(State, Destroy);
  TBaseObject.Destroy;
end;

procedure TMouseDriver.Init;
{$ifdef fpc}
begin
end;
{$else}
var
  reg: Registers;
  success: boolean;
begin
  success := false;
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := InitMouseCode;
  Intr(MouseInterrupt, reg);
  success := Reg.AX = $FFFF;
  State := New(PMouseState, Create);
  if success then InitMouseCursor;
  StateStack := New(PStack, Create);
end;
{$endif}

function TMouseDriver.GetTypeName: ShortString;
begin
  GetTypeName := 'TMouseDriver';
end;

procedure TMouseDriver.ShowMouse;
{$ifdef fpc}
begin
end;
{$else}
var
  reg: Registers;
begin;
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := ShowMouseCode;
  Intr(MouseInterrupt, reg);
  State^.Visible := true;
end;
{$endif}

procedure TMouseDriver.HideMouse;
{$ifdef fpc}
begin
end;
{$else}
var
  reg: Registers;
begin;
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := HideMouseCode;
  Intr(MouseInterrupt, reg);
  State^.Visible := false;
end;
{$endif}

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
  if (oldState = nil) then exit;
  State^.Assign(oldState^);
  Dispose(oldState, Done);
  if (State^.Visible) then ShowMouse
  else HideMouse;
end;

procedure TMouseDriver.SetMouseResolution(width, height: word);
{$ifdef fpc}
begin
end;
{$else}
begin
  Dec(width, 1);
  Dec(height, 1);
  asm
    mov  ax, 7h
    mov  cx, 0
    mov  dx, [width]
    int  33h
    mov  ax, 8h
    mov  cx, 0
    mov  dx, [height]
    int  33h
  end;
end;
{$endif}

procedure TMouseDriver.SetMousePosition(x, y: word);
{$ifdef fpc}
begin
end;
{$else}
begin
  asm
    mov ax, 4h
    mov cx, [x]
    mov dx, [y]
    int 33h
  end;
end;
{$endif}

procedure TMouseDriver.GetMouseState(var currentState: TMouseState);
{$ifdef fpc}
begin
end;

{$else}
var
  reg: Registers;
begin
  FillChar(reg, SizeOf(reg), 0);
  currentState.Create;
  reg.AX := GetMouseStatusCode;
  Intr(MouseInterrupt, reg);
  currentState.X := reg.CX;
  currentState.Y := reg.DX;
  currentState.Visible := State^.Visible;
  if (reg.BX and $01 > 0) then
    Include(currentState.ButtonState, bsLeft);
  if (reg.BX and $02 > 0) then
    Include(currentState.ButtonState, bsRight);
  State^.X := currentState.X;
  State^.Y := currentState.Y;
  State^.ButtonState := currentState.ButtonState;
end;
{$endif}

end.
