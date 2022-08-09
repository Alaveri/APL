{$I Compiler.Inc}
unit StrUtils;

interface

uses
  Strings;

function NewLargeString(st: string): PChar;
function CopyLargeString(st: PChar): PChar;
function PascalString(st: PChar): string;
procedure AppendLargeStrings(var st1: PChar; st2: PChar);
procedure AppendStringToLarge(var st1: PChar; st2: string);
procedure DisposeLargeString(st: PChar);

var
  EmptyString: PChar;

implementation

function PascalString(st: PChar): string;
begin
  PascalString := '';
  if (st = nil) then exit;
  PascalString := StrPas(st);
end;

procedure AppendStringToLarge(var st1: PChar; st2: string);
var
  result: PChar;
  st1Len, st2Len: word;
  ptr: PChar;
begin
  st1Len := StrLen(st1);
  GetMem(result, st1Len + Length(st2) + 1);
  ptr := result;
  Move(st1^, result^, st1Len);
  Inc(ptr, st1Len);
  Move(st2[1], ptr^, Length(st2));
  FreeMem(st1, st1Len + 1);
  st1 := result;
end;

procedure AppendLargeStrings(var st1: PChar; st2: PChar);
var
  result: PChar;
  st1Len, st2Len: word;
begin
  st1Len := StrLen(st1);
  st2Len := StrLen(st2);
  GetMem(result, st1Len + st2Len + 1);
  result := StrCat(st1, st2);
  FreeMem(st1, st1Len + 1);
  st1 := result;
end;

procedure DisposeLargeString(st: PChar);
begin
  if (st = nil) then exit;
  FreeMem(st, StrLen(st) + 1);
end;

function CopyLargeString(st: PChar): PChar;
var
  result: PChar;
  len: word;
begin
  if (st = nil) then exit;
  len := StrLen(st);
  GetMem(result, len + 1);
  StrCopy(result, st);
  CopyLargeString := result;
end;

function NewLargeString(st: string): PChar;
var
  result: PChar;
begin
  GetMem(result, Length(st) + 1);
  StrPCopy(result, st);
  NewLargeString := result;
end;

begin
  EmptyString := StrNew('');

end.