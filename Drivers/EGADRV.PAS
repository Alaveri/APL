{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit EgaDrv;

interface

uses
  Objects,
  GraphDrv,
  Common,
  StrUtils,
  Strings,
  Streams,
  Drawing;

type
  PEgaDriver = ^TEgaDriver;
  TEgaDriver = object(TGraphicsDriver)
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

uses
  Dos;

procedure TEgaDriver.Init;
begin
  inherited Init;
end;

function TEgaDriver.GetPixel(AX, AY: integer): byte;
begin
end;

procedure TEgaDriver.SetMode(AMode: PGraphicsMode);
begin
end;

procedure TEgaDriver.SetPixel(AX, AY: integer);
begin
end;

procedure TEgaDriver.DrawText(AX, AY: integer; AText: string);
begin
end;

procedure TEgaDriver.DrawTextLarge(AX, AY: integer; AText: PChar);
begin
end;

procedure TEgaDriver.MoveTo(AX, AY: integer);
begin
end;

procedure TEgaDriver.LineTo(AX, AY: integer);
begin
end;

procedure TEgaDriver.Line(AX1, AY1, AX2, AY2: integer);
begin
end;

procedure TEgaDriver.HLine(AX, AY, AWidth: integer);
begin
end;

procedure TEgaDriver.VLine(AX, AY, AHeight: integer);
begin
end;

procedure TEgaDriver.FillRect(ARect: TRect);
begin
end;

procedure TEgaDriver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TEgaDriver.DrawImageTransparent(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TEgaDriver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TEgaDriver.DrawImageStreamTransparent(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TEgaDriver.DrawImageBuffer(ABufferPos: TPoint; AImageSize, ABufferSize: TSize; AImage, ABuffer: PByte);
begin
end;

procedure TEgaDriver.DrawImageBufferTransparent(ABufferPos: TPoint; AImageSize, ABufferSize: TSize; AImage, ABuffer: PByte);
begin
end;

procedure TEgaDriver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
begin
end;

procedure TEgaDriver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
begin
end;

procedure TEgaDriver.WaitForVSync;
begin
end;

destructor TEgaDriver.Free;
begin
  inherited Free;
end;

begin
end.