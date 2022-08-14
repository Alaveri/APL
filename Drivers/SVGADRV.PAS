{$I COMPILER.INC}
unit SVgaDrv;

interface

uses
  Objects,
  GraphDrv,
  Utils,
  StrUtils,
  Streams,
  Drawing;

type
  PVbeInfo = ^TVbeInfo;
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
  PSVgaMode = ^TSvgaMode;
  TSvgaMode = object(TGraphicsMode)
  private
    Attributes: word;
    Granularity: word;
    WinFuncPtr: pointer;
  public
    procedure Init; virtual;
    procedure Assign(var source: TPersistent); virtual;
    procedure AssignTo(var dest: TPersistent); virtual;
  end;
  PSVgaDriver = ^TSVgaDriver;
  TSVgaDriver = object(TGraphicsDriver)
  private
    _svgaDriver: integer;
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
    procedure DrawImage(x, y, width, height: integer; image: PByte); virtual;
    procedure DrawImageTransparent(x, y, width, height: integer; image: PByte); virtual;
    procedure DrawImageStream(x, y, width, height: integer; stream: PStream); virtual;
    procedure DrawImageStreamTransparent(x, y, width, height: integer; stream: PStream); virtual;
    procedure DrawImageBuffer(x, y, width, height: integer; image, buffer: PByte); virtual;
    procedure DrawImageBufferTransparent(x, y, width, height: integer; image, buffer: PByte); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Done; virtual;
  end;

implementation

uses
  Globals,
  Dos;

type
  PVbeMode = ^TVbeMode;
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


procedure TSvgaMode.Init;
begin
  inherited Init;
  Granularity := 0;
  Attributes := 0;
  WinFuncPtr := nil;
end;

procedure TSvgaMode.Assign(var source: TPersistent);
var
  mode: PSVgaMode;
begin
  TGraphicsMode.Assign(source);
  mode := PSVgaMode(@source);
  Attributes := mode^.Attributes;
  Granularity := mode^.Granularity;
  WinFuncPtr := mode^.WinFuncPtr;
end;

procedure TSvgaMode.AssignTo(var dest: TPersistent);
var
  mode: PSVgaMode;
begin
  TGraphicsMode.AssignTo(dest);
  mode := PSVgaMode(@dest);
  mode^.Attributes := Attributes;
  mode^.Granularity := Granularity;
  mode^.WinFuncPtr := WinFuncPtr;
end;

procedure TSVgaDriver.Init;
var
  newMode: PSvgaMode;
  oldMode: byte;
  info: TVbeInfo;
  segm, offs: word;
  supported, status: byte;
  modePtr: PWord;
  modeInfo: TVbeMode;
  vbeModeIndex: word;
  colors: string;
  index: integer;
  vbeMode: TVbeMode;
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
  index := 0;
  while modePtr^ <> $FFFF do begin
    newMode := New(PSVgaMode, Create);
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
      Description := NewLargeString('SVGA '
        + IntToStr(vbeMode.Width)
        + 'x'
        + IntToStr(vbeMode.Height)
        + ' ');
      case vbeMode.Bpp of
          4: colors := '16';
          8: colors := '256';
          15: colors := '32k';
          16: colors := '64k';
          32: colors := '16m';
      end;
      AppendStringToLarge(Description, colors + ' color');
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

function TSVgaDriver.GetPixel(x, y: integer): byte;
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

procedure TSVgaDriver.SetMode(newMode: PGraphicsMode);
var
  selectedMode: word;
  svgaMode: PSVgaMode;
begin
  svgaMode := PSVgaMode(pointer(newMode));
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
  if (Mode = nil) then Mode := New(PGraphicsMode, Create);
  Mode^.Assign(SvgaMode^);
  TGraphicsDriver.SetMode(newMode);
end;

procedure TSVgaDriver.SetBank(bank: word);
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

procedure TSVgaDriver.SetPixel(x, y: integer);
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

procedure TSVgaDriver.DrawText(x, y: integer; text: string);
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
  if (Font = nil) or (Length(text) = 0) then exit;
  maxX := Mode^.MaxX;
  maxY := Mode^.MaxY;
  pitch := Mode^.Pitch;
  fontData := Font^.FontData;
  sForeColor := State^.ForeColor;
  sBackColor := State^.BackColor;
  for charIndex := 1 to Length(text) do begin
    ch := text[charIndex];
    chWidth := Font^.TextWidth(ch);
    sy := y;
    sx := x + (charIndex - 1) * chWidth - 1;
    color := State^.ForeColor;
    chVal := Ord(ch);
    for yIndex := 0 to Font^.Height - 1 do begin
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


procedure TSVgaDriver.DrawTextLarge(x, y: integer; text: PChar);
begin
end;

