{$I COMPILER.INC}
unit TextDrv;

interface

uses
  AplObj,
  AplTypes,
  Streams,
  Lists,
  AplConst,
  KeyDrv,
  AplUtils,
  AplMath,
  Drawing,
  TextType,
  MouseDrv,
  Strings,
  Dos;

type
  PTextModeList = ^TTextModeList;
  PTextModeListProc = ^TTextModeListProc;
  PTextDriver = ^TTextDriver;

  TTextModeList = object(TObjectList)
  private
  public
    function GetItem(AIndex: integer): PTextMode;
    function GetModeById(AModeId: TTextModes): PTextMode;
    function IndexOf(AItem: PTextMode): integer;
    function Add(AItem: PTextMode): integer;
    procedure Insert(AIndex: integer; AItem: PTextMode);
  end;

  TTextDriver = Object(TStatusObject)
  private
  public
    Mode: PTextMode;
    Modes: TTextModeList;
    State: PTextState;
    StateStack: TObjectStack;
    BppMode: byte;
    StartMode: integer;
    destructor Free; virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure RenderText(AXPos, AYPos: byte; const AText: string); virtual;
    procedure WriteText(AXPos, AYPos: byte; AText: PChar; ALength: word); virtual;
    procedure Write(const AText: string);
    procedure WriteLarge(AText: PChar);
    procedure WriteLn(const AText: string);
    procedure WriteLnLarge(AText: PChar);
    procedure DrawText(AXPos, AYPos: integer; const AText: string);
    procedure DrawTextLarge(AXPos, AYPos: integer; AText: PChar);
    procedure DrawImage(AXPos, AYPos, AWidth, AHeight: byte; AImage: PByte);
    procedure DrawImageStream(AXPos, AYPos, AWidth, AHeight: byte; AStream: PStream);
    procedure GetImage(AXPos, AYPos, AWidth, AHeight: byte; AImage: PByte);
    procedure GetImageStream(AXPos, AYPos, AWidth, AHeight: byte; AStream: PStream);
    procedure DrawImageRect(var ARect: TRect; AImage: PByte); virtual;
    procedure DrawImageStreamRect(var ARect: TRect; AStream: PStream); virtual;
    procedure GetImageRect(var ARect: TRect; AImage: PByte); virtual;
    procedure GetImageStreamRect(var ARect: TRect; AStream: PStream); virtual;
    procedure SetForeColor(AColor: byte); virtual;
    procedure SetBackColor(AColor: byte); virtual;
    procedure SetXY(AXPos, AYPos: byte); virtual;
    procedure ScrollText; virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure Init; virtual;
    procedure SetMode(AMode: PTextMode); virtual;
    procedure HorzLine(AX, AY, AWidth: integer; ALineStyle: TLineStyle); virtual;
    procedure VertLine(AX, AY, AHeight: integer; ALineStyle: TLineStyle); virtual;
    procedure VertLineChar(AX, AY, AHeight: integer; AChar: char);
    procedure HorzLineChar(AX, AY, AWidth: integer; AChar: char); virtual;
    procedure HorzLineWithEnds(AX, AY, AWidth: integer; ALineStyle: TLineStyle); virtual;
    procedure VertLineWithEnds(AX, AY, AHeight: integer; ALineStyle: TLineStyle); virtual;
    procedure FillRect(ARect: TRect; AChar: char); virtual;
    procedure FillDims(AXPos1, AYPos1: byte; AXPos2, AYPos2: byte; AChar: char); virtual;
    procedure Rectangle(ARect: TRect; ABorderStyle: TBorderStyle); virtual;
    procedure ClrScr; virtual;
    procedure ShowMouseCursor; virtual;
    procedure HideMouseCursor; virtual;
    procedure ClearLine; virtual;
    procedure SetScreenForeColor(APX, APY: byte; AColor: byte); virtual;
    procedure SetScreenBackColor(APX, APY: byte; AColor: byte); virtual;
    procedure SetBlink(ABlink: boolean); virtual;
    procedure SetScreenAttributes(APX, APY: byte; AAttributes: byte); virtual;
    procedure GetTextChar(APX, APY: byte; var AChar: TTextChar); virtual;
    procedure SetTextChar(APX, APY: byte; AChar: TTextChar); virtual;
    procedure SetChar(APX, APY: byte; AChar: char); virtual;
    procedure SetScreenBlink(AXPos, AYPos: byte; ABlink: boolean);
    function GetScreenBackColor(APX, APY: byte): byte; virtual;
    function GetScreenForeColor(APX, APY: byte): byte; virtual;
    function ForeColor: byte; virtual;
    function BackColor: byte; virtual;
    function CheckBounds(AXPos, AYPos, ALength: byte; var ADrawRect: TRect): boolean;
    function GetAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte; virtual;
    function GetScreenAttributes(AXPos, AYPos: byte): byte; virtual;
    function GetChar(APX, APY: byte): char; virtual;
    function GetScreenBlink(APX, APY: byte): boolean; virtual;
  end;

