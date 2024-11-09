{$I COMPILER.INC}
unit GrDrv8;

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
  PMouseCursor = ^TMouseCursor;
  PMouseCursorList = ^TMouseCursorList;
  PMouseCursorListProc = ^TMouseCursorListProc;

  TLargeMouseCursorImage = array[0..14, 0..7] of byte;
  TSmallMouseCursorImage = array[0..8, 0..7] of byte;
  TMouseCursorListProc = procedure(ASender: PMouseCursorList; AMouseCursor: PMouseCursor);

  TMouseCursor = object(TIdentifiable)
  private
    FBackData: PByte;
    FBackBuffer: PByte;
  public
    Visible: boolean;
    X, Y: integer;
    OffsetX, OffsetY: integer;
    Image: PByte;
    Width, Height: word;
    constructor Create(AId: string; AWidth, AHeight: integer; AImage: PByte);
    procedure Draw;
    procedure Paint;
    procedure Init; virtual;
    procedure StoreBackground(AX, AY: integer);
    destructor Free; virtual;
    function BackBuffer: PByte;
    function BackData: PByte;
  end;

  TGraphics8Driver = object(TGraphicsDriver)
  public
    MouseCursor: PMouseCursor;
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
    procedure ShowMouseCursor; virtual;
    procedure HideMouseCursor; virtual;
    procedure EraseMouseCursor(const AMouseState: TMouseState); virtual;
    procedure DrawMouseCursor(const AMouseState: TMouseState); virtual;
    procedure MoveMouseCursor(const AMouseState, AOldMouseState: TMouseState); virtual;
    function ClosestColor(var AColor: TRgbColor): byte; virtual;
  end;

  TMouseCursorList = object(TIdentifiableList)
  private
  public
    function GetItem(AIndex: integer): PMouseCursor;
    function GetItemById(const AId: string): PMouseCursor;
    function Add(AItem: PMouseCursor): integer;
    function IndexOf(AItem: PMouseCursor): integer;
    procedure SetItem(AIndex: integer; AItem: PMouseCursor);
    procedure Insert(AIndex: integer; AItem: PMouseCursor);

    procedure Init; virtual;
  end;

const
  DefaultSmallMouseCursor: TSmallMouseCursorImage =
  (
    ($0F, $0F, $0F, $0F, $0F, $0F, $FF, $FF),
    ($0F, $00, $00, $00, $0F, $0F, $FF, $FF),
    ($0F, $00, $00, $00, $0F, $0F, $FF, $FF),
    ($0F, $00, $00, $00, $00, $0F, $0F, $FF),
    ($0F, $0F, $0F, $00, $00, $00, $0F, $0F),
    ($0F, $0F, $0F, $0F, $00, $00, $0F, $0F),
    ($FF, $FF, $FF, $0F, $0F, $0F, $0F, $0F),
    ($FF, $FF, $FF, $FF, $0F, $0F, $0F, $0F),
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF)
  );

  DefaultMouseCursor: TLargeMouseCursorImage =
  (
    ($0F, $FF, $FF, $FF, $FF, $FF, $FF, $FF),
    ($0F, $0F, $FF, $FF, $FF, $FF, $FF, $FF),
    ($0F, $00, $0F, $FF, $FF, $FF, $FF, $FF),
    ($0F, $00, $00, $0F, $FF, $FF, $FF, $FF),
    ($0F, $00, $00, $00, $0F, $FF, $FF, $FF),
    ($0F, $00, $00, $00, $00, $0F, $FF, $FF),
    ($0F, $00, $00, $00, $00, $00, $0F, $FF),
    ($0F, $00, $00, $00, $00, $00, $00, $0F),
    ($0F, $00, $00, $00, $00, $00, $00, $0F),
    ($0F, $00, $00, $00, $0F, $0F, $0F, $FF),
    ($0F, $00, $00, $0F, $FF, $FF, $FF, $FF),
    ($FF, $0F, $0F, $FF, $FF, $FF, $FF, $FF),
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF),
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF),
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF)
  );

  DefaultBeamMouseCursor: TLargeMouseCursorImage =
  (
    ($0F, $0F, $0F, $FF, $0F, $0F, $0F, $FF),
    ($0F, $00, $00, $0F, $00, $00, $0F, $FF),
    ($0F, $0F, $0F, $00, $0F, $0F, $0F, $FF),
    ($FF, $FF, $0F, $00, $0F, $FF, $FF, $FF),
    ($FF, $FF, $0F, $00, $0F, $FF, $FF, $FF),
    ($FF, $FF, $0F, $00, $0F, $FF, $FF, $FF),
    ($FF, $FF, $0F, $00, $0F, $FF, $FF, $FF),
    ($FF, $FF, $0F, $00, $0F, $FF, $FF, $FF),
    ($FF, $FF, $0F, $00, $0F, $FF, $FF, $FF),
    ($FF, $FF, $0F, $00, $0F, $FF, $FF, $FF),
    ($FF, $FF, $0F, $00, $0F, $FF, $FF, $FF),
    ($FF, $FF, $0F, $00, $0F, $FF, $FF, $FF),
    ($0F, $0F, $0F, $00, $0F, $0F, $0F, $FF),
    ($0F, $00, $00, $0F, $00, $00, $0F, $FF),
    ($0F, $0F, $0F, $FF, $0F, $0F, $0F, $FF)
  );

