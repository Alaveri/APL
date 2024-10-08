{$I COMPILER.INC}
unit KeyDrv;

interface

uses
  {$IFDEF DOS}
  Dos,
  {$ENDIF}
  AplObj,
  AplTypes,
  Common,
  DateTime;

const
  ExtKeyFlag = word($100);
  ExtShiftFlag = word($200);

  kyAltQ = ExtKeyFlag + 16;
  kyAltW = ExtKeyFlag + 17;
  kyAltE = ExtKeyFlag + 18;
  kyAltR = ExtKeyFlag + 19;
  kyAltT = ExtKeyFlag + 20;
  kyAltY = ExtKeyFlag + 21;
  kyAltU = ExtKeyFlag + 22;
  kyAltI = ExtKeyFlag + 23;
  kyAltO = ExtKeyFlag + 24;
  kyAltP = ExtKeyFlag + 25;
  kyAltA = ExtKeyFlag + 30;
  kyAltS = ExtKeyFlag + 31;
  kyAltD = ExtKeyFlag + 32;
  kyAltF = ExtKeyFlag + 33;
  kyAltG = ExtKeyFlag + 34;
  kyAltH = ExtKeyFlag + 35;
  kyAltJ = ExtKeyFlag + 36;
  kyAltK = ExtKeyFlag + 37;
  kyAltL = ExtKeyFlag + 38;
  kyAltZ = ExtKeyFlag + 44;
  kyAltX = ExtKeyFlag + 45;
  kyAltC = ExtKeyFlag + 46;
  kyAltV = ExtKeyFlag + 47;
  kyAltB = ExtKeyFlag + 48;
  kyAltN = ExtKeyFlag + 49;
  kyAltM = ExtKeyFlag + 50;

  kyQ = 16;
  kyW = 17;
  kyE = 18;
  kyR = 19;
  kyT = 20;
  kyY = 21;
  kyU = 22;
  kyI = 23;
  kyO = 24;
  kyP = 25;
  kyA = 30;
  kyS = 31;
  kyD = 32;
  kyF = 33;
  kyG = 34;
  kyH = 35;
  kyJ = 36;
  kyK = 37;
  kyL = 38;
  kyZ = 44;
  kyX = 45;
  kyC = 46;
  kyV = 47;
  kyB = 48;
  kyN = 49;
  kyM = 50;

  kyShiftAltQ = ExtShiftFlag + kyAltQ;
  kyShiftAltW = ExtShiftFlag + kyAltW;
  kyShiftAltE = ExtShiftFlag + kyAltE;
  kyShiftAltR = ExtShiftFlag + kyAltR;
  kyShiftAltT = ExtShiftFlag + kyAltT;
  kyShiftAltY = ExtShiftFlag + kyAltY;
  kyShiftAltU = ExtShiftFlag + kyAltU;
  kyShiftAltI = ExtShiftFlag + kyAltI;
  kyShiftAltO = ExtShiftFlag + kyAltO;
  kyShiftAltP = ExtShiftFlag + kyAltP;
  kyShiftAltA = ExtShiftFlag + kyAltA;
  kyShiftAltS = ExtShiftFlag + kyAltS;
  kyShiftAltD = ExtShiftFlag + kyAltD;
  kyShiftAltF = ExtShiftFlag + kyAltF;
  kyShiftAltG = ExtShiftFlag + kyAltG;
  kyShiftAltH = ExtShiftFlag + kyAltH;
  kyShiftAltJ = ExtShiftFlag + kyAltJ;
  kyShiftAltK = ExtShiftFlag + kyAltK;
  kyShiftAltL = ExtShiftFlag + kyAltL;
  kyShiftAltZ = ExtShiftFlag + kyAltZ;
  kyShiftAltX = ExtShiftFlag + kyAltX;
  kyShiftAltC = ExtShiftFlag + kyAltC;
  kyShiftAltV = ExtShiftFlag + kyAltV;
  kyShiftAltB = ExtShiftFlag + kyAltB;
  kyShiftAltN = ExtShiftFlag + kyAltN;
  kyShiftAltM = ExtShiftFlag + kyAltM;

  kyF1 = ExtKeyFlag + 59;
  kyF2 = ExtKeyFlag + 60;
  kyF3 = ExtKeyFlag + 61;
  kyF4 = ExtKeyFlag + 62;
  kyF5 = ExtKeyFlag + 63;
  kyF6 = ExtKeyFlag + 64;
  kyF7 = ExtKeyFlag + 65;
  kyF8 = ExtKeyFlag + 66;
  kyF9 = ExtKeyFlag + 67;
  kyF10 = ExtKeyFlag + 68;
  kyAltF1 = ExtKeyFlag + 104;
  kyAltF2 = ExtKeyFlag + 105;
  kyAltF3 = ExtKeyFlag + 106;
  kyAltF4 = ExtKeyFlag + 107;
  kyAltF5 = ExtKeyFlag + 108;
  kyAltF6 = ExtKeyFlag + 109;
  kyAltF7 = ExtKeyFlag + 110;
  kyAltF8 = ExtKeyFlag + 111;
  kyAltF9 = ExtKeyFlag + 112;
  kyAltF10 = ExtKeyFlag + 113;
  kyShiftF1 = ExtKeyFlag + 84;
  kyShiftF2 = ExtKeyFlag + 85;
  kyShiftF3 = ExtKeyFlag + 86;
  kyShiftF4 = ExtKeyFlag + 87;
  kyShiftF5 = ExtKeyFlag + 88;
  kyShiftF6 = ExtKeyFlag + 89;
  kyShiftF7 = ExtKeyFlag + 90;
  kyShiftF8 = ExtKeyFlag + 91;
  kyShiftF9 = ExtKeyFlag + 92;
  kyShiftF10 = ExtKeyFlag + 93;

  kyCtrlF1 = ExtKeyFlag + 94;
  kyCtrlF2 = ExtKeyFlag + 95;
  kyCtrlF3 = ExtKeyFlag + 96;
  kyCtrlF4 = ExtKeyFlag + 97;
  kyCtrlF5 = ExtKeyFlag + 98;
  kyCtrlF6 = ExtKeyFlag + 99;
  kyCtrlF7 = ExtKeyFlag + 100;
  kyCtrlF8 = ExtKeyFlag + 101;
  kyCtrlF9 = ExtKeyFlag + 102;
  kyCtrlF10 = ExtKeyFlag + 103;

  kyAlt1 = ExtKeyFlag + 120;
  kyAlt2 = ExtKeyFlag + 121;
  kyAlt3 = ExtKeyFlag + 122;
  kyAlt4 = ExtKeyFlag + 123;
  kyAlt5 = ExtKeyFlag + 124;
  kyAlt6 = ExtKeyFlag + 125;
  kyAlt7 = ExtKeyFlag + 126;
  kyAlt8 = ExtKeyFlag + 427;
  kyAlt9 = ExtKeyFlag + 128;
  kyAlt0 = ExtKeyFlag + 129;

  kyShiftAlt1 = ExtShiftFlag + kyAlt1;
  kyShiftAlt2 = ExtShiftFlag + kyAlt2;
  kyShiftAlt3 = ExtShiftFlag + kyAlt3;
  kyShiftAlt4 = ExtShiftFlag + kyAlt4;
  kyShiftAlt5 = ExtShiftFlag + kyAlt5;
  kyShiftAlt6 = ExtShiftFlag + kyAlt6;
  kyShiftAlt7 = ExtShiftFlag + kyAlt7;
  kyShiftAlt8 = ExtShiftFlag + kyAlt8;
  kyShiftAlt9 = ExtShiftFlag + kyAlt9;
  kyShiftAlt0 = ExtShiftFlag + kyAlt0;

  kyAltDash = ExtKeyFlag + 130;
  kyAltEqual = ExtKeyFlag + 131;
  kyInsert = ExtKeyFlag + 82;

  kyDel = ExtKeyFlag + 83;
  kyLeft = ExtKeyFlag + 75;
  kyRight = ExtKeyFlag + 77;
  kyUp = ExtKeyFlag + 72;
  kyDown = ExtKeyFlag + 80;
  kyPageUp = ExtKeyFlag + 73;
  kyPageDown = ExtKeyFlag + 81;
  kyHome = ExtKeyFlag + 71;
  kyEnd = ExtKeyFlag + 79;

  kyCtrlLeft = ExtKeyFlag + 115;
  kyCtrlRight = ExtKeyFlag + 116;
  kyCtrlPageUp = ExtKeyFlag + 132;
  kyCtrlPageDown = ExtKeyFlag + 118;
  kyCtrlHome = ExtKeyFlag + 119;
  kyCtrlEnd = ExtKeyFlag + 117;

  kyShiftDel = ExtShiftFlag + kyDel;
  kyShiftLeft = ExtShiftFlag + kyLeft;
  kyShiftRight = ExtShiftFlag + kyRight;

  kyShiftUp = ExtShiftFlag + kyUp;
  kyShiftDown = ExtShiftFlag + kyDown;
  kyShiftPageUp = ExtShiftFlag + kyPageUp;
  kyShiftPageDown = ExtShiftFlag + kyPageDown;
  kyShiftHome = ExtShiftFlag + kyHome;
  kyShiftEnd = ExtShiftFlag + kyEnd;
  kyShiftIns = ExtShiftFlag + kyInsert;

  kyShiftCtrlLeft = ExtShiftFlag + kyCtrlLeft;
  kyShiftCtrlRight = ExtShiftFlag + kyCtrlRight;
  kyShiftCtrlPageUp = ExtShiftFlag + kyCtrlPageUp;
  kyShiftCtrlPageDown = ExtShiftFlag + kyCtrlPageDown;
  kyShiftCtrlHome = ExtShiftFlag + kyCtrlHome;
  kyShiftCtrlEnd = ExtShiftFlag + kyCtrlEnd;

  kyCtrlA = 1;
  kyCtrlB = 2;
  kyCtrlC = 3;
  kyCtrlD = 4;
  kyCtrlE = 5;
  kyCtrlF = 6;
  kyCtrlG = 7;
  kyCtrlH = 8;
  kyCtrlI = 9;
  kyCtrlJ = 10;
  kyCtrlK = 11;
  kyCtrlL = 12;
  kyCtrlM = 13;
  kyCtrlN = 14;
  kyCtrlO = 15;
  kyCtrlP = 16;
  kyCtrlQ = 17;
  kyCtrlR = 18;
  kyCtrlS = 19;
  kyCtrlT = 20;
  kyCtrlU = 21;
  kyCtrlV = 22;
  kyCtrlW = 23;
  kyCtrlX = 24;
  kyCtrlY = 25;
  kyCtrlZ = 26;
  kyEsc = 27;
  kyEnter = 13;
  kyBackSpace = 8;
  kyTab = 9;
  kyShiftTab = ExtKeyFlag + ExtShiftFlag + 15;

