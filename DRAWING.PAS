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

  TRegionMode = (rmInclude, rmExclude);

  TPointList = object(TObjectList)
  private
  public
    function GetItem(AIndex: integer): PPoint;
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
    function GetItem(AIndex: integer): PRect;
  end;

  TInversionPointList = object(TObjectList)
  private
  public
    constructor Create;
    procedure Init; virtual;
    function GetItem(AIndex: integer): PInversionPoint;
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

  TRegion = object(TRectList)
  private
  public
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    function GetInversionPoints(AMode: TRegionMode;
      AY, AStartX, AEndX: integer): PInversionPointList;
    function IntersectsCoords(AX, AY: integer): boolean;
    function IntersectsRect(var ARect: TRect): boolean;
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
  if (AY < Y) or (AY > Bottom) then
    exit;
  if AStartX = AEndX then
    exit;
  if AStartX <= X then begin
    point := New(PInversionPoint, CreatePoint(startMode, X));
    AList^.Add(point);
  end;
  if AEndX >= Right then begin
    point := New(PInversionPoint, CreatePoint(endMode, Right + 1));
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

function TPointList.GetItem(AIndex: integer): PPoint;
begin
  GetItem := PPoint(inherited GetItem(AIndex));
end;

function TRectList.GetItem(AIndex: integer): PRect;
begin
  GetItem := PRect(inherited GetItem(AIndex));
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

function TRegion.IntersectsRect(var ARect: TRect): boolean;
var
  index: integer;
  rect: PRect;
begin
  IntersectsRect:= false;
  for index := 0 to Count - 1 do begin
    rect := GetItem(index);
    if rect^.IntersectsRect(ARect) then begin
      IntersectsRect := true;
      exit;
    end;
  end;
end;


function TRegion.GetInversionPoints(AMode: TRegionMode;
  AY, AStartX, AEndX: integer): PInversionPointList;
var
  result: PInversionPointList;
  index: integer;
  rect: PRect;
begin
  result := New(PInversionPointList, CreateSortedCapacity(InversionCompare, 2));
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

function TInversionPointList.GetItem(AIndex: integer): PInversionPoint;
begin
  GetItem := PInversionPoint(inherited GetItem(AIndex));
end;

procedure TInversionPointList.Init;
begin
  inherited Init;
end;

constructor TInversionPointList.Create;
begin
  inherited Create;
end;

end.