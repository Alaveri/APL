{$I COMPILER.INC}
unit GraphIni;

interface

uses
 Objects,
 Svga8Drv,
 Vga8Drv,
 EgaDrv,
 HercDrv,
 CgaDrv,
 GraphDrv;

type
  TGraphDrivers =
  (
    gdVga256,
    gdSVga256,
    gdEga,
    gdCga,
    gdHercules
  );

  PGraphicsFactory = ^TGraphicsFactory;

  TGraphicsFactory = object(TBaseObject)
  public
    procedure Init; virtual;
    constructor CreateGraphicsDriver(driverId: TGraphDrivers; var driver: PGraphicsDriver);
  end;

implementation

procedure TGraphicsFactory.Init;
begin
  inherited Init;
end;

constructor TGraphicsFactory.CreateGraphicsDriver(driverId: TGraphDrivers; var driver: PGraphicsDriver);
begin
  case driverId of
    gdHercules: driver := new(PHerculesDriver, Create);
    gdCga: driver := New(PCgaDriver, Create);
    gdEga: driver := New(PEgaDriver, Create);
    gdVga256: driver := New(PVga8Driver, Create);
    gdSVga256: driver := New(PSVga8Driver, Create);
  end;
end;

end.
