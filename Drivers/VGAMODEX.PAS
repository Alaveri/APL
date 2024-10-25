{$I COMPILER.INC}
unit VgaModeX;

interface

uses
  AplTypes,
  AplObj,
  GraphDrv,
  GrDrv8,
  Math,
  Common,
  VgaConst,
  Streams,
  Drawing;

type
  PVgaModeXDriver = ^TVgaModeXDriver;
  PVgaModeXMode = ^TVgaModeXMode;
  PVgaModeXState = ^TVgaModeXState;

  TVgaModeXMode = object(TGraphicsMode)
  private
    FPages: array[0..3] of word;
  public
    CurrentPage: byte;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TVgaModeXState = object(TGraphicsState)
  private
  public
    CurrentPage: byte;
    PageStart: word;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TVgaModeXDriver = object(TGraphics8Driver)
  private
    function InitializeDrawRect(APX, APY, AWidth, AHeight: integer; var ADrawRect: TRect): boolean;
    procedure Render4BppText(APX, APY, ALength: integer; AText: PChar);
  public
    function GetScreenPointer(APX, APY: integer; var AOffset: longint): PByte; virtual;
    function GetPixel(APX, APY: integer): byte; virtual;
    procedure GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure RenderText(APX, APY, ALength: integer; AText: PChar); virtual;
    procedure Line(AX1, AY1, AX2, AY2: integer); virtual;
    procedure HLine(APX, APY, AWidth: integer); virtual;
    procedure VLine(APX, APY, AHeight: integer); virtual;
    procedure Circle(ACenterX, ACenterY, ARadius: integer); virtual;
    procedure SetPixel(APX, APY: integer); virtual;
    procedure DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure FastFillScreen(AColor: byte); virtual;
    procedure FastDrawScreen(AImage: PByte); virtual;
    procedure FastDrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure FastGetImage(APX, APY, AWidth, AHeight: integer; ABuffer: PByte); virtual;
    procedure FastSetPixel(APX, APY: integer); virtual;
    procedure SetCurrentPage(APage: byte);
    procedure WaitForVSync; virtual;
    procedure PageFlip(var APage1, APage2: word); virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  MouseDrv,
  Errors,
  Palettes,
  StrUtils;

procedure TVgaModeXDriver.Init;
var
  newMode: PVgaModeXMode;
  desc: string;
  index: integer;
  size: word;
