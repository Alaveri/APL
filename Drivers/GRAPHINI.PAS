{$I COMPILER.INC}
unit GraphIni;

interface

uses
  GraphDrv,
  Svga8Drv,
  SvgaBgi8,
  FastVga8,
  Vga8Drv;

type
  TGraphDrivers =
  (
    gdVga8,
    gdSVga8,
    gdSVgaBgi8,
    gdFastVga8
{    gdEga,
    gdCga,
    gdHercules,
    gdVgaModeX}
  );

procedure InitGraphicsDriver(ADriverId: TGraphDrivers);

implementation

procedure InitGraphicsDriver(ADriverId: TGraphDrivers);
begin
  case ADriverId of
{    gdHercules: Graph := New(PHerculesDriver, Create);}
{    gdCga: Graph := New(PCgaDriver, Create);
    gdEga: Graph := New(PEgaDriver, Create);}
    gdVga8: Graph := New(PVga8Driver, Create);
    gdFastVga8: Graph := New(PFastVgaDriver, Create);
    gdSVga8: Graph := New(PSVga8Driver, Create);
    gdSVgaBgi8: Graph := New(PSVgaBgiDriver, Create);
{    gdVgaModeX: Graph := New(PVgaModeXDriver, Create);}
  end;
end;

end.
