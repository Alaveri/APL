{$I COMPILER.INC}
unit Objects;

interface

uses
  Consts,
  Strings,
  StrUtils,
  Utils;

type
  (** Pointer to a word.*)
  PWord = ^word;

  (** Pointer to a pointer.*)
  PPointer = ^pointer;

  (** Pointer to a basic object containing initialization and finalization.*)
  PBaseObject = ^TBaseObject;

  (**
   * Compares one item to another.  If item1 is greater than item2, the
   * comparer should return 1.  If item1 is less than item2, the comparer
   * return -1.  If they are equal, the comparer should return 0.
   * @param item1 The first item to compare.
   * @param item2 The second item to compare.
   *)
  TComparer = function(item1, item2: pointer): integer;

  (**
   * Compares an item to a value and returns true if a condition is met.
   * @param item The item to be compared to the value.
   * @param value The value to be compared to the item.
   * @returns true if the compared item and value satisfies a condition.
   *)
  TPredicate = function(item: pointer; var value): boolean;

  (** Represents a basic object containing initialization and finalization.*)
  TBaseObject = object
  private
  public
    (** Creates a new object of type TBaseObject. Create calls Init. *)

    constructor Create;

    (** Initializes this object. Called by Create.
     *)
    procedure Init; virtual;

    (** Finalizes this object *)
    destructor Done; virtual;
  end;


  (** Pointer to an object containing TypeName and Id. *)
  PObject = ^TObject;

  (** Represents an object containing TypeName and Id. *)
  TObject = object(TBaseObject)
  private
  public
    (** The id of this object *)
    Id: PChar;

    (** Creates a new object of type TObject.  Create calls Init. *)
    constructor Create;

    (**
     * Creates a new object of type TObject using the specified id.
     * Create calls Init.
     *)
    constructor CreateId(newId: string);

    (** Initializes this object.  Called by Create and CreateId.
     * @param typeName The name of this type.
     *)
    procedure Init; virtual;

    (** Converts this object to a string.
    * @returns a string representation of this object.
    *)
    function ToString: string; virtual;
    function GetTypeName: string; virtual;
    destructor Done; virtual;
  end;

  (** Pointer to a callback invoked when a memory allocation fails *)
  PAllocationError = ^TAllocationError;

  (** Callback invoked when a memory allocation fails *)
  TAllocationError = procedure(var error: TError);

  (** Pointer to an object that can be assigned to other objects
  * of the same type.
  *)
  PPersistent = ^TPersistent;

  (** Represents an object that can be assigned to other objects
  * of the same type.
  *)
  TPersistent = object(TObject)
  public
    (** Initializes this object.  Called by Create and CreateId. *)
    procedure Init; virtual;

    (**
    * Assigns the values of the source object to this object.
    * @param source The source object to assign to this object.
    *)
    procedure Assign(var source: TPersistent); virtual;

    (**
    * Assigns the values of this object to the destination object.
    * @param dest The destination object to be assigned to this object.
    *)
    procedure AssignTo(var dest: TPersistent); virtual;
    function GetTypeName: string; virtual;
  end;

var
  (** Callback invoked when a memory allocation error occurs. *)
  OnAllocationError: PAllocationError;

implementation

uses
  Crt;

constructor TBaseObject.Create;
begin
  Init;
end;

procedure TBaseObject.Init;
begin
end;

destructor TBaseObject.Done;
begin
end;

constructor TObject.CreateId(newId: string);
begin
  Init;
  Id := NewLargeString(newId);
end;

constructor TObject.Create;
begin
  Init;
end;

function TObject.GetTypeName: string;
begin
  GetTypeName := 'TObject';
end;

procedure TObject.Init;
begin
  inherited Init;
  id := nil;
end;

function TObject.ToString: string;
begin
  ToString := GetTypeName;
end;

destructor TObject.Done;
begin
  DisposeLargeString(Id);
end;

procedure TPersistent.Init;
begin
  TObject.Init;
end;

function TPersistent.GetTypeName: string;
begin
  GetTypeName := 'TPersistent';
end;

procedure TPersistent.Assign(var source: TPersistent);
begin
end;

procedure TPersistent.AssignTo(var dest: TPersistent);
begin
end;

begin
  OnAllocationError := nil;

end.