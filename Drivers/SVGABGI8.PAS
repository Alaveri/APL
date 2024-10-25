{$I COMPILER.INC}
unit SVgaBgi8;

interface

uses
  GraphDrv,
  GrDrv8,
  Common,
  AplTypes,
  Math,
  BgiInter,
  Streams,
  Palettes,
  Drawing;

type
  PSVgaBgiDriver = ^TSVgaBgiDriver;

  TSVgaBgiDriver = object(TGraphics8Driver)
  private
    FBgiInterface: TBgiInterface;
    function InitializeDrawRect(APX, APY, AWidth, AHeight: integer; var ADrawRect: TRect): boolean;
    procedure Render4BppText(APX, APY, ALength: integer; AText: PChar);
  public
    function GetScreenPointer(APX, APY: integer; var AOffset: longint): PByte; virtual;
    procedure GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure RenderText(APX, APY, ALength: integer; AText: PChar); virtual;
    procedure Line(AX1, AY1, AX2, AY2: integer); virtual;
    procedure HLine(APX, APY, AWidth: integer); virtual;
    procedure VLine(APX, APY, AHeight: integer); virtual;
    procedure Circle(ACenterX, ACenterY, ARadius: integer); virtual;
    procedure DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure FastFillScreen(AColor: byte); virtual;
    procedure FastDrawScreen(AImage: PByte); virtual;
    procedure FastDrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure FastSetPixel(APX, APY: integer); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure SetRgbPaletteData(APalette: PRgbPaletteData); virtual;
    procedure WaitForVSync; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

implementation

uses
  MouseDrv,
  Errors,
  StrUtils;

procedure TSVgaBgiDriver.Init;
var
  newMode: PGraphicsMode;
  desc: string;
