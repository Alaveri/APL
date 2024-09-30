{$I COMPILER.INC}
unit Palettes;

interface

uses
  AplObj,
  Errors,
  Streams,
  Lists;

type
  PRgbPalette = ^TRgbPalette;
  PPaletteWriter = ^TPaletteWriter;
  PPaletteReader = ^TPaletteReader;
  PGimpPaletteWriter = ^TGimpPaletteWriter;
  PGimpPaletteReader = ^TGimpPaletteReader;
  PRgbColor = ^TRgbColor;
  PRgbColorList = ^TRgbColorList;
  PRgbPaletteData = ^TRgbPaletteData;
  PJascPaletteWriter = ^TJascPaletteWriter;
  PJascPaletteReader = ^TJascPaletteReader;

  TPaletteFormat =
  (
    pfNone,
    pfApl,
    pfJasc,
    pfGimp,
    pfPhotoshop,
    pfAesprite
  );

  TRgbColor = record
    Red: byte;
    Green: byte;
    Blue: byte;
  end;

  TRgbPaletteData = array[byte] of TRgbColor;

  TRgbColorList = object(TList)
  private
  public
    function Add(AItem: PRgbColor): integer;
    function GetItem(AIndex: integer): PRgbColor;
    function IndexOf(AItem: PRgbColor): integer;
    procedure SetItem(AIndex: integer; AItem: PRgbColor);
    procedure Insert(AIndex: integer; AItem: PRgbColor);
    procedure Delete(AIndex: integer); virtual;
    destructor Free; virtual;
  end;

  TRgbPalette = object(TStatusObject)
  private
    FColors: PRgbColorList;
    FFormat: TPaletteFormat;
  public
    constructor CreateFromFile(AFilename: string; AFormat: TPaletteFormat);
    constructor CreateFromStream(AStream: PStream; AFormat: TPaletteFormat);
    function Colors: PRgbColorList;
    function Format: TPaletteFormat;
    function GetPaletteData: PRgbPaletteData;
    procedure SetPaletteData(AData: PRgbPaletteData);
    procedure SetColor(AIndex: byte; AColor: TRgbColor);
    procedure SaveToFile(AFilename: string);
    procedure SaveToStream(AStream: PStream);
    procedure SaveToStreamFormat(AStream: PStream; AFormat: TPaletteFormat);
    procedure SaveToFileFormat(AFilename: string; AFormat: TPaletteFormat);
    procedure LoadFromFile(AFilename: string; AFormat: TPaletteFormat);
    procedure LoadFromStream(AStream: PStream; AFormat: TPaletteFormat);
    procedure SetFormat(AFormat: TPaletteFormat);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TPaletteWriter = object(TStatusObject)
  private
  public
    function Format: TPaletteFormat; virtual;
    procedure WritePalette(APalette: PRgbColorList; AStream: PStream); virtual;
    procedure WriteLine(AStream: PStream; ALine: string);
  end;

  TPaletteReader = object(TStatusObject)
  private
  public
    function Format: TPaletteFormat; virtual;
    function ReadPalette(AStream: PStream): PRgbColorList; virtual;
    function ReadLine(AStream: PStream): string;
  end;

  TGimpPaletteWriter = object(TPaletteWriter)
  private
  public
    function Format: TPaletteFormat; virtual;
    procedure WritePalette(APalette: PRgbColorList; AStream: PStream); virtual;
  end;

  TGimpPaletteReader = object(TPaletteReader)
  private
  public
    function Format: TPaletteFormat; virtual;
    function ReadPalette(AStream: PStream): PRgbColorList; virtual;
  end;

  TJascPaletteWriter = object(TPaletteWriter)
  private
  public
    function Format: TPaletteFormat; virtual;
    procedure WritePalette(APalette: PRgbColorList; AStream: PStream); virtual;
  end;

  TJascPaletteReader = object(TPaletteReader)
  private
  public
    function Format: TPaletteFormat; virtual;
    function ReadPalette(AStream: PStream): PRgbColorList; virtual;
  end;

implementation

uses
  Common;

function TRgbColorList.Add(AItem: PRgbColor): integer;
begin
  inherited Add(AItem);
end;

function TRgbColorList.GetItem(AIndex: integer): PRgbColor;
begin
  GetItem := PRgbColor(inherited GetItem(AIndex));
end;

function TRgbColorList.IndexOf(AItem: PRgbColor): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TRgbColorList.SetItem(AIndex: integer; AItem: PRgbColor);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TRgbColorList.Insert(AIndex: integer; AItem: PRgbColor);
begin
  inherited Insert(AIndex, AItem);
end;

procedure TRgbColorList.Delete(AIndex: integer);
begin
  if (AIndex < 0) or (AIndex > Count - 1) then begin
    Raise(ecIndexOutOfBounds);
    exit;
  end;
  Dispose(PRgbColor(inherited GetItem(AIndex)));
  inherited Delete(AIndex);
