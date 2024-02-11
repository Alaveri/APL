{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit DirTxDrv;

interface

uses
  Objects,
  Lists,
  Common,
  Drawing,
  DosConst,
  Strings,
  StrUtils,
  TextDrv;

type
  PDirectTextDriver = ^TDirectTextDriver;

  TDirectTextDriver = object(TTextDriver)
  private
    FStartMode: byte;
    function GetTextAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte; virtual;
  public
    procedure RenderText(AText: PChar; ALength: word); virtual;
    procedure Write(const AText: string); virtual;
    procedure WriteLarge(AText: PChar); virtual;
    procedure WriteLn(const AText: string); virtual;
    procedure WriteLnLarge(AText: PChar); virtual;
    procedure SetForeColor(AColor: byte); virtual;
    procedure SetBackColor(AColor: byte); virtual;
    procedure SetBlink(ABlink: boolean); virtual;
    procedure Init; virtual;
    procedure SetMode(AMode: PTextMode); virtual;
    procedure HLine(AX, AY, AWidth: integer; ALineStyle: TLineStyle); virtual;
    procedure VLine(AX, AY, AHeight: integer; ALineStyle: TLineStyle); virtual;
    procedure Box(ARect: TRect; ALineStyle: TLineStyle); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure SetXY(AXPos, AYPos: byte); virtual;
    procedure ScrollText; virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure ClrScr; virtual;
    destructor Free; virtual;
  end;

implementation

const
  ColorScreen: PByte = Ptr($B800, $0000);
  MonoScreen: PByte = Ptr($B000, $000);

type
  TColor80x25Screen = array[0..24, 0..79] of byte;

var
  CurrentScreen: PByte;

procedure TDirectTextDriver.SetMode(AMode: PTextMode);
var
  startMode: byte;
  newModeId: byte;
  windMax, windMin: byte;
begin
  inherited SetMode(AMode);
  Mode := AMode;
  asm
    mov ah, 0Fh
    int 10h
    mov [startMode], al
  end;
  FStartMode := startMode;
  if StrPas(AMode^.Id) = 'Mono' then
    CurrentScreen := MonoScreen
  else
    CurrentScreen := ColorScreen;
  newModeId := Mode^.AdditionalData;
  asm
    mov ah, 0
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
    mov ah, 2
    mov bh, 0
    mov dl, [AXPos]
    mov dh, [AYPos]
    int 10h
  end;
end;

procedure TDirectTextDriver.WriteLn(const AText: string);
begin
  Write(AText);
  State^.X := 0;
  Inc(State^.Y);
  if State^.Y > State^.ViewPort.Bottom then begin
    if Scroll then
      ScrollText
    else
      State^.Y := State^.ViewPort.Bottom
  end;
  SetXY(State^.X, State^.Y);
end;

procedure TDirectTextDriver.ScrollText;
var
  lineIndex, index: integer;
  screenPtr, nextPtr: PByte;
  ch: TTextChar;
begin
  PushState;
  CursorOff;
  for lineIndex := State^.ViewPort.Y to State^.ViewPort.Height do begin
    screenPtr := CurrentScreen;
    Inc(screenPtr, 2 * (lineIndex * Mode^.Width + State^.ViewPort.X));
    nextPtr := screenPtr;
    Inc(nextPtr, 2 * Mode^.Width);
    Move(nextPtr^, screenPtr^, 2 * State^.ViewPort.Width);
  end;
  State^.X := 0;
  State^.Y := State^.ViewPort.Bottom;
  SetXY(State^.X, State^.Y);
  ch.Character := #32;
  ch.Attributes := State^.Attributes;
  for index := State^.ViewPort.X to State^.ViewPort.Width - 1 do begin
    screenPtr := currentScreen;
    inc(screenPtr, (State^.Y * Mode^.Width + index) * 2);
    Move(ch, screenPtr^, 2);
  end;
  PopState;
  State^.X := 0;
  State^.Y := State^.ViewPort.Bottom;
  SetXY(State^.X, State^.Y);
end;

procedure TDirectTextDriver.WriteLnLarge(AText: PChar);
begin
  WriteLarge(AText);
  State^.X := 0;
  Inc(State^.Y);
  if State^.Y > State^.ViewPort.Bottom then begin
    if Scroll then
      ScrollText
    else
      State^.Y := State^.ViewPort.Bottom
  end;
  SetXY(State^.X, State^.Y);
end;

procedure TDirectTextDriver.RenderText(AText: PChar; ALength: word);
var
  ch: TTextChar;
  index: integer;
  screenPtr: PByte;
begin
  if ALength = 0 then
    exit;
  if State^.Y > State^.ViewPort.Bottom then
    exit;
  ch.Attributes := State^.Attributes;
  for index := 1 to ALength do begin
    if State^.X < State^.ViewPort.X then begin
      Inc(State^.X);
      continue;
    end;
    if State^.Y < State^.ViewPort.Y then
      continue;
    screenPtr := CurrentScreen;
    Inc(screenPtr, 2 * (State^.Y * Mode^.Width + State^.X));
    ch.Character := AText^;
    Inc(AText);
    Move(ch, screenPtr^, 2);
    Inc(State^.X);
    if State^.X > State^.ViewPort.Right then begin
      State^.X := 0;
      if State^.Y + 1 > State^.ViewPort.Bottom then begin
        if Scroll then
          ScrollText;
      end
      else
        Inc(State^.Y);
    end;
  end;
  SetXY(state^.X, state^.Y);
end;

procedure TDirectTextDriver.Write(const AText: string);
begin
  RenderText(@AText[1], Length(AText));
end;

procedure TDirectTextDriver.WriteLarge(AText: PChar);
begin
  RenderText(AText, StrLen(AText));
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
    mov   ax,[Seg0040]
    mov   es,ax
    mov   di,0060h
    mov   cx,word ptr es:[di]
    mov   ax,0100h
    and   ch,0dfh
    int   10h
  end;
end;

procedure TDirectTextDriver.CursorOff;
begin
  inherited CursorOff;
  asm
    mov   ax,[Seg0040]
    mov   es,ax
    mov   di,0060h
    mov   cx,word ptr es:[di]
    mov   ax,0100h
    or    ch,20h
    int   10h
  end;
end;

function TDirectTextDriver.GetTextAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte;
var
  blinkByte : byte;
begin
  blinkByte := 0;
  if (ABlink) then blinkByte := 1;
  GetTextAttributes := AForeColor or (ABackColor shl 4) or (byte(ABlink) shl 7);
end;

procedure TDirectTextDriver.Init;
var
  newMode: PTextMode;
begin
  inherited Init;
  Scroll := false;
  newMode := New(PTextMode, Create);
  with newMode^ do begin
    SetId('BW40');
    Width := 40;
    Height := 25;
    MaxX := 39;
    MaxY := 24;
    Name := 'BW40';
    AdditionalData := BW40;
    Description := '40x25 B/W on color adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, Create);
  with newMode^ do begin
    SetId('BW80');
    Width := 80;
    Height := 25;
    MaxX := 79;
    MaxY := 24;
    Name := 'BW80';
    AdditionalData := BW80;
    Description := '80x25 B/W on color adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, Create);
  with newMode^ do begin
    SetId('Mono');
    Width := 80;
    Height := 25;
    MaxX := 79;
    MaxY := 24;
    Name := 'Mono';
    AdditionalData := Mono;
    Description := '80x25 B/W on monochrome adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, Create);
  with newMode^ do begin
    SetId('CO40');
    Width := 40;
    Height := 25;
    MaxX := 39;
    MaxY := 24;
    Name := 'CO40';
    AdditionalData := CO40;
    Description := '40x25 color on color adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, Create);
  with newMode^ do begin
    SetId('CO408x8');
    Width := 40;
    Height := 25;
    MaxX := 39;
    MaxY := 24;
    Name := 'CO40';
    AdditionalData := CO40 + Font8x8;
    Description := '40x25 color on color adapter with 8x8 font';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, Create);
  with newMode^ do begin
    SetId('CO80');
    Width := 80;
    Height := 25;
    MaxX := 79;
    MaxY := 24;
    Name := 'CO80';
    AdditionalData := CO80;
    Description := '80x25 color on color adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, Create);
  with newMode^ do begin
    SetId('CO808x8');
    Width := 80;
    Height := 50;
    MaxX := 79;
    MaxY := 49;
    Name := 'CO80';
    AdditionalData := CO80 + Font8x8;
    Description := '80x25 color on color adapter with 8x8 font';
    HelpText := '';
    Modes^.Add(newMode);
  end;
