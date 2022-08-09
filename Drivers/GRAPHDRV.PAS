{$I COMPILER.INC}
unit GraphDrv;

interface

uses
  Crt,
  Objects,
  Utils,
  Dos,
  Drawing,
  Collects,
  Consts,
  MouseDrv,
  StrUtils,
  Strings,
  Streams;

const
  MinIntensity = 1;
  MaxIntensity = 18;
  Intensity50 = 9;
  Intensity25 = 4;
  Intensity75 = 14;
  TransparentColor = 1;

type
  TStandardColor =
  (
    scWhite,
    scRed,
    scGreen,
    scBlue,
    scCyan,
    scYellow,
    scMagenta,
    scOrange,
    scChartreuse,
    scSpringGreen,
    scAzure,
    scViolet,
    scPink,
    scBlack
  );
  TColor = record
    Color: TStandardColor;
    Shade: byte;
  end;
  TRgbColor = record
    Red: byte;
    Green: byte;
    Blue: byte;
  end;
  TMouseCursorImage = array[0..14, 0..10] of byte;
  PMouseCursor = ^TMouseCursor;
  TMouseCursor = object(TBaseObject)
  private
    _image: TMouseCursorImage;
    _width, _height: word;
    _visible: boolean;
    _x, _y: integer;
  public
    BackData: PByte;
    procedure Draw; virtual;
    procedure Init; virtual;
    destructor Done; virtual;
    function Width: integer; virtual;
    function Height: integer; virtual;
    function GetTypeName: string; virtual;
    procedure StoreBackground(X, Y: integer); virtual;
  end;
  PFontData = ^TFontData;
  TFontData = array[0..255, 0..15] of byte;
  TRgbPalette = array[byte] of TRgbColor;
  PGraphicsMode = ^TGraphicsMode;
  TGraphicsMode = object(TPersistent)
  public
    Width, Height: integer;
    MaxX, MaxY: integer;
    Bpp: byte;
    Description: PChar;
    HelpText: PChar;
    AdditionalData: integer;
    Pitch: word;
    FrameBuffer: pointer;
    function GetTypeName: string; virtual;
    constructor CreateAssign(mode: TGraphicsMode);
    procedure Assign(var source: TPersistent); virtual;
    procedure AssignTo(var dest: TPersistent); virtual;
    procedure Init; virtual;
    destructor Done; virtual;
  end;
  PGraphicsModeList = ^TGraphicsModeList;
  TGraphicsModeList = object(TObjectList)
  public
    function GetItem(index: integer): PGraphicsMode;
    function IndexOf(item: PGraphicsMode): integer;
    function Add(item: PGraphicsMode): integer;
    procedure Insert(index: integer; item: PGraphicsMode);
    function Where(predicate: TPredicate; var value): PGraphicsModeList;
    function GetTypeName: string; virtual;
  end;
  PGraphicsDriver = ^TGraphicsDriver;
  PFont = ^TFont;
  TFont = object(TPersistent)
  private
    _maxWidth: integer;
  public
    Version: real;
    TransparentColor: byte;
    Transparent: boolean;
    Initialized: boolean;
    Height: integer;
    FontData: PFontData;
    FontDataSize: integer;
    constructor CreateAssign(font: TFont);
    destructor Done; virtual;
    procedure Assign(var source: TPersistent); virtual;
    procedure AssignTo(var dest: TPersistent); virtual;
    procedure Init; virtual;
    procedure ReadFromStream(stream: TStream; var error: TError); virtual;
    procedure WriteToStream(stream: TStream; var error: TError); virtual;
    function CharWidth(ch: char): integer; virtual;
    function TextWidth(text: string): integer; virtual;
    function TextWidthLarge(text: PChar): integer; virtual;
    function PixelSet(ch: char; x, y: byte): boolean; virtual;
    function GetTypeName: string; virtual;
  end;
  PMonospaceFont = ^TMonospaceFont;
  TMonospaceFont = object(TFont)
  public
    procedure Init; virtual;
    function TextWidth(text: string): integer; virtual;
    function TextWidthLarge(text: PChar): integer; virtual;
    function GetTypeName: string; virtual;
  end;
  PSystemFont = ^TSystemFont;
  TSystemFont = object(TMonospaceFont)
  private
  public
    function CharWidth(ch: char): integer; virtual;
    function PixelSet(ch: char; x, y: byte): boolean; virtual;
    function TextWidth(text: string): integer; virtual;
    function TextWidthLarge(text: PChar): integer; virtual;
    function GetTypeName: string; virtual;
    procedure Init; virtual;
    destructor Done; virtual;
  end;
  PGraphicsState = ^TGraphicsState;
  TGraphicsState = object(TPersistent)
  private
  public
    ForeColor: byte;
    BackColor: byte;
    XPos, YPos: integer;
    function GetTypeName: string; virtual;
    procedure Init; virtual;
    procedure Assign(var source: TPersistent); virtual;
    procedure AssignTo(var dest: TPersistent); virtual;
  end;
  TGraphicsDriver = object(TObject)
  private
    _oldMode: byte;
    _mouseCursor: PMouseCursor;
  public
    State: PGraphicsState;
    StateStack: PStack;
    Modes: PGraphicsModeList;
    Mode: PGraphicsMode;
    Error: TError;
    Font: PFont;
    SystemFont: PFont;
    function GetPixel(x, y: integer): byte; virtual;
    function GetColor(color: TStandardColor; intensity: byte): byte; virtual;
    function ForeColor: byte; virtual;
    function BackColor: byte; virtual;
    function XPos: byte; virtual;
    function YPos: byte; virtual;
    function GetTypeName: string; virtual;
    procedure GetImage(var buffer: PByte; rect: TRect); virtual;
    procedure GetImageStream(stream: PStream; rect: TRect); virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure SetMode(newMode: PGraphicsMode); virtual;
    procedure SetPixel(x, y: integer); virtual;
    procedure MoveTo(x, y: integer); virtual;
    procedure LineTo(x, y: integer); virtual;
    procedure Line(x1, y1, x2, y2: integer); virtual;
    procedure HLine(x, y, width: integer); virtual;
    procedure VLine(x, y, height: integer); virtual;
    procedure Rectangle(x1, y1, width, height: integer); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure DrawImage(x, y, width, height: integer; image: PByte); virtual;
    procedure DrawImageStream(x, y, width, height: integer; stream: PStream); virtual;
    procedure DrawText(x, y: integer; text: string); virtual;
    procedure DrawTextLarge(x, y: integer; text: PChar); virtual;
    procedure SetStandardPalette; virtual;
    procedure SetRgbPalette(palette: TRgbPalette); virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure Init; virtual;
    procedure ShowMouseCursor; virtual;
    procedure HideMouseCursor; virtual;
    procedure EraseMouseCursor(mouseState: TMouseState); virtual;
    procedure DrawMouseCursor(mouseState: TMouseState); virtual;
    destructor Done; virtual;
  end;

