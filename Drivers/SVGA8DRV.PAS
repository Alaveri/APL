{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit SVga8Drv;

interface

uses
  Objects,
  Except,
  GraphDrv,
  Graph8,
  Common,
  StrUtils,
  Strings,
  Streams,
  Drawing;

type
  PSVga8Mode = ^TSvga8Mode;
  TSvga8Mode = object(TGraphicsMode)
  private
    FAttributes: word;
    FGranularity: word;
    FWinFuncPtr: pointer;
  public
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  PSVga8Driver = ^TSVga8Driver;
  TSVga8Driver = object(TGraphics256Driver)
  private
    FSVga8Driver: integer;
    FCurrentBank: integer;
    FGranularity: longint;
    FWinFunc: pointer;
    FBankShift: word;
    procedure SetBank(ABank: word);
    function GetScreenPtr(AX, AY: integer; var offset: longint): PByte;
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
  Dos,
  MouseDrv;

type
  PVbeInfo = ^TVbeInfo;
  PVbeMode = ^TVbeMode;

  TVbeInfo = record
    VbeSignature: array[0..3] of char;
    VbeVersion: word;
    OemStringPtr: pointer;
    Capabilities: longint;
    VideoModes: pointer;
    TotalMemory: word;
    SoftwareRevision: word;
    Vendor: longint;
    ProductName: pointer;
    ProductRevision: pointer;
    Reserved: array[0..221] of byte;
    OemData: array[0..255] of byte
  end;

  TVbeMode = record
    Attributes: word; {depricated; bit 7 indicates linear fram buffer support}
    WindowA: byte; {depricated}
    WindowB: byte; {depricated}
    Granularity: word; {depricated}
    WindowSize: word;
    SegmentA: word;
    SegmentB: word;
    WinFuncPtr: pointer; {depricated}
    Pitch: word; {bytes per horizontal line}
    Width: word; {width in pixels}
    Height: word; {height in pixels}
    Wchar: char; {unused}
    Ychar: char; {unused}
    Planes: byte;
    Bpp: byte; {bits per pixel}
    Banks: byte; {deprecated; total number of banks in this mode}
    MemoryModel: byte;
    BankSize: byte; {deprecated; size of bank, usually 64k, could be 16k}
    ImagePages: byte;
    Reserved0: byte;
    RedMask: byte;
    RedPosition: byte;
    GreenMask: byte;
    GreenPosition: byte;
    BlueMask: byte;
    BluePosition: byte;
    ReservedMask: byte;
    ReservedPosition: byte;
    DirectColorAttributes: byte;
    FrameBuffer: pointer; {physical address of the frame buffer}
    OffScreenMemOffset: longint;
    OffScreenMemSize: word;
    Reserved1: array[0..205] of byte;
  end;

procedure TSvga8Mode.Init;
begin
  inherited Init;
  FGranularity := 0;
  FAttributes := 0;
  FWinFuncPtr := nil;
end;

procedure TSVga8Mode.Assign(var ASource: TObject);
var
  mode: PSVga8Mode;
begin
  inherited Assign(ASource);
  mode := PSVga8Mode(@ASource);
  FAttributes := mode^.FAttributes;
  FGranularity := mode^.FGranularity;
  FWinFuncPtr := mode^.FWinFuncPtr;
end;

procedure TSVga8Driver.Init;
var
  newMode: PSVga8Mode;
  oldMode: byte;
  info: TVbeInfo;
  segm, offs, modeCount: word;
  supported, status: byte;
  modePtr: PWord;
  modeInfo: TVbeMode;
  vbeModeIndex: word;
  colors: string;
  index: integer;
  vbeMode: TVbeMode;
  desc: string;
begin
  inherited Init;
  FCurrentBank := -1;
  segm := Seg(info);
  offs := Ofs(info);
  FGranularity := 0;
  FBankShift := 0;
  asm
    push ES
    mov  AX, 4F00h
    mov  ES, [segm]
    mov  DI, [offs]
    int  10h
    mov  [supported], AL
    mov  [status], AH
    pop  ES
  end;
  if (supported <> $4F) or (status <> 0) then begin
    Raise(ecGraphicsNotSupported);
    exit;
  end;

  modePtr := info.VideoModes;
  modeCount := 0;
  while modePtr^ <> $FFFF do begin
    Inc(modeCount);
    Inc(modePtr);
  end;

  Modes := New(PGraphicsModeList, CreateCapacity(modeCount));

  modePtr := info.VideoModes;
  index := 0;
  while modePtr^ <> $FFFF do begin
    vbeModeIndex := modePtr^;
    segm := Seg(modeInfo);
    offs := Ofs(modeInfo);
    asm
      mov  AX, $4F01
      mov  ES, [segm]
      mov  DI, [offs]
      mov  CX, [vbeModeIndex]
      int  10h
    end;
    if modeInfo.Bpp <> 8 then begin
      Inc(modePtr);
      Inc(index);
      continue;
    end;
    newMode := New(PSVga8Mode, Create);
    vbeMode := modeInfo;
    with newMode^ do begin
      Id := NewLargeString('SVga'
        + IntToStr(vbeMode.Width)
        + 'x'
        + IntToStr(vbeMode.Height)
        + 'x'
        + IntToStr(vbeMode.Bpp));
      case vbeMode.Bpp of
          4: colors := '16';
          8: colors := '256';
          15: colors := '32k';
          16: colors := '64k';
          32: colors := '16m';
      end;
      desc := 'SVGA '
        + IntToStr(vbeMode.Width)
        + 'x'
        + IntToStr(vbeMode.Height)
        + ' '
        + colors
        + ' Color';
      Description := NewLargeString(desc);
      AdditionalData := vbeModeIndex;
      Width := vbeMode.Width;
      Height := vbeMode.Height;
      MaxX := vbeMode.Width - 1;
      MaxY := vbeMode.Height - 1;
      Bpp := vbeMode.Bpp;
      Pitch := vbeMode.Pitch;
      FAttributes := vbeMode.Attributes;
      FGranularity := vbeMode.Granularity;
      FWinFuncPtr := vbeMode.WinFuncPtr;
      HelpText := NewLargeString('Requires a VESA compliant Super VGA card.');
      FrameBuffer := Ptr($A000,$0000);
    end;
    Inc(modePtr);
    Inc(index);
    Modes^.Add(newMode);
  end;
end;

function TSVga8Driver.GetPixel(AX, AY: integer): byte;
var
  offset: longint;
  screen: PByte;
begin
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
  selectedMode := AMode^.AdditionalData;
  if (bit7 in TBits(Lo(sVgaMode^.FAttributes))) then begin
    selectedMode := selectedMode or $4000;
  end;
  asm
    mov   ax, 4F02h
    mov   bx, [selectedMode]
    int   10h
  end;
  Mouse.SetMouseResolution(AMode^.Width, AMode^.Height);
  if HasException then
    exit;
  State^.FrameBuffer := AMode^.FrameBuffer;
  SetStandardPalette;
  FGranularity := longint(SVgaMode^.FGranularity) * 1024 - 1;
  FWinFunc := SVgaMode^.FWinFuncPtr;
  FCurrentBank := -1;
  FBankShift := 0;
  while (64 shr FBankShift <> SvgaMode^.FGranularity) do begin
    Inc(FBankShift);
  end;
end;

procedure TSVga8Driver.SetBank(ABank: word);
var
  winFunc: pointer;
begin
  if ABank = FCurrentBank then
    exit;
  FCurrentBank := ABank;
  winFunc := FWinFunc;
  asm
    mov bx, 0
    mov dx, [ABank]
    call [winFunc]

    inc bx
    call [winFunc]
  end;
end;

procedure TSVga8Driver.SetPixel(AX, AY: integer);
var
  offset: longint;
  screen: PByte;
begin
  screen := GetScreenPtr(AX, AY, offset);
  screen^ := State^.ForeColor;
end;

function TSVga8Driver.GetScreenPtr(AX, AY: integer; var offset: longint): PByte;
var
  bank: integer;
  screen: PByte;
begin
  offset := longint(AY) * Mode^.Pitch + AX;
  bank := offset shr 16;
  offset := offset and FGranularity;
  screen := Mode^.FrameBuffer;
  Inc(screen, offset);
  SetBank(bank);
  GetScreenPtr := screen;
end;

procedure TSVga8Driver.RenderText(AX, AY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  charIndex, yIndex, xIndex: integer;
  ch: char;
  sy, sx, minX, maxX: integer;
  linePtr: PByte;
  width, height: integer;
  screen: PByte;
  fore, back: byte;
  offset: longint;
  granularity: word;
begin
  Mode^.Bounds.Intersection(State^.ViewPort, drawRect);
  if AX > drawRect.Right then
    exit;
  if AY > drawRect.Bottom then
    exit;
  height := State^.Font^.Height;
  if AY + height < drawRect.Y then
    exit;
  granularity := FGranularity;
  width := 0;
  for charIndex := 0 to ALength - 1 do begin
    ch := AText[charIndex];
    sx := AX + width;
    sy := AY;
    fore := State^.ForeColor;
    back := State^.BackColor;
    linePtr := PMonospaceFont(State^.Font)^.FontData;
    Inc(linePtr, Ord(ch) * height);
    maxX := MinL(State^.Font^.TextWidth(ch) - 1, drawRect.Right - sx);
    minX := MaxL(0, drawRect.X - sx);
    if minX > maxX then
      continue;
    Inc(linePtr, minX);
    for yIndex := 0 to height - 1 do begin
      sy := AY + yIndex;
      if sy > drawRect.Bottom then
        break;
      screen := GetScreenPtr(sx + minX, sy, offset);
      for xIndex := minX to maxX do begin
        if (linePtr^ and (128 shr xIndex)) > 0 then
          screen^ := fore;
        Inc(screen);
        Inc(offset);
        if offset > granularity then
          screen := GetScreenPtr(xIndex, sy, offset);
      end;
      Inc(linePtr);
    end;
    Inc(width, State^.Font^.TextWidth(ch));
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
  Mode^.Bounds.Intersection(State^.ViewPort, drawRect);
  if (AY < drawRect.Y) or (AY > drawRect.Bottom) then
    exit;
  AX := MaxL(MinL(AX, drawRect.Right), drawRect.X);
  AWidth := MinL(drawRect.Right - AX + 1, AWidth);
  if AWidth <= 0 then
    exit;

  screen := GetScreenPtr(AX, AY, offset);
  color := byte(ForeColor);
  if AWidth + offset > FGranularity then begin
    partialWidth := FGranularity - offset + 1;
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
  Mode^.Bounds.Intersection(State^.ViewPort, drawRect);
  if (AX < drawRect.X) or (AX > drawRect.Right) then
    exit;
  AY := MaxL(MinL(AY, drawRect.Right), drawRect.Y);
  AHeight := MinL(drawRect.Bottom - AY + 1, AHeight);
  if AHeight <= 0 then
    exit;
  for index := MaxL(AY, 0) to MinL(AY + AHeight - 1, Mode^.MaxY) do begin
    screen := GetScreenPtr(AX, index, offset);
    screen^ := ForeColor;
  end;
end;

procedure TSVga8Driver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
var
  imageRect, viewRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: longint;
  sy: longint;
  lineWidth, partialWidth: integer;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, sy, offset);
    image := AImage;
    Inc(image, yIndex * drawRect.Width);
    if offset + lineWidth > FGranularity then begin
      partialWidth := FGranularity - offset + 1;
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
  imageRect, viewRect, drawRect: TRect;
  xIndex, yIndex, imageX, imageY: integer;
  offset: longint;
  screen, image: PByte;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  imageX := drawRect.X - AX;
  imageY := drawRect.Y - AY;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, yIndex + drawRect.Y, offset);
    image := AImage;
    Inc(image, (imageY + yIndex) * AWidth + imageX);
    for xIndex := 0 to drawRect.Width - 1 do begin
      if image^ <> TransparentColor then
        screen^ := image^;
      Inc(image);
      Inc(screen);
      Inc(offset);
      if offset > FGranularity then
        screen := GetScreenPtr(drawRect.X + xIndex, yIndex + imageY, offset);
    end;
  end;