type
  PKeyboardDriver = ^TKeyboardDriver;
  PKeyInterruptProc = ^TKeyInterruptProc;

  TKeyInterruptProc = procedure(AScanCode: byte; AKeyDown: boolean);

  TKeyboardFlag = (
    kfRightShift,
    kfLeftShift,
    kfControl,
    kfAlt,
    kfScrollLock,
    kfNumLock,
    kfCapsLock,
    kfInsert
  );

  TKeyboardFlags = set of TKeyboardFlag;

  TKeyboardState = record
    ScanCode: byte;
    Down: boolean;
    ShiftState: TKeyboardFlags;
  end;

  TKeyboardDriver = object(TObject)
  private
    FDriverInstalled: boolean;
    procedure InstallInterrupt;
    procedure UninstallInterrupt;
  public
    OnKeyInterrupt: PKeyInterruptProc;
    function KeyPressed: boolean;
    function GetKey: word;
    function KeyToShortcut(AKey: word): string;
    function CharToAltChar(AChar: char): word;
    function UpCase(AKey: word): word;
    procedure ProcessKeyUp(AScanCode: byte);
    procedure ProcessKeyDown(AScanCode: byte);
    procedure CursorOn;
    procedure CursorOff;
    procedure Init; virtual;
    procedure GetKeyState(AScanCode: byte; var AState: TKeyboardState);
    destructor Free; virtual;
  end;

