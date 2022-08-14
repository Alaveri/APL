{$I COMPILER.INC}
unit Apps;

interface

uses
  Crt,
  Objects,
  MemDrv,
  KeyDrv,
  Dos,
  Utils,
  StrUtils,
  MouseDrv;

type
  PApplication = ^TApplication;
  TApplication = object(TObject)
  private
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

var
  Keyboard: TKeyboardDriver;

constructor TApplication.Create(newId: string; interfaceMem: longint);
begin
  InterfaceMemory := interfaceMem;
  Init;
  Id := NewLargeString(newId);
end;

procedure TApplication.Init;
begin
  inherited Init;
  ClrScr;
  MouseDriver := New(PMouseDriver, Create);
  Memory := new(PMemDrv, CreateReserved(InterfaceMemory));
  WriteLn('Mouse initialized.');
{  Keyboard.Create;}
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
  Dispose(Memory, Done);
{  Keyboard.Done;}
  while KeyPressed do ReadKey;
  DisposeLargeString(EmptyString);
  TObject.Done;
end;

end.