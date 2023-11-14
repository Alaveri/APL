{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit TextDrv;

interface

uses
  Objects,
  Collects,
  Consts,
  Common,
  MouseDrv,
  Strings,
  Drawing;

type
  PTextDriver = ^TTextDriver;
  PTextState = ^TTextState;
  PTextMode = ^TTextMode;
  PTextModeList = ^TTextModeList;

  TTextChar = record
    Character: char;
    Attributes: byte;
  end;

  TLineStyle = (
    lsSingle,
    lsDouble
  );

  TTextState = object(TObject)
  public
    ForeColor, BackColor: byte;
    Blink: boolean;
    X, Y: integer;
    Attributes: byte;
    IsCursorOn: boolean;
    ViewPort: TRect;
    procedure Init; virtual;
    function GetTypeName: string; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TTextMode = Object(TIdObject)
  private
  public
    Width, Height, MaxX, MaxY: integer;
    Name: string50;
    AdditionalData: integer;
    Description: string;
    HelpText: string;
    procedure Init; virtual;
    procedure GetBounds(var ARect: TRect); virtual;
  end;

  TTextModeList = object(TIdObjectList)
  private
  public
    function GetItem(AIndex: integer): PTextMode;
    function GetItemById(const AId: string): PTextMode;
    function IndexOfId(const AId: string): integer;
    function IndexOf(AItem: PTextMode): integer;
    function Add(AItem: PTextMode): integer;
    procedure Insert(AIndex: integer; AItem: PTextMode);
  end;

  TTextDriver = Object(TObject)
    FStateStack: PStack;
  public
    Mode: PTextMode;
    Modes: PTextModeList;
    State: PTextState;
    BppMode: byte;
    Scroll: boolean;
    function TextWidth(const AText: string): integer; virtual;
    function TextWidthLarge(AText: PChar): integer; virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure RenderText(AText: PChar; ALength: word); virtual;
    procedure Write(const AText: string); virtual;
    procedure WriteLarge(AText: PChar); virtual;
    procedure WriteLn(const AText: string); virtual;
    procedure WriteLnLarge(AText: PChar); virtual;
    procedure SetForeColor(AColor: byte); virtual;
    procedure SetBackColor(AColor: byte); virtual;
    procedure SetBlink(ABlink: boolean); virtual;
    procedure SetXY(AXPos, AYPos: byte); virtual;
    procedure ScrollText; virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure Init; virtual;
    procedure SetMode(AMode: PTextMode); virtual;
    procedure HLine(AX, AY, AWidth: integer; ALineStyle: TLineStyle); virtual;
    procedure VLine(AX, AY, AHeight: integer; ALineStyle: TLineStyle); virtual;
    procedure Box(ARect: TRect; ALineStyle: TLineStyle); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure Rectangle(ARect: TRect; ALineStyle: TLineStyle); virtual;
    procedure ClrScr; virtual;
    procedure ShowMouseCursor; virtual;
    procedure HideMouseCursor; virtual;
    function ForeColor: byte; virtual;
    function BackColor: byte; virtual;
    destructor Free; virtual;
  end;

var
  Text: PTextDriver;

implementation

procedure TTextState.Init;
begin
  ForeColor := 0;
  BackColor := 0;
  X := 0;
  Y := 0;
  Blink := false;
  Attributes := 0;
  IsCursorOn := true;
  ViewPort.Create;
end;

procedure TTextState.Assign(var ASource: TObject);
var
  state: PTextState;
begin
  inherited Assign(ASource);
  state := PTextState(@ASource);
  ForeColor := state^.ForeColor;
  BackColor := state^.BackColor;
  Blink := state^.Blink;
  X := state^.X;
  Y := state^.Y;
  Attributes := state^.Attributes;
  IsCursorOn := state^.IsCursorOn;
  ViewPort.SetRect(state^.ViewPort);
end;

function TTextState.GetTypeName: string;
begin
  GetTypeName := 'TTextState';
end;

procedure TTextMode.Init;
begin
  inherited Init;
  Width := 0;
  Height := 0;
  MaxX := 0;
  MaxY := 0;
  Name := '';
  AdditionalData := 0;
  Description := '';
  HelpText := '';
end;

procedure TTextMode.GetBounds(var ARect: TRect);
begin
  ARect.CreateDims(0, 0, Width, Height);
end;

function TTextModeList.GetItem(AIndex: integer): PTextMode;
begin
  GetItem := PTextMode(inherited GetItem(AIndex));
end;

function TTextModeList.GetItemById(const AId: string): PTextMode;
begin
  GetItemById := PTextMode(inherited GetItemById(AId));
end;

function TTextModeList.IndexOfId(const AId: string): integer;
begin
  IndexOfId := inherited IndexOfId(AId);
end;

function TTextModeList.IndexOf(AItem: PTextMode): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TTextModeList.Add(AItem: PTextMode): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TTextModeList.Insert(AIndex: integer; AItem: PTextMode);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TTextDriver.PushState;
var
  newState: PTextState;
begin
  newState := New(PTextState, Create);
  newState^.Assign(State^);
  FStateStack^.Push(newState);
end;

procedure TTextDriver.PopState;
var
  oldState: PTextState;
begin
  oldState := PTextState(FStateStack^.Pop);
  if (oldState = nil) then exit;
  State^.Assign(oldState^);
  Dispose(oldState, Free);
  if State^.IsCursorOn then
    CursorOn
  else
    CursorOff;
  SetXY(State^.X, State^.Y);
end;

procedure TTextDriver.SetXY(AXPos, AYPos: byte);
begin
  State^.X := AXPos;
  State^.Y := AYPos;
end;

procedure TTextDriver.SetMode(AMode: PTextMode);
begin
  State^.ViewPort.SetDims(0, 0, AMode^.Width, AMode^.Height);
end;

procedure TTextDriver.RenderText(AText: PChar; ALength: word);
begin
end;

procedure TTextDriver.Write(const AText: string);
begin
end;

procedure TTextDriver.WriteLarge(AText: PChar);
begin
end;

procedure TTextDriver.WriteLn(const AText: string);
begin
end;

procedure TTextDriver.WriteLnLarge(AText: PChar);
begin
end;

procedure TTextDriver.SetForeColor(AColor: byte);
begin
  State^.ForeColor := AColor;
end;

procedure TTextDriver.SetBlink(ABlink: boolean);
begin
  State^.Blink := ABlink;
end;

procedure TTextDriver.SetBackColor(AColor: byte);
begin
  State^.BackColor := AColor;
end;

procedure TTextDriver.CursorOn;
begin
  State^.IsCursorOn := true;
end;

procedure TTextDriver.CursorOff;
begin
  State^.IsCursorOn := false;
end;

function TTextDriver.TextWidth(const AText: string): integer;
begin
  TextWidth := Length(AText);
end;

function TTextDriver.TextWidthLarge(AText: PChar): integer;
begin
  TextWidthLarge := StrLen(AText);
end;

procedure TTextDriver.Init;
begin
  Modes := New(PTextModeList, Create);
  State := New(PTextState, Create);
  FStateStack := New(PStack, Create);
  Mode := nil;
  BppMode := 4;
  State^.ViewPort.Create;
  Scroll := true;
end;

procedure TTextDriver.Rectangle(ARect: TRect; ALineStyle: TLineStyle);
begin
end;

destructor TTextDriver.Free;
begin
  Dispose(Modes, Free);
  Dispose(State, Free);
  Dispose(FStateStack, Free);
  inherited Free;
end;

procedure TTextDriver.HLine(AX, AY, AWidth: integer; ALineStyle: TLineStyle);
begin
end;

procedure TTextDriver.VLine(AX, AY, AHeight: integer; ALineStyle: TLineStyle);
begin
end;

procedure TTextDriver.Box(ARect: TRect; ALineStyle: TLineStyle);
begin
end;

procedure TTextDriver.ClrScr;
begin
end;

procedure TTextDriver.FillRect(ARect: TRect);
begin
end;

function TTextDriver.ForeColor: byte;
begin
  ForeColor := State^.ForeColor;
end;

function TTextDriver.BackColor: byte;
begin
  BackColor := State^.BackColor;
end;

procedure TTextDriver.ShowMouseCursor;
begin
  Mouse.ShowMouse;
end;

procedure TTextDriver.HideMouseCursor;
begin
  Mouse.HideMouse;
end;

procedure TTextDriver.ScrollText;
begin
end;

end.