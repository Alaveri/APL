{$I COMPILER.INC}
unit SVga8Drv;

interface

uses
  AplTypes,
  AplConst,
  AplObj,
  Drawing,
  AplUtils,
  AplStr,
  AplMath,
  Streams,
  Graphics,
  Gr8Drv,
  MemDrv,
  Palettes,
  VbeTypes,
  Strings;

type
  PSVga8Mode = ^TSvga8Mode;

  TSvga8Mode = object(TGraphicsMode)
  private
    FAttributes: TVbeModeAttributes;
    FWinSize: word;
    FWinFunc: pointer;
    FGranularity: word;
  public
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  PSVga8Driver = ^TSVga8Driver;
  TSVga8Driver = object(TGraphics8Driver)
  private
    FSVga8Driver: integer;
    FCurrentBank: integer;
    FWinSize: word;
    FWinFunc: pointer;
    FBankShift: word;
    FScreenOffset: longint;
    procedure SetBank(ABank: word);
    procedure FillPattern(ARect: TRect);
    procedure HLinePattern(AWidth: integer; AScreen: PByte; APattern: word;
      var APX: integer);
    procedure VLinePattern(AHeight: integer; APattern: word; APX, APY: integer);
  public
    function SupportsRegions: boolean; virtual;
    function GetScreenPointer(APX, APY: integer): PByte; virtual;
    procedure GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure RenderText(APX, APY, ALength: integer; AText: PChar); virtual;
    procedure Line(AX1, AY1, AX2, AY2: integer); virtual;
    procedure HLine(APX, APY, AWidth: integer); virtual;
    procedure VLine(ApX, APY, AHeight: integer); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure InverseHLine(APX, APY, AWidth: integer); virtual;
    procedure InverseVLine(APX, APY, AHeight: integer); virtual;
    procedure DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  MouseDrv;

procedure TSVga8Mode.Init;
begin
  inherited Init;
  FWinSize := 0;
  FAttributes := [];
  FWinFunc := nil;
  FGranularity := 0;
end;

function TSVga8Driver.SupportsRegions: boolean;
begin
  SupportsRegions := true;
end;

procedure TSVga8Mode.Assign(var ASource: TObject);
var
  mode: PSVga8Mode;
begin
  inherited Assign(ASource);
  mode := PSVga8Mode(@ASource);
  FAttributes := mode^.FAttributes;
  FWinSize := mode^.FWinSize;
  FWinFunc := mode^.FWinFunc;
  FGranularity := 0;
end;

procedure TSVga8Driver.Init;
var
  newMode: PSVga8Mode;
  oldMode: byte;
  vbeInfo: TVbeInfo;
  supported, callStatus: byte;
  modePtr: PWord;
  vbeModeIndex: word;
  colors: string;
  vbeMode: TVbeMode;
  recordPtr: pointer;
  desc: string;
begin
  inherited Init;
  FCurrentBank := -1;
  recordPtr := @vbeInfo;
  FWinSize := 0;
  FBankShift := 0;
  asm
    mov ax, 4F00h
    les di, recordPtr
    int 10h
    mov [supported], al
    mov [callStatus], ah
  end;
  if (supported <> $4F) or (callStatus <> 0) then begin
    Raise(ecGraphicsNotSupported);
    exit;
  end;

  modePtr := vbeInfo.VideoModePtr;
  while modePtr^ <> $FFFF do begin
    vbeModeIndex := modePtr^;
    if vbeModeIndex < $100 then begin
      Inc(modePtr);
      continue;
    end;
    recordPtr := @vbeMode;
    asm
      mov ax, 4F01h
      les di, recordPtr
      mov cx, [vbeModeIndex]
      int 10h
    end;
    if (vbeMode.v1.Bpp <> 8)
      or (not vbeMode.v1.MemoryModel = mmPackedPixel)
      or (not (vbeSupportedInHardware in vbeMode.v1.ModeAttributes))
      or (vbeIsNotVgaCompatible in vbeMode.v1.ModeAttributes)
      or (not (vbeIsColor in vbeMode.v1.ModeAttributes))
      or (not (vbeIsGraphics in vbeMode.v1.ModeAttributes)) then begin
      Inc(modePtr);
      continue;
    end;
    newMode := New(PSVga8Mode, Create);
    with newMode^ do begin
      ModeId := vbeModeIndex;
      case vbeMode.v1.Bpp of
          4: colors := '16';
          8: colors := '256';
          15: colors := '32k';
          16: colors := '64k';
          32: colors := '16m';
      end;
      desc := 'SVGA '
        + IntToStr(vbeMode.v1.XResolution)
        + 'x'
        + IntToStr(vbeMode.v1.YResolution)
        + ' '
        + colors
        + ' Color';
      Description := TString.New(desc);
      ModeIndex := vbeModeIndex;
      Width := vbeMode.v1.XResolution;
      Height := vbeMode.v1.YResolution;
      MaxX := vbeMode.v1.XResolution - 1;
      MaxY := vbeMode.v1.YResolution - 1;
      Bpp := vbeMode.v1.Bpp;
      BytesPerScanLine := vbeMode.v1.BytesPerScanLine;
      FAttributes := vbeMode.v1.ModeAttributes;
      FWinSize := vbeMode.v1.WinSize;
      FWinFunc := vbeMode.v1.WinFuncPtr;
      HelpText := TString.New('Requires Super VGA card supporting VBE extensions.');
      FrameBuffer := Ptr(vbeMode.v1.WinSegmentA, 0);
      FGranularity := vbeMode.v1.WinGranularity;
    end;
    Inc(modePtr);
    Modes.Add(newMode);
  end;