begin
  inherited Init;
  newMode := New(PVgaModeXMode, Create);
  FreeAndNil(State);
  State := New(PVgaModeXState, Create);
  with newMode^ do begin
    ModeId := $01;
    desc := 'VGA Mode X'
      + IntToStr(320)
      + 'x'
      + IntToStr(240)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 320;
    Height := 240;
    MaxX := 319;
    MaxY := 239;
    Bpp := 8;
    NumPages := 3;
    BytesPerScanLine := 320;
    HelpText := TString.New('Requires a VGA card.');
    FrameBuffer := Ptr($A000, $0000);
  end;

  with newMode^ do begin
    ModeId := $02;
    desc := 'VGA Mode Y'
      + IntToStr(320)
      + 'x'
      + IntToStr(200)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 320;
    Height := 200;
    MaxX := 319;
    MaxY := 200;
    Bpp := 8;
    NumPages := 4;
    BytesPerScanLine := 320;
    HelpText := TString.New('Requires a VGA card.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  for index := 0 to newMode^.NumPages - 1 do
    newMode^.FPages[index] :=
      word(newMode^.Width) * newMode^.Height div newMode^.NumPages * index;
  Modes.Add(newMode);
end;

procedure TVgaModeXDriver.SetMode(AMode: PGraphicsMode);
var
  ptr: PBufferArray;
  crtcAddress: word;
begin
  inherited SetMode(AMode);
  asm
    mov ah, 0
    mov al, 13h
    int 10h
  end;

  PortW[VgaScIndex] := VgaChain4Disable + VgaMemoryMode;
  PortW[VgaCrtcIndex] := VgaWordDisable + VgaModeControl;
  PortW[VgaCrtcIndex] := VgaDwordModeDisable;

  if Mode^.NumPages = 3 then begin
    PortW[VgaMiscOutput] := VgaVSyncPolarity;
    PortW[VgaCrtcIndex]:=$2C11; { Turn off write protect }
    PortW[VgaCrtcIndex]:=$0D06; { Vertical total }
    PortW[VgaCrtcIndex]:=$3E07; { Overflow register }
    PortW[VgaCrtcIndex]:=$EA10; { Vertical retrace start }
    PortW[VgaCrtcIndex]:=$AC11; { Vertical retrace and write protect end }
    PortW[VgaCrtcIndex]:=$DF12; { Vertical display enable end }
    PortW[VgaCrtcIndex]:=$E715; { Start vertical blanking }
    PortW[VgaCrtcIndex]:=$0616; { End Vertical blanking  }
  end;

  PortW[VgaScIndex] := VgaAllPlanes + VgaMapMask;

  ptr := Mode^.FrameBuffer;
  FillCharLarge(ptr^, $10000, 0);
  State^.FrameBuffer := Mode^.FrameBuffer;
  SetStandardPalette;
  Mouse.XShift := 1;
end;

procedure TVgaModeXDriver.SetCurrentPage(APage: byte);
begin
  if APage = PVgaModeXState(State)^.CurrentPage then
    exit;
  PVgaModeXState(State)^.CurrentPage := APage;
  PVgaModeXState(State)^.PageStart := PVgaModeXMode(Mode)^.FPages[APage];
  Port[VgaCrtcIndex] := $0C;
  { Start Memory Video address High of upper left corner of screen }
  Port[VgaCrtcData] := PVgaModeXState(State)^.PageStart shr 8;
  Port[VgaCrtcIndex] := $0D;
  { Start Memory Video address Low of upper left corner of screen }
  Port[VgaCrtcIndex] := PVgaModeXState(State)^.PageStart and $FF;
end;

function TVgaModeXDriver.GetScreenPointer(APX, APY: integer; var AOffset: longint): PByte;
var
  result: PByte;
begin
  AOffset := PVgaModeXState(State)^.CurrentPage + (APY * Mode^.BytesPerScanLine) shr 2 + APX shr 2;
  result := Mode^.FrameBuffer;
  Inc(result, AOffset);
  GetScreenPointer := result;
end;

procedure TVgaModeXDriver.PageFlip(var APage1, APage2: word);
var
  currentMode: PVgaModeXMode;
  highAddress, lowAddress: word;
begin
  currentMode := PVgaModeXMode(Mode);
  SwapWord(APage1, APage2);
  highAddress := VgaHighAddress or (APage1 and $FF00);
  lowAddress := VgaLowAddress or (APage1 shl 8);
  while port[VgaInputStatus] and VgaDisplayEnable <> 0 do;
  port[VgaCrtcIndex] := highAddress;
  port[VgaCrtcIndex] := lowAddress;
  while not (port[VgaInputStatus] and VgaRetrace <> 0) do;
end;

procedure TVgaModeXDriver.WaitForVSync;
begin
  asm
    mov dx, 3DAh
    @loop:
    in al, dx
    test al, 8h
    jz @loop
  end;
end;

function TVgaModeXDriver.GetPixel(APX, APY: integer): byte;
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  GetPixel := 0;
  Mode^.Bounds.GetIntersection(State^.ViewPort, drawRect);
  if not drawRect.Contains(APX, APY) then
    exit;
  ptr := GetDrawPointer(APX, APY, offset);
  GetPixel := ptr^;
end;

procedure TVgaModeXDriver.SetPixel(APX, APY: integer);
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  Mode^.Bounds.GetIntersection(State^.ViewPort, drawRect);
  if not drawRect.Contains(APX, APY) then
    exit;
  ptr := GetDrawPointer(APX, APY, offset);
  ptr^ := ForeColor;
end;

procedure TVgaModeXDriver.FastFillScreen(AColor: byte);
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

procedure TVgaModeXDriver.FastDrawScreen(AImage: PByte);
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

procedure TVgaModeXDriver.FastDrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte);
var
  screen: PByte;
  off: longint;
  wordOffset: word;
begin
  screen := GetScreenPointer(APX, APY, off);
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

procedure TVgaModeXDriver.FastGetImage(APX, APY, AWidth, AHeight: integer; ABuffer: PByte);
var
  screen: PByte;
  off: longint;
  wordOffset: word;
