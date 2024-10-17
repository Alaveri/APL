{$I COMPILER.INC}
unit GraphDrv;

interface

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  AplObj,
  AplTypes,
  Errors,
  Common,
  Streams,
  Drawing,
  Lists,
  AplConst,
  StrUtils,
  Palettes,
  MemDrv;

const
  FontMajorVersion = 1;
  FontMinorVersion = 0;

type
  PGraphicsMode = ^TGraphicsMode;
  PGraphicsDriver = ^TGraphicsDriver;
  PGraphicsModeList = ^TGraphicsModeList;
  PFont = ^TFont;
  PFontList = ^TFontList;
  PGraphicsState = ^TGraphicsState;
  PSystemFont = ^TSystemFont;
  PMonospaceFont = ^TMonospaceFont;
  PProportionalFont = ^TProportionalFont;
  PColoredFont = ^TColoredFont;
  PFontFormats = ^TFontFormats;
  PGraphicsModeListProc = ^TGraphicsModeListProc;
  PFontListProc = ^TFontListProc;

  TFontWidthArray = array[byte] of word;
  TFontCompression = (fcNone, fcLzw);
  TFontFormat = (ffProportional, ffMonospace, ffSystem, ffColored, ff1Bpp, ff2Bpp, ff4Bpp, ff8Bpp);
  TFontFormats = set of TFontFormat;
  TGraphicsModeListProc = procedure(ASender: PGraphicsModeList; AMode: PGraphicsMode);
  TFontListProc = procedure(ASender: PFontList; AFont: PFont);

  TGraphicsMode = object(TIdentifiable)
  private
  public
    Description: PChar;
    Width, Height: integer;
    MaxX, MaxY: integer;
    Bounds: TRect;
    Bpp: byte;
    HelpText: PChar;
    ModeIndex: word;
    BytesPerScanLine: word;
    FrameBuffer: pointer;
    NumPages: byte;
    ModeId: integer;
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TGraphicsModeList = object(TIdentifiableList)
  public
    function GetItemById(const AID: string): PGraphicsMode;
    function GetItem(AIndex: integer): PGraphicsMode;
    function GetModeById(AModeID: integer): PGraphicsMode;
    function Add(AItem: PGraphicsMode): integer;
    function IndexOf(AItem: PGraphicsMode): integer;
    procedure ForEach(AProc: PGraphicsModeListProc);
    procedure SetItem(AIndex: integer; AItem: PGraphicsMode);
    procedure Insert(AIndex: integer; AItem: PGraphicsMode);
  end;

  TFontHeader = record
    MajorVersion: integer;
    MinorVersion: integer;
    Name: string[50];
    DataSize: longint;
    MaxWidth: byte;
    Height: byte;
    Compression: TFontCompression;
    Spacing: byte;
    Format: word;
    Reserved: array[0..252] of byte;
  end;

  TFont = object(TStatusObject)
  private
    FFontData: PWord;
    FFontDataSize: word;
  public
    Version: real;
    TransparentColor: longint;
    Transparent: boolean;
    Height: byte;
    MaxWidth: byte;
    AverageWidth: integer;
    Spacing: byte;
    destructor Free; virtual;
    constructor CreateSize(AMaxWidth, AHeight: byte);
    constructor CreateLoadStream(AStream: PStream);
    constructor CreateLoadFile(const AFilename: string);
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
    procedure SetPixel(AChar: char; APX, APY: integer); virtual;
    procedure ClearPixel(AChar: char; APX, APY: integer); virtual;
    procedure SaveToStream(AStream: PStream); virtual;
    procedure SaveToFile(const AFilename: string); virtual;
    procedure LoadFromStream(AStream: PStream); virtual;
    procedure LoadFromFile(const AFilename: string); virtual;
    procedure SetCharWidths; virtual;
    function FontFormatsToWord(AFormat: TFontFormats): word;
    function Format: word; virtual;
    function IsPixelSet(AChar: char; APX, APY: integer): boolean; virtual;
    function CharWidth(AChar: char): integer; virtual;
    function TextWidthAny(AText: PChar; ALength: word): longint; virtual;
    function TextWidth(const AText: string): longint; virtual;
    function TextWidthLarge(AText: PChar): longint; virtual;
    function FontData: PWord; virtual;
    function FontDataSize: word; virtual;
  end;

  TMonospaceFont = object(TFont)
  private
  public
    function Format: word; virtual;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    destructor Free; virtual;
  end;

  TProportionalFont = object(TFont)
  private
  public
    CharWidths: TByteArray;
    constructor CreateSize(AMaxWidth, AHeight: byte);
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure SaveToStream(AStream: PStream); virtual;
    procedure SaveToFile(const AFilename: string); virtual;
    procedure LoadFromStream(AStream: PStream); virtual;
    procedure LoadFromFile(const AFilename: string); virtual;
    procedure SetCharWidths; virtual;
    function TextWidthAny(AText: PChar; ALength: word): longint; virtual;
    function CharWidth(AChar: char): integer; virtual;
    function Format: word; virtual;
    destructor Free; virtual;
  end;

  TColoredFont = object(TProportionalFont)
  private
  public
    StartChar: byte;
    EndChar: byte;
    constructor CreateSize(AMaxWidth, AHeight: byte);
    function Format: word; virtual;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    destructor Free; virtual;
  end;

  TSystemFont = object(TMonospaceFont)
  private
  public
    function CharWidth(AChar: char): integer; virtual;
    function TextWidthAny(AText: PChar; ALength: word): longint; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TGraphicsState = object(TObject)
  private
  public
    ForeColor: longint;
    BackColor: longint;
    XPos, YPos: integer;
    Font: PFont;
    ViewPort: TRect;
    FrameBuffer: PByte;
    BufferMode: boolean;
    FontColor: TStandardColor;
    FontShade: byte;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TGraphicsDriver = object(TStatusObject)
  private
    FOldMode: byte;
  public
    State: TGraphicsState;
    StateStack: TObjectStack;
    Modes: TGraphicsModeList;
    Mode: PGraphicsMode;
    function GetPixel(APX, APY: integer): byte; virtual;
    function ForeColor: longint; virtual;
    function BackColor: longint; virtual;
    function XPos: byte; virtual;
    function YPos: byte; virtual;
    function GetScreenPointer(APX, APY: integer; var AOffset: longint): PByte; virtual;
    function GetBufferPointer(APX, APY: integer; var AOffset: longint): PByte; virtual;
    function GetDrawPointer(APX, APY: integer; var AOffset: longint): PByte;
    procedure BeginDrawBuffer(var ABuffer: PByte; var ABounds: TRect); virtual;
    procedure GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageRect(ARect: TRect; ABuffer: PByte); virtual;
    procedure GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure GetImageStreamRect(ARect: TRect; AStream: PStream); virtual;
    procedure SetForeColor(AColor: longint); virtual;
    procedure SetBackColor(AColor: longint); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure SetPixel(APX, APY: integer); virtual;
    procedure FastSetPixel(APX, APY: integer); virtual;
    procedure MoveTo(APX, APY: integer); virtual;
    procedure LineTo(APX, APY: integer); virtual;
    procedure Line(AX1, AY1, AX2, AY2: integer); virtual;
    procedure HLine(APX, APY, AWidth: integer); virtual;
    procedure VLine(APX, APY, AHeight: integer); virtual;
    procedure Rectangle(ARect: TRect); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure BezierQuad(AP1: TPoint; AP2: TPoint; AControl: TPoint; AResolution: integer);
    procedure BezierCubic(AP1: TPoint; AP2: TPoint; AControl1: TPoint; AControl2: TPoint; AResolution: integer);
    procedure Ellipse(AX1, AY1, AX2, AY2: integer); virtual;
    procedure EllipseRect(ARect: TRect); virtual;
    procedure EllipsePoints(AP1, AP2: TPoint); virtual;
    procedure EllipseCenter(APX, APY, ARadiusX, ARadiusY: integer); virtual;
    procedure Circle(ACenterX, ACenterY, ARadius: integer); virtual;
    procedure FastFillScreen(AColor: byte); virtual;
    procedure FastDrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure RenderText(APX, APY, ALength: integer; AText: PChar); virtual;
    procedure DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageRect(ARect: TRect; AImage: PByte); virtual;
    procedure DrawImageRectT(ARect: TRect; AImage: PByte); virtual;
    procedure DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamRect(ARect: TRect; AStream: PStream); virtual;
    procedure DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamRectT(ARect: TRect; AStream: PStream); virtual;
    procedure DrawImageStreamSection(ASourceRect: TRect; ADestX, ADestY: integer); virtual;
    procedure DrawImageStreamSectionT(ASourceRect: TRect; ADestX, ADestY: integer); virtual;
    procedure DrawText(APX, APY: integer; AText: string); virtual;
    procedure DrawTextLarge(APX, APY: integer; AText: PChar); virtual;
    procedure GetDrawRect(var ARect: TRect); virtual;
    procedure GetImageDrawRects(APX, APY, AWidth, AHeight: longint;
      var AImageRect, ADrawRect: TRect); virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure EndDrawBuffer; virtual;
    procedure Init; virtual;
    procedure WaitForVSync; virtual;
    procedure ResetMode; virtual;
    procedure GetFontFormats(AFont: PFont; var AFormats: TFontFormats);
    destructor Free; virtual;
  end;

  TFontList = Object(TIdentifiableList)
  public
    function GetItemById(const AId: string): PFont;
    function GetItem(AIndex: integer): PFont;
    function Add(AItem: PFont): integer;
    function IndexOf(AItem: PFont): integer;
    procedure ForEach(AProc: PFontListProc);
    procedure SetItem(AIndex: integer; AItem: PFont);
    procedure Insert(AIndex: integer; AItem: PFont);
  end;

