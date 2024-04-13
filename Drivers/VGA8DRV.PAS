{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Vga8Drv;

interface

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  Objects,
  Common,
  StrUtils,
  Streams,
  Drawing,
  MouseDrv,
  GraphDrv,
  GrDrv8;

type
  PVga8Driver = ^TVga8Driver;

  TVga8Driver = object(TGraphics8Driver)
  private
    function GetScreenPtr(AX, AY: integer; var AOffset: word): PByte;
  public
    function GetPixel(AX, AY: integer): byte; virtual;
    procedure GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure SetPixel(AX, AY: integer); virtual;
    procedure Line(AX1, AY1, AX2, AY2: integer); virtual;
    procedure HLine(AX, AY, AWidth: integer); virtual;
    procedure VLine(AX, AY, AHeight: integer); virtual;
    procedure RenderText(AX, AY, ALength: integer; AText: PChar); virtual;
    procedure DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  Errors;

function TVga8Driver.GetPixel(AX, AY: integer): byte;
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  GetPixel := 0;
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if not drawRect.IntersectsCoords(AX, AY) then
    exit;
  offset := AX + longint(AY) * Mode^.BytesPerScanLine;
  ptr := State.FrameBuffer;
  Inc(ptr, offset);
  GetPixel := ptr^;
end;

procedure TVga8Driver.SetMode(AMode: PGraphicsMode);
begin
  inherited SetMode(AMode);
  asm
    mov   ah, 0
    mov   al, 13h
    int   10h
  end;
  State.FrameBuffer := Mode^.FrameBuffer;
  SetStandardPalette;
  Mouse.XDiv := 1;
end;

procedure TVga8Driver.SetPixel(AX, AY: integer);
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if not drawRect.IntersectsCoords(AX, AY) then
    exit;
  ptr := State.FrameBuffer;
  offset := AX + longint(AY) * Mode^.BytesPerScanLine;
  Inc(ptr, offset);
  ptr^ := State.ForeColor;
end;

function TVga8Driver.GetScreenPtr(AX, AY: integer; var AOffset: word): PByte;
var
  bank: integer;
  screen: PByte;
begin
  if State.FrameBuffer <> Mode^.FrameBuffer then begin
    screen := State.FrameBuffer;
    AOffset := AY * State.ViewPort.Width + AX;
    Inc(screen, AOffset);
    GetScreenPtr := screen;
    exit;
  end;
  AOffset := AY * Mode^.BytesPerScanLine + AX;
  screen := Mode^.FrameBuffer;
  Inc(screen, AOffset);
  GetScreenPtr := screen;
end;


procedure TVga8Driver.RenderText(AX, AY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  charIndex, yIndex, xIndex: integer;
  ch: char;
  sx, sy, minX, maxX: integer;
  width: integer;
  linePtr: PByte;
  height: integer;
  screen: PByte;
  fore: byte;
  offset: word;
  currentLine: byte;
begin
  if HasException then
    exit;
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if AX > drawRect.Right then
    exit;
  if AY > drawRect.Bottom then
    exit;
  height := State.Font^.Height;
  if AY + height < drawRect.Y then
    exit;
  sx := AX;
  for charIndex := 0 to ALength - 1 do begin
    ch := AText[charIndex];
    width := State.Font^.TextWidth(ch);
    if sx > drawRect.Right then
      exit;
    if sx + width < drawRect.X then begin
      Inc(sx, width);
      continue;
    end;
    sy := AY;
    fore := State.ForeColor;
    linePtr := State.Font^.FontData;
    Inc(linePtr, Ord(ch) * height);
    minX := MaxLong(0, drawRect.X - sx);
    maxX := MinLong(State.Font^.TextWidth(ch) - 1, drawRect.Right - sx);
    sy := AY;
    for yIndex := 0 to height - 1 do begin
      currentLine := linePtr^;
      if sy < drawRect.Y then begin
        Inc(linePtr);
        Inc(sy);
        continue;
      end;
      if sy > drawRect.Bottom then
        break;
      screen := GetScreenPtr(sx + minX, sy, offset);
      for xIndex := minX to maxX do begin
        if (currentLine and (128 shr xIndex)) > 0 then
          screen^ := fore;
        Inc(screen);
        Inc(offset);
      end;
      Inc(linePtr);
      Inc(sy);
    end;
    Inc(sx, width);
  end;
end;

procedure TVga8Driver.Line(AX1, AY1, AX2, AY2: integer);
var
  aError, aError2, sx, sy, dlx, dly: integer;
  screenPtr: PByte;
  x, y, right, bottom, width: integer;
  color: byte;
  drawRect: TRect;
begin
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  dlx := Abs(AX2 - AX1);
  if AX1 < AX2 then
    sx := 1
  else
    sx := -1;

  dly := -Abs(AY2 - AY1);
  if AY1 < AY2 then
    sy := 1
  else
    sy := -1;

  aError := dlx + dly;
  x := drawRect.X;
  y := drawRect.Y;
  right := drawRect.Right;
  bottom := drawRect.Bottom;
  screenPtr := State.FrameBuffer;
  width := Mode^.Width;
  color := State.ForeColor;
  asm
    mov cx, [aError]
    @loop:
      mov ax, [AX1]
      mov bx, [x]
      cmp ax, bx
      jl @calc
      mov bx, [right]
      cmp ax, bx
      jg @calc
      mov ax, [AY1]
      mov bx, [y]
      cmp ax, bx
      jl @calc
      mov bx, [bottom]
      cmp ax, bx
      jg @calc
      les di, screenPtr
      mov ax, [AY1]
      mov bx, [width]
      mul bx
      add ax, [AX1]
      add di, ax
      mov bl, [color]
      mov [es:di], bl
      @calc:
      mov ax, [AX1]
      mov bx, [AX2]
      cmp ax, bx
      jne @notDone
      mov ax, [AY1]
      mov bx, [AY2]
      cmp ax, bx
      jne @notDone
      jmp @endLoop
      @notDone:
      mov dx, cx
      shl dx, 1
      mov ax, [dly]
      cmp dx, ax
      jl @yComp
      mov ax, [AX1]
      mov bx, [AX2]
      cmp ax, bx
      je @endLoop
      add cx, [dly]
      add ax, [sx]
      mov [AX1], ax
      @yComp:
      mov ax, [dlx]
      cmp dx, ax
      jg @loop
      mov ax, [AY1]
      mov bx, [AY2]
      cmp ax, dx
      je @endLoop
      add cx, [dlx]
      add ax, [sy]
      mov [AY1], ax
    jmp @loop
    @endLoop:
   end;
{  while true do begin
    if State^.ViewPort.IntersectCoords(AX1, AY1) then begin
      screenPtr := State^.FrameBuffer;
      Inc(screenPtr, longint(AY1) * Mode^.Width + AX1);
      screenPtr^ := State^.ForeColor;
    end;
    if (AX1 = AX2) and (AY1 = AY2) then
      break;
    aError2 := 2 * aError;
    if aError2 >= dly then begin
      if AX1 = AX2 then
        break;
      Inc(aError, dly);
      Inc(AX1, sx);
    end;
    if aError2 <= dlx then begin
      if AY1 = AY2 then
        break;
      Inc(aError, dlx);
      Inc(AY1, sy);
    end;
  end;}
end;

procedure TVga8Driver.HLine(AX, AY, AWidth: integer);
var
  screen: PByte;
  lineWidth: integer;
  offset: word;
  color: byte;
  drawRect: TRect;
begin
  if HasException then
    exit;
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if (AY < drawRect.Y) or (AY > drawRect.Bottom) then
    exit;
  CheckRange(AX, drawRect.X, drawRect.Right);
  AWidth := MinLong(drawRect.Width, AWidth);
  if AWidth <= 0 then
    exit;
  screen := GetScreenPtr(AX, AY, offset);
  color := byte(ForeColor);
  FillChar(screen^, AWidth, color);
end;

procedure TVga8Driver.VLine(AX, AY, AHeight: integer);
var
  index: integer;
  offset: word;
  screen: PByte;
  drawRect: TRect;
begin
  if HasException then
    exit;
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if (AX < drawRect.X) or (AX > drawRect.Right) then
    exit;
  CheckRange(AY, drawRect.Y, drawRect.Bottom);
  AHeight := MinLong(drawRect.Height, AHeight);
  if AHeight <= 0 then
    exit;
  for index := MaxLong(AY, 0) to MinLong(AY + AHeight - 1, Mode^.MaxY) do begin
    screen := GetScreenPtr(AX, index, offset);
    screen^ := ForeColor;
  end;
end;

procedure TVga8Driver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: word;
  sy: word;
  lineWidth: integer;
begin
  if HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, sy, offset);
    image := AImage;
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    Move(image^, screen^, lineWidth);
    Inc(image, lineWidth);
    Inc(sy);
  end;
end;

procedure TVga8Driver.DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: integer;
  sy: longint;
  offset: word;
  screen, image: PByte;
begin
  if HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, sy, offset);
    image := AImage;
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    for xIndex := 0 to drawRect.Width - 1 do begin
      if image^ <> TransparentColor then
        screen^ := image^;
      Inc(image);
      Inc(screen);
    end;
    Inc(sy);
  end;
