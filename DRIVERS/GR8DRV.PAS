{$I COMPILER.INC}
unit Gr8Drv;

interface

uses
  AplTypes,
  AplObj,
  AplUtils,
  Drawing,
  Lists,
  AplConst,
  AplMath,
  AplStr,
  Graphics,
  MemDrv,
  Palettes,
  Strings;

type
  PGraphics8Driver = ^TGraphics8Driver;

  TGraphics8Driver = object(TGraphicsDriver)
  public
    Palette: PRgbPalette;
    procedure Init; virtual;
    destructor Free; virtual;
    function GetColor8(AColor: TStandardColor; AIntensity: byte): longint; virtual;
    procedure GetStandardColor(AColor: longint; var AStandardColor: TStandardColor; var AIntensity: byte); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure SetVgaPaletteData(APalette: PRgbColors); virtual;
    procedure SetVgaPalette; virtual;
    procedure SetForeColor8(AColor: TStandardColor; AIntensity: byte); virtual;
    procedure SetBackColor8(AColor: TStandardColor; AIntensity: byte); virtual;
    function ClosestColor(var AColor: TRgbColor): byte; virtual;
  end;

implementation

procedure TGraphics8Driver.Init;
var
  oldMode: byte;
begin
  inherited Init;
  Palette := New(PRgbPalette, CreateVgaStandard);
end;

procedure TGraphics8Driver.SetMode(AMode: PGraphicsMode);
begin
  inherited SetMode(AMode);
end;

procedure TGraphics8Driver.SetVgaPalette;
var
  color: TRgbColor;
  index: byte;
  result: PRgbColors;
begin
  result := Palette^.GetPaletteDataVga;
  SetVgaPaletteData(result);
  FreeMem(result, Palette^.ColorCount * SizeOf(TRgbColor));
end;

function TGraphics8Driver.ClosestColor(var AColor: TRgbColor): byte;
var
  closest: integer;
  closestMag: longint;
  index: integer;
  mag: longint;
  function Magnitude(const AColor1, AColor2: TRgbColor): longint;
  var
    mg: byte;
    mc: array[0..2] of word;
    mt: longint;
    ml, mh: word;
  begin
    mc[0] := Abs(AColor1.Red - AColor2.Red);
    mc[1] := Abs(AColor1.Green - AColor2.Green);
    mc[2] := Abs(AColor1.Blue - AColor2.Blue);
    mt := SumW(@mc, 3);
    ml := LowestW(@mc, 3);
    mh := HighestW(@mc, 3);
    Magnitude := (mh - ml) * mt;
  end;
begin
  closest := -1;
  closestMag := MaxLongint;
  for index := 0 to 255 do begin
    mag := Magnitude(AColor, Palette^.Colors^[index]);
    if mag < closestMag then begin
      closest := index;
      closestMag := mag;
    end;
  end;
  ClosestColor := closest;
end;


procedure TGraphics8Driver.SetVgaPaletteData(APalette: PRgbColors);
var
  segm, offs: word;
  index: integer;
begin
  segm := Seg(APalette^);
  offs := Ofs(APalette^);

  asm
    mov   AX, 1012h
    mov   BX, 0
    mov   CX, 00FFh
    mov   ES, [segm]
    mov   DX, [offs]
    int   10h
  end;
end;

destructor TGraphics8Driver.Free;
begin
  if Assigned(Palette) then
    Dispose(Palette);
  inherited Free;
end;

procedure TGraphics8Driver.GetStandardColor(AColor: longint;
  var AStandardColor: TStandardColor; var AIntensity: byte);
begin
  if AColor = 0 then begin
    AStandardColor := scEga;
    AIntensity := 0;
    exit;
  end;
  AStandardColor := TStandardColor((AColor - 1) div 16);
  AIntensity := (AColor - 1) mod 16 + 1;
end;

function TGraphics8Driver.GetColor8(AColor: TStandardColor; AIntensity: byte): longint;
begin
  if AColor = scEga then begin
    GetColor8 := 0;
    exit;
  end;
  GetColor8 := Ord(AColor) * 16 + AIntensity;
end;

procedure TGraphics8Driver.SetForeColor8(AColor: TStandardColor; AIntensity: byte);
begin
  SetForeColor(GetColor8(AColor, AIntensity));
end;

procedure TGraphics8Driver.SetBackColor8(AColor: TStandardColor; AIntensity: byte);
begin
  SetBackColor(GetColor8(AColor, AIntensity));
end;

end.