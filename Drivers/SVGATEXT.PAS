{$I COMPILER.INC}
unit SvgaText;

interface

uses
  Crt,
  Objects,
  GraphDrv,
  SVgaDrv,
  GraphIni,
  TextDrv,
  WideStr,
  Drawing,
  Utils,
  MouseDrv,
  Collects;

type
  TMouseCursorImage = array[0..12, 0..9] of byte;
  PMouseCursor = ^TMouseCursor;
  TMouseCursor = object(TBaseObject)
  private
    _image: TMouseCursorImage;
    _width, _height: word;
    _visible: boolean;
    _x, _y: integer;
  public
    BackData: PByte;
    procedure Draw; virtual;
    procedure Init; virtual;
    destructor Done; virtual;
    function Width: integer; virtual;
    function Height: integer; virtual;
    procedure StoreBackground(X, Y: integer); virtual;
  end;
  PSvgaTextState = object(TTextState)
  private
  public
    GraphX, GraphY: integer;
  end;
  PSvgaTextDriver = ^TSvgaTextDriver;
  TSvgaTextDriver = Object(TTextDriver)
  private
    _mouseCursor: PMouseCursor;
    function GetStandardColor(color: byte): byte;
  public
    procedure Write(const txt: string); virtual;
    procedure WriteWide(txt: TWideString); virtual;
    procedure SetXY(newX, newY: byte); virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure Init; virtual;
    procedure SetMode(newMode: PTextMode); virtual;
    procedure HLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure VLine(x1, y1, height: byte; lineStyle: TLineStyle); virtual;
    procedure Box(rect: TRect; style: TLineStyle); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure ShowMouseCursor; virtual;
    procedure HideMouseCursor; virtual;
    procedure EraseMouseCursor(mouseState: TMouseState); virtual;
    procedure DrawMouseCursor(mouseState: TMouseState); virtual;
    procedure ClrScr; virtual;
    destructor Done; virtual;
  end;

implementation

const
  DefaultMouseCursor: TMouseCursorImage =
  (
    ($27, $01, $01, $01, $01, $01, $01, $01, $01, $01),
    ($27, $27, $01, $01, $01, $01, $01, $01, $01, $01),
    ($27, $00, $27, $01, $01, $01, $01, $01, $01, $01),
    ($27, $00, $00, $27, $01, $01, $01, $01, $01, $01),
    ($27, $00, $00, $00, $27, $01, $01, $01, $01, $01),
    ($27, $00, $00, $00, $00, $27, $01, $01, $01, $01),
    ($27, $00, $00, $00, $00, $00, $27, $01, $01, $01),
    ($27, $00, $00, $00, $00, $00, $00, $27, $01, $01),
    ($27, $00, $00, $00, $00, $00, $00, $00, $27, $01),
    ($27, $00, $00, $27, $27, $27, $27, $27, $27, $27),
    ($27, $00, $27, $01, $01, $01, $01, $01, $01, $01),
    ($27, $27, $01, $01, $01, $01, $01, $01, $01, $01),
    ($27, $01, $01, $01, $01, $01, $01, $01, $01, $01)
  );


procedure TSvgaTextDriver.SetMode(newMode: PTextMode);
var
  graphMode: PGraphicsMode;
  modeIndex: integer;
begin
  graphMode := Graphics^.Modes^.GetItem(newMode^.AdditionalData);
  if (graphMode = nil) then
  begin
    CreateError(Graphics^.Error, ecGraphicsModeNotFound, esError);
    exit;
  end;
  Graphics^.SetMode(graphMode);
  Mode := newMode;
  MouseDriver^.SetMouseResolution(graphMode^.Width, graphMode^.Height);
  if (_mouseCursor <> nil) then Dispose(_mouseCursor, Done);
  _mouseCursor := New(PMouseCursor, Create);
end;

procedure TSvgaTextDriver.SetXY(newX, newY: byte);
begin
  TTextDriver.SetXY(newX, newY);
end;

procedure TSvgaTextDriver.Write(const txt: string);
var
  index: integer;
  ch: char;
begin
  Graphics^.SetForecolor(ForeColor);
  Graphics^.SetBackColor(BackColor);
  for index := 1 to Length(txt) do begin
    ch := txt[index];
    Graphics^.DrawText(State^.X * 8, State^.Y * 16, ch);
    State^.X := State^.X + 1;
    if (State^.X > Mode^.MaxX) then begin
      State^.X := 0;
      State^.Y := State^.Y + 1;
      if (State^.Y > Mode^.MaxY) then break;
    end;
  end;
  SetXY(state^.X, state^.Y);
end;

procedure TSvgaTextDriver.WriteWide(txt: TWideString);
begin
end;

procedure TSvgaTextDriver.CursorOn;
begin
end;

