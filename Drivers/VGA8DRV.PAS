unit Vga8Drv;

interface

uses
  Objects,
  GraphDrv,
  Utils,
  StrUtils,
  Streams,
  Drawing;

type
  PVga8Driver = ^TVga8Driver;
  TVga8Driver = object(TGraphicsDriver)
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

function TVga8Driver.GetPixel(x, y: integer): byte;
begin
end;

procedure TVga8Driver.GetImage(x, y, width, height: longint; buffer: PByte);
begin
end;

procedure TVga8Driver.GetImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TVga8Driver.SetMode(newMode: PGraphicsMode);
begin
end;

procedure TVga8Driver.SetPixel(x, y: integer);
begin
end;

procedure TVga8Driver.DrawText(x, y: integer; text: string);
begin
end;

procedure TVga8Driver.DrawTextLarge(x, y: integer; text: PChar);
begin
end;

procedure TVga8Driver.MoveTo(x, y: integer);
begin
end;

procedure TVga8Driver.LineTo(x, y: integer);
begin
end;

procedure TVga8Driver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure TVga8Driver.HLine(x, y, width: integer);
begin
end;

procedure TVga8Driver.VLine(x, y, height: integer);
begin
end;

procedure TVga8Driver.FillRect(rect: TRect);
begin
end;

procedure TVga8Driver.DrawImage(x, y, width, height: longint; image: PByte);
begin
end;

procedure TVga8Driver.DrawImageTransparent(x, y, width, height: longint; image: PByte);
begin
end;

procedure TVga8Driver.DrawImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TVga8Driver.DrawImageStreamTransparent(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TVga8Driver.DrawImageBuffer(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
begin
end;

procedure TVga8Driver.DrawImageBufferTransparent(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
begin
end;

procedure TVga8Driver.WaitForVSync;
begin
end;

procedure TVga8Driver.Init;
begin
end;

destructor TVga8Driver.Done;
begin
end;

end.