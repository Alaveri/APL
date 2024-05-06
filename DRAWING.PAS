{$I COMPILER.INC}
unit Drawing;

interface

uses
  AplObj,
  Lists,
  Common;

type
  PPoint = ^TPoint;
  PRect = ^TRect;
  PSize = ^TSize;
  PRectList = ^TRectList;
  PPointList = ^TPointList;
  PRegion = ^TRegion;
  PInversionPoint = ^TInversionPoint;
  PInversionPointList = ^TInversionPointList;
  PHorzSegment = ^THorzSegment;
  PHorzSegmentList = ^THorzSegmentList;

  TRegionMode = (rmInclude, rmExclude);

  TPointList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PPoint): integer;
    function Add(AItem: PPoint): integer;
    function GetItem(AIndex: integer): PPoint;
    function SetItem(AIndex: integer; AItem: PPoint): boolean;
    procedure Insert(AIndex: integer; AItem: PPoint);
  end;

  TInversionPoint = object(TObject)
  private
  public
    On: boolean;
    Position: integer;
    constructor CreatePoint(AOn: boolean; APosition: integer);
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TRectList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PRect): integer;
    function Add(AItem: PRect): integer;
    function GetItem(AIndex: integer): PRect;
    function SetItem(AIndex: integer; AItem: PRect): boolean;
    procedure Insert(AIndex: integer; AItem: PRect);
  end;

  TRegion = object(TRectList)
  private
  public
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    function GetInversionPoints(AMode: TRegionMode;
      AY, AStartX, AEndX: integer): PInversionPointList;
    function GetHorzSegments(AMode: TRegionMode; AY, AStartX, AEndX: integer): PHorzSegmentList;
    function IntersectsCoords(AX, AY: integer): boolean;
  end;

  TInversionPointList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PInversionPoint): integer;
    function Add(AItem: PInversionPoint): integer;
    function GetItem(AIndex: integer): PInversionPoint;
    function SetItem(AIndex: integer; AItem: PInversionPoint): boolean;
    procedure Insert(AIndex: integer; AItem: PInversionPoint);
  end;

  TPoint = object(TObject)
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

  TRect = object(TObject)
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
    procedure TranslateToOrigin;
    procedure Grow(ADW, ADH: integer);
    procedure Intersect(var ARect: TRect);
    procedure GetIntersection(ARect: TRect; var AResult: TRect);
    procedure Init; virtual;
    procedure GetInversionPoints(AList: PInversionPointList;
      AMode: TRegionMode; AY, AStartX, AEndX: integer);
    procedure GetHorzSegments(AList: PHorzSegmentList;
      AMode: TRegionMode; AY, AStartX, AEndX: integer);
    function GetNewObject: PObject; virtual;
    function Equals(ARect: TRect): boolean;
    function EqualsCoords(AX, AY, AWidth, AHeight: integer): boolean;
    function IsEmpty: boolean;
    function Right: integer;
    function Bottom: integer;
    function IntersectsCoords(AX, AY: integer): boolean;
    function IntersectsPoint(APoint: TPoint): boolean;
    function IntersectsRect(ARect: TRect): boolean;
  end;

  THorzSegment = object(TObject)
  private
  public
    X1, X2: integer;
    constructor CreateSegment(AX1, AX2: integer);
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  THorzSegmentList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PHorzSegment): integer;
    function Add(AItem: PHorzSegment): integer;
    function GetItem(AIndex: integer): PHorzSegment;
    function SetItem(AIndex: integer; AItem: PHorzSegment): boolean;
    procedure Insert(AIndex: integer; AItem: PHorzSegment);
  end;

  TSize = object(TObject)
  public
    Width, Height: longint;
    constructor Create;
    constructor CreateDims(AWidth, AHeight: longint);
    constructor CreateSize(ASize: TSize);
    constructor CreateRect(ARect: TRect);
    procedure Assign(var ASource: TObject); virtual;
    procedure SetDims(AWidth, AHeight: longint);
    procedure SetRect(ARect: TRect);
    procedure SetSize(ASize: TSize);
    procedure Grow(ADW, ADH: longint);
    procedure Init; virtual;
  end;

implementation

function InversionCompare(AItem1, AItem2: pointer): integer; far;
var
  item1, item2: PInversionPoint;