var
  Text: PTextDriver;

implementation

uses
  AplStr;

var
  PreviousExitProc: PProc;

function TTextModeList.GetItem(AIndex: integer): PTextMode;
begin
  GetItem := PTextMode(inherited GetItem(AIndex));
end;

function TTextModeList.GetModeById(AModeId: TTextModes): PTextMode;
var
  index: integer;
  item: PTextMode;
begin
  GetModeById := nil;
  for index := 0 to Count - 1 do begin
    item := GetItem(index);
    if item^.ModeId = AModeId then begin
      GetModeById := item;
      break;
    end;
  end;
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
  StateStack.Push(newState);
end;

procedure TTextDriver.PopState;
var
  oldState: PTextState;
begin
  oldState := PTextState(StateStack.Pop);
  if not Assigned(oldState) then
    exit;
  State^.Assign(oldState^);
  FreeAndNil(oldState);
  SetXY(State^.CursorX, State^.CursorY);
  if State^.IsCursorOn then
    CursorOn
  else
    CursorOff;
end;

procedure TTextDriver.SetXY(AXPos, AYPos: byte);
begin
  if (State^.CursorX = AXPos) and (State^.CursorY = AYPos) then
    exit;
  State^.CursorX := AXPos;
  State^.CursorY := AYPos;
end;

function TTextDriver.CheckBounds(AXPos, AYPos, ALength: byte; var ADrawRect: TRect): boolean;
begin
  CheckBounds :=
    (AXPos + ALength >= ADrawRect.X)
    and (AXPos <= ADrawRect.Right)
    and (AYPos <= ADrawRect.Bottom)
    and (AYPos >= ADrawRect.Y);
end;

procedure TTextDriver.SetMode(AMode: PTextMode);
begin
  Mode := AMode;
  AMode^.Bounds.SetDims(0, 0, AMode^.Width, AMode^.Height);
  State^.ViewPort.SetDims(0, 0, AMode^.Width, AMode^.Height);
end;

procedure TTextDriver.DrawText(AXPos, AYPos: integer; const AText: string);
begin
  RenderText(AXPos, AYPos, AText);
end;

procedure TTextDriver.DrawTextLarge(AXPos, AYPos: integer; AText: PChar);
begin
  RenderText(AXPos, AYPos, TString.GetString(AText));
end;

procedure TTextDriver.RenderText(AXPos, AYPos: byte; const AText: string);
begin
end;

procedure TTextDriver.ClearLine;
begin
end;

procedure TTextDriver.Write(const AText: string);
begin
  WriteText(State^.CursorX, State^.CursorY, @AText[1], Length(AText));
end;

procedure TTextDriver.WriteLarge(AText: PChar);
begin
  WriteText(State^.CursorX, State^.CursorY, AText, StrLen(AText));
end;

procedure TTextDriver.WriteLn(const AText: string);
begin
  WriteText(State^.CursorX, State^.CursorY, @AText[1], Length(AText));
  State^.CursorX := 0;
  Inc(State^.CursorY);
  if State^.CursorY > Mode^.Bounds.Bottom then
    ScrollText;
  SetXY(State^.CursorX, State^.CursorY);
  SetScreenAttributes(State^.CursorX, State^.CursorY,
    GetAttributes(State^.ForeColor, State^.BackColor, State^.Blink));
end;

procedure TTextDriver.WriteText(AXPos, AYPos: byte; AText: PChar; ALength: word);
begin
end;

procedure TTextDriver.WriteLnLarge(AText: PChar);
begin
  WriteText(State^.CursorX, State^.CursorY, AText, StrLen(AText));
  State^.CursorX := 0;
  Inc(State^.CursorY);
  if State^.CursorY > Mode^.Bounds.Bottom then
    ScrollText;
  SetScreenAttributes(State^.CursorX, State^.CursorY,
    GetAttributes(State^.ForeColor, State^.BackColor, State^.Blink));
