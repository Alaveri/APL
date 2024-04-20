{$I COMPILER.INC}
unit VgaXDrv;

interface

uses
  Objects,
  GraphDrv,
  GrDrv8,
  Common,
  Streams,
  Lists,
  Drawing;

type
  PVgaModeXDriver = ^ TVgaModeXDriver;

  TVgaXPageArray = array[0..3] of word;

  TVgaModeXDriver = object(TGraphics8Driver)
  private
    FActivePageOffset: word;
    FDisplayPageOffset: word;
    FPage: TVgaXPageArray;
    FPlanesPerPixel: word;
    FCrtcAddress: word;
    function GetScreenPtr(AX, AY: integer; var AOffset: word): PByte;
    function GetCrtcAddress: word;
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
    procedure SetActivePage(APage: byte);
    procedure SetDisplayPage(APage: byte);
    procedure CopyPage(ASource, ADest: byte);
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  StrUtils,
  Errors,
  MouseDrv;

function TVgaModeXDriver.GetScreenPtr(AX, AY: integer; var AOffset: word): PByte;
var
  screen: PByte;
begin
  if State.FrameBuffer <> Mode^.FrameBuffer then begin
    screen := State.FrameBuffer;
    AOffset := (longint(AY) * State.ViewPort.Width + AX) div 4;
    Inc(screen, AOffset);
    GetScreenPtr := screen;
    exit;
  end;

  AOffset := (longint(AY) * Mode^.BytesPerScanLine + AX) div 4;
  screen := Mode^.FrameBuffer;
  Inc(screen, AOffset);
  GetScreenPtr := screen;
end;

procedure TVgaModeXDriver.Init;
var
  newMode: PGraphicsMode;
  desc: string;