var
  Graph: PGraphicsDriver;

implementation

uses
  Compress,
  Lzw;
var
  PreviousExitProc: PProc;

procedure TGraphicsDriver.Init;
var
  oldMode: byte;
begin
  inherited Init;
  asm
    mov ah, 0Fh
    int 10h
    mov oldMode, al
  end;
  FOldMode := oldMode;
  Modes.Create;
  Mode := nil;
  State.Create;
  StateStack.Create;
  MoveTo(0, 0);
end;

procedure TGraphicsDriver.RenderText(APX, APY, ALength: integer; AText: PChar);
begin
end;

function TGraphicsDriver.GetScreenPointer(APX, APY: integer; var AOffset: longint): PByte;
begin
end;

procedure TGraphicsDriver.FastFillScreen(AColor: byte);
begin
end;

procedure TGraphicsDriver.FastDrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TGraphicsDriver.FastSetPixel(APX, APY: integer);
begin
end;

function TGraphicsDriver.GetBufferPointer(APX, APY: integer; var AOffset: longint): PByte;
var
  screen: PByte;
begin
  screen := State.FrameBuffer;
  AOffset := longint(APY) * State.ViewPort.Width + APX;
  Inc(screen, AOffset);
  GetBufferPointer := screen;
end;

function TGraphicsDriver.GetDrawPointer(APX, APY: integer; var AOffset: longint): PByte;
begin
  if State.BufferMode then
    GetDrawPointer := GetBufferPointer(APX, APY, AOffset)
  else
    GetDrawPointer := GetScreenPointer(APX, APY, AOffset);
