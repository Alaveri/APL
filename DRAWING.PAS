{$I COMPILER.INC}
unit Drawing;

interface

uses
  Objects,
  Lists,
  Common;

type

  PPoint = ^TPoint;
  PRect = ^TRect;
  PSize = ^TSize;
  PShape = ^TShape;
  PShapeList = ^TShapeList;
  PPointList = ^TPointList;
  PRegion = ^TRegion;

  TShape = object(TObject)
  private
  public
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    function GetNewObject: PObject; virtual;
    function GetInversionPoints(AY, AStartX, AEndX: integer): PPointList; virtual;
  end;

  TRegion = object(TObjectList)
  private
  public
    Shapes: PShapeList;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    function GetInversionPoints(AY, AStartX, AEndX: integer): PPointList; virtual;
  end;

  TPointList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PPoint): integer;
    function Add(AItem: PPoint): integer;
    function GetItem(AIndex: integer): PPoint;
    function SetItem(AIndex: integer; AItem: PPoint): boolean;
    procedure Insert(AIndex: integer; AItem: PPoint);
  end;

  TShapeList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PShape): integer;
    function Add(AItem: PShape): integer;
    function GetItem(AIndex: integer): PShape;
    function SetItem(AIndex: integer; AItem: PShape): boolean;
    procedure Insert(AIndex: integer; AItem: PShape);
  end;

  TPoint = object(TShape)
  public
    X, Y: integer;
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

  TRect = object(TShape)
  public
    X, Y: integer;
    Width, Height: integer;
    constructor CreateDims(AX, AY, AWidth, AHeight: integer);
    constructor CreateCoords(AX, AY, ARight, ABottom: integer);
    constructor CreateRect(ARect: TRect);
    procedure SetDims(AX, AY, AWidth, AHeight: integer);
    procedure SetCoords(AX, AY, ARight, ABottom: integer);
    procedure SetRect(ARect: TRect);
    procedure Assign(var ASource: TObject); virtual;
    procedure SetRight(ARight: integer);
    procedure SetBottom(ABottom: integer);
    procedure Translate(ADX, ADY: integer);
    procedure Grow(ADW, ADH: integer);
    procedure Intersect(var ARect: TRect);
    procedure GetIntersection(ARect: TRect; var AResult: TRect);
    procedure Init; virtual;
    function GetNewObject: PObject; virtual;
    function Equals(ARect: TRect): boolean;
    function EqualsCoords(AX, AY, AWidth, AHeight: integer): boolean;
    function IsEmpty: boolean;
    function Right: integer;
    function Bottom: integer;
    function IntersectsCoords(AX, AY: integer): boolean;
    function IntersectsPoint(APoint: TPoint): boolean;
    function IntersectsRect(ARect: TRect): boolean;
    function GetInversionPoints(AY, AStartX, AEndX: integer): PPointList; virtual;
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

function PointXAscendingCompare(AItem1, AItem2: pointer): integer;
var
  result: integer;
begin
  result := 0;
  if (PPoint(AItem1)^.X < PPoint(AItem2)^.X) then
    result := -1
  else if (PPoint(AItem1)^.X < PPoint(AItem2)^.X) then
    result := 1;
end;

constructor TRect.CreateRect(ARect: TRect);
begin
  inherited Create;
  SetRect(ARect);
end;

constructor TRect.CreateDims(AX, AY, AWidth, AHeight: integer);
begin
  inherited Create;
  SetDims(AX, AY, AWidth, AHeight);
end;

constructor TRect.CreateCoords(AX, AY, ARight, ABottom: integer);
begin
  inherited Create;
  SetCoords(AX, AY, ARight, ABottom);
end;

function TRect.GetNewObject: PObject;
begin
  GetNewObject := New(PRect, Create);
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

procedure TRect.Translate(ADX, ADY: integer);
begin
  Inc(X, ADX);
  Inc(Y, ADY);
end;

procedure TRect.Assign(var ASource: TObject);
var
  source: PRect;
begin
  inherited Assign(ASource);
  source := PRect(@ASource);
  SetRect(source^);
end;

procedure TRect.SetRect(ARect: TRect);
begin
  X := ARect.X;
  Y := ARect.Y;
  Width := ARect.Width;
  Height := ARect.Height
end;

procedure TRect.SetDims(AX, AY, AWidth, AHeight: integer);
begin
  X := AX;
  Y := AY;
  Width := AWidth;
  Height := AHeight;
end;

procedure TRect.SetCoords(AX, AY, ARight, ABottom: integer);
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

function TRect.EqualsCoords(AX, AY, AWidth, AHeight: integer): boolean;
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

function TRect.IntersectsCoords(AX, AY: integer): boolean;
begin
  IntersectsCoords :=
    (AX >= X) and
    (AY >= Y) and
    (AX <= Right) and
    (AY <= Bottom);
end;

