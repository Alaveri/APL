{$I COMPILER.INC}
unit HercDrv;

interface

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  AplTypes,
  AplObj,
  Common,
  StrUtils,
  Streams,
  Drawing,
  GraphDrv;

type
  PHerculesDriver = ^THerculesDriver;
  THerculesDriver = object(TGraphicsDriver)
  private
  public
    function GetPixel(AX, AY: integer): byte; virtual;
    procedure GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure SetPixel(AX, AY: integer); virtual;
    procedure DrawText(AX, AY: integer; AText: string); virtual;
    procedure DrawTextLarge(AX, AY: integer; AText: PChar); virtual;
    procedure MoveTo(AX, AY: integer); virtual;
    procedure LineTo(AX, AY: integer); virtual;
    procedure Line(AX1, AY1, AX2, AY2: integer); virtual;
    procedure HLine(AX, AY, AWidth: integer); virtual;
    procedure VLine(AX, AY, AHeight: integer); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageTransparent(AX, AY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamTransparent(AX, AY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageBuffer(ABufferPos: TPoint; AImageSize, ABufferSize: TSize; AImage, ABuffer: PByte); virtual;
    procedure DrawImageBufferTransparent(ABufferPos: TPoint; AImageSize, ABufferSize: TSize; AImage, ABuffer: PByte); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

procedure THerculesDriver.Init;
begin
  inherited Init;
end;

function THerculesDriver.GetPixel(AX, AY: integer): byte;
begin
end;

procedure THerculesDriver.SetMode(AMode: PGraphicsMode);
begin
end;

procedure THerculesDriver.SetPixel(AX, AY: integer);
begin
end;

procedure THerculesDriver.DrawText(AX, AY: integer; AText: string);
begin
end;

procedure THerculesDriver.DrawTextLarge(AX, AY: integer; AText: PChar);
begin
end;

procedure THerculesDriver.MoveTo(AX, AY: integer);
begin
end;

procedure THerculesDriver.LineTo(AX, AY: integer);
begin
end;

procedure THerculesDriver.Line(AX1, AY1, AX2, AY2: integer);
begin
end;

procedure THerculesDriver.HLine(AX, AY, AWidth: integer);
begin
end;

procedure THerculesDriver.VLine(AX, AY, AHeight: integer);
begin
end;

procedure THerculesDriver.FillRect(ARect: TRect);
begin
end;

procedure THerculesDriver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure THerculesDriver.DrawImageTransparent(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure THerculesDriver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure THerculesDriver.DrawImageStreamTransparent(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure THerculesDriver.DrawImageBuffer(ABufferPos: TPoint; AImageSize, ABufferSize: TSize; AImage, ABuffer: PByte);
begin
end;

procedure THerculesDriver.DrawImageBufferTransparent(ABufferPos: TPoint; AImageSize, ABufferSize: TSize;
  AImage, ABuffer: PByte);
begin
end;

procedure THerculesDriver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
begin
end;

procedure THerculesDriver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
begin
end;

procedure THerculesDriver.WaitForVSync;
begin
end;

destructor THerculesDriver.Free;
begin
  inherited Free;
end;

begin
end.