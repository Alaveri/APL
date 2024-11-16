{$I COMPILER.INC}
unit VarStr;

interface

uses
  AplObj,
  AplTypes,
  Strings,
  Lists;

const
  DefaultVarStringSize = 16;

type
  PVarStringSizeFunc = ^TVarStringSizeFunc;
  PVarString = ^TVarString;
  PVarStringList = ^TVarStringList;

  TVarStringSizeFunc = function(ACapacity: word): word;

  TVarString = object(TObject)
  private
    FString: PChar;
    FCapacity: word;
  public
    Length: word;
    constructor Create;
    constructor CreateCapacity(ACapacity: word);
    constructor CreateString(ASource: PChar);
    constructor CreateShort(const ASource: string);
    destructor Free; virtual;
    function GetCapacity: word;
    function GetString: PChar;
    function Copy(AIndex, ALength: word): PChar;
    procedure Init; virtual;
    procedure Resize(AMinCapacity: word);
    procedure SetCapacity(ACapacity: word);
    procedure SetString(ASource: PChar);
    procedure Clear;
    procedure AddChar(AChar: char);
    procedure AddString(ASource: PChar);
    procedure InsertChar(AIndex: word; AChar: char);
    procedure InsertString(AIndex: word; ASource: PChar);
    procedure DeleteChar(AIndex: word);
    procedure Delete(AIndex, ACount: word);
  end;

  TVarStringList = object(TList)
  private
  public
    DisposeStrings: boolean;
    procedure Init; virtual;
    function Add(AItem: PVarString): integer;
    function GetItem(AIndex: integer): PVarString;
    function IndexOf(AItem: PVarString): integer;
    procedure SetItem(AIndex: integer; AItem: PVarString);
    procedure Insert(AIndex: integer; AItem: PVarString);
    procedure Remove(AIndex: integer); virtual;
    procedure RemoveItem(AItem: PVarString);
    procedure Delete(AIndex: integer); virtual;
  end;

function DefaultVarStringSizeFunc(ACapacity: word): word; far;

var
  VarStringSizeFunc: TVarStringSizeFunc;

implementation

function DefaultVarStringSizeFunc(ACapacity: word): word;
var
  newCapacity: word;
begin
  newCapacity := 0;
  while newCapacity < ACapacity do begin
    if newCapacity >= 64 then
      newCapacity := (newCapacity * 3) div 2
    else if newCapacity >= 8 then
      newCapacity := newCapacity + 16
    else
      newCapacity := newCapacity + 4;
  end;
  DefaultVarStringSizeFunc := newCapacity;
end;

constructor TVarString.Create;
begin
  CreateCapacity(DefaultVarStringSize);
end;

constructor TVarString.CreateCapacity(ACapacity: word);
begin
  inherited Create;
  SetCapacity(ACapacity);
end;

constructor TVarString.CreateString(ASource: PChar);
var
  len: word;
begin
  len := StrLen(ASource);
  CreateCapacity(len);
  Move(ASource^, FString^, len);
end;

constructor TVarString.CreateShort(const ASource: string);
begin
  CreateCapacity(System.Length(ASource));
  Move(ASource[1], FString^, System.Length(ASource));
end;

procedure TVarString.Init;
begin
  inherited Init;
  FString := nil;
  FCapacity := 0;
end;

destructor TVarString.Free;
begin
  FreeMem(FString, FCapacity);
  inherited Free;
end;

function TVarString.GetCapacity: word;
begin
  GetCapacity := FCapacity;
end;

function TVarString.GetString: PChar;
begin
  GetString := FString;
end;

procedure TVarString.Resize(AMinCapacity: word);
var
  newCapacity: word;
begin
  newCapacity := VarStringSizeFunc(AMinCapacity);
  SetCapacity(newCapacity);
end;

procedure TVarString.SetCapacity(ACapacity: word);
var
  newString: PChar;
begin
  if FCapacity = ACapacity then
    exit;
  GetMem(newString, ACapacity);
  if not Assigned(newString) then
    exit;
  if not Assigned(FString) then begin
    GetMem(FString, ACapacity);
    FillChar(FString^, ACapacity, 0);
    if not Assigned(FString) then
      exit;
    FCapacity := ACapacity;
  end;
  if ACapacity < FCapacity then
    Move(FString^, newString^, ACapacity)
  else
    Move(FString^, newString^, FCapacity);
  FreeMem(FString, FCapacity);
  FString := newString;
  FCapacity := ACapacity;
  if Length > FCapacity then
    Length := FCapacity;
