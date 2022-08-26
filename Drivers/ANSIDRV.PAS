unit AnsiDrv;

interface

uses
  Objects,
  Collects,
  Utils,
  Drawing,
  DosConst,
  Strings,
  TextDrv;

type
  PAnsiDriver = ^TAnsiDriver;
  TAnsiDriver = object(TTextDriver)
  private
    _startMode: byte;
    function GetTextAttributes(fore, back: byte; doBlink: boolean): byte; virtual;
  public
    function GetTypeName: string; virtual;
    procedure Write(const txt: string); virtual;
    procedure WriteLarge(txt: PChar); virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure SetBlink(doBlink: boolean); virtual;
    procedure Init; virtual;
    procedure SetMode(newMode: PTextMode); virtual;
    procedure HLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure VLine(x1, y1, height: byte; lineStyle: TLineStyle); virtual;
    procedure Box(rect: TRect; style: TLineStyle); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure SetXY(newX, newY: byte); virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure ClrScr; virtual;
    destructor Done; virtual;
  end;

implementation


procedure TAnsiDriver.SetMode(newMode: PTextMode);
begin
end;

procedure TAnsiDriver.SetXY(newX, newY: byte);
begin
end;

procedure TAnsiDriver.Write(const txt: string);
begin
end;

procedure TAnsiDriver.WriteLarge(txt: PChar);
begin
end;

procedure TAnsiDriver.SetBlink(doBlink: boolean);
begin
end;

procedure TAnsiDriver.SetForeColor(color: byte);
begin
end;

procedure TAnsiDriver.SetBackColor(color: byte);
begin
end;

procedure TAnsiDriver.CursorOn;
begin
end;

procedure TAnsiDriver.CursorOff;
begin
end;

function TAnsiDriver.GetTextAttributes(fore, back: byte; doBlink: boolean): byte;
begin
end;

function TAnsiDriver.GetTypeName: string;
begin
end;

procedure TAnsiDriver.Init;
begin
end;

procedure TAnsiDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TAnsiDriver.VLine(x1, y1, height: byte; lineStyle: TLineStyle);
begin
end;

procedure TAnsiDriver.Box(rect: TRect; style: TLineStyle);
begin
end;

procedure TAnsiDriver.ClrScr;
begin
end;

procedure TAnsiDriver.FillRect(rect: TRect);
begin
end;

destructor TAnsiDriver.Done;
begin
  inherited Done;
end;

begin
end.
