{$I COMPILER.INC}
unit TextDrv;

interface

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  Objects,
  Lists,
  AplConst,
  KeyDrv,
  Common,
  Errors,
  Drawing,
  MouseDrv,
  Lines;

type
  PTextDriver = ^TTextDriver;
  PTextState = ^TTextState;
  PTextMode = ^TTextMode;
  PTextModeList = ^TTextModeList;

  TTextChar = record
    Character: char;
    Attributes: byte;
  end;

  TTextState = object(TObject)
  {$IFDEF VER70}public{$ENDIF}
    ForeColor, BackColor: byte;
    Blink: boolean;
    X, Y: integer;
    Attributes: byte;
    IsCursorOn: boolean;
    ViewPort: TRect;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TTextMode = Object(TIdentifiable)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
    Width, Height, MaxX, MaxY: integer;
    Name: string50;
    AdditionalData: integer;
    Description: string;
    HelpText: string;
    procedure Init; virtual;
    procedure GetBounds(var ARect: TRect); virtual;
  end;

  TTextModeList = object(TIdentifiableList)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
    function GetItem(AIndex: integer): PTextMode;    function GetItemById(const AId: string): PTextMode;
    function IndexOfId(const AId: string): integer;
    function IndexOf(AItem: PTextMode): integer;
    function Add(AItem: PTextMode): integer;
    procedure Insert(AIndex: integer; AItem: PTextMode);
  end;

  TTextDriver = Object(TExceptionObject)
    FStateStack: PStack;
  {$IFDEF VER70}public{$ENDIF}
    Mode: PTextMode;
    Modes: PTextModeList;
    State: PTextState;
    BppMode: byte;
    Scroll: boolean;
    function TextWidth(const AText: string): integer; virtual;
    function TextWidthLarge(AText: PChar): integer; virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure RenderText(AXPos, AYPos: byte; AText: PChar; ALength: word); virtual;
    procedure Write(const AText: string); virtual;
    procedure WriteLarge(AText: PChar); virtual;
    procedure WriteLn(const AText: string); virtual;
    procedure WriteLnLarge(AText: PChar); virtual;
    procedure DrawText(AXPos, AYPos: byte; AText: string);
    procedure DrawTextLarge(AXPos, AYPos: byte; AText: PChar);
    procedure SetForeColor(AColor: byte); virtual;
    procedure SetBackColor(AColor: byte); virtual;
    procedure SetBlink(ABlink: boolean); virtual;
    procedure SetXY(AXPos, AYPos: byte); virtual;
    procedure ScrollText; virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure Init; virtual;
    procedure SetMode(AMode: PTextMode); virtual;
    procedure HorzLine(AX, AY, AWidth: integer; ALineStyle: TLineStyle); virtual;
    procedure VertLine(AX, AY, AHeight: integer; ALineStyle: TLineStyle); virtual;
    procedure HorzLineWithEnds(AX, AY, AWidth: integer; ALineStyle: TLineStyle); virtual;
    procedure VertLineWithEnds(AX, AY, AHeight: integer; ALineStyle: TLineStyle); virtual;
    procedure HorzFill(AX, AY, AWidth: integer); virtual;
    procedure VertFill(AX, AY, AHeight: integer); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure Rectangle(ARect: TRect; ABorderStyle: TBorderStyle); virtual;
    procedure ClrScr; virtual;
    procedure ShowMouseCursor; virtual;
    procedure HideMouseCursor; virtual;
    function ForeColor: byte; virtual;
    function BackColor: byte; virtual;
    destructor Free; virtual;
  end;

var
  TextDriver: PTextDriver;

implementation

var
  PreviousExitProc: PFunc;

procedure TTextState.Init;
begin
  ForeColor := 0;
  BackColor := 0;
  X := 0;
  Y := 0;
  Blink := false;
  Attributes := 0;
  IsCursorOn := true;
  ViewPort.Create;
end;

procedure TTextState.Assign(var ASource: TObject);
var
  state: PTextState;
