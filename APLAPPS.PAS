{$I COMPILER.INC}
unit AplApps;

interface

uses
  {$IFDEF DOS}
  Dos,
  {$ENDIF}
  Objects,
  MemDrv,
  AplTypes,
  Common,
  StrUtils,
  KeyDrv,
  MouseDrv;

type
  PApplication = ^TApplication;
  PApplicationErrorProc = ^TApplicationErrorProc;

  TApplicationErrorProc = procedure(ASender: pointer; ACode: word);

  TApplication = object(TObject)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
    Closed: boolean;
    OnError: PApplicationErrorProc;
    procedure Init; virtual;
    procedure Run; virtual;
    procedure Close; virtual;
    procedure ProcessEvents; virtual;
    procedure Error(ASender: pointer; ACode: word); virtual;
  end;

implementation

procedure TApplication.Error(ASender: pointer; ACode: word);
begin
  if Assigned(OnError) then
    TApplicationErrorProc(OnError)(ASender, ACode);
end;

procedure TApplication.Init;
begin
  inherited Init;
  Closed := false;
  OnError := nil;
end;

procedure TApplication.Run;
begin
  repeat
    ProcessEvents;
    if Closed then
      exit;
  until Closed;
end;

procedure TApplication.ProcessEvents;
begin
end;

procedure TApplication.Close;
begin
  Closed := true;
end;

end.