var
  Keyboard: TKeyboardDriver;
  {$IFDEF DOS}
  ShiftStateFlags: TKeyboardFlags absolute $0040:$0017;
  {$ENDIF}

implementation

var
  StoredInt09: pointer;
  {$IFDEF DOS}
  KeyboardHead: byte absolute $0040:$001A;
  KeyboardTail: byte absolute $0040:$001C;
  KeyDown: array[byte] of boolean;
  {$ENDIF}
  PreviousExitProc: PProc;
(*
procedure KeyboardHandler(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: Word); {$IFDEF DOS}interrupt;{$ENDIF}
var
  code: byte;
  int9: pointer;
begin
  asm
    in al, 60h
    mov [code], al
    in al, 61h
    or al, 80h
    out 61h, al
    xor al, 80h
    out 61h, al
    mov al, 20h
    out 20h, al
  end;

  if code and $80 > 0 then begin
    code := code and not $80;
    KeyDown[code] := false;
  end
  else begin
    KeyDown[code] := true;
  end;

  int9 := StoredInt09;
  asm
    call int9;
  end;
end;*)

procedure TKeyboardDriver.ProcessKeyUp;
begin

end;

procedure TKeyboardDriver.ProcessKeyDown;
begin
end;

function TKeyboardDriver.KeyToShortcut(AKey: word): string;
var
  result: string;
