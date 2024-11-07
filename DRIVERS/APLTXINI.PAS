{$I COMPILER.INC}
unit AplTxIni;

interface

uses
  AplObj,
  AplTypes,
  AplTxtTp,
  AplDirTx;

procedure InitTextDriver(ADriverId: TTextDrivers);

implementation

uses
  AplText;

procedure InitTextDriver(ADriverId: TTextDrivers);
begin
  Text := nil;
  case ADriverId of
    tdDirect: Text := New(PDirectTextDriver, Create);
  end;
end;

end.