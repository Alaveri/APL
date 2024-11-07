{$I COMPILER.INC}
unit AplObj;

interface

uses
  AplConst,
  AplStr,
  Strings;

type
  PObject = ^TObject;
  PException = ^TException;
  PIdentifiable = ^TIdentifiable;
  PStatusObject = ^TStatusObject;

  TComparer = function(AItem1, AItem2: pointer): integer;
  TPredicate = function(AItem: pointer; var AValue): boolean;
  TCustomErrorMessageProc = function(AErrorCode: word; var AFound: boolean): string;
  TObjectStatus = integer;
  TExceptionCode = word;

  TExceptionSeverity =
  (
    esNone,
    esHint,
    esWarning,
    esError,
    esFatal
  );

  TObject = object
    constructor Create;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure AssignTo(var ADest: TObject); virtual;
    destructor Free; virtual;
  end;

  TIdentifiable = object(TObject)
  private
  public
    Id: PChar;
    constructor CreateId(AId: string);
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure SetId(const AId: string);
    function GetId: string;
    destructor Free; virtual;
  end;

  TException = object(TIdentifiable)
  private
  public
    Code: TExceptionCode;
    Severity: TExceptionSeverity;
    InnerException: PException;
    constructor Create(ACode: TExceptionCode);
    procedure Init; virtual;
    procedure Clear;
    procedure Assign(var ASource: TObject); virtual;
    function Message: string;
    destructor Free; virtual;
  end;

  TStatusObject = object(TIdentifiable)
  private
  public
    Exception: PException;
    Status: TObjectStatus;
    procedure Init; virtual;
    procedure Raise(ACode: TExceptionCode);
    procedure RaiseNullParameter(AParam: string);
    procedure RaiseInvalidOperation(AMessage: string);
    procedure RaiseWarning(ACode: TExceptionCode);
    procedure RaiseHint(ACode: TExceptionCode);
    procedure RaiseSeverity(ACode: TExceptionCode; ASeverity: TExceptionSeverity);
    procedure Reraise(AObject: PStatusObject);
    procedure ClearException;
    procedure Assign(var ASource: TObject); virtual;
    function HasException: boolean;
    function NoException: boolean;
    function GetBaseException: PException;
    function CheckReraise(AObject: PStatusObject): boolean;
    function NilPtr(APtr: pointer; ACode: TExceptionCode): boolean;
    function NilPtrSeverity(APtr: pointer; ACode: TExceptionCode;
      ASeverity: TExceptionSeverity): boolean;
    destructor Free; virtual;
  end;

procedure FreeAndNil(var AObject); far;

var
  OutOfMemoryException: PException;

implementation

procedure FreeAndNil(var AObject);
var
  obj: PObject;
  ptr: ^Pointer;
begin
  obj := PObject(AObject);
  if Assigned(obj) then
    Dispose(obj, Free);
  ptr := @AObject;
  ptr^ := nil;
end;

constructor TObject.Create;
begin
  init;
end;

procedure TObject.Init;
begin
end;

procedure TObject.Assign(var ASource: TObject);
begin
end;

procedure TObject.AssignTo(var ADest: TObject);
begin
  ADest.Assign(Self);
end;

destructor TObject.Free;
begin
end;

constructor TIdentifiable.CreateId(AId: string);
begin
  inherited Create;
  Id := TString.New(AId);
end;

procedure TIdentifiable.Init;
begin
  inherited Init;
  Id := nil;
end;

procedure TIdentifiable.Assign(var ASource: TObject);
begin
  inherited Assign(ASource);
end;

function TIdentifiable.GetId: string;
begin
  if not Assigned(Id) then
    GetId := ''
  else
    GetId := StrPas(Id);
end;

procedure TIdentifiable.SetId(const AId: string);
begin
  TString.AssignString(Id, AId);
end;

destructor TIdentifiable.Free;
begin
  inherited Free;
end;

constructor TException.Create(ACode: TExceptionCode);
begin
  inherited Create;
  Code := ACode;
end;

procedure TException.Init;
begin
  inherited Init;
  Code := 0;
  Severity := esNone;
  InnerException := nil;
end;

procedure TException.Clear;
begin
  FreeAndNil(InnerException);
  Code := ecNone;
  Severity := esError;
