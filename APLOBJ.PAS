{$I COMPILER.INC}
unit AplObj;

interface

uses
  AplConst,
  StrUtils;

type
  PObject = ^TObject;
  PIdentifiable = ^TIdentifiable;
  PComparer = ^TComparer;

  TComparer = function(AItem1, AItem2: pointer): integer;
  TPredicate = function(AItem: pointer; var AValue): boolean;
  TProc = procedure;

  TObject = object
  private
  public
    constructor Create;
    constructor CreateAssign(var ASource: TObject);
    destructor Free; virtual;
    procedure Abstract; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
  end;

  TIdentifiable = object(TObject)
  private
  public
    Id: PChar;
    constructor CreateId(const AId: string);
    destructor Free; virtual;
    procedure SetId(const AId: string);
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
    function GetId: string;
  end;

procedure FreeAndNil(var AObject);

implementation

uses
  Common;

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
  Init;
end;

constructor TObject.CreateAssign(var ASource: TObject);
begin
  Create;
  Assign(ASource);
end;

procedure TObject.Init;
begin
end;

destructor TObject.Free;
begin
end;

procedure TObject.Abstract;
begin
  WriteLn('Abstract method not implemented.');
  RunError(301);
end;

procedure TObject.Assign(var ASource: TObject);
begin
end;

constructor TIdentifiable.CreateId(const AId: string);
begin
  inherited Create;
  SetId(AId);
end;

destructor TIdentifiable.Free;
begin
  TString.Free(Id);
  inherited Free;
end;

procedure TIdentifiable.SetId(const AId: string);
begin
  TString.Assign(Id, AId);
end;

procedure TIdentifiable.Assign(var ASource: TObject);
var
  source: PIdentifiable;
begin
  inherited Assign(ASource);
  source := PIdentifiable(@ASource);
  Id := TString.Reassign(Id, source^.Id);
end;

procedure TIdentifiable.Init;
begin
  inherited Init;
  Id := nil;
end;

function TIdentifiable.GetId: string;
begin
  GetId := TString.Get(Id);
end;

end.