begin
  item1 := PInversionPoint(AItem1);
  item2 := PInversionPoint(AItem2);
  InversionCompare := 0;
  if item1^.Position = item2^.Position then
    exit;
  if item1^.Position < item2^.Position then
    InversionCompare := -1
  else if item1^.Position > item2^.Position then
    InversionCompare := 1;
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

procedure TRect.TranslateToOrigin;
begin
  X := 0;
  Y := 0;
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

procedure TRect.GetHorzSegments(AList: PHorzSegmentList;
  AMode: TRegionMode; AY, AStartX, AEndX: integer);
var
  point: PInversionPoint;
  startMode, endMode: boolean;
  startPoint: PInversionPoint;
  endPoint: PInversionPoint;
  segment: PHorzSegment;
  rect: TRect;
begin
  startPoint := nil;
  endPoint := nil;
  if AMode = rmInclude then begin
    rect.CreateDims(AStartX, AY, AEndX, 1);
    if not IntersectsRect(rect) then
      exit;
    if IntersectsCoords(AStartX, AY) then
      startPoint := New(PInversionPoint, CreatePoint(true, X));
    if IntersectsCoords(AEndX, AY) then
      endPoint := New(PInversionPoint, CreatePoint(true, X));
    if not Assigned(startPoint) then
      startPoint := New(PInversionPoint, CreatePoint(true, AStartX));
    if not Assigned(endPoint) then
      endPoint := New(PInversionPoint, CreatePoint(true, AEndX));
    segment := New(PHorzSegment, CreateSegment(startPoint^.Position, endPoint^.Position));
    AList^.Add(segment);
  end
  else begin
    if (X >= AStartX) and (Right <= AEndX) then
      exit;
    if (X < AStartX) and (Right <= AEndX) then begin
      segment := New(PHorzSegment, CreateSegment(X, AStartX));
      AList^.Add(segment);
    end
    else if (X >= AStartX) and (Right > AEndX) then begin
      segment := New(PHorzSegment, CreateSegment(AEndX, Right));
      AList^.Add(segment);
    end
    else if (X < AStartX) and (Right > AEndX) then begin
      segment := New(PHorzSegment, CreateSegment(X, AStartX));
      AList^.Add(segment);
      segment := New(PHorzSegment, CreateSegment(AEndX, Right));
      AList^.Add(segment);
    end;
  end;
  FreeAndNil(startPoint);
  FreeAndNil(endPoint);
end;

procedure TRect.GetInversionPoints(AList: PInversionPointList;
  AMode: TRegionMode; AY, AStartX, AEndX: integer);
var
  point: PInversionPoint;
  startMode, endMode: boolean;
begin
  startMode := true;
  endMode := false;
  if AMode = rmExclude then begin
    startMode := false;
    endMode := true;
  end;
  if IntersectsCoords(AStartX, AY) then begin
    point := New(PInversionPoint, CreatePoint(startMode, X));
    AList^.Add(point);
  end;
  if IntersectsCoords(AEndX, AY) then begin
    point := New(PInversionPoint, CreatePoint(endMode, Right));
    AList^.Add(point);
  end;
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

constructor TSize.CreateRect(ARect: TRect);
begin
  Init;
  SetRect(ARect);
end;

procedure TSize.Init;
begin
  inherited Init;
  Width := 0;
  Height := 0;
end;

procedure TSize.Assign(var ASource: TObject);
var
  source: PSize;
begin
  inherited Assign(ASource);
  source := PSize(@ASource);
  Width := source^.Width;
  Height := source^.Height;
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

procedure TSize.SetRect(ARect: TRect);
begin
  Width := ARect.Width;
  Height := ARect.Height;
end;

procedure TSize.Grow(ADW, ADH: longint);
begin
  Inc(width, ADW);
  Inc(height, ADH);
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

function TRectList.IndexOf(AItem: PRect): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TRectList.Add(AItem: PRect): integer;
begin
  Add := inherited Add(AItem);
end;

function TRectList.GetItem(AIndex: integer): PRect;
begin
  GetItem := PRect(inherited GetItem(AIndex));
end;

function TRectList.SetItem(AIndex: integer; AItem: PRect): boolean;
begin
  SetItem := inherited SetItem(AIndex, AItem);