end;

destructor TException.Free;
begin
  Clear;
  inherited Free;
end;

procedure TException.Assign(var ASource: TObject);
var
  source: PException;
begin
  inherited Assign(ASource);
  source := PException(@ASource);
  Clear;
  if Assigned(source^.InnerException) then begin
    InnerException := New(PException, Create(ecNone));
    InnerException^.Assign(source^.InnerException^);
  end;
  Code := source^.Code;
  Severity := source^.Severity;
end;

function TException.Message: string;
begin
  ErrorMessage(Code);
end;

function TStatusObject.GetBaseException: PException;
var
  result: PException;
begin
  GetBaseException := Exception;
  if not Assigned(Exception) then
    exit;
  result := Exception;
  while Assigned(Exception^.InnerException) do
    result := result^.InnerException;
  GetBaseException := result;
end;

function TStatusObject.HasException: boolean;
begin
  HasException := Assigned(Exception);
end;

function TStatusObject.NoException: boolean;
begin
  NoException := not Assigned(Exception);
end;

procedure TStatusObject.Raise(ACode: TExceptionCode);
var
  newException: PException;
  prev: PException;
begin
  newException := New(PException, Create(ACode));
  if not Assigned(newException) then
    newException := OutOfMemoryException;
  if not Assigned(Exception) then begin
    Exception := newException;
    exit;
  end;
  prev := Exception;
  Exception := newException;
  Exception^.InnerException := prev;
  Status := sException;
end;

procedure TStatusObject.RaiseSeverity(ACode: TExceptionCode; ASeverity: TExceptionSeverity);
begin
  Raise(ACode);
  Exception^.Severity := ASeverity;
end;

function TStatusObject.CheckReraise(AObject: PStatusObject): boolean;
var
  result: boolean;
begin
  CheckReraise := false;
  if not Assigned(AObject) then
    exit;
  result := AObject^.HasException;
  if result then begin
    Reraise(AObject);
    AObject^.ClearException;
  end;
  CheckReraise := result;
end;

function TStatusObject.NilPtr(APtr: pointer; ACode: TExceptionCode): boolean;
var
  result: boolean;
begin
  result := not Assigned(APtr);
  if result then
    Raise(ACode);
  NilPtr := result;
end;

function TStatusObject.NilPtrSeverity(APtr: pointer; ACode: TExceptionCode;
  ASeverity: TExceptionSeverity): boolean;
var
  result: boolean;
begin
  result := not Assigned(APtr);
  if result then
    RaiseSeverity(ACode, ASeverity);
  NilPtrSeverity := result;
end;

procedure TStatusObject.Reraise(AObject: PStatusObject);
begin
  if not (Assigned(AObject) and AObject^.HasException) then
    exit;
  RaiseSeverity(AObject^.Exception^.Code, AObject^.Exception^.Severity);
  AObject^.ClearException;
end;

procedure TStatusObject.RaiseWarning(ACode: TExceptionCode);
begin
  RaiseSeverity(ACode, esWarning);
end;

procedure TStatusObject.RaiseHint(ACode: TExceptionCode);
begin
  RaiseSeverity(ACode, esHint);
end;

procedure TStatusObject.ClearException;
begin
  FreeAndNil(Exception);
  Status := sOk;
end;

destructor TStatusObject.Free;
begin
  ClearException;
  inherited Free;
end;

procedure TStatusObject.Assign(var ASource: TObject);
var
  source: PStatusObject;
begin
  inherited Assign(ASource);
  source := PStatusObject(@ASource);
  ClearException;
  Exception := New(PException, Create(ecNone));
  Exception^.Assign(source^.Exception^);
  Status := source^.Status;
end;

procedure TStatusObject.RaiseNullParameter(AParam: string);
begin
  Raise(ecNullParameter);
end;

procedure TStatusObject.RaiseInvalidOperation(AMessage: string);
begin
  Raise(ecInvalidOperation);
end;

procedure TStatusObject.Init;
begin
  inherited Init;
  Exception := nil;
  Status := sOk;
end;

var
  PreviousExitProc: PProc;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  FreeAndNil(OutOfMemoryException);
end;

begin
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
  OutOfMemoryException := New(PException, Create(ecNotEnoughMemory));
end.