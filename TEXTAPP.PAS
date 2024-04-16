{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q+,R-,S-,T+,V-,X+}
{$ENDIF}
unit TextApp;

interface

uses
  Objects,
  Lists,
  Errors,
  AplApps,
  KeyDrv,
  TextDrv,
  TextIni;

type
  PTextApplication = ^TTextApplication;

  TTextApplication = object(TApplication)
  private
    FDriverId: TTextDrivers;
    FModeId: string;
    procedure InitText(ADriverId: TTextDrivers);
  public
    constructor Create(ADriverId: TTextDrivers; AModeId: string);
    procedure Init; virtual;
    procedure ProcessEvents; virtual;
    destructor Free; virtual;
  end;

implementation

constructor TTextApplication.Create(ADriverId: TTextDrivers; AModeId: string);
begin
  FDriverId := ADriverId;
  FModeId := AModeId;
  inherited Create;
end;

procedure TTextApplication.InitText(ADriverId: TTextDrivers);
var
  mode: PTextMode;
begin
  InitTextDriver(ADriverId);
  mode := TextDriver^.Modes^.GetItemById(FModeId);
  if not Assigned(mode) then begin
    WriteLn(ErrorMessage(ecTextModeNotFound));
    Close;
    exit;
  end;
  WriteLn('Text driver initialized.');
  TextDriver^.SetMode(mode);
  if TextDriver^.HasException then begin
    FreeAndNil(TextDriver);
    WriteLn(ErrorMessage(TextDriver^.Exception^.Code));
    Close;
  end;
end;

procedure TTextApplication.Init;
begin
  inherited Init;
  InitText(FDriverId);
end;

destructor TTextApplication.Free;
begin
  FreeTextDriver;
  Keyboard.CursorOn;
  inherited Free;
end;

procedure TTextApplication.ProcessEvents;
begin
  inherited ProcessEvents;
end;

end.