{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit GraphApp;

interface

uses
  Objects,
  Collects,
  Except,
  Apps,
  Graph8,
  GraphDrv,
  Vga8Drv,
  GraphIni;

type
  PGraphApp = ^TGraphApp;

  TGraphApp = object(TApplication)
  private
    FDriverId: TGraphDrivers;
    FModeId: string;
  public
    constructor Create(ADriverId: TGraphDrivers; AModeId: string);
    procedure Init; virtual;
    procedure InitGraphics(ADriverId: TGraphDrivers);
    procedure ProcessEvents; virtual;
    destructor Free; virtual;
  end;

var
  Graph256: PGraphics256Driver;

implementation

constructor TGraphApp.Create(ADriverId: TGraphDrivers; AModeId: string);
begin
  FDriverId := ADriverId;
  FModeId := AModeId;
  inherited Create;
end;

procedure TGraphApp.InitGraphics(ADriverId: TGraphDrivers);
var
  mode: PGraphicsMode;
begin
  InitGraphicsDriver(ADriverId);
  Graph256 := PGraphics256Driver(Graph);
  mode := Graph^.Modes^.GetItemById(FModeId);
  if mode = nil then begin
    WriteLn('Graphics mode not supported.');
    Close;
    exit;
  end;
  Graph^.SetMode(mode);
  if Graph^.HasException then begin
    WriteLn(ErrorMessage(Graph^.Exception^.Code));
    Close;
  end;
end;

procedure TGraphApp.Init;
begin
  inherited Init;
  InitGraphics(FDriverId);
end;

destructor TGraphApp.Free;
begin
  FreeGraphicsDriver;
  inherited Free;
end;

procedure TGraphApp.ProcessEvents;
begin
  inherited ProcessEvents;
end;

end.