end;

procedure TVga8Driver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  offset: word;
  sy: longint;
  lineWidth: integer;
  streamStart: longint;
begin
  if AStream^.HasException or HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  streamStart := AStream^.Position;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, sy, offset);
    AStream^.Seek((yIndex + imageRect.Y) * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Read(screen, lineWidth);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
end;

procedure TVga8Driver.DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: integer;
  screen: PByte;
  offset: word;
  imageLine, linePtr: PByte;
  streamStart: longint;
  sy: integer;
  lineWidth: integer;
begin
  if AStream^.HasException or HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  lineWidth := drawRect.Width;
  GetMem(imageLine, lineWidth);
  if not Assigned(imageLine) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  streamStart := AStream^.Position;
  sy := drawRect.Y;
  AStream^.Seek((yIndex + imageRect.Y) * AWidth + imageRect.X, soFromPosition);
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, drawRect.Y + yIndex, offset);
    AStream^.Seek(yIndex * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Read(imageLine, lineWidth);
    linePtr := imageLine;
    for xIndex := 0 to lineWidth - 1 do begin
      if linePtr^ <> TransparentColor then
        screen^ := linePtr^;
      Inc(screen);
      Inc(offset);
      Inc(linePtr);
    end;
    Inc(sy);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
  FreeMem(imageLine, lineWidth);
end;

procedure TVga8Driver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: word;
  sy: longint;
  lineWidth: integer;
begin
  if HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, sy, offset);
    image := ABuffer;
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width);
    Move(screen^, image^, lineWidth);
    Inc(image, lineWidth);
    Inc(sy);
  end;