var
  Graphics: PGraphicsDriver;

implementation

const
  DefaultMouseCursor: TMouseCursorImage =
  (
    ($27, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01),
    ($27, $27, $01, $01, $01, $01, $01, $01, $01, $01, $01),
    ($27, $00, $27, $01, $01, $01, $01, $01, $01, $01, $01),
    ($27, $00, $00, $27, $01, $01, $01, $01, $01, $01, $01),
    ($27, $00, $00, $00, $27, $01, $01, $01, $01, $01, $01),
    ($27, $00, $00, $00, $00, $27, $01, $01, $01, $01, $01),
    ($27, $00, $00, $00, $00, $00, $27, $01, $01, $01, $01),
    ($27, $00, $00, $00, $00, $00, $00, $27, $01, $01, $01),
    ($27, $00, $00, $00, $00, $00, $00, $00, $27, $01, $01),
    ($27, $00, $00, $00, $00, $00, $00, $00, $00, $27, $01),
    ($27, $00, $00, $00, $27, $27, $27, $27, $27, $27, $27),
    ($27, $00, $00, $27, $01, $01, $01, $01, $01, $01, $01),
    ($27, $00, $27, $01, $01, $01, $01, $01, $01, $01, $01),
    ($27, $27, $01, $01, $01, $01, $01, $01, $01, $01, $01),
    ($27, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01)
  );

procedure TGraphicsDriver.Init;
var
  oldMode: byte;
begin
  inherited Init;
  _oldMode := LastMode;
  ClearError(Error);
  Modes := New(PGraphicsModeList, Create);
  SystemFont := New(PSystemFont, CreateId('SystemFont'));
  Font := SystemFont;
  Mode := nil;
  State := New(PGraphicsState, Create);
  StateStack := New(PStack, Create);
  MoveTo(0, 0);
  _mouseCursor := nil;
