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
  MouseDrv,
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
    procedure InverseHLine(APX, APY, AWidth: integer); virtual;
    procedure InverseVLine(APX, APY, AHeight: integer); virtual;
    procedure InverseRectangle(ARect: TRect); virtual;
  end;

const
  CheckerFillPattern: array[0..15] of word =
  (
    $AAAA,
    $5555,
    $AAAA,
    $5555,
    $AAAA,
    $5555,
    $AAAA,
    $5555,
    $AAAA,
    $5555,
    $AAAA,
    $5555,
    $AAAA,
    $5555,
    $AAAA,
    $5555
  );

  CheckerLinePattern: word = $AAAA;

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
  result: PRgbColors;
begin
  result := Palette^.GetPaletteDataVga;
  SetVgaPaletteData(result);
  FreeMem(result, Palette^.ColorCount * SizeOf(TRgbColor));
  Palette^.SetFormat(pfJasc);
  Palette^.SaveToFile('APL.PAL');
  Palette^.SetFormat(pfGimp);
  Palette^.SaveToFile('APL.GPL');
  Palette^.SetFormat(pfApl);
  color.Red := Random(256);
  color.Green := Random(256);
  color.Blue := Random(256);
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

procedure TGraphics8Driver.InverseHLine(APX, APY, AWidth: integer);
begin
end;

procedure TGraphics8Driver.InverseVLine(APX, APY, AHeight: integer);
begin
end;

procedure TGraphics8Driver.InverseRectangle(ARect: TRect);
begin
  InverseHLine(ARect.X, ARect.Y, ARect.Width);
  InverseHLine(ARect.X, ARect.Bottom, ARect.Width);
  InverseVLine(ARect.X, ARect.Y, ARect.Height);
  InverseVLine(ARect.Right, ARect.Y, ARect.Height);
end;

end.