begin
  inherited Init;
  FActivePageOffset := 0;
  FDisplayPageOffset := 0;
  FillChar(FPage, SizeOf(FPage), 0);
  FPlanesPerPixel := 0;
  FCrtcAddress := 0;
  newMode := New(PGraphicsMode, Create);
  with newMode^ do begin
    Id := TString.New('VgaX'
      + IntToStr(320)
      + 'x'
      + IntToStr(200)
      + 'x'
      + IntToStr(8));
    desc := 'VGA X '
      + IntToStr(320)
      + 'x'
      + IntToStr(200)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 320;
    Height := 200;
    MaxX := 319;
    MaxY := 199;
    NumPages := 4;
    FPage[0] := 0;
    FPage[1] := 16000;
    FPage[2] := 32000;
    FPage[3] := 48000;
    Bpp := 8;
    BytesPerScanLine := 320;
    HelpText := TString.New('Requires a VGA card.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  Modes.Add(newMode);
  newMode := New(PGraphicsMode, Create);
  with newMode^ do begin
    Id := TString.New('VgaX'
      + IntToStr(320)
      + 'x'
      + IntToStr(240)
      + 'x'
      + IntToStr(8));
    desc := 'VGA X '
      + IntToStr(320)
      + 'x'
      + IntToStr(240)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 320;
    Height := 240;
    NumPages := 3;
    FPage[0] := 0;
    FPage[1] := 19200;
    FPage[2] := 38400;
    FPage[3] := 0;
    MaxX := 319;
    MaxY := 239;
    Bpp := 8;
    BytesPerScanLine := 320;
    HelpText := TString.New('Requires a VGA card.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  Modes.Add(newMode);
end;

function TVgaModeXDriver.GetCrtcAddress: word; assembler;
asm
  mov es, [Seg0040]
  mov di, 063h;
  mov ax, word ptr es:[di]
end;

function TVgaModeXDriver.GetPixel(AX, AY: integer): byte;
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  GetPixel := 0;
{  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if not drawRect.IntersectsCoords(AX, AY) then
    exit;
  offset := AX + longint(AY) * Mode^.BytesPerScanLine;
  ptr := State.FrameBuffer;
  Inc(ptr, offset);
  GetPixel := ptr^;}
end;

procedure TVgaModeXDriver.SetMode(AMode: PGraphicsMode);
begin
  inherited SetMode(AMode);
  FCrtcAddress := GetCrtcAddress;
  asm
    mov ax, 0013h
    int 10h
  end;
  { Change to Mode-Y 320x200 with 4 pages }
  PortW[$03C4] := $0604; { Clear chain 4 }
  PortW[FCrtcAddress] := $0014; { Disable dword mode }
  PortW[FCrtcAddress] := $E317; { Enabled byte mode }
  if AMode^.Height = 240 then begin
    { 320x240 with 3 pages }
    Port[$03C2] := $00E3;  { Change to square pixels }
    PortW[FCrtcAddress] := $2C11; { Change vertical timing and center }
    PortW[FCrtcAddress] := $0D06; { Vertical total }
    PortW[FCrtcAddress] := $3E07; { Overflow register }
    PortW[FCrtcAddress] := $EA10; { Vertical retrace start }
    PortW[FCrtcAddress] := $AC11; { Vertical retrace and write protect }
    PortW[FCrtcAddress] := $DF12; { Vertical display enable end }
    PortW[FCrtcAddress] := $E715; { Start vertical blanking }
    PortW[FCrtcAddress] := $0616; { End Vertical blanking }
  end;
  State.FrameBuffer := Mode^.FrameBuffer;
  SetStandardPalette;
  Mouse.XShift := 1;
end;

procedure TVgaModeXDriver.SetPixel(AX, AY: integer);
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
{  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if not drawRect.IntersectsCoords(AX, AY) then
    exit;
  ptr := State.FrameBuffer;
  offset := AX + longint(AY) * Mode^.BytesPerScanLine;
  Inc(ptr, offset);
  ptr^ := State.ForeColor;}
end;

procedure TVgaModeXDriver.RenderText(AX, AY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  charIndex, yIndex: integer;
  count: word;
  ch: char;
  sx, sy: integer;
  minX, maxX: byte;
  width: integer;
  linePtr: PByte;
  height: integer;
  screen: PByte;
  fore: byte;
  offset: word;
  currentLine: byte;
begin
{  if HasException then
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
    minX := Max(0, drawRect.X - sx);
    maxX := Min(State.Font^.TextWidth(ch) - 1, drawRect.Right - sx);
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
      count := maxX - minX + 1;
      asm
        les di, screen
        mov cx, count
        mov dl, minx
        mov ah, fore
        mov bh, currentLine
        @loop:
          mov al, bh
          push cx
          mov cl, dl
          mov bl, 128
          shr bl, cl
          pop cx
          and al, bl
          jz @next
          mov al, ah
          mov [es:di], al
          @next:
          inc dl
          inc di
        loop @loop
      end;
      Inc(linePtr);
      Inc(sy);
    end;
    Inc(sx, width);
  end;}
end;

procedure TVgaModeXDriver.Line(AX1, AY1, AX2, AY2: integer);
var
  aError, aError2, sx, sy, dlx, dly: integer;
  screenPtr: PByte;
  x, y, right, bottom, width: integer;
  color: byte;
  drawRect: TRect;
begin
{  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
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

procedure TVgaModeXDriver.HLine(AX, AY, AWidth: integer);
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
  asm
    mov cx, AWidth
    mov al, color
    les di, screen
    @loop:
      mov [es:di], al
      inc di
    loop @loop
  end;
  FillChar(screen^, AWidth, color);
end;

procedure TVgaModeXDriver.VLine(AX, AY, AHeight: integer);
var
  index: integer;
  offset: word;
  screen: PByte;
  drawRect: TRect;
begin
{  if HasException then
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
  end;}
end;

procedure TVgaModeXDriver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: word;
  sy: word;
  lineWidth: word;
begin
{  if HasException then
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
    asm
      push ds
      lds si, image
      les di, screen
      mov cx, lineWidth
      rep movsb
      pop ds
    end;
    Inc(image, lineWidth);
    Inc(sy);
  end;}
end;

procedure TVgaModeXDriver.DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: integer;
  sy: longint;
  offset: word;
  screen, image: PByte;
  width: word;
begin
{  if HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  width := drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, sy, offset);
    image := AImage;
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    asm
      push ds
      lds si, image
      les di, screen
      mov cx, width
      mov bl, TransparentColor
      @loop:
        mov al, [ds:si]
        cmp al, bl
        je @equal
        movsb
        jmp @end
        @equal:
        inc di
        inc si
        @end:
      loop @loop
      pop ds
    end;
    Inc(sy);
  end;}
end;

procedure TVgaModeXDriver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  offset: word;
  sy: longint;
  lineWidth: integer;
  streamStart: longint;
begin
{  if AStream^.HasException or HasException then
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
    Raise(AStream^.Exception^.Code);}
end;

procedure TVgaModeXDriver.DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: integer;
  screen: PByte;
  offset: word;
  imageLine: PByte;
  streamStart: longint;
  sy: integer;
  lineWidth: integer;
begin
{  if AStream^.HasException or HasException then
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
    asm
      push ds
      lds si, imageLine
      les di, screen
      mov cx, lineWidth
      mov bl, TransparentColor
      @loop:
        mov al, [ds:si]
        cmp al, bl
        je @equal
        movsb
        jmp @end
        @equal:
        inc di
        inc si
        @end:
      loop @loop
      pop ds
    end;
    Inc(sy);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
  FreeMem(imageLine, lineWidth);}
end;

procedure TVgaModeXDriver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: word;
  sy: longint;
  lineWidth: integer;
begin
{  if HasException then
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
    asm
      push ds
      lds si, screen
      les di, image
      mov cx, lineWidth
      rep movsb
      pop ds
    end;
    Inc(image, lineWidth);
    Inc(sy);
  end;}
end;

procedure TVgaModeXDriver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  offset: word;
  sy: longint;
  lineWidth: integer;
  streamStart: longint;
begin
{  if AStream^.HasException or HasException then
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
    Raise(AStream^.Exception^.Code);}
end;

procedure TVgaModeXDriver.SetActivePage(APage: byte);
begin
end;

procedure TVgaModeXDriver.SetDisplayPage(APage: byte);
begin
end;

procedure TVgaModeXDriver.CopyPage(ASource, ADest: byte);
begin
end;

destructor TVgaModeXDriver.Free;
begin
  inherited Free;
end;

procedure TVgaModeXDriver.WaitForVSync;
begin
  asm
    mov dx, 3DAh
    @end:
    in al, dx
    test al, 8h
    jz @end
  end;
end;


end.