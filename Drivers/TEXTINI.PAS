{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
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
    tdDirect: Text := New(PDirectTextDriver, Create);
    tdAnsi: ;
  end;
end;

end.