end;

function TSVga8Driver.GetScreenPointer(APX, APY: integer): PByte;
var
  bank: integer;
  screen: PByte;
begin
  if State^.BufferMode then begin
    screen := State^.FrameBuffer;
    FScreenOffset := longint(APY) * State^.Bounds.Width + APX;
    Inc(screen, FScreenOffset);
    GetScreenPointer := screen;
    exit;
  end;
  FScreenOffset := APY * Mode^.BytesPerScanLine + APX;
  screen := State^.FrameBuffer;
  bank := FScreenOffset shr 16;
  FScreenOffset := FScreenOffset and FWinSize;
  Inc(screen, FScreenOffset);
  if bank <> FCurrentBank then
    SetBank(bank);
  GetScreenPointer := screen;
end;

procedure TSVga8Driver.SetMode(AMode: PGraphicsMode);
var
  selectedMode: word;
  svgaMode: PSVga8Mode;
begin
  inherited SetMode(AMode);
  svgaMode := PSVga8Mode(AMode);
  selectedMode := AMode^.ModeIndex;
  asm
    mov   ax, 4F02h
    mov   bx, [selectedMode]
    int   10h
  end;
  Mouse.SetMouseResolution(AMode^.Width - 1, AMode^.Height - 1);
  if HasException then
    exit;
  State^.FrameBuffer := AMode^.FrameBuffer;
  State^.Bpp := AMode^.Bpp;
  SetVgaPalette;
  FWinSize := longint(SVgaMode^.FWinSize) * 1024 - 1;
  FWinFunc := SVgaMode^.FWinFunc;
  FCurrentBank := -1;
  FBankShift := 0;
  while (64 shr FBankShift <> SVgaMode^.FGranularity) do
    Inc(FBankShift);
end;

procedure TSVga8Driver.SetBank(ABank: word);
var
  winFunc: pointer;
begin
  if ABank = FCurrentBank then
    exit;
  FCurrentBank := ABank;
  ABank := ABank shl FBankShift;
  winFunc := FWinFunc;
  asm
    mov bx, 0
    mov dx, [ABank]
    call winFunc
    mov bx, 1
    mov dx, [ABank]
    call winFunc
  end;
end;

