{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit KeyDrv;

interface

uses
  Crt,
  Objects;

const
  { Extended Codes }
  kyAltQ = 316;
  kyAltW = 317;
  kyAltE = 318;
  kyAltR = 319;
  kyAltT = 320;
  kyAltY = 321;
  kyAltU = 322;
  kyAltI = 323;
  kyAltO = 324;
  kyAltP = 325;
  kyAltA = 330;
  kyAltS = 331;
  kyAltD = 332;
  kyAltF = 333;
  kyAltG = 334;
  kyAltH = 335;
  kyAltJ = 336;
  kyAltK = 337;
  kyAltL = 338;
  kyAltZ = 344;
  kyAltX = 345;
  kyAltC = 346;
  kyAltV = 347;
  kyAltB = 348;
  kyAltN = 349;
  kyAltM = 350;
  kyF1 = 359;
  kyF2 = 360;
  kyF3 = 361;
  kyF4 = 362;
  kyF5 = 363;
  kyF6 = 364;
  kyF7 = 365;
  kyF8 = 366;
  kyF9 = 367;
  kyF10 = 368;
  kyAltF1 = 404;
  kyAltF2 = 405;
  kyAltF3 = 406;
  kyAltF4 = 407;
  kyAltF5 = 408;
  kyAltF6 = 409;
  kyAltF7 = 410;
  kyAltF8 = 411;
  kyAltF9 = 412;
  kyAltF10 = 413;
  kyShiftF1 = 384;
  kyShiftF2 = 385;
  kyShiftF3 = 386;
  kyShiftF4 = 387;
  kyShiftF5 = 388;
  kyShiftF6 = 389;
  kyShiftF7 = 390;
  kyShiftF8 = 391;
  kyShiftF9 = 392;
  kyShiftF10 = 393;
  kyAlt1 = 420;
  kyAlt2 = 421;
  kyAlt3 = 422;
  kyAlt4 = 423;
  kyAlt5 = 424;
  kyAlt6 = 425;
  kyAlt7 = 426;
  kyAlt8 = 427;
  kyAlt9 = 428;
  kyAlt0 = 429;
  kyAltDash = 430;
  kyAltEqual = 431;
  kyInsert = 382;
  kyDel = 383;
  kyLeft = 375;
  kyRight = 377;
  kyUp = 372;
  kyDown = 380;
  kyPageUp = 373;
  kyPageDown = 381;

  { Standard Codes }
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

type
  PKeyboardDriver = ^TKeyboardDriver;
  TKeyboardDriver = object(TBaseObject)
  private
  public
    function KeyPressed: boolean; virtual;
    function GetKey: word; virtual;
    function KeyToShortcut(key: word): string; virtual;
    function CharToAltChar(ch: char): word; virtual;
    function UpCase(key: word): word; virtual;
  end;

var
  Keyboard: TKeyboardDriver;

implementation

function TKeyboardDriver.KeyToShortcut(key: word): string;
var
  result: string;
begin
  case key of
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
  end;
  KeyToShortcut := result;
end;

function TKeyboardDriver.KeyPressed: boolean;
begin
  KeyPressed := Crt.KeyPressed;
end;

function TKeyboardDriver.GetKey : word;
var
  ch: char;
begin
  GetKey := 0;
  if not KeyPressed then exit;
  ch := ReadKey;
  if (ch = #0) then begin
    ch := ReadKey;
    GetKey := 300+ord(ch);
  end
  else
    GetKey := ord(ch);
end;

function TKeyboardDriver.UpCase(key: word): word;
begin
  if (key >= 97) and (key <= 122) then
    UpCase := key - 32
  else
    UpCase := key;
end;

function TKeyboardDriver.CharToAltChar(ch: char): word;
var
  result: word;
begin
  case System.UpCase(ch) of
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

end.
