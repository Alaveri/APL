unit EgaDrv;

interface

uses
  Objects,
  GraphDrv,
  Common,
  StrUtils,
  Streams,
  Drawing;

type
  PEgaDriver = ^TEgaDriver;
  TEgaDriver = object(TGraphicsDriver)
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

function TEgaDriver.GetPixel(x, y: integer): byte;
begin
end;

procedure TEgaDriver.GetImage(x, y, width, height: longint; buffer: PByte);
begin
end;

procedure TEgaDriver.GetImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TEgaDriver.SetMode(newMode: PGraphicsMode);
begin
end;

procedure TEgaDriver.SetPixel(x, y: integer);
begin
end;

procedure TEgaDriver.DrawText(x, y: integer; text: string);
begin
end;

procedure TEgaDriver.DrawTextLarge(x, y: integer; text: PChar);
begin
end;

procedure TEgaDriver.MoveTo(x, y: integer);
begin
end;

procedure TEgaDriver.LineTo(x, y: integer);
begin
end;

procedure TEgaDriver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure TEgaDriver.HLine(x, y, width: integer);
begin
end;

procedure TEgaDriver.VLine(x, y, height: integer);
begin
end;

procedure TEgaDriver.FillRect(rect: TRect);
begin
end;

procedure TEgaDriver.DrawImage(x, y, width, height: longint; image: PByte);
begin
end;

procedure TEgaDriver.DrawImageTransparent(x, y, width, height: longint; image: PByte);
begin
end;

procedure TEgaDriver.DrawImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TEgaDriver.DrawImageStreamTransparent(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TEgaDriver.DrawImageBuffer(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
begin
end;

procedure TEgaDriver.DrawImageBufferTransparent(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
begin
end;

procedure TEgaDriver.WaitForVSync;
begin
end;

procedure TEgaDriver.Init;
begin
end;

destructor TEgaDriver.Done;
begin
end;

end.