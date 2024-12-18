{$I COMPILER.INC}
unit KeyDrv;

interface

uses
  AplObj,
  AplTypes,
  AplUtils,
  Lists,
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

  kyA = 97;
  kyB = 98;
  kyC = 99;
  kyD = 100;
  kyE = 101;
  kyF = 102;
  kyG = 103;
  kyH = 104;
  kyI = 105;
  kyJ = 106;
  kyK = 107;
  kyL = 108;
  kyM = 109;
  kyN = 110;
  kyO = 111;
  kyP = 112;
  kyQ = 113;
  kyR = 114;
  kyS = 115;
  kyT = 116;
  kyU = 117;
  kyV = 118;
  kyW = 119;
  kyX = 120;
  kyY = 121;
  kyZ = 122;

  kyShiftA = 65;
  kyShiftB = 66;
  kyShiftC = 67;
  kyShiftD = 68;
  kyShiftE = 69;
  kyShiftF = 70;
  kyShiftG = 71;
  kyShiftH = 72;
  kyShiftI = 73;
  kyShiftJ = 74;
  kyShiftK = 75;
  kyShiftL = 76;
  kyShiftM = 77;
  kyShiftN = 78;
  kyShiftO = 79;
  kyShiftP = 80;
  kyShiftQ = 81;
  kyShiftR = 82;
  kyShiftS = 83;
  kyShiftT = 84;
  kyShiftU = 85;
  kyShiftV = 86;
  kyShiftW = 87;
  kyShiftX = 88;
  kyShiftY = 89;
  kyShiftZ = 90;

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
  PKeyboardShortcut = ^TKeyboardShortcut;
  PKeyboardShortcutList = ^TKeyboardShortcutList;

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
    procedure GetFlags(var AFlags: TKeyboardFlags);
    procedure CursorOn;
    procedure CursorOff;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TKeyboardShortcut = object(TObject)
  private
  public
    Key: word;
    Shortcut: PChar;
    constructor Create(AKey: word; AShortcut: string);
    constructor CreateKey(AKey: word);
    destructor Free; virtual;
    procedure Init; virtual;
    function GetShortcut: string;
  end;

  TKeyboardShortcutList = object(TObjectList)
    constructor Create;
    procedure Init; virtual;
    function Add(AItem: PKeyboardShortcut): integer;
    function GetItem(AIndex: integer): PKeyboardShortcut;
    function GetShortcutByKey(AKey: word): PKeyboardShortcut;
    function IndexOf(AItem: PKeyboardShortcut): integer;
    procedure SetItem(AIndex: integer; AItem: PKeyboardShortcut);
    procedure Insert(AIndex: integer; AItem: PKeyboardShortcut);
    procedure RemoveItem(AItem: PKeyboardShortcut);
    procedure AddShortcut(AKey: word; AShortcut: string);
  end;

var
  Keyboard: TKeyboardDriver;
  KeyboardShortcuts: PKeyboardShortcutList;

implementation

uses
  AplConst,
  AplStr,
  Strings;

var
  KeyboardHead: byte absolute $0000:$041A;
  KeyboardTail: byte absolute $0000:$041C;
  PreviousExitProc: PProc;

function TKeyboardDriver.KeyToShortcut(AKey: word): string;
var
  result: string;
  var shortcut: PKeyboardShortcut;
begin
  KeyToShortcut := '';
  shortcut := KeyboardShortcuts^.GetShortcutByKey(AKey);
  if Assigned(shortcut) then
    KeyToShortcut := shortcut^.GetShortcut;
end;

function TKeyboardDriver.KeyPressed: boolean;
var
  result: boolean;
begin
  result := false;
  asm
    mov ah, 01h
    int 16h
    jnz @end
    mov result, 1
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
    and   CH, 255 - 20h
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

procedure TKeyboardDriver.GetFlags(var AFlags: TKeyboardFlags);
var
  flags: TKeyboardFlags;
begin
  asm
    mov ah, 2
    int 16h
    mov [flags], al
  end;
  AFlags := flags;
end;

function TKeyboardDriver.GetKey : word;
var
  character: byte;
  scanCode: byte;
  key: word;
  flags: TKeyboardFlags;
