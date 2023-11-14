{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit CgaDrv;

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
  PCgaDriver = ^TCgaDriver;
  TCgaDriver = object(TGraphicsDriver)
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

procedure TCgaDriver.Init;
begin
  inherited Init;
end;

function TCgaDriver.GetPixel(AX, AY: integer): byte;
begin
end;

procedure TCgaDriver.SetMode(AMode: PGraphicsMode);
begin
end;

procedure TCgaDriver.SetPixel(AX, AY: integer);
begin
end;

procedure TCgaDriver.DrawText(AX, AY: integer; AText: string);
begin
end;

procedure TCgaDriver.DrawTextLarge(AX, AY: integer; AText: PChar);
begin
end;

procedure TCgaDriver.MoveTo(AX, AY: integer);
begin
end;

procedure TCgaDriver.LineTo(AX, AY: integer);
begin
end;

procedure TCgaDriver.Line(AX1, AY1, AX2, AY2: integer);
begin
end;

procedure TCgaDriver.HLine(AX, AY, AWidth: integer);
begin
end;

procedure TCgaDriver.VLine(AX, AY, AHeight: integer);
begin
end;

procedure TCgaDriver.FillRect(ARect: TRect);
begin
end;

procedure TCgaDriver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TCgaDriver.DrawImageTransparent(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TCgaDriver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TCgaDriver.DrawImageStreamTransparent(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TCgaDriver.DrawImageBuffer(ABufferPos: TPoint; AImageSize, ABufferSize: TSize; AImage, ABuffer: PByte);
begin
end;

procedure TCgaDriver.DrawImageBufferTransparent(ABufferPos: TPoint; AImageSize, ABufferSize: TSize; AImage, ABuffer: PByte);
begin
end;

procedure TCgaDriver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
begin
end;

procedure TCgaDriver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
begin
end;

procedure TCgaDriver.WaitForVSync;
begin
end;

destructor TCgaDriver.Free;
begin
  inherited Free;
end;

begin
end.