end;

function TGraphicsDriver.ForeColor: longint;
begin
  ForeColor := State.ForeColor;
end;

function TGraphicsDriver.BackColor: longint;
begin
  BackColor := State.BackColor;
end;

function TGraphicsDriver.XPos: byte;
begin
  XPos := State.XPos;
end;

function TGraphicsDriver.YPos: byte;
begin
  YPos := State.YPos;
end;

procedure TGraphicsDriver.SetForeColor(AColor: longint);
begin
  State.ForeColor := AColor;
end;

procedure TGraphicsDriver.SetBackColor(AColor: longint);
begin
  State.BackColor := AColor;
end;

procedure TGraphicsDriver.ResetMode;
var
  oldMode: byte;
begin
  oldMode := FOldMode;
  asm
    mov ah, 0
    mov al, [oldMode]
    int 10h
  end;
end;

procedure TGraphicsDriver.GetFontFormats(AFont: PFont; var AFormats: TFontFormats);
var
  formatByte: byte;
begin
  formatByte := State.Font^.Format;
  AFormats := PFontFormats(@formatByte)^;
end;

procedure TGraphicsDriver.GetDrawRect(var ARect: TRect);
begin
  Mode^.Bounds.GetIntersection(State.ViewPort, ARect);
end;

function TGraphicsDriver.GetPixel(APX, APY: integer): byte;
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  GetPixel := 0;
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if not drawRect.Contains(APX, APY) then
    exit;
  ptr := GetDrawPointer(APX, APY, offset);
  GetPixel := ptr^;
end;

procedure TGraphicsDriver.SetPixel(APX, APY: integer);
var
  offset: longint;
  ptr: PByte;
  drawRect: TRect;
begin
  Mode^.Bounds.GetIntersection(State.ViewPort, drawRect);
  if not drawRect.Contains(APX, APY) then
    exit;
  ptr := GetDrawPointer(APX, APY, offset);
  ptr^ := ForeColor;
end;

procedure TGraphicsDriver.SetMode(AMode: PGraphicsMode);
begin
  Mode := AMode;
  State.ViewPort.SetDims(0, 0, Mode^.Width, Mode^.Height);
  Mode^.Bounds.SetRect(State.ViewPort);
end;

procedure TGraphicsDriver.MoveTo(APX, APY: integer);
begin
  State.XPos := APX;
  State.YPos := APY;
end;

procedure TGraphicsDriver.LineTo(APX, APY: integer);
begin
  Line(State.XPos, State.YPos, APX, APY);
  State.XPos := APX;
  State.YPos := APY;
end;

procedure TGraphicsDriver.Line(AX1, AY1, AX2, AY2: integer);
begin
end;

procedure TGraphicsDriver.Rectangle(ARect: TRect);
begin
  HLine(ARect.X, ARect.Y, ARect.Width);
  HLine(ARect.X, ARect.Bottom, ARect.Width);
  VLine(ARect.X, ARect.Y, ARect.Height);
  VLine(ARect.Right, ARect.Y, ARect.Height);
end;

procedure TGraphicsDriver.HLine(APX, APY, AWidth: integer);
begin
end;

procedure TGraphicsDriver.VLine(APX, APY, AHeight: integer);
begin
end;

procedure TGraphicsDriver.FillRect(ARect: TRect);
var
  index: integer;
  tempColor: longint;
  rect: PRect;
begin
  tempColor := State.ForeColor;
  State.ForeColor := State.BackColor;
  if ARect.IsEmpty then
    exit;
  ARect.Intersect(State.ViewPort);
  for index := ARect.Y to ARect.Bottom do
    HLine(ARect.X, index, ARect.Width);
  State.ForeColor := tempColor;
end;

procedure TGraphicsDriver.BezierQuad(AP1: TPoint; AP2: TPoint; AControl: TPoint; AResolution: integer);
var
  v1, v2, v3: TVector2;
  previous, next: TVector2;
  value: integer;
  index: integer;
begin
  v1.CreatePoint(AP1);
  v2.CreatePoint(AControl);
  v3.CreatePoint(AP2);
  previous.CreateVector(v1);
  for index := 1 to AResolution do begin
    BezierInterpolationQuad(v1, v2, v3, index / AResolution, next);
    Line(Round(previous.X), Round(previous.Y), Round(next.X), round(next.Y));
    previous.Assign(next);
  end;
