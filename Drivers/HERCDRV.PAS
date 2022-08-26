unit HercDrv;

interface

uses
  Objects,
  GraphDrv,
  Utils,
  StrUtils,
  Streams,
  Drawing;

type
  PHerculesDriver = ^THerculesDriver;
  THerculesDriver = object(TGraphicsDriver)
  private
  public
    function GetPixel(x, y: integer): byte; virtual;
    procedure GetImage(x, y, width, height: longint; buffer: PByte); virtual;
    procedure GetImageStream(x, y, width, height: longint; stream: PStream); virtual;
    procedure SetMode(newMode: PGraphicsMode); virtual;
    procedure SetPixel(x, y: integer); virtual;
    procedure DrawText(x, y: integer; text: string); virtual;
    procedure DrawTextLarge(x, y: integer; text: PChar); virtual;
    procedure MoveTo(x, y: integer); virtual;
    procedure LineTo(x, y: integer); virtual;
    procedure Line(x1, y1, x2, y2: integer); virtual;
    procedure HLine(x, y, width: integer); virtual;
    procedure VLine(x, y, height: integer); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure DrawImage(x, y, width, height: longint; image: PByte); virtual;
    procedure DrawImageTransparent(x, y, width, height: longint; image: PByte); virtual;
    procedure DrawImageStream(x, y, width, height: longint; stream: PStream); virtual;
    procedure DrawImageStreamTransparent(x, y, width, height: longint; stream: PStream); virtual;
    procedure DrawImageBuffer(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte); virtual;
    procedure DrawImageBufferTransparent(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Done; virtual;
  end;

implementation

function THerculesDriver.GetPixel(x, y: integer): byte;
begin
end;

procedure THerculesDriver.GetImage(x, y, width, height: longint; buffer: PByte);
begin
end;

procedure THerculesDriver.GetImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

procedure THerculesDriver.SetMode(newMode: PGraphicsMode);
begin
end;

procedure THerculesDriver.SetPixel(x, y: integer);
begin
end;

procedure THerculesDriver.DrawText(x, y: integer; text: string);
begin
end;

procedure THerculesDriver.DrawTextLarge(x, y: integer; text: PChar);
begin
end;

procedure THerculesDriver.MoveTo(x, y: integer);
begin
end;

procedure THerculesDriver.LineTo(x, y: integer);
begin
end;

procedure THerculesDriver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure THerculesDriver.HLine(x, y, width: integer);
begin
end;

procedure THerculesDriver.VLine(x, y, height: integer);
begin
end;

procedure THerculesDriver.FillRect(rect: TRect);
begin
end;

procedure THerculesDriver.DrawImage(x, y, width, height: longint; image: PByte);
begin
end;

procedure THerculesDriver.DrawImageTransparent(x, y, width, height: longint; image: PByte);
begin
end;

procedure THerculesDriver.DrawImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

procedure THerculesDriver.DrawImageStreamTransparent(x, y, width, height: longint; stream: PStream);
begin
end;

procedure THerculesDriver.DrawImageBuffer(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
begin
end;

procedure THerculesDriver.DrawImageBufferTransparent(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
begin
end;

procedure THerculesDriver.WaitForVSync;
begin
end;

procedure THerculesDriver.Init;
begin
end;

destructor THerculesDriver.Done;
begin
end;

end.