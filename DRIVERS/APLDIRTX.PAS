{$I COMPILER.INC}
unit AplDirTx;

interface

uses
  AplObj,
  AplTypes,
  AplMath,
  AplLists,
  AplUtils,
  AplStrms,
  AplDraw,
  AplStr,
  AplTxtTp,
  AplText,
  Dos,
  Strings;

type
  PDirectTextDriver = ^TDirectTextDriver;

  TDirectTextDriver = object(TTextDriver)
  private
  public
    procedure RenderText(AXPos, AYPos: byte; const AText: string); virtual;
    procedure WriteText(AXPos, AYPos: byte; AText: PChar; ALength: word); virtual;
    procedure SetForeColor(AColor: byte); virtual;
    procedure SetBackColor(AColor: byte); virtual;
    procedure SetBlink(ABlink: boolean); virtual;
    procedure Init; virtual;
    procedure SetMode(AMode: PTextMode); virtual;
    procedure FillRect(ARect: TRect; AChar: char); virtual;
    procedure SetXY(AXPos, AYPos: byte); virtual;
    procedure ScrollText; virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure ClrScr; virtual;
    procedure SetAttribute(AXPos, AYPos: byte; AAttribute: byte); virtual;
    procedure ClearLine; virtual;
    procedure DrawImageRect(var ARect: TRect; AImage: PByte); virtual;
    procedure DrawImageStreamRect(var ARect: TRect; AStream: PStream); virtual;
    procedure GetImageRect(var ARect: TRect; AImage: PByte); virtual;
    procedure GetImageStreamRect(var ARect: TRect; AStream: PStream); virtual;
    destructor Free; virtual;
  end;

implementation

uses
 Crt;

const
  ColorScreen: PByte = Ptr($B800, $0000);
  MonoScreen: PByte = Ptr($B000, $0000);

var
  CurrentScreen: PByte;

procedure TDirectTextDriver.SetMode(AMode: PTextMode);
var
  modeIndex: TTextModes;
  newModeId: byte;
begin
  inherited SetMode(AMode);
  Mode := AMode;
  if AMode^.ColorType <> ctColor then
    CurrentScreen := MonoScreen
  else
    CurrentScreen := ColorScreen;
  newModeId := AMode^.DosMode;
  asm
    xor ah, ah
    mov al, [newModeId]
    int 10h
  end;
  ClrScr;
  CursorOn;
end;

procedure TDirectTextDriver.SetXY(AXPos, AYPos: byte);
begin
  inherited SetXY(AXPos, AYPos);
  asm
    mov ah, 2h
    mov bh, 0h
    mov dl, [AXPos]
    mov dh, [AYPos]
    int 10h
  end;
end;

procedure TDirectTextDriver.ScrollText;
var
  screenPtr: PByte;
begin
  PushState;
  CursorOff;
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * Mode^.Width);
  Move(screenPtr^, CurrentScreen^, 2 * Mode^.Width * (Mode^.Height - 1));
  PopState;
  SetXY(0, Mode^.Bounds.Bottom);
  ClearLine;
end;

procedure TDirectTextDriver.RenderText(AXPos, AYPos: byte; const AText: string);
var
  index: integer;
  screenPtr: PChar;
  drawRect: TRect;
  attr: char;
  ch: char;
  x, right: byte;
  len: byte;
begin
  State^.ViewPort.GetIntersection(Mode^.Bounds, drawRect);
  if not CheckBounds(AXPos, AYPos, Length(AText), drawRect) then
    exit;
  attr := Chr(State^.Attributes);
  screenPtr := PChar(CurrentScreen);
  Inc(screenPtr, 2 * (AYPos * Mode^.Width + AXPos));
  right := drawRect.Right;
  x := drawRect.X;
  index := 1;
  if AXPos < x then begin
    Inc(index, x - AXPos);
    Inc(screenPtr, 2 * (x - AXPos));
    AXPos := x;
  end;
  len := Length(AText);
  if AXPos + Length(AText) > right then
    len := right - AXPos + 1;
  while index <= len do begin
    ch := AText[index];
    Inc(index);
    screenPtr^ := ch;
    Inc(screenPtr);
    screenPtr^ := attr;
    Inc(screenPtr);
    Inc(AXPos);
    if AXPos > right then
      break;
  end;
  SetXY(AXPos, AYPos);
