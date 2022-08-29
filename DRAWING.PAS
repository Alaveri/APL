unit Drawing;

interface

uses
  Objects,
  Common;

type
  TRect = object(TBaseObject)
  public
    X, Y, Width, Height: longint;
    constructor Create;
    constructor CreateDims(newX, newY, newWidth, newHeight: longint);
    constructor CreateCoords(newX, newY, newRight, newBottom: longint);
    constructor CreateRect(newRect: TRect);
    procedure SetDims(newX, newY, newWidth, newHeight: longint); virtual;
    procedure SetCoords(newX, newY, newRight, newBottom: longint); virtual;
    procedure SetRect(newRect: TRect); virtual;
    procedure SetRight(newRight: integer); virtual;
    procedure SetBottom(newBottom: integer); virtual;
    procedure Translate(dX, dY: longint); virtual;
    procedure Grow(dW, dH: integer); virtual;
    procedure Intersection(rect: TRect; var result: TRect); virtual;
    procedure Init; virtual;
    function IsEmpty: boolean; virtual;
    function Right: integer; virtual;
    function Bottom: integer; virtual;
    function IntersectPoint(pX, pY: longint): boolean; virtual;
    function IntersectRect(rect: TRect): boolean; virtual;
  end;
  TPoint = object(TBaseObject)
  public
    X, Y: longint;
    constructor Create;
    constructor CreateCoords(newX, newY: longint);
    constructor CreatePoint(point: TPoint);
    procedure SetCoords(newX, newY: longint); virtual;
    procedure SetPoint(point: TPoint); virtual;
    procedure Translate(dX, dY: longint); virtual;
    procedure Init; virtual;
    function Equals(xPos, yPos: longint): boolean; virtual;
    function EqualsPoint(point: TPoint): boolean; virtual;
    function IntersectRect(rect: TRect): boolean; virtual;
  end;
  TLocation = TPoint;
  TSize = object(TBaseObject)
  public
    Width, Height: longint;
    constructor Create;
    constructor CreateDims(newWidth, newHeight: longint);
    constructor CreateSize(size: TSize);
    procedure SetDims(newWidth, newHeight: longint); virtual;
    procedure SetSize(size: TSize); virtual;
    procedure Grow(dW, dH: longint); virtual;
    procedure Init; virtual;
  end;

implementation

constructor TRect.Create;
begin
  X := 0;
  Y := 0;
  Width := 0;
  Height := 0;
end;

constructor TRect.CreateRect(newRect: TRect);
begin
  Init;
  SetRect(newRect);
end;

constructor TRect.CreateDims(newX, newY, newWidth, newHeight: longint);
begin
  Init;
  SetDims(newX, newY, newWidth, newHeight);
end;

constructor TRect.CreateCoords(newX, newY, newRight, newBottom: longint);
begin
  Init;
  SetCoords(newX, newY, newRight, newBottom);
end;

procedure TRect.SetRight(newRight: integer);
begin
  Width := newRight - X + 1;
end;

procedure TRect.Init;
begin
  inherited Init;
  X := 0;
  Y := 0;
  Width := 0;
  Height := 0;
end;

procedure TRect.SetBottom(newBottom: integer);
begin
  Height := newBottom - Y + 1;
end;

procedure TRect.Translate(dX, dY: longint);
begin
  Inc(X, dX);
  Inc(Y, dY);
end;

procedure TRect.SetRect(newRect: TRect);
begin
  X := newRect.X;
  Y := newRect.Y;
  Width := newRect.Width;
  Height := newRect.Height
end;

procedure TRect.SetDims(newX, newY, newWidth, newHeight: longint);
begin
  X := newX;
  Y := newY;
  Width := newWidth;
  Height := newHeight;
end;

procedure TRect.SetCoords(newX, newY, newRight, newBottom: longint);
begin
  X := newX;
  Y := newY;
  Width := newRight - newX + 1;
  Height := newBottom - newY + 1;
end;

procedure TRect.Grow(dW, dH: integer);
begin
  Inc(Width, dW);
  Inc(Height, dH);
end;

function TRect.Right: integer;
begin
  Right := X + Width - 1;
end;

function TRect.Bottom: integer;
begin
  Bottom := Y + Height - 1;
end;

function TRect.IntersectPoint(pX, pY: longint): boolean;
begin
  IntersectPoint :=
    (pX >= X) and
    (pY >= Y) and
    (pX <= Right) and
    (pY <= Bottom);
end;

function TRect.IntersectRect(rect: TRect): boolean;
begin
  IntersectRect := not
    ((rect.Right < X) or
     (rect.X > Right) or
     (rect.Bottom < Y) or
     (rect.Y > Bottom));
end;

function TRect.IsEmpty: boolean;
begin
  IsEmpty := (X = 0) and (Y = 0) and (Width = 0) and (Height = 0);
end;

procedure TRect.Intersection(rect: TRect; var result: TRect);
begin
  result.Create;
  if (not IntersectRect(rect)) then exit;
  result.CreateCoords(MaxL(X, rect.X), MaxL(Y, rect.Y), MinL(Right, rect.Right), MinL(Bottom, rect.Bottom));
end;

constructor TPoint.Create;
begin
  Init;
end;

constructor TPoint.CreateCoords(newX, newY: longint);
begin
  Init;
  SetCoords(newX, newY);
end;

constructor TPoint.CreatePoint(point: TPoint);
begin
  Init;
  SetPoint(point);
end;

procedure TPoint.SetCoords(newX, newY: longint);
begin
  X := newX;
  Y := newY;
end;

procedure TPoint.SetPoint(point: TPoint);
begin
  X := point.X;
  Y := point.Y;
end;

procedure TPoint.Translate(dX, dY: longint);
begin
  Inc(X, dX);
  Inc(Y, dY);
end;

procedure TPoint.Init;
begin
  inherited Init;
  X := 0;
  Y := 0;
end;

function TPoint.Equals(xPos, yPos: longint): boolean;
begin
  Equals := (xPos = X) and (yPos = Y);
end;

function TPoint.EqualsPoint(point: TPoint): boolean;
begin
  EqualsPoint := (point.X = X) and (point.Y = Y);
end;

function TPoint.IntersectRect(rect: TRect): boolean;
begin
  IntersectRect :=
    (X >= rect.X) and
    (Y >= rect.Y) and
    (X <= rect.Right) and
    (Y <= rect.Bottom);
end;

constructor TSize.Create;
begin
  Init;
end;

constructor TSize.CreateDims(newWidth, newHeight: longint);
begin
  Init;
  SetDims(newWidth, newHeight);
end;

constructor TSize.CreateSize(size: TSize);
begin
  Init;
  SetSize(size);
end;

procedure TSize.Init;
begin
  inherited Init;
  Width := 0;
  Height := 0;
end;

procedure TSize.SetDims(newWidth, newHeight: longint);
begin
  Width := newWidth;
  Height := newHeight;
end;

procedure TSize.SetSize(size: TSize);
begin
  Width := size.Width;
  Height := size.Height;
end;

procedure TSize.Grow(dW, dH: longint);
begin
  Inc(width, dW);
  Inc(height, dH);
end;

end.