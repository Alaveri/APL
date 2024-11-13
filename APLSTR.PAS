{$I COMPILER.INC}
unit AplStr;

interface

uses
  Strings,
  Dos;

type
  TStringCompareOption = (scIgnoreCase);
  TStringCompareOptions = set of TStringCompareOption;

  TStringUtil = object
  private
  public
    constructor Create;
    function Alloc(ALength: word): PChar;
    function New(ASource: string): PChar;
    function CompareLength(AStr1, AStr2: PChar; AMaxLength: word; ACompareOptions: TStringCompareOptions): integer;
    function Compare(AStr1, AStr2: PChar; ACompareOptions: TStringCompareOptions): integer;
    function CompareString(AStr1: string; AStr2: PChar; ACompareOptions: TStringCompareOptions): integer;
    function AppendString(AStr1: PChar; const AStr2: string): PChar;
    function Append(var AStr1: PChar; AStr2: PChar): PChar;
    function Copy(ASource: PChar): PChar;
    function CopyLength(ASource: PChar; AMaxLength: word): PChar;
    function EndString(AString: PChar): PChar;
    function EndCopy(ASource: PChar): PChar;
    function GetString(ASource: PChar): string;
    function Reassign(ADest, ASource: PChar): PChar;
    function IndexOf(ASource: PChar; AChar: char): integer;
    function Length(AString: PChar): word;
    procedure Free(var AString: PChar);
    procedure AssignString(var ADest: PChar; ASource: string);
  end;

var
  TString: TStringUtil;

implementation

constructor TStringUtil.Create;
begin
end;

function TStringUtil.Alloc(ALength: word): PChar;
var
  result: PChar;
begin
  GetMem(result, ALength + 1);
  if Assigned(result) then
    FillChar(result^, ALength + 1, 0);
  Alloc := result;
end;

function TStringUtil.New(ASource: string): PChar;
var
  dest: PChar;
begin
  New := nil;
  GetMem(dest, System.Length(ASource) + 1);
  if not Assigned(dest) then
    exit;
  StrPCopy(dest, ASource);
  New := dest;
end;

function TStringUtil.AppendString(AStr1: PChar; const AStr2: string): PChar;
var
  str: PChar;
  short: string;
begin
  AppendString := nil;
  if not Assigned(AStr1) or (System.Length(AStr2) = 0) then
    exit;
  GetMem(str, StrLen(AStr1) + System.Length(AStr2) + 1);
  if not Assigned(str) then
    exit;
  short := AStr2 + #0;
  str := StrCat(AStr1, @short[1]);
  AppendString := str;
end;

function TStringUtil.Append(var AStr1: PChar; AStr2: PChar): PChar;
var
  str: PChar;
  str1Len, str2Len: word;
  len: word;
begin
  str1Len := StrLen(AStr1);
  str2Len := StrLen(AStr2);
  len := str1Len + str2Len + 1;
  GetMem(str, len);
  if not Assigned(str) then
    exit;
  FillChar(str^, len, 0);
  if Assigned(AStr1) then
    str := StrCat(AStr1, AStr2);
  Append := str;
end;

procedure TStringUtil.Free(var AString: PChar);
begin
  if not Assigned(AString) then
    exit;
  FreeMem(AString, StrLen(AString) + 1);
  AString := nil;
end;

function TStringUtil.CopyLength(ASource: PChar; AMaxLength: word): PChar;
var
  dest: PChar;
begin
  dest := nil;
  CopyLength := nil;
  if not Assigned(ASource) then
    exit;
  GetMem(dest, AMaxLength + 1);
  if not Assigned(dest) then
    exit;
  StrLCopy(dest, ASource, AMaxLength);
  Inc(dest, AMaxLength);
  dest^ := #0;
  CopyLength := dest;
end;

function TStringUtil.EndString(AString: PChar): PChar;
begin
  EndString := StrEnd(AString);
end;

function TStringUtil.EndCopy(ASource: PChar): PChar;
begin
  EndCopy := EndString(Copy(ASource));
end;

function TStringUtil.Copy(ASource: PChar): PChar;
var
  dest: PChar;
begin
  dest := nil;
  Copy := nil;
  if not Assigned(ASource) then
    exit;
  GetMem(dest, StrLen(ASource) + 1);
  if not Assigned(dest) then
    exit;
  StrCopy(dest, ASource);
  Copy := dest;
end;

function TStringUtil.Reassign(ADest, ASource: PChar): PChar;
begin
  Free(ADest);
  Reassign := Copy(ASource);
end;

function TStringUtil.CompareLength(AStr1, AStr2: PChar; AMaxLength: word; ACompareOptions: TStringCompareOptions): integer;
begin
  if scIgnoreCase in ACompareOptions then
    CompareLength := StrLIComp(AStr1, AStr2, AMaxLength)
  else
    CompareLength := StrLComp(AStr1, AStr2, AMaxLength);
end;

function TStringUtil.Compare(AStr1, AStr2: PChar; ACompareOptions: TStringCompareOptions): integer;
begin
  if scIgnoreCase in ACompareOptions then
    Compare := StrIComp(AStr1, AStr2)
  else
    Compare := StrComp(AStr1, AStr2);
end;

function TStringUtil.CompareString(AStr1: string; AStr2: PChar;
  ACompareOptions: TStringCompareOptions): integer;
var
  str: PChar;
begin
  AStr1 := AStr1 + #0;
  str := @AStr1[1];
  CompareString := Compare(str, AStr2, ACompareOptions);
end;

procedure TStringUtil.AssignString(var ADest: PChar; ASource: string);
begin
  Free(ADest);
  ADest := New(ASource);
end;

function TStringUtil.GetString(ASource: PChar): string;
begin
  GetString := '';
  if Assigned(ASource) then
    GetString := StrPas(ASource);
end;

function TStringUtil.Length(AString: PChar): word;
begin
  Length := 0;
  if Assigned(AString) then
    Length := StrLen(AString);
end;

function TStringUtil.IndexOf(ASource: PChar; AChar: char): integer;
var
  index: integer;
begin
  IndexOf := -1;
  if not Assigned(ASource) then
    exit;
  for index := 0 to StrLen(ASource) - 1 do
    if ASource[index] = AChar then begin
      IndexOf := index;
      break;
    end;
end;

begin
  TString.Create;
end.