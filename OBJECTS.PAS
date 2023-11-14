{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Objects;

interface

uses
  Consts,
  Strings,
  StrUtils;

type
  PWord = ^word;
  PPointer = ^pointer;
  PObject = ^TObject;
  PIdentifiable = ^TIdentifiable;

  TComparer = function(AItem1, AItem2: pointer): integer;
  TPredicate = function(AItem: pointer; var AValue): boolean;

  TObject = object
  private
  public
    constructor Create;
    destructor Free; virtual;
    function ToString: string; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
  end;

  TIdentifiable = object(TObject)
  private
  public
    Id: PChar;
    constructor CreateId(const AId: string);
    destructor Free; virtual;
    procedure SetId(const AId: string); virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
    function GetId: string; virtual;
  end;

procedure FreeAndNil(var AObject);

implementation

procedure FreeAndNil(var AObject);
var
  obj: PObject;
  ptr: PPointer;
begin
  obj := PObject(AObject);
  if obj <> nil then
    Dispose(obj, Free);
  ptr := @AObject;
  ptr^ := nil;
end;

constructor TObject.Create;
begin
  Init;
end;

procedure TObject.Init;
begin
end;

destructor TObject.Free;
begin
end;

function TObject.ToString: string;
begin
  ToString := '';
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
  DisposeLargeString(Id);
  inherited Free;
end;

procedure TIdentifiable.SetId(const AId: string);
begin
  DisposeLargeString(Id);
  Id := NewLargeString(AId);
end;

procedure TIdentifiable.Assign(var ASource: TObject);
var
  source: PIdentifiable;
begin
  inherited Assign(ASource);
  source := PIdentifiable(@ASource);
  DisposeLargeString(Id);
  Id := CopyLargeString(source^.Id);
end;

procedure TIdentifiable.Init;
begin
  inherited Init;
  Id := nil;
end;

function TIdentifiable.GetId: string;
begin
  GetId := '';
  if Id = nil then
    exit;
  GetId := StrPas(Id);
end;

end.