{$I COMPILER.INC}
unit SVga8Drv;

interface

uses
  {$IFDEF DOS}
  Strings,
  {$ENDIF}
  AplTypes,
  AplObj,
  Errors,
  Drawing,
  Common,
  StrUtils,
  Streams,
  GraphDrv,
  GrDrv8,
  MemDrv,
  Palettes,
  SVgaType;

type
  PSVga8Mode = ^TSvga8Mode;

  TSvga8Mode = object(TGraphicsMode)
  private
    FAttributes: TVbeModeAttributes;
    FWinSize: word;
    FWinFuncPtr: pointer;
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
    procedure SetBank(ABank: word);
    procedure Render4BppText(AX, AY, ALength: integer; AText: PChar); virtual;
  public
    function SupportsRegions: boolean; virtual;
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
  FWinFuncPtr := nil;
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
  FWinFuncPtr := mode^.FWinFuncPtr;
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
      Id := vbeModeIndex;
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
      FWinFuncPtr := vbeMode.v1.WinFuncPtr;
      HelpText := TString.New('Requires Super VGA card supporting VBE extensions.');
      FrameBuffer := Ptr(vbeMode.v1.WinSegmentA, 0);
      FGranularity := vbeMode.v1.WinGranularity;
    end;
    Inc(modePtr);
    Modes.Add(newMode);
  end;
end;

function TSVga8Driver.GetScreenPointer(AX, AY: integer; var AOffset: longint): PByte;
var
  bank: integer;
  screen: PByte;
begin
  AOffset := AY * Mode^.BytesPerScanLine + AX;
  screen := Mode^.FrameBuffer;
  bank := AOffset shr 16;
  AOffset := AOffset and FWinSize;
  Inc(screen, AOffset);
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
  State.FrameBuffer := AMode^.FrameBuffer;
  SetStandardPalette;
  FWinSize := longint(SVgaMode^.FWinSize) * 1024 - 1;
  FWinFunc := SVgaMode^.FWinFuncPtr;
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
    call [winFunc]

    mov bx, 1
    mov dx, [ABank]
    call [winFunc]
  end;
end;

procedure TSVga8Driver.Render4BppText(AX, AY, ALength: integer; AText: PChar);
var
  sx, sy, minX, maxX: integer;
  height: integer;
  drawRect: TRect;
begin
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  height := State.Font^.Height;
  sx := AX;
end;

procedure TSVga8Driver.RenderText(AX, AY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  charIndex, yIndex, xIndex: integer;
  ch: char;
  sx, sy, minX, maxX: integer;
  width: integer;
  linePtr: PWord;
  height: word;
  screen: PByte;
  fore: byte;
  offset: longint;
  currentLine: word;
  px: integer;
  format: TFontFormats;
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
  GetFontFormats(State.Font, format);
  if ff4Bpp in format then begin
    Render4BppText(AX, AY, ALength, AText);
    exit;
  end;
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
      screen := GetDrawPointer(sx + minX, sy, offset);
      px := AX;
      for xIndex := minX to maxX do begin
        if (currentLine and ($8000 shr xIndex)) > 0 then
          FillLine(screen, px, sy, 1, fore);
        Inc(px);
        Inc(screen);
        Inc(offset);
        if offset > FWinSize then
          screen := GetDrawPointer(sx + xIndex + 1, sy, offset);
      end;
      Inc(linePtr);
      Inc(sy);
    end;
    Inc(sx, width);
  end;
end;

procedure TSVga8Driver.Line(AX1, AY1, AX2, AY2: integer);
begin
end;

procedure TSVga8Driver.HLine(AX, AY, AWidth: integer);
var
  screen: PByte;
  partialWidth, lineWidth: integer;
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
  if AWidth + offset > FWinSize then begin
    partialWidth := FWinSize - offset + 1;
    FillLine(screen, AX, AY, partialWidth, color);
    SetBank(FCurrentBank + 1);
    screen := Mode^.FrameBuffer;
    Dec(AWidth, partialWidth);
    FillLine(screen, AX, AY, AWidth, color);
  end
  else
    FillLine(screen, AX, AY, AWidth, color);
end;

procedure TSVga8Driver.VLine(AX, AY, AHeight: integer);
var
  index: integer;
  offset: longint;
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
    screen := GetDrawPointer(AX, index, offset);
    FillLine(screen, AX, AY, 1, ForeColor);
  end;
end;

procedure TSVga8Driver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: longint;
  sy: longint;
  lineWidth, partialWidth: integer;
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
    if offset + lineWidth > FWinSize then begin
      partialWidth := FWinSize - offset + 1;
      MoveLine(image, screen, drawRect.X, sy, partialWidth);
      Inc(image, partialWidth);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      MoveLine(image, screen, drawRect.X, sy, lineWidth - partialWidth);
      Inc(image, lineWidth - partialWidth);
    end
    else begin
      MoveLine(image, screen, drawRect.X, sy, lineWidth);
      Inc(image, lineWidth);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: integer;
  sy, offset: longint;
  screen, image: PByte;
begin
  if HasException then
    exit;
  GetImageDrawRects(AX, AY, AWidth, AHeight, imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetDrawPointer(drawRect.X, sy, offset);
    image := AImage;
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    for xIndex := 0 to drawRect.Width - 1 do begin
      if image^ <> TransparentColor then
        MoveLine(image, screen, drawRect.X, sy, 1);
      Inc(image);
      Inc(screen);
      Inc(offset);
      if offset > FWinSize then
        screen := GetDrawPointer(drawRect.X + xIndex + 1, sy, offset);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  offset: longint;
  sy: longint;
  lineWidth, partialWidth: integer;
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
    AStream^.Seek(streamStart + (yIndex + imageRect.Y) * longint(imageRect.Width) + imageRect.X, soFromBeginning);
    if offset + lineWidth > FWinSize then begin
      partialWidth := FWinSize - offset + 1;
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

procedure TSVga8Driver.DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, drawRect: TRect;
  xIndex, yIndex: integer;
  screen: PByte;
  offset: longint;
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
  AStream^.Seek(streamStart + (yIndex + imageRect.Y) * AWidth + imageRect.X, soFromPosition);
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetDrawPointer(drawRect.X, drawRect.Y + yIndex, offset);
    AStream^.Seek(yIndex * imageRect.Width + imageRect.X, soFromBeginning);
    AStream^.Read(imageLine, lineWidth);
    linePtr := imageLine;
    for xIndex := 0 to lineWidth - 1 do begin
      if linePtr^ <> TransparentColor then
        screen^ := linePtr^;
      Inc(screen);
      Inc(offset);
      Inc(linePtr);
      if offset > FWinSize then
        screen := GetDrawPointer(drawRect.X + xIndex + 1, sy, offset);
    end;
    Inc(sy);
  end;
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
  FreeMem(imageLine, lineWidth);
end;

procedure TSVga8Driver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: longint;
  sy: longint;
  lineWidth, partialWidth: integer;
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
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    if offset + lineWidth > FWinSize then begin
      partialWidth := FWinSize - offset + 1;
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

procedure TSVga8Driver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
var
  imageRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  offset: longint;
  sy: longint;
  lineWidth, partialWidth: integer;
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
    AStream^.Seek(streamStart + (yIndex + imageRect.Y) * longint(imageRect.Width) + imageRect.X, soFromBeginning);
    if offset + lineWidth > FWinSize then begin
      partialWidth := FWinSize - offset + 1;
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