begin
  inherited Assign(ASource);
  state := PTextState(@ASource);
  ForeColor := state^.ForeColor;
  BackColor := state^.BackColor;
  Blink := state^.Blink;
  X := state^.X;
  Y := state^.Y;
  Attributes := state^.Attributes;
  IsCursorOn := state^.IsCursorOn;
  ViewPort.SetRect(state^.ViewPort);
end;

procedure TTextMode.Init;
begin
  inherited Init;
  Width := 0;
  Height := 0;
  MaxX := 0;
  MaxY := 0;
  Name := '';
  AdditionalData := 0;
  Description := '';
  HelpText := '';
end;

procedure TTextMode.GetBounds(var ARect: TRect);
begin
  ARect.CreateDims(0, 0, Width, Height);
end;

function TTextModeList.GetItem(AIndex: integer): PTextMode;
begin
  GetItem := PTextMode(inherited GetItem(AIndex));
end;

function TTextModeList.GetItemById(const AId: string): PTextMode;
begin
  GetItemById := PTextMode(inherited GetItemById(AId));
end;

function TTextModeList.IndexOfId(const AId: string): integer;
begin
  IndexOfId := inherited IndexOfId(AId);
end;

function TTextModeList.IndexOf(AItem: PTextMode): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TTextModeList.Add(AItem: PTextMode): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TTextModeList.Insert(AIndex: integer; AItem: PTextMode);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TTextDriver.PushState;
var
  newState: PTextState;
begin
  newState := New(PTextState, Create);
  newState^.Assign(State^);
  FStateStack^.Push(newState);
end;

procedure TTextDriver.PopState;
var
  oldState: PTextState;
begin
  oldState := PTextState(FStateStack^.Pop);
  if not Assigned(oldState) then
    exit;
  State^.Assign(oldState^);
  FreeAndNil(oldState);
  if State^.IsCursorOn then
    CursorOn
  else
    CursorOff;
  SetXY(State^.X, State^.Y);
end;

procedure TTextDriver.SetXY(AXPos, AYPos: byte);
begin
  State^.X := AXPos;
  State^.Y := AYPos;
end;

procedure TTextDriver.SetMode(AMode: PTextMode);
begin
  State^.ViewPort.SetDims(0, 0, AMode^.Width, AMode^.Height);
end;

procedure TTextDriver.DrawText(AXPos, AYPos: byte; AText: string);
begin
  RenderText(AXPos, AYPos, @AText[1], Length(AText));
end;

procedure TTextDriver.DrawTextLarge(AXPos, AYPos: byte; AText: PChar);
begin
  RenderText(AXPos, AYPos, AText, StrLen(AText));
end;

procedure TTextDriver.RenderText(AXPos, AYPos: byte; AText: PChar; ALength: word);
begin
end;

procedure TTextDriver.Write(const AText: string);
begin
end;

procedure TTextDriver.WriteLarge(AText: PChar);
begin
end;

procedure TTextDriver.WriteLn(const AText: string);
begin
end;

procedure TTextDriver.WriteLnLarge(AText: PChar);
begin
end;

procedure TTextDriver.SetForeColor(AColor: byte);
begin
  State^.ForeColor := AColor;
end;

procedure TTextDriver.SetBlink(ABlink: boolean);
begin
  State^.Blink := ABlink;
end;

procedure TTextDriver.SetBackColor(AColor: byte);
begin
  State^.BackColor := AColor;
end;

procedure TTextDriver.CursorOn;
begin
  State^.IsCursorOn := true;
end;

procedure TTextDriver.CursorOff;
begin
  State^.IsCursorOn := false;
end;

function TTextDriver.TextWidth(const AText: string): integer;
begin
  TextWidth := Length(AText);
end;

function TTextDriver.TextWidthLarge(AText: PChar): integer;
begin
  TextWidthLarge := StrLen(AText);
end;

procedure TTextDriver.Init;
begin
  inherited Init;
  Modes := New(PTextModeList, Create);
  State := New(PTextState, Create);
  FStateStack := New(PStack, Create);
  Mode := nil;
  BppMode := 4;
  State^.ViewPort.Create;
  Scroll := true;
end;

