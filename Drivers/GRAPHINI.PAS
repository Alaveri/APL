{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
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
    constructor CreateGraphicsDriver(driverId: TGraphDrivers);
  end;

implementation

procedure TGraphicsFactory.Init;
begin
  inherited Init;
end;

constructor TGraphicsFactory.CreateGraphicsDriver(driverId: TGraphDrivers);
begin
  case driverId of
    gdHercules: Graphics := New(PHerculesDriver, Create);
    gdCga: Graphics := New(PCgaDriver, Create);
    gdEga: Graphics := New(PEgaDriver, Create);
    gdVga256: Graphics := New(PVga8Driver, Create);
    gdSVga256: Graphics := New(PSVga8Driver, Create);
  end;
end;

end.
