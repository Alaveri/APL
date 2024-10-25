{$I COMPILER.INC}
unit Palettes;

interface

uses
  AplObj,
  AplTypes,
  Errors,
  Common,
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
  PAplPaletteWriter = ^TAplPaletteWriter;
  PAplPaletteReader = ^TAplPaletteReader;
  PRgbColorListProc = ^TRgbColorListProc;

  TRgbColorListProc = procedure(ASender: PRgbColorList; AItem: PRgbColor);

  TStandardColor =
  (
    scEga,
    scWhite,
    scRed,
    scGreen,
    scBlue,
    scCyan,
    scYellow,
    scMagenta,
    scOrange,
    scBrown,
    scSpringGreen,
    scAzure,
    scViolet,
    scFleshTone
  );

  TColor = record
    Color: TStandardColor;
    Shade: byte;
  end;

  TPaletteFormat =
  (
    pfNone,
    pfApl,
    pfJasc,
    pfGimp
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
    procedure ForEach(AProc: PRgbColorListProc);
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
    procedure SaveToStreamWriter(AWriter: PPaletteWriter);
    procedure SaveToFileFormat(AFilename: string; AFormat: TPaletteFormat);
    procedure LoadFromFile(AFilename: string; AFormat: TPaletteFormat);
    procedure LoadFromStream(AStream: PStream; AFormat: TPaletteFormat);
    procedure LoadFromStreamReader(AReader: PPaletteReader);
    procedure SetFormat(AFormat: TPaletteFormat);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TPaletteWriter = object(TStatusObject)
  private
    FStream: PStream;
  public
    constructor Create(AStream: PStream);
    function Format: TPaletteFormat; virtual;
    procedure WritePalette(APalette: PRgbColorList); virtual;
    procedure WriteLine(ALine: string);
    procedure SetStream(AStream: PStream);
  end;

  TPaletteReader = object(TStatusObject)
  private
    FStream: PStream;
  public
    constructor Create(AStream: PStream);
    function Format: TPaletteFormat; virtual;
    function ReadPalette: PRgbColorList; virtual;
    function ReadLine: string;
    procedure SetStream(AStream: PStream);
  end;

  TAplPaletteWriter = object(TPaletteWriter)
  private
  public
    function Format: TPaletteFormat; virtual;
    procedure WritePalette(APalette: PRgbColorList); virtual;
  end;

  TAplPaletteReader = object(TPaletteReader)
  private
  public
    function Format: TPaletteFormat; virtual;
    function ReadPalette: PRgbColorList; virtual;
  end;

  TGimpPaletteWriter = object(TPaletteWriter)
  private
  public
    function Format: TPaletteFormat; virtual;
    procedure WritePalette(APalette: PRgbColorList); virtual;
  end;

  TGimpPaletteReader = object(TPaletteReader)
  private
  public
    function Format: TPaletteFormat; virtual;
    function ReadPalette: PRgbColorList; virtual;
  end;

  TJascPaletteWriter = object(TPaletteWriter)
  private
  public
    function Format: TPaletteFormat; virtual;
    procedure WritePalette(APalette: PRgbColorList); virtual;
  end;

  TJascPaletteReader = object(TPaletteReader)
  private
  public
    function Format: TPaletteFormat; virtual;
    function ReadPalette: PRgbColorList; virtual;
  end;

const
  egaBlack = 0;
  egaBlue = 1;
  egaGreen = 2;
  egaCyan = 3;
  egaRed = 4;
  egaMagenta = 5;
  egaBrown = 6;
  egaLightGray = 7;
  egaDarkGray = 8;
  egaLightBlue = 9;
  egaLightGreen = 10;
  egaLightCyan = 11;
  egaLightRed = 12;
  egaLightMagenta = 13;
  egaYellow = 14;
  egaWhite = 15;

  rgbEgaBlack: TRgbColor = (Red: $00; Green: $00; Blue: $00);
  rgbEgaBlue: TRgbColor = (Red: $00; Green: $00; Blue: $AA);
  rgbEgaGreen: TRgbColor = (Red: $00; Green: $AA; Blue: $00);
  rgbEgaCyan: TRgbColor = (Red: $00; Green: $AA; Blue: $AA);
  rgbEgaRed: TRgbColor = (Red: $AA; Green: $00; Blue: $00);
  rgbEgaMagenta: TRgbColor = (Red: $AA; Green: $00; Blue: $AA);
  rgbEgaBrown: TRgbColor = (Red: $AA; Green: $55; Blue: $00);
  rgbEgaLightGray: TRgbColor = (Red: $AA; Green: $AA; Blue: $AA);
  rgbEgaDarkGray: TRgbColor = (Red: $55; Green: $55; Blue: $55);
  rgbEgaLightBlue: TRgbColor = (Red: $55; Green: $55; Blue: $FF);
  rgbEgaLightGreen: TRgbColor = (Red: $55; Green: $FF; Blue: $55);
  rgbEgaLightCyan: TRgbColor = (Red: $55; Green: $FF; Blue: $FF);
  rgbEgaLightRed: TRgbColor = (Red: $FF; Green: $55; Blue: $55);
  rgbEgaLightMagenta: TRgbColor = (Red: $FF; Green: $55; Blue: $FF);
  rgbEgaYellow: TRgbColor = (Red: $FF; Green: $FF; Blue: $55);
  rgbEgaWhite: TRgbColor = (Red: $FF; Green: $FF; Blue: $FF);

  MinIntensity: byte = 0;
  MaxIntensity: byte = 15;
  Intensity50: byte = 7;
  Intensity25: byte = 3;
  Intensity75: byte = 11;
  PaletteAnimationStart: byte = 224;
  PaletteAnimationEnd: byte = 254;
  TransparentColor: byte = 255;

function GetStandardPalette: PRgbPaletteData; far;

implementation

function GetStandardPalette: PRgbPaletteData;
var
  colorIndex: TStandardColor;
  shadeIndex, shade: integer;
  paletteIndex: integer;
  index: integer;
  newPalette: PRgbPaletteData;
  color: PRgbColor;
begin
  New(newPalette);
  FillChar(newPalette^, SizeOf(TRgbPaletteData), 0);

  { Standard EGA colors }
  newPalette^[0] := rgbEgaBlack;
  newPalette^[1] := rgbEgaBlue;
  newPalette^[2] := rgbEgaGreen;
  newPalette^[3] := rgbEgaCyan;
  newPalette^[4] := rgbEgaRed;
  newPalette^[5] := rgbEgaMagenta;
  newPalette^[6] := rgbEgaBrown;
  newPalette^[7] := rgbEgaLightGray;
  newPalette^[8] := rgbEgaDarkGray;
  newPalette^[9] := rgbEgaLightBlue;
  newPalette^[10] := rgbEgaLightGreen;
  newPalette^[11] := rgbEgaLightCyan;
  newPalette^[12] := rgbEgaLightRed;
  newPalette^[13] := rgbEgaLightMagenta;
  newPalette^[14] := rgbEgaYellow;
  newPalette^[15] := rgbEgaWhite;
  paletteIndex := 16;

  for colorIndex := scWhite to High(TStandardColor) do begin
    for shadeIndex := 1 to 16 do begin
      shade := shadeIndex * 16 - 1;
      case colorIndex of
        scWhite: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scRed: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := 0;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scGreen: begin
          newPalette^[paletteIndex].Red := 0;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scBlue: begin
          newPalette^[paletteIndex].Red := 0;
          newPalette^[paletteIndex].Green := 0;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scYellow: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scMagenta: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := 0;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scCyan: begin
          newPalette^[paletteIndex].Red := 0;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scOrange: begin
          newPalette^[paletteIndex].Red := shade;
          newPalette^[paletteIndex].Green := shade div 2;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scBrown: begin
          newPalette^[paletteIndex].Red := Round(shade / 1.7);
          newPalette^[paletteIndex].Green := shade div 2;
          newPalette^[paletteIndex].Blue := 0;
        end;
        scSpringGreen: begin
          newPalette^[paletteIndex].Red := shade div 2;
          newPalette^[paletteIndex].Green := shade;
          newPalette^[paletteIndex].Blue := shade div 2;
        end;
        scAzure: begin
          newPalette^[paletteIndex].Red := shade div 3;
          newPalette^[paletteIndex].Green := shade div 3;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scViolet: begin
          newPalette^[paletteIndex].Red := shade div 2;
          newPalette^[paletteIndex].Green := 0;
          newPalette^[paletteIndex].Blue := shade;
        end;
        scFleshTone: begin
          newPalette^[paletteIndex].Red := 215 - Round((shadeIndex / 18) * 115);
          newPalette^[paletteIndex].Green := 190 - Round((shadeIndex / 18) * 135);
          newPalette^[paletteIndex].Blue := 140 - Round((shadeIndex / 18) * 135);
        end;
      end;
      Inc(paletteIndex);
    end;
  end;

  GetStandardPalette := newPalette;
end;

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

procedure TRgbColorList.ForEach(AProc: PRgbColorListProc);
begin
  TList.ForEach(PListProc(AProc));
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
  FFormat := pfApl;
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
    pfGimp: writer := New(PGimpPaletteWriter, Create(AStream));
    pfJasc: writer := New(PJascPaletteWriter, Create(AStream));
    pfApl: writer := New(PAplPaletteWriter, Create(AStream));
    else begin
      Raise(ecUnsupportedPaletteFormat);
      exit;
    end;
  end;
  SaveToStreamWriter(writer);
  FreeAndNil(writer);
end;

procedure TRgbPalette.SaveToStreamWriter(AWriter: PPaletteWriter);
begin
  AWriter^.WritePalette(FColors);
  if AWriter^.HasException then
    Raise(AWriter^.Exception^.Code);
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
  case AFormat of
    pfGimp: reader := New(PGimpPaletteReader, Create(AStream));
    pfJasc: reader := New(PJascPaletteReader, Create(AStream));
    else begin
      Raise(ecUnsupportedPaletteFormat);
      exit;
    end;
  end;
  LoadFromStreamReader(reader);
  FreeAndNil(reader);
end;

procedure TRgbPalette.LoadFromStreamReader(AReader: PPaletteReader);
begin
  FreeAndNil(FColors);
  FColors := AReader^.ReadPalette;
  if AReader^.HasException then
    Raise(AReader^.Exception^.Code);
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

constructor TPaletteWriter.Create(AStream: PStream);
begin
  inherited Create;
  FStream := AStream;
end;

procedure TPaletteWriter.WriteLine(ALine: string);
var
  buffer: string;
begin
  buffer := ALine + #13#10;
  FStream^.Write(@buffer[1], Length(buffer));
  if FStream^.HasException then
    Raise(FStream^.Exception^.Code);
end;

procedure TPaletteWriter.SetStream(AStream: PStream);
begin
  FStream := AStream;
end;

procedure TPaletteWriter.WritePalette(APalette: PRgbColorList);
begin
  Abstract;
end;

function TPaletteReader.Format: TPaletteFormat;
begin
  Format := pfNone;
end;

procedure TPaletteReader.SetStream(AStream: PStream);
begin
  FStream := AStream;
end;

constructor TPaletteReader.Create(AStream: PStream);
begin
  inherited Create;
  FStream := AStream;
end;

function TPaletteReader.ReadPalette: PRgbColorList;
begin
  Abstract;
end;

function TPaletteReader.ReadLine: string;
var
  buffer: string;
  ch: char;
begin
  buffer := '';
  while not FStream^.EndOfStream do begin
    ch := Char(FStream^.ReadByte);
    if FStream^.HasException then
      Raise(FStream^.Exception^.Code);
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

procedure TGimpPaletteWriter.WritePalette(APalette: PRgbColorList);
var
  index: integer;
  color: PRgbColor;
begin
  WriteLine('GIMP Palette');
  for index := 0 to APalette^.Count - 1 do begin
    color := APalette^.GetItem(index);
    WriteLine(
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

function TGimpPaletteReader.ReadPalette: PRgbColorList;
var
  line: string;
  color: TRgbColor;
  comment: boolean;
  result: PRgbColorList;
begin
  New(result, Create);
  while not FStream^.EndOfStream do begin
    line := ReadLine;
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

procedure TJascPaletteWriter.WritePalette(APalette: PRgbColorList);
var
  index: integer;
  color: PRgbColor;
begin
  WriteLine('JASC-PAL');
  WriteLine('0100');
  WriteLine(IntToStr(APalette^.Count));
  for index := 0 to APalette^.Count - 1 do begin
    color := APalette^.GetItem(index);
    WriteLine(
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

function TJascPaletteReader.ReadPalette: PRgbColorList;
var
  line: string;
  color: TRgbColor;
  result: PRgbColorList;
  count: integer;
begin
  New(result, Create);
  line := ReadLine;
  if line <> 'JASC-PAL' then begin
    Raise(ecInvalidPalette);
    exit;
  end;
  line := ReadLine;
  if line <> '0100' then begin
    Raise(ecInvalidPalette);
    exit;
  end;
  line := ReadLine;
  count := StrToInt(line, 0);
  if FStream^.HasException then begin
    Raise(FStream^.Exception^.Code);
    exit;
  end;
  while not FStream^.EndOfStream do begin
    line := ReadLine;
    if FStream^.HasException then begin
      Raise(FStream^.Exception^.Code);
      exit;
    end;
    {// Change this to not read padding for each color component}
    color.Red := StrToInt(Trim(Copy(line, 1, 3)), 0);
    color.Green := StrToInt(Trim(Copy(line, 5, 3)), 0);
    color.Blue := StrToInt(Trim(Copy(line, 9, 3)), 0);
    result^.Add(New(PRgbColor));
  end;
  ReadPalette := result;
end;

function TAplPaletteReader.Format: TPaletteFormat;
begin
  Format := pfApl;
end;

function TAplPaletteReader.ReadPalette: PRgbColorList;
var
  line: string;
  color: PRgbColor;
  result: PRgbColorList;
  count: word;
  index: word;
begin
  New(result, Create);
  count := FStream^.ReadWord;
  if FStream^.HasException then begin
    Raise(FStream^.Exception^.Code);
    exit;
  end;
  for index := 0 to count - 1 do begin
    color := New(PRgbColor);
    FStream^.Read(PByte(color), SizeOf(TRgbColor));
    if CheckReraise(FStream) then
      exit;
    result^.Add(color);
  end;
end;

function TAplPaletteWriter.Format: TPaletteFormat;
begin
  Format := pfApl;
end;

procedure TAplPaletteWriter.WritePalette(APalette: PRgbColorList);
var
  index: integer;
  color: PRgbColor;
begin
  FStream^.WriteWord(APalette^.Count);
  if FStream^.HasException then begin
    Raise(FStream^.Exception^.Code);
    exit;
  end;
  for index := 0 to APalette^.Count - 1 do begin
    color := APalette^.Items^[index];
    FStream^.Write(PByte(color), SizeOf(TRgbColor));
    if CheckReraise(FStream) then
      exit;
  end;
end;

end.