var
  Graph8: PGraphics8Driver;

implementation

procedure TGraphics8Driver.Init;
var
  oldMode: byte;
begin
  inherited Init;
  Graph8 := @self;
  Palette := New(PRgbPalette, CreateVgaStandard);
  MouseCursor := nil;
end;

procedure TGraphics8Driver.SetMode(AMode: PGraphicsMode);
begin
  inherited SetMode(AMode);
  if Assigned(MouseCursor) then
    FreeAndNil(MouseCursor);
end;

procedure TGraphics8Driver.MoveMouseCursor(const AMouseState, AOldMouseState: TMouseState);
var
  oldRect, newRect: TRect;
begin
  if (not MouseCursor^.Visible) or not (AMouseState.Visible) then
    exit;
  WaitForVSync;
  if Assigned(MouseCursor^.FBackData) then
    EraseMouseCursor(AOldMouseState);
  DrawMouseCursor(AMouseState);
end;

procedure TGraphics8Driver.EraseMouseCursor(const AMouseState: TMouseState);
begin
  if (not MouseCursor^.Visible) or not (AMouseState.Visible) then
    exit;
  if Assigned(MouseCursor^.FBackData) then begin
    DrawImage(
      AMouseState.X - MouseCursor^.OffsetX,
      AMouseState.Y - MouseCursor^.OffsetY,
      MouseCursor^.Width,
      MouseCursor^.Height,
      MouseCursor^.FBackData
    );
  end;
end;

procedure TGraphics8Driver.DrawMouseCursor(const AMouseState: TMouseState);
begin
  if (not MouseCursor^.Visible) or (not AMouseState.Visible) then
    exit;
  MouseCursor^.StoreBackground(AMouseState.X, AMouseState.Y);
  MouseCursor^.X := AMouseState.X;
  MouseCursor^.Y := AMouseState.Y;
  MouseCursor^.Draw;
end;

procedure TGraphics8Driver.ShowMouseCursor;
begin
  State^.ViewPort.SetDims(0, 0, Mode^.Width, Mode^.Height);
  Mouse.ShowMouse;
  Mouse.UpdateState;
  MouseCursor^.Visible := true;
  DrawMouseCursor(Mouse.State);
end;

procedure TGraphics8Driver.HideMouseCursor;
begin
  if not MouseCursor^.Visible then
    exit;
  State^.ViewPort.SetDims(0, 0, Mode^.Width, Mode^.Height);
  EraseMouseCursor(Mouse.State);
  MouseCursor^.Visible := false;
  Mouse.HideMouse;
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
  Palette^.SetFormat(pfJasc);
  Palette^.SaveToFile('APL.PAL');
  Palette^.SetFormat(pfGimp);
  Palette^.SaveToFile('APL.GPL');
  Palette^.SetFormat(pfApl);
  color.Red := Random(256);
  color.Green := Random(256);
  color.Blue := Random(256);
  index := ClosestColor(color);
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

constructor TMouseCursor.Create(AId: string; AWidth, AHeight: integer; AImage: PByte);
begin
  inherited CreateId(AId);
  Width := AWidth;
  Height := AHeight;
  Image := AImage;
  GetMem(FBackData, Width * Height);
end;

procedure TMouseCursor.Init;
begin
  inherited Init;
  Width := 0;
  Height := 0;
  Visible := true;
  Y := 0;
  X := 0;
  OffsetX := 0;
  OffsetY := 0;
  FBackData := nil;
  FBackBuffer := nil;
end;

procedure TMouseCursor.Paint;
begin
  Graph^.DrawImageT(X - OffsetX, Y - OffsetY, Width, Height, Image);
end;

procedure TMouseCursor.Draw;
begin
  if not Visible then
    exit;
  Graph^.PushState;
  Graph^.State^.ViewPort.SetRect(Graph^.State^.Bounds);
  Paint;
  Graph^.PopState;
end;

procedure TMouseCursor.StoreBackground(AX, AY: integer);
var
  rect: TRect;
begin
  Dec(AX, OffsetX);
  Dec(AY, OffsetY);
  rect.CreateDims(AX, AY, Width, Height);
  Graph^.PushState;
  Graph^.State^.ViewPort.SetRect(Graph^.State^.Bounds);
  Graph^.GetImage(AX, AY, Width, Height, FBackData);
  Graph^.PopState;
end;

destructor TMouseCursor.Free;
begin
  if Assigned(FBackData) then
    FreeMem(FBackData, Width * Height);
  if Assigned(FBackBuffer) then
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

function TMouseCursorList.GetItem(AIndex: integer): PMouseCursor;
begin
  GetItem := PMouseCursor(inherited GetItem(AIndex));
end;

procedure TMouseCursorList.Init;
begin
  inherited Init;
end;

function TMouseCursorList.GetItemById(const AId: string): PMouseCursor;
begin
  GetItemById := PMouseCursor(inherited GetItemById(AId));
end;

function TMouseCursorList.Add(AItem: PMouseCursor): integer;
begin
  Add := inherited Add(AItem);
end;

function TMouseCursorList.IndexOf(AItem: PMouseCursor): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TMouseCursorList.SetItem(AIndex: integer; AItem: PMouseCursor);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TMouseCursorList.Insert(AIndex: integer; AItem: PMouseCursor);
begin
  inherited Insert(AIndex, AItem);
end;

end.