begin
  GetKey := 0;
  if not KeyPressed then
    exit;
  asm
    mov ah, 0
    int 16h
    mov [character], al
    mov [scanCode], ah
    mov ah, 2
    int 16h
    mov [flags], al
  end;
  if character = 0 then begin
    key := ExtKeyFlag + scanCode;
    if (kfLeftShift in flags) or (kfRightShift in flags) then
      Inc(key, ExtShiftFlag);
  end
  else begin
    if ((kfLeftShift in flags) or (kfRightShift in flags))
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
  FDriverInstalled := true;
end;

procedure TKeyboardDriver.UninstallInterrupt;
begin
  if not FDriverInstalled then
    exit;
  FDriverInstalled := false;
end;

procedure TKeyboardDriver.Init;
begin
  inherited Init;
  FDriverInstalled := false;
  KeyboardHead := $20;
  KeyboardTail := $20;
end;

destructor TKeyboardDriver.Free;
begin
{  UninstallInterrupt;}
  inherited Free;
end;

constructor TKeyboardShortcut.Create(AKey: word; AShortcut: string);
begin
  inherited Create;
  Key := AKey;
  ShortCut := TString.New(AShortcut);
end;

constructor TKeyboardShortcut.CreateKey(AKey: word);
begin
  inherited Create;
  Key := AKey;
  ShortCut := nil;
end;

procedure TKeyboardShortcut.Init;
begin
  inherited Init;
  Key := 0;
  ShortCut := nil;
end;

destructor TKeyboardShortcut.Free;
begin
  TString.Free(ShortCut);
  inherited Free;
end;

function TKeyboardShortcut.GetShortcut: string;
begin
  GetShortcut := TString.GetString(ShortCut);
end;

function KeyboardShortcutCompare(AItem1, AItem2: pointer): integer; far;
begin
  KeyboardShortcutCompare := integer(PKeyboardShortcut(AItem1)^.Key) - PKeyboardShortcut(AItem2)^.Key;
end;