end;

procedure TDirectTextDriver.HLine(AX, AY, AWidth: integer; ALineStyle: TLineStyle);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  cursorState: boolean;
begin
  cursorState := State^.IsCursorOn;
  if CursorState then CursorOff;
  ch.Attributes := State^.Attributes;
  ch.Character := #196;
  if (ALineStyle = lsDouble) then ch.Character := #205;
  Offset := CurrentScreen;
  Inc(offset, 2 * (AY * Mode^.Width + AX));
  for index := 0 to AWidth - 1 do begin
    Move(ch, offset^, 2);
    Inc(offset, 2);
  end;
  if CursorState then CursorOn;
end;

procedure TDirectTextDriver.VLine(AX, AY, AHeight: integer; ALineStyle: TLineStyle);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  cursorState: boolean;
begin
  cursorState := State^.IsCursorOn;
  if CursorState then CursorOff;
  ch.Attributes := State^.Attributes;
  ch.Character := #179;
  if (ALineStyle = lsDouble) then ch.Character := #186;
  offset := CurrentScreen;
  Inc(offset, 2 * (AY * Mode^.Width + AX));
  for index := AY to AY + AHeight - 1 do begin
    Move(ch, offset^, 2);
    Inc(offset, 2 * Mode^.Width);
  end;
  if CursorState then CursorOn;
