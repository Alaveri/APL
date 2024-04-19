{$I COMPILER.INC}
unit GraphIni;

interface

uses
  Objects,
  GraphDrv,
  Svga8Drv,
  Vga8Drv,
  EgaDrv,
  HercDrv,
  CgaDrv,
  UVga8Drv;

type
  TGraphDrivers =
  (
    gdVga8,
    gdSVga8,
    gdEga,
    gdCga,
    gdHercules,
    gdVgaUnchained
  );

procedure InitGraphicsDriver(ADriverId: TGraphDrivers);

implementation

procedure InitGraphicsDriver(ADriverId: TGraphDrivers);
begin
  case ADriverId of
    gdHercules: Graph := New(PHerculesDriver, Create);
    gdCga: Graph := New(PCgaDriver, Create);
    gdEga: Graph := New(PEgaDriver, Create);
    gdVga8: Graph := New(PVga8Driver, Create);
    gdSVga8: Graph := New(PSVga8Driver, Create);
    gdVgaUnchained: Graph := New(PVgaUnchainedDriver, Create);
  end;
end;

end.
