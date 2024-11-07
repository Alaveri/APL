{$I COMPILER.INC}
unit AplGrIni;

interface

uses
  AplGraph,
  AplSVga8,
  AplVga8;

type
  TGraphDrivers =
  (
    gdVga8,
    gdSVga8
  );

procedure InitGraphicsDriver(ADriverId: TGraphDrivers);

implementation

procedure InitGraphicsDriver(ADriverId: TGraphDrivers);
begin
  case ADriverId of
    gdVga8: Graph := New(PVga8Driver, Create);
    gdSVga8: Graph := New(PSVga8Driver, Create);
  end;
end;

end.