procedure TSvgaTextDriver.CursorOff;
begin
end;

procedure TSvgaTextDriver.EraseMouseCursor(mouseState: TMouseState);
begin
  if (_mouseCursor^.BackData <> nil) and (_mouseCursor^._Visible) and (mouseState.Visible) then
    Graphics^.DrawImage(_mouseCursor^._X, _mouseCursor^._Y, _mouseCursor^.Width, _mouseCursor^.Height, _mouseCursor^.BackData);
end;

procedure TSvgaTextDriver.DrawMouseCursor(mouseState: TMouseState);
begin
  if (not _mouseCursor^._Visible) or (not mouseState.Visible) then exit;
  _mouseCursor^.StoreBackground(mouseState.X, mouseState.Y);
  _mouseCursor^._X := mouseState.X;
  _mouseCursor^._Y := mouseState.Y;
  _mouseCursor^.Draw;
end;

procedure TSvgaTextDriver.ShowMouseCursor;
var
  mouseState: TMouseState;
begin
  _mouseCursor^._Visible := true;
  MouseDriver^.State^.Visible := true;
  MouseDriver^.GetMouseState(mouseState);
  DrawMouseCursor(mouseState);
  MouseDriver^.ShowMouse;
end;

procedure TSvgaTextDriver.HideMouseCursor;
var
  mouseState: TMouseState;
begin
  EraseMouseCursor(MouseDriver^.State^);
  _mouseCursor^._visible := false;
  MouseDriver^.State^.Visible := false;
  MouseDriver^.HideMouse;
end;


function Is16Color(item: pointer; var value): boolean; far;
begin
  Is16Color := PGraphicsMode(item)^.Bpp = 4;
end;

procedure TSvgaTextDriver.Init;
var
  factory: TGraphicsFactory;
  modeIndex: integer;
  graphicsMode: PGraphicsMode;
  textMode: PTextMode;
  value: integer;
  count: integer;
begin
  TTextDriver.Init;
  TypeName := 'TSvgaTextDriver';
  factory.CreateGraphicsDriver(gdSVga256, Graphics);
  for modeIndex := 0 to Graphics^.Modes^.Count - 1 do begin
    graphicsMode := Graphics^.Modes^.GetItem(modeIndex);
    textMode := New(PTextMode, Create);
    with textMode^ do begin
      Width := graphicsMode^.Width div 8;
      Height := graphicsMode^.Height div 16;
      MaxX := Width - 1;
      MaxY := Height - 1;
      Name := 'SVga Text ' + IntToStr(Width) + 'x' + IntToStr(Height);
      Id := 'SVgaText' + IntToStr(Width) + 'x' + IntToStr(Height) + 'x' + IntToStr(GraphicsMode^.Bpp);
      AdditionalData := modeIndex;
      Description := 'SVGA Text ' + IntToStr(Width) + 'x' + IntToStr(Height) +
        ' (SVGA ' + IntToStr(graphicsMode^.Width) + 'x' + IntToStr(graphicsMode^.Height) + ')';
      HelpText := 'Requires VESA compatible Super VGA card.';
    end;
    Modes^.Add(textMode);
  end;
  _mouseCursor := nil;
end;

function TSVgaTextDriver.GetStandardColor(color: byte): byte;
var
  result: byte;
begin
  case color of
    Black: result := 0;
    Blue: result := Graphics^.GetColor(scBlue, Intensity50);
    Green: result := Graphics^.GetColor(scGreen, Intensity50);
    Cyan: result := Graphics^.GetColor(scCyan, Intensity50);
    Red: result := Graphics^.GetColor(scRed, Intensity50);
    Magenta: result := Graphics^.GetColor(scMagenta, Intensity50);
    Brown: result := Graphics^.GetColor(scYellow, Intensity50);
    LightGray: result := Graphics^.GetColor(scWhite, Intensity75);
    DarkGray: result := Graphics^.GetColor(scWhite, Intensity50);
    LightBlue: result := Graphics^.GetColor(scBlue, MaxIntensity);
    LightGreen: result := Graphics^.GetColor(scGreen, MaxIntensity);
    LightCyan: result := Graphics^.GetColor(scCyan, MaxIntensity);
    LightRed: result := Graphics^.GetColor(scRed, MaxIntensity);
    LightMagenta: result := Graphics^.GetColor(scMagenta, MaxIntensity);
    Yellow: result := Graphics^.GetColor(scYellow, MaxIntensity);
    White: result := Graphics^.GetColor(scWhite, MaxIntensity);
  end;
  GetStandardColor := result;
end;

procedure TSvgaTextDriver.SetForeColor(color: byte);
begin
  if (BppMode = 4) then begin
    TTextDriver.SetForeColor(GetStandardColor(color));
  end
  else begin
    TTextDriver.SetForeColor(color);
  end;
  Graphics^.SetForeColor(ForeColor);