end;

procedure TGraphicsDriver.BezierCubic(AP1: TPoint; AP2: TPoint; AControl1: TPoint; AControl2: TPoint; AResolution: integer);
var
  v1, v2, v3, v4: TVector2;
  previous, next: TVector2;
  value: integer;
  index: integer;
begin
  v1.CreatePoint(AP1);
  v2.CreatePoint(AControl1);
  v3.CreatePoint(AControl2);
  v4.CreatePoint(AP2);
  previous.CreateVector(v1);
  for index := 1 to AResolution do begin
    BezierInterpolationCubic(v1, v2, v3, v4, index / AResolution, next);
    Line(Round(previous.X), Round(previous.Y), Round(next.X), round(next.Y));
    previous.Assign(next);
  end;
end;

procedure TGraphicsDriver.Ellipse(AX1, AY1, AX2, AY2: integer);
var
  halfX, halfY: integer;
begin
  if AX1 > AX2 then
    Swap(AX1, AX2);
  if AY1 > AY2 then
    Swap(AY1, AY2);
  halfX := (AX2 - AX1) div 2;
  halfY := (AY2 - AY1) div 2;
  EllipseCenter(AX1 + halfX, AY1 + halfY, halfX, halfY);
end;

procedure TGraphicsDriver.EllipseRect(ARect: TRect);
begin
  Ellipse(ARect.X, ARect.Y, ARect.Right, ARect.Bottom);
end;

procedure TGraphicsDriver.EllipsePoints(AP1, AP2: TPoint);
begin
  Ellipse(AP1.X, AP1.Y, AP2.X, AP2.Y);
end;

procedure TGraphicsDriver.EllipseCenter(APX, APY, ARadiusX, ARadiusY: integer);
var
  x, y: longint;
  dx, dY: longint;
  error: longint;
  twoASquared, twoBSquared : longint;
  stopX, stopY : longint;
begin
  if (ARadiusX = 0) or (ARadiusY = 0) then
    exit;
  twoASquared := 2 * longint(ARadiusX) * ARadiusX;
  twoBSquared := 2 * longint(ARadiusY) * ARadiusY;
  x := ARadiusX;
  y := 0;
  dx := longint(ARadiusY) * ARadiusY * (1 - 2 * longint(ARadiusX));
  dy := longint(ARadiusX) * ARadiusX;
  error := 0;
  stopX := twoBSquared * ARadiusX;
  stopY := 0;
  while stopX >= stopy do begin
    SetPixel(APX + x, APY + y);
    SetPixel(APX - x, APY + y);
    SetPixel(APX - x, APY - y);
    SetPixel(APX + x, APY - y);
    Inc(y);
    Inc(stopY, twoASquared);
    Inc(error, dy);
    Inc(dy, twoASquared);
    if 2 * error + dx > 0 then begin
      Dec(x);
      Dec(stopX, twoBSquared);
      Inc(error, dx);
      Inc(dx, twoBSquared);
    end;
  end;
  X := 0;
  Y := ARadiusY;
  dx := longint(ARadiusY) * ARadiusY;
  dy := longint(ARadiusX) * ARadiusX * (1 - 2 * longint(ARadiusY));
  error := 0;
  stopX := 0;
  stopY := twoASquared * ARadiusY;
  while stopX <= stopY do begin
    SetPixel(APX + x, APY + y);
    SetPixel(APX - x, APY + y);
    SetPixel(APX - x, APY - y);
    SetPixel(APX + x, APY - y);
    Inc(X);
    Inc(stopX, twoBSquared);
    Inc(error, dx);
    Inc(dx, twoBSquared);
    if 2 * error + dy > 0 then begin
      Dec(Y);
      Dec(stopY, twoASquared);
      Inc(error, dy);
      Inc(dy, twoASquared);
    end;
  end;
end;

procedure TGraphicsDriver.Circle(ACenterX, ACenterY, ARadius: integer);
var
  t1, t2: integer;
  x, y: integer;
begin
  t1 := ARadius div 16;
  x := ARadius;
  y := 0;
  repeat
    SetPixel(ACenterX + x, ACenterY + y);
    SetPixel(ACenterX - x, ACenterY + y);
    SetPixel(ACenterX + x, ACenterY - y);
    SetPixel(ACenterX - x, ACenterY - y);
    SetPixel(ACenterX + y, ACenterY + x);
    SetPixel(ACenterX - y, ACenterY + x);
    SetPixel(ACenterX + y, ACenterY - x);
    SetPixel(ACenterX - y, ACenterY - x);
    Inc(y);
    t1 := t1 + y;
    t2 := t1 - x;
    if t2 >= 0 then begin
      t1 := t2;
      Dec(x);
    end;
  until x < y;
end;

procedure TGraphicsDriver.DrawText(APX, APY: integer; AText: string);
var
  ptr: PChar;
begin
  if not Assigned(State.Font) then
    exit;
  if Length(AText) = 0 then
    exit;
  ptr := @AText[1];
  RenderText(APX, APY, Length(AText), ptr);
end;

procedure TGraphicsDriver.DrawTextLarge(APX, APY: integer; AText: PChar);
var
  len: word;
