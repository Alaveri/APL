{$I COMPILER.INC}
unit GraphIni;

interface

uses
  GraphDrv,
  Svga8Drv,
  Vga8Drv,
  EgaDrv,
  HercDrv,
  CgaDrv,
  VgaXDrv;

type
  TGraphDrivers =
  (
    gdVga8,
    gdSVga8,
    gdEga,
    gdCga,
    gdHercules,
    gdVgaModeX
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
    gdVgaModeX: Graph := New(PVgaModeXDriver, Create);
  end;
end;

end.