end;

destructor TRgbColorList.Free;
begin
  Clear;
  inherited Free;
end;

constructor TRgbPalette.CreateFromFile(AFilename: string; AFormat: TPaletteFormat);
begin
  Create;
  LoadFromFile(AFilename, AFormat);
end;

constructor TRgbPalette.CreateFromStream(AStream: PStream; AFormat: TPaletteFormat);
begin
  Create;
  LoadFromStream(AStream, AFormat);
end;

procedure TRgbPalette.Init;
begin
  inherited Init;
  FColors := New(PRgbColorList, Create);
  FFormat := pfNone;
end;

function TRgbPalette.Colors: PRgbColorList;
begin
  Colors := FColors;
end;

function TRgbPalette.Format: TPaletteFormat;
begin
  Format := FFormat;
end;

procedure TRgbPalette.SetColor(AIndex: byte; AColor: TRgbColor);
var
  color: PRgbColor;
begin
  if AIndex > FColors^.Count - 1 then begin
    Raise(ecIndexOutOfBounds);
    exit;
  end;
  color := FColors^.GetItem(AIndex);
  color^.Red := AColor.Red;
  color^.Green := AColor.Green;
  color^.Blue := AColor.Blue;
end;

procedure TRgbPalette.SaveToFile(AFilename: string);
begin
  SaveToFileFormat(AFilename, FFormat);
end;

procedure TRgbPalette.SaveToFileFormat(AFilename: string; AFormat: TPaletteFormat);
  var
  stream: PStream;
begin
  stream := New(PFileStream, Create(AFilename, fmWrite));
  SaveToStreamFormat(stream, AFormat);
  if stream^.HasException then
    Raise(stream^.Exception^.Code);
  FreeAndNil(stream);
end;

procedure TRgbPalette.SaveToStream(AStream: PStream);
begin
  SaveToStreamFormat(AStream, FFormat);
end;

procedure TRgbPalette.SaveToStreamFormat(AStream: PStream; AFormat: TPaletteFormat);
var
  writer: PPaletteWriter;
begin
  case AFormat of
    pfGimp: writer := New(PGimpPaletteWriter, Create);
    pfJasc: writer := New(PJascPaletteWriter, Create);
    else begin
      Raise(ecUnsupportedPaletteFormat);
      exit;
    end;
  end;
  writer^.WritePalette(FColors, AStream);
  if writer^.HasException then
    Raise(writer^.Exception^.Code);
  FreeAndNil(writer);
end;

procedure TRgbPalette.LoadFromFile(AFilename: string; AFormat: TPaletteFormat);
var
  stream: PStream;
begin
  stream := New(PFileStream, Create(AFilename, fmRead));
  LoadFromStream(stream, AFormat);
  if stream^.HasException then
    Raise(stream^.Exception^.Code);
  FreeAndNil(stream);
end;

procedure TRgbPalette.LoadFromStream(AStream: PStream; AFormat: TPaletteFormat);
var
  reader: PPaletteReader;
begin
  FreeAndNil(FColors);
  case AFormat of
    pfGimp: reader := New(PGimpPaletteReader, Create);
    else begin
      Raise(ecUnsupportedPaletteFormat);
      exit;
    end;
  end;
  FColors := reader^.ReadPalette(AStream);
  if reader^.HasException then
    Raise(reader^.Exception^.Code);
  FreeAndNil(reader);
end;

procedure TRgbPalette.SetFormat(AFormat: TPaletteFormat);
begin
  FFormat := AFormat;
end;

function TPaletteWriter.Format: TPaletteFormat;
begin
  Format := pfNone;
end;

procedure TRgbPalette.SetPaletteData(AData: PRgbPaletteData);
var
  index: byte;
  color: PRgbColor;
begin
  FColors^.Clear;
  for index := 0 to 255 do begin
    color := New(PRgbColor);
    color^.Red := AData^[index].Red;
    color^.Green := AData^[index].Green;
    color^.Blue := AData^[index].Blue;
    FColors^.Add(color);
  end;
end;

function TRgbPalette.GetPaletteData: PRgbPaletteData;
var
  index: byte;
  color: PRgbColor;
  result: PRgbPaletteData;
begin
  New(result);
  if (FColors^.Count < 256) or not Assigned(FColors) then begin
    Raise(ecInvalidPalette);
    exit;
  end;
  for index := 0 to 255 do begin
    color := FColors^.GetItem(index);
    result^[index].Red := color^.Red;
    result^[index].Green := color^.Green;
    result^[index].Blue := color^.Blue;
  end;
  GetPaletteData := result;
end;

procedure TPaletteWriter.WriteLine(AStream: PStream; ALine: string);
var
  buffer: string;
