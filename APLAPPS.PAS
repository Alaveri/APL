{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
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
  private
  public
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