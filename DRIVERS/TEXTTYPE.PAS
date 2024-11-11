{$I COMPILER.INC}
unit TextType;

interface

uses
  AplObj,
  AplConst,
  Drawing;

type
  PTextState = ^TTextState;
  PTextMode = ^TTextMode;
  PTextChar = ^TTextChar;

  TTextDrivers =
  (
    tdDirect,
    tdAnsi
  );

  TLineOrientation = (loHorizontal, loVertical);
  TLineStyle = (lsSingle, lsDouble);
  TLineCharacter = (lcStart, lcMiddle, lcEnd);
  TBorderCharcter = (bcTopLeft, bcTopRight, bcBottomLeft, bcBottomRight, bcLeft, bcTop, bcRight, bcBottom);
  TBorderStyle = (bsNone, bsSingle, bsDouble);

  TBorderChars = array[TBorderStyle, TBorderCharcter] of char;
  TLineChars = array[TLineOrientation, TLineStyle, TLineCharacter] of char;

  TTextChar = record
    Character: char;
    Attributes: byte;
  end;

  TColorType = (ctMono, ctGrayScale, ctColor);

  TTextModes =
  (
    tmMono40x25,  { 0 }
    tmColor40x25, { 1 }
    tmGrayscale80x25, { 2 }
    tmColor80x25, { 3 }
    tmHercules80x25, { 6 }
    tmMono80x25, { 7 }
    tmEga80x25, { 16 }
    tmEga80x43, { 23 }
    tmVga80x50 { 102 }
  );

  TTextModeDimensions = record
    Width: byte;
    Height: byte;
    MaxX: byte;
    MaxY: byte;
    CharWidth: byte;
    CharHeight: byte;
    WidthPixels: word;
    HeightPixels: word;
    MouseShiftX: byte;
    MouseShiftY: byte;
    Color: boolean;
    FontSupport: boolean;
    DosMode: integer;
  end;

  TTextState = object(TObject)
  public
    ForeColor, BackColor: byte;
    Blink: boolean;
    IsCursorOn: boolean;
    ViewPort: TRect;
    function Attributes: byte;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TTextMode = object(TObject)
  private
  public
    Width, Height: integer;
    MaxX, MaxY: integer;
    CharWidth: byte; CharHeight: byte;
    WidthPixels: word; HeightPixels: word;
    MaxXPixels: word; MaxYPixels: word;
    MouseShiftX: byte; MouseShiftY: byte;
    ModeId: TTextModes; DosMode: integer;
    ColorType: TColorType; FontSupport: boolean;
    Bounds: TRect;
    AdditionalData: integer;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TTextModeArray = array[TTextModes] of TTextMode;
  TTextModeDescriptionArray = array[TTextModes] of string15;

