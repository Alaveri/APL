{$I COMPILER.INC}
unit MouseDrv;

interface

uses
  AplObj,
  AplTypes,
  Lists;

type
  PMouseDriver = ^TMouseDriver;

  TMouseDriver = object(TObject)
  private
    FMouseWheelSupported: boolean;
    function CheckMouseWheelSupported: boolean;
  public
    State: TMouseState;
    StateStack: TObjectStack;
    UseSystemCursor: boolean;
    XShift, YShift: byte;
    destructor Free; virtual;
    procedure Init; virtual;
    procedure ShowMouse;
    procedure HideMouse;
    procedure PushState;
    procedure PopState;
    procedure UpdateState;
    procedure SetMouseResolution(AMaxX, AMaxY: word);
    procedure SetMousePosition(APx, APy: word);
    procedure SetIncToPixelRatio(AIncPerPixX, AIncPerPixY: word);
    procedure SetSensitivity(ASensX, ASensY: real);
    function IsMouseWheelSupported: boolean;
  end;

var
  Mouse: TMouseDriver;

implementation

uses
  AplDos;

var
  PreviousExitProc: PProc;

destructor TMouseDriver.Free;
var
  index: integer;
begin
  StateStack.DisposeObjects := true;
  StateStack.Free;
  State.Free;
  inherited Free;
end;

procedure TMouseDriver.Init;
var
  success: boolean;
  result: word;
begin
  inherited Init;
  StateStack.Create;
  State.Create;
  success := false;
  asm
    mov  AX, 0
    int  33h
    mov  result, AX
  end;
  success := result = $FFFF;
  if success then
    CheckMouseWheelSupported;
  UseSystemCursor := false;
  XShift := 0;
  YShift := 0;
end;

procedure TMouseDriver.ShowMouse;
begin;
  State.Visible := true;
  if not UseSystemCursor then
    exit;
  asm
    mov   AX, 1
    int   33h
  end;
end;

procedure TMouseDriver.HideMouse;
begin;
  State.Visible := false;
  if not UseSystemCursor then
    exit;
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
  newState^.Assign(State);
  StateStack.Push(newState);
end;

procedure TMouseDriver.PopState;
var
  oldState: PMouseState;
begin
  oldState := PMouseState(StateStack.Pop);
  if not Assigned(oldState) then
    exit;
  State.Assign(oldState^);
  FreeAndNil(oldState);
end;

procedure TMouseDriver.SetSensitivity(ASensX, ASensY: real);
var
  x, y: integer;
begin
  x := Round(32 / ASensX);
  y := Round(32 / ASensY);
  asm
    mov AX, 000Fh
    mov CX, x
    mov DX, y
    int 33h
    mov AX, 0013h
    mov DX, 65535
    int 33h
  end;
end;

procedure TMouseDriver.SetIncToPixelRatio(AIncPerPixX, AIncPerPixY: word);
begin
  asm
    mov AX, 000Fh
    mov CX, AIncPerPixX
    mov DX, AIncPerPixY
    int 33h
  end;
end;

function TMouseDriver.IsMouseWheelSupported: boolean;
begin
  IsMouseWheelSupported := FMouseWheelSupported;
end;

function TMouseDriver.CheckMouseWheelSupported: boolean;
var
  result: word;
  caps: word;
begin
  FMouseWheelSupported := false;
  asm
    mov  AX, 0011h
    int  33h
    mov  [result], AX
    mov  [caps], CX
  end;
  FMouseWheelSupported := (result = $574D) and (caps and $01 > 0);
end;

procedure TMouseDriver.SetMouseResolution(AMaxX, AMaxY: word);
begin
  asm
    mov ax, 07h
    mov cx, 0
    mov dx, AMaxX
    int 33h
    mov ax, 08h
    mov cx, 0
    mov dx, AMaxY
    int 33h
  end;
end;

procedure TMouseDriver.SetMousePosition(APx, APy: word);
begin
  asm
    mov   ax, 04h
    mov   cx, APx
    mov   dx, APy
    int   33h
  end;
end;

procedure TMouseDriver.UpdateState;
var
  x, y, status: word;
begin
  asm
    mov   AX, 3
    int   33h
    mov   x, CX
    mov   y, DX
    mov   status, BX
  end;
  State.X := x shr XShift;
  State.Y := y shr YShift;
  State.ButtonState := [];
  if FMouseWheelSupported and (Hi(status) <> 0) then
    State.WheelCounter := shortInt(hi(status))
  else
    State.WheelCounter := 0;
  if (status and $01 > 0) then
    Include(State.ButtonState, bsLeft);
  if (status and $02 > 0) then
    Include(State.ButtonState, bsRight);
end;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  Mouse.Free;
  WriteLn('Mouse driver uninstalled.');
end;

begin
  Mouse.Create;
  WriteLn('Mouse driver installed.');
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
