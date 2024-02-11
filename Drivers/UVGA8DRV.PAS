{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit UVga8Drv;

interface

uses
  Objects,
  GraphDrv,
  GrDrv8,
  Common,
  StrUtils,
  Streams,
  Strings,
  Drawing;

type
  PVgaUnchainedDriver = ^TVgaUnchainedDriver;
  TVgaUnchainedDriver = object(TGraphics8Driver)
  private
    procedure DrawTextAny(x, y: integer; text: string; largeText: PChar); virtual;
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
    procedure DrawImage(x, y, width, height: integer; image: PByte); virtual;
    procedure DrawImageTransparent(x, y, width, height: integer; image: PByte); virtual;
    procedure DrawImageStream(x, y, width, height: integer; stream: PStream); virtual;
    procedure DrawImageStreamTransparent(x, y, width, height: integer; stream: PStream); virtual;
    procedure DrawImageBuffer(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte); virtual;
    procedure DrawImageBufferTransparent(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    constructor Create;
    destructor Free; virtual;
  end;

implementation

function TVgaUnchainedDriver.GetPixel(x, y: integer): byte;
begin
end;

procedure TVgaUnchainedDriver.SetMode(newMode: PGraphicsMode);
begin
  asm
    mov   ah, 0
    mov   al, 13h
    int   10h
  end;
  SetStandardPalette;
  Mode^.Assign(newMode^);
  inherited SetMode(newMode);
end;

procedure TVgaUnchainedDriver.SetPixel(x, y: integer);
begin
end;

procedure TVgaUnchainedDriver.DrawTextAny(x, y: integer; text: string; largeText: PChar);
begin
end;

procedure TVgaUnchainedDriver.DrawText(x, y: integer; text: string);
begin
  DrawTextAny(x, y, text, nil);
end;

procedure TVgaUnchainedDriver.DrawTextLarge(x, y: integer; text: PChar);
begin
  DrawTextAny(x, y, '', text);
end;

procedure TVgaUnchainedDriver.MoveTo(x, y: integer);
begin
end;

procedure TVgaUnchainedDriver.LineTo(x, y: integer);
begin
end;

procedure TVgaUnchainedDriver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure TVgaUnchainedDriver.HLine(x, y, width: integer);
begin
end;

procedure TVgaUnchainedDriver.VLine(x, y, height: integer);
begin
end;

procedure TVgaUnchainedDriver.FillRect(rect: TRect);
begin
end;

procedure TVgaUnchainedDriver.DrawImage(x, y, width, height: integer; image: PByte);
begin
end;

procedure TVgaUnchainedDriver.DrawImageTransparent(x, y, width, height: integer; image: PByte);
begin
end;

procedure TVgaUnchainedDriver.DrawImageStream(x, y, width, height: integer; stream: PStream);
begin
end;

procedure TVgaUnchainedDriver.DrawImageStreamTransparent(x, y, width, height: integer; stream: PStream);
begin
end;

procedure TVgaUnchainedDriver.DrawImageBuffer(bufferPos: TPoint; imageSize, bufferSize: TSize; image, buffer: PByte);
begin
end;

procedure TVgaUnchainedDriver.DrawImageBufferTransparent(bufferPos: TPoint; imageSize, bufferSize: TSize;
  image, buffer: PByte);
begin
end;

procedure TVgaUnchainedDriver.GetImage(x, y, width, height: longint; buffer: PByte);
begin
end;

procedure TVgaUnchainedDriver.GetImageStream(x, y, width, height: longint; stream: PStream);
begin
end;

procedure TVgaUnchainedDriver.Init;
var
  newMode: PGraphicsMode;
  desc: string;
begin
  inherited Init;
  newMode := New(PGraphicsMode, Create);
  with newMode^ do begin
    Id := TString.New('VgaUnchained'
      + IntToStr(320)
      + 'x'
      + IntToStr(200)
      + 'x'
      + IntToStr(8));
    desc := 'VGA '
      + IntToStr(320)
      + 'x'
      + IntToStr(200)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 320;
    Height := 200;
    MaxX := 319;
    MaxY := 199;
    Bpp := 8;
    BytesPerScanLine := 320;
    HelpText := TString.New('Requires a VGA card.');
    FrameBuffer := Ptr($A000,$0000);
  end;
  Modes.Add(newMode);
end;

destructor TVgaUnchainedDriver.Free;
begin
  inherited Free;
end;

procedure TVgaUnchainedDriver.WaitForVSync;
begin
  while (Port[$3DA] and 8) = 8 do;
  while (Port[$3DA] and 8) <> 8 do;
end;

constructor TVgaUnchainedDriver.Create;
begin
  inherited Create;
end;

end.

end.