begin
  case AKey of
    0: result := '';
    kyAltQ: result := 'Alt+Q';
    kyAltW: result := 'Alt+W';
    kyAltE: result := 'Alt+E';
    kyAltR: result := 'Alt+R';
    kyAltT: result := 'Alt+T';
    kyAltY: result := 'Alt+Y';
    kyAltU: result := 'Alt+U';
    kyAltI: result := 'Alt+I';
    kyAltO: result := 'Alt+O';
    kyAltP: result := 'Alt+P';
    kyAltA: result := 'Alt+A';
    kyAltS: result := 'Alt+S';
    kyAltD: result := 'Alt+D';
    kyAltF: result := 'Alt+F';
    kyAltG: result := 'Alt+G';
    kyAltH: result := 'Alt+H';
    kyAltJ: result := 'Alt+J';
    kyAltK: result := 'Alt+K';
    kyAltL: result := 'Alt+L';
    kyAltZ: result := 'Alt+Z';
    kyAltX: result := 'Alt+X';
    kyAltC: result := 'Alt+C';
    kyAltV: result := 'Alt+V';
    kyAltB: result := 'Alt+B';
    kyAltN: result := 'Alt+N';
    kyAltM: result := 'Alt+M';
    kyF1: result := 'F1';
    kyF2: result := 'F2';
    kyF3: result := 'F3';
    kyF4: result := 'F4';
    kyF5: result := 'F5';
    kyF6: result := 'F6';
    kyF7: result := 'F7';
    kyF8: result := 'F8';
    kyF9: result := 'F9';
    kyF10: result := 'F10';
    kyAltF1: result := 'Alt+F1';
    kyAltF2: result := 'Alt+F2';
    kyAltF3: result := 'Alt+F3';
    kyAltF4: result := 'Alt+F4';
    kyAltF5: result := 'Alt+F5';
    kyAltF6: result := 'Alt+F6';
    kyAltF7: result := 'Alt+F7';
    kyAltF8: result := 'Alt+F8';
    kyAltF9: result := 'Alt+F9';
    kyAltF10: result := 'Alt+F10';
    kyCtrlF1: result := 'Ctrl+F1';
    kyCtrlF2: result := 'Ctrl+F2';
    kyCtrlF3: result := 'Ctrl+F3';
    kyCtrlF4: result := 'Ctrl+F4';
    kyCtrlF5: result := 'Ctrl+F5';
    kyCtrlF6: result := 'Ctrl+F6';
    kyCtrlF7: result := 'Ctrl+F7';
    kyCtrlF8: result := 'Ctrl+F8';
    kyCtrlF9: result := 'Ctrl+F9';
    kyCtrlF10: result := 'F10';
    kyAltF1: result := 'Alt+F1';
    kyAltF2: result := 'Alt+F2';
    kyAltF3: result := 'Alt+F3';
    kyAltF4: result := 'Alt+F4';
    kyAltF5: result := 'Alt+F5';
    kyAltF6: result := 'Alt+F6';
    kyAltF7: result := 'Alt+F7';
    kyAltF8: result := 'Alt+F8';
    kyAltF9: result := 'Alt+F9';
    kyAltF10: result := 'Alt+F10';
    kyShiftF1: result := 'Shift+F1';
    kyShiftF2: result := 'Shift+F2';
    kyShiftF3: result := 'Shift+F3';
    kyShiftF4: result := 'Shift+F4';
    kyShiftF5: result := 'Shift+F5';
    kyShiftF6: result := 'Shift+F6';
    kyShiftF7: result := 'Shift+F7';
    kyShiftF8: result := 'Shift+F8';
    kyShiftF9: result := 'Shift+F9';
    kyShiftF10: result := 'Shift+F10';
    kyAlt1: result := 'Alt+1';
    kyAlt2: result := 'Alt+2';
    kyAlt3: result := 'Alt+3';
    kyAlt4: result := 'Alt+4';
    kyAlt5: result := 'Alt+5';
    kyAlt6: result := 'Alt+6';
    kyAlt7: result := 'Alt+7';
    kyAlt8: result := 'Alt+8';
    kyAlt9: result := 'Alt+9';
    kyAlt0: result := 'Alt+0';
    kyAltDash: result := 'Alt+Dash';
    kyAltEqual: result := 'Alt+Equal';
    kyInsert: result := 'Ins';
    kyDel: result := 'Del';
    kyLeft: result := 'Left';
    kyRight: result := 'Right';
    kyUp: result := 'Up';
    kyDown: result := 'Down';
    kyPageUp: result := 'PgUp';
    kyPageDown: result := 'PgDn';
    kyHome: result := 'Home';
    kyEnd: result := 'End';
    kyCtrlA: result := 'Ctrl+A';
    kyCtrlB: result := 'Ctrl+B';
    kyCtrlC: result := 'Ctrl+C';
    kyCtrlD: result := 'Ctrl+D';
    kyCtrlE: result := 'Ctrl+E';
    kyCtrlF: result := 'Ctrl+F';
    kyCtrlG: result := 'Ctrl+G';
    kyCtrlH: result := 'Ctrl+H';
    kyCtrlI: result := 'Ctrl+I';
    kyCtrlJ: result := 'Ctrl+J';
    kyCtrlK: result := 'Ctrl+K';
    kyCtrlL: result := 'Ctrl+L';
    kyCtrlM: result := 'Ctrl+M';
    kyCtrlN: result := 'Ctrl+N';
    kyCtrlO: result := 'Ctrl+O';
    kyCtrlP: result := 'Ctrl+P';
    kyCtrlQ: result := 'Ctrl+Q';
    kyCtrlR: result := 'Ctrl+R';
    kyCtrlS: result := 'Ctrl+S';
    kyCtrlT: result := 'Ctrl+T';
    kyCtrlU: result := 'Ctrl+U';
    kyCtrlV: result := 'Ctrl+V';
    kyCtrlW: result := 'Ctrl+W';
    kyCtrlX: result := 'Ctrl+X';
    kyCtrlY: result := 'Ctrl+Y';
    kyCtrlZ: result := 'Ctrl+Z';
    kyCtrlRight: result := 'Ctrl '#26;
    kyCtrlLeft: result := 'Ctrl '#27;
    kyEsc: result := 'Esc';
    kyShiftAltA: result := 'Shift+Alt+A';
    kyShiftAltB: result := 'Shift+Alt+B';
    kyShiftAltC: result := 'Shift+Alt+C';
    kyShiftAltD: result := 'Shift+Alt+D';
    kyShiftAltE: result := 'Shift+Alt+E';
    kyShiftAltF: result := 'Shift+Alt+F';
    kyShiftAltG: result := 'Shift+Alt+G';
    kyShiftAltH: result := 'Shift+Alt+H';
    kyShiftAltI: result := 'Shift+Alt+I';
    kyShiftAltJ: result := 'Shift+Alt+J';
    kyShiftAltK: result := 'Shift+Alt+K';
    kyShiftAltL: result := 'Shift+Alt+L';
    kyShiftAltM: result := 'Shift+Alt+M';
    kyShiftAltN: result := 'Shift+Alt+N';
    kyShiftAltO: result := 'Shift+Alt+O';
    kyShiftAltP: result := 'Shift+Alt+P';
    kyShiftAltQ: result := 'Shift+Alt+Q';
    kyShiftAltR: result := 'Shift+Alt+R';
    kyShiftAltS: result := 'Shift+Alt+S';
    kyShiftAltT: result := 'Shift+Alt+T';
    kyShiftAltU: result := 'Shift+Alt+U';
    kyShiftAltV: result := 'Shift+Alt+V';
    kyShiftAltW: result := 'Shift+Alt+W';
    kyShiftAltX: result := 'Shift+Alt+X';
    kyShiftAltY: result := 'Shift+Alt+Y';
    kyShiftAltZ: result := 'Shift+Alt+Z';
  end;
  KeyToShortcut := result;
