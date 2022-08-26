{$I COMPILER.INC}
unit KeyDrv;

interface

uses
  Objects,
  DateTime,
  Dos,
  Utils;

type
  TShiftStates =
  (
    ssNone,
    ssShift,
    ssControl,
    ssAlt
  );
  TShiftState = set of TShiftStates;
  TKeyboardBuffer = array[0..255] of word;
  PKeyboardDriver = ^TKeyboardDriver;
  TKeyboardDriver = object(TBaseObject)
    private
      _keyPressed: boolean;
    public
     destructor Done; virtual;
     procedure Init; virtual;
     function BufferLength: byte; virtual;
     function KeyPressed: boolean; virtual;
     function GetKey: word; virtual;
     function NumLock: boolean; virtual;
     function InsertMode: boolean; virtual;
     function ScrollLock: boolean; virtual;
     function CapsLock: boolean; virtual;
     function GetKeyDesc(key: integer): string; virtual;
     procedure GetBuffer(var buffer: TKeyboardBuffer); virtual;
     procedure ClearBuffer; virtual;
  end;

const
  kyEsc: word = 0;
  kyF1: word = 0;
  kyF2: word = 0;
  kyF3: word = 0;
  kyF4: word = 0;
  kyF5: word = 0;
  kyF6: word = 0;
  kyF7: word = 0;
  kyF8: word = 0;
  kyF9: word = 0;
  kyF10: word = 0;
  kyF11: word = 0;
  kyF12: word = 0;
  kyPrtSc: word = 0;
  kyScrollLock: word = 0;
  kyPause: word = 0;
  kyBackApos: word = 0;
  ky1: word = 0;
  ky2: word = 0;
  ky3: word = 0;
  ky4: word = 0;
  ky5: word = 0;
  ky6: word = 0;
  ky7: word = 0;
  ky8: word = 0;
  ky9: word = 0;
  ky0: word = 0;
  kyDash: word = 0;
  kyPlus: word = 0;
  kyBackSpace: word = 0;
  kyInsert: word = 0;
  kyHome: word = 0;
  kyPageUp: word = 0;
  kyNumLock: word = 0;
  kyPadSlash: word = 0;
  kyPadAsterisk: word = 0;
  kyPadMinus: word = 0;
  kyTab: word = 0;
  kyQ: word = 0;
  kyW: word = 0;
  kyE: word = 0;
  kyR: word = 0;
  kyT: word = 0;
  kyY: word = 0;
  kyU: word = 0;
  kyI: word = 0;
  kyO: word = 0;
  kyP: word = 0;
  kyOpenBracket: word = 0;
  kyCloseBracket: word = 0;
  kyBackSlash: word = 0;
  kyDel: word = 0;
  kyEnd: word = 0;
  kyPageDown: word = 0;
  kyPad7: word = 0;
  kyPad8: word = 0;
  kyPad9: word = 0;
  kyPadPlus: word = 0;
  kyCapsLock: word = 0;
  kyA: word = 0;
  kyS: word = 0;
  kyD: word = 0;
  kyF: word = 0;
  kyG: word = 0;
  kyH: word = 0;
  kyJ: word = 0;
  kyK: word = 0;
  kyL: word = 0;
  kySemiColon: word = 0;
  kyApost: word = 0;
  kyEnter: word = 0;
  kyPad4: word = 0;
  kyPad5: word = 0;
  kyPad6: word = 0;
  kyLeftShift: word = 0;
  kyZ: word = 0;
  kyX: word = 0;
  kyC: word = 0;
  kyV: word = 0;
  kyB: word = 0;
  kyN: word = 0;
  kyM: word = 0;
  kyComma: word = 0;
  kyPeriod: word = 0;
  kySlash: word = 0;
  kyRightShift: word = 0;
  kyUp: word = 0;
  kyPad1: word = 0;
  kyPad2: word = 0;
  kyPad3: word = 0;
  kyPadEnter: word = 0;
  kyLeftCtrl: word = 0;
  kyLeftAlt: word = 0;
  kySpace: word = 0;
  kyRightAlt: word = 0;
  kyRightCtrl: word = 0;
  kyLeft: word = 0;
  kyDown: word = 0;
  kyRight: word = 0;
  kyPad0: word = 0;
  kyPadPeriod: word = 0;

  kyShift: word = $100;
  kyCtrl: word = $200;
  kyAlt: word = $400;

  kAlpha: set of char = ['A'..'Z', 'a'..'z'];
  kNumeric: set of char = ['0'..'9'];
  kAlphaNumeric: set of char = ['A'..'Z', 'a'..'z', '0'..'9'];
  kPuncuation: set of char = ['!'..'/', ':'..'@', '['..'`', '{'..'~'];


implementation

uses
  DosConst;

