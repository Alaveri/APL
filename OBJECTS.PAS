{$ifndef fpc}
{$ifdef debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$else}
  {$A-,B-,D-,E+,F+,G+,I-,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$endif}
{$endif}
unit Objects;

interface

uses
  Consts,
  Strings,
  WideStr,
  Common;

type
  {$ifndef fpc}
  ShortString = string;
  {$endif}
  PWord = ^word;
  PBaseObject = ^TBaseObject;
  PNamedObject = ^TNamedObject;
  PPointer = ^pointer;
  PAllocationError = ^TAllocationError;

  TComparer = function(item1, item2: pointer): integer;
  TAllocationError = procedure(var error: TErr);

  TBaseObject = object
  private
  public
    constructor Create;
    procedure Init; virtual;
    function ToString: ShortString; virtual;
    function GetTypeName: ShortString; virtual;
    destructor Destroy; virtual;
  end;

  TNamedObject = object(TBaseObject)
  private
    fName: PWideString;
  public
    constructor CreateName(const aName: ShortString);
    destructor Destroy; virtual;
    procedure SetName(const aName: ShortString);
    procedure Init; virtual;
    function GetTypeName: ShortString; virtual;
    function GetName: ShortString; virtual;
    property Name: ShortString read GetName write SetName;
  end;


  PAssignable = ^TAssignable;
  TAssignable = object(TNamedObject)
  public
    constructor CreateAssign(var source: TAssignable);
    procedure Init; virtual;
    procedure Assign(var source: TAssignable); virtual;
    procedure AssignTo(var dest: TAssignable); virtual;
    function GetTypeName: ShortString; virtual;
  end;

var
  OnAllocationError: PAllocationError;

implementation

constructor TBaseObject.Create;
begin
  Init;
end;

procedure TBaseObject.Init;
begin
end;

destructor TBaseObject.Destroy;
begin
end;

function TBaseObject.ToString: ShortString;
begin
  ToString := GetTypeName;
end;

function TBaseObject.GetTypeName: ShortString;
begin
  GetTypeName := 'TBaseObject';
end;

constructor TNamedObject.CreateName(const aName: ShortString);
begin
  Init;
  fName := New(PWideString, CreateString(aName));
end;

function TNamedObject.GetTypeName: ShortString;
begin
  GetTypeName := 'TNamedObject';
end;

procedure TNamedObject.Init;
begin
  inherited Init;
  fName := nil;
end;

procedure TNamedObject.SetName(const aName: ShortString);
begin
  if (fName <> nil) then
    Dispose(fName, Destroy);
  fName := New(PWideString, CreateString(aName));
end;

function TNamedObject.GetName: ShortString;
begin
  if (fName <> nil) then begin
    GetName := '';
    exit;
  end;
  GetName := fName^.ToString;
end;

destructor TNamedObject.Destroy;
begin
  if (fName <> nil) then
    Dispose(fName, Destroy);
end;

constructor TAssignable.CreateAssign(var source: TAssignable);
begin
  Init;
  Assign(source);
end;

procedure TAssignable.Init;
begin
  TNamedObject.Init;
end;

function TAssignable.GetTypeName: ShortString;
begin
  GetTypeName := 'TAssignable';
end;

procedure TAssignable.Assign(var source: TAssignable);
begin
end;

procedure TAssignable.AssignTo(var dest: TAssignable);
begin
end;

begin
  OnAllocationError := nil;

end .