constructor TKeyboardShortcutList.Create;
begin
  inherited CreateSorted(KeyboardShortcutCompare);
  AddShortcut(kyAltQ, 'Alt+Q');
  AddShortcut(kyAltW, 'Alt+W');
  AddShortcut(kyAltE, 'Alt+E');
  AddShortcut(kyAltR, 'Alt+R');
  AddShortcut(kyAltT, 'Alt+T');
  AddShortcut(kyAltY, 'Alt+Y');
  AddShortcut(kyAltU, 'Alt+U');
  AddShortcut(kyAltI, 'Alt+I');
  AddShortcut(kyAltO, 'Alt+O');
  AddShortcut(kyAltP, 'Alt+P');
  AddShortcut(kyAltA, 'Alt+A');
  AddShortcut(kyAltS, 'Alt+S');
  AddShortcut(kyAltD, 'Alt+D');
  AddShortcut(kyAltF, 'Alt+F');
  AddShortcut(kyAltG, 'Alt+G');
  AddShortcut(kyAltH, 'Alt+H');
  AddShortcut(kyAltJ, 'Alt+J');
  AddShortcut(kyAltK, 'Alt+K');
  AddShortcut(kyAltL, 'Alt+L');
  AddShortcut(kyAltZ, 'Alt+Z');
  AddShortcut(kyAltX, 'Alt+X');
  AddShortcut(kyAltC, 'Alt+C');
  AddShortcut(kyAltV, 'Alt+V');
  AddShortcut(kyAltB, 'Alt+B');
  AddShortcut(kyAltN, 'Alt+N');
  AddShortcut(kyAltM, 'Alt+M');
  AddShortcut(kyA, 'A');
  AddShortcut(kyB, 'B');
  AddShortcut(kyC, 'C');
  AddShortcut(kyD, 'D');
  AddShortcut(kyE, 'E');
  AddShortcut(kyF, 'F');
  AddShortcut(kyG, 'G');
  AddShortcut(kyH, 'H');
  AddShortcut(kyI, 'I');
  AddShortcut(kyJ, 'J');
  AddShortcut(kyK, 'K');
  AddShortcut(kyL, 'L');
  AddShortcut(kyM, 'M');
  AddShortcut(kyN, 'N');
  AddShortcut(kyO, 'O');
  AddShortcut(kyP, 'P');
  AddShortcut(kyQ, 'Q');
  AddShortcut(kyR, 'R');
  AddShortcut(kyS, 'S');
  AddShortcut(kyT, 'T');
  AddShortcut(kyU, 'U');
  AddShortcut(kyV, 'V');
  AddShortcut(kyW, 'W');
  AddShortcut(kyX, 'X');
  AddShortcut(kyY, 'Y');
  AddShortcut(kyZ, 'Z');
  AddShortcut(kyShiftAltQ, 'Shift+Alt+Q');
  AddShortcut(kyShiftAltW, 'Shift+Alt+W');
  AddShortcut(kyShiftAltE, 'Shift+Alt+E');
  AddShortcut(kyShiftAltR, 'Shift+Alt+R');
  AddShortcut(kyShiftAltT, 'Shift+Alt+T');
  AddShortcut(kyShiftAltY, 'Shift+Alt+Y');
  AddShortcut(kyShiftAltU, 'Shift+Alt+U');
  AddShortcut(kyShiftAltI, 'Shift+Alt+I');
  AddShortcut(kyShiftAltO, 'Shift+Alt+O');
  AddShortcut(kyShiftAltP, 'Shift+Alt+P');
  AddShortcut(kyShiftAltA, 'Shift+Alt+A');
  AddShortcut(kyShiftAltS, 'Shift+Alt+S');
  AddShortcut(kyShiftAltD, 'Shift+Alt+D');
  AddShortcut(kyShiftAltF, 'Shift+Alt+F');
  AddShortcut(kyShiftAltG, 'Shift+Alt+G');
  AddShortcut(kyShiftAltH, 'Shift+Alt+H');
  AddShortcut(kyShiftAltJ, 'Shift+Alt+J');
  AddShortcut(kyShiftAltK, 'Shift+Alt+K');
  AddShortcut(kyShiftAltL, 'Shift+Alt+L');
  AddShortcut(kyShiftAltZ, 'Shift+Alt+Z');
  AddShortcut(kyShiftAltX, 'Shift+Alt+X');
  AddShortcut(kyShiftAltC, 'Shift+Alt+C');
  AddShortcut(kyShiftAltV, 'Shift+Alt+V');
  AddShortcut(kyShiftAltB, 'Shift+Alt+B');
  AddShortcut(kyShiftAltN, 'Shift+Alt+N');
  AddShortcut(kyShiftAltM, 'Shift+Alt+M');
  AddShortcut(kyF1, 'F1');
  AddShortcut(kyF2, 'F2');
  AddShortcut(kyF3, 'F3');
  AddShortcut(kyF4, 'F4');
  AddShortcut(kyF5, 'F5');
  AddShortcut(kyF6, 'F6');
  AddShortcut(kyF7, 'F7');
  AddShortcut(kyF8, 'F8');
  AddShortcut(kyF9, 'F9');
  AddShortcut(kyF10, 'F10');
  AddShortcut(kyAltF1, 'Alt+F1');
  AddShortcut(kyAltF2, 'Alt+F2');
  AddShortcut(kyAltF3, 'Alt+F3');
  AddShortcut(kyAltF4, 'Alt+F4');
  AddShortcut(kyAltF5, 'Alt+F5');
  AddShortcut(kyAltF6, 'Alt+F6');
  AddShortcut(kyAltF7, 'Alt+F7');
  AddShortcut(kyAltF8, 'Alt+F8');
  AddShortcut(kyAltF9, 'Alt+F9');
  AddShortcut(kyAltF10, 'Alt+F10');
  AddShortcut(kyShiftF1, 'Shift+F1');
  AddShortcut(kyShiftF2, 'Shift+F2');
  AddShortcut(kyShiftF3, 'Shift+F3');
  AddShortcut(kyShiftF4, 'Shift+F4');
  AddShortcut(kyShiftF5, 'Shift+F5');
  AddShortcut(kyShiftF6, 'Shift+F6');
  AddShortcut(kyShiftF7, 'Shift+F7');
  AddShortcut(kyShiftF8, 'Shift+F8');
  AddShortcut(kyShiftF9, 'Shift+F9');
  AddShortcut(kyShiftF10, 'Shift+F10');
  AddShortcut(kyCtrlF1, 'Ctrl+F1');
  AddShortcut(kyCtrlF2, 'Ctrl+F2');
  AddShortcut(kyCtrlF3, 'Ctrl+F3');
  AddShortcut(kyCtrlF4, 'Ctrl+F4');
  AddShortcut(kyCtrlF5, 'Ctrl+F5');
  AddShortcut(kyCtrlF6, 'Ctrl+F6');
  AddShortcut(kyCtrlF7, 'Ctrl+F7');
  AddShortcut(kyCtrlF8, 'Ctrl+F8');
  AddShortcut(kyCtrlF9, 'Ctrl+F9');
  AddShortcut(kyCtrlF10, 'Ctrl+F10');
  AddShortcut(kyAlt1, 'Alt+1');
  AddShortcut(kyAlt2, 'Alt+2');
  AddShortcut(kyAlt3, 'Alt+3');
  AddShortcut(kyAlt4, 'Alt+4');
  AddShortcut(kyAlt5, 'Alt+5');
  AddShortcut(kyAlt6, 'Alt+6');
  AddShortcut(kyAlt7, 'Alt+7');
  AddShortcut(kyAlt8, 'Alt+8');
  AddShortcut(kyAlt9, 'Alt+9');
  AddShortcut(kyAlt0, 'Alt+0');
  AddShortcut(kyShiftAlt1, 'Shift+Alt+1');
  AddShortcut(kyShiftAlt2, 'Shift+Alt+2');
  AddShortcut(kyShiftAlt3, 'Shift+Alt+3');
  AddShortcut(kyShiftAlt4, 'Shift+Alt+4');
  AddShortcut(kyShiftAlt5, 'Shift+Alt+5');
  AddShortcut(kyShiftAlt6, 'Shift+Alt+6');
  AddShortcut(kyShiftAlt7, 'Shift+Alt+7');
  AddShortcut(kyShiftAlt8, 'Shift+Alt+8');
  AddShortcut(kyShiftAlt9, 'Shift+Alt+9');
  AddShortcut(kyShiftAlt0, 'Shift+Alt+0');
  AddShortcut(kyAltDash, 'Alt+-');
  AddShortcut(kyAltEqual, 'Alt+=');
  AddShortcut(kyInsert, 'Ins');
  AddShortcut(kyDel, 'Del');
  AddShortcut(kyLeft, 'Left');
  AddShortcut(kyRight, 'Right');
  AddShortcut(kyUp, 'Up');
  AddShortcut(kyDown, 'Down');
  AddShortcut(kyPageUp, 'PgUp');
  AddShortcut(kyPageDown, 'PgDn');
  AddShortcut(kyHome, 'Home');
  AddShortcut(kyEnd, 'End');
  AddShortcut(kyCtrlLeft, 'Ctrl+Left');
  AddShortcut(kyCtrlRight, 'Ctrl+Right');
  AddShortcut(kyCtrlPageUp, 'Ctrl+PgUp');
  AddShortcut(kyCtrlPageDown, 'Ctrl+PgDn');
  AddShortcut(kyCtrlHome, 'Ctrl+Home');
  AddShortcut(kyCtrlEnd, 'Ctrl+End');
  AddShortcut(kyShiftDel, 'Shift+Del');
  AddShortcut(kyShiftLeft, 'Shift+Left');
  AddShortcut(kyShiftRight, 'Shift+Right');
  AddShortcut(kyShiftUp, 'Shift+Up');
  AddShortcut(kyShiftDown, 'Shift+Down');
  AddShortcut(kyShiftPageUp, 'Shift+PgUp');
  AddShortcut(kyShiftPageDown, 'Shift+PgDn');
  AddShortcut(kyShiftHome, 'Shift+Home');
  AddShortcut(kyShiftEnd, 'Shift+End');
  AddShortcut(kyShiftIns, 'Shift+Ins');
  AddShortcut(kyShiftCtrlLeft, 'Shift+Ctrl+Left');
  AddShortcut(kyShiftCtrlRight, 'Shift+Ctrl+Right');
  AddShortcut(kyShiftCtrlPageUp, 'Shift+Ctrl+PgUp');
  AddShortcut(kyShiftCtrlPageDown, 'Shift+Ctrl+PgDn');
  AddShortcut(kyShiftCtrlHome, 'Shift+Ctrl+Home');
  AddShortcut(kyShiftCtrlEnd, 'Shift+Ctrl+End');
  AddShortcut(kyCtrlA, 'Ctrl+A');
  AddShortcut(kyCtrlB, 'Ctrl+B');
  AddShortcut(kyCtrlC, 'Ctrl+C');
  AddShortcut(kyCtrlD, 'Ctrl+D');
  AddShortcut(kyCtrlE, 'Ctrl+E');
  AddShortcut(kyCtrlF, 'Ctrl+F');
  AddShortcut(kyCtrlG, 'Ctrl+G');
  AddShortcut(kyCtrlH, 'Ctrl+H');
  AddShortcut(kyCtrlI, 'Ctrl+I');
  AddShortcut(kyCtrlJ, 'Ctrl+J');
  AddShortcut(kyCtrlK, 'Ctrl+K');
  AddShortcut(kyCtrlL, 'Ctrl+L');
  AddShortcut(kyCtrlM, 'Ctrl+M');
  AddShortcut(kyCtrlN, 'Ctrl+N');
  AddShortcut(kyCtrlO, 'Ctrl+O');
  AddShortcut(kyCtrlP, 'Ctrl+P');
  AddShortcut(kyCtrlQ, 'Ctrl+Q');
  AddShortcut(kyCtrlR, 'Ctrl+R');
  AddShortcut(kyCtrlS, 'Ctrl+S');
  AddShortcut(kyCtrlT, 'Ctrl+T');
  AddShortcut(kyCtrlU, 'Ctrl+U');
  AddShortcut(kyCtrlV, 'Ctrl+V');
  AddShortcut(kyCtrlW, 'Ctrl+W');
  AddShortcut(kyCtrlX, 'Ctrl+X');
  AddShortcut(kyCtrlY, 'Ctrl+Y');
  AddShortcut(kyCtrlZ, 'Ctrl+Z');
  AddShortcut(kyEsc, 'Esc');
  AddShortcut(kyEnter, 'Enter');
  AddShortcut(kyBackSpace, 'Backspace');
  AddShortcut(kyTab, 'Tab');
  AddShortcut(kyShiftTab, 'Shift+Tab');