end;

procedure TDirectTextDriver.SetAttribute(AXPos, AYPos: byte; AAttribute: byte);
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (AYPos * Mode^.Width + AXPos) + 1);
  screenPtr^ := AAttribute;
end;

procedure TDirectTextDriver.WriteText(AXPos, AYPos: byte; AText: PChar; ALength: word);
var
  index: word;
  screenPtr: PChar;
  drawRect: TRect;
  ch, attr: char;
  x1, x2: byte;
begin
  XPos := Clamp(AXPos, Mode^.Bounds.X, Mode^.Bounds.Right);
  YPos := Clamp(AYPos, Mode^.Bounds.Y, Mode^.Bounds.Bottom);
  screenPtr := PChar(CurrentScreen);
  Inc(screenPtr, 2 * (YPos * Mode^.Width + XPos));
  attr := Chr(State^.Attributes);
  index := 0;
  while index < ALength do begin
    ch := AText[index];
    Inc(index);
    screenPtr^ := ch;
    Inc(screenPtr);
    screenPtr^ := attr;
    Inc(screenPtr);
    Inc(XPos);
    if XPos > Mode^.Bounds.Right then begin
      XPos := Mode^.Bounds.X;
      Inc(YPos);
      if YPos > Mode^.Bounds.Bottom then begin
        ScrollText;
        YPos := Mode^.Bounds.Bottom;
      end;
      screenPtr := PChar(CurrentScreen);
      Inc(screenPtr, 2 * (YPos * Mode^.Width + XPos));
    end;
  end;
  SetAttribute(XPos, YPos, GetTextAttributes(State^.ForeColor, State^.BackColor, State^.Blink));
end;

procedure TDirectTextDriver.ClearLine;
var
  screenPtr: PByte;
  index: integer;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (YPos * Mode^.Width + Mode^.Bounds.X));
  for index := Mode^.Bounds.X to Mode^.Bounds.Right do begin
    screenPtr^ := 32;
    Inc(screenPtr, 2);
  end;
end;

procedure TDirectTextDriver.SetBlink(ABlink: boolean);
begin
  inherited SetBlink(ABlink);
  State^.Attributes := GetTextAttributes(State^.ForeColor, State^.BackColor, ABlink);
end;

procedure TDirectTextDriver.SetForeColor(AColor: byte);
begin
  inherited SetForeColor(AColor);
  State^.Attributes := GetTextAttributes(AColor, State^.BackColor, State^.Blink);
end;

procedure TDirectTextDriver.SetBackColor(AColor: byte);
begin
  inherited SetBackColor(AColor);
  State^.Attributes := GetTextAttributes(State^.ForeColor, AColor, State^.Blink);
end;

procedure TDirectTextDriver.CursorOn;
begin
  inherited CursorOn;
  asm
    mov ax, Seg0040
    mov es, ax
    mov di, 0060h
    mov cx, es:[di]
    mov ax, 0100h
    and ch, 0DFh
    int 10h
  end;
end;

procedure TDirectTextDriver.CursorOff;
begin
  inherited CursorOff;
  asm
    mov ax, Seg0040
    mov es, ax
    mov di, 0060h
    mov cx, es:[di]
    mov ax, 0100h
    or  ch, 20h
    int 10h
  end;
end;

procedure TDirectTextDriver.Init;
var
  newMode: PTextMode;
  modeIndex: TTextModes;
begin
  inherited Init;
  for modeIndex := Low(modeIndex) to High(modeIndex) do begin
    newMode := New(PTextMode, Create);
    newMode^ := TextModes[ModeIndex];
    Modes.Add(newMode);
  end;
end;


