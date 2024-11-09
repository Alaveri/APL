{$I COMPILER.INC}
unit AplApps;

interface

uses
  AplObj,
  AplConst,
  MemDrv,
  Lists,
  AplTypes,
  AplUtils,
  KeyDrv,
  MouseDrv,
  AplStr;

const
  mUser = 10000;

type
  PApplication = ^TApplication;
  PApplicationErrorProc = ^TApplicationErrorProc;
  PMessage = ^TMessage;
  PKeyMessage = ^TKeyMessage;
  PMouseMessage = ^TMouseMessage;
  PMessageObject = ^TMessageObject;

  TApplicationErrorProc = procedure(var ASender; ACode: word);

  TMessageType = (mMessage, mMouse, mKey);

  TMessageObject = object(TIdentifiable)
  private
  public
    procedure ProcessMessage(var AMessage: PMessage); virtual;
  end;

  TMessage = object(TObject)
  private
  public
    Sender: PObject;
    Target: PObject;
    Code: word;
    MessageType: TMessageType;
    Processed: boolean;
    constructor Create(var ASender; ACode: word);
    procedure Init; virtual;
  end;

  TMouseMessage = object(TMessage)
  private
  public
    MouseState: TMouseState;
    constructor Create(var ASender; ACode: word; var AMouseState: TMouseState);
    procedure Init; virtual;
  end;

  TKeyMessage = object(TMessage)
  private
    Key: word;
    ScanCode: byte;
    ShiftState: TKeyboardFlags;
    constructor Create(var ASender; ACode: word; AKey: word);
    procedure Init; virtual;
  end;

  TMessageQueue = object(TObjectQueue)
  private
  public
    function Enq(AObject: PMessage): integer;
    function Deq: PMessage;
  end;

  TApplication = object(TStatusObject)
  private
  public
    Closed: boolean;
    OnError: PApplicationErrorProc;
    MessageQueue: TMessageQueue;
    destructor Free; virtual;
    procedure Init; virtual;
    procedure Run; virtual;
    procedure Close; virtual;
    procedure ProcessMessages; virtual;
    procedure ProcessEvents; virtual;
    procedure Error(var ASender; ACode: word); virtual;
    procedure PostMessage(ASender, ATarget: PObject; ACode: word);
    procedure SendMessage(ASender, ATarget: PObject; ACode: word);
  end;

implementation

var
  Application: PApplication;

function AllocError(ASize: word): boolean;
begin
  if Assigned(Application) then
    Application^.Error(Application, ecNotEnoughMemory);
end;

procedure TApplication.Error(var ASender; ACode: word);
begin
  if Assigned(OnError) then
    TApplicationErrorProc(OnError)(ASender, ACode);
end;

procedure TApplication.Init;
begin
  inherited Init;
  Application := @self;
  MessageQueue.Create;
  Closed := false;
  OnError := nil;
  Memory.OnAllocError := @AllocError;
end;

procedure TApplication.PostMessage(ASender, ATarget: PObject; ACode: word);
var
  message: PMessage;
begin
  message := New(PMessage, Create(ASender, ACode));
  if message = nil then
    exit;
  message^.Target := ATarget;
  PMessageObject(ATarget)^.ProcessMessage(message);
  FreeAndNil(message);
end;

procedure TApplication.SendMessage(ASender, ATarget: PObject; ACode: word);
var
  message: PMessage;
begin
  message := New(PMessage, Create(ASender, ACode));
  if message = nil then
    exit;
  message^.Target := ATarget;
  MessageQueue.Enq(message);
end;

destructor TApplication.Free;
begin
  MessageQueue.DisposeAplObj := true;
  MessageQueue.Free;
  inherited Free;
end;

procedure TApplication.ProcessMessages;
begin
end;

procedure TApplication.ProcessEvents;
begin
end;

procedure TApplication.Run;
begin
  repeat
    ProcessMessages;
    ProcessEvents;
    if Closed then
      exit;
  until Closed;
end;

procedure TApplication.Close;
begin
  Closed := true;
end;

constructor TMessage.Create(var ASender; ACode: word);
begin
  inherited Create;
  Sender := @ASender;
  Code := ACode;
end;

procedure TMessage.Init;
begin
  inherited Init;
  Sender := nil;
  Target := nil;
  Code := 0;
  MessageType := mMessage;
  Processed := false;
end;

constructor TMouseMessage.Create(var ASender; ACode: word; var AMouseState: TMouseState);
begin
  inherited Create(ASender, ACode);
  MouseState.Assign(AMouseState);
end;

procedure TMouseMessage.Init;
begin
  inherited Init;
  MouseState.Create;
  MessageType := mMouse;
end;

constructor TKeyMessage.Create(var ASender; ACode: word; AKey: word);
begin
  inherited Create(ASender, ACode);
  Key := AKey;
end;

procedure TKeyMessage.Init;
begin
  inherited Init;
  Code := 0;
  Key := 0;
  MessageType := mKey;
end;

function TMessageQueue.Enq(AObject: PMessage): integer;
begin
  Enq := inherited Enq(AObject);
end;

function TMessageQueue.Deq: PMessage;
begin
  Deq := PMessage(inherited Deq);
end;

procedure TMessageObject.ProcessMessage(var AMessage: PMessage);
begin
end;

end.