end;

function TKeyboardDriver.KeyPressed: boolean;
var
  available: byte;
  result: boolean;
begin
  result := false;
  asm
    mov ah, 01h
    int 16h
    jnz @end
    mov [result], 1
    @end:
  end;
  KeyPressed := not result;
end;

procedure TKeyboardDriver.CursorOn;
begin
   asm
    mov   AH, 3
    mov   BX, 0
    int   10h
    and   CH, 255-20h
    mov   AH, 1
    mov   BX, 0
    int   10h
  end;
end;

procedure TKeyboardDriver.CursorOff;
begin
  asm
    mov   AH, 3
    mov   BX, 0
    int   10h
    or    CH, 20h
    and   AH, 1
    mov   BX, 0
    int   10h
  end;
end;

function TKeyboardDriver.GetKey : word;
var
  character: byte;
  scanCode: byte;
  key: word;
  flags: TKeyboardFlags;
begin
  flags := ShiftStateFlags;
  GetKey := 0;
  if not KeyPressed then
    exit;
  asm
    mov ah, 0
    int 16h
    mov [character], al
    mov [scanCode], ah
  end;
  if character = 0 then begin
    key := ExtKeyFlag + scanCode;
    if (kfLeftShift in ShiftStateFlags) or (kfRightShift in ShiftStateFlags) then
      Inc(key, ExtShiftFlag);
  end
  else begin
    if ((kfLeftShift in ShiftStateFlags) or (kfRightShift in ShiftStateFlags))
      and (scanCode in [71..75, 77..83]) then begin
      key := ExtShiftFlag + ExtKeyFlag + scanCode;
    end
    else
      key := character;
  end;
  GetKey := key;
