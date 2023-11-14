{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Drawing;

interface

uses
  Objects,
  Common;

type

  PPoint = ^TPoint;
  PRect = ^TRect;
  PSize = ^TSize;

  TPoint = object(TObject)
  public
    X, Y: longint;
    constructor Create;
    constructor CreateCoords(AX, AY: longint);
    constructor CreatePoint(APoint: TPoint);
    procedure SetCoords(AX, AY: longint);
    procedure SetPoint(APoint: TPoint);
    procedure Translate(ADX, ADY: longint);
    procedure Init; virtual;
    function EqualsCoords(AX, AY: longint): boolean;
    function Equals(APoint: TPoint): boolean;
  end;

  PLocation = ^TLocation;
  TLocation = TPoint;

  TRect = object(TObject)
  public
    X, Y, Width, Height: longint;
    constructor Create;
    constructor CreateDims(AX, AY, AWidth, AHeight: longint);
    constructor CreateCoords(AX, AY, ARight, ABottom: longint);
    constructor CreateRect(ARect: TRect);
    procedure SetDims(AX, AY, AWidth, AHeight: longint);
    procedure SetCoords(AX, AY, ARight, ABottom: longint);
    procedure SetRect(ARect: TRect);
    procedure SetRight(ARight: integer);
    procedure SetBottom(ABottom: integer);
    procedure Translate(ADX, ADY: longint);
    procedure Grow(ADW, ADH: integer);
    procedure Intersection(ARect: TRect; var AResult: TRect);
    procedure Init; virtual;
    function Equals(ARect: TRect): boolean;
    function EqualsCoords(AX, AY, AWidth, AHeight: longint): boolean;
    function IsEmpty: boolean;
    function Right: integer;
    function Bottom: integer;
    function IntersectCoords(AX, AY: longint): boolean;
    function IntersectPoint(APoint: TPoint): boolean;
    function IntersectRect(ARect: TRect): boolean;
  end;

  TSize = object(TObject)
  public
    Width, Height: longint;
    constructor Create;
    constructor CreateDims(AWidth, AHeight: longint);
    constructor CreateSize(ASize: TSize);
    procedure SetDims(AWidth, AHeight: longint);
    procedure SetSize(ASize: TSize);
    procedure Grow(ADW, ADH: longint);
    procedure Init; virtual;
  end;

implementation

constructor TRect.Create;
begin
  inherited Create;
  X := 0;
  Y := 0;
  Width := 0;
  Height := 0;
end;

constructor TRect.CreateRect(ARect: TRect);
begin
  inherited Create;
  SetRect(ARect);
end;

constructor TRect.CreateDims(AX, AY, AWidth, AHeight: longint);
begin
  inherited Create;
  SetDims(AX, AY, AWidth, AHeight);
end;

constructor TRect.CreateCoords(AX, AY, ARight, ABottom: longint);
begin
  inherited Create;
  SetCoords(AX, AY, ARight, ABottom);
end;

procedure TRect.SetRight(ARight: integer);
begin
  Width := ARight - X + 1;
end;

procedure TRect.Init;
begin
  inherited Init;
  X := 0;
  Y := 0;
  Width := 0;
  Height := 0;
end;

procedure TRect.SetBottom(ABottom: integer);
begin
  Height := ABottom - Y + 1;
end;

procedure TRect.Translate(ADX, ADY: longint);
begin
  Inc(X, ADX);
  Inc(Y, ADY);
end;

procedure TRect.SetRect(ARect: TRect);
begin
  X := ARect.X;
  Y := ARect.Y;
  Width := ARect.Width;
  Height := ARect.Height
end;

procedure TRect.SetDims(AX, AY, AWidth, AHeight: longint);
begin
  X := AX;
  Y := AY;
  Width := AWidth;
  Height := AHeight;
end;

procedure TRect.SetCoords(AX, AY, ARight, ABottom: longint);
begin
  X := AX;
  Y := AY;
  Width := ARight - AX + 1;
  Height := ABottom - AY + 1;
end;

procedure TRect.Grow(ADW, ADH: integer);
begin
  Inc(Width, ADW);
  Inc(Height, ADH);
end;

function TRect.Equals(ARect: TRect): boolean;
begin
  Equals := EqualsCoords(ARect.X, ARect.Y, ARect.Width, ARect.Height);
end;

function TRect.EqualsCoords(AX, AY, AWidth, AHeight: longint): boolean;
begin
  EqualsCoords :=
    (X = AX)
    and (Y = AY)
    and (Width = AWidth)
    and (Height = AHeight);
end;

function TRect.Right: integer;
begin
  Right := X + Width - 1;
end;

function TRect.Bottom: integer;
begin
  Bottom := Y + Height - 1;
end;

function TRect.IntersectCoords(AX, AY: longint): boolean;
begin
  IntersectCoords :=
    (AX >= X) and
    (AY >= Y) and
    (AX <= Right) and
    (AY <= Bottom);
end;

function TRect.IntersectPoint(APoint: TPoint): boolean;
begin
  IntersectPoint := IntersectCoords(APoint.X, APoint.Y);
end;

function TRect.IntersectRect(ARect: TRect): boolean;
begin
  IntersectRect := not
    ((ARect.Right < X) or
     (ARect.X > Right) or
     (ARect.Bottom < Y) or
     (ARect.Y > Bottom));
end;

function TRect.IsEmpty: boolean;
begin
  IsEmpty := (X = 0) and (Y = 0) and (Width = 0) and (Height = 0);
end;

procedure TRect.Intersection(ARect: TRect; var AResult: TRect);
begin
  AResult.Create;
  if not IntersectRect(ARect) then
    exit;
  AResult.SetCoords(MaxL(X, ARect.X), MaxL(Y, ARect.Y), MinL(Right, ARect.Right), MinL(Bottom, ARect.Bottom));
end;

constructor TPoint.Create;
begin
  Init;
end;

constructor TPoint.CreateCoords(AX, AY: longint);
begin
  Init;
  SetCoords(AX, AY);
end;

constructor TPoint.CreatePoint(APoint: TPoint);
begin
  Init;
  SetPoint(APoint);
end;

procedure TPoint.SetCoords(AX, AY: longint);
begin
  X := AX;
  Y := AY;
end;

procedure TPoint.SetPoint(APoint: TPoint);
begin
  X := APoint.X;
  Y := APoint.Y;
end;

procedure TPoint.Translate(ADX, ADY: longint);
begin
  Inc(X, ADX);
  Inc(Y, ADY);
end;

procedure TPoint.Init;
begin
  inherited Init;
  X := 0;
  Y := 0;
end;

function TPoint.EqualsCoords(AX, AY: longint): boolean;
begin
  EqualsCoords := (AX = X) and (AY = Y);
end;

function TPoint.Equals(APoint: TPoint): boolean;
begin
  Equals := (APoint.X = X) and (APoint.Y = Y);
end;

constructor TSize.Create;
begin
  Init;
end;

constructor TSize.CreateDims(AWidth, AHeight: longint);
begin
  Init;
  SetDims(AWidth, AHeight);
end;

constructor TSize.CreateSize(ASize: TSize);
begin
  Init;
  SetSize(ASize);
end;

procedure TSize.Init;
begin
  inherited Init;
  Width := 0;
  Height := 0;
end;

procedure TSize.SetDims(AWidth, AHeight: longint);
begin
  Width := AWidth;
  Height := AHeight;
end;

procedure TSize.SetSize(ASize: TSize);
begin
  Width := ASize.Width;
  Height := ASize.Height;
end;

procedure TSize.Grow(ADW, ADH: longint);
begin
  Inc(width, ADW);
  Inc(height, ADH);
end;

end.