procedure TDirectTextDriver.ClrScr;
begin
  inherited ClrScr;
  FillChar(CurrentScreen^, 2 * Mode^.Width * Mode^.Height, 0);
end;

procedure TDirectTextDriver.FillRect(ARect: TRect; AChar: char);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  line, linePtr: PByte;
  rect: TRect;
  drawRect: TRect;
begin
  State^.ViewPort.GetIntersection(Mode^.Bounds, drawRect);
  drawRect.Intersect(ARect);
  GetMem(line, drawRect.Width * 2);
  offset := CurrentScreen;
  ch.Attributes := State^.Attributes;
  ch.Character := AChar;
  linePtr := line;
  for index := 0 to drawRect.Width - 1 do begin
    Move(ch, linePtr^, 2);
    Inc(linePtr, 2);
  end;
  Inc(offset, 2 * (drawRect.Y * Mode^.Width + ARect.X));
  for index := drawRect.Y to drawRect.Bottom do begin
    Move(line^, offset^, drawRect.Width * 2);
    Inc(offset, Mode^.Width * 2);
  end;
  SetXY(0, 0);
  FreeMem(line, drawRect.Width * 2);
end;

procedure TDirectTextDriver.DrawImageRect(var ARect: TRect; AImage: PByte);
var
  drawRect: TRect;
  index: integer;
  screenPtr: PByte;
begin
  State^.ViewPort.GetIntersection(Mode^.Bounds, drawRect);
  drawRect.Intersect(ARect);
  if drawRect.IsEmpty then
    exit;
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (drawRect.Y * Mode^.Width + drawRect.X));
  for index := drawRect.Y to drawRect.Bottom do begin
    Move(AImage^, screenPtr^, drawRect.Width * 2);
    Inc(screenPtr, Mode^.Width * 2);
    Inc(AImage, ARect.Width * 2);
  end;
end;

procedure TDirectTextDriver.DrawImageStreamRect(var ARect: TRect; AStream: PStream);
var
  drawRect: TRect;
  index: integer;
  screenPtr: PByte;
begin
  State^.ViewPort.GetIntersection(Mode^.Bounds, drawRect);
  drawRect.Intersect(ARect);
  if drawRect.IsEmpty then
    exit;
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (drawRect.Y * Mode^.Width + drawRect.X));
  for index := drawRect.Y to drawRect.Bottom do begin
    AStream^.Read(screenPtr, drawRect.Width * 2);
    if CheckReraise(AStream) then
      exit;
    Inc(screenPtr, Mode^.Width * 2);
  end;
end;

procedure TDirectTextDriver.GetImageRect(var ARect: TRect; AImage: PByte);
var
  drawRect: TRect;
  index: integer;
  screenPtr: PByte;
begin
  State^.ViewPort.GetIntersection(Mode^.Bounds, drawRect);
  drawRect.Intersect(ARect);
  if drawRect.IsEmpty then
    exit;
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (drawRect.Y * Mode^.Width + drawRect.X));
  for index := drawRect.Y to drawRect.Bottom do begin
    Move(screenPtr^, AImage^, drawRect.Width * 2);
    Inc(screenPtr, Mode^.Width * 2);
    Inc(AImage, ARect.Width * 2);
  end;
end;

procedure TDirectTextDriver.GetImageStreamRect(var ARect: TRect; AStream: PStream);
var
  drawRect: TRect;
  index: integer;
  screenPtr: PByte;
begin
  State^.ViewPort.GetIntersection(Mode^.Bounds, drawRect);
  drawRect.Intersect(ARect);
  if drawRect.IsEmpty then
    exit;
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (drawRect.Y * Mode^.Width + drawRect.X));
  for index := drawRect.Y to drawRect.Bottom do begin
    AStream^.Write(screenPtr, drawRect.Width * 2);
    if CheckReraise(AStream) then
      exit;
    Inc(screenPtr, Mode^.Width * 2);
  end;
end;

destructor TDirectTextDriver.Free;
begin
  inherited Free;
end;

begin
end.