end;

procedure TRectList.Insert(AIndex: integer; AItem: PRect);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TRegion.Init;
begin
  inherited Init;
end;

procedure TRegion.Assign(var ASource: TObject);
var
  source: PRegion;
  index: integer;
  rect, sourceRect: PRect;
begin
  inherited Assign(ASource);
  source := PRegion(@ASource);
  Clear;
  for index := 0 to source^.Count - 1 do begin
    sourceRect := source^.GetItem(index);
    rect := New(PRect, Create);
    rect^.Assign(sourceRect^);
    Add(rect);
  end;
end;

function TRegion.IntersectsCoords(AX, AY: integer): boolean;
var
  index: integer;
  rect: PRect;
begin
  IntersectsCoords := false;
  for index := 0 to Count - 1 do begin
    rect := GetItem(index);
    if rect^.IntersectsCoords(AX, AY) then begin
      IntersectsCoords := true;
      exit;
    end;
  end;
end;

function TRegion.GetHorzSegments(AMode: TRegionMode; AY, AStartX, AEndX: integer): PHorzSegmentList;
var
  list: PHorzSegmentList;
  result: PHorzSegmentList;
begin
  list := New(PHorzSegmentList, CreateCapacity(16));
  result := New(PHorzSegmentList, CreateCapacity(16));
  GetHorzSegments := result;
end;

function TRegion.GetInversionPoints(AMode: TRegionMode;
  AY, AStartX, AEndX: integer): PInversionPointList;
var
  result: PInversionPointList;
  index: integer;
  rect: PRect;
begin
  result := New(PInversionPointList, CreateSortedCapacity(InversionCompare, 16));
  for index := 0 to Count - 1 do begin
    rect := GetItem(index);
    rect^.GetInversionPoints(result, AMode, AY, AStartX, AEndX);
  end;
  GetInversionPoints := result;
end;

constructor TInversionPoint.CreatePoint(AOn: boolean; APosition: integer);
begin
  inherited Create;
  On := AOn;
  Position := APosition;
end;

procedure TInversionPoint.Init;
begin
  inherited Init;
  Position := 0;
  On := true;
end;

procedure TInversionPoint.Assign(var ASource: TObject);
var
  source: PInversionPoint;
begin
  inherited Assign(ASource);
  source := PInversionPoint(@ASource);
  Position := source^.Position;
  On := source^.On;
end;

function TInversionPointList.IndexOf(AItem: PInversionPoint): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TInversionPointList.Add(AItem: PInversionPoint): integer;
begin
  Add := inherited Add(AItem);
end;

function TInversionPointList.GetItem(AIndex: integer): PInversionPoint;
begin
  GetItem := PInversionPoint(inherited GetItem(AIndex));
end;

function TInversionPointList.SetItem(AIndex: integer; AItem: PInversionPoint): boolean;
begin
  SetItem := inherited SetItem(AIndex, AItem);
end;

procedure TInversionPointList.Insert(AIndex: integer; AItem: PInversionPoint);
begin
  inherited Insert(AIndex, AItem);
end;

constructor THorzSegment.CreateSegment(AX1, AX2: integer);
begin
  Create;
  X1 := AX1;
  X2 := AX2;
end;

procedure THorzSegment.Init;
begin
  inherited Init;
  X1 := 0;
  X2 := 0;
end;

procedure THorzSegment.Assign(var ASource: TObject);
var
  source: PHorzSegment;
begin
  inherited Assign(ASource);
  source := PHorzSegment(@ASource);
  X1 := source^.X1;
  X2 := source^.X2;
end;

function THorzSegmentList.IndexOf(AItem: PHorzSegment): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function THorzSegmentList.Add(AItem: PHorzSegment): integer;
begin
  Add := inherited Add(AItem);
end;

function THorzSegmentList.GetItem(AIndex: integer): PHorzSegment;
begin
  GetItem := PHorzSegment(inherited GetItem(AIndex));
end;

function THorzSegmentList.SetItem(AIndex: integer; AItem: PHorzSegment): boolean;
begin
  inherited SetItem(AIndex, AItem);
end;

procedure THorzSegmentList.Insert(AIndex: integer; AItem: PHorzSegment);
begin
  inherited Insert(AIndex, AItem);
end;

end.