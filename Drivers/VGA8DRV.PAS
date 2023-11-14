{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Vga8Drv;

interface

uses
  Objects,
  GraphDrv,
  Graph8,
  Common,
  StrUtils,
  Strings,
  Streams,
  MouseDrv,
  Drawing;

type
  PVga256Driver = ^TVga256Driver;

  TVga256Driver = object(TGraphics256Driver)
  private
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

function TVga256Driver.GetPixel(AX, AY: integer): byte;
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  GetPixel := 0;
  Mode^.Bounds.Intersection(State^.ViewPort, drawRect);
  if not drawRect.IntersectCoords(AX, AY) then
    exit;
  offset := AX + longint(AY) * Mode^.Pitch;
  ptr := State^.FrameBuffer;
  Inc(ptr, offset);
  GetPixel := ptr^;
end;

procedure TVga256Driver.SetMode(AMode: PGraphicsMode);
begin
  inherited SetMode(AMode);
  asm
    mov   ah, 0
    mov   al, 13h
    int   10h
  end;
  State^.FrameBuffer := Mode^.FrameBuffer;
  SetStandardPalette;
  Mouse.XDiv := 1;
end;

procedure TVga256Driver.SetPixel(AX, AY: integer);
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  Mode^.Bounds.Intersection(State^.ViewPort, drawRect);
  if not drawRect.IntersectCoords(AX, AY) then
    exit;
  ptr := State^.FrameBuffer;
  offset := AX + longint(AY) * Mode^.Pitch;
  Inc(ptr, offset);
  ptr^ := State^.ForeColor;
end;

procedure TVga256Driver.RenderText(AX, AY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  charIndex, yIndex, xIndex: integer;
  ch: char;
  sy, sx, minX, maxX: integer;
  linePtr: PByte;
  width, height: integer;
  screen: PByte;
  fore, back: byte;
begin
  Mode^.Bounds.Intersection(State^.ViewPort, drawRect);
  if AX > drawRect.Right then
    exit;
  if AY > drawRect.Bottom then
    exit;
  width := State^.Font^.TextWidth('w');
  height := State^.Font^.Height;
  if AX + width < drawRect.X then
    exit;
  if AY + height < drawRect.Y then
    exit;
  Inc(screen, AY * Mode^.Pitch + AX);
  for charIndex := 0 to ALength - 1 do begin
    ch := AText[charIndex];
    sx := AX + charIndex * width;
    sy := AY;
    fore := State^.ForeColor;
    back := State^.BackColor;
    linePtr := PMonospaceFont(State^.Font)^.FontData;
    Inc(linePtr, Ord(ch) * height);
    maxX := MinL(width - 1, drawRect.Right - sx);
    minX := MaxL(0, drawRect.X - sx);
    if minX > maxX then
      continue;
    Inc(linePtr, minX);
    for yIndex := 0 to height - 1 do begin
      sy := AY + yIndex;
      if sy > drawRect.Bottom then
        break;
      screen := State^.FrameBuffer;
      Inc(screen, sy * longint(Mode^.Pitch) + sx);
      Inc(screen, minX);
      for xIndex := minX to maxX do begin
        if (linePtr^ and (128 shr xIndex)) > 0 then
          screen^ := fore;
        Inc(screen);
      end;
      Inc(linePtr);
    end;
  end;
end;

procedure TVga256Driver.Line(AX1, AY1, AX2, AY2: integer);
var
  aError, aError2, sx, sy, dlx, dly: integer;
  screenPtr: PByte;
  x, y, right, bottom, width: integer;
  color: byte;
  drawRect: TRect;
begin
  Mode^.Bounds.Intersection(State^.ViewPort, drawRect);
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

procedure TVga256Driver.HLine(AX, AY, AWidth: integer);
var
  buffer: PByte;
  bank: word;
  offset: longint;
  drawRect: TRect;
  color: byte;
begin
  Mode^.Bounds.Intersection(State^.ViewPort, drawRect);
  if (AY < drawRect.Y) or (AY > drawRect.Bottom) then
    exit;
  AX := MaxL(MinL(AX, drawRect.Right), drawRect.X);
  AWidth := MinL(drawRect.Right - AX + 1, AWidth);
  if AWidth <= 0 then
    exit;
  offset := longint(AY) * Mode^.Pitch + AX;
  buffer := State^.FrameBuffer;
  color := byte(ForeColor);
  Inc(buffer, offset);
  FillChar(buffer^, AWidth, color);
end;

procedure TVga256Driver.VLine(AX, AY, AHeight: integer);
var
  index: integer;
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  Mode^.Bounds.Intersection(State^.ViewPort, drawRect);
  if (AX < drawRect.X) or (AX > drawRect.Right) then
    exit;
  AY := MaxL(MinL(AY, drawRect.Right), drawRect.Y);
  AHeight := MinL(drawRect.Bottom - AY + 1, AHeight);
  if AHeight <= 0 then
    exit;
  for index := MaxL(AY, 0) to MinL(AY + AHeight - 1, Mode^.MaxY) do begin
    offset := longint(AX) + index * Mode^.Pitch;
    ptr := State^.FrameBuffer;
    Inc(ptr, offset);
    ptr^ := ForeColor;
  end;
end;

procedure TVga256Driver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, viewRect, drawRect: TRect;
  yIndex, imageX, imageY: integer;
  screenPtr, imagePtr: PByte;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  imageX := drawRect.X - AX;
  imageY := drawRect.Y - AY;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screenPtr := State^.FrameBuffer;
    Inc(screenPtr, (yIndex + drawRect.Y) * Mode^.Pitch + drawRect.X);
    imagePtr := AImage;
    Inc(imagePtr, (imageY + yIndex) * AWidth + imageX);
    Move(imagePtr^, screenPtr^, drawRect.Width);
  end;
end;

procedure TVga256Driver.DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, viewRect, drawRect: TRect;
  xIndex, yIndex, imageX, imageY: integer;
  screenPtr, imagePtr: PByte;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  imageX := drawRect.X - AX;
  imageY := drawRect.Y - AY;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screenPtr := State^.FrameBuffer;
    Inc(screenPtr, (yIndex + drawRect.Y) * Mode^.Pitch + drawRect.X);
    imagePtr := AImage;
    Inc(imagePtr, (imageY + yIndex) * AWidth + imageX);
    for xIndex := 0 to drawRect.Width - 1 do begin
      if imagePtr^ <> TransparentColor then
        screenPtr^ := imagePtr^;
      Inc(imagePtr);
      Inc(screenPtr);
    end;
  end;
end;

procedure TVga256Driver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, viewRect, drawRect: TRect;
  yIndex, imageX, imageY: integer;
  screenPtr: PByte;
  streamWidth, width: integer;
  linePtr: PByte;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  imageX := drawRect.X - AX;
  imageY := drawRect.Y - AY;
  AStream^.Seek(imageY * AWidth + imageX, soFromPosition);
  screenPtr := State^.FrameBuffer;
  Inc(screenPtr, drawRect.Y * Mode^.Pitch + drawRect.X);
  streamWidth := AWidth - drawRect.Width;
  width := drawRect.Width;
  GetMem(linePtr, drawRect.Width);
  for yIndex := 0 to drawRect.Height - 1 do begin
    AStream^.Read(linePtr, drawRect.Width);
    asm
      push ds
      lds si, linePtr
      les di, screenPtr
      cld
      mov cx, [width]
      rep movsb
      pop ds
    end;
    Inc(screenPtr, Mode^.Pitch);
    AStream^.Seek(streamWidth, soFromPosition);
    if AStream^.HasException then begin
      Raise(AStream^.Exception^.Code);
      break;
    end;
  end;
  FreeMem(linePtr, drawRect.Width);
end;

procedure TVga256Driver.DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, viewRect, drawRect: TRect;
  yIndex, imageX, imageY: integer;
  screenPtr, linePtr: PByte;
  width: integer;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  imageX := drawRect.X - AX;
  imageY := drawRect.Y - AY;
  GetMem(linePtr, drawRect.Width);
  width := drawRect.Width - 1;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screenPtr := State^.FrameBuffer;
    Inc(screenPtr, (yIndex + drawRect.Y) * Mode^.Pitch + drawRect.X);
    AStream^.Seek((imageY + yIndex) * AWidth + imageX, soFromBeginning);
    if AStream^.HasException then begin
      FreeMem(linePtr, drawRect.Width);
      exit;
    end;
    AStream^.Read(linePtr, drawRect.Width);
    if AStream^.HasException then begin
      FreeMem(linePtr, drawRect.Width);
      exit;
    end;
    asm
      push ds
      mov cx, [width]
      mov al, [TransparentColor]
      les di, linePtr
      lds si, screenPtr
      @lineloop:
        mov dl, [es:di]
        cmp al, dl
        je @transparent
        mov [ds:si], dl
      @transparent:
        inc di
        inc si
      loop @lineloop
      pop ds
    end;
  end;
  FreeMem(linePtr, drawRect.Width);
end;

procedure TVga256Driver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
var
  imageRect, viewRect, drawRect: TRect;
  yIndex: integer;
  screenPtr, imagePtr: PByte;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screenPtr := State^.FrameBuffer;
    Inc(screenPtr, (yIndex + drawRect.Y) * Mode^.Pitch + drawRect.X);
    imagePtr := ABuffer;
    Inc(imagePtr, yIndex * AWidth);
    Move(screenPtr^, imagePtr^, drawRect.Width);
  end;
end;

procedure TVga256Driver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
var
  imageRect, viewRect, drawRect: TRect;
  yIndex: integer;
  screenPtr: PByte;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screenPtr := State^.FrameBuffer;
    Inc(screenPtr, (yIndex + drawRect.Y) * Mode^.Pitch + drawRect.X);
    AStream^.Write(screenPtr, drawRect.Width);
    if AStream^.HasException then
      exit;
  end;
end;

procedure TVga256Driver.Init;
var
  newMode: PGraphicsMode;
  desc: string;
begin
  inherited Init;
  Modes := New(PGraphicsModeList, CreateCapacity(1));
  newMode := New(PGraphicsMode, Create);
  with newMode^ do begin
    Id := NewLargeString('Vga'
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
    Description := NewLargeString(desc);
    Width := 320;
    Height := 200;
    MaxX := 319;
    MaxY := 199;
    Bpp := 8;
    Pitch := 320;
    HelpText := NewLargeString('Requires a VGA card.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  Modes^.Add(newMode);
end;

destructor TVga256Driver.Free;
begin
  inherited Free;
end;

procedure TVga256Driver.WaitForVSync;
begin
  while (Port[$3DA] and $08) = $08 do;
  while (Port[$3DA] and $08) <> $08 do;
end;

end.