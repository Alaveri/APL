unit WideStr;

{$mode ObjFPC}{$H+}

interface

uses
  Common,
{$ifdef fpc}
  Classes,
  SysUtils;
{$else}
{$endif}

type
  PWideString = ^TWideString;

  TWideString = object
  private
    fBuffer: PChar;
    fLength: word;
    fCapacity: word;
  public
    property Length: word read fLength;
    property Capacity: word read fCapacity;

    constructor Create;
    constructor CreateString(const aString: ShortString);
    constructor CreateWideString(const aString: TWideString);
    destructor Destroy; virtual;
    procedure Init; virtual;
    procedure SetString(const aString: ShortString); virtual;
    procedure SetWide(const aString: TWideString); virtual;
    procedure SetCapacity(const aCapacity: word); virtual;
    procedure Append(const aString: ShortString); virtual;
    procedure AppendWide(const aString: TWideString); virtual;
    procedure Insert(const aIndex: integer; const aString: ShortString); virtual;
    procedure InsertWide(const aIndex: integer; const aString: TWideString); virtual;
    procedure Delete(const aIndex, count: word); virtual;
    function ToString: ShortString; virtual;
    function Compare(const aString: ShortString): integer; virtual;
    function CompareWide(const aString: TWideString): integer; virtual;
    function GetChar(const aIndex: integer): char; virtual;
    function SubString(const aStartIndex, aLength: word): string; virtual;
    function SubWide(const aStartIndex, aLength: word): TWideString; virtual;
    function IndexOf(const aString: ShortString): word; virtual;
    function IndexOfWide(const aString: TWideString): word; virtual;
  end;

implementation

uses
  Objects;

constructor TWideString.Create;
begin
end;

constructor TWideString.CreateString(const aString: ShortString);
begin
end;

constructor TWideString.CreateWideString(const aString: TWideString);
begin
end;

destructor TWideString.Destroy;
begin
end;

procedure TWideString.Init;
begin
  fBuffer := nil;
  fCapacity := 0;
  fLength := 0;
end;

procedure TWideString.SetString(const aString: ShortString);
begin
end;

procedure TWideString.SetWide(const aString: TWideString);
begin
end;

procedure TWideString.SetCapacity(const aCapacity: word);
var
  newBuffer: pointer;
  max: word;
  dataSize: word;
  error: TErr;
begin
  if (fCapacity = aCapacity) then exit;
  dataSize := aCapacity + 1;
  GetMem(newBuffer, dataSize);
  if (newBuffer = nil) then
  begin
    if (OnAllocationError <> nil) then
      TAllocationError(OnAllocationError^)(error);
    exit;
  end;
  FillChar(newBuffer^, dataSize, 0);
  if (fCapacity > 0) and (fBuffer <> nil) then
  begin
    if (aCapacity > fCapacity) then
      Move(fBuffer^, newBuffer^, fCapacity)
    else
      Move(fBuffer^, NewBuffer^, aCapacity);
    FreeMem(fBuffer, fCapacity);
  end;
  fBuffer := newBuffer;
  fCapacity := aCapacity;
  if Length > fCapacity then
    fLength := fCapacity;
end;

procedure TWideString.Append(const aString: ShortString);
begin
end;

procedure TWideString.AppendWide(const aString: TWideString);
begin
end;

procedure TWideString.Insert(const aIndex: integer; const aString: ShortString);
begin
end;

procedure TWideString.InsertWide(const aIndex: integer; const aString: TWideString);
begin
end;

procedure TWideString.Delete(const aIndex, count: word);
begin
end;

function TWideString.ToString: ShortString;
begin
end;

function TWideString.Compare(const aString: ShortString): integer;
begin
end;

function TWideString.CompareWide(const aString: TWideString): integer;
begin
end;

function TWideString.GetChar(const aIndex: integer): char;
begin
end;

function TWideString.SubString(const aStartIndex, aLength: word): string;
begin
end;

function TWideString.SubWide(const aStartIndex, aLength: word): TWideString;
begin
end;

function TWideString.IndexOf(const aString: ShortString): word;
begin
end;

function TWideString.IndexOfWide(const aString: TWideString): word;
begin
end;

end.

