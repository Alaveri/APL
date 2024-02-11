{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit StrUtils;

interface

uses
  Strings;

type
  TStringCompareOption = (scIgnoreCase);
  TStringCompareOptions = set of TStringCompareOption;

  TStringUtil = object
  private
  public
    constructor Create;
    function New(ASource: string): PChar;
    function CompareLength(AStr1, AStr2: PChar; AMaxLength: word; ACompareOptions: TStringCompareOptions): integer;
    function Compare(AStr1, AStr2: PChar; ACompareOptions: TStringCompareOptions): integer;
    function CompareShort(AStr1: string; AStr2: PChar; ACompareOptions: TStringCompareOptions): integer;
    function AppendShort(AStr1: PChar; const AStr2: string): PChar;
    function Append(var AStr1: PChar; AStr2: PChar): PChar;
    function Copy(ASource: PChar): PChar;
    function CopyLength(ASource: PChar; AMaxLength: word): PChar;
    function EndString(AString: PChar): PChar;
    function EndCopy(ASource: PChar): PChar;
    procedure Dispose(var AString: PChar);
    procedure Assign(var ADest: PChar; ASource: string);
  end;

var
  TString: TStringUtil;

implementation

constructor TStringUtil.Create;
begin
end;

function TStringUtil.New(ASource: string): PChar;
var
  dest: PChar;
begin
  New := nil;
  GetMem(dest, Length(ASource) + 1);
  if not Assigned(dest) then
    exit;
  StrPCopy(dest, ASource);
  New := dest;
end;

function TStringUtil.AppendShort(AStr1: PChar; const AStr2: string): PChar;
var
  str: PChar;
  short: string;
begin
  AppendShort := nil;
  if not Assigned(AStr1) or (Length(AStr2) = 0) then
    exit;
  GetMem(str, StrLen(AStr1) + Length(AStr2) + 1);
  short := AStr2 + #0;
  str := StrCat(AStr1, @short[1]);
  AppendShort := str;
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
  FillChar(str^, len, 0);
  if Assigned(AStr1) then
    str := StrCat(AStr1, AStr2);
  Append := str;
end;

procedure TStringUtil.Dispose(var AString: PChar);
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

function TStringUtil.CompareShort(AStr1: string; AStr2: PChar;
  ACompareOptions: TStringCompareOptions): integer;
var
  str: PChar;
begin
  AStr1 := AStr1 + #0;
  str := @AStr1[1];
  CompareShort := Compare(str, AStr2, ACompareOptions);
end;

procedure TStringUtil.Assign(var ADest: PChar; ASource: string);
begin
  Dispose(ADest);
  ADest := New(ASource);
end;

begin
  TString.Create;
end.