end;

procedure TDirectTextDriver.Box(ARect: TRect; ALineStyle: TLineStyle);
var
  ch: TTextChar;
  offset: PByte;
begin
  ch.Attributes := State^.Attributes;

  ch.Character := #218;
  if (ALineStyle = lsDouble) then ch.Character := #201;
  offset := CurrentScreen;
  Inc(offset, 2 * (ARect.Y * Mode^.Width + ARect.X));
  Move(ch, offset^, 2);

  ch.Character := #191;
  if (ALineStyle = lsDouble) then ch.Character := #187;
  offset := CurrentScreen;
  Inc(offset, 2 * (ARect.Y * Mode^.Width + ARect.X + ARect.Width - 1));
  Move(ch, offset^, 2);

  ch.Character := #192;
  if (ALineStyle = lsDouble) then ch.Character := #200;
  offset := CurrentScreen;
  Inc(offset, 2 * ((ARect.Y + ARect.Height - 1) * Mode^.Width + ARect.X));
  Move(ch, offset^, 2);

  ch.Character := #217;
  if (ALineStyle = lsDouble) then ch.Character := #188;
  offset := CurrentScreen;
  Inc(offset, 2 * ((ARect.Y + ARect.Height - 1) * Mode^.Width + ARect.X + ARect.Width - 1));
  Move(ch, offset^, 2);

  HLine(ARect.X + 1, ARect.Y, ARect.Width - 2, ALineStyle);
  HLine(ARect.X + 1, ARect.Y + ARect.Height - 1, ARect.Width - 2, ALineStyle);
  VLine(ARect.X, ARect.Y + 1, ARect.Height - 2, ALineStyle);
  VLine(ARect.X + ARect.Width - 1, ARect.Y + 1, ARect.Height - 2, ALineStyle);
end;

procedure TDirectTextDriver.ClrScr;
var
  rect: TRect;
begin
  rect.CreateDims(0, 0, Mode^.Width, Mode^.Height);
  FillRect(rect);
end;

procedure TDirectTextDriver.FillRect(ARect: TRect);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  line, linePtr: PByte;
begin
  GetMem(line, ARect.Width * 2);
  offset := CurrentScreen;
  ch.Attributes := State^.Attributes;
  ch.Character := #32;
  linePtr := line;
  for index := 0 to ARect.Width - 1 do begin
    Move(ch, linePtr^, 2);
    Inc(linePtr, 2);
  end;
  Inc(offset, 2 * (ARect.Y * Mode^.Width + ARect.X));
  for index := ARect.Y to ARect.Bottom do begin
    Move(line^, offset^, ARect.Width * 2);
    Inc(offset, Mode^.Width * 2);
  end;
  SetXY(0, 0);
  FreeMem(line, ARect.Width * 2);
end;

destructor TDirectTextDriver.Free;
begin
  inherited Free;
end;

begin
end.