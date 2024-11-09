{$I COMPILER.INC}
unit GraphIni;

interface

uses
  Graphics,
  SVga8Drv,
  Vga8Drv;

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
