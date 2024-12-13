{$I COMPILER.INC}
unit Vga8Drv;

interface

uses
  Graphics,
  GrDrv8,
  AplMath,
  AplConst,
  AplUtils,
  AplTypes,
  Streams,
  Drawing;

type
  PVga8Driver = ^TVga8Driver;

  TVga8Driver = object(TGraphics8Driver)
  private
    function InitializeDrawRect(APX, APY, AWidth, AHeight: integer; var ADrawRect: TRect): boolean;
  public
    procedure GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure RenderText(APX, APY, ALength: integer; AText: PChar); virtual;
    procedure Line(AX1, AY1, AX2, AY2: integer); virtual;
    procedure HLine(APX, APY, AWidth: integer); virtual;
    procedure VLine(APX, APY, AHeight: integer); virtual;
    procedure Circle(ACenterX, ACenterY, ARadius: integer); virtual;
    procedure DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure FastFillScreen(AColor: byte); virtual;
    procedure FastDrawScreen(AImage: PByte); virtual;
    procedure FastDrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure FastSetPixel(APX, APY: integer); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  MouseDrv,
  Palettes,
  AplStr;

procedure TVga8Driver.Init;
var
  newMode: PGraphicsMode;
  desc: string;
begin
  inherited Init;
  newMode := New(PGraphicsMode, Create);
  with newMode^ do begin
    ModeId := $13;
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

procedure TVga8Driver.SetMode(AMode: PGraphicsMode);
begin
  inherited SetMode(AMode);
  asm
    mov ah, 0
    mov al, 13h
    int 10h
  end;
  State^.FrameBuffer := Mode^.FrameBuffer;
  State^.ViewPort.SetDims(0, 0, Mode^.Width, Mode^.Height);
  SetVgaPalette;
  Mouse.XShift := 1;
end;

procedure TVga8Driver.WaitForVSync;
begin
  asm
    mov dx, 3DAh
    @loop:
    in al, dx
    test al, 8h
    jz @loop
  end;
end;

procedure TVga8Driver.FastFillScreen(AColor: byte);
var
  buffer: PByte;
begin
  buffer := Mode^.FrameBuffer;
  asm
    les di, buffer
    mov cx, 32000
    mov al, AColor
    mov ah, al
    rep stosw
  end;
end;

procedure TVga8Driver.FastDrawScreen(AImage: PByte);
var
  buffer: PByte;
begin
  buffer := Mode^.FrameBuffer;
  asm
    push ds
    les di, buffer
    lds si, AImage
    mov cx, 32000
    rep movsw
    pop ds
  end;
end;

procedure TVga8Driver.FastDrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte);
var
  screen: PByte;
  screenWidth: word;
begin
  screenWidth := Mode^.BytesPerScanline;
  screen := Mode^.FrameBuffer;
  Inc(screen, APY * screenWidth + APX);
  asm
    push ds
    les di, screen
    lds si, AImage
    mov ax, screenWidth
    mov dx, AWidth
    mov bx, AHeight
    sub ax, dx
    @loop:
      mov cx, dx
      rep movsb
      add di, ax
      dec bx
      jnz @loop
    pop ds
  end;
end;

procedure TVga8Driver.FastSetPixel(APX, APY: integer);
var
  ptr: PBufferArray;
begin
  ptr := Mode^.FrameBuffer;
  ptr^[APY * Mode^.BytesPerScanLine + APX] := State^.ForeColor;
end;

function TVga8Driver.InitializeDrawRect(APX, APY, AWidth, AHeight: integer; var ADrawRect: TRect): boolean;
var
  visibleRect: TRect;
begin
  InitializeDrawRect := false;
  if HasException then
    exit;
  State^.Bounds.GetIntersection(State^.ViewPort, visibleRect);
  ADrawRect.CreateDims(APX, APY, AWidth, AHeight);
  ADrawRect.Intersect(visibleRect);
  if not ADrawRect.IsEmpty then
    InitializeDrawRect := true;
end;