procedure TSVga8Driver.RenderText(APX, APY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  ch: char;
  maxY, sx, sy, minX, maxX: integer;
  width: integer;
  shift, height: word;
  screen: PByte;
  charIndex, fore: byte;
  highBit: word;
  DrawFunc: procedure;

  procedure DrawCharLineB;
  var
    currentLine: byte;
    linePtr: PByte;
    xIndex: integer;
  begin
    linePtr := PByte(State^.Font^.FontData);
    Inc(linePtr, Ord(ch) * height + (sy - APY));
    currentLine := linePtr^;
    Inc(linePtr);
    shift := $80 shr minX;
    for xIndex := minX to maxX do begin
      if currentLine and shift > 0 then
        screen^ := fore;
      Inc(screen);
      Inc(FScreenOffset);
      shift := shift shr 1;
      if FScreenOffset > FWinSize then
        screen := GetScreenPointer(sx + xIndex + 1, sy);
    end;
    Inc(sy);
  end;

  procedure DrawCharLineW;
  var
    currentLine: word;
    linePtr: PWord;
    xIndex: integer;
  begin
    linePtr := State^.Font^.FontData;
    Inc(linePtr, Ord(ch) * height + (sy - APY));
    currentLine := linePtr^;
    Inc(linePtr);
    shift := $8000 shr minX;
    for xIndex := minX to maxX do begin
      if currentLine and shift > 0 then
        screen^ := fore;
      Inc(screen);
      Inc(FScreenOffset);
      shift := shift shr 1;
      if FScreenOffset > FWinSize then
        screen := GetScreenPointer(sx + xIndex + 1, sy);
    end;
    Inc(sy);
  end;

  procedure DrawCharLine;
  begin
    if State^.Font^.BytesPerCharacter = 1 then
      DrawCharLineB
    else
      DrawCharLineW;
  end;

begin
  if HasException then
    exit;
  State^.Bounds.GetIntersection(State^.ViewPort, drawRect);
  drawRect.Intersect(Mode^.Bounds);
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
    minX := Max(0, drawRect.X - sx);
    maxX := Min(width - 1, drawRect.Right - sx);
    sy := Max(drawRect.Y, APY);
    while sy <= maxY do begin
      screen := GetScreenPointer(sx + minX, sy);
      DrawCharLine;
    end;
    Inc(sx, width);
  end;
end;

procedure TSVga8Driver.Line(AX1, AY1, AX2, AY2: integer);
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

  while true do begin
    if State^.ViewPort.Contains(AX1, AY1) then begin
      screenPtr := GetScreenPointer(AX1, AY1);
      screenPtr^ := color;
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

procedure TSVga8Driver.FillPattern(ARect: TRect);
var
  screen: PByte;
  px, py, sy, width, partialWidth, index: integer;
begin
  width := ARect.Width;
  for index := 0 to ARect.Height - 1 do begin
    sy := ARect.Y + index;
    screen := GetScreenPointer(ARect.X, sy);
    px := ARect.X mod 16;
    py := sy mod 16;
    if width + FScreenOffset > FWinSize then begin
      partialWidth := FWinSize - FScreenOffset + 1;
      HLinePattern(partialWidth, screen, State^.FillPattern^[py], px);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      HLinePattern(width - partialWidth, screen, State^.FillPattern^[py], px);
    end
    else
      HLinePattern(width, screen, State^.FillPattern^[py], px);
  end;
end;

procedure TSVga8Driver.FillRect(ARect: TRect);
var
  screen: PByte;
  drawRect: TRect;
  width, partialWidth, index: integer;
  color: byte;
begin
  if HasException then
    exit;
  State^.Bounds.GetIntersection(State^.ViewPort, drawRect);
  drawRect.Intersect(Mode^.Bounds);
  if drawRect.IsEmpty then
    exit;
  if not drawRect.IntersectsRect(ARect) then
    exit;
  ARect.Intersect(drawRect);
  color := byte(State^.BackColor);
  width := ARect.Width;
  if Assigned(State^.FillPattern) then begin
    FillPattern(ARect);
    exit;
  end;
  for index := 0 to ARect.Height - 1 do begin
    screen := GetScreenPointer(ARect.X, ARect.Y + index);
    if width + FScreenOffset > FWinSize then begin
      partialWidth := FWinSize - FScreenOffset + 1;
      FillChar(screen^, partialWidth, color);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      FillChar(screen^, width - partialWidth, color);
    end
    else
      FillChar(screen^, width, color);
  end;
end;

procedure TSVga8Driver.HLinePattern(AWidth: integer; AScreen: PByte; APattern: word;
  var APX: integer);
var
  patternIndex: integer;
  fore, back: byte;
begin
  fore := State^.ForeColor;
  back := State^.BackColor;
  for patternIndex := 0 to AWidth - 1 do begin
    if APattern and (1 shl APX) > 0 then
      AScreen^ := fore
    else
      AScreen^ := back;
    Inc(AScreen);
    Inc(APX);
    APX := APX mod 16;
  end;
end;

procedure TSVga8Driver.VLinePattern(AHeight: integer; APattern: word; APX, APY: integer);
var
  patternIndex: integer;
  fore, back: byte;
  screen: PByte;
  py: integer;
begin
  fore := State^.ForeColor;
  back := State^.BackColor;
  screen := GetScreenPointer(APX, APY);
  for patternIndex := 0 to AHeight - 1 do begin
    py := APY mod 16;
    if APattern and (1 shl py) > 0 then
      screen^ := fore
    else
      screen^ := back;
    Inc(screen, Mode^.Width);
    Inc(FScreenOffset, Mode^.Width);
    Inc(APY);
    if FScreenOffset > FWinSize then begin
      screen := GetScreenPointer(APX, APY);
      Inc(FScreenOffset, Mode^.Width);
    end;
  end;
end;

procedure TSVga8Driver.HLine(APX, APY, AWidth: integer);
var
  screen: PByte;
  partialWidth, lineWidth: integer;
  color: byte;
  drawRect: TRect;
  px: integer;
begin
  GetDrawRect(drawRect);
  if HasException or (APY < drawRect.Y) or (APY > drawRect.Bottom) then
    exit;
  if APX < drawRect.X then begin
    AWidth := AWidth - (drawRect.X - APX);
    APX := drawRect.X;
  end;
  if APX + AWidth - 1 > drawRect.Right then begin
    AWidth := drawRect.Right - APX + 1;
    if AWidth <= 0 then
      exit;
  end;
  if AWidth <= 0 then
    exit;
  screen := GetScreenPointer(APX, APY);
  if Assigned(State^.LinePattern) then begin
    px := APX mod 16;
    HLinePattern(AWidth, screen, State^.LinePattern^, px);
    exit;
  end;
  color := byte(State^.ForeColor);
  if AWidth + FScreenOffset > FWinSize then begin
    partialWidth := FWinSize - FScreenOffset + 1;
    asm
      les di, screen
      mov cx, partialWidth
      mov al, color
      rep stosb
     end;
    SetBank(FCurrentBank + 1);
    screen := Mode^.FrameBuffer;
    Dec(AWidth, partialWidth);
    asm
      les di, screen
      mov cx, AWidth
      mov al, color
      rep stosb
    end;
  end
  else
    FillChar(screen^, AWidth, color);
end;

procedure TSVga8Driver.VLine(APX, APY, AHeight: integer);
var
  index: integer;
  screen: PByte;
  drawRect: TRect;
begin
  if HasException then
    exit;
  GetDrawRect(drawRect);
  if (APX < drawRect.X) or (APX > drawRect.Right) then
    exit;
  APY := Clamp(APY, drawRect.Y, drawRect.Bottom);
  if APY + AHeight - 1 > drawRect.Bottom then
    AHeight := drawRect.Bottom - APY + 1;
  if AHeight <= 0 then
    exit;
  if Assigned(State^.LinePattern) then begin
    screen := GetScreenPointer(APX, APY);
    VLinePattern(AHeight, State^.LinePattern^, APX, APY);
    exit;
  end;
  for index := APY to APY + AHeight - 1 do begin
    screen := GetScreenPointer(APX, index);
    screen^ := ForeColor;
  end;
end;

procedure TSVga8Driver.InverseHLine(APX, APY, AWidth: integer);
var
  drawRect: TRect;
  index: integer;
  screen: PByte;
begin
  GetDrawRect(drawRect);
  if HasException or (APY < drawRect.Y) or (APY > drawRect.Bottom) then
    exit;
  if APX < drawRect.X then begin
    AWidth := AWidth - (drawRect.X - APX);
    APX := drawRect.X;
  end;
  if APX + AWidth - 1 > drawRect.Right then begin
    AWidth := drawRect.Right - APX + 1;
    if AWidth <= 0 then
      exit;
  end;
  if AWidth <= 0 then
    exit;
  screen := GetScreenPointer(APX, APY);
  if State^.BufferMode then begin
    for index := 0 to AWidth - 1 do begin
      screen^ := screen^ xor 15;
      Inc(screen);
    end;
    exit;
  end;
  for index := 0 to AWidth - 1 do begin
    if FScreenOffset > FWinSize then begin
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      FScreenOffset := 0;
    end;
    screen^ := screen^ xor 15;
    Inc(FScreenOffset);
    Inc(screen);
  end;
end;

procedure TSVga8Driver.InverseVLine(APX, APY, AHeight: integer);
var
  index: integer;
  screen: PByte;
  drawRect: TRect;
begin
  if HasException then
    exit;
  State^.Bounds.GetIntersection(State^.ViewPort, drawRect);
  drawRect.Intersect(Mode^.Bounds);
  if (APX < drawRect.X) or (APX > drawRect.Right) then
    exit;
  APY := Clamp(APY, drawRect.Y, drawRect.Bottom);
  AHeight := MinL(drawRect.Height, AHeight);
  if AHeight <= 0 then
    exit;
  screen := GetScreenPointer(APX, APY);
  for index := APY to APY + AHeight - 1 do begin
    screen := GetScreenPointer(APX, index);
    screen^ := screen^ xor 15;
  end;
end;


procedure TSVga8Driver.DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: longint;
  screen, image: PByte;
  sy: longint;
  lineWidth, partialWidth: integer;
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
    image := AImage;
    Inc(image, (yIndex + imageRect.Y) * AWidth + imageRect.X);
    if FScreenOffset + lineWidth > FWinSize then begin
      partialWidth := FWinSize - FScreenOffset + 1;
      Move(image^, screen^, partialWidth);
      Inc(image, partialWidth);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      Move(image^, screen^, lineWidth - partialWidth);
      Inc(image, lineWidth - partialWidth);
    end
    else begin
      Move(image^, screen^, lineWidth);
      Inc(image, lineWidth);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: integer;
  sy: word;
  screen, image: PByte;
begin
  if HasException then
    exit;
  GetImageDrawRects(APX, APY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPointer(drawRect.X, sy);
    image := AImage;
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    for xIndex := 0 to drawRect.Width - 1 do begin
      if image^ <> TransparentColor then
        screen^ := image^;
      Inc(image);
      Inc(screen);
      Inc(FScreenOffset);
      if FScreenOffset > FWinSize then
        screen := GetScreenPointer(drawRect.X + xIndex + 1, sy);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  sy: word;
  lineWidth, partialWidth: integer;
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
    AStream^.Seek(streamStart + (yIndex + imageRect.Y) * longint(imageRect.Width) + imageRect.X, soFromBeginning);
    if FScreenOffset + lineWidth > FWinSize then begin
      partialWidth := FWinSize - FScreenOffset + 1;
      AStream^.Read(screen, partialWidth);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      AStream^.Read(screen, lineWidth - partialWidth);
    end
    else
      AStream^.Read(screen, lineWidth);
    Inc(sy);
    if AStream^.HasException then
      break;
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
end;

procedure TSVga8Driver.DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: integer;
  screen: PByte;
  imageLine, linePtr: PByte;
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
  AStream^.Seek(streamStart + (yIndex + imageRect.Y) * AWidth + imageRect.X, soFromPosition);
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPointer(drawRect.X, drawRect.Y + yIndex);
    AStream^.Seek(yIndex * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Read(imageLine, lineWidth);
    linePtr := imageLine;
    for xIndex := 0 to lineWidth - 1 do begin
      if linePtr^ <> TransparentColor then
        screen^ := linePtr^;
      Inc(screen);
      Inc(FScreenOffset);
      Inc(linePtr);
      if FScreenOffset > FWinSize then
        screen := GetScreenPointer(drawRect.X + xIndex + 1, sy);
    end;
    Inc(sy);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
  FreeMem(imageLine, lineWidth);
end;

procedure TSVga8Driver.GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  sy: word;
  lineWidth, partialWidth: integer;
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
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    if FScreenOffset + lineWidth > FWinSize then begin
      partialWidth := FWinSize - FScreenOffset + 1;
      Move(screen^, image^, partialWidth);
      Inc(image, partialWidth);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      Move(screen^, image^, lineWidth - partialWidth);
      Inc(image, lineWidth - partialWidth);
    end
    else begin
      Move(screen^, image^, lineWidth);
      Inc(image, lineWidth);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  sy: longint;
  lineWidth, partialWidth: integer;
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
    AStream^.Seek(streamStart + (yIndex + imageRect.Y) * longint(imageRect.Width) + imageRect.X, soFromBeginning);
    if FScreenOffset + lineWidth > FWinSize then begin
      partialWidth := FWinSize - FScreenOffset + 1;
      AStream^.Write(screen, partialWidth);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      AStream^.Write(screen, lineWidth - partialWidth);
    end
    else
      AStream^.Write(screen, lineWidth);
    Inc(sy);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
end;

procedure TSVga8Driver.WaitForVSync;
begin
  asm
    mov dx, 3DAh
    @end:
    in al, dx
    test al, 8h
    jz @end
  end;
end;

destructor TSVga8Driver.Free;
begin
  inherited Free;
end;

begin
end.