procedure TSVgaDriver.MoveTo(x, y: integer);
begin
end;

procedure TSVgaDriver.LineTo(x, y: integer);
begin
end;

procedure TSVgaDriver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure TSVgaDriver.HLine(x, y, width: integer);
var
  offset: longint;
  ptr: PByte;
  index: word;
  partialWidth: word;
  ptrOffset: word;
  bank: word;
begin
  offset := x + longint(y) * Mode^.Pitch;
  ptr := Mode^.FrameBuffer;
  ptrOffset := offset and _granularity;
  Inc(ptr, ptrOffset);
  bank := offset shr 16;
  SetBank(bank);
  if (ptrOffset + width > _granularity) then begin
    partialWidth := _granularity - ptrOffset + 1;
    FillChar(ptr^, partialWidth, ForeColor);
    SetBank(bank + 1);
    ptr := Mode^.FrameBuffer;
    FillChar(ptr^, width - partialWidth, ForeColor);
  end
  else
    FillChar(ptr^, width, ForeColor);
end;

procedure TSVgaDriver.VLine(x, y, height: integer);
var
  index: integer;
  offset: longint;
  ptr: PByte;
  bank: word;
begin
  for index := y to y + height - 1 do begin
    offset := x + longint(index) * Mode^.Pitch;
    bank := offset shr 16;
    SetBank(bank);
    ptr := Mode^.FrameBuffer;
    Inc(ptr, offset);
    ptr^ := ForeColor;
  end;
end;

procedure TSVgaDriver.FillRect(rect: TRect);
var
  index: word;
begin
  for index := rect.Y to rect.Bottom do begin
    HLine(rect.X, index, rect.Width);
  end;
end;

procedure TSVgaDriver.DrawImage(x, y, width, height: integer; image: PByte);
var
  yIndex, sx, sy: integer;
  lineWidth, partialWidth: integer;
  xOffset: integer;
  screenPtr, imagePtr: PByte;
  offset, ptrOffset: longint;
  bank: word;
begin
  sy := y;
  xOffset := 0;
  if (x < 0) then begin
    xOffset := Abs(x);
  end;
  lineWidth := width - xOffset;
  lineWidth := MinL(lineWidth, Mode^.Width - x);
  imagePtr := image;
  sx := x + xOffset;
  for yIndex := 0 to height - 1 do begin
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    if (sy > Mode^.MaxY) then begin
      break;
    end;

    imagePtr := image;
    Inc(imagePtr, longint(yIndex) * width + xOffset);

    offset := sx + longint(sy) * Mode^.Pitch;
    screenPtr := Mode^.FrameBuffer;
    ptrOffset := offset and _granularity;
    Inc(screenPtr, ptrOffset);
    bank := offset shr 16;
    if (_currentBank <> bank) then SetBank(bank);

    if (ptrOffset + lineWidth > _granularity) then begin
      partialWidth := _granularity - ptrOffset + 1;
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

procedure TSVgaDriver.DrawImageTransparent(x, y, width, height: integer; image: PByte);
var
  xIndex, yIndex, sx, sy: integer;
  lineWidth, partialWidth: integer;
  xOffset: integer;
  screenPtr, imagePtr: PByte;
  offset, ptrOffset: longint;
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
  lineWidth := MinL(lineWidth, Mode^.Width - x);
  imagePtr := image;
  for yIndex := 0 to height - 1 do begin
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    if (sy > Mode^.MaxY) then begin
      break;
    end;

    imageLineOffset := longint(yIndex) * width;
    imagePtr := image;
    Inc(imagePtr, imageLineOffset + xOffset);

    offset := longint(sy) * Mode^.Pitch + x + xOffset;
    ptrOffset := offset and _granularity;
    bank := offset shr 16;
    SetBank(bank);

    screenPtr := Mode^.FrameBuffer;
    Inc(screenPtr, ptrOffset);

    sx := x + xOffset;
    lineRight := sx + lineWidth - 1;

    while (sx <= lineRight) do begin
      if (ptrOffset > _granularity) then begin
        SetBank(bank + 1);
        screenPtr := Mode^.Framebuffer;
      end;
      if (imagePtr^ <> transparentColor) then screenPtr^ := imagePtr^;
      Inc(screenPtr);
      Inc(sx);
      Inc(imagePtr);
    end;
    Inc(sy);
  end;
end;

procedure TSVgaDriver.DrawImageStream(x, y, width, height: integer; stream: PStream);
begin
end;

procedure TSVgaDriver.DrawImageStreamTransparent(x, y, width, height: integer; stream: PStream);
begin
end;

procedure TSVgaDriver.DrawImageBuffer(x, y, width, height: integer; image, buffer: PByte);
begin
end;