function TRect.IntersectsPoint(APoint: TPoint): boolean;
begin
  IntersectsPoint := IntersectsCoords(APoint.X, APoint.Y);
end;

function TRect.IntersectsRect(ARect: TRect): boolean;
begin
  IntersectsRect := not
    ((ARect.Right < X) or
     (ARect.X > Right) or
     (ARect.Bottom < Y) or
     (ARect.Y > Bottom));
end;

function TRect.IsEmpty: boolean; assembler;
asm
  les di, self
  mov al, 0
  mov dx, es:[di].TRect.Width
  cmp dx, 0
  jg @end
  mov dx, es:[di].TRect.Height
  cmp dx, 0
  jg @end
  inc ax
  @end:
end;

procedure TRect.Intersect(var ARect: TRect);
begin
  if not IntersectsRect(ARect) then begin
    SetDims(0, 0, 0, 0);
    exit;
  end;
  SetCoords(MaxLong(X, ARect.X), MaxLong(Y, ARect.Y),
    MinLong(Right, ARect.Right), MinLong(Bottom, ARect.Bottom));
end;

procedure TRect.GetIntersection(ARect: TRect; var AResult: TRect);
begin
  AResult.Create;
  if not IntersectsRect(ARect) then
    exit;
  AResult.SetCoords(MaxLong(X, ARect.X), MaxLong(Y, ARect.Y),
    MinLong(Right, ARect.Right), MinLong(Bottom, ARect.Bottom));
end;

function TRect.GetInversionPoints(AY, AStartX, AEndX: integer): PPointList;
var
  result: PPointList;
  index: integer;
  point: PPoint;
  inverse: boolean;
  intersects: boolean;
begin
  result := New(PPointList, CreateCapacity(16));

  inverse := false;
  for index := AStartX to AEndX do begin
    intersects := IntersectsCoords(index, AY);
    if (intersects and not inverse) or (inverse and not intersects) then begin
      point := New(PPoint, CreateCoords(index, AY));
      result^.Add(point);
      inverse := not inverse;
    end;
  end;

  GetInversionPoints := result;
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

procedure TShape.Init;
begin
  inherited Init;
end;

function TPointList.IndexOf(AItem: PPoint): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TPointList.Add(AItem: PPoint): integer;
begin
  Add := inherited Add(AItem);
end;

function TPointList.GetItem(AIndex: integer): PPoint;
begin
  GetItem := PPoint(inherited GetItem(AIndex));
end;

function TPointList.SetItem(AIndex: integer; AItem: PPoint): boolean;
begin
  SetItem := inherited SetItem(AIndex, AItem);
end;

procedure TPointList.Insert(AIndex: integer; AItem: PPoint);
begin
  inherited Insert(AIndex, AItem);
end;

function TShapeList.IndexOf(AItem: PShape): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TShapeList.Add(AItem: PShape): integer;
begin
  Add := inherited Add(AItem);
end;

function TShapeList.GetItem(AIndex: integer): PShape;
begin
  GetItem := PShape(inherited GetItem(AIndex));
end;

function TShapeList.SetItem(AIndex: integer; AItem: PShape): boolean;
begin
  SetItem := inherited SetItem(AIndex, AItem);
end;

procedure TShapeList.Insert(AIndex: integer; AItem: PShape);
begin
  inherited Insert(AIndex, AItem);
end;

function TShape.GetNewObject: PObject;
begin
  GetNewObject := New(PShape, Create);
end;

function TShape.GetInversionPoints(AY, AStartX, AEndX: integer): PPointList;
begin
end;

procedure TShape.Assign(var ASource: TObject);
var
  source: PShape;
begin
  inherited Assign(ASource);
  source := PShape(@ASource);
end;

procedure TRegion.Init;
begin
  inherited Init;
  Shapes := New(PShapeList, Create);
end;

procedure TRegion.Assign(var ASource: TObject);
var
  source: PRegion;
  index: integer;
  shape, sourceShape: PShape;
begin
  inherited Assign(ASource);
  source := PRegion(@ASource);
  if Assigned(Shapes) then
    FreeAndNil(Shapes);
  for index := 0 to source^.Shapes^.Count - 1 do begin
    sourceShape := source^.Shapes^.GetItem(index);
    shape := New(PShape, Create);
    shape^.Assign(sourceShape^);
    Shapes^.Add(shape);
  end;
end;

function TRegion.GetInversionPoints(AY, AStartX, AEndX: integer): PPointList;
var
  index: integer;
  result: PPointList;
  shape: PShape;
  shapePoints: PPointList;
  point, newPoint: PPoint;
begin
  result := New(PPointList, CreateSorted(PointXAscendingCompare));
  for index := 0 to Shapes^.Count - 1 do begin
    shape := Shapes^.GetItem(index);
    shapePoints := shape^.GetInversionPoints(AY, AStartX, AEndX);
    result^.AddRange(shapePoints, true);
    FreeAndNil(shapePoints);
  end;
  GetInversionPoints := result;
end;

end.