end;

procedure TSVga8Driver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, viewRect, drawRect: TRect;
  imageX, imageY, yIndex: integer;
  screen: PByte;
  offset: longint;
  lineWidth, partialWidth: integer;
  streamWidth: integer;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  lineWidth := drawRect.Width;
  imageX := drawRect.X - AX;
  imageY := drawRect.Y - AY;
  AStream^.Seek(imageY * AWidth + imageX, soFromPosition);
  streamWidth := AWidth - drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, yIndex + drawRect.Y, offset);
    if offset + lineWidth > FGranularity then begin
      partialWidth := FGranularity - offset + 1;
      AStream^.Read(screen, partialWidth);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      AStream^.Read(screen, lineWidth - partialWidth);
    end
    else begin
      AStream^.Read(screen, lineWidth);
    end;
    AStream^.Seek(streamWidth, soFromPosition);
    if AStream^.HasException then begin
      Raise(AStream^.Exception^.Code);
      break;
    end;
  end;
end;

procedure TSVga8Driver.DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream);
var
  imageRect, viewRect, drawRect: TRect;
  imageX, imageY, xIndex, yIndex: integer;
  screen: PByte;
  offset: longint;
  streamWidth: integer;
  pixel: byte;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  imageX := drawRect.X - AX;
  imageY := drawRect.Y - AY;
  AStream^.Seek(imageY * AWidth + imageX, soFromPosition);
  streamWidth := AWidth - drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, yIndex + drawRect.Y, offset);
    for xIndex := 0 to drawRect.Width - 1 do begin
      pixel := AStream^.ReadByte;
      if pixel <> TransparentColor then
        screen^ := pixel;
      Inc(screen);
      Inc(offset);
      if offset > FGranularity then
        screen := GetScreenPtr(drawRect.X + xIndex, yIndex + imageY, offset);
    end;
    AStream^.Seek(streamWidth, soFromPosition);
    if AStream^.HasException then begin
      Raise(AStream^.Exception^.Code);
      break;
    end;
  end;