end;

function TGraphicsDriver.ForeColor: byte;
begin
  ForeColor := State^.ForeColor;
end;

function TGraphicsDriver.BackColor: byte;
begin
  BackColor := State^.BackColor;
end;

function TGraphicsDriver.XPos: byte;
begin
  XPos := State^.XPos;
end;

function TGraphicsDriver.YPos: byte;
begin
  YPos := State^.YPos;
end;

procedure TGraphicsDriver.SetForeColor(color: byte);
begin
  State^.ForeColor := color;
end;

procedure TGraphicsDriver.SetBackColor(color: byte);
begin
  State^.BackColor := color;
end;

function TGraphicsDriver.GetPixel(x, y: integer): byte;
begin
end;

procedure TGraphicsDriver.SetMode(newMode: PGraphicsMode);
begin
  if (_mouseCursor <> nil) then Dispose(_mouseCursor, Done);
  _mouseCursor := New(PMouseCursor, Create);
  MouseDriver^.SetMouseResolution(Mode^.Width, Mode^.Height);  
end;

procedure TGraphicsDriver.SetPixel(x, y: integer);
begin
end;

procedure TGraphicsDriver.MoveTo(x, y: integer);
begin
end;

procedure TGraphicsDriver.LineTo(x, y: integer);
begin
end;

procedure TGraphicsDriver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure TGraphicsDriver.Rectangle(x1, y1, width, height: integer);
begin
  HLine(x1, y1, width);
  HLine(x1, height - 1, width);
  VLine(x1, y1, height);
  VLine(width - 1, y1, height);
end;

procedure TGraphicsDriver.HLine(x, y, width: integer);
begin
end;

procedure TGraphicsDriver.VLine(x, y, height: integer);
begin
end;

procedure TGraphicsDriver.FillRect(rect: TRect);
begin
end;

procedure TGraphicsDriver.DrawImage(x, y, width, height: integer; image: PByte);
begin
end;

procedure TGraphicsDriver.DrawImageStream(x, y, width, height: integer; stream: PStream);
begin

end;

procedure TGraphicsDriver.GetImage(var buffer: PByte; rect: TRect);
begin
end;

procedure TGraphicsDriver.GetImageStream(stream: PStream; rect: TRect);
begin
end;

procedure TGraphicsDriver.DrawText(x, y: integer; text: string);
begin
end;

procedure TGraphicsDriver.DrawTextLarge(x, y: integer; text: PChar);
begin
end;

procedure TGraphicsDriver.SetStandardPalette;
var
  palette: TRgbPalette;
  colorIndex: TStandardColor;
  shadeIndex, shade: integer;
  paletteIndex: integer;
  index: integer;
begin
  for Index := 0 to 21 do
  begin
    palette[index].Red := 0;
    palette[index].Green := 0;
    palette[index].Blue := 0;
  end;
  paletteIndex := 22;

  for colorIndex := Low(TStandardColor) to High(TStandardColor) do
  begin
    for shadeIndex := 1 to 18 do
    begin
      shade := shadeIndex * 14;
      case colorIndex of
        scWhite:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := shade;
        end;
        scRed:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := 0;
          palette[paletteIndex].Blue := 0;
        end;
        scGreen:
        begin
          palette[paletteIndex].Red := 0;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := 0;
        end;
        scBlue:
        begin
          palette[paletteIndex].Red := 0;
          palette[paletteIndex].Green := 0;
          palette[paletteIndex].Blue := shade;
        end;
        scYellow:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := 0;
        end;
        scMagenta:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := 0;
          palette[paletteIndex].Blue := shade;
        end;
        scCyan:
        begin
          palette[paletteIndex].Red := 0;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := shade;
        end;
        scOrange:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := shade div 2;
          palette[paletteIndex].Blue := 0;
        end;
        scChartreuse:
        begin
          palette[paletteIndex].Red := shade div 2;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := 0;
        end;
        scSpringGreen:
        begin
          palette[paletteIndex].Red := shade div 2;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := shade div 2;
        end;
        scAzure:
        begin
          palette[paletteIndex].Red := shade div 3;
          palette[paletteIndex].Green := shade div 3;
          palette[paletteIndex].Blue := shade;
        end;
        scViolet:
        begin
          palette[paletteIndex].Red := shade div 2;
          palette[paletteIndex].Green := 0;
          palette[paletteIndex].Blue := shade;
        end;
        scPink:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := shade div 3;
          palette[paletteIndex].Blue := shade;
        end;
      end;
      Inc(paletteIndex);
    end;
  end;
  SetRgbPalette(palette);