end;

procedure TVarString.SetString(ASource: PChar);
var
  len: word;
begin
  len := StrLen(ASource);
  Resize(len + 1);
  FillChar(FString^, FCapacity, 0);
  Move(ASource^, FString^, len);
  Length := len;
end;

procedure TVarString.Clear;
begin
  if not Assigned(FString) then
    exit;
  FreeMem(FString, FCapacity);
  FString := nil;
  FCapacity := 0;
  Length := 0;
end;

procedure TVarString.AddChar(AChar: char);
begin
  Resize(Length + 1);
  FString[Length] := AChar;
  Inc(Length);
end;

procedure TVarString.AddString(ASource: PChar);
var
  len: word;
begin
  len := StrLen(ASource);
  Resize(Length + len + 1);
  Move(ASource^, FString[Length], len);
  Inc(Length, len);
end;

procedure TVarString.InsertChar(AIndex: word; AChar: char);
begin
  if AIndex < 0 then
    AIndex := 0;
  if AIndex > Length then
    AIndex := Length;
  Resize(Length + 1);
  Move(FString[AIndex], FString[AIndex + 1], Length - AIndex);
  FString[AIndex] := AChar;
  Inc(Length);
end;

procedure TVarString.InsertString(AIndex: word; ASource: PChar);
var
  len: word;
begin
  len := StrLen(ASource);
  if AIndex < 0 then
    AIndex := 0;
  if AIndex > Length then
    AIndex := Length;
  Resize(Length + len + 1);
  Move(FString[AIndex], FString[AIndex + len], Length - AIndex);
  Move(ASource^, FString[AIndex], len);
  Inc(Length, len);
end;

procedure TVarString.DeleteChar(AIndex: word);
begin
  if AIndex < 0 then
    AIndex := 0;
  if AIndex >= Length then
    AIndex := Length - 1;
  Move(FString[AIndex + 1], FString[AIndex], Length - AIndex);
  FString[Length - 1] := #0;
  Dec(Length);
end;

procedure TVarString.Delete(AIndex, ACount: word);
begin
  if AIndex < 0 then
    AIndex := 0;
  if AIndex >= Length then
    AIndex := Length - 1;
  if ACount > Length - AIndex then
    ACount := Length - AIndex;
  Move(FString[AIndex + ACount], FString[AIndex], Length - AIndex - ACount);
  FString[Length - ACount] := #0;
  Dec(Length, ACount);
end;

function TVarString.Copy(AIndex, ALength: word): PChar;
var
  dest: PChar;
begin
  dest := nil;
  Copy := nil;
  if AIndex < 0 then
    AIndex := 0;
  if AIndex >= Length then
    AIndex := Length - 1;
  if ALength > Length - AIndex then
    ALength := Length - AIndex;
  GetMem(dest, ALength + 1);
  if not Assigned(dest) then
    exit;
  Move(FString[AIndex], dest^, ALength);
  dest[ALength] := #0;
  Copy := dest;
end;

procedure TVarStringList.Init;
begin
  inherited Init;
  DisposeStrings := true;
end;

function TVarStringList.Add(AItem: PVarString): integer;
begin
  Add := inherited Add(AItem);
end;

function TVarStringList.GetItem(AIndex: integer): PVarString;
begin
  GetItem := PVarString(inherited GetItem(AIndex));
end;

function TVarStringList.IndexOf(AItem: PVarString): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TVarStringList.SetItem(AIndex: integer; AItem: PVarString);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TVarStringList.Insert(AIndex: integer; AItem: PVarString);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TVarStringList.Remove(AIndex: integer);
begin
  inherited Delete(AIndex);
end;

procedure TVarStringList.RemoveItem(AItem: PVarString);
var
  index: integer;
begin
  index := IndexOf(AItem);
  if index >= 0 then
    Remove(index);
end;

procedure TVarStringList.Delete(AIndex: integer);
var
  item: PVarString;
begin
  item := GetItem(AIndex);
  if DisposeStrings and Assigned(item) then begin
    FreeAndNil(item);
  end;
  inherited Delete(AIndex);
end;

begin
  VarStringSizeFunc := DefaultVarStringSizeFunc;
end.