{$I COMPILER.INC}
unit Vga8Drv;

interface

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  AplTypes,
  AplObj,
  Common,
  StrUtils,
  Streams,
  Drawing,
  MouseDrv,
  GraphDrv,
  Palettes,
  GrDrv8;

type
  PVga8Driver = ^TVga8Driver;

  TVga8Driver = object(TGraphics8Driver)
  private
  public
    function GetScreenPointer(AX, AY: integer; var AOffset: longint): PByte; virtual;
    procedure GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
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

function TVga8Driver.GetScreenPointer(AX, AY: integer; var AOffset: longint): PByte;
var
  result: PByte;
begin
  AOffset := longint(AY) * Mode^.BytesPerScanLine + AX;
  result := Mode^.FrameBuffer;
  Inc(result, AOffset);
  GetScreenPointer := result;
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
  Mouse.XShift := 1;
end;

procedure TVga8Driver.RenderText(AX, AY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  charIndex, yIndex: integer;
  count: word;
  ch: char;
  sx, sy: integer;
  minX, maxX: byte;
  width: integer;
  linePtr: PWord;
  height: integer;
  screen: PByte;
  fore: byte;
  offset: longint;
  currentLine: word;
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
  {asm
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
  end;}
  while true do begin
    if State.ViewPort.IntersectsCoords(AX1, AY1) then begin
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
  end;
end;

procedure TVga8Driver.HLine(AX, AY, AWidth: integer);
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
  if (AY < drawRect.Y) or (AY > drawRect.Bottom) then
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

procedure TVga8Driver.VLine(AX, AY, AHeight: integer);
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
  if (AX < drawRect.X) or (AX > drawRect.Right) then
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

procedure TVga8Driver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: longint;
  sy: word;
  lineWidth: word;
begin
  if HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetDrawPointer(drawRect.X, sy, offset);
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
    Inc(sy);
  end;
end;

procedure TVga8Driver.DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: integer;
  sy: longint;
  offset: longint;
  screen, image: PByte;
  width: word;
begin
  if HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
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

procedure TVga8Driver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  offset: longint;
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
    screen := GetDrawPointer(drawRect.X, sy, offset);
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
  offset: longint;
  imageLine: PByte;
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

procedure TVga8Driver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: longint;
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

procedure TVga8Driver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  offset: longint;
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
    screen := GetDrawPointer(drawRect.X, sy, offset);
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