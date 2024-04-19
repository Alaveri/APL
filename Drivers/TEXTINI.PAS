{$I COMPILER.INC}
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

procedure InitTextDriver(ADriverId: TTextDrivers);
procedure FreeTextDriver;

implementation

procedure FreeTextDriver;
begin
  FreeAndNil(TextDriver);
end;

procedure InitTextDriver(ADriverId: TTextDrivers);
begin
  case ADriverId of
    tdDirect: TextDriver := New(PDirectTextDriver, Create);
    tdAnsi: ;
  end;
end;

end.