begin
  buffer := ALine + #13#10;
  AStream^.Write(@buffer[1], Length(buffer));
  if AStream^.HasException then
    Raise(AStream^.Exception^.Code);
end;

procedure TPaletteWriter.WritePalette(APalette: PRgbColorList; AStream: PStream);
begin
  Abstract;
end;

function TPaletteReader.Format: TPaletteFormat;
begin
  Format := pfNone;
end;

function TPaletteReader.ReadPalette(AStream: PStream): PRgbColorList;
begin
  Abstract;
end;

function TPaletteReader.ReadLine(AStream: PStream): string;
var
  buffer: string;
  ch: char;
begin
  buffer := '';
  while not AStream^.EndOfStream do begin
    ch := Char(AStream^.ReadByte);
    if AStream^.HasException then
      Raise(AStream^.Exception^.Code);
    if ch = #13 then
      continue;
    if ch = #10 then
      break;
    buffer := buffer + ch;
  end;
  ReadLine := buffer;
end;

destructor TRgbPalette.Free;
begin
  FreeAndNil(FColors);
  inherited Free;
end;

function TGimpPaletteWriter.Format: TPaletteFormat;
begin
  Format := pfGimp;
end;

procedure TGimpPaletteWriter.WritePalette(APalette: PRgbColorList; AStream: PStream);
var
  index: integer;
  color: PRgbColor;
begin
  WriteLine(AStream, 'GIMP Palette');
   {38  33  68	Untitled}
  for index := 0 to APalette^.Count - 1 do begin
    color := APalette^.GetItem(index);
    WriteLine(AStream,
      LeftPad(IntToStr(color^.Red), 3, ' ') + ' '
      + LeftPad(IntToStr(color^.Green), 3, ' ') + ' '
      + LeftPad(IntToStr(color^.Blue), 3, ' ') + ' '
      + ' Untitled'
    );
  end;
end;

function TGimpPaletteReader.Format: TPaletteFormat;
begin
  Format := pfGimp;
end;

function TGimpPaletteReader.ReadPalette(AStream: PStream): PRgbColorList;
var
  line: string;
  color: TRgbColor;
  comment: boolean;
  result: PRgbColorList;
begin
  New(result, Create);
  while not AStream^.EndOfStream do begin
    line := ReadLine(AStream);
    if StartsWith(line, '#') then
      continue;
    color.Red := StrToInt(Trim(Copy(line, 1, 3)), 0);
    color.Green := StrToInt(Trim(Copy(line, 5, 3)), 0);
    color.Blue := StrToInt(Trim(Copy(line, 9, 3)), 0);
    result^.Add(New(PRgbColor));
  end;
  ReadPalette := result;
end;

function TJascPaletteWriter.Format: TPaletteFormat;
begin
  Format := pfJasc;
end;

procedure TJascPaletteWriter.WritePalette(APalette: PRgbColorList; AStream: PStream);
var
  index: integer;
  color: PRgbColor;
begin
  WriteLine(AStream, 'JASC-PAL');
  WriteLine(AStream, '0100');
  WriteLine(AStream, IntToStr(APalette^.Count));
  for index := 0 to APalette^.Count - 1 do begin
    color := APalette^.GetItem(index);
    WriteLine(AStream,
      IntToStr(color^.Red) + ' '
      + IntToStr(color^.Green) + ' '
      + IntToStr(color^.Blue)
    );
  end;
end;

function TJascPaletteReader.Format: TPaletteFormat;
begin
  Format := pfJasc;
end;

function TJascPaletteReader.ReadPalette(AStream: PStream): PRgbColorList;
var
  line: string;
  color: TRgbColor;
  result: PRgbColorList;
  count: integer;
begin
  New(result, Create);
  line := ReadLine(AStream);
  if line <> 'JASC-PAL' then begin
    Raise(ecInvalidPalette);
    exit;
  end;
  line := ReadLine(AStream);
  if line <> '0100' then begin
    Raise(ecInvalidPalette);
    exit;
  end;
  line := ReadLine(AStream);
  count := StrToInt(line, 0);
  if AStream^.HasException then begin
    Raise(AStream^.Exception^.Code);
    exit;
  end;
  while not AStream^.EndOfStream do begin
    line := ReadLine(AStream);
    if AStream^.HasException then begin
      Raise(AStream^.Exception^.Code);
      exit;
    end;
    // Change this to not read padding for each color component
    color.Red := StrToInt(Trim(Copy(line, 1, 3)), 0);
    color.Green := StrToInt(Trim(Copy(line, 5, 3)), 0);
    color.Blue := StrToInt(Trim(Copy(line, 9, 3)), 0);
    result^.Add(New(PRgbColor));
  end;
  ReadPalette := result;
end;

end.