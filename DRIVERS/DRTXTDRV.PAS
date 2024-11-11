{$I COMPILER.INC}
unit DrTxtDrv;

interface

uses
  AplObj,
  AplTypes,
  AplMath,
  Lists,
  AplUtils,
  Streams,
  Drawing,
  AplStr,
  TextType,
  TextDrv,
  Dos,
  Strings;

type
  PDirectTextDriver = ^TDirectTextDriver;

  TDirectTextDriver = object(TTextDriver)
  private
  public
    procedure RenderText(AXPos, AYPos: byte; const AText: string); virtual;
    procedure WriteText(AXPos, AYPos: byte; AText: PChar; ALength: word); virtual;
    procedure Init; virtual;
    procedure SetMode(AMode: PTextMode); virtual;
    procedure FillRect(ARect: TRect; AChar: char); virtual;
    procedure SetXY(AXPos, AYPos: byte); virtual;
    procedure ScrollText; virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure ClrScr; virtual;
    procedure ClearLine; virtual;
    procedure DrawImageRect(var ARect: TRect; AImage: PByte); virtual;
    procedure DrawImageStreamRect(var ARect: TRect; AStream: PStream); virtual;
    procedure GetImageRect(var ARect: TRect; AImage: PByte); virtual;
    procedure GetImageStreamRect(var ARect: TRect; AStream: PStream); virtual;
    procedure SetScreenForeColor(APX, APY: byte; AColor: byte); virtual;
    procedure SetScreenBackColor(APX, APY: byte; AColor: byte); virtual;
    procedure SetBlink(ABlink: boolean); virtual;
    procedure SetScreenBlink(AXPos, AYPos: byte; ABlink: boolean); virtual;
    procedure SetScreenAttributes(APX, APY: byte; AAttributes: byte); virtual;
    procedure GetTextChar(APX, APY: byte; var AChar: TTextChar); virtual;
    procedure SetTextChar(APX, APY: byte; AChar: TTextChar); virtual;
    procedure SetChar(APX, APY: byte; AChar: char); virtual;
    function GetScreenBackColor(APX, APY: byte): byte; virtual;
    function GetScreenForeColor(APX, APY: byte): byte; virtual;
    function GetAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte; virtual;
    function GetScreenAttributes(AXPos, AYPos: byte): byte; virtual;
    function GetChar(APX, APY: byte): char; virtual;
    function GetScreenBlink(APX, APY: byte): boolean; virtual;
    destructor Free; virtual;
  end;

implementation

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
  SetScreenAttributes(XPos, YPos, GetAttributes(State^.ForeColor, State^.BackColor, State^.Blink));
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

function TDirectTextDriver.GetAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte;
begin
  GetAttributes := AForeColor or (ABackColor shl 4) or (byte(ABlink) shl 7);
end;

procedure TDirectTextDriver.SetScreenForeColor(APX, APY: byte; AColor: byte);
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (APY * Mode^.Width + APX) + 1);
  screenPtr^ := ScreenPtr^ and $F0 or AColor;
end;

procedure TDirectTextDriver.SetScreenBackColor(APX, APY: byte; AColor: byte);
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (APY * Mode^.Width + APX) + 1);
  screenPtr^ := ((AColor and $0F) shl 4 ) or (screenPtr^ and $8F);
end;

procedure TDirectTextDriver.SetScreenBlink(AXPos, AYPos: byte; ABlink: boolean);
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (AYPos * Mode^.Width + AXPos) + 1);
  screenPtr^ := (screenPtr^ and $7F) or (byte(ABlink) shl 7);
end;

procedure TDirectTextDriver.SetScreenAttributes(APX, APY: byte; AAttributes: byte);
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (APY * Mode^.Width + APX) + 1);
  screenPtr^ := AAttributes;
end;

function TDirectTextDriver.GetScreenAttributes(AXPos, AYPos: byte): byte;
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (AYPos * Mode^.Width + AXPos) + 1);
  GetScreenAttributes := screenPtr^;
end;

function TDirectTextDriver.GetScreenForeColor(APX, APY: byte): byte;
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (APY * Mode^.Width + APX) + 1);
  GetScreenForeColor := screenPtr^ and $0F;
end;

function TDirectTextDriver.GetScreenBackColor(APX, APY: byte): byte;
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (APY * Mode^.Width + APX) + 1);
  GetScreenBackColor := (screenPtr^ shr 4) and $07;
end;

function TDirectTextDriver.GetScreenBlink(APX, APY: byte): boolean;
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (APY * Mode^.Width + APX) + 1);
  GetScreenBlink := (screenPtr^ and $80) <> 0;
end;

procedure TDirectTextDriver.SetChar(APX, APY: byte; AChar: char);
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (APY * Mode^.Width + APX));
  screenPtr^ := byte(AChar);
end;

procedure TDirectTextDriver.SetBlink(ABlink: boolean);
begin
  State^.Blink := ABlink;
end;

function TDirectTextDriver.GetChar(APX, APY: byte): char;
var
  screenPtr: PByte;
begin
  screenPtr := CurrentScreen;
  Inc(screenPtr, 2 * (APY * Mode^.Width + APX));
  GetChar := Chr(screenPtr^);
end;

procedure TDirectTextDriver.SetTextChar(APX, APY: byte; AChar: TTextChar);
var
  screenPtr: PTextChar;
begin
  screenPtr := PTextChar(CurrentScreen);
  Inc(screenPtr, APY * Mode^.Width + APX);
  screenPtr^ := AChar;
end;

procedure TDirectTextDriver.GetTextChar(APX, APY: byte; var AChar: TTextChar);
var
  screenPtr: PTextChar;
begin
  screenPtr := PTextChar(CurrentScreen);
  Inc(screenPtr, APY * Mode^.Width + APX);
  AChar := screenPtr^;
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