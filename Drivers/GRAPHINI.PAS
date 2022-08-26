{$I COMPILER.INC}
unit GraphIni;

interface

uses
 Objects,
 Svga8Drv,
 Vga8Drv,
 GraphDrv;

type
  TGraphDrivers =
  (
    gdVga256,
    gdSVga256
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
    gdVga256:
    begin
      driver := New(PVga8Driver, Create);
    end;
    gdSVga256:
    begin
      driver := New(PSVga8Driver, Create);
    end;
  end;
end;

end.