procedure TSVgaDriver.DrawImageBufferTransparent(x, y, width, height: integer; image, buffer: PByte);
begin
end;

procedure TSVgaDriver.GetImage(x, y, width, height: longint; buffer: PByte);
begin
end;

procedure TSVgaDriver.GetImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

{procedure TSvgaDriver.DrawImageBuffer(x, y, width, height: TRect; image, buffer: PByte);
var
  xIndex, yIndex, sx, sy: integer;
  offset: longint;
  ptr: PByte;
  bank, ptrOffset: word;
  sourceOffset: longint;
  partialWidth: longint;
  originalWidth: longint;
  lineStart: PByte;
  lineWidth: longint;
var 
  xIndex, yIndex: integer;
  offset: longint;
begin
  sx :=
  for yIndex := 0 to height - 1 do begin
    offset := sx + longint(sy) * Mode^.Pitch;
    ptr := Mode^.FrameBuffer;
    ptrOffset := offset and _granularity;
    Inc(ptr, ptrOffset);
    if (sourceOffset > 0) then Inc(image, sourceOffset);
    bank := offset shr 16;
    SetBank(bank);
    
  end;


  if (sourceRect.X < 0) then begin
    if (sourceRect.X + sourceRect.Width < 0) then exit;
    sourceOffset := Abs(sourceRect.X);
  end else begin
    sourceOffset := 0;
  end;
  originalWidth := sourceRect.Width;
  lineWidth := MinL(sourceRect.width, Mode^.MaxX - sourceRect.X) - sourceOffset;
  sy := sourceRect.Y;
  lineStart := image;
  for yIndex := 0 to sourceRect.Height - 1 do begin
    sx := sourceRect.X + sourceOffset;
    if (sy > Mode^.MaxY) then break;
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    offset := sx + longint(sy) * Mode^.Pitch;
    ptr := Mode^.FrameBuffer;
    ptrOffset := offset and _granularity;
    Inc(ptr, ptrOffset);
    if (sourceOffset > 0) then Inc(image, sourceOffset);
    bank := offset shr 16;
    SetBank(bank);
    if (ptrOffset + lineWidth > _granularity) then begin
      partialWidth := _granularity - ptrOffset + 1;
      Move(image^, ptr^, partialWidth);
      Inc(ptr, partialWidth);
      SetBank(bank + 1);
      ptr := Mode^.FrameBuffer;
      Move(image^, ptr^, lineWidth - partialWidth);
    end
    else begin
      Move(image^, ptr^, lineWidth);
    end;
    Inc(lineStart, originalWidth);
    image := lineStart;
    Inc(sy);
  end;
end;

procedure TSvgaDriver.DrawImageStream(x, y, width, height: integer; stream: PStream);
var
  xIndex, yIndex, sx, sy: integer;
  offset: longint;
  ptr: PByte;
  bank, ptrOffset: word;
  sourceOffset: longint;
  partialWidth: longint;
  lineStart, originalWidth: longint;
begin
  if (x < 0) then begin
    if (x + width < 0) then exit;
    sourceOffset := Abs(x);
  end else begin
    sourceOffset := 0;
  end;
  originalWidth := width;
  width := MinL(width, Mode^.MaxX - x) - sourceOffset;
  sy := y;
  for yIndex := 0 to height - 1 do begin
    sx := x + sourceOffset;
    if (sy > Mode^.MaxY) then break;
    if (sy < 0) then begin
      Inc(sy);
      continue;
    end;
    lineStart := stream^.Position;
    offset := sx + longint(sy) * Mode^.Pitch;
    ptr := Mode^.FrameBuffer;
    ptrOffset := offset and _granularity;
    Inc(ptr, ptrOffset);
    if (sourceOffset > 0) then stream^.Seek(sourceOffset, soFromPosition);
    bank := offset shr 16;
    SetBank(bank);
    if (ptrOffset + width > _granularity) then begin
      partialWidth := _granularity - ptrOffset + 1;
      stream^.Read(ptr, partialWidth);
      SetBank(bank + 1);
      ptr := Mode^.FrameBuffer;
      stream^.Read(ptr, width - partialWidth);
    end
    else begin
      stream^.Read(ptr, width);
    end;
    Inc(lineStart, originalWidth);
    stream^.Seek(lineStart, soFromBeginning);
    Inc(sy);
  end;
end;

procedure TSvgaDriver.DrawImageStreamRect(rect: TRect; stream: PStream);
begin
  DrawImageStream(rect.X, rect.Y, rect.Width, rect.Height, stream);
end;

procedure TSvgaDriver.DrawImage(x, y, width, height: integer; image: PByte);
var
  sourceRect, destRect: TRect;
begin
  destRect.CreateDims(x, y, width, height);
  sourceRect.CreateDims(0, 0, width, height);
  DrawImageBuffer(sourceRect, destRect, image, Mode^.FrameBuffer);
end;

procedure TSvgaDriver.DrawImageRect(rect: TRect; image: PByte);
var
  sourceRect: TRect;
begin
  sourceRect.CreateDims(0, 0, rect.Width, rect.Height);
  DrawImageBuffer(sourceRect, rect, image, Mode^.FrameBuffer);
end;

procedure TSvgaDriver.GetImageStream(x, y, width, height: longint; stream: PStream);
var
  yIndex, maxX, maxY: integer;
  offset: longint;
  pitch: word;
  bank: word;
  ptr: PByte;
  destOffset: longint;
  lineStart: longint;
  ptrOffset, partialWidth, originalWidth: longint;
  frameBuffer: PByte;
begin
  pitch := Mode^.Pitch;
  maxX := Mode^.MaxX;
  maxY := Mode^.MaxY;
  frameBuffer := Mode^.FrameBuffer;
  originalWidth := width;
  width := MinL(width, Mode^.MaxX - x) - destOffset;
  for yIndex := y to y + height - 1 do begin
    offset := x + longint(yIndex) * pitch;
    ptr := frameBuffer;
    ptrOffset := offset and _granularity;
    Inc(ptr, ptrOffset);
    bank := offset shr 16;
    lineStart := stream^.Position;
    if (bank <> _currentBank) then
      SetBank(bank);
    if (ptrOffset + width > _granularity) then begin
      partialWidth := _granularity - ptrOffset + 1;
      if (y < 0) or (y > maxY) then begin
        stream^.FillChar(width, #0);
      end else begin
        stream^.Write(ptr, partialWidth);
        SetBank(bank + 1);
        ptr := frameBuffer;
        stream^.Write(ptr, width - partialWidth);
      end;
    end
    else begin
      if (y < 0) or (y > maxY) then begin
        stream^.FillChar(width, #0);
      end else begin
        stream^.Write(ptr, width);
      end;
    end;
    Inc(lineStart, originalWidth);
    stream^.Seek(lineStart, soFromBeginning);
  end;
end;

procedure TSvgaDriver.GetImageStreamRect(rect: TRect; stream: PStream);
begin
  GetImageStream(rect.X, rect.Y, rect.Width, rect.Height, stream);
end;

procedure TSvgaDriver.GetImage(x, y, width, height: longint; buffer: PByte);
var
  yIndex, maxX, maxY: integer;
  offset: longint;
  pitch: word;
  bank: word;
  ptr: PByte;
  ptrOffset, partialWidth, originalWidth: longint;
  lineStart: PByte;
  frameBuffer: PByte;
begin
  pitch := Mode^.Pitch;
  maxX := Mode^.MaxX;
  maxY := Mode^.MaxY;
  frameBuffer := Mode^.FrameBuffer;
  originalWidth := width;
  width := MinL(width, Mode^.MaxX - x);
  lineStart := buffer;
  for yIndex := y to y + height - 1 do begin
    offset := x + longint(yIndex) * pitch;
    ptr := frameBuffer;
    ptrOffset := offset and _granularity;
    Inc(ptr, ptrOffset);
    bank := offset shr 16;
    if (bank <> _currentBank) then
      SetBank(bank);
    if (ptrOffset + width > _granularity) then begin
      partialWidth := _granularity - ptrOffset + 1;
      if (y < 0) or (y > maxY) then begin
        FillChar(buffer^, width, #0);
        Inc(buffer, width);
      end else begin
        Move(ptr^, buffer^, partialWidth);
        Inc(buffer, partialWidth);
        SetBank(bank + 1);
        ptr := frameBuffer;
        Move(ptr^, buffer^, width - partialWidth);
        Inc(buffer, width - partialWidth);
      end;
    end
    else begin
      if (y < 0) or (y > maxY) then begin
        FillChar(ptr^, width, #0);
      end else begin
        Move(ptr^, buffer^, width);
      end;
    end;
    Inc(lineStart, originalWidth);
    buffer := lineStart;
  end;
end;

procedure TSvgaDriver.GetImageRect(rect: TRect; buffer: PByte);
begin
  GetImage(rect.X, rect.Y, rect.Width, rect.Height, buffer);
end;}

procedure TSvgaDriver.WaitForVSync;
begin
  while (Port[$3DA] and 8) = 8 do;
  while (Port[$3DA] and 8) <> 8 do;
end;


destructor TSVgaDriver.Done;
begin
  TGraphicsDriver.Done;
end;

begin
end.