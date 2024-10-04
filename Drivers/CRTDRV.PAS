{$I COMPILER.INC}
unit CrtDrv;

interface

uses
  TextDrv,
  Crt;

type
  PCrtTextDriver = ^TCrtTextDriver;

  TCrtTextDriver = object(TTextDriver)
  private
    FStartMode: byte;
    function GetTextAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte; virtual;
  public
    procedure RenderText(AXPos, AYPos: byte; AText: PChar; ALength: word); virtual;
    procedure Write(const AText: string); virtual;
    procedure WriteLarge(AText: PChar); virtual;
    procedure WriteLn(const AText: string); virtual;
    procedure WriteLnLarge(AText: PChar); virtual;
    procedure SetForeColor(AColor: byte); virtual;
    procedure SetBackColor(AColor: byte); virtual;
    procedure SetBlink(ABlink: boolean); virtual;
    procedure Init; virtual;
    procedure SetMode(AMode: PTextMode); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure SetXY(AXPos, AYPos: byte); virtual;
    procedure ScrollText; virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure ClrScr; virtual;
    destructor Free; virtual;
  end;

implementation

function TCrtTextDriver.GetTextAttributes(AForeColor, ABackColor: byte; ABlink: boolean): byte;
begin
  GetTextAttributes := AForeColor or (ABackColor shl 4) or (byte(ABlink) shl 7);
end;

procedure TCrtTextDriver.RenderText(AXPos, AYPos: byte; AText: PChar; ALength: word);
var
  index: word;
begin
  GotoXY(AXPos + 1, AYPos + 1);
  for index := 0 to ALength - 1 do
    Write(AText[index]);
end;

end.