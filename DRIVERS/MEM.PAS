{$I COMPILER.INC}
unit Mem;

interface

uses
  AplConst,
  AplObj,
  AplStr,
  AplTypes,
  Lists,
  Strings;

type
  PMemoryDriver = ^TMemoryDriver;
  PMemoryReference = ^TMemoryReference;
  PMemoryObject = ^TMemoryObject;

  THandle = longint;

  TMemoryObject = object(TObject)
  private
    FHandle: THandle;
  public
    destructor Free; virtual;
    procedure Init; virtual;
    function Handle: THandle;
    procedure SetHandle(AHandle: THandle);
  end;

  TMemoryReferenceFlag = (
    mrConventional,
    mrXms,
    mrEms,
    mrObject,
    mrVariable
  );

  TMemoryReferenceFlags = set of TMemoryReferenceFlag;

  TMemoryReference = record
    Handle: THandle;
    Flags: TMemoryReferenceFlags;
    case boolean of
      true: (Obj: PObject);
      false: (Ptr: pointer);
  end;

  TMemoryDriver = object(TStatusObject)
  private
    FCurrentHandle: THandle;
  public
    function AllocObject(AObject: PMemoryObject): THandle;
    function AllocMem(ASize: longint): THandle;
    function GetObj(AHandle: THandle): PObject;
    function GetVar(AHandle: THandle): pointer;
    procedure FreeObject(AObject: PMemoryObject);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

procedure TMemoryDriver.Init;
begin
  inherited Init;
  FCurrentHandle := 1;
end;

function TMemoryDriver.AllocObj(AObject: PMemoryObject): THandle;
var
  reference: PMemoryReference;
begin
  New(reference);
  reference^.Handle := FCurrentHandle;
  reference^.Obj := AObject;
  reference^.Flags := [mrConventional, mrObject];
  AObject^.SetHandle(FCurrentHandle);
  AllocObject := FCurrentHandle;
  Inc(FCurrentHandle);
end;

function TMemoryDriver.AllocMem(ASize: longint): THandle;
var
  reference: PMemoryReference;
begin
  New(reference);
  GetMem(reference^.Ptr, ASize);
  reference^.Handle := FCurrentHandle;
  reference^.Flags := [mrConventional, mrVariable];
  Inc(FCurrentHandle);
  AllocMem := FCurrentHandle;
end;

function TMemoryDriver.GetObj(AHandle: THandle): PObject;
begin
end;

function TMemoryDriver.GetVar(AHandle: THandle): pointer;
begin
end;

destructor TMemoryDriver.Free;
begin
  inherited Free;
end;

destructor TMemoryObject.Free;
begin
  inherited Free;
end;

procedure TMemoryObject.Init;
begin
  inherited Init;
  FHandle := 0;
end;

function TMemoryObject.Handle: THandle;
begin
  Handle := FHandle;
end;

procedure TMemoryObject.SetHandle(AHandle: THandle);
begin
  FHandle := AHandle;
end;

var
  PreviousExitProc: PProc;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
end;

begin
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
