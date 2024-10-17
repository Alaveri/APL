{$I COMPILER.INC}
unit GrDrv3d;

interface

uses
  AplObj,
  GraphDrv,
  Errors;

type
  P3DGraphicsExtension = ^T3DGraphicsExtension;

  T3DGraphicsExtension = object(TStatusObject)
  private
    FGraph: PGraphicsDriver;
  public
    constructor Create(AGraph: PGraphicsDriver);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

var
  Graph3D: P3DGraphicsExtension;

implementation

constructor T3DGraphicsExtension.Create(AGraph: PGraphicsDriver);
begin
  inherited Create;
  FGraph := AGraph;
end;

procedure T3DGraphicsExtension.Init;
begin
  inherited Init;
  Graph3D := @Self;
end;

destructor T3DGraphicsExtension.Free;
begin
  inherited Free;
end;

begin
  Graph3D := nil;
end.

