{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit StrUtils;

interface

uses
  Strings;

function NewLargeString(ASource: string): PChar;
function CompareShortToLarge(AString: string; ALargeString: PChar): boolean;
function AppendShortToLarge(ALargeString: PChar; AString: string): PChar;
function CopyLargeString(ASource: PChar): PChar;
function AppendLargeStrings(var AStr1: PChar; AStr2: PChar): PChar;
procedure DisposeLargeString(var ALargeString: PChar);

implementation

function AppendShortToLarge(ALargeString: PChar; AString: string): PChar;
var
  len: word;
  ptr: PChar;
begin
  if (ALargeString = nil) or (Length(AString) = 0) then exit;
  len := StrLen(ALargeString);
  GetMem(ptr, len + Length(AString) + 1);
  Move(AString[1], ptr^, Length(AString));
  Inc(ptr, Length(AString));
  ptr^ := #0;
  AppendShortToLarge := ptr;
end;

function AppendLargeStrings(var AStr1: PChar; AStr2: PChar): PChar;
var
  ptr: PChar;
  str1Len, str2Len: word;
begin
  str1Len := StrLen(AStr1);
  str2Len := StrLen(AStr2);
  GetMem(ptr, str1Len + str2Len + 1);
  ptr := StrCat(AStr1, AStr2);
  AppendLargeStrings := ptr;
end;

procedure DisposeLargeString(var ALargeString: PChar);
var
  len: longint;
begin
  if ALargeString = nil then
    exit;
  len := StrLen(ALargeString) + 1;
  FreeMem(ALargeString, len);
  ALargeString := nil;
end;

function CopyLargeString(ASource: PChar): PChar;
var
  len: word;
  dest: PChar;
begin
  dest := nil;
  CopyLargeString := nil;
  if ASource = nil then
    exit;
  len := StrLen(ASource);
  GetMem(dest, len + 1);
  StrCopy(dest, ASource);
  CopyLargeString := dest;
end;

function NewLargeString(ASource: string): PChar;
var
  dest: PChar;
begin
  GetMem(dest, Length(ASource) + 1);
  StrPCopy(dest, ASource);
  NewLargeString := dest;
end;

function CompareShortToLarge(AString: string; ALargeString: PChar): boolean;
var
  index: word;
  ptr: PChar;
begin
  CompareShortToLarge := true;
  if (ALargeString = nil) then begin
    if (Length(AString) > 0) then
      CompareShortToLarge := false;
    exit;
  end;
  ptr := ALargeString;
  index := 0;
  while index <= High(word) do begin
    if (ptr^ = #0) then begin
      if (index < Length(AString) - 1) then
        CompareShortToLarge := false;
      exit;
    end;
    if (index > Length(AString) - 1) then begin
      CompareShortToLarge := false;
      exit;
    end;
    if (ptr^ <> AString[index + 1]) then begin
      CompareShortToLarge := false;
      exit;
    end;
    Inc(ptr);
    Inc(index);
  end;
end;

end.