begin
  if not Assigned(State.Font) then
    exit;
  if not Assigned(AText) then
    exit;
  len := StrLen(AText);
  if len = 0 then
    exit;
  RenderText(APX, APY, len, AText);
end;

procedure TGraphicsDriver.GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte);
begin
end;

procedure TGraphicsDriver.GetImageRect(ARect: TRect; ABuffer: PByte);
begin
  GetImage(ARect.X, ARect.Y, ARect.Width, ARect.Height, ABuffer);
end;

procedure TGraphicsDriver.GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream);
begin
end;

procedure TGraphicsDriver.GetImageStreamRect(ARect: TRect; AStream: PStream);
begin
  GetImageStream(ARect.X, ARect.Y, ARect.Width, ARect.Height, AStream);
end;

procedure TGraphicsDriver.DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TGraphicsDriver.DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TGraphicsDriver.DrawImageRectT(ARect: TRect; AImage: PByte);
begin
  DrawImageT(ARect.X, ARect.Y, ARect.Width, ARect.Height, AImage);
end;

procedure TGraphicsDriver.DrawImageRect(ARect: TRect; AImage: PByte);
begin
  DrawImage(ARect.X, ARect.Y, ARect.Width, ARect.Height, AImage);
end;

procedure TGraphicsDriver.DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TGraphicsDriver.DrawImageStreamRect(ARect: TRect; AStream: PStream);
begin
  DrawImageStream(ARect.X, ARect.Y, ARect.Width, ARect.Height, AStream);
end;

procedure TGraphicsDriver.DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TGraphicsDriver.DrawImageStreamRectT(ARect: TRect; AStream: PStream);
begin
  DrawImageStreamT(ARect.X, ARect.Y, ARect.Width, ARect.Height, AStream);
end;

procedure TGraphicsDriver.DrawImageStreamSection(ASourceRect: TRect; ADestX, ADestY: integer);
begin
end;

procedure TGraphicsDriver.DrawImageStreamSectionT(ASourceRect: TRect; ADestX, ADestY: integer);
begin
end;

procedure TGraphicsDriver.GetImageDrawRects(APX, APY, AWidth, AHeight: longint;
  var AImageRect, ADrawRect: TRect);
begin
  AImageRect.CreateDims(APX, APY, AWidth, AHeight);
  Mode^.Bounds.GetIntersection(State.ViewPort, ADrawRect);
  ADrawRect.Intersect(AImageRect);
  AImageRect.X := ADrawRect.X - AImageRect.X;
  AImageRect.Y := ADrawRect.Y - AImageRect.Y;
end;

procedure TGraphicsDriver.PushState;
var
  newState: PGraphicsState;
begin
  newState := New(PGraphicsState, Create);
  newState^.Assign(State);
  StateStack.Push(newState);
end;

procedure TGraphicsDriver.BeginDrawBuffer(var ABuffer: PByte; var ABounds: TRect);
var
  size: word;
begin
  size := ABounds.Width * ABounds.Height;
  GetMem(ABuffer, size);
  if not Assigned(ABuffer) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  ABounds.TranslateToOrigin;
  State.FrameBuffer := ABuffer;
  State.ViewPort.Assign(ABounds);
  State.BufferMode := true;
end;

procedure TGraphicsDriver.EndDrawBuffer;
begin
  State.BufferMode := false;
  State.FrameBuffer := Mode^.FrameBuffer;
end;

procedure TGraphicsDriver.PopState;
var
  oldState: PGraphicsState;
begin
  oldState := PGraphicsState(StateStack.Pop);
  if not Assigned(oldState) then
    exit;
  State.Assign(oldState^);
  FreeAndNil(oldState);
end;

destructor TGraphicsDriver.Free;
begin
  ResetMode;
  Modes.Free;
  State.Free;
  StateStack.DisposeObjects := true;
  StateStack.Free;
  inherited Free;
end;

procedure TGraphicsDriver.WaitForVSync;
begin
end;

procedure TGraphicsMode.Init;
begin
  inherited Init;
  ModeId := 0;
  Width := 0;
  Height := 0;
  MaxX := 0;
  MaxY := 0;
  Bpp := 0;
  NumPages := 1;
  Bounds.Create;
  ModeIndex := 0;
  BytesPerScanLine := 0;
  HelpText := nil;
  Description := nil;
  FrameBuffer := nil;
  HelpText := nil;
end;

destructor TGraphicsMode.Free;
begin
  TString.Free(HelpText);
  TString.Free(Description);
  inherited Free;
end;

procedure TGraphicsMode.Assign(var ASource: TObject);
var
  mode: PGraphicsMode;
begin
  inherited Assign(ASource);
  mode := PGraphicsMode(@ASource);
  Width := mode^.Width;
  Height := mode^.Height;
  NumPages := mode^.NumPages;
  MaxX := mode^.MaxX;
  MaxY := mode^.MaxY;
  Bounds.SetRect(mode^.Bounds);
  Bpp := mode^.Bpp;
  ModeIndex := mode^.ModeIndex;
  TString.Free(Description);
  TString.Free(HelpText);
  Description := TString.Copy(mode^.Description);
  HelpText:= TString.Copy(mode^.HelpText);
  BytesPerScanLine := mode^.BytesPerScanLine;
  FrameBuffer := mode^.FrameBuffer;