end;

procedure TSvgaTextDriver.SetBackColor(color: byte);
begin
  if (BppMode = 4) then begin
    TTextDriver.SetBackColor(GetStandardColor(color));
  end
  else begin
    TTextDriver.SetBackColor(color);
  end;
  Graphics^.SetBackColor(BackColor);
end;

destructor TSvgaTextDriver.Done;
begin
  TTextDriver.Done;
  if (_mouseCursor <> nil) then begin
    Dispose(_mouseCursor, Done);
  end;
  Graphics^.Done;
end;

procedure TSvgaTextDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
var
  ch: char;
  index: integer;
  cursorState: boolean;
begin
  PushState;
  MouseDriver^.PushState;
  MouseDriver^.HideMouse;
  CursorOff;
  ch := #196;
  if (lineStyle = lsDouble) then ch := #205;
  SetXY(x1, y1);
  for index := 0 to width - 1 do begin
    Write(ch);
  end;
  PopState;
  MouseDriver^.PopState;
end;

procedure TSvgaTextDriver.VLine(x1, y1, height: byte; lineStyle: TLineStyle);
var
  ch: char;
  index: integer;
  cursorState: boolean;
begin
  MouseDriver^.PushState;
  PushState;
  CursorOff;
  ch := #179;
  if (lineStyle = lsDouble) then ch := #186;
  for index := y1 to y1 + height - 1 do begin
    SetXY(x1, index);
    Write(ch);
  end;
  PopState;
  MouseDriver^.PopState;
end;

procedure TSvgaTextDriver.Box(rect: TRect; style: TLineStyle);
var
  ch: char;
  offset: PByte;
begin
  MouseDriver^.PushState;
  PushState;
  ch := #218;
  if (style = lsDouble) then ch := #201;
  SetXY(rect.X, rect.Y);
  Write(ch);

  ch := #191;
  if (style = lsDouble) then ch:= #187;
  SetXY(rect.X + rect.width - 1, rect.Y);
  Write(ch);

  ch := #192;
  if (style = lsDouble) then ch := #200;
  SetXY(rect.X, rect.Y + rect.Height - 1);
  Write(ch);

  ch := #217;
  if (style = lsDouble) then ch := #188;
  SetXY(rect.X + rect.Width - 1, rect.Y + rect.Height - 1);
  Write(ch);

  HLine(rect.X + 1, rect.Y, rect.Width - 2, style);
  HLine(rect.X + 1, rect.Y + rect.Height - 1, rect.Width - 2, style);
  VLine(rect.X, rect.Y + 1, rect.Height - 2, style);
  VLine(rect.X + rect.Width - 1, rect.Y + 1, rect.Height - 2, style);
  MouseDriver^.PopState;
  PopState;
end;

procedure TSvgaTextDriver.ClrScr;
var
  rect: TRect;
begin
  rect.Create(0, 0, Graphics^.Mode^.Width, Graphics^.Mode^.Height);
  Graphics^.FillRect(rect);
end;

procedure TSvgaTextDriver.FillRect(rect: TRect);
var
  graphRect: TRect;
  width, height: integer;
begin
  Graphics^.PushState;
  Graphics^.SetForeColor(BackColor);
  width := Graphics^.Font^.TextWidth('W');
  height := Graphics^.Font^.Height;
  graphRect.Create(
    rect.X * width,
    rect.Y * height,
    rect.Width * width,
    rect.Height * height
  );
  Graphics^.FillRect(graphRect);
  Graphics^.PopState;
end;

procedure TMouseCursor.Init;
begin
  TBaseObject.Init;
  _width := 10;
  _height := 13;
  _visible := true;
  _y := 0;
  _x := 0;
  BackData := nil;
  _image := DefaultMouseCursor;
end;

procedure TMouseCursor.Draw;
var
  xIndex, yIndex: integer;
  pixel: PByte;
  rect, mouseRect, clipRect: TRect;
  xPos, yPos, startX, startY: integer;
begin
  if not _visible then exit;
  Graphics^.DrawImage(_x, _y, _width, _height, @_image);
end;

procedure TMouseCursor.StoreBackground(x, y: integer);
var
  rect: TRect;
begin
  if (BackData = nil) then GetMem(BackData, Width * Height);
  rect.Create(x, y, Width, Height);
  Graphics^.GetImage(BackData, rect);
end;

function TMouseCursor.Width: integer;
begin
  Width := _width;
end;

function TMouseCursor.Height: integer;
begin
  Height := _height;
end;

destructor TMouseCursor.Done;
begin
  if (BackData <> nil) then
    FreeMem(BackData, _width * _height);
  TBaseObject.Done;
end;


end.