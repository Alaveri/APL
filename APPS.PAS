{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
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
    _memPtr: pointer;
  public
    Closed: boolean;
    InterfaceMemory: longint;
    constructor Create(newId: string; interfaceMem: longint);
    procedure Init; virtual;
    procedure Run; virtual;
    procedure Close; virtual;
    procedure MainLoop; virtual;
    procedure ProcessEvents; virtual;
    destructor Done; virtual;
  end;

implementation


constructor TApplication.Create(newId: string; interfaceMem: longint);
begin
  InterfaceMemory := interfaceMem;
  Init;
  Id := NewLargeString(newId);
end;

procedure TApplication.Init;
begin
  inherited Init;
  MouseDriver := New(PMouseDriver, Create);
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

destructor TApplication.Done;
begin
  Dispose(MouseDriver, Done);
{  find out what isn't getting disposed}
  Keyboard.Done;
  TObject.Done;
end;

end.