end;

procedure TGraphicsDriver.SetRgbPalette(palette: TRgbPalette);
var
  reg: Registers;
  index: integer;
begin
  for index := 0 to 255 do
  begin
    with palette[index] do
    begin
      Red := Red shr 2;
      Green := Green shr 2;
      Blue := Blue shr 2;
    end;
  end;
  FillChar(reg, SizeOf(reg), 0);
  with reg do
  begin
    AX := $1012;
    BX := $0;
    CX := $FF;
    ES := Seg(palette);
    DX := Ofs(palette);
    Intr($10, reg);
  end;
end;

procedure TGraphicsDriver.PushState;
var
  newState: PGraphicsState;
begin
  newState := New(PGraphicsState, Create);
  newState^ := State^;
  StateStack^.Push(newState);
end;

procedure TGraphicsDriver.PopState;
var
  oldState: PGraphicsState;
begin
  oldState := PGraphicsState(StateStack^.Pop);
  if (oldState = nil) then exit;
  State^ := oldState^;
  Dispose(oldState, Done);
end;

destructor TGraphicsDriver.Done;
begin
  TextMode(_oldMode);
  if (_mouseCursor <> nil) then begin
    Dispose(_mouseCursor, Done);
  end;  
  Dispose(StateStack, Done);
  Dispose(State, Done);
  Dispose(SystemFont, Done);
  TObject.Done;
end;

function TGraphicsDriver.GetTypeName: string;
begin
  GetTypeName := 'TGraphicsDriver';
end;

function TGraphicsDriver.GetColor(color: TStandardColor; intensity: byte): byte;
begin
  if (color = scBlack) then
  begin
    GetColor := 0;
    exit;
  end;
  GetColor := 21 + ord(color) * 18 + intensity;
end;

procedure TGraphicsDriver.EraseMouseCursor(mouseState: TMouseState);
begin
  if (_mouseCursor^.BackData <> nil) and (_mouseCursor^._Visible) and (mouseState.Visible) then
    Graphics^.DrawImage(_mouseCursor^._X, _mouseCursor^._Y, _mouseCursor^.Width, _mouseCursor^.Height, _mouseCursor^.BackData);
end;

procedure TGraphicsDriver.DrawMouseCursor(mouseState: TMouseState);
begin
  if (not _mouseCursor^._Visible) or (not mouseState.Visible) then exit;
  _mouseCursor^.StoreBackground(mouseState.X, mouseState.Y);
  _mouseCursor^._X := mouseState.X;
  _mouseCursor^._Y := mouseState.Y;
  _mouseCursor^.Draw;
end;

procedure TGraphicsDriver.ShowMouseCursor;
var
  mouseState: TMouseState;
begin
  _mouseCursor^._Visible := true;
  MouseDriver^.State^.Visible := true;
  MouseDriver^.GetMouseState(mouseState);
  DrawMouseCursor(mouseState);
  MouseDriver^.ShowMouse;
end;

procedure TGraphicsDriver.HideMouseCursor;
var
  mouseState: TMouseState;
begin
  EraseMouseCursor(MouseDriver^.State^);
  _mouseCursor^._visible := false;
  MouseDriver^.State^.Visible := false;
  MouseDriver^.HideMouse;
end;

constructor TGraphicsMode.CreateAssign(mode: TGraphicsMode);
begin
  Init;
  Assign(mode);
end;

procedure TGraphicsMode.Init;
begin
  inherited Init;
  Width := 0;
  Height := 0;
  MaxX := 0;
  MaxY := 0;
  Bpp := 0;
  AdditionalData := -1;
  Pitch := 0;
  HelpText := nil;
  Description := nil;
  FrameBuffer := nil;
  HelpText := nil;
end;

destructor TGraphicsMode.Done;
begin
  DisposeLargeString(HelpText);
  DisposeLargeString(Description);
  TObject.Done;
