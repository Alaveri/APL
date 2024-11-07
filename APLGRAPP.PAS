{$I COMPILER.INC}
unit AplGrApp;

interface

uses
  AplObj,
  AplLists,
  AplApps,
  AplGrap8,
  AplGraph,
  AplGrIni;

type
  PGraphApp = ^TGraphApp;

  TGraphApp = object(TApplication)
  private
  public
    constructor Create;
    procedure Init; virtual;
    procedure InitGraphics(ADriverId: TGraphDrivers);
    function SetMode(AModeId: integer): boolean;
    function GetGraphicsModeId(AWidth: integer; AHeight: integer; ABpp: integer): integer;
  end;

var
  Graph8: PGraphics8Driver;

implementation

constructor TGraphApp.Create;
begin
  inherited Create;
end;

procedure TGraphApp.InitGraphics(ADriverId: TGraphDrivers);
begin
  AplGrIni.InitGraphicsDriver(ADriverId);
  Graph8 := PGraphics8Driver(Graph);
end;

function TGraphApp.GetGraphicsModeId(AWidth: integer; AHeight: integer; ABpp: integer): integer;
var
  mode: PGraphicsMode;
  index: integer;
begin
  GetGraphicsModeId := -1;
  for index := 0 to Graph^.Modes.Count - 1 do begin
    mode := Graph^.Modes.GetItem(index);
    if (mode^.Width = AWidth) and (mode^.Height = AHeight) and (mode^.Bpp = ABpp) then begin
      GetGraphicsModeId := mode^.ModeId;
      exit;
    end;
  end;
end;

function TGraphApp.SetMode(AModeId: integer): boolean;
var
  mode: PGraphicsMode;
begin
  SetMode := true;
  mode := Graph^.Modes.GetModeById(AModeId);
  if not Assigned(mode) then begin
    SetMode := false;
    exit;
  end;
  Graph^.SetMode(mode);
  if Graph^.HasException then
    SetMode := false;
end;

procedure TGraphApp.Init;
begin
  inherited Init;
end;

end.