end;

procedure TTextDriver.DrawImage(AXPos, AYPos, AWidth, AHeight: byte; AImage: PByte);
var
  drawRect: TRect;
begin
  drawRect.SetDims(AXPos, AYPos, AWidth, AHeight);
  DrawImageRect(drawRect, AImage);
end;

procedure TTextDriver.DrawImageStream(AXPos, AYPos, AWidth, AHeight: byte; AStream: PStream);
var
  drawRect: TRect;
begin
  drawRect.SetDims(AXPos, AYPos, AWidth, AHeight);
  DrawImageStreamRect(drawRect, AStream);
end;

procedure TTextDriver.GetImage(AXPos, AYPos, AWidth, AHeight: byte; AImage: PByte);
var
  drawRect: TRect;
begin
  drawRect.SetDims(AXPos, AYPos, AWidth, AHeight);
  GetImageRect(drawRect, AImage);
end;

procedure TTextDriver.GetImageStream(AXPos, AYPos, AWidth, AHeight: byte; AStream: PStream);
var
  drawRect: TRect;
begin
  drawRect.SetDims(AXPos, AYPos, AWidth, AHeight);
  GetImageStreamRect(drawRect, AStream);
end;

procedure TTextDriver.DrawImageRect(var ARect: TRect; AImage: PByte);
begin
end;

procedure TTextDriver.DrawImageStreamRect(var ARect: TRect; AStream: PStream);
begin
end;

procedure TTextDriver.GetImageRect(var ARect: TRect; AImage: PByte);
begin
end;

procedure TTextDriver.GetImageStreamRect(var ARect: TRect; AStream: PStream);
begin
end;

procedure TTextDriver.SetTextChar(APX, APY: byte; AChar: TTextChar);
begin
end;

procedure TTextDriver.GetTextChar(APX, APY: byte; var AChar: TTextChar);
begin
end;

function TTextDriver.GetChar(APX, APY: byte): char;
begin
end;

procedure TTextDriver.SetChar(APX, APY: byte; AChar: char);
begin
end;

function TTextDriver.GetScreenBackColor(APX, APY: byte): byte;
begin
  GetScreenBackColor := 0;
end;

function TTextDriver.GetScreenForeColor(APX, APY: byte): byte;
begin
end;

procedure TTextDriver.SetScreenForeColor(APX, APY: byte; AColor: byte);
begin
end;

procedure TTextDriver.SetScreenBackColor(APX, APY: byte; AColor: byte);
begin
end;

procedure TTextDriver.SetBlink(ABlink: boolean);
begin
end;

procedure TTextDriver.SetScreenBlink(AXPos, AYPos: byte; ABlink: boolean);
begin
end;

procedure TTextDriver.SetForeColor(AColor: byte);
begin
  State^.ForeColor := AColor;
end;

procedure TTextDriver.SetBackColor(AColor: byte);
begin
  State^.BackColor := AColor;
end;

function TTextDriver.GetScreenAttributes(AXPos, AYPos: byte): byte;
begin
  GetScreenAttributes := 0;
end;

function TTextDriver.GetAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte;
begin
  GetAttributes := (AForeColor and $0F) or ((ABackColor and $0F) shl 4) or (byte(ABlink) shl 7);
end;

procedure TTextDriver.SetScreenAttributes(APX, APY: byte; AAttributes: byte);
begin
end;

function TTextDriver.GetScreenBlink(APX, APY: byte): boolean;
begin
  GetScreenBlink := false;
end;

procedure TTextDriver.CursorOn;
begin
  State^.IsCursorOn := true;
end;

procedure TTextDriver.CursorOff;
begin
  State^.IsCursorOn := false;
end;

procedure TTextDriver.Init;
begin
  inherited Init;
  Modes.Create;
  State := New(PTextState, Create);
  StateStack.Create;
  Mode := nil;
  BppMode := 4;
end;