end;

function TGraphicsMode.GetTypeName: string;
begin
  GetTypeName := 'TGraphicsMode';
end;

procedure TGraphicsMode.Assign(var source: TPersistent);
var
  mode: PGraphicsMode;
begin
  mode := PGraphicsMode(@source);
  Width := mode^.Width;
  Height := mode^.Height;
  MaxX := mode^.MaxX;
  MaxY := mode^.MaxY;
  Bpp := mode^.Bpp;
  Description :=  CopyLargeString(mode^.Description);
  AdditionalData := mode^.AdditionalData;
  HelpText := CopyLargeString(mode^.HelpText);
  Id := CopyLargeString(mode^.Id);
  Pitch := mode^.Pitch;
  FrameBuffer := mode^.FrameBuffer;
end;

procedure TGraphicsMode.AssignTo(var dest: TPersistent);
var
  mode: PGraphicsMode;
begin
  mode := PGraphicsMode(@dest);
  mode^.Width := Width;
  mode^.Height := Height;
  mode^.MaxX := MaxX;
  mode^.MaxY := MaxY;
  mode^.Bpp := Bpp;
  mode^.Description := CopyLargeString(Description);
  mode^.AdditionalData := AdditionalData;
  mode^.HelpText := CopyLargeString(HelpText);
  mode^.Pitch := Pitch;
  mode^.Id := CopyLargeString(Id);
  mode^.FrameBuffer := FrameBuffer;
end;

function TGraphicsModeList.GetTypeName: string;
begin
  GetTypeName := 'TGraphicsModeList';
end;


function TGraphicsModeList.GetItem(index: integer): PGraphicsMode;
begin
  GetItem := pointer(TObjectList.GetItem(index));
end;

function TGraphicsModeList.IndexOf(item: PGraphicsMode): integer;
begin
  IndexOf := TObjectList.IndexOf(item);
end;

function TGraphicsModeList.Add(item: PGraphicsMode): integer;
begin
  Add := TObjectList.Add(item);
end;

procedure TGraphicsModeList.Insert(index: integer; item: PGraphicsMode);
begin
  TObjectList.Insert(index, item);
end;

function TGraphicsModeList.Where(predicate: TPredicate; var value): PGraphicsModeList;
begin
  Where := PGraphicsModeList(TList.Where(predicate, value));
end;

constructor TFont.CreateAssign(font: TFont);
begin
  Init;
  Assign(font);
end;

destructor TFont.Done;
begin
  if (FontData <> nil) then
    FreeMem(FontData, FontDataSize);
  TPersistent.Done;
end;

procedure TFont.Assign(var source: TPersistent);
var
  font: PFont;
begin
  font := PFont(@source);
  if (FontData <> nil) then begin
    FreeMem(FontData, FontDataSize);
    GetMem(FontData, font^.FontDataSize);
    Move(font^.FontData^, FontData^, font^.FontDataSize);
  end;
  FontDataSize := font^.FontDataSize;
  _maxWidth := font^._maxWidth;
  Version := font^.Version;
  TransparentColor := font^.TransparentColor;
  Transparent := font^.Transparent;
  Initialized := font^.Initialized;
  Height := font^.Height;
  Id := CopyLargeString(font^.Id);
end;

procedure TFont.AssignTo(var dest: TPersistent);
var
  font: PFont;
begin
  font := PFont(@dest);
  if (font^.FontData <> nil) then begin
    FreeMem(font^.FontData, font^.FontDataSize);
    GetMem(font^.FontData, FontDataSize);
    Move(FontData^, font^.FontData^, FontDataSize);
  end;
  font^.FontDataSize := FontDataSize;
  font^._maxWidth := _maxWidth;
  font^.Version := Version;
  font^.TransparentColor := TransparentColor;
  font^.Transparent := Transparent;
  font^.Initialized := Initialized;
  font^.Height := Height;
end;

procedure TFont.Init;
begin
  TPersistent.Init;
  FontData := nil;
  Version := 1.0;
  TransparentColor := 0;
  Transparent := true;
  Initialized := true;
  Height := 0;
end;

function TFont.GetTypeName: string;
begin
  GetTypeName := 'TFont';
end;


procedure TFont.ReadFromStream(stream: TStream; var error: TError);
begin
end;

procedure TFont.WriteToStream(stream: TStream; var error: TError);
begin
end;