begin
  screen := GetScreenPointer(APX, APY, off);
  wordOffset := off;
  asm
    push ds
    lds di, ABuffer
    les si, screen
    add di, wordOffset
    mov cx, AHeight
    @loop:
      push cx
      mov cx, AWidth
      rep movsb
      pop cx
      mov dx, 320
      sub dx, cx
      add si, dx
    loop @loop
    pop ds
  end;
end;

procedure TVgaModeXDriver.FastSetPixel(APX, APY: integer);
var
  ptr: PByte;
  offset: longint;
  drawRect: TRect;
begin
  Mode^.Bounds.GetIntersection(State^.ViewPort, drawRect);
  if not drawRect.Contains(APX, APY) then
    exit;
  ptr := GetDrawPointer(APX, APY, offset);
  ptr^ := ForeColor;
end;

function TVgaModeXDriver.InitializeDrawRect(APX, APY, AWidth, AHeight: integer; var ADrawRect: TRect): boolean;
var
  visibleRect: TRect;
begin
  InitializeDrawRect := false;
  if HasException then
    exit;
  Mode^.Bounds.GetIntersection(State^.ViewPort, visibleRect);
  ADrawRect.CreateDims(APX, APY, AWidth, AHeight);
  ADrawRect.Intersect(visibleRect);
  if not ADrawRect.IsEmpty then
    InitializeDrawRect := true;
end;

procedure TVgaModeXDriver.Render4BppText(APX, APY, ALength: integer; AText: PChar);
begin
end;

