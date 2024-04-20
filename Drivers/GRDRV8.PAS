{$I COMPILER.INC}
unit GrDrv8;

interface

uses
  {$IFDEF DOS}
  Strings,
  {$ENDIF}
  Objects,
  Common,
  Drawing,
  Lists,
  AplConst,
  StrUtils,
  Streams,

  MouseDrv,
  GraphDrv,
  MemDrv;

const
  MinIntensity = 1;
  MaxIntensity = 18;
  Intensity50 = 9;
  Intensity25 = 4;
  Intensity75 = 14;
  TransparentColor: byte = 1;

type
  PGraphics8Driver = ^TGraphics8Driver;
  PMouseCursor = ^TMouseCursor;
  PMouseCursorList = ^TMouseCursorList;
  PRgbPalette = ^TRgbPalette;

  TLargeMouseCursorImage = array[0..14, 0..7] of byte;
  TSmallMouseCursorImage = array[0..8, 0..7] of byte;

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
    procedure GetStandardColor(AColor: longint;
      var AStandardColor: TStandardColor; var AIntensity: byte); virtual;
    function GetStandardPalette: PRgbPalette; virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure SetStandardPalette; virtual;
    procedure SetRgbPalette(APalette: PRgbPalette); virtual;
    procedure SetForeColor8(AColor: TStandardColor; AIntensity: byte); virtual;
    procedure SetBackColor8(AColor: TStandardColor; AIntensity: byte); virtual;
    procedure ShowMouseCursor; virtual;
    procedure HideMouseCursor; virtual;
    procedure EraseMouseCursor(const AMouseState: TMouseState); virtual;
    procedure DrawMouseCursor(const AMouseState: TMouseState); virtual;
    procedure MoveMouseCursor(const AMouseState, AOldMouseState: TMouseState); virtual;
  end;

  TMouseCursorList = object(TIdentifiableList)
  private
  public
    function IndexOf(AItem: PMouseCursor): integer;
    function Add(AItem: PMouseCursor): integer;
    function GetItem(AIndex: integer): PMouseCursor;
    function GetItemById(const AId: string): PMouseCursor;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PMouseCursor);
  end;

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
    ($27, $01, $01, $01, $01, $01, $01, $01),
    ($27, $27, $01, $01, $01, $01, $01, $01),
    ($27, $00, $27, $01, $01, $01, $01, $01),
    ($27, $00, $00, $27, $01, $01, $01, $01),
    ($27, $00, $00, $00, $27, $01, $01, $01),
    ($27, $00, $00, $00, $00, $27, $01, $01),
    ($27, $00, $00, $00, $00, $00, $27, $01),
    ($27, $00, $00, $00, $00, $00, $00, $27),
    ($27, $00, $00, $00, $00, $00, $00, $27),
    ($27, $00, $00, $00, $27, $27, $27, $01),
    ($27, $00, $00, $27, $01, $01, $01, $01),
    ($01, $27, $27, $01, $01, $01, $01, $01),
    ($01, $01, $01, $01, $01, $01, $01, $01),
    ($01, $01, $01, $01, $01, $01, $01, $01),
    ($01, $01, $01, $01, $01, $01, $01, $01)
  );

  DefaultBeamMouseCursor: TLargeMouseCursorImage =
  (
    ($27, $27, $27, $01, $27, $27, $27, $01),
    ($27, $00, $00, $27, $00, $00, $27, $01),
    ($27, $27, $27, $00, $27, $27, $27, $01),
    ($01, $01, $27, $00, $27, $01, $01, $01),
    ($01, $01, $27, $00, $27, $01, $01, $01),
    ($01, $01, $27, $00, $27, $01, $01, $01),
    ($01, $01, $27, $00, $27, $01, $01, $01),
    ($01, $01, $27, $00, $27, $01, $01, $01),
    ($01, $01, $27, $00, $27, $01, $01, $01),
    ($01, $01, $27, $00, $27, $01, $01, $01),
    ($01, $01, $27, $00, $27, $01, $01, $01),
    ($01, $01, $27, $00, $27, $01, $01, $01),
    ($27, $27, $27, $00, $27, $27, $27, $01),
    ($27, $00, $00, $27, $00, $00, $27, $01),
    ($27, $27, $27, $01, $27, $27, $27, $01)
  );

implementation

procedure TGraphics8Driver.Init;
var
  oldMode: byte;
begin
  inherited Init;
  Palette := nil;
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
  State.ViewPort.SetDims(0, 0, Mode^.Width, Mode^.Height);
  Mouse.ShowMouse;
  Mouse.UpdateState;
  MouseCursor^.Visible := true;
  DrawMouseCursor(Mouse.State);
end;

procedure TGraphics8Driver.HideMouseCursor;
begin
  if not MouseCursor^.Visible then
    exit;
  State.ViewPort.SetDims(0, 0, Mode^.Width, Mode^.Height);
  EraseMouseCursor(Mouse.State);
  MouseCursor^.Visible := false;
  Mouse.HideMouse;
end;

procedure TGraphics8Driver.SetStandardPalette;
begin
  FreeAndNil(Palette);
  Palette := GetStandardPalette;
  SetRgbPalette(Palette);
end;

function TGraphics8Driver.GetStandardPalette: PRgbPalette;
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

procedure TGraphics8Driver.SetRgbPalette(APalette: PRgbPalette);
var
  segm, offs: word;
  index: integer;
begin
  for index := 0 to 255 do begin
    with APalette^[index] do begin
      Red := Red shr 2;
      Green := Green shr 2;
      Blue := Blue shr 2;
    end;
  end;

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
    AStandardColor := scBlack;
    AIntensity := 0;
    exit;
  end;
  AStandardColor := TStandardColor((AColor - 22) div 18);
  AIntensity := (AColor - 22) mod 18 + 1;
end;

function TGraphics8Driver.GetColor8(AColor: TStandardColor; AIntensity: byte): longint;
begin
  if AColor = scBlack then begin
    GetColor8 := 0;
    exit;
  end;
  GetColor8 := 21 + Ord(AColor) * 18 + AIntensity;
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
  Graph^.State.ViewPort.SetRect(Graph^.Mode^.Bounds);
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
  Graph^.State.ViewPort.SetRect(Graph^.Mode^.Bounds);
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

function TMouseCursorList.IndexOf(AItem: PMouseCursor): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TMouseCursorList.Add(AItem: PMouseCursor): integer;
begin
  Add := inherited Add(AItem);
end;

function TMouseCursorList.GetItem(AIndex: integer): PMouseCursor;
begin
  GetItem := PMouseCursor(inherited GetItem(AIndex));
end;

procedure TMouseCursorList.Init;
begin
  inherited Init;
end;

procedure TMouseCursorList.Insert(AIndex: integer; AItem: PMouseCursor);
begin
  inherited Insert(AIndex, AItem);
end;

function TMouseCursorList.GetItemById(const AId: string): PMouseCursor;
begin
  GetItemById := PMouseCursor(inherited GetItemById(AId));
end;

end.