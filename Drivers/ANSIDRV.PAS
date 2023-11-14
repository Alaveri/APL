{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit AnsiDrv;

interface

uses
  Objects,
  Collects,
  Common,
  Drawing,
  DosConst,
  Strings,
  TextDrv;

type
  PAnsiDriver = ^TAnsiDriver;

  TAnsiDriver = object(TTextDriver)
  private
    _startMode: byte;
    function GetTextAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte; virtual;
  public
    function GetTypeName: string; virtual;
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

function TAnsiDriver.GetTypeName: string;
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