procedure TVgaModeXDriver.RenderText(APX, APY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  charIndex, yIndex: integer;
  ch: char;
  sx, sy: integer;
  minX, maxX: byte;
  width: integer;
  linePtr: PWord;
  height: integer;
  screen: PByte;
  fore: byte;
  offset: longint;
  format: TFontFormats;
  count: word;
  currentLine: word;
begin
  if HasException then
    exit;
  GetDrawRect(drawRect);
  height := State^.Font^.Height;
  if (APX > drawRect.Right) or (APY > drawRect.Bottom) or (APY + height < drawRect.Y) then
    exit;
  GetFontFormats(State^.Font, format);
  if ff4Bpp in format then begin
    Render4BppText(APX, APY, ALength, AText);
    exit;
  end;
  sx := APX;
  for charIndex := 0 to ALength - 1 do begin
    ch := AText[charIndex];
    width := State^.Font^.TextWidth(ch);
    if sx > drawRect.Right then
      exit;
    if sx + width < drawRect.X then begin
      Inc(sx, width);
      continue;
    end;
    sy := APY;
    fore := State^.ForeColor;
    linePtr := State^.Font^.FontData;
    Inc(linePtr, Ord(ch) * height);
    minX := Max(0, drawRect.X - sx);
    maxX := Min(State^.Font^.TextWidth(ch) - 1, drawRect.Right - sx);
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
        push ds
        les di, screen { Load screen pointer into ES:DI }
        mov cx, count { Load count into CX as the loop counter }
        mov dl, minX { Load starting x index into DL }
        mov dh, fore { Load foreground color into DH }
        mov ax, currentLine { Load current character line into AX }
        @loop:
          xchg si, cx { Move the loop counter into si }
          mov cl, dl { Load x index into CL }
          mov bx, 8000h { Load 32768 into BX }
          shr bx, cl { Shift 32768 right by x index to get the mask }
          push ax { Save the character line }
          and ax, bx { Check if the character pixel is set }
          jz @next { If the pixel is not set, skip to the next pixel }
          mov [es:di], dh { Set the screen pixel to the ForeColor }
          @next:
          pop ax { Restore the character line }
          xchg si, cx
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

procedure TVgaModeXDriver.Line(AX1, AY1, AX2, AY2: integer);
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

procedure TVgaModeXDriver.HLine(APX, APY, AWidth: integer);
var
  screen: PByte;
  lineWidth: integer;
  offset: longint;
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

  screen := GetDrawPointer(APX, APY, offset);
  color := byte(State^.ForeColor);
  asm
    mov cx, AWidth
    mov al, color
    les di, screen
    rep stosb
  end;
end;

procedure TVgaModeXDriver.VLine(APX, APY, AHeight: integer);
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
  GetDrawRect(drawRect);
  if not drawRect.ContainsX(APX) then
    exit;
  APY := drawRect.ClampY(APY);
  AHeight := MinL(drawRect.Height, AHeight);
  if AHeight <= 0 then
    exit;

  screen := GetDrawPointer(APX, APY, offset);
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

procedure TVgaModeXDriver.Circle(ACenterX, ACenterY, ARadius: integer);
var
  t1, t2: integer;
  x, y: integer;
  color: byte;
begin
  t1 := ARadius div 16;
  x := ARadius;
  y := 0;
  color := State^.ForeColor;
  repeat
    FastSetPixel(ACenterX + x, ACenterY + y);
    FastSetPixel(ACenterX - x, ACenterY + y);
    FastSetPixel(ACenterX + x, ACenterY - y);
    FastSetPixel(ACenterX - x, ACenterY - y);
    FastSetPixel(ACenterX + y, ACenterY + x);
    FastSetPixel(ACenterX - y, ACenterY + x);
    FastSetPixel(ACenterX + y, ACenterY - x);
    FastSetPixel(ACenterX - y, ACenterY - x);
    Inc(y);
    t1 := t1 + y;
    t2 := t1 - x;
    if t2 >= 0 then begin
      t1 := t2;
      Dec(x);
    end;
  until x < y;
end;

procedure TVgaModeXDriver.DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: word;
  screen, image: PByte;
  offset: longint;
  sy: word;
begin
  if HasException then
    exit;
  GetImageDrawRects(APX, APY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetDrawPointer(drawRect.X, sy, offset);
    image := AImage;
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    asm
      push ds
      lds si, image
      les di, screen
      mov cx, drawRect.Width
      rep movsb
      pop ds
    end;
    Inc(sy);
  end;
end;

procedure TVgaModeXDriver.DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: word;
  sy: longint;
  offset: longint;
  screen, image: PByte;
  width: word;
begin
  if HasException then
    exit;
  GetImageDrawRects(APX, APY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  width := drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetDrawPointer(drawRect.X, sy, offset);
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
  end;
end;

procedure TVgaModeXDriver.DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: word;
  screen: PByte;
  offset: longint;
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
    screen := GetDrawPointer(drawRect.X, sy, offset);
    AStream^.Seek((yIndex + imageRect.Y) * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Read(screen, lineWidth);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
end;

procedure TVgaModeXDriver.DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: word;
  screen: PByte;
  offset: longint;
  imageLine: PByte;
  streamStart: longint;
  sy: integer;
  lineWidth: integer;
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
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetDrawPointer(drawRect.X, drawRect.Y + yIndex, offset);
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
  FreeMem(imageLine, lineWidth);
end;

procedure TVgaModeXDriver.GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: word;
  screen, image: PByte;
  offset: longint;
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
    screen := GetDrawPointer(drawRect.X, sy, offset);
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

procedure TVgaModeXDriver.GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: word;
  screen: PByte;
  offset: longint;
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
    screen := GetDrawPointer(drawRect.X, sy, offset);
    AStream^.Seek((yIndex + imageRect.Y) * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Write(screen, lineWidth);
    Inc(sy);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
end;

procedure TVgaModeXDriver.PushState;
var
  newState: PVgaModeXState;
begin
  newState := New(PVgaModeXState, Create);
  newState^.Assign(State^);
  StateStack.Push(newState);
end;

procedure TVgaModeXDriver.PopState;
var
  oldState: PVgaModeXState;
begin
  oldState := PVgaModeXState(StateStack.Pop);
  if not Assigned(oldState) then
    exit;
  State^.Assign(oldState^);
  FreeAndNil(oldState);
end;

destructor TVgaModeXDriver.Free;
begin
  inherited Free;
end;

procedure TVgaModeXMode.Init;
begin
  inherited Init;
  FillChar(FPages, SizeOf(FPages), 0);
end;

procedure TVgaModeXMode.Assign(var ASource: TObject);
var
  source: PVgaModeXMode;
begin
  inherited Assign(ASource);
  source := PVgaModeXMode(@ASource);
  FPages := source^.FPages;
end;

procedure TVgaModeXState.Init;
begin
  inherited Init;
  CurrentPage := 0;
  PageStart := 0;
end;

procedure TVgaModeXState.Assign(var ASource: TObject);
var
  source: PVgaModeXState;
begin
  inherited Assign(ASource);
  source := PVgaModeXState(@ASource);
  CurrentPage := source^.CurrentPage;
  PageStart := source^.PageStart;
end;

end.