const
  TextModeDescription: TTextModeDescriptionArray =
  (
    'Mono 40x25',
    'Color 40x25',
    'Grayscale 80x25',
    'Color 80x25',
    'Hercules 80x25',
    'Mono 80x25',
    'EGA 80x25',
    'EGA 80x43',
    'VGA 80x50'
  );

  TextModes: TTextModeArray =
  (
    (
      { tmMono40x25 }
      Width: 40; Height: 25;
      MaxX: 39; MaxY: 24;
      CharWidth: 8; CharHeight: 16;
      WidthPixels: 360; HeightPixels: 400;
      MaxXPixels: 359; MaxYPixels: 399;
      MouseShiftX: 3; MouseShiftY: 3;
      ModeId: tmMono40x25; DosMode: 0;
      ColorType: ctMono; FontSupport: false;
      Bounds: (X: 0; Y: 0; Width: 40; Height: 25);
      AdditionalData: 0
    ),
    (
      { tmColor40x25 }
      Width: 40; Height: 25;
      MaxX: 39; MaxY: 24;
      CharWidth: 8; CharHeight: 8;
      WidthPixels: 320; HeightPixels: 200;
      MaxXPixels: 319; MaxYPixels: 199;
      MouseShiftX: 3; MouseShiftY: 3;
      ModeId: tmColor40x25; DosMode: 1;
      ColorType: ctColor; FontSupport: false;
      Bounds: (X: 0; Y: 0; Width: 40; Height: 25);
      AdditionalData: 0
    ),
    (
      { tmGrayscale80x25 }
      Width: 80; Height: 25;
      MaxX: 79; MaxY: 24;
      CharWidth: 8; CharHeight: 8;
      WidthPixels: 640; HeightPixels: 200;
      MaxXPixels: 630; MaxYPixels: 199;
      MouseShiftX: 3; MouseShiftY: 3;
      ModeId: tmGrayscale80x25; DosMode: 2;
      ColorType: ctGrayScale; FontSupport: false;
      Bounds: (X: 0; Y: 0; Width: 80; Height: 25);
      AdditionalData: 0
    ),
    (
      { tmColor80x25 }
      Width: 80; Height: 25;
      MaxX: 79; MaxY: 24;
      CharWidth: 8; CharHeight: 16;
      WidthPixels: 640; HeightPixels: 400;
      MaxXPixels: 719; MaxYPixels: 399;
      MouseShiftX: 3; MouseShiftY: 3;
      ModeId: tmColor80x25; DosMode: 3;
      ColorType: ctColor; FontSupport: true;
      Bounds: (X: 0; Y: 0; Width: 80; Height: 25);
      AdditionalData: 0
    ),
    (
      { tmHercules80x25 }
      Width: 80; Height: 25;
      MaxX: 79; MaxY: 24;
      CharWidth: 8; CharHeight: 8;
      WidthPixels: 640; HeightPixels: 200;
      MaxXPixels: 639; MaxYPixels: 199;
      MouseShiftX: 3; MouseShiftY: 3;
      ModeId: tmHercules80x25; DosMode: 6;
      ColorType: ctMono; FontSupport: false;
      Bounds: (X: 0; Y: 0; Width: 80; Height: 25);
      AdditionalData: 0
    ),
    (
      { tmMono80x25 }
      Width: 80; Height: 25;
      MaxX: 79; MaxY: 24;
      CharWidth: 8; CharHeight: 16;
      WidthPixels: 720; HeightPixels: 350;
      MaxXPixels: 719; MaxYPixels: 349;
      MouseShiftX: 3; MouseShiftY: 3;
      ModeId: tmMono80x25; DosMode: 7;
      ColorType: ctMono; FontSupport: false;
      Bounds: (X: 0; Y: 0; Width: 80; Height: 25);
      AdditionalData: 0
    ),
    (
      { tmEga80x25 }
      Width: 80; Height: 25;
      MaxX: 79; MaxY: 24;
      CharWidth: 8; CharHeight: 14;
      WidthPixels: 640; HeightPixels: 350;
      MaxXPixels: 639; MaxYPixels: 349;
      MouseShiftX: 3; MouseShiftY: 3;
      ModeId: tmEga80x25; DosMode: 16;
      ColorType: ctColor; FontSupport: true;
      Bounds: (X: 0; Y: 0; Width: 80; Height: 25);
      AdditionalData: 0
    ),
    (
      { tmEga80x43 }
      Width: 80; Height: 43;
      MaxX: 79; MaxY: 42;
      CharWidth: 8; CharHeight: 8;
      WidthPixels: 720; HeightPixels: 350;
      MaxXPixels: 719; MaxYPixels: 349;
      MouseShiftX: 3; MouseShiftY: 3;
      ModeId: tmEga80x43; DosMode: 23;
      ColorType: ctColor; FontSupport: true;
      Bounds: (X: 0; Y: 0; Width: 80; Height: 43);
      AdditionalData: 0
    ),
    (
      { tmVga80x50 }
      Width: 80; Height: 50;
      MaxX: 79; MaxY: 49;
      CharWidth: 8; CharHeight: 8;
      WidthPixels: 640; HeightPixels: 400;
      MaxXPixels: 639; MaxYPixels: 399;
      MouseShiftX: 3; MouseShiftY: 3;
      ModeId: tmVga80x50; DosMode: 102;
      ColorType: ctColor; FontSupport: true;
      Bounds: (X: 0; Y: 0; Width: 80; Height: 50);
      AdditionalData: 0
    )
  );


  LineChars: TLineChars =
  (
    ((#195, #196, #180), (#204, #205, #185)),
    ((#194, #179, #193), (#203, #186, #202))
  );

  StandardBorderChars: TBorderChars =
  (
    (#32, #32, #32, #32, #32, #32, #32, #32),
    (#218, #191, #192, #217, #179, #196, #179, #196),
    (#201, #187, #200, #188, #186, #205, #186, #205)
  );

  EnhancedBorderChars: TBorderChars =
  (
    (#32, #32, #32, #32, #32, #32, #32, #32),
    (#218, #216, #192, #217, #179, #202, #197, #196),
    (#201, #187, #200, #188, #179, #196, #179, #196)
  );


var
  BorderChars: TBorderChars;

implementation

uses
  AplStr,
  Strings;

procedure TTextState.Init;
begin
  ForeColor := 0;
  BackColor := 0;
  Blink := false;
  IsCursorOn := true;
  ViewPort.Create;
end;

procedure TTextState.Assign(var ASource: TObject);
var
  state: PTextState;
begin
  inherited Assign(ASource);
  state := PTextState(@ASource);
  ForeColor := state^.ForeColor;
  BackColor := state^.BackColor;
  Blink := state^.Blink;
  IsCursorOn := state^.IsCursorOn;
  ViewPort.SetRect(state^.ViewPort);
end;

function TTextState.Attributes: byte;
begin
  Attributes := (ForeColor and $0F) or ((BackColor and $0F) shl 4) or (byte(Blink) shl 7);
end;

procedure TTextMode.Init;
begin
  inherited Init;
  Width := 0;
  Height := 0;
  MaxX := 0;
  MaxY := 0;
  CharWidth := 8;
  CharHeight := 16;
  WidthPixels := 639;
  HeightPixels := 199;
  MouseShiftX := 3;
  MouseShiftY := 3;
  AdditionalData := 0;
  ColorType := ctColor;
  ModeId := tmColor80x25;
  Bounds.Create;
end;

destructor TTextMode.Free;
begin
  inherited Free;
end;


end.