end;

function TKeyboardDriver.Upcase(AKey: word): word;
begin
  if (AKey >= 97) and (AKey <= 122) then
    UpCase := AKey - 32
  else
    UpCase := AKey;
end;

function TKeyboardDriver.CharToAltChar(AChar: char): word;
var
  result: word;
  ch: char;
begin
  ch := System.UpCase(AChar);
  case ch of
    'A': result := kyAltA;
    'B': result := kyAltB;
    'C': result := kyAltC;
    'D': result := kyAltD;
    'E': result := kyAltE;
    'F': result := kyAltF;
    'G': result := kyAltG;
    'H': result := kyAltH;
    'I': result := kyAltI;
    'J': result := kyAltJ;
    'K': result := kyAltK;
    'L': result := kyAltL;
    'M': result := kyAltM;
    'N': result := kyAltN;
    'O': result := kyAltO;
    'P': result := kyAltP;
    'Q': result := kyAltQ;
    'R': result := kyAltR;
    'S': result := kyAltS;
    'T': result := kyAltT;
    'U': result := kyAltU;
    'V': result := kyAltV;
    'W': result := kyAltW;
    'X': result := kyAltX;
    'Y': result := kyAltY;
    'Z': result := kyAltZ;
  end;
  CharToAltChar := result;
end;

procedure TKeyboardDriver.InstallInterrupt;
begin
 if FDriverInstalled then
    exit;
  GetIntVec($09, StoredInt09);
{  SetIntVec($09, @KeyboardHandler);}
  FDriverInstalled := true;
end;

procedure TKeyboardDriver.UninstallInterrupt;
begin
  if not FDriverInstalled then
    exit;
  SetIntVec($09, StoredInt09);
  FDriverInstalled := false;
end;

procedure TKeyboardDriver.GetKeyState(AScanCode: byte; var AState: TKeyboardState);
begin
  FillChar(AState, SizeOf(AState), 0);
  AState.ScanCode := AScanCode;
  AState.Down := KeyDown[AScanCode];
  AState.ShiftState := ShiftStateFlags;
end;

procedure TKeyboardDriver.Init;
begin
  inherited Init;
  FDriverInstalled := false;
  FillChar(KeyDown, SizeOf(KeyDown), 0);
  KeyboardHead := $20;
  KeyboardTail := $20;
{  InstallInterrupt;}
end;

destructor TKeyboardDriver.Free;
begin
{  UninstallInterrupt;}
  inherited Free;
end;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  Keyboard.Free;
  WriteLn('Keyboard driver uninstalled.');
end;

begin
  Keyboard.Create;
  WriteLn('Keyboard driver installed.');
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
