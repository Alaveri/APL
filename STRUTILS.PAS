{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I-,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit StrUtils;

interface

uses
  Strings,
  Common;

function NewLargeString(source: string): PChar;
function LargeShortCompare(shortString: string; largeString: PChar): boolean;
function AppendShortToLarge(largeString: PChar; shortString: string): PChar;
function CopyLargeString(source: PChar): PChar;
procedure DisposeLargeString(var largeString: PChar);


implementation

function AppendShortToLarge(largeString: PChar; shortString: string): PChar;
var
  result: PChar;
  len: word;
  ptr: PChar;
begin
  if (largeString = nil) or (Length(shortString) = 0) then exit;
  len := StrLen(largeString);;
  GetMem(result, len + Length(shortString) + 1);
  Move(largeString^, result^, len);
  ptr := result;
  Inc(ptr, len);
  Move(shortString[1], ptr^, Length(shortString));
  Inc(ptr, Length(shortString));
  ptr^ := #0;
  AppendShortToLarge := result;
end;

procedure AppendLargeStrings(var str1: PChar; str2: PChar);
var
  result: PChar;
  str1Len, str2Len: word;
begin
  str1Len := StrLen(str1);
  str2Len := StrLen(str2);
  GetMem(result, str1Len + str2Len + 1);
  result := StrCat(str1, str2);
  FreeMem(str1, str1Len + 1);
  str1 := result;
end;

procedure DisposeLargeString(var largeString: PChar);
var
  len: longint;
begin
  if (largeString = nil) then exit;
  len := StrLen(largeString) + 1;
  FreeMem(largeString, len);
  largeString := nil;
end;

function CopyLargeString(source: PChar): PChar;
var
  len: word;
  dest: PChar;
begin
  dest := nil;
  if (source = nil) then exit;
  len := StrLen(source);
  GetMem(dest, len + 1);
  StrCopy(dest, source);
  CopyLargeString := dest;
end;

function NewLargeString(source: string): PChar;
var
  dest: PChar;
begin
  GetMem(dest, Length(source) + 1);
  StrPCopy(dest, source);
  NewLargeString := dest;
end;

function LargeShortCompare(shortString: string; largeString: PChar): boolean;
var
  index: word;
  ptr: PChar;
begin
  LargeShortCompare := true;
  if (largeString = nil) then begin
    if (Length(shortString) > 0) then
      LargeShortCompare := false;
    exit;
  end;
  ptr := largeString;
  index := 0;
  while (index < High(word)) do begin
    if (ptr^ = #0) then begin
      if (index < Length(shortString) - 1) then
        LargeShortCompare := false;
      exit;
    end;
    if (index > Length(shortString) - 1) then begin
      LargeShortCompare := false;
      exit;
    end;
    if (ptr^ <> shortString[index + 1]) then begin
      LargeShortCompare := false;
      exit;
    end;
    Inc(ptr);
    Inc(index);
  end;
end;


end.