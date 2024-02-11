{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Apps;

interface

uses
  Objects,
  MemDrv,
  Dos,
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
    constructor Create;
    procedure Init; virtual;
    procedure Run; virtual;
    procedure Close; virtual;
    procedure MainLoop; virtual;
    procedure ProcessEvents; virtual;
    procedure Error(ASender: pointer; ACode: word);
    destructor Free; virtual;
  end;

implementation

constructor TApplication.Create;
begin
  inherited Create;
end;

procedure TApplication.Error(ASender: pointer; ACode: word);
begin
  if Assigned(OnError) then
    TApplicationErrorProc(OnError)(ASender, ACode);
end;

procedure TApplication.Init;
begin
  inherited Init;
  Mouse.Create;
  WriteLn('Mouse initialized.');
  Keyboard.Create;
  WriteLn('Keyboard initialized.');
  Closed := false;
  OnError := nil;
end;

procedure TApplication.Run;
begin
  repeat
    ProcessEvents;
    if Closed then
      exit;
    MainLoop;
  until Closed;
end;

procedure TApplication.ProcessEvents;
begin
end;

procedure TApplication.Close;
begin
  Closed := true;
end;

procedure TApplication.MainLoop;
begin
end;

destructor TApplication.Free;
begin
  Mouse.Free;
  Keyboard.Free;
  inherited Free;
end;

end.