end;

function TGraphicsModeList.GetItem(AIndex: integer): PGraphicsMode;
begin
  GetItem := PGraphicsMode(inherited GetItem(AIndex));
end;

function TGraphicsModeList.GetItemById(const AID: string): PGraphicsMode;
begin
  GetItemById := PGraphicsMode(inherited GetItemById(AId));
end;

function TGraphicsModeList.GetModeById(AModeId: integer): PGraphicsMode;
var
  index: integer;
  mode: PGraphicsMode;
begin
  GetModeById := nil;
  for index := 0 to Count - 1 do begin
    mode := GetItem(index);
    if mode^.ModeId = AModeId then begin
      GetModeById := mode;
      exit;
    end;
  end;
end;

function TGraphicsModeList.Add(AItem: PGraphicsMode): integer;
begin
  Add := inherited Add(AItem);
end;

function TGraphicsModeList.IndexOf(AItem: PGraphicsMode): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TGraphicsModeList.ForEach(AProc: PGraphicsModeListProc);
begin
  TList.ForEach(PListProc(AProc));
end;

procedure TGraphicsModeList.SetItem(AIndex: integer; AItem: PGraphicsMode);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TGraphicsModeList.Insert(AIndex: integer; AItem: PGraphicsMode);
begin
  inherited Insert(AIndex, AItem);
end;

destructor TFont.Free;
begin
  if Assigned(FFontData) then
    FreeMem(FFontData, FFontDataSize);
  inherited Free;
end;

procedure TFont.Assign(var ASource: TObject);
var
  source: PFont;
begin
  inherited Assign(ASource);
  source := PFont(@ASource);
  Version := source^.Version;
  TransparentColor := source^.TransparentColor;
  Transparent := source^.Transparent;
  Height := source^.Height;
  MaxWidth := source^.MaxWidth;
  if Assigned(FFontData) then
    FreeMem(FFontData, FFontDataSize);
  FFontDataSize := source^.FFontDataSize;
  GetMem(FFontData, source^.FFontDataSize);
  Move(source^.FFontData^, FFontData^, source^.FFontDataSize);
end;

procedure TFont.Init;
begin
  inherited Init;
  Version := 1.0;
  TransparentColor := 0;
  Transparent := true;
  Height := 0;
  AverageWidth := 0;
  MaxWidth := 0;
  FFontData := nil;
  FFontDataSize := 0;
  Spacing := 2;
end;

constructor TFont.CreateSize(AMaxWidth, AHeight: byte);
begin
  inherited Create;
  MaxWidth := AMaxWidth;
  Height := AHeight;
end;

function TFont.CharWidth(AChar: char): integer;
begin
end;

function TFont.TextWidthAny(AText: PChar; ALength: word): longint;
begin
end;

function TFont.TextWidth(const AText: string): longint;
var
  textPtr: PChar;
begin
  TextWidth := 0;
  if Length(AText) = 0 then
    exit;
  textPtr := @AText[1];
  TextWidth := TextWidthAny(textPtr, Length(AText));
end;

function TFont.TextWidthLarge(AText: PChar): longint;
begin
  TextWidthLarge := TextWidthAny(AText, StrLen(AText));
end;

function TFont.FontData: PWord;
begin
  FontData := FFontData;
end;

function TFont.FontDataSize: word;
begin
  FontDataSize := FFontDataSize;
end;

function TFont.Format: word;
begin
  Abstract;
end;

procedure TFont.SetCharWidths;
begin
end;

function TFont.FontFormatsToWord(AFormat: TFontFormats): word;
var
  result: byte;
begin
  result := PByte(@AFormat)^;
  FontFormatsToWord := result;
end;

constructor TFont.CreateLoadStream(AStream: PStream);
begin
  inherited Create;
  LoadFromStream(AStream);
end;

constructor TFont.CreateLoadFile(const AFilename: string);
begin
  inherited Create;
  LoadFromFile(AFilename);
end;

procedure TFont.SaveToStream(AStream: PStream);
begin
end;

procedure TFont.SaveToFile(const AFilename: string);
begin
end;

procedure TFont.LoadFromStream(AStream: PStream);
begin
end;

procedure TFont.LoadFromFile(const AFilename: string);
begin
end;

function TFont.IsPixelSet(AChar: char; APX, APY: integer): boolean;
var
  ptr: PWord;
  px, currentLine: word;
begin
  ptr := FontData;
  Inc(ptr, Ord(AChar) * Height + APY);
  currentLine := ptr^;
  px := word(1) shl (15 - APX);
  IsPixelSet := currentLine and px > 0;
end;

procedure TFont.SetPixel(AChar: char; APX, APY: integer);
var
  ptr: PWord;
  px, currentLine: word;
begin
  ptr := FontData;
  Inc(ptr, Ord(AChar) * Height + APY);
  currentLine := ptr^;
  px := word(1) shl (15 - APX);
  if currentLine and px > 0 then
    exit;
  ptr^ := currentLine or px;
end;

procedure TFont.ClearPixel(AChar: char; APX, APY: integer);
var
  ptr: PWord;
  px, currentLine: word;
