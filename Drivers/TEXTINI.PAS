{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I-,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit TextIni;

interface

uses
 Objects,
 TextDrv,
 DirTxDrv;

type
  TTextDrivers =
  (
    tdDirect,
    tdAnsi
  );
  PTextDriverFactory = ^TTextDriverFactory;
  TTextDriverFactory = object(TBaseObject)
  public
    procedure Init; virtual;
    procedure CreateTextDriver(driverId: TTextDrivers; var driver: PTextDriver);
  end;

implementation

procedure TTextDriverFactory.Init;
begin
end;

procedure TTextDriverFactory.CreateTextDriver(driverId: TTextDrivers; var driver: PTextDriver);
begin
  case driverId of
    tdDirect: begin
      driver := New(PDirectTextDriver, Create);
    end;
    tdAnsi: begin
    end;
  end;
end;

end.