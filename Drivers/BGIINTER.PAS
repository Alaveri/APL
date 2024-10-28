{$I COMPILER.INC}
unit BgiInter;

interface

uses
  Graph,
  AplObj,
  Errors,
  Palettes,
  Drawing,
  GraphDrv,
  Lists;

type
  TBgiInterface = object(TStatusObject)
  private
    FGraphDriver: integer;
    FGraphMode: integer;
    FGraphPath: string;
    FInitialized: boolean;
    FDriverName: string;
  public
    constructor Create(const ADriverName: string);
    procedure Init; virtual;
    procedure SetMode(AModeIndex: integer);
    procedure FillRect(ARect: TRect);
    procedure SetPalette(APalette: PRgbColors);
    procedure PutPixel(APX, APY: integer; AColor: word);
  end;

implementation

uses
  GrDrv8;

var
  Graph8: PGraphics8Driver;

function DetectVGA256 : integer; far;
var
  driver : integer;
  suggestedMode  : integer;
begin
  DetectGraph(driver, suggestedMode);
  if (driver = VGA) or (driver = MCGA) then
    DetectVGA256 := SuggestedMode
  else
    DetectVGA256 := grError;
end;

constructor TBgiInterface.Create(const ADriverName: string);
begin
  FDriverName := ADriverName;
  inherited Create;
end;

procedure TBgiInterface.FillRect(ARect: TRect);
begin
  ARect.Intersect(Graph8^.State^.ViewPort);
  SetFillStyle(SolidFill, Graph8^.State^.BackColor);
  Bar(ARect.X, ARect.Y, ARect.Right, ARect.Bottom);
end;

procedure TBgiInterface.Init;
var
  errorCode: integer;
begin
  inherited Init;
  FGraphPath := '';
  FInitialized := false;
  FGraphDriver := InstallUserDriver(FDriverName, @DetectVGA256);
  errorCode := GraphResult;
  if errorCode <> grOk then begin
    Raise(ecGraphicsDriverError);
    exit;
  end;
end;

procedure TBgiInterface.SetMode(AModeIndex: integer);
var
  errorCode: integer;
begin
  if HasException then
    exit;
  if not FInitialized then begin
    InitGraph(FGraphDriver, AModeIndex, FGraphPath);
    Graph8 := PGraphics8Driver(GraphDrv.Graph);
    errorCode := GraphResult;
    if errorCode <> grOk then begin
      Raise(ecGraphicsDriverError);
      exit;
    end;
    FGraphMode := AModeIndex;
    FInitialized := true;
  end
  else begin
    SetGraphMode(AModeIndex);
    if GraphResult <> grOk then
      Raise(ecGraphicsDriverError);
  end;
  Graph8^.SetVgaPalette;
end;

procedure TBgiInterface.SetPalette(APalette: PRgbColors);
var
  index: integer;
  color: TRgbColor;
begin
  for index := 0 to 255 do begin
    color := APalette^[index];
    SetRGBPalette(index, color.Red shr 2, color.Green shr 2, color.Blue shr 2);
  end;
end;

procedure TBgiInterface.PutPixel(APX, APY: integer; AColor: word);
begin
  Graph.PutPixel(APX, APY, AColor);
end;

end.