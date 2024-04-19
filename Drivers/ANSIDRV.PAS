{$I COMPILER.INC}
unit AnsiDrv;

interface

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  Objects,
  Lists,
  Common,
  Drawing,
  AplDos,
  TextDrv;

type
  PAnsiDriver = ^TAnsiDriver;

  TAnsiDriver = object(TTextDriver)
  {$IFDEF VER70}private{$ENDIF}
    _startMode: byte;
    function GetTextAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte; virtual;
  {$IFDEF VER70}public{$ENDIF}
    procedure Write(const AText: string); virtual;
    procedure WriteLarge(AText: PChar); virtual;
    procedure SetForeColor(AColor: byte); virtual;
    procedure SetBackColor(AColor: byte); virtual;
    procedure SetBlink(ABlink: boolean); virtual;
    procedure Init; virtual;
    procedure SetMode(AMode: PTextMode); virtual;
    procedure HLine(AX1, AY1, AWidth: integer; ALineStyle: TLineStyle); virtual;
    procedure VLine(AX1, AY1, AHeight: integer; ALineStyle: TLineStyle); virtual;
    procedure Box(ARect: TRect; ALineStyle: TLineStyle); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure SetXY(AX, AY: integer); virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure ClrScr; virtual;
    destructor Done; virtual;
  end;

implementation


procedure TAnsiDriver.SetMode(AMode: PTextMode);
begin
end;

procedure TAnsiDriver.SetXY(AX, AY: integer);
begin
end;

procedure TAnsiDriver.Write(const AText: string);
begin
end;

procedure TAnsiDriver.WriteLarge(AText: PChar);
begin
end;

procedure TAnsiDriver.SetBlink(ABlink: boolean);
begin
end;

procedure TAnsiDriver.SetForeColor(AColor: byte);
begin
end;

procedure TAnsiDriver.SetBackColor(AColor: byte);
begin
end;

procedure TAnsiDriver.CursorOn;
begin
end;

procedure TAnsiDriver.CursorOff;
begin
end;

function TAnsiDriver.GetTextAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte;
begin
end;

procedure TAnsiDriver.Init;
begin
end;

procedure TAnsiDriver.HLine(AX1, AY1, AWidth: integer; ALineStyle: TLineStyle);
begin
end;

procedure TAnsiDriver.VLine(AX1, AY1, AHeight: integer; ALineStyle: TLineStyle);
begin
end;

procedure TAnsiDriver.Box(ARect: TRect; ALineStyle: TLineStyle);
begin
end;

procedure TAnsiDriver.ClrScr;
begin
end;

procedure TAnsiDriver.FillRect(ARect: TRect);
begin
end;

destructor TAnsiDriver.Done;
begin
  inherited Done;
end;

begin
end.
