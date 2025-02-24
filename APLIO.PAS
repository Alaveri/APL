{$I COMPILER.INC}
unit AplIo;

interface

uses
  AplConst,
  AplObj,
  AplStr,
  AplTypes,
  AplUtils,
  Lists,
  Compress,
  Streams,
  Strings;

type
  PPersistent = ^TPersistent;
  PCompressible = ^TCompressible;

  TPersistent = object(TStatusObject)
  private
  public
    function IsPersistent: boolean; virtual;
    function TryLoadFromStream(AStream: PStream): boolean;
    function TrySaveToStream(AStream: PStream): boolean;
    function TryLoadFromFile(const AFileName: string): boolean;
    function TrySaveToFile(const AFileName: string): boolean;
    procedure LoadFromFile(const AFileName: string); virtual;
    procedure LoadFromStream(AStream: PStream); virtual;
    procedure SaveToFile(const AFileName: string); virtual;
    procedure SaveToStream(AStream: PStream); virtual;
  end;

  TCompressible = object(TPersistent)
  private
    FCompression: TAplCompression;
    FCompressionLevel: TCompressionLevel;
  public
    constructor Create;
    constructor CreateCompression(ACompression: TAplCompression; ACompressionLevel: TCompressionLevel);
    procedure Init; virtual;
    function Compression: TAplCompression;
    function CompressionLevel: TCompressionLevel;
    procedure SetCompressionType(ACompression: TAplCompression);
    procedure SetCompressionLevel(ACompressionLevel: TCompressionLevel);
    procedure SetCompression(ACompression: TAplCompression; ACompressionLevel: TCompressionLevel);
  end;


implementation

function TPersistent.IsPersistent: boolean;
begin
  IsPersistent := true;
end;

procedure TPersistent.LoadFromFile(const AFileName: string);
var
  stream: PFileStream;
begin
  if not FileExists(AFilename) then begin
    Raise(ecFileNotFound);
    exit;
  end;
  stream := New(PFileStream, Create(AFileName, fmRead));
  if not CheckReRaise(stream) then
    LoadFromStream(stream);
  CheckReRaise(stream);
  FreeAndNil(stream);
end;

procedure TPersistent.LoadFromStream(AStream: PStream);
begin
  Abstract;
end;

procedure TPersistent.SaveToFile(const AFileName: string);
var
  stream: PFileStream;
begin
  stream := New(PFileStream, Create(AFileName, fmCreate));
  if not CheckReRaise(stream) then
    SaveToStream(stream);
  CheckReRaise(stream);
  FreeAndNil(stream);
end;

procedure TPersistent.SaveToStream(AStream: PStream);
begin
  Abstract;
end;

function TPersistent.TryLoadFromFile(const AFileName: string): boolean;
begin
  LoadFromFile(AFileName);
  TryLoadFromFile := not HasException;
  ClearException;
end;

function TPersistent.TrySaveToFile(const AFileName: string): boolean;
begin
  SaveToFile(AFileName);
  TrySaveToFile := not HasException;
  ClearException;
end;

function TPersistent.TryLoadFromStream(AStream: PStream): boolean;
begin
  LoadFromStream(AStream);
  CheckReRaise(AStream);
  TryLoadFromStream := not HasException;
  ClearException;
end;

function TPersistent.TrySaveToStream(AStream: PStream): boolean;
begin
  SaveToStream(AStream);
  CheckReRaise(AStream);
  TrySaveToStream := not HasException;
  ClearException;
end;

constructor TCompressible.Create;
begin
  inherited Create;
end;

constructor TCompressible.CreateCompression(ACompression: TAplCompression; ACompressionLevel: TCompressionLevel);
begin
  inherited Create;
  FCompression := ACompression;
  FCompressionLevel := ACompressionLevel;
end;

procedure TCompressible.Init;
begin
  inherited Init;
  FCompression := acNone;
  FCompressionLevel := clLow;
end;

function TCompressible.Compression: TAplCompression;
begin
  Compression := FCompression;
end;

function TCompressible.CompressionLevel: TCompressionLevel;
begin
  CompressionLevel := FCompressionLevel;
end;

procedure TCompressible.SetCompressionType(ACompression: TAplCompression);
begin
  FCompression := ACompression;
end;

procedure TCompressible.SetCompressionLevel(ACompressionLevel: TCompressionLevel);
begin
  FCompressionLevel := ACompressionLevel;
end;

procedure TCompressible.SetCompression(ACompression: TAplCompression; ACompressionLevel: TCompressionLevel);
begin
  FCompression := ACompression;
  FCompressionLevel := ACompressionLevel;
end;

var
  PreviousExitProc: PProc;

procedure Finalize;
begin
  ExitProc := PreviousExitProc;
end;

begin
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