procedure TVga8Driver.RenderText(APX, APY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  ch: char;
  xIndex, maxY, sx, sy, minX, maxX: integer;
  width: integer;
  linePtr: PWord;
  height: word;
  screen: PByte;
  charIndex, fore: byte;
  count: word;
begin
  if HasException then
    exit;
  State^.Bounds.GetIntersection(State^.ViewPort, drawRect);
  if drawRect.IsEmpty then
    exit;
  if APX > drawRect.Right then
    exit;
  if APY > drawRect.Bottom then
    exit;
  height := State^.Font^.Height;
  if APY + height < drawRect.Y then
    exit;
  sx := APX;
  charIndex := 0;
  maxY := Min(drawRect.Bottom, APY + height - 1);
  fore := State^.ForeColor;
  while charIndex < ALength  do begin
    ch := AText[charIndex];
    Inc(charIndex);
    width := State^.Font^.TextWidth(ch);
    if sx > drawRect.Right then
      exit;
    if sx + width < drawRect.X then begin
      Inc(sx, width);
      continue;
    end;
    linePtr := State^.Font^.FontData;
    minX := Max(0, drawRect.X - sx);
    maxX := Min(width - 1, drawRect.Right - sx);
    sy := Max(drawRect.Y, APY);
    Inc(linePtr, Ord(ch) * height + (sy - APY));
    count := maxX - minX + 1;
    screen := GetScreenPointer(sx + minX, sy);
    while sy <= maxY do begin
      asm
        push ds
        les di, screen
        lds si, linePtr
        mov ax, ds:[si]
        mov bx, 8000h
        mov cx, minX
        shr bx, cl
        mov cx, count
        mov dh, fore
        @loop:
          mov si, ax
          and si, bx
          jz @next
          mov es:[di], dh
          @next:
          shr bx, 1
          inc di
        loop @loop
        pop ds
      end;
      Inc(screen, 320);
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
  GetDrawRect(drawRect);
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
  screenPtr := State^.FrameBuffer;
  width := Mode^.Width;
  color := State^.ForeColor;
  asm
    mov cx, aError
    @loop:
      mov ax, AX1
      mov bx, x
      cmp ax, bx
      jl @xCompare
      mov bx, right
      cmp ax, bx
      jg @xCompare
      mov ax, AY1
      mov bx, y
      cmp ax, bx
      jl @xCompare
      mov bx, bottom
      cmp ax, bx
      jg @xCompare
      les di, screenPtr
      mov ax, AY1
      mov bx, width
      mul bx
      add ax, AX1
      add di, ax
      mov bl, color
      mov es:[di], bl
    @xCompare:
      mov ax, AX1
      mov bx, AX2
      cmp ax, bx
      jne @continue
      mov ax, AY1
      mov bx, AY2
      cmp ax, bx
      jne @continue
      jmp @endLoop
    @continue:
      mov dx, cx
      shl dx, 1
      mov ax, dly
      cmp dx, ax
      jl @yCompare
      mov ax, AX1
      mov bx, AX2
      cmp ax, bx
      je @endLoop
      add cx, dly
      add ax, sx
      mov AX1, ax
    @yCompare:
      mov ax, dlx
      cmp dx, ax
      jg @loop
      mov AX, AY1
      mov bx, AY2
      cmp ax, dx
      je @endLoop
      add cx, dlx
      add ax, sy
      mov AY1, ax
      jmp @loop
    @endLoop:
   end;

{  while true do begin
    if State.ViewPort.Contains(AX1, AY1) then begin
      screenPtr := State.FrameBuffer;
      Inc(screenPtr, longint(AY1) * Mode^.Width + AX1);
      screenPtr^ := State.ForeColor;
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

procedure TVga8Driver.HLine(APX, APY, AWidth: integer);
var
  screen: PByte;
  lineWidth: integer;
  color: byte;
  drawRect: TRect;
begin
  if HasException then
    exit;
  GetDrawRect(drawRect);
  if not drawRect.ContainsY(APY) then
    exit;
  APX := drawRect.ClampY(APX);
  AWidth := MinL(drawRect.Width, AWidth);
  if AWidth <= 0 then
    exit;

  screen := GetScreenPointer(APX, APY);
  color := byte(State^.ForeColor);
  asm
    mov cx, AWidth
    mov al, color
    les di, screen
    rep stosb
  end;
end;

procedure TVga8Driver.VLine(APX, APY, AHeight: integer);
var
  index: integer;
  screen: PByte;
  drawRect: TRect;
  min, max: integer;
  color: byte;
  screenWidth: word;
begin
  if HasException then
    exit;
  GetDrawRect(drawRect);
  if not drawRect.ContainsX(APX) then
    exit;
  APY := drawRect.ClampY(APY);
  AHeight := MinL(drawRect.Height, AHeight);
  if AHeight <= 0 then
    exit;

  screen := GetScreenPointer(APX, APY);
  color := ForeColor;
  screenWidth := Mode^.BytesPerScanLine;
  if State^.BufferMode then
    screenWidth := State^.ViewPort.Width;

  asm
    mov ax, screenWidth
    mov cx, AHeight
    mov bl, color
    les di, screen
  @loop:
    mov es:[di], bl
    add di, ax
    loop @loop
  end;
end;

procedure TVga8Driver.Circle(ACenterX, ACenterY, ARadius: integer);
var
  t1, t2: integer;
  x, y: integer;
  color: byte;
  drawRect: TRect;
  procedure SetPix(APX, APY: integer);
  var
    drawPtr: PByte;
  begin
    if not drawRect.Contains(APX, APY) then
      exit;
    drawPtr := GetScreenPointer(APX, APY);
    drawPtr^ := ForeColor;
  end;
begin
  State^.Bounds.GetIntersection(State^.ViewPort, drawRect);
  t1 := ARadius shr 4;
  x := ARadius;
  y := 0;
  color := State^.ForeColor;
  repeat
    SetPix(ACenterX + x, ACenterY + y);
    SetPix(ACenterX - x, ACenterY + y);
    SetPix(ACenterX + x, ACenterY - y);
    SetPix(ACenterX - x, ACenterY - y);
    SetPix(ACenterX + y, ACenterY + x);
    SetPix(ACenterX - y, ACenterY + x);
    SetPix(ACenterX + y, ACenterY - x);
    SetPix(ACenterX - y, ACenterY - x);
    Inc(y);
    Inc(t1, y);
    t2 := t1 - x;
    if t2 >= 0 then begin
      t1 := t2;
      Dec(x);
    end;
  until x < y;
end;

procedure TVga8Driver.DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte);
var
  screen: PByte;
  imageRect, drawRect: TRect;
  index: integer;
  screenWidth: word;
begin
  GetImageDrawRects(APX, APY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  screenWidth := Mode^.BytesPerScanline;
  screen := Mode^.FrameBuffer;
  Inc(screen, drawRect.Y * screenWidth + drawRect.X);
  Inc(AImage, word(imageRect.Y) * AWidth + imageRect.X);
  index := drawRect.Height;
  asm
    push ds
    lds si, AImage
    les di, screen
    mov cx, drawRect.Height
    mov bx, imageRect.Width
    mov dx, drawRect.Width
    mov ax, screenWidth
    sub ax, dx
    sub bx, dx
    @yloop:
      push cx
      mov cx, dx
      rep movsb
      pop cx
      add di, ax
      add si, bx
    loop @yloop
    pop ds
  end;
end;

procedure TVga8Driver.DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  screen, image: PByte;
  screenWidth: word;
  tcolor: byte;
begin
  if HasException then
    exit;
  GetImageDrawRects(APX, APY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  screen := GetScreenPointer(drawRect.X, drawRect.Y);
  image := AImage;
  Inc(image, imageRect.Y * imageRect.Width + imageRect.X);
  screenWidth := Mode^.BytesPerScanline;
  tcolor := TransparentColor;
  asm
    push ds
    lds si, image
    les di, screen
    mov cx, drawRect.Height
    mov bx, imageRect.Width
    mov dx, drawRect.Width
    mov ax, screenWidth
    @yloop:
      push cx
      push ax
      mov cx, dx
      mov ah, tcolor
      @xLoop:
        cmp ds:[si], ah
        je @skip
        movsb
        jmp @next
        @skip:
        inc si
        inc di
        @next:
      loop @xLoop
      pop ax
      pop cx
      add di, ax
      sub di, dx
      add si, bx
      sub si, dx
    loop @yloop
    pop ds
  end;
end;

procedure TVga8Driver.DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: word;
  screen: PByte;
  sy: longint;
  lineWidth: integer;
  streamStart: longint;
begin
  if AStream^.HasException or HasException then
    exit;
  GetImageDrawRects(APX, APY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  streamStart := AStream^.Position;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPointer(drawRect.X, sy);
    AStream^.Seek((yIndex + imageRect.Y) * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Read(screen, lineWidth);
    Inc(sy);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
end;

procedure TVga8Driver.DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: word;
  screen: PByte;
  imageLine: PByte;
  streamStart: longint;
  sy: integer;
  lineWidth: integer;
  tcolor: byte;
begin
  if AStream^.HasException or HasException then
    exit;
  GetImageDrawRects(APX, APY, AWidth, AHeight, imageRect, drawRect);
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
  tcolor := TransparentColor;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPointer(drawRect.X, drawRect.Y + yIndex);
    AStream^.Seek(yIndex * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Read(imageLine, lineWidth);
    asm
      push ds
      lds si, imageLine
      les di, screen
      mov cx, lineWidth
      mov bl, tcolor
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
  FreeMem(imageLine, lineWidth);
end;

procedure TVga8Driver.GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: word;
  screen, image: PByte;
  sy: longint;
  lineWidth: integer;
begin
  if HasException then
    exit;
  GetImageDrawRects(APX, APY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPointer(drawRect.X, sy);
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
  end;
end;

procedure TVga8Driver.GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: word;
  screen: PByte;
  sy: longint;
  lineWidth: integer;
  streamStart: longint;
begin
  if AStream^.HasException or HasException then
    exit;
  GetImageDrawRects(APX, APY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  streamStart := AStream^.Position;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPointer(drawRect.X, sy);
    AStream^.Seek((yIndex + imageRect.Y) * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Write(screen, lineWidth);
    Inc(sy);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
end;

destructor TVga8Driver.Free;
begin
  inherited Free;
end;

end.