var
  _savedInterruptVector: pointer;
  _keyBufHead: PByte;
  _keyBufTail: PByte;
  _shiftState: TShiftState;
  _capsLock: boolean;
  _numLock: boolean;
  _scrollLock: boolean;
  _insertMode: boolean;
  _memShiftState: PByte;
  _buffer: TKeyboardBuffer;
  _bufferLength: byte;


procedure AddToBuffer(key: word);
begin
  if (_bufferLength < High(_bufferLength)) then
  begin
    Inc(_bufferLength);
    _buffer[_bufferLength] := key;
  end;
end;

procedure KeyboardHandler(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: word); interrupt;
var
  data: byte;
  down: boolean;
begin
  asm
    pushf
    call _savedInterruptVector
  end;
  data := port[$60];
  down := false;
  down := data shr 7 = 0;
  if (not down) then
    data := data and $7F;
  if (down) then
  begin
{    case data of
      kcLeftShift, kcRightShift: Include(_shiftState, ssShift);
      kcControl: Include(_shiftState, ssControl);
      kcAlt: Include(_shiftState, ssAlt);
      kcCapsLock: _capsLock := true;
      kcNumLock: _numLock := true;
      kcKeypad0: if (_numLock) then _insertMode := not _insertMode;
    end;}
  end
  else
  begin
{    case data of
      kcLeftShift, kcRightShift: Exclude(_shiftState, ssShift);
      kcControl: Exclude(_shiftState, ssControl);
      kcAlt: Exclude(_shiftState, ssAlt);
      kcCapsLock: _capsLock := false;
      kcNumLock: _numLock := false;
    end;}
  end;

{  if (_bufferLength < Hi(_bufferLength))
     and not (data in kShiftKeys)
     and not ((not _numLock) and (data = kcKeypad0))
    then
  begin
    AddToBuffer((byte(_shiftState) shl 8) or data);
  end;}

  asm
    { send EOI to XT keyboard }
    in  al, 61h
    mov ah, al
    or  al, 80h
    out 61h, al
    mov al, ah
    out 61h, al

    { send EOI to master PIC }
    mov al, 20h
    out 20h, al
  end;

{  TextColor(Black);
  TextBackground(LightGray);
  GotoXY(26, 3);
  Write('Key: ', IntToHex(data), '    ');
  GotoXY(26, 4);
  Write('Num Lock: ', _numLock, '    ');
  GotoXY(26, 5);
  Write('Caps Lock: ', _capsLock, '    ');
  GotoXY(26, 6);
  Write('Insert: ', _insertMode, '    ');
  GotoXY(26, 9);
  Write('Shift: ', ssShift in _shiftState, '    ');
  GotoXY(26, 10);
  Write('Alt: ', ssAlt in _shiftState, '    ');
  GotoXY(26, 11);
  Write('Control: ', ssControl in _shiftState, '    ');
  GotoXY(26, 12);
  Write('Key Down: ', down, '    ');}

  { clear bios keyboard buffer }
  _keyBufHead^ := $20;
  _keyBufTail^ := $20;
end;

procedure TKeyboardDriver.Init;
begin
  inherited Init;
  FillChar(_buffer, SizeOf(_buffer), 0);
  _shiftState := [];
  _bufferLength := 0;
  _keyPressed := false;
  _capsLock := _memShiftState^ and $0040 <> 0;
  _numLock := _memShiftState^ and $0020 <> 0;
  _insertMode := true;
  GetIntVec($09, _savedInterruptVector);
  SetIntVec($09, @KeyboardHandler);
end;

destructor TKeyboardDriver.Done;
begin
  SetIntVec($09, _savedInterruptVector);
  TBaseObject.Done;
end;

function TKeyboardDriver.BufferLength: byte;
begin
end;

function TKeyboardDriver.KeyPressed: boolean;
begin
  KeyPressed := _keyPressed;
end;

function TKeyboardDriver.GetKey: word;
begin
  if (not _keyPressed) then exit;
end;

procedure TKeyboardDriver.GetBuffer(var buffer: TKeyboardBuffer);
begin
  FillChar(buffer, SizeOf(buffer), 0);
  Move(_buffer, buffer, _bufferLength);
end;

procedure TKeyboardDriver.ClearBuffer;
begin
  FillChar(_buffer, SizeOf(_buffer), 0);
  _bufferLength := 0;
end;

function TKeyboardDriver.GetKeyDesc(key: integer): string;
begin
  GetKeyDesc := '';
end;

function TKeyboardDriver.NumLock: boolean;
begin
  NumLock := _numLock;
end;

function TKeyboardDriver.InsertMode: boolean;
begin
  InsertMode := _insertMode;
end;

function TKeyboardDriver.CapsLock: boolean;
begin
  CapsLock := _capsLock;
end;

function TKeyboardDriver.ScrollLock: boolean;
begin
  ScrollLock := _scrollLock;
end;


begin
  _keyBufHead := Ptr($0040, $001A);
  _keyBufTail :=  Ptr($0040, $001C);
  _memShiftState := Ptr($0040, $0017);

end.