begin
  inherited Init;
  FBgiInterface.Create('SVGA256');
  newMode := New(PGraphicsMode, Create);
  with newMode^ do begin
    ModeId := 0;
    desc := 'SVGA '
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
    HelpText := TString.New('Requires an SVGA card supporting VBE.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  Modes.Add(newMode);
  newMode := New(PGraphicsMode, Create);
  with newMode^ do begin
    ModeId := 1;
    desc := 'SVGA '
      + IntToStr(640)
      + 'x'
      + IntToStr(400)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 640;
    Height := 400;
    MaxX := 639;
    MaxY := 399;
    Bpp := 8;
    BytesPerScanLine := 640;
    HelpText := TString.New('Requires an SVGA card supporting VBE.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  newMode := New(PGraphicsMode, Create);
  Modes.Add(newMode);
  with newMode^ do begin
    ModeId := 2;
    desc := 'SVGA '
      + IntToStr(640)
      + 'x'
      + IntToStr(480)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 640;
    Height := 480;
    MaxX := 639;
    MaxY := 479;
    Bpp := 8;
    BytesPerScanLine := 640;
    HelpText := TString.New('Requires an SVGA card supporting VBE.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  newMode := New(PGraphicsMode, Create);
  Modes.Add(newMode);
  with newMode^ do begin
    ModeId := 3;
    desc := 'SVGA '
      + IntToStr(800)
      + 'x'
      + IntToStr(600)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 800;
    Height := 600;
    MaxX := 799;
    MaxY := 599;
    Bpp := 8;
    BytesPerScanLine := 800;
    HelpText := TString.New('Requires an SVGA card supporting VBE.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  newMode := New(PGraphicsMode, Create);
  Modes.Add(newMode);
  with newMode^ do begin
    ModeId := 4;
    desc := 'SVGA '
      + IntToStr(1024)
      + 'x'
      + IntToStr(768)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 1024;
    Height := 768;
    MaxX := 1023;
    MaxY := 767;
    Bpp := 8;
    BytesPerScanLine := 1024;
    HelpText := TString.New('Requires an SVGA card supporting VBE.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  newMode := New(PGraphicsMode, Create);
  Modes.Add(newMode);
  with newMode^ do begin
    ModeId := 5;
    desc := 'SVGA '
      + IntToStr(640)
      + 'x'
      + IntToStr(350)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 640;
    Height := 350;
    MaxX := 639;
    MaxY := 349;
    Bpp := 8;
    BytesPerScanLine := 640;
    HelpText := TString.New('Requires an SVGA card supporting VBE.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  newMode := New(PGraphicsMode, Create);
  Modes.Add(newMode);
  with newMode^ do begin
    ModeId := 6;
    desc := 'SVGA '
      + IntToStr(1280)
      + 'x'
      + IntToStr(1024)
      + ' 256 Color';
    Description := TString.New(desc);
    Width := 1280;
    Height := 1024;
    MaxX := 1279;
    MaxY := 1023;
    Bpp := 8;
    BytesPerScanLine := 1280;
    HelpText := TString.New('Requires an SVGA card supporting VBE.');
    FrameBuffer := Ptr($A000, $0000);
  end;
  Modes.Add(newMode);
end;

procedure TSVgaBgiDriver.SetMode(AMode: PGraphicsMode);
begin
   inherited SetMode(AMode);
   FBgiInterface.SetMode(AMode^.ModeId);
end;

function TSVgaBgiDriver.GetScreenPointer(APX, APY: integer; var AOffset: longint): PByte;
{var
  result: PByte;}
begin
  {AOffset := longint(APY) * Mode^.BytesPerScanLine + APX;
  result := Mode^.FrameBuffer;
  Inc(result, AOffset);
  GetScreenPointer := result;}
end;

procedure TSVgaBgiDriver.WaitForVSync;
begin
  asm
    mov dx, 3DAh
    @loop:
    in al, dx
    test al, 8h
    jz @loop
  end;
end;

procedure TSVgaBgiDriver.FillRect(ARect: TRect);
begin
  FBgiInterface.FillRect(ARect);
end;

procedure TSVgaBgiDriver.FastFillScreen(AColor: byte);
begin
end;

procedure TSVgaBgiDriver.FastDrawScreen(AImage: PByte);
begin
end;

procedure TSVgaBgiDriver.FastDrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TSVgaBgiDriver.FastSetPixel(APX, APY: integer);
begin
end;

function TSVgaBgiDriver.InitializeDrawRect(APX, APY, AWidth, AHeight: integer; var ADrawRect: TRect): boolean;
begin
end;

procedure TSVgaBgiDriver.Render4BppText(APX, APY, ALength: integer; AText: PChar);
begin
end;

procedure TSVgaBgiDriver.RenderText(APX, APY, ALength: integer; AText: PChar);
var
  drawRect: TRect;
  charIndex, yIndex, xIndex: integer;
  ch: char;
  sx, sy, minX, maxX: integer;
  width: integer;
  linePtr: PWord;
  height: word;
  screen: PByte;
  fore: byte;
  offset: longint;
  currentLine: word;
  px: integer;
  format: TFontFormats;
begin
  if HasException then
    exit;
  Mode^.Bounds.GetIntersection(State^.ViewPort, drawRect);
  if APX > drawRect.Right then
    exit;
  if APY > drawRect.Bottom then
    exit;
  height := State^.Font^.Height;
  if APY + height < drawRect.Y then
    exit;
  GetFontFormats(State^.Font, format);
  if ff4Bpp in format then begin
    Render4BppText(APX, APY, ALength, AText);
    exit;
  end;
  sx := APX;
  for charIndex := 0 to ALength - 1 do begin
    ch := AText[charIndex];
    width := State^.Font^.TextWidth(ch);
    if sx > drawRect.Right then
      exit;
    if sx + width < drawRect.X then begin
      Inc(sx, width);
      continue;
    end;
    sy := APY;
    fore := State^.ForeColor;
    linePtr := State^.Font^.FontData;
    Inc(linePtr, Ord(ch) * height);
    minX := MaxL(0, drawRect.X - sx);
    maxX := MinL(State^.Font^.TextWidth(ch) - 1, drawRect.Right - sx);
    sy := APY;
    for yIndex := 0 to height - 1 do begin
      currentLine := linePtr^;
      if sy < drawRect.Y then begin
        Inc(linePtr);
        Inc(sy);
        continue;
      end;
      if sy > drawRect.Bottom then
        break;
      px := APX;
      for xIndex := minX to maxX do begin
        if (currentLine and ($8000 shr xIndex)) > 0 then
          FBgiInterface.PutPixel(px, sy, fore);
        Inc(px);
      end;
      Inc(linePtr);
      Inc(sy);
    end;
    Inc(sx, width);
  end;
end;

procedure TSVgaBgiDriver.Line(AX1, AY1, AX2, AY2: integer);
begin
end;

procedure TSVgaBgiDriver.HLine(APX, APY, AWidth: integer);
begin
end;

procedure TSVgaBgiDriver.VLine(APX, APY, AHeight: integer);
begin
end;

procedure TSVgaBgiDriver.Circle(ACenterX, ACenterY, ARadius: integer);
begin
end;

procedure TSVgaBgiDriver.DrawImage(APX, APY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TSVgaBgiDriver.DrawImageT(APX, APY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TSVgaBgiDriver.DrawImageStream(APX, APY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TSVgaBgiDriver.DrawImageStreamT(APX, APY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TSVgaBgiDriver.GetImage(APX, APY, AWidth, AHeight: longint; ABuffer: PByte);
begin
end;

procedure TSVgaBgiDriver.GetImageStream(APX, APY, AWidth, AHeight: longint; AStream: PStream);
begin
end;

procedure TSVgaBgiDriver.SetRgbPaletteData(APalette: PRgbPaletteData);
begin
  inherited SetRgbPaletteData(APalette);
{  FBgiInterface.SetPalette(APalette);}
end;

destructor TSVgaBgiDriver.Free;
begin
  FBgiInterface.Free;
  inherited Free;
end;

end.