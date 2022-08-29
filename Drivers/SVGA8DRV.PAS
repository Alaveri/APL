{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I-,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit SVga8Drv;

interface

uses
  Objects,
  GraphDrv,
  Common,
  StrUtils,
  Streams,
  Drawing;

type
  PSVga8Mode = ^TSvga8Mode;
  TSvga8Mode = object(TGraphicsMode)
  private
    Attributes: word;
    Granularity: word;
    WinFuncPtr: pointer;
  public
    procedure Init; virtual;
    procedure Assign(var source: TPersistent); virtual;
    procedure AssignTo(var dest: TPersistent); virtual;
  end;
  PSVga8Driver = ^TSVga8Driver;
  TSVga8Driver = object(TGraphicsDriver)
  private
    _SVga8Driver: integer;
    _currentBank: integer;
    _granularity: longint;
    _winFunc: pointer;
    _bankShift: word;
    procedure SetBank(bank: word);
  public
    function GetPixel(x, y: integer): byte; virtual;
    procedure GetImage(x, y, width, height: longint; buffer: PByte); virtual;
    procedure GetImageStream(x, y, width, height: longint; stream: PStream); virtual;
    procedure SetMode(newMode: PGraphicsMode); virtual;
    procedure SetPixel(x, y: integer); virtual;
    procedure DrawText(x, y: integer; text: string); virtual;
    procedure DrawTextLarge(x, y: integer; text: PChar); virtual;
    procedure MoveTo(x, y: integer); virtual;
    procedure LineTo(x, y: integer); virtual;
    procedure Line(x1, y1, x2, y2: integer); virtual;
    procedure HLine(x, y, width: integer); virtual;
    procedure VLine(x, y, height: integer); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure DrawImage(x, y, width, height: longint; image: PByte); virtual;
    procedure DrawImageTransparent(x, y, width, height: longint; image: PByte); virtual;
    procedure DrawImageStream(x, y, width, height: longint; stream: PStream); virtual;
    procedure DrawImageStreamTransparent(x, y, width, height: longint; stream: PStream); virtual;
    procedure DrawImageBuffer(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte); virtual;
    procedure DrawImageBufferTransparent(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Done; virtual;
  end;

implementation

uses
  Globals,
  Dos;


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
  Granularity := 0;
  Attributes := 0;
  WinFuncPtr := nil;
end;

procedure TSVga8Mode.Assign(var source: TPersistent);
var
  mode: PSVga8Mode;
begin
  TGraphicsMode.Assign(source);
  mode := PSVga8Mode(@source);
  Attributes := mode^.Attributes;
  Granularity := mode^.Granularity;
  WinFuncPtr := mode^.WinFuncPtr;
end;

procedure TSVga8Mode.AssignTo(var dest: TPersistent);
var
  mode: PSVga8Mode;
begin
  TGraphicsMode.AssignTo(dest);
  mode := PSVga8Mode(@dest);
  mode^.Attributes := Attributes;
  mode^.Granularity := Granularity;
  mode^.WinFuncPtr := WinFuncPtr;
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
  TGraphicsDriver.Init;
  _currentBank := -1;
  segm := Seg(info);
  offs := Ofs(info);
  _granularity := 0;
  _bankShift := 0;
  asm
    push es
    mov  ax, 4F00h
    mov  es, [segm]
    mov  di, [offs]
    int  10h
    mov  [supported], al
    mov  [status], ah
    pop  es
  end;
  if (supported <> $4F) or (status <> 0) then begin
    CreateError(error, ecGraphicsNotSupported, esError);
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
    newMode := New(PSVga8Mode, Create);
    vbeModeIndex := modePtr^;
    segm := Seg(modeInfo);
    offs := Ofs(modeInfo);
    with newMode^ do begin
      asm
        mov  ax, $4F01
        mov  es, [segm]
        mov  di, [offs]
        mov  cx, [vbeModeIndex]
        int  10h
      end;
      vbeMode := modeInfo;
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
        + colors;
      Description := NewLargeString(desc);
      AdditionalData := vbeModeIndex;
      Width := vbeMode.Width;
      Height := vbeMode.Height;
      MaxX := vbeMode.Width - 1;
      MaxY := vbeMode.Height - 1;
      Bpp := vbeMode.Bpp;
      Pitch := vbeMode.Pitch;
      Attributes := vbeMode.Attributes;
      Granularity := vbeMode.Granularity;
      WinFuncPtr := vbeMode.WinFuncPtr;
      HelpText := NewLargeString('Requires a VESA compliant Super VGA card.');
      FrameBuffer := Ptr($A000,$0000);
    end;
    Inc(modePtr);
    Modes^.Add(newMode);
    Inc(index);
  end;
end;

function TSVga8Driver.GetPixel(x, y: integer): byte;
var
  offset: longint;
  ptr: PByte;
begin
  offset := x + longint(y) * Mode^.Pitch;
  ptr := Mode^.FrameBuffer;
  Inc(ptr, offset and $FFFF);
  SetBank(offset shr 16);
  GetPixel := ptr^;
end;

procedure TSVga8Driver.SetMode(newMode: PGraphicsMode);
var
  selectedMode: word;
  svgaMode: PSVga8Mode;
begin
  svgaMode := PSVga8Mode(pointer(newMode));
  selectedMode := newMode^.AdditionalData;
  if (bit7 in TBits(Lo(SvgaMode^.Attributes))) then begin
    selectedMode := selectedMode or $4000;
  end;
  asm
    mov   ax, 4F02h
    mov   bx, [selectedMode]
    int   10h
  end;
  if (Error.ErrorCode <> ecNone) then exit;
  SetStandardPalette;
  _granularity := longint(SvgaMode^.Granularity) * 1024 - 1;
  _winFunc := SVgaMode^.WinFuncPtr;
  _currentBank := -1;
  _bankShift := 0;
  while (64 shr _bankShift <> SvgaMode^.Granularity) do begin
    Inc(_bankShift);
  end;
  Mode := svgaMode;
  inherited SetMode(newMode);
end;

procedure TSVga8Driver.SetBank(bank: word);
var
  winFunc: pointer;
begin
  if (bank = _currentBank) then exit;
  _currentBank := bank;
  bank := bank shl _bankShift;
  winFunc := _winFunc;
  asm
    mov  ax, 4f05h
    mov  bx, 0
    mov  dx, [bank]
    call [winFunc]

    mov  ax, 4f05h
    mov  bx, 1
    mov  dx, [bank]
    call [winFunc]
  end;
end;

procedure TSVga8Driver.SetPixel(x, y: integer);
var
  offset: longint;
  ptr: PByte;
begin
  offset := x + longint(y) * Mode^.Pitch;
  ptr := Mode^.FrameBuffer;
  Inc(ptr, offset and $FFFF);
  SetBank(offset shr 16);
  ptr^ := State^.ForeColor;
end;

procedure TSVga8Driver.DrawText(x, y: integer; text: string);
var
  charIndex, xIndex, yIndex, sx, sy, chWidth, MaxX, MaxY: integer;
  ch: char;
  pixel: byte;
  tx: integer;
  color: byte;
  offset: longint;
  ptr: PByte;
  lineSize: word;
  chVal: byte;
  currentLine: array[0..8] of byte;
  pitch: integer;
  fontData: PFontData;
  sForeColor, sBackColor: byte;
begin
  if (State^.Font = nil) or (Length(text) = 0) then exit;
  maxX := Mode^.MaxX;
  maxY := Mode^.MaxY;
  pitch := Mode^.Pitch;
  fontData := State^.Font^.FontData;
  sForeColor := State^.ForeColor;
  sBackColor := State^.BackColor;
  for charIndex := 1 to Length(text) do begin
    ch := text[charIndex];
    chWidth := State^.Font^.TextWidth(ch);
    sy := y;
    sx := x + (charIndex - 1) * chWidth - 1;
    color := State^.ForeColor;
    chVal := Ord(ch);
    for yIndex := 0 to State^.Font^.Height - 1 do begin
      if (sy > MaxY) then exit;
      offset := longint(sy) * pitch + sx;
      ptr := Mode^.FrameBuffer;
      Inc(ptr, offset and _granularity);

      for xIndex := 0 to chWidth - 1 do begin
        tx := sx + xIndex;
        if (tx > maxX) then break;
        if (fontData^[chVal, yIndex] and (128 shr xIndex) > 0) then begin
          color := sForeColor;
        end
        else
          color := sBackColor;
        Inc(ptr);
        Inc(offset);
        if (offset shr 16 <> _currentBank) then begin
          SetBank(offset shr 16);
        end;
        ptr^ := color;
      end;
      Inc(sy);
    end;
  end;
end;


procedure TSVga8Driver.DrawTextLarge(x, y: integer; text: PChar);
begin
end;

procedure TSVga8Driver.MoveTo(x, y: integer);
begin
end;

procedure TSVga8Driver.LineTo(x, y: integer);
begin
end;

procedure TSVga8Driver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure TSVga8Driver.HLine(x, y, width: integer);
var
  lineWidth, xOffset, offset: longint;
  ptr: PByte;
  index: word;
  partialWidth: word;
  bank: word;
begin
  xOffset := 0;
  if (x < 0) then begin
    xOffset := Abs(x);
  end;
  Inc(x, xOffset);
  lineWidth := width - xOffset;
  lineWidth := MinL(lineWidth, Mode^.MaxX - x);
  if (y < 0) or (y > Mode^.MaxY) then exit;
  offset := x + longint(y) * Mode^.Pitch;
  bank := offset shr 16;
  offset := offset and _granularity;
  ptr := Mode^.FrameBuffer;
  Inc(ptr, offset);
  SetBank(bank);
  if (offset + lineWidth > _granularity) then begin
    partialWidth := _granularity - offset + 1;
    FillChar(ptr^, partialWidth, ForeColor);
    SetBank(bank + 1);
    ptr := Mode^.FrameBuffer;
    FillChar(ptr^, lineWidth - partialWidth, ForeColor);
  end
  else
    FillChar(ptr^, lineWidth, ForeColor);
end;

procedure TSVga8Driver.VLine(x, y, height: integer);
var
  index: integer;
  offset: longint;
  ptr: PByte;
  bank: word;
begin
  if (x < 0) or (x > Mode^.MaxX) then exit;
  for index := (MaxL(y, 0)) to MinL(y + height - 1, Mode^.MaxY) do begin
    offset := x + longint(index) * Mode^.Pitch;
    bank := offset shr 16;
    SetBank(bank);
    ptr := Mode^.FrameBuffer;
    Inc(ptr, offset);
    ptr^ := ForeColor;
  end;
end;

procedure TSVga8Driver.FillRect(rect: TRect);
var
  index: word;
begin
  if (rect.IsEmpty) then exit;
  for index := rect.Y to rect.Bottom do begin
    HLine(rect.X, index, rect.Width);
  end;
end;

procedure TSVga8Driver.DrawImage(x, y, width, height: longint ; image: PByte);
var
  yIndex, sx, sy: integer;
  lineWidth, partialWidth: integer;
  xOffset: integer;
  imagePtr, screenPtr: PByte;
  offset: longint;
  bank: word;
begin
  sy := y;
  xOffset := 0;
  if (x < 0) then begin
    xOffset := Abs(x);
  end;

  lineWidth := width - xOffset;
  lineWidth := MinL(lineWidth, Mode^.MaxX - x);
  imagePtr := image;
  sx := x + xOffset;

  for yIndex := 0 to height - 1 do begin
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    if (sy > Mode^.MaxX) then begin
      break;
    end;

    imagePtr := image;
    Inc(imagePtr, longint(yIndex) * width + xOffset);

    offset := sx + longint(sy) * Mode^.Pitch;
    bank := offset shr 16;
    offset := offset and _granularity;
    if (bank <> _currentBank) then SetBank(bank);
    screenPtr := Mode^.FrameBuffer;
    Inc(screenPtr, offset);

    if (offset + lineWidth > _granularity) then begin
      partialWidth := _granularity - offset + 1;
      Move(imagePtr^, screenPtr^, partialWidth);
      Inc(imagePtr, partialWidth);
      SetBank(bank + 1);
      screenPtr := Mode^.FrameBuffer;
      Move(imagePtr^, screenPtr^, lineWidth - partialWidth);
    end
    else begin
      Move(imagePtr^, screenPtr^, lineWidth);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.DrawImageTransparent(x, y, width, height: longint; image: PByte);
var
  xIndex, yIndex, sx, sy: integer;
  lineWidth, partialWidth: integer;
  xOffset: integer;
  screenPtr, imagePtr: PByte;
  offset: longint;
  imageLineOffset: integer;
  bank: word;
  lineRight: integer;
begin
  sy := y;
  xOffset := 0;
  if (x < 0) then begin
    xOffset := Abs(x);
  end;

  lineWidth := width - xOffset;
  lineWidth := MinL(lineWidth, Mode^.MaxX - x);
  imagePtr := image;

  for yIndex := 0 to height - 1 do begin
    sx := x + xOffset;
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    if (sy > Mode^.MaxY) then begin
      break;
    end;

    imagePtr := image;
    imageLineOffset := longint(yIndex) * width + xOffset;
    Inc(imagePtr, imageLineOffset);

    offset := sx + longint(sy) * Mode^.Pitch;
    bank := offset shr 16;
    offset := offset and _granularity;
    if (bank <> _currentBank) then SetBank(bank);
    screenPtr := Mode^.FrameBuffer;
    Inc(screenPtr, offset);
    lineRight := sx + lineWidth - 1;

    while (sx <= lineRight) do begin
      if (offset > _granularity) then begin
        SetBank(bank + 1);
        screenPtr := Mode^.FrameBuffer;
        offset := 0;
      end;
      if (imagePtr^ <> transparentColor) then screenPtr^ := imagePtr^;
      Inc(sx);
      Inc(imagePtr);
      Inc(screenPtr);
      Inc(offset);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.DrawImageStream(x, y, width, height: longint; stream: PStream);
var
  yIndex, sx, sy: integer;
  lineWidth, partialWidth: integer;
  xOffset: integer;
  screenPtr: PByte;
  offset: longint;
  bank: word;
  position: longint;
begin
  sy := y;
  xOffset := 0;
  if (x < 0) then begin
    xOffset := Abs(x);
  end;

  position := stream^.Position;

  lineWidth := width - xOffset;
  lineWidth := MinL(lineWidth, Mode^.MaxX - x);
  sx := x + xOffset;

  for yIndex := 0 to height - 1 do begin
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    if (sy > Mode^.MaxX) then begin
      break;
    end;

    stream^.Seek(position + longint(yIndex) * width + xOffset, soFromBeginning);
    if (not NoError(stream^.Error)) then exit;

    offset := sx + longint(sy) * Mode^.Pitch;
    bank := offset shr 16;
    offset := offset and _granularity;
    if (bank <> _currentBank) then SetBank(bank);
    screenPtr := Mode^.FrameBuffer;
    Inc(screenPtr, offset);

    if (offset + lineWidth > _granularity) then begin
      partialWidth := _granularity - offset + 1;
      stream^.Read(screenPtr, partialWidth);
      if (not NoError(stream^.Error)) then exit;
      stream^.Seek(partialWidth, soFromPosition);
      if (not NoError(stream^.Error)) then exit;
      SetBank(bank + 1);
      screenPtr := Mode^.FrameBuffer;
      stream^.Read(screenPtr, lineWidth - partialWidth);
      if (not NoError(stream^.Error)) then exit;
    end
    else begin
      stream^.Read(screenPtr, lineWidth);
      if (not NoError(stream^.Error)) then exit;
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.DrawImageStreamTransparent(x, y, width, height: longint; stream: PStream);
var
  xIndex, yIndex, sx, sy: integer;
  lineWidth, partialWidth: integer;
  xOffset: integer;
  screenPtr: PByte;
  offset: longint;
  bank: word;
  lineRight: integer;
  position: longint;
  pixel: byte;
begin
  sy := y;
  xOffset := 0;
  if (x < 0) then begin
    xOffset := Abs(x);
  end;
  lineWidth := width - xOffset;
  lineWidth := MinL(lineWidth, Mode^.MaxX - x);
  position := stream^.Position;
  for yIndex := 0 to height - 1 do begin
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    if (sy > Mode^.MaxY) then begin
      break;
    end;

    stream^.Seek(position + longint(yIndex) * width + xOffset, soFromBeginning);
    if (not NoError(stream^.Error)) then exit;

    offset := longint(sy) * Mode^.Pitch + x + xOffset;
    bank := offset shr 16;
    offset := offset and _granularity;
    if (bank <> _currentBank) then SetBank(bank);
    screenPtr := Mode^.FrameBuffer;
    Inc(screenPtr, offset);

    sx := x + xOffset;
    lineRight := sx + lineWidth - 1;

    while (sx <= lineRight) do begin
      if (offset > _granularity) then begin
        SetBank(bank + 1);
        screenPtr := Mode^.FrameBuffer;
        offset := 0;
      end;

      pixel := stream^.ReadByte;
      if (not NoError(stream^.Error)) then exit;
      if (pixel <> transparentColor) then begin
        screenPtr^ := pixel;
      end;
      Inc(sx);
      Inc(screenPtr);
      Inc(offset);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.DrawImageBuffer(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
var
  yIndex, sx, sy: integer;
  lineWidth: integer;
  xOffset: integer;
  imagePtr, bufferPtr: PByte;
  offset: longint;
begin
  sy := bufferPos.Y;
  xOffset := 0;
  if (bufferPos.X < 0) then begin
    xOffset := Abs(bufferPos.X);
  end;

  lineWidth := imageSize.Width - xOffset;
  lineWidth := MinL(lineWidth, bufferSize.Width - bufferPos.X);
  imagePtr := image;
  sx := bufferPos.X + xOffset;

  for yIndex := 0 to imageSize.Height - 1 do begin
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    if (sy > bufferSize.Height - 1) then begin
      break;
    end;

    imagePtr := image;
    Inc(imagePtr, longint(yIndex) * imageSize.Width + xOffset);

    offset := sx + longint(sy) * bufferSize.Width + xOffset;
    bufferPtr := buffer;
    Inc(bufferPtr, offset);
    Move(imagePtr^, bufferPtr^, lineWidth);
    Inc(sy);
  end;
end;

procedure TSVga8Driver.DrawImageBufferTransparent(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
var
  xIndex, yIndex, sx, sy: integer;
  lineWidth: integer;
  xOffset: integer;
  bufferPtr, imagePtr: PByte;
  offset: longint;
  imageLineOffset: integer;
  lineRight: integer;
begin
  sy := bufferPos.Y;
  xOffset := 0;
  if (bufferPos.X < 0) then begin
    xOffset := Abs(bufferPos.X);
  end;
  lineWidth := bufferPos.X - xOffset;
  lineWidth := MinL(lineWidth, bufferSize.Width - bufferPos.X);
  imagePtr := image;
  for yIndex := 0 to imageSize.Height - 1 do begin
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    if (sy > Mode^.MaxY) then begin
      break;
    end;

    imagePtr := image;
    imageLineOffset := longint(yIndex) * imageSize.Width + xOffset;
    Inc(imagePtr, imageLineOffset);

    offset := longint(sy) * bufferSize.Width + bufferPos.X + xOffset;

    imagePtr := image;
    Inc(imagePtr, offset);

    sx := bufferPos.X + xOffset;
    lineRight := sx + lineWidth - 1;

    while (sx <= lineRight) do begin
      if (imagePtr^ <> transparentColor) then bufferPtr^ := imagePtr^;
      Inc(sx);
      Inc(imagePtr);
      Inc(bufferPtr);
      Inc(offset);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.GetImage(x, y, width, height: longint; buffer: PByte);
var
  yIndex, sx, sy: integer;
  lineWidth, partialWidth: integer;
  xOffset: integer;
  screenPtr, bufferPtr: PByte;
  offset: longint;
  bank: word;
begin
  sy := y;
  xOffset := 0;
  if (x < 0) then begin
    xOffset := Abs(x);
  end;
  sx := x + xOffset;
  lineWidth := width - xOffset;
  lineWidth := MinL(lineWidth, Mode^.Width - sx);
  for yIndex := 0 to height - 1 do begin
    bufferPtr := buffer;
    Inc(bufferPtr, longint(yIndex) * width + xOffset);

    if (sy < 0) or (sy > Mode^.MaxY) then begin
      FillChar(bufferPtr, width, 0);
      Inc(sy);
      continue;
    end;

    if (xOffset > 0) then begin
      FillChar(buffer^, xOffset, 0);
      Inc(buffer, xOffset);
    end;

    offset := sx + longint(sy) * Mode^.Pitch;
    screenPtr := Mode^.FrameBuffer;
    bank := offset shr 16;
    offset := offset and _granularity;
    Inc(screenPtr, offset);
    if (_currentBank <> bank) then SetBank(bank);

    if (offset + lineWidth > _granularity) then begin
      partialWidth := _granularity - offset + 1;
      Move(screenPtr^, bufferPtr^, partialWidth);
      Inc(bufferPtr, partialWidth);
      SetBank(bank + 1);
      screenPtr := Mode^.FrameBuffer;
      Move(screenPtr^, bufferPtr^, lineWidth - partialWidth);
      Inc(bufferPtr, lineWidth - partialWidth);
    end
    else begin
      Move(screenPtr^, bufferPtr^, lineWidth);
      Inc(bufferPtr, lineWidth);
    end;
    if (xOffset > 0) then begin
      FillChar(buffer^, width - lineWidth, 0);
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.GetImageStream(x, y, width, height: longint; stream: PStream);
var
  yIndex, sx, sy: integer;
  lineWidth, partialWidth: integer;
  xOffset: integer;
  screenPtr: PByte;
  position: longint;
  offset: longint;
  bank: word;
begin
  sy := y;
  xOffset := 0;
  if (x < 0) then begin
    xOffset := Abs(x);
  end;
  sx := x + xOffset;
  lineWidth := width - xOffset;
  lineWidth := MinL(lineWidth, Mode^.Width - sx);
  position := stream^.Position;
  for yIndex := 0 to height - 1 do begin
    stream^.Seek(position + longint(yIndex) * width, soFromBeginning);

    if (sy < 0) or (sy > Mode^.MaxY) then begin
      stream^.FillChar(width, #0);
      Inc(sy);
      continue;
    end;

    if (xOffset > 0) then begin
      stream^.FillChar(xOffset, #0);
      if (not NoError(stream^.Error)) then exit;
    end;

    offset := sx + longint(sy) * Mode^.Pitch;
    screenPtr := Mode^.FrameBuffer;
    bank := offset shr 16;
    offset := offset and _granularity;
    Inc(screenPtr, offset);
    if (_currentBank <> bank) then SetBank(bank);

    if (offset + lineWidth > _granularity) then begin
      partialWidth := _granularity - offset + 1;
      stream^.Write(screenPtr, partialWidth);
      if (not NoError(stream^.Error)) then exit;
      stream^.Seek(partialWidth, soFromPosition);
      SetBank(bank + 1);
      screenPtr := Mode^.FrameBuffer;
      stream^.Write(screenPtr, lineWidth - partialWidth);
      if (not NoError(stream^.Error)) then exit;
      stream^.Seek(lineWidth - partialWidth, soFromPosition);
    end
    else begin
      stream^.Write(screenPtr, lineWidth);
      if (not NoError(stream^.Error)) then exit;
    end;
    if (sx + lineWidth > Mode^.MaxX) then begin
      stream^.FillChar(width - lineWidth, #0);
      if (not NoError(stream^.Error)) then exit;
    end;
    Inc(sy);
  end;
end;

procedure TSVga8Driver.WaitForVSync;
begin
  while (Port[$3DA] and 8) = 8 do;
  while (Port[$3DA] and 8) <> 8 do;
end;


destructor TSVga8Driver.Done;
begin
  TGraphicsDriver.Done;
end;

begin
end.