function TFont.CharWidth(ch: char): integer;
begin
end;

function TFont.TextWidth(text: string): integer;
begin
end;

function TFont.TextWidthLarge(text: PChar): integer;
begin
end;

function TFont.PixelSet(ch: char; x, y: byte): boolean;
begin
end;

procedure TMonospaceFont.Init;
begin
  TFont.Init;
end;

function TMonospaceFont.GetTypeName: string;
begin
  GetTypeName := 'TMonospaceFont';
end;


function TMonospaceFont.TextWidth(text: string): integer;
begin
end;

function TMonospaceFont.TextWidthLarge(text: PChar): integer;
begin
end;

function TSystemFont.TextWidth(text: string): integer;
var
  width: integer;
begin
  width := Length(text) * 8;
  TextWidth := width;
end;

function TSystemFont.TextWidthLarge(text: PChar): integer;
var
  width: integer;
begin
  width := StrLen(text) * 8;
  TextWidthLarge := width;
end;

procedure TSystemFont.Init;
var
  regs: Registers;
  fontPtr: pointer;
begin
  TMonospaceFont.Init;
  Id := NewLargeString('System');
  FillChar(regs, SizeOf(regs), 0);
  regs.ax := $1130;
  regs.bh := $06;
  Intr($10, regs);
  Height := regs.cx;
  fontPtr := Ptr(regs.es, regs.bp);
  FontDataSize := 256 * Height;
  GetMem(FontData, FontDataSize);
  Move(fontPtr^, FontData^, FontDataSize);
end;

function TSystemFont.GetTypeName: string;
begin
  GetTypeName := 'TSystemFont';
end;

destructor TSystemFont.Done;
begin
  TMonospaceFont.Done;
end;

function TSystemFont.CharWidth(ch: char): integer;
begin
  CharWidth := 8;
end;

function TSystemFont.PixelSet(ch: char; x, y: byte): boolean;
begin
  PixelSet := PFontData(FontData)^[ord(ch), y] and (128 shr x) > 0;
end;

procedure TGraphicsState.Init;
begin
  TObject.Init;
  ForeColor := 0;
  BackColor := 0;
  XPos := 0;
  YPos := 0;
end;

procedure TGraphicsState.Assign(var source: TPersistent); 
var
  mode: PGraphicsState;
begin
  TPersistent.Assign(source);
  mode := PGraphicsState(@source);
  mode^.ForeColor := ForeColor;
  mode^.BackColor := BackColor;
  mode^.XPos := XPos;
  mode^.YPos := YPos;
end;

procedure TGraphicsState.AssignTo(var dest: TPersistent);
var
  mode: PGraphicsState;
begin
  TPersistent.AssignTo(dest);
  mode := PGraphicsState(@dest);
  ForeColor := mode^.ForeColor;
  BackColor := mode^.BackColor;
  XPos := mode^.XPos;
  YPos := mode^.YPos;
end;

function TGraphicsState.GetTypeName: string;
begin
  GetTypeName := 'TGraphicsState';
end;

procedure TMouseCursor.Init;
begin
  TBaseObject.Init;
  _width := 11;
  _height := 15;
  _visible := true;
  _y := 0;
  _x := 0;
  BackData := nil;
  _image := DefaultMouseCursor;
end;

procedure TMouseCursor.Draw;
var
  xIndex, yIndex: integer;
  pixel: PByte;
  rect, mouseRect, clipRect: TRect;
  xPos, yPos, startX, startY: integer;
begin
  if not _visible then exit;
  Graphics^.DrawImage(_x, _y, _width, _height, @_image);
end;

procedure TMouseCursor.StoreBackground(x, y: integer);
var
  rect: TRect;
begin
  if (BackData = nil) then GetMem(BackData, Width * Height);
  rect.CreateDims(x, y, Width, Height);
  Graphics^.GetImage(BackData, rect);
end;

function TMouseCursor.Width: integer;
begin
  Width := _width;
end;

function TMouseCursor.Height: integer;
begin
  Height := _height;
end;

destructor TMouseCursor.Done;
begin
  if (BackData <> nil) then
    FreeMem(BackData, _width * _height);
  TBaseObject.Done;
end;

function TMouseCursor.GetTypeName: string;
begin
  GetTypeName := 'TMouseCursor';
end;

end.