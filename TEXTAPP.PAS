{$I COMPILER.INC}
unit TextApp;

interface

uses
  AplObj,
  AplTypes,
  AplConst,
  Lists,
  AplApps,
  KeyDrv,
  AplUtils,
  TextType,
  TextDrv,
  TextIni;

type
  PTextApplication = ^TTextApplication;

  TTextApplication = object(TApplication)
  private
    FDriver: TTextDrivers;
    FMode: TTextModes;
  public
    constructor Create(ADriver: TTextDrivers; AMode: TTextModes);
    procedure SetMode(AMode: TTextModes); virtual;
    procedure Init; virtual;
    procedure InitText(ADriver: TTextDrivers);
  end;

implementation

constructor TTextApplication.Create(ADriver: TTextDrivers; AMode: TTextModes);
begin
  inherited Create;
  FDriver := ADriver;
  FMode := AMode;
end;

procedure TTextApplication.InitText(ADriver: TTextDrivers);
begin
  TextIni.InitTextDriver(ADriver);
  if NilPtr(Text, ecNotEnoughMemory) then
    exit;
  CheckReraise(Text);
end;

procedure TTextApplication.SetMode(AMode: TTextModes);
var
  mode: PTextMode;
begin
  mode := Text^.Modes.GetModeById(AMode);
  if NilPtr(mode, ecTextModeNotFound) then
    exit;
  Text^.SetMode(mode);
  if CheckReraise(Text) then
    exit;
end;

procedure TTextApplication.Init;
begin
  inherited Init;
  FDriver := tdDirect;
  FMode := tmColor80x25;
end;

end.