end;

procedure TSVga8Driver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
var
  imageRect, viewRect, drawRect: TRect;
  yIndex: integer;
  screen, image: PByte;
  offset: longint;
  sy: longint;
  lineWidth, partialWidth: integer;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  sy := drawRect.Y;
  lineWidth := drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, sy, offset);
    image := ABuffer;
    Inc(image, yIndex * drawRect.Width);
    if offset + lineWidth > FGranularity then begin
      partialWidth := FGranularity - offset + 1;
      Move(screen^, image^, partialWidth);
      Inc(image, partialWidth);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      Move(image^, screen^, lineWidth - partialWidth);
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
  imageRect, viewRect, drawRect: TRect;
  yIndex: integer;
  screen: PByte;
  offset: longint;
  lineWidth, partialWidth: integer;
begin
  imageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(imageRect, drawRect);
  if drawRect.IsEmpty then
    exit;
  lineWidth := drawRect.Width;
  for yIndex := 0 to drawRect.Height - 1 do begin
    screen := GetScreenPtr(drawRect.X, yIndex + drawRect.Y, offset);
    if offset + lineWidth > FGranularity then begin
      partialWidth := FGranularity - offset + 1;
      AStream^.Write(screen, partialWidth);
      SetBank(FCurrentBank + 1);
      screen := Mode^.FrameBuffer;
      AStream^.Write(screen, lineWidth - partialWidth);
    end
    else begin
      AStream^.Write(screen, lineWidth);
    end;
    if AStream^.HasException then begin
      Raise(AStream^.Exception^.Code);
      break;
    end;
  end;
end;

procedure TSVga8Driver.WaitForVSync;
begin
  while (Port[$3DA] and $08) = $08 do;
  while (Port[$3DA] and $08) <> $08 do;
end;

destructor TSVga8Driver.Free;
begin
  inherited Free;
end;

begin
end.