end;

procedure TKeyboardShortcutList.Init;
begin
  inherited Init;
end;

function TKeyboardShortcutList.Add(AItem: PKeyboardShortcut): integer;
begin
  inherited Add(AItem);
end;

function TKeyboardShortcutList.GetItem(AIndex: integer): PKeyboardShortcut;
begin
  GetItem := PKeyboardShortcut(inherited GetItem(AIndex));
end;

function TKeyboardShortcutList.IndexOf(AItem: PKeyboardShortcut): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TKeyboardShortcutList.SetItem(AIndex: integer; AItem: PKeyboardShortcut);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TKeyboardShortcutList.Insert(AIndex: integer; AItem: PKeyboardShortcut);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TKeyboardShortcutList.RemoveItem(AItem: PKeyboardShortcut);
begin
  inherited RemoveItem(AItem);
end;

procedure TKeyboardShortcutList.AddShortcut(AKey: word; AShortcut: string);
begin
  Add(New(PKeyboardShortcut, Create(AKey, AShortcut)));
end;

function TKeyboardShortcutList.GetShortcutByKey(AKey: word): PKeyboardShortcut;
var
  index: integer;
  searchValue: TKeyboardShortcut;
begin
  GetShortcutByKey := nil;
  searchValue.CreateKey(AKey);
  index := BinarySearch(@searchValue);
  searchValue.Free;
  if index >= 0 then
    GetShortcutByKey := GetItem(index);
end;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  Keyboard.Free;
  FreeAndNil(KeyboardShortcuts);
  WriteLn('Keyboard driver uninstalled.');
end;

begin
  Keyboard.Create;
  KeyboardShortcuts := New(PKeyboardShortcutList, Create);
  WriteLn('Keyboard driver installed.');
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
