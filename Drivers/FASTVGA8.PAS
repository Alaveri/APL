{$I COMPILER.INC}
unit FastVga8;

interface

uses
  GraphDrv,
  GrDrv8,
  Common,
  AplTypes,
  Streams,
  Drawing;

type
  PFastVgaDriver = ^TFastVgaDriver;

  TFastVgaDriver = object(TGraphics8Driver)
  private
    function InitialBoundsCheck(AX, AY, AWidth, AHeight: integer; var ADrawRect: TRect): boolean;
  public
    function GetScreenPointer(AX, AY: integer; var AOffset: longint): PByte; virtual;
    procedure GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure RenderText(AX, AY, ALength: integer; AText: PChar); virtual;
    procedure Line(AX1, AY1, AX2, AY2: integer); virtual;
    procedure HLine(AX, AY, AWidth: integer); virtual;
    procedure VLine(AX, AY, AHeight: integer); virtual;
    procedure DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure FastFillScreen(AColor: byte); virtual;
    procedure FastDrawScreen(AImage: PByte); virtual;
    procedure FastDrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  MouseDrv,
  StrUtils;

procedure TFastVgaDriver.Init;
var
  newMode: PGraphicsMode;
  desc: string;
begin
  inherited Init;
  newMode := New(PGraphicsMode, Create);
  with newMode^ do begin
    Id := $13;
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

procedure TFastVgaDriver.SetMode(AMode: PGraphicsMode);
begin
  inherited SetMode(AMode);
  asm
    mov ah, 0
    mov al, 13h
    int 10h
  end;
  State.FrameBuffer := Mode^.FrameBuffer;
  SetStandardPalette;
  Mouse.XShift := 1;
end;

function TFastVgaDriver.GetScreenPointer(AX, AY: integer; var AOffset: longint): PByte;
var
  result: PByte;
begin
  AOffset := longint(AY) * Mode^.BytesPerScanLine + AX;
  result := Mode^.FrameBuffer;
  Inc(result, AOffset);
  GetScreenPointer := result;
end;

procedure TFastVgaDriver.WaitForVSync;
begin
  asm
    mov dx, 3DAh
    @loop:
    in al, dx
    test al, 8h
    jz @loop
  end;
end;

procedure TFastVgaDriver.FastFillScreen(AColor: byte);
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

procedure TFastVgaDriver.FastDrawScreen(AImage: PByte);
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

procedure TFastVgaDriver.FastDrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  screen: PByte;
  off: longint;
  wordOffset: word;
begin
  screen := GetScreenPointer(AX, AY, off);
  wordOffset := off;
  asm
    push ds
    lds si, AImage
    les di, screen
    add si, wordOffset
    mov cx, AHeight
    @loop:
      push cx
      mov cx, AWidth
      rep movsb
      pop cx
      mov dx, 320
      sub dx, cx
      add di, dx
    loop @loop
  end;
end;

function TFastVgaDriver.InitialBoundsCheck(AX, AY, AWidth, AHeight: integer; var ADrawRect: TRect): boolean;
begin
  InitialBoundsCheck := false;
  if HasException then
    exit;
  if HasException then
    exit;
  if AX > ADrawRect.Right then
    exit;
  if (AWidth > 0) and (AX + AWidth < ADrawRect.X) then
    exit;
  if AY > ADrawRect.Bottom then
    exit;
  if (AHeight > 0) and (AY + AHeight < ADrawRect.Y) then
    exit;
  InitialBoundsCheck := true;
end;

procedure TFastVgaDriver.RenderText(AX, AY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  charIndex, yIndex: integer;
  count: word;
  ch: char;
  sx, sy: integer;
  minX, maxX: byte;
  width: integer;
  linePtr: PWord;
  screen: PByte;
  fore: byte;
  offset: longint;
  currentLine: word;
  height: word;
begin
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  height := State.Font^.Height;
  if not InitialBoundsCheck(AX, AY, 0, height, drawRect) then
    exit;
  sx := AX;
  fore := State.ForeColor;
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
      screen := GetDrawPointer(sx + minX, sy, offset);
      count := maxX - minX + 1;
      asm
        les di, screen { Load screen pointer into ES:DI }
        mov cx, count { Load count into CX as the loop counter }
        mov dl, minx { Load starting x index into DL }
        mov dh, fore { Load foreground color into DH }
        mov ax, currentLine { Load current character line into AX }
        @loop:
          push cx { Save loop counter }
          mov cl, dl { Load x index into CL }
          mov bx, 8000h { Load 32768 into BX }
          shr bx, cl { Shift 32768 right by x index to get the mask }
          pop cx { Restore loop counter }
          push ax
          and ax, bx { Check if the character pixel is set }
          jz @next { If the pixel is not set, skip to the next pixel }
          mov [es:di], dh { Set the screen pixel to the ForeColor }
          @next:
          pop ax
          inc dl { Increment the x index }
          inc di { Increment the screen pointer }
        loop @loop
      end;
      Inc(linePtr);
      Inc(sy);
    end;
    Inc(sx, width);
  end;
end;

procedure TFastVgaDriver.Line(AX1, AY1, AX2, AY2: integer);
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
      mov [es:di], bl
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
      mov [AX1], ax
    @yCompare:
      mov ax, dlx
      cmp dx, ax
      jg @loop
      mov ax, AY1
      mov bx, AY2
      cmp ax, dx
      je @endLoop
      add cx, dlx
      add ax, sy
      mov [AY1], ax
      jmp @loop
    @endLoop:
   end;
end;

procedure TFastVgaDriver.HLine(AX, AY, AWidth: integer);
var
  screen: PByte;
  lineWidth: integer;
  offset: longint;
  color: byte;
  drawRect: TRect;
begin
  if HasException then
    exit;
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if not InitialBoundsCheck(AX, AY, AWidth, 0, drawRect) then
    exit;
  if AX < drawRect.X then
    AX := drawRect.X;
  if AX + AWidth > drawRect.Right then
    AWidth := drawRect.Right - AX + 1;
  if AWidth <= 0 then
    exit;
  screen := GetDrawPointer(AX, AY, offset);
  color := byte(State.ForeColor);
  asm
    mov cx, AWidth
    mov al, color
    les di, screen
    @loop:
      mov [es:di], al
      inc di
    loop @loop
  end;
end;

procedure TFastVgaDriver.VLine(AX, AY, AHeight: integer);
var
  index: integer;
  offset: longint;
  screen: PByte;
  drawRect: TRect;
  min, max: integer;
  color: byte;
  screenWidth: word;
begin
  if HasException then
    exit;
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if not InitialBoundsCheck(AX, AY, 0, AHeight, drawRect) then
    exit;
  AY := EnsureRange(AY, drawRect.Y, drawRect.Bottom);
  AHeight := MinLong(drawRect.Height, AHeight);
  if AHeight <= 0 then
    exit;
  screen := GetDrawPointer(AX, AY, offset);
  color := ForeColor;
  if State.BufferMode then
    screenWidth := State.ViewPort.Width
  else
    screenWidth := Mode^.BytesPerScanLine;
  asm
    mov ax, screenWidth
    mov cx, AHeight
    mov bl, color
    les di, screen
    @loop:
      mov [es:di], bl
      add di, ax
    loop @loop
  end;
end;

procedure TFastVgaDriver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TFastVgaDriver.DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TFastVgaDriver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TFastVgaDriver.DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TFastVgaDriver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
begin
end;

procedure TFastVgaDriver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
begin
end;

destructor TFastVgaDriver.Free;
begin
  inherited Free;
end;

end.