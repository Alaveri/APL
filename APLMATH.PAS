{$I COMPILER.INC}
unit AplMath;

interface

uses
  AplConst;

type
  PWordArray = ^TWordArray;

  TWordArray = array[1..MaxVarSize div SizeOf(word)] of word;

function Min(ANum1, ANum2: integer): integer; far;
function MinB(ANum1, ANum2: byte): byte; far;
function MinS(ANum1, ANum2: shortint): shortint; far;
function MinW(ANum1, ANum2: word): word; far;
function MinL(ANum1, ANum2: longint): longint; far;
function Max(ANum1, ANum2: integer): integer; far;
function MaxB(ANum1, ANum2: byte): byte; far;
function MaxS(ANum1, ANum2: shortint): shortint; far;
function MaxW(ANum1, ANum2: word): word; far;
function MaxL(ANum1, ANum2: longint): longint; far;
function Clamp(AValue, AMin, AMax: integer): integer; far;
function ClampB(AValue, AMin, AMax: byte): byte; far;
function ClampW(AValue, AMin, AMax: word): word; far;
function ClampL(AValue, AMin, AMax: longint): longint; far;
function LowestW(AValues: PWordArray; ACount: word): word; far;
function HighestW(AValues: PWordArray; ACount: word): word; far;
function SumW(AValues: PWordArray; ACount: word): longint; far;

const
  RadianConvert: real = 57.295779513082320876798154814105;
  DegreeConvert: real = 0.017453292519943295769236907684886;

implementation

function Min(ANum1, ANum2: integer): integer; assembler;
asm
    mov ax, ANum1
    cmp ax, ANum2
    jle @end
    mov ax, ANum2
  @end:
end;

function MinW(ANum1, ANum2: word): word; assembler;
asm
    mov ax, ANum1
    cmp ax, ANum2
    jbe @end
    mov ax, ANum2
  @end:
end;

function MinS(ANum1, ANum2: shortint): shortint; assembler;
asm
    mov al, ANum1
    cmp al, ANum2
    jle @end
    mov al, ANum2
  @end:
end;

function MinB(ANum1, ANum2: byte): byte; assembler;
asm
    mov al, ANum1
    cmp al, ANum2
    jbe @end
    mov al, ANum2
  @end:
end;

function MinL(ANum1, ANum2: longint): longint;
begin
  MinL := ANum1;
  if ANum2 < ANum1 then
    MinL := ANum2;
end;

function Max(ANum1, ANum2: integer): integer; assembler;
asm
    mov ax, ANum1
    cmp ax, ANum2
    jge @end
    mov ax, ANum2
  @end:
end;

function MaxW(ANum1, ANum2: word): word; assembler;
asm
    mov ax, ANum1
    cmp ax, ANum2
    jae @end
    mov ax, ANum2
  @end:
end;

function MaxS(ANum1, ANum2: shortint): shortint; assembler;
asm
    mov al, ANum1
    cmp al, ANum2
    jge @end
    mov al, ANum2
  @end:
end;

function MaxB(ANum1, ANum2: byte): byte; assembler;
asm
    mov al, ANum1
    cmp al, ANum2
    jae @end
    mov al, ANum2
  @end:
end;

function MaxL(ANum1, ANum2: longint): longint;
begin
  MaxL := ANum1;
  if ANum2 > ANum1 then
    MaxL := ANum2;
end;

function MinReal(ANum1, ANum2: real): real;
begin
  MinReal := ANum1;
  if ANum2 < ANum1 then
    MinReal := ANum2;
end;

function MaxReal(ANum1, ANum2: real): real;
begin
  MaxReal := ANum1;
  if ANum2 > ANum1 then
    MaxReal := ANum2;
end;

function Clamp(AValue, AMin, AMax: integer): integer; assembler;
asm
    mov ax, AValue
    mov dx, AMin
    cmp ax, dx
    jge @max
    mov ax, dx
    jmp @end
  @max:
    mov dx, AMax
    cmp ax, dx
    jle @end
    mov ax, dx
  @end:
end;

function ClampB(AValue, AMin, AMax: byte): byte; assembler;
asm
    mov al, AValue
    mov dl, AMin
    cmp al, dl
    jae @max
    mov al, dl
    jmp @end
  @max:
    mov dl, AMax
    cmp al, dl
    jbe @end
    mov al, dl
  @end:
end;

function ClampW(AValue, AMin, AMax: word): word; assembler;
asm
    mov ax, AValue
    mov dx, AMin
    cmp ax, dx
    jae @max
    mov ax, dx
    jmp @end
  @max:
    mov dx, AMax
    cmp ax, dx
    jbe @end
    mov ax, dx
  @end:
end;

function ClampL(AValue, AMin, AMax: longint): longint;
begin
  ClampL := AValue;
  if AValue < AMin then
    ClampL := AMin
  else if AValue > AMax then
    ClampL := AMax;
end;

function LowestW(AValues: PWordArray; ACount: word): word; assembler;
asm
  les di, AValues
  mov cx, ACount
  xor ax, ax
  @loop:
    mov bx, es:[di]
    cmp ax, bx
    jl @skip
    mov ax, bx
  @skip:
    add di, 2
  loop @loop
end;

function HighestW(AValues: PWordArray; ACount: word): word; assembler;
asm
  les di, AValues
  mov cx, ACount
  xor ax, ax
  @loop:
    mov bx, es:[di]
    cmp ax, bx
    jg @skip
    mov ax, bx
  @skip:
    add di, 2
  loop @loop
end;

function SumW(AValues: PWordArray; ACount: word): longint; assembler;
asm
  les di, AValues
  mov cx, ACount
  xor ax, ax
  xor dx, dx
  @loop:
    mov bx, es:[di]
    add ax, bx
    adc dx, 0
    add di, 2
  loop @loop
end;

end.