begin
  ptr := FontData;
  Inc(ptr, Ord(AChar) * Height + APY);
  currentLine := ptr^;
  px := word(1) shl (15 - APX);
  if currentLine and px = 0 then
    exit;
  ptr^ := currentLine and not px;
end;

procedure TMonospaceFont.Init;
begin
  inherited Init;
  MaxWidth := 8;
  AverageWidth := 8;
end;

function TMonospaceFont.Format: word;
begin
  Format := FontFormatsToWord([ffMonospace, ff1Bpp]);
end;

destructor TMonospaceFont.Free;
begin
  inherited Free;
end;

procedure TMonospaceFont.Assign(var ASource: TObject);
var
  source: PMonospaceFont;
begin
  inherited Assign(ASource);
  source := PMonospaceFont(@ASource);
end;

constructor TProportionalFont.CreateSize(AMaxWidth, AHeight: byte);
begin
  inherited CreateSize(AMaxWidth, AHeight);
  FillChar(CharWidths, SizeOf(CharWidths), MaxWidth);
  FFontDataSize := AHeight * 512;
  GetMem(FFontData, FontDataSize);
  FillChar(FFontData^, FontDataSize, 0);
end;

procedure TProportionalFont.Init;
begin
  inherited Init;
  MaxWidth := 8;
  AverageWidth := 0;
  FillChar(CharWidths, SizeOf(CharWidths), 0);
end;

function TProportionalFont.Format: word;
begin
  Format := FontFormatsToWord([ffProportional, ff1Bpp]);
end;

destructor TProportionalFont.Free;
begin
  inherited Free;
end;

function TProportionalFont.TextWidthAny(AText: PChar; ALength: word): longint;
var
  index: word;
  total: longint;
  ptr: PChar;
begin
  total := 0;
  ptr := AText;
  for index := 1 to ALength do begin
    Inc(total, CharWidths[Ord(ptr^)]);
    Inc(ptr);
  end;
  TextWidthAny := total;
end;

procedure TProportionalFont.Assign(var ASource: TObject);
var
  source: PProportionalFont;
begin
  inherited Assign(ASource);
  source := PProportionalFont(@ASource);
  CharWidths := source^.CharWidths;
end;

function TProportionalFont.CharWidth(AChar: char): integer;
begin
  CharWidth := CharWidths[Ord(AChar)];
end;

procedure TProportionalFont.SetCharWidths;
var
  charIndex, xIndex, yIndex: integer;
  linePtr: PWord;
  avgCount: integer;
  avgTotal: integer;
  width: word;
begin
  avgCount := 0;
  avgTotal := 0;
  for charIndex := 0 to High(byte) do begin
    width := 0;
    linePtr := FFontData;
    Inc(linePtr, charIndex * Height);
    for yIndex := 0 to Height - 1 do begin
      for xIndex := 0 to MaxWidth - 1 do begin
        if (linePtr^ and (32768 shr xIndex)) > 0 then
          width := MaxWord(xIndex + 1, width);
      end;
      Inc(linePtr);
    end;
    Inc(AvgTotal);
    Inc(AvgCount, width + Spacing);
    Inc(width, Spacing);
    CharWidths[charIndex] := width;
  end;
  if AvgTotal = 0 then
    AverageWidth := MaxWidth
  else
    AverageWidth := Round(avgCount / avgTotal);
  CharWidths[32] := AverageWidth div 2;
  CharWidths[0] := CharWidths[32];
end;

procedure TProportionalFont.SaveToStream(AStream: PStream);
var
  header: TFontHeader;
  lzw: TLzw;
  stream: TMemoryStream;
begin
  lzw.CreateBitSize(13);
  FillChar(header, SizeOf(header), 0);
  header.MajorVersion := FontMajorVersion;
  header.MinorVersion := FontMinorVersion;
  header.Name := GetId;
  header.DataSize := FFontDataSize;
  header.MaxWidth := MaxWidth;
  header.Height := Height;
  header.Compression := fcLzw;
  header.Spacing := Spacing;
  header.Format := Format;

  SetCharWidths;

  stream.Create(FFontDataSize);
  stream.Write(PByte(FFontData), FFontDataSize);
  stream.Seek(0, soFromBeginning);
  if stream.HasException then
    Raise(stream.Exception^.Code)
  else begin
    AStream^.Write(@header, SizeOf(header));
    if AStream^.HasException then
      Raise(AStream^.Exception^.Code)
    else begin
      lzw.CompressStream(@stream, AStream, FFontDataSize);
      if lzw.HasException then
        Raise(lzw.Exception^.Code);
      lzw.Free;
    end;
  end;
  stream.Free;
end;

procedure TProportionalFont.SaveToFile(const AFilename: string);
var
  fileStream: TFileStream;
begin
  fileStream.Create(AFilename, fmWrite);
  SaveToStream(@fileStream);
  fileStream.Free;
end;

procedure TProportionalFont.LoadFromStream(AStream: PStream);
var
  header: TFontHeader;
  stream: TMemoryStream;
  lzw: TLzw;
  index: integer;
  lineIndex: integer;
  ptr: PByte;
