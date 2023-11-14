{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
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

procedure CreateTextDriver(ADriverId: TTextDrivers);

implementation

procedure CreateTextDriver(ADriverId: TTextDrivers);
begin
  case ADriverId of
    tdDirect: TextDriver := New(PDirectTextDriver, Create);
    tdAnsi: ;
  end;
end;

end.