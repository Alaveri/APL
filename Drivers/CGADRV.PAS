unit CgaDrv;

interface

uses
  Objects,
  GraphDrv,
  Common,
  Streams,
  Drawing;

type
  PCgaDriver = ^TCgaDriver;
  TCgaDriver = object(TGraphicsDriver)
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

function TCgaDriver.GetPixel(x, y: integer): byte;
begin
end;

procedure TCgaDriver.GetImage(x, y, width, height: longint; buffer: PByte);
begin
end;

procedure TCgaDriver.GetImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TCgaDriver.SetMode(newMode: PGraphicsMode);
begin
end;

procedure TCgaDriver.SetPixel(x, y: integer);
begin
end;

procedure TCgaDriver.DrawText(x, y: integer; text: string);
begin
end;

procedure TCgaDriver.DrawTextLarge(x, y: integer; text: PChar);
begin
end;

procedure TCgaDriver.MoveTo(x, y: integer);
begin
end;

procedure TCgaDriver.LineTo(x, y: integer);
begin
end;

procedure TCgaDriver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure TCgaDriver.HLine(x, y, width: integer);
begin
end;

procedure TCgaDriver.VLine(x, y, height: integer);
begin
end;

procedure TCgaDriver.FillRect(rect: TRect);
begin
end;

procedure TCgaDriver.DrawImage(x, y, width, height: longint; image: PByte);
begin
end;

procedure TCgaDriver.DrawImageTransparent(x, y, width, height: longint; image: PByte);
begin
end;

procedure TCgaDriver.DrawImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TCgaDriver.DrawImageStreamTransparent(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TCgaDriver.DrawImageBuffer(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
begin
end;

procedure TCgaDriver.DrawImageBufferTransparent(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
begin
end;

procedure TCgaDriver.WaitForVSync;
begin
end;

procedure TCgaDriver.Init;
begin
end;

destructor TCgaDriver.Done;
begin
end;

end.