begin
  AStream^.Read(@header, SizeOf(header));
  if header.Format = 0 then
    header.Format := FontFormatsToWord([ffProportional, ff1Bpp]);
  if AStream^.HasException then begin
    Raise(AStream^.Exception^.Code);
    exit;
  end;
  if (header.MajorVersion > FontMajorVersion) or (header.MinorVersion > FontMinorVersion) then begin
    Raise(ecFontVersionNotSupported);
    exit;
  end;
  if Assigned(FFontData) then
    FreeMem(FFontData, FontDataSize);
  GetMem(FFontData, header.DataSize);
  if not Assigned(FFontData) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  FFontDataSize := header.DataSize;
  SetId(header.Name);
  stream.Create(header.DataSize);
  if stream.HasException then begin
    FreeMem(FFontData, header.DataSize);
    Raise(stream.Exception^.Code);
  end
  else begin
    case header.Compression of
      fcNone: begin
      end;
      fcLzw: begin
        lzw.CreateBitSize(13);
        lzw.DecompressStream(AStream, @stream, header.DataSize);
        if lzw.HasException then
          Raise(lzw.Exception^.Code);
        lzw.Free;
        stream.Seek(0, soFromBeginning);
        stream.Read(PByte(FFontData), header.DataSize);
        if stream.HasException then
          Raise(stream.Exception^.Code)
        else begin
          Height := header.Height;
          Spacing := header.Spacing;
          MaxWidth := header.MaxWidth;
          SetCharWidths;
        end;
      end
      else
        Raise(ecFontCompressionNotSupported)
    end;
  end;
  stream.Free;
end;

procedure TProportionalFont.LoadFromFile(const AFilename: string);
var
  fileStream: TFileStream;
begin
  fileStream.Create(AFilename, fmRead);
  LoadFromStream(@fileStream);
  fileStream.Free;
end;

constructor TColoredFont.CreateSize(AMaxWidth, AHeight: byte);
begin
  inherited CreateSize(AMaxWidth, AHeight);
  FillChar(CharWidths, SizeOf(CharWidths), MaxWidth);
  FFontDataSize := Height * (StartChar - EndChar) * 2;
  GetMem(FFontData, FontDataSize);
  FillChar(FFontData^, FontDataSize, 0);
end;

procedure TColoredFont.Init;
begin
  inherited Init;
  StartChar := 32;
  EndChar := 126;
end;

destructor TColoredFont.Free;
begin
  inherited Free;
end;

procedure TColoredFont.Assign(var ASource: TObject);
var
  source: PColoredFont;
begin
  inherited Assign(ASource);
end;

function TColoredFont.Format: word;
begin
  Format := FontFormatsToWord([ffColored, ff4Bpp]);
end;

function TSystemFont.TextWidthAny(AText: PChar; ALength: word): longint;
begin
  if not Assigned(AText) then begin
    TextWidthAny := 0;
    exit;
  end;
  TextWidthAny := longint(ALength) * 8;
end;

procedure TSystemFont.Init;
var
  fontPtr: PByte;
  segm, offs: word;
  regs: Registers;
begin
  inherited Init;
  Id := TString.New('SystemFont');
  Height := 16;
  MaxWidth := 8;
  AverageWidth := 8;
  fontPtr := Ptr(segm, offs);
  regs.Ax := $1130;
  regs.Bh := $06;
  Intr($10, regs);
  fontPtr := Ptr(regs.Es, regs.Bp);
  FFontDataSize := 256 * Height;
  GetMem(FFontData, FFontDataSize);
  Move(fontPtr^, FFontData^, FFontDataSize);
end;

destructor TSystemFont.Free;
begin
  inherited Free;
end;

function TSystemFont.CharWidth(AChar: char): integer;
begin
  CharWidth := 8;
end;

procedure TGraphicsState.Init;
begin
  inherited Init;
  ForeColor := 0;
  BackColor := 0;
  XPos := 0;
  YPos := 0;
  Font := nil;
  ViewPort.Create;
  BufferMode := false;
  FrameBuffer := nil;
  FontColor := scWhite;
  FontShade := 0;
end;

procedure TGraphicsState.Assign(var ASource: TObject);
var
  state: PGraphicsState;
begin
  inherited Assign(ASource);
  state := PGraphicsState(@ASource);
  ForeColor := state^.ForeColor;
  BackColor := state^.BackColor;
  XPos := state^.XPos;
  YPos := state^.YPos;
  Font := state^.Font;
  FrameBuffer := state^.FrameBuffer;
  ViewPort.SetRect(state^.ViewPort);
  BufferMode := state^.BufferMode;
end;

function TFontList.GetItem(AIndex: integer): PFont;
begin
  GetItem := PFont(inherited GetItem(AIndex));
end;

function TFontList.GetItemById(const AId: string): PFont;
begin
  GetItemById := PFont(inherited GetItemById(AId));
end;

function TFontList.Add(AItem: PFont): integer;
begin
  Add := inherited Add(AItem);
end;

function TFontList.IndexOf(AItem: PFont): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TFontList.ForEach(AProc: PFontListProc);
begin
  TList.ForEach(PListProc(AProc));
end;

procedure TFontList.SetItem(AIndex: integer; AItem: PFont);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TFontList.Insert(AIndex: integer; AItem: PFont);
begin
  inherited Insert(AIndex, AItem);
end;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  if Assigned(Graph) then
    FreeAndNil(Graph);
  WriteLn('Graphics driver uninstalled.');
end;

begin
  Graph := nil;
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