end;

procedure TVga8Driver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  offset: word;
  sy: longint;
  lineWidth: integer;
  streamStart: longint;
begin
  if AStream^.HasException or HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  streamStart := AStream^.Position;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, sy, offset);
    AStream^.Seek((yIndex + imageRect.Y) * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Write(screen, lineWidth);
    Inc(sy);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
end;

procedure TVga8Driver.Init;
var
  newMode: PGraphicsMode;
  desc: string;
begin
  inherited Init;
  newMode := New(PGraphicsMode, Create);
  with newMode^ do begin
    Id := TString.New('Vga'
      + IntToStr(320)
      + 'x'
      + IntToStr(200)
      + 'x'
      + IntToStr(8));
    desc := 'VGA '
      + IntToStr(320)
      + 'x'
      + IntToStr(200)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 320;
    Height := 200;
    MaxX := 319;
    MaxY := 199;
    Bpp := 8;
    BytesPerScanLine := 320;
    HelpText := TString.New('Requires a VGA card.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  Modes.Add(newMode);
end;

destructor TVga8Driver.Free;
begin
  inherited Free;
end;

procedure TVga8Driver.WaitForVSync;
begin
  while (Port[$3DA] and $08) = $08 do;
  while (Port[$3DA] and $08) <> $08 do;
end;

end.