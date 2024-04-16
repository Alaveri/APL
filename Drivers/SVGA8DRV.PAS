{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q+,R-,S-,T+,V-,X+}
{$ENDIF}
unit SVga8Drv;

interface

uses
  {$IFDEF DOS}
  Strings,
  {$ENDIF}
  Objects,
  Errors,
  Drawing,
  Common,
  StrUtils,
  Streams,
  GraphDrv,
  GrDrv8,
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
    function GetScreenPtr(AX, AY: integer; var AOffset: longint): PByte;
  public
    function GetPixel(AX, AY: integer): byte; virtual;
    procedure GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure SetPixel(AX, AY: integer); virtual;
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
  supported, status: byte;
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
    mov [status], ah
  end;
  if (supported <> $4F) or (status <> 0) then begin
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
      Id := TString.New('SVga'
        + IntToStr(vbeMode.v1.XResolution)
        + 'x'
        + IntToStr(vbeMode.v1.YResolution)
        + 'x'
        + IntToStr(vbeMode.v1.Bpp));
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
      HelpText := TString.New('Requires a VESA compliant Super VGA card.');
      FrameBuffer := Ptr(vbeMode.v1.WinSegmentA, 0);
      FGranularity := vbeMode.v1.WinGranularity;
    end;
    Inc(modePtr);
    Modes.Add(newMode);
  end;
end;

function TSVga8Driver.GetPixel(AX, AY: integer): byte;
var
  offset: longint;
  screen: PByte;
begin
  if HasException then
    exit;
  screen := GetScreenPtr(AX, AY, offset);
  GetPixel := screen^;
end;

procedure TSVga8Driver.SetMode(AMode: PGraphicsMode);
var
  selectedMode: word;
  svgaMode: PSVga8Mode;
begin
  inherited SetMode(AMode);
  svgaMode := PSVga8Mode(pointer(AMode));
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

procedure TSVga8Driver.SetPixel(AX, AY: integer);
var
  offset: longint;
  screen: PByte;
begin
  if HasException then
    exit;
  screen := GetScreenPtr(AX, AY, offset);
  screen^ := State.ForeColor;
end;

function TSVga8Driver.GetScreenPtr(AX, AY: integer; var AOffset: longint): PByte;
var
  bank: integer;
  screen: PByte;
  count: longint;
begin
  if State.FrameBuffer <> Mode^.FrameBuffer then begin
    screen := State.FrameBuffer;
    AOffset := AY * State.ViewPort.Width + AX;
    Inc(screen, AOffset);
    GetScreenPtr := screen;
    exit;
  end;
  AOffset := longint(AY) * Mode^.BytesPerScanLine + AX;
  screen := Mode^.FrameBuffer;
  bank := AOffset shr 16;
  AOffset := AOffset and FWinSize;
  Inc(screen, AOffset);
  SetBank(bank);
  GetScreenPtr := screen;
end;

procedure TSVga8Driver.RenderText(AX, AY, ALength: integer; AText: PChar);
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
  offset: longint;
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
        if offset > FWinSize then
          screen := GetScreenPtr(sx + xIndex + 1, sy, offset);
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
  CheckRange(AX, drawRect.X, drawRect.Right);
  AWidth := MinLong(drawRect.Width, AWidth);
  if AWidth <= 0 then
    exit;
  screen := GetScreenPtr(AX, AY, offset);
  color := byte(ForeColor);
  if AWidth + offset > FWinSize then begin
    partialWidth := FWinSize - offset + 1;
    FillChar(screen^, partialWidth, color);
    SetBank(FCurrentBank + 1);
    screen := Mode^.FrameBuffer;
    FillChar(screen^, AWidth - partialWidth, color);
  end
  else
    FillChar(screen^, AWidth, color);
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
    screen := GetScreenPtr(AX, index, offset);
    screen^ := ForeColor;
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
    screen := GetScreenPtr(drawRect.X, sy, offset);
    image := AImage;
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    if offset + lineWidth > FWinSize then begin
      partialWidth := FWinSize - offset + 1;
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
    screen := GetScreenPtr(drawRect.X, sy, offset);
    image := AImage;
    Inc(image, (yIndex + imageRect.Y) * imageRect.Width + imageRect.X);
    for xIndex := 0 to drawRect.Width - 1 do begin
      if image^ <> TransparentColor then
        screen^ := image^;
      Inc(image);
      Inc(screen);
      Inc(offset);
      if offset > FWinSize then
        screen := GetScreenPtr(drawRect.X + xIndex + 1, sy, offset);
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
    screen := GetScreenPtr(drawRect.X, sy, offset);
    AStream^.Seek((yIndex + imageRect.Y) * imageRect.Width + imageRect.X, soFromBeginning);
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
      if offset > FWinSize then
        screen := GetScreenPtr(drawRect.X + xIndex + 1, sy, offset);
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
    screen := GetScreenPtr(drawRect.X, sy, offset);
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
    screen := GetScreenPtr(drawRect.X, sy, offset);
    AStream^.Seek((yIndex + imageRect.Y) * imageRect.Width + imageRect.X, soFromBeginning);
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