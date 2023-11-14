{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Graph8;

interface

uses
  Objects,
  Common,
  Drawing,
  Collects,
  Consts,
  MouseDrv,
  GraphDrv,
  StrUtils,
  MemDrv,
  Strings,
  Dos,
  Streams;

const
  MinIntensity = 1;
  MaxIntensity = 18;
  Intensity50 = 9;
  Intensity25 = 4;
  Intensity75 = 14;
  TransparentColor: byte = 1;

type
  PGraphics256Driver = ^TGraphics256Driver;
  PMouseCursor = ^TMouseCursor;
  PRgbPalette = ^TRgbPalette;

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
    scBrown,
    scSpringGreen,
    scAzure,
    scViolet,
    scFleshTone,
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

  TRgbPalette = array[byte] of TRgbColor;

  TMouseCursor = object(TObject)
  private
    FGraph: PGraphicsDriver;
    FBackData: PByte;
    FBackBuffer: PByte;
  public
    Visible: boolean;
    X, Y: integer;
    Image: PByte;
    Width, Height: word;
    constructor Create(ADriver: PGraphicsDriver);
    procedure Draw; virtual;
    procedure Init; virtual;
    procedure StoreBackground(AX, AY: integer); virtual;
    destructor Free; virtual;
    function BackBuffer: PByte; virtual;
    function BackData: PByte; virtual;
  end;

  TGraphics256Driver = object(TGraphicsDriver)
  public
    MouseCursor: PMouseCursor;
    Palette: PRgbPalette;
    procedure Init; virtual;
    destructor Free; virtual;
    function GetColor256(AColor: TStandardColor; AIntensity: byte): longint; virtual;
    function GetStandardPalette: PRgbPalette; virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure SetStandardPalette; virtual;
    procedure SetRgbPalette(APalette: TRgbPalette); virtual;
    procedure SetForeColor256(AColor: TStandardColor; AIntensity: byte); virtual;
    procedure SetBackColor256(AColor: TStandardColor; AIntensity: byte); virtual;
    procedure ShowMouseCursor; virtual;
    procedure HideMouseCursor; virtual;
    procedure EraseMouseCursor(AMouseState: TMouseState); virtual;
    procedure DrawMouseCursor(AMouseState: TMouseState); virtual;
    procedure MoveMouseCursor(AMouseState, AOldMouseState: TMouseState); virtual;
  end;

implementation

type
  TLargeMouseCursorImage = array[0..14, 0..10] of byte;
  TSmallMouseCursorImage = array[0..8, 0..7] of byte;

const
  DefaultSmallMouseCursor: TSmallMouseCursorImage =
  (
    ($27, $27, $27, $27, $27, $20, $01, $01),
    ($27, $00, $00, $00, $27, $20, $01, $01),
    ($27, $00, $00, $00, $27, $20, $01, $01),
    ($27, $00, $00, $00, $00, $27, $20, $01),
    ($27, $27, $27, $00, $00, $00, $27, $20),
    ($20, $20, $20, $27, $00, $00, $27, $20),
    ($01, $01, $01, $20, $27, $27, $27, $20),
    ($01, $01, $01, $01, $20, $20, $20, $20),
    ($01, $01, $01, $01, $01, $01, $01, $01)
  );

  DefaultMouseCursor: TLargeMouseCursorImage =
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

procedure TGraphics256Driver.Init;
var
  oldMode: byte;
begin
  inherited Init;
  Palette := nil;
  MouseCursor := nil;
end;

procedure TGraphics256Driver.SetMode(AMode: PGraphicsMode);
begin
  inherited SetMode(AMode);
  if MouseCursor <> nil then
    FreeAndNil(MouseCursor);
  MouseCursor := New(PMouseCursor, Create(@self));
end;

procedure TGraphics256Driver.MoveMouseCursor(AMouseState, AOldMouseState: TMouseState);
var
  oldRect, newRect: TRect;
begin
  if (not MouseCursor^.Visible) or not (AMouseState.Visible) then
    exit;
  if MouseCursor^.FBackData <> nil then begin
    EraseMouseCursor(AOldMouseState);

  end;
  DrawMouseCursor(AMouseState);
end;

procedure TGraphics256Driver.EraseMouseCursor(AMouseState: TMouseState);
begin
  if (not MouseCursor^.Visible) or not (AMouseState.Visible) then
    exit;
  if MouseCursor^.FBackData <> nil then
    DrawImage(AMouseState.X, AMouseState.Y, MouseCursor^.Width, MouseCursor^.Height, MouseCursor^.FBackData);
end;

procedure TGraphics256Driver.DrawMouseCursor(AMouseState: TMouseState);
begin
  if (not MouseCursor^.Visible) or (not AMouseState.Visible) then
    exit;
  MouseCursor^.StoreBackground(AMouseState.X, AMouseState.Y);
  MouseCursor^.X := AMouseState.X;
  MouseCursor^.Y := AMouseState.Y;
  MouseCursor^.Draw;
end;

procedure TGraphics256Driver.ShowMouseCursor;
var
  mouseState: TMouseState;
begin
  Mouse.ShowMouse;
  Mouse.GetMouseState(mouseState);
  MouseCursor^.Visible := true;
  DrawMouseCursor(mouseState);
end;

procedure TGraphics256Driver.HideMouseCursor;
begin
  if (not MouseCursor^.Visible) then exit;
  State^.ViewPort.SetDims(0, 0, Mode^.Width, Mode^.Height);
  EraseMouseCursor(Mouse.State^);
  MouseCursor^.Visible := false;
  Mouse.HideMouse;
end;

procedure TGraphics256Driver.SetStandardPalette;
begin
  if Palette <> nil then
    Dispose(Palette);
  Palette := GetStandardPalette;
  SetRgbPalette(Palette^);
end;

function TGraphics256Driver.GetStandardPalette: PRgbPalette;
var
  colorIndex: TStandardColor;
  shadeIndex, shade: integer;
  paletteIndex: integer;
  index: integer;
  newPalette: PRgbPalette;
begin
  newPalette := New(PRgbPalette);
  FillChar(newPalette^, SizeOf(TRgbPalette), 0);

  for Index := 0 to 21 do begin
    newPalette^[index].Red := 0;
    newPalette^[index].Green := 0;
    newPalette^[index].Blue := 0;
  end;
  paletteIndex := 22;

  for colorIndex := scWhite to scFleshTone do begin
    for shadeIndex := 1 to 18 do begin
      shade := shadeIndex * 14 + 3;
      case colorIndex of
        scWhite: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scRed: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := 0;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scGreen: begin
          newPalette^[paletteIndex].Red := 0;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scBlue: begin
          newPalette^[paletteIndex].Red := 0;
          newPalette^[paletteIndex].Green := 0;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scYellow: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scMagenta: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := 0;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scCyan: begin
          newPalette^[paletteIndex].Red := 0;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scOrange: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := shade div 2;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scBrown: begin
          newPalette^[paletteIndex].Red := Round(shade / 1.7);
          newPalette^[paletteIndex].Green := shade div 2;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scSpringGreen: begin
          newPalette^[paletteIndex].Red := shade div 2;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := shade div 2;
        end;
        scAzure: begin
          newPalette^[paletteIndex].Red := shade div 3;
          newPalette^[paletteIndex].Green := shade div 3;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scViolet: begin
          newPalette^[paletteIndex].Red := shade div 2;
          newPalette^[paletteIndex].Green := 0;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scFleshTone: begin
          newPalette^[paletteIndex].Red := 215 - Round((shadeIndex / 18) * 115);
          newPalette^[paletteIndex].Green := 190 - Round((shadeIndex / 18) * 135);
          newPalette^[paletteIndex].Blue := 140 - Round((shadeIndex / 18) * 135);
        end;
      end;
      Inc(paletteIndex);
    end;
  end;
  GetStandardPalette := newPalette;
end;

procedure TGraphics256Driver.SetRgbPalette(APalette: TRgbPalette);
var
  reg: Registers;
  segm, offs: word;
  index: integer;
begin
  for index := 0 to 255 do begin
    with APalette[index] do begin
      Red := Red shr 2;
      Green := Green shr 2;
      Blue := Blue shr 2;
    end;
  end;

  segm := Seg(APalette);
  offs := Ofs(APalette);

  asm
    push  ES
    mov   AX, 1012h
    mov   BX, 0
    mov   CX, 00FFh
    mov   ES, [segm]
    mov   DX, [offs]
    int   10h
    pop   ES
  end;
end;

destructor TGraphics256Driver.Free;
begin
  if MouseCursor <> nil then
    Dispose(MouseCursor, Free);
  if Palette <> nil then
    Dispose(Palette);
  inherited Free;
end;

function TGraphics256Driver.GetColor256(AColor: TStandardColor; AIntensity: byte): longint;
begin
  if AColor = scBlack then begin
    GetColor256 := 0;
    exit;
  end;
  GetColor256 := 21 + ord(AColor) * 18 + AIntensity;
end;

procedure TGraphics256Driver.SetForeColor256(AColor: TStandardColor; AIntensity: byte);
begin
  SetForeColor(GetColor256(AColor, AIntensity));
end;

procedure TGraphics256Driver.SetBackColor256(AColor: TStandardColor; AIntensity: byte);
begin
  SetBackColor(GetColor256(AColor, AIntensity));
end;

constructor TMouseCursor.Create(ADriver: PGraphicsDriver);
begin
  inherited Create;
  FGraph := ADriver;
end;

procedure TMouseCursor.Init;
begin
  TObject.Init;
  Width := 8;
  Height := 9;
  Visible := true;
  Y := 0;
  X := 0;
  FBackData := nil;
  FBackBuffer := nil;
  Image := @DefaultSmallMouseCursor;
end;

procedure TMouseCursor.Draw;
begin
  if not Visible then
    exit;
  FGraph^.PushState;
  FGraph^.State^.ViewPort.SetRect(FGraph^.Mode^.Bounds);
  FGraph^.DrawImageT(X, Y, Width, Height, Image);
  FGraph^.PopState;
end;

procedure TMouseCursor.StoreBackground(AX, AY: integer);
var
  rect: TRect;
begin
  if FBackData = nil then
    GetMem(FBackData, Width * Height);
  rect.CreateDims(AX, AY, Width, Height);
  FGraph^.PushState;
  FGraph^.State^.ViewPort.SetRect(FGraph^.Mode^.Bounds);
  FGraph^.GetImage(AX, AY, Width, Height, FBackData);
  FGraph^.PopState;
end;

destructor TMouseCursor.Free;
begin
  if FBackData <> nil then
    FreeMem(FBackData, Width * Height);
  if FBackBuffer <> nil then
    FreeMem(FBackBuffer, Width * Height * 2);
  inherited Free;
end;

function TMouseCursor.BackBuffer: PByte;
begin
  BackBuffer := FBackBuffer;
end;

function TMouseCursor.BackData: PByte;
begin
  BackData := FBackData;
end;

end.