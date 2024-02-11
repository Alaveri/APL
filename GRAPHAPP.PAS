{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit GraphApp;

interface

uses
  Objects,
  Lists,
  Except,
  Apps,
  GrDrv8,
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
  Graph8: PGraphics8Driver;

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
  Graph8 := PGraphics8Driver(Graph);
  mode := Graph^.Modes.GetItemById(FModeId);
  if not Assigned(mode) then begin
    WriteLn(ErrorMessage(ecGraphicsModeNotFound));
    Close;
    exit;
  end;
  WriteLn('Graphics initialized.');
  Graph^.SetMode(mode);
  if Graph^.HasException then begin
    FreeAndNil(Graph);
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