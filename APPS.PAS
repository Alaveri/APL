{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
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

  TApplication = object(TObject)
  private
  public
    Closed: boolean;
    constructor Create;
    procedure Init; virtual;
    procedure Run; virtual;
    procedure Close; virtual;
    procedure MainLoop; virtual;
    procedure ProcessEvents; virtual;
    destructor Free; virtual;
  end;

implementation

constructor TApplication.Create;
begin
  inherited Create;
end;

procedure TApplication.Init;
begin
  inherited Init;
  Mouse.Create;
  WriteLn('Mouse initialized.');
  Keyboard.Create;
  Closed := false;
end;

procedure TApplication.Run;
begin
  repeat
    ProcessEvents;
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