{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I-,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit KeyDrv;

interface

uses
  Objects,
  DateTime,
  Dos,
  Consts,
  Common;

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
  kyEsc: word = 27;
  kyF1: word = 128;
  kyF2: word = 129;
  kyF3: word = 130;
  kyF4: word = 131;
  kyF5: word = 132;
  kyF6: word = 133;
  kyF7: word = 134;
  kyF8: word = 135;
  kyF9: word = 136;
  kyF10: word = 136;
  kyF11: word = 138;
  kyF12: word = 139;
  kyPrtSc: word = 140;
  kyScrollLock: word = 141;
  kyPause: word = 142;
  kyBackApos: word = 96;
  ky1: word = 49;
  ky2: word = 50;
  ky3: word = 51;
  ky4: word = 52;
  ky5: word = 53;
  ky6: word = 54;
  ky7: word = 55;
  ky8: word = 56;
  ky9: word = 57;
  ky0: word = 58;
  kyDash: word = 45;
  kyPlus: word = 61;
  kyBackSpace: word = 8;
  kyInsert: word = 143;
  kyHome: word = 144;
  kyPageUp: word = 145;
  kyNumLock: word = 146;
  kyPadSlash: word = 147;
  kyPadAsterisk: word = 148;
  kyPadMinus: word = 149;
  kyTab: word = 9;
  kyQ: word = 81;
  kyW: word = 87;
  kyE: word = 69;
  kyR: word = 82;
  kyT: word = 84;
  kyY: word = 89;
  kyU: word = 85;
  kyI: word = 73;
  kyO: word = 79;
  kyP: word = 80;
  kyOpenBracket: word = 91;
  kyCloseBracket: word = 93;
  kyBackSlash: word = 92;
  kyDel: word = 127;
  kyEnd: word = 150;
  kyPageDown: word = 151;
  kyPad7: word = 152;
  kyPad8: word = 153;
  kyPad9: word = 154;
  kyPadPlus: word = 155;
  kyCapsLock: word = 156;
  kyA: word = 65;
  kyS: word = 83;
  kyD: word = 68;
  kyF: word = 70;
  kyG: word = 71;
  kyH: word = 72;
  kyJ: word = 74;
  kyK: word = 75;
  kyL: word = 76;
  kySemiColon: word = 59;
  kyApost: word = 39;
  kyEnter: word = 13;
  kyPad4: word = 157;
  kyPad5: word = 158;
  kyPad6: word = 159;
  kyLeftShift: word = 160;
  kyZ: word = 90;
  kyX: word = 88;
  kyC: word = 67;
  kyV: word = 86;
  kyB: word = 66;
  kyN: word = 78;
  kyM: word = 77;
  kyComma: word = 44;
  kyPeriod: word = 46;
  kySlash: word = 47;
  kyRightShift: word = 161;
  kyUp: word = 162;
  kyPad1: word = 163;
  kyPad2: word = 164;
  kyPad3: word = 165;
  kyPadEnter: word = 166;
  kyLeftCtrl: word = 167;
  kyLeftAlt: word = 168;
  kySpace: word = 32;
  kyRightAlt: word = 169;
  kyRightCtrl: word = 170;
  kyLeft: word = 171;
  kyDown: word = 172;
  kyRight: word = 173;
  kyPad0: word = 174;
  kyPadPeriod: word = 175;

  kyShift: word = $100;
  kyCtrl: word = $200;
  kyAlt: word = $400;

  kAlpha: set of char = ['A'..'Z', 'a'..'z'];
  kNumeric: set of char = ['0'..'9'];
  kAlphaNumeric: set of char = ['A'..'Z', 'a'..'z', '0'..'9'];
  kPuncuation: set of char = ['!'..'/', ':'..'@', '['..'`', '{'..'~'];

function KeyToAscii(key: word): byte;
function KeyToChar(key: word): char;
function KeyToString(key: word): string;
function KeyToShortcut(key: word): string;

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


function KeyToAscii(key: word): byte;
var
  shift: boolean;
  ch: byte;
begin
  shift := key and kyShift > 0;
  case Lo(Key) of
    0..127: begin
      ch := Lo(key);
      if (shift) then begin
        case key of
          44, 46..47: Inc(ch, 16);
          45: ch := 95;
          49: ch := 33;
          50: ch := 64;
          51..53, 57: Dec(ch, 16);
          54: ch := 94;
          55: ch := 38;
          56: ch := 42;
          59: ch := 58;
          61: ch := 43;
          91..93: Inc(ch, 32);
          97..133: Dec(ch, 32);
          96: ch := 126;
        end;
      end;
    end;
  end;
  KeyToAscii := ch;
end;

function KeyToChar(key: word): char;
begin
  KeyToChar := Chr(KeyToAscii(key));
end;

function KeyToString(key: word): string;
var
  result: string;
const
  Desc: array[140..175] of string5 =
  (
    'PrtSc',
    'ScrLk',
    'Pause',
    'Ins',
    'Home',
    'PgUp',
    'NumLk',
    '/',
    '*',
    '-',
    'End',
    'PgDn',
    '7',
    '8',
    '9',
    '+',
    'Caps',
    '4',
    '5',
    '6',
    '',
    '',
    'Up',
    '1',
    '2',
    '3',
    'Enter',
    '',
    '',
    '',
    '',
    'Left',
    'Down',
    'Right',
    '0',
    '.'
  );
var
  ch: byte;
begin
  ch := Lo(key);
  result := '';
  case ch of
    8: result := 'BkSp';
    9: result := 'Tab';
    13: result := 'Enter';
    27: result := 'Esc';
    32: result := 'Space';
    127: result := 'Del';
    140..175: result := Desc[ch];
    39, 44..47, 59, 65..93, 96: result := Chr(KeyToAscii(key));
    128..139: result := 'F' + IntToStr(ch - 127);
  end;
  KeyToString := result;
end;

function KeyToShortcut(key: word): string;
var
  result: string;
  ch: byte;
begin
  result := KeyToString(key);

  if (key and kyShift) > 0 then
    result := 'Shift+' + result;
  if (key and kyAlt) > 0 then
    result := 'Alt+' + result;
  if (key and kyCtrl) > 0 then
    result := 'Ctrl+' + result;

  KeyToShortcut := result;
end;

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