procedure TTextDriver.Rectangle(ARect: TRect; ABorderStyle: TBorderStyle);
begin
  DrawText(ARect.X, ARect.Y, BorderChars[ABorderStyle, bcTopLeft]);
  DrawText(ARect.Right, ARect.Y, BorderChars[ABorderStyle, bcTopRight]);
  DrawText(ARect.X, ARect.Bottom, BorderChars[ABorderStyle, bcBottomLeft]);
  DrawText(ARect.Right, ARect.Bottom, BorderChars[ABorderStyle, bcBottomRight]);
  HorzLine(ARect.X + 1, ARect.Y, ARect.Width - 2, BorderToLine[ABorderStyle]);
  HorzLine(ARect.X + 1, ARect.Bottom, ARect.Width - 2, BorderToLine[ABorderStyle]);
  VertLine(ARect.X, ARect.Y + 1, ARect.Height - 2, BorderToLine[ABorderStyle]);
  VertLine(ARect.Right, ARect.Y + 1, ARect.Height - 2, BorderToLine[ABorderStyle]);
end;

destructor TTextDriver.Free;
begin
  FreeAndNil(Modes);
  FreeAndNil(State);
  FreeAndNil(FStateStack);
  Keyboard.CursorOn;
  inherited Free;
end;

procedure TTextDriver.HorzFill(AX, AY, AWidth: integer);
begin
end;

procedure TTextDriver.VertFill(AX, AY, AHeight: integer);
begin
end;

procedure TTextDriver.HorzLineWithEnds(AX, AY, AWidth: integer; ALineStyle: TLineStyle);
begin
  DrawText(AX, AY, LineChars[loHorizontal, ALineStyle, lcStart]);
  DrawText(AX + AWidth - 1, AY, LineChars[loHorizontal, ALineStyle, lcEnd]);
  HorzLine(AX + 1, AY, AWidth - 2, ALineStyle);
end;

procedure TTextDriver.VertLineWithEnds(AX, AY, AHeight: integer; ALineStyle: TLineStyle);
begin
end;

procedure TTextDriver.HorzLine(AX, AY, AWidth: integer; ALineStyle: TLineStyle);
var
  rect: TRect;
  line: array[0..79] of TTextChar;
  index: integer;
begin
  rect.CreateDims(AX, AY, AWidth, 1);
  rect.Intersect(State^.ViewPort);
  if rect.IsEmpty then
    exit;
  for index := rect.X to rect.X + rect.Width - 1 do
    DrawText(index, AY, LineChars[loHorizontal, ALineStyle, lcMiddle]);
end;

procedure TTextDriver.VertLine(AX, AY, AHeight: integer; ALineStyle: TLineStyle);
var
  rect: TRect;
  line: array[0..79] of TTextChar;
  index: integer;
begin
  rect.CreateDims(AX, AY, 1, AHeight);
  rect.Intersect(State^.ViewPort);
  if rect.IsEmpty then
    exit;
  for index := rect.Y to rect.Y + rect.Height - 1 do begin
    DrawText(rect.X, index, LineChars[loHorizontal, ALineStyle, lcMiddle]);
    DrawText(rect.Right, index, LineChars[loVertical, ALineStyle, lcMiddle]);
  end;
end;

procedure TTextDriver.ClrScr;
begin
end;

procedure TTextDriver.FillRect(ARect: TRect);
begin
end;

function TTextDriver.ForeColor: byte;
begin
  ForeColor := State^.ForeColor;
end;

function TTextDriver.BackColor: byte;
begin
  BackColor := State^.BackColor;
end;

procedure TTextDriver.ShowMouseCursor;
begin
  Mouse.ShowMouse;
end;

procedure TTextDriver.HideMouseCursor;
begin
  Mouse.HideMouse;
end;

procedure TTextDriver.ScrollText;
begin
end;

procedure TextDriverExitProc; far;
begin
  ExitProc := PreviousExitProc;
  if Assigned(TextDriver) then
    FreeAndNil(TextDriver);
  WriteLn('Text driver uninstalled.');
end;

begin
  TextDriver := nil;
  PreviousExitProc := ExitProc;
  ExitProc := @TextDriverExitProc;
end.
