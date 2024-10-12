{$I COMPILER.INC}
unit BgiInter;

interface

uses
  Graph,
  AplObj,
  Errors,
  Lists;

type
  TBgiInterface = object(TStatusObject)
  private
    FGraphDriver: integer;
    FGraphMode: integer;
    FGraphPath: string;
    FInitialized: boolean;
    FDriverName: string;
  public
    constructor Create(const ADriverName: string);
    procedure Init; virtual;
    procedure SetMode(AModeIndex: integer);
  end;

implementation

function DetectVGA256 : integer; far;
var
  driver : integer;
  suggestedMode  : integer;
begin
  DetectGraph(driver, suggestedMode);
  if (driver = VGA) or (driver = MCGA) then
    DetectVGA256 := SuggestedMode
  else
    DetectVGA256 := grError;
end;

constructor TBgiInterface.Create(const ADriverName: string);
begin
  FDriverName := ADriverName;
  inherited Create;
end;

procedure TBgiInterface.Init;
var
  errorCode: integer;
begin
  inherited Init;
  FGraphPath := '';
  FInitialized := false;
  FGraphDriver := InstallUserDriver(FDriverName, @DetectVGA256);
  errorCode := GraphResult;
  if errorCode <> grOk then begin
    Raise(ecGraphicsDriverError);
    exit;
  end;
end;

procedure TBgiInterface.SetMode(AModeIndex: integer);
var
  errorCode: integer;
begin
  if HasException then
    exit;
  if not FInitialized then begin
    InitGraph(FGraphDriver, AModeIndex, FGraphPath);
    errorCode := GraphResult;
    if errorCode <> grOk then begin
      Raise(ecGraphicsDriverError);
      exit;
    end;
    FGraphMode := AModeIndex;
    FInitialized := true;
  end
  else begin
    SetGraphMode(AModeIndex);
    if GraphResult <> grOk then
      Raise(ecGraphicsDriverError);
  end;
end;

end.