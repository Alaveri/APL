{$I COMPILER.INC}
unit TextIni;

interface

uses
  AplObj,
  AplTypes,
  TextType,
  DrTxtDrv;

procedure InitTextDriver(ADriverId: TTextDrivers);

implementation

uses
  TextDrv;

procedure InitTextDriver(ADriverId: TTextDrivers);
begin
  Text := nil;
  case ADriverId of
    tdDirect: Text := New(PDirectTextDriver, Create);
  end;
end;

end.