procedure TTextDriver.Rectangle(ARect: TRect; ABorderStyle: TBorderStyle);
begin
  DrawText(ARect.X, ARect.Y, BorderChars[ABorderStyle, bcTopLeft]);
  DrawText(ARect.Right, ARect.Y, BorderChars[ABorderStyle, bcTopRight]);
  DrawText(ARect.X, ARect.Bottom, BorderChars[ABorderStyle, bcBottomLeft]);
  DrawText(ARect.Right, ARect.Bottom, BorderChars[ABorderStyle, bcBottomRight]);
  HorzLineChar(ARect.X + 1, ARect.Y, ARect.Width - 2, BorderChars[ABorderStyle, bcTop]);
  HorzLineChar(ARect.X + 1, ARect.Bottom, ARect.Width - 2, BorderChars[ABorderStyle, bcBottom]);
  VertLineChar(ARect.X, ARect.Y + 1, ARect.Height - 2, BorderChars[ABorderStyle, bcLeft]);
  VertLineChar(ARect.Right, ARect.Y + 1, ARect.Height - 2, BorderChars[ABorderStyle, bcRight]);
end;

destructor TTextDriver.Free;
begin
  Modes.Free;
  FreeAndNil(State);
  StateStack.DisposeObjects := true;
  StateStack.Free;
  inherited Free;
end;

procedure TTextDriver.HorzLineWithEnds(AX, AY, AWidth: integer; ALineStyle: TLineStyle);
begin
  DrawText(AX, AY, LineChars[loHorizontal, ALineStyle, lcStart]);
  DrawText(AX + AWidth - 1, AY, LineChars[loHorizontal, ALineStyle, lcEnd]);
  HorzLine(AX + 1, AY, AWidth - 2, ALineStyle);
end;

procedure TTextDriver.VertLineWithEnds(AX, AY, AHeight: integer; ALineStyle: TLineStyle);
begin
  DrawText(AX, AY, LineChars[loVertical, ALineStyle, lcStart]);
  DrawText(AX, AY + AHeight - 1, LineChars[loVertical, ALineStyle, lcEnd]);
  VertLine(AX, AY + 1, AHeight - 2, ALineStyle);
end;

procedure TTextDriver.HorzLineChar(AX, AY, AWidth: integer; AChar: char);
var
  drawRect: TRect;
  index: integer;
begin
  drawRect.CreateDims(AX, AY, AWidth, 1);
  drawRect.Intersect(Mode^.Bounds);
  drawRect.Intersect(State^.ViewPort);
  if drawRect.IsEmpty then
    exit;
  for index := drawRect.X to drawRect.Right do
    DrawText(index, drawRect.Y, AChar);
end;

procedure TTextDriver.VertLineChar(AX, AY, AHeight: integer; AChar: char);
var
  drawRect: TRect;
  index: integer;
begin
  drawRect.CreateDims(AX, AY, 1, AHeight);
  drawRect.Intersect(Mode^.Bounds);
  drawRect.Intersect(State^.ViewPort);
  if drawRect.IsEmpty then
    exit;
  for index := drawRect.Y to drawRect.Bottom do
    DrawText(drawRect.Right, index, AChar);
end;

procedure TTextDriver.HorzLine(AX, AY, AWidth: integer; ALineStyle: TLineStyle);
var
  drawRect: TRect;
  index: integer;
begin
  drawRect.CreateDims(AX, AY, AWidth, 1);
  drawRect.Intersect(Mode^.Bounds);
  drawRect.Intersect(State^.ViewPort);
  if drawRect.IsEmpty then
    exit;
  for index := drawRect.X to drawRect.Right do
    DrawText(index, drawRect.Y, LineChars[loHorizontal, ALineStyle, lcMiddle]);
end;

procedure TTextDriver.VertLine(AX, AY, AHeight: integer; ALineStyle: TLineStyle);
var
  drawRect: TRect;
  index: integer;
begin
  drawRect.CreateDims(AX, AY, 1, AHeight);
  drawRect.Intersect(Mode^.Bounds);
  drawRect.Intersect(State^.ViewPort);
  if drawRect.IsEmpty then
    exit;
  for index := drawRect.Y to drawRect.Bottom do
    DrawText(drawRect.Right, index, LineChars[loVertical, ALineStyle, lcMiddle]);
end;

procedure TTextDriver.ClrScr;
begin
  State^.CursorX := 0;
  State^.CursorY := 0;
end;

procedure TTextDriver.FillRect(ARect: TRect; AChar: char);
begin
end;

procedure TTextDriver.FillDims(AXPos1, AYPos1: byte; AXPos2, AYPos2: byte; AChar: char);
var
  drawRect: TRect;
begin
  drawRect.SetCoords(AXPos1, AYPos1, AXPos2, AYPos2);
  FillRect(drawRect, AChar);
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

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  FreeAndNil(Text);
  WriteLn('Text driver uninstalled.');
end;

begin
  Text := nil;
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
