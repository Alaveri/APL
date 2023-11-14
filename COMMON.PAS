{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Common;

interface

uses
  Objects,
  Strings;

type
  PByte = ^byte;
  PPointer = ^pointer;
  PInteger = ^integer;
  PWord = ^word;
  PLongint = ^longint;

  Int64 = comp;
  TBit = (bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7);
  TBits = set of TBit;
  THexString = string[9];

  TLongLowHigh = record
    Low: word;
    High: word;
  end;

var
  NumberSeparator: char;

const
  HexDigits: String[16] = '0123456789ABCDEF';

function Trim(AString: string): string;
function IntToStr(ANum: longint): string;
function WordToStr(ANum: word): string;
function IntToHex(ANum: longint): THexString;
function IntToBool(ANum: longint): boolean;
function DoubleToStr(ADouble: double; ADigits: byte): string;
function BoolToStr(ABool: boolean): string;
function BoolToYN(ABool: boolean): string;
function BoolToYesNo(ABool: boolean): string;
function BoolToInt(ABool: boolean): byte;
function BoolToIntStr(ABool: boolean): string;
function MaxW(AWord1, AWord2: word): word;
function MinW(AWord1, AWord2: word): word;
function MaxL(ALong1, ALong2: longint): longint;
function MinL(ALong1, ALong2: longint): longint;
function FileExists(const AFilename: string): boolean;
function GetExtension(const AFilename: string): string;
function UpperCase(const AString: string): string;
function LowCase(const AChar: char): char;
function LowerCase(const AString: string): string;
function ExtractFilePath(const AFilename: string): string;
function Equal(var AVar1, AVar2; ASize: word): boolean;
function Replace(const AString, APattern, AReplacePattern: string): string;
function ZeroPad(AInt: longint; ALength: byte): string;
function EndZeroPad(AInt: longint; ALength: byte): string;
function FormatLong(ALong: longint): string;
procedure SwapL(var ALong1: longint; var ALong2: longint);
procedure SwapW(var AWord1: word; var AWord2: word);
procedure FillByteLarge(ABuffer: pointer; ASize: longint; AChar: byte);

var
  WhiteSpaceChars: set of char;

implementation

uses
  MemDrv,
  TPAlloc;

procedure FillByteLarge(ABuffer: pointer; ASize: longint; AChar: byte);
var
  current: PByte;
  pos: longint;
begin
  current := ABuffer;
  while ASize > 0 do begin
    if ASize <= MaxVarSize then begin
      FillChar(current^, ASize, AChar);
      exit;
    end;
    FillChar(current^, MaxVarSize, AChar);
    pos := Linear(current);
    Inc(pos, MaxVarSize);
    current := LinearToPointer(pos);
    Dec(ASize, MaxVarSize);
  end;
end;


function Trim(AString: string): string;
var
  result: string;
  index: integer;
begin
  result := '';
  index := 1;
  while (index <= Length(AString)) and (AString[index] in WhiteSpaceChars) do
    Inc(index);
  result := Copy(AString, index, Length(AString) - index + 1);
  index := Length(result);
  while (index >= 1) and (result[index] in WhiteSpaceChars) do
    Dec(index);
  result := Copy(result, 1, index);
  Trim := result;
end;

function Equal(var AVar1, AVar2; ASize: word): boolean;
var
  index: integer;
  byte1, byte2: PByte;
begin
  byte1 := @AVar1;
  byte2 := @AVar2;
  Equal := true;
  if (ASize <= 0) then exit;
  for index := 0 to ASize - 1 do begin
    if (byte1^ <> byte2^) then begin
      Equal := false;
      exit;
    end;
    Inc(byte1);
    Inc(byte2);
  end;
end;

procedure SwapL(var ALong1: longint; var ALong2: longint);
var
  temp: longint;
begin
  temp := ALong1;
  ALong1 := ALong2;
  ALong2 := temp;
end;

procedure SwapW(var AWord1: word; var AWord2: word);
var
  temp: word;
begin
  temp := AWord1;
  AWord1 := AWord2;
  AWord2 := temp;
end;

function FileExists(const AFilename: string): boolean;
var
  testFile: file;
begin
  {$I-}
  FileMode := 0;
  Assign(testFile, AFilename);
  Reset(testFile);
  if IOResult = 0 then begin
    FileExists := true;
    Close(testFile);
  end
  else
    FileExists := false;
  {$I+}
end;

function GetExtension(const AFilename: string): string;
var
  dotPos: integer;
  index: integer;
begin
  dotPos := -1;
  for index := length(AFilename) downto 1 do begin
    if AFilename[index] = '.' then begin
      dotPos := index;
      break;
    end;
  end;
  if (dotPos < 0) then
    GetExtension := ''
  else
    GetExtension := Copy(AFilename, dotPos, Length(AFilename) - dotPos + 1);
end;

function LowCase(const AChar: char): char;
begin
  if (ord(AChar) < 65) or (ord(AChar) > 90) then
    LowCase := AChar
  else
    LowCase := Chr(Ord(AChar) + 32);
end;

function LowerCase(const AString: string): string;
var
  index: integer;
begin
  LowerCase := AString;
  for index := 1 to Length(AString) do
    LowerCase[index] := LowCase(AString[index]);
end;

function UpperCase(const AString: string): string;
var
  index: integer;
begin
  UpperCase := AString;
  for index := 1 to Length(AString) do
    UpperCase[index] := UpCase(AString[index]);
end;

function MaxW(AWord1, AWord2: word): word;
begin
  MaxW := AWord1;
  if (AWord2 > AWord1) then MaxW := AWord2;
end;

function MinW(AWord1, AWord2: word): word;
begin
  MinW := AWord1;
  if (AWord2 < AWord1) then MinW := AWord2;
end;

function MaxL(ALong1, ALong2: longint): longint;
begin
  MaxL := ALong1;
  if (ALong2 > ALong1) then MaxL := ALong2;
end;

function MinL(ALong1, ALong2: longint): longint;
begin
  MinL := ALong1;
  if (ALong2 < ALong1) then MinL := ALong2;
end;

function IntToStr(ANum: longint): string;
var
  result: string;
begin
  Str(ANum, result);
  IntToStr := result;
end;

function WordToStr(ANum: word): string;
var
  result: string;
begin
  Str(ANum, result);
  WordToStr := result;
end;

function DoubleToStr(ADouble: double; ADigits: byte): string;
var
  result: string;
begin
  Str(ADouble:10:ADigits, result);
  DoubleToStr := Trim(result);
end;

function BoolToStr(ABool: boolean): string;
begin
  if ABool then
    BoolToStr := 'true'
  else
    BoolToStr := 'false';
end;

function BoolToYN(ABool: boolean): string;
begin
  if ABool then
    BoolToYN := 'Y'
  else
    BoolToYN := 'N';
end;

function BoolToYesNo(ABool: boolean): string;
begin
  if ABool then
    BoolToYesNo := 'Yes'
  else
    BoolToYesNo := 'No';
end;

function BoolToInt(ABool: boolean): byte;
begin
  if ABool then
    BoolToInt := 1
  else
    BoolToInt := 0;
end;

function BoolToIntStr(ABool: boolean): string;
begin
  if ABool then
    BoolToIntStr := '1'
  else
    BoolToIntStr := '0';
end;

function IntToBool(ANum: longint): boolean;
begin
  if ANum <> 0 then
    IntToBool := true
  else
    IntToBool := false;
end;

function IntToHex(ANum: longint): THexString;
var
  digit, numPos: byte;
  result: THexString;
  width: byte;
begin
  FillChar(result, SizeOf(result), ord('0'));
  result[1] := '$';
  if (ANum >= High(word)) then
    width := 8
  else if (ANum >= High(byte)) then
    width := 4
  else
    width := 2;
  result[0] := chr(width + 1);
  numPos := width + 1;
  while (ANum > 0) do begin
    result[numPos] := HexDigits[ANum mod 16 + 1];
    Dec(numPos);
    ANum := ANum div 16;
  end;
  IntToHex := result;
end;

function ExtractFilePath(const AFilename: string): string;
var
  index: integer;
  result: string;
begin
  ExtractFilePath := '';
  if Length(AFilename) = 0 then exit;
  result := '';
  for index := Length(AFilename) downto 1 do begin
    if AFilename[index] = '\' then
    begin
      result := Copy(AFilename, 1, index);
      break;
    end;
  end;
  ExtractFilePath := result;
end;

function Replace(const AString, APattern, AReplacePattern: string): string;
var
  index, patternIndex, currentIndex: integer;
  result: string;
  stringLength: integer;
  patternLength: integer;
  patternString: string;
  aChar: char;
begin
  index := 1;
  stringLength := Length(AString);
  patternLength := Length(APattern);
  result := '';
  while index <= stringLength do begin
    patternString := '';
    currentIndex := index;
    for patternIndex := 1 to patternLength do begin
      aChar := AString[currentIndex];
      if (index + patternIndex - 1 > stringLength)
        or (APattern[patternIndex] <> aChar) then
        break;
      patternString := patternString + aChar;
      Inc(CurrentIndex);
    end;
    if Length(patternString) = patternLength then begin
      result := result + AReplacePattern;
      Inc(index, patternLength);
      continue;
    end;
    result := result + AString[index];
    Inc(index);
  end;
  Replace := result;
end;

function ZeroPad(aInt: longint; aLength: byte): string;
var
  result: string;
begin
  result := IntToStr(aInt);
  while Length(result) < aLength do
    result := '0' + result;
  ZeroPad := result;
end;

function EndZeroPad(aInt: longint; aLength: byte): string;
var
  result: string;
begin
  result := IntToStr(aInt);
  while Length(result) < aLength do
    result := result + '0';
  EndZeroPad := result;
end;

function FormatLong(ALong: longint): string;
var
  result: string;
begin
  result := '';
  while true do begin
    if aLong div 1000 = 0 then begin
      result := IntToStr(aLong mod 1000) + result;
      break;
    end;
    result := numberSeparator + ZeroPad(aLong mod 1000, 3) + result;
    aLong := aLong div 1000;
  end;
  FormatLong := result;
end;

begin
 WhiteSpaceChars := [#32, #13, #10, #9];
 NumberSeparator := ',';
end.