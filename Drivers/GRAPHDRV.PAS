{$I COMPILER.INC}
unit GraphDrv;

interface

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  Objects,
  Errors,
  Common,
  Streams,
  Drawing,
  Lists,
  AplConst,
  StrUtils,
  MemDrv;

const
  FontMajorVersion = 1;
  FontMinorVersion = 0;

type
  PGraphicsMode = ^TGraphicsMode;
  PGraphicsDriver = ^TGraphicsDriver;
  PGraphicsModeList = ^TGraphicsModeList;
  PFont = ^TFont;
  PFontList = ^TFontList;
  PGraphicsState = ^TGraphicsState;
  PSystemFont = ^TSystemFont;
  PMonospaceFont = ^TMonospaceFont;
  PProportionalFont = ^TProportionalFont;

  TFontWidthArray = array[byte] of word;
  TFontCompression = (fcNone, fcLzw);

  TGraphicsMode = object(TIdentifiable)
  private
  public
    Description: PChar;
    Width, Height: integer;
    MaxX, MaxY: integer;
    Bounds: TRect;
    Bpp: byte;
    HelpText: PChar;
    ModeIndex: word;
    BytesPerScanLine: word;
    FrameBuffer: pointer;
    NumPages: byte;
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TGraphicsModeList = object(TIdentifiableList)
  public
    function IndexOf(AItem: PGraphicsMode): integer;
    function GetItemById(const AId: string): PGraphicsMode;
    function IndexOfId(const AId: string): integer;
    function Add(AItem: PGraphicsMode): integer;
    function GetItem(AIndex: integer): PGraphicsMode;
    procedure Insert(AIndex: integer; AItem: PGraphicsMode);
  end;

  TFontHeader = record
    MajorVersion: integer;
    MinorVersion: integer;
    Name: string[50];
    DataSize: longint;
    MaxWidth: byte;
    Height: byte;
    Compression: TFontCompression;
    Spacing: byte;
    Reserved: array[0..254] of byte;
  end;

  TFont = object(TExceptionObject)
  private
    FFontData: PWord;
    FFontDataSize: word;
  public
    Version: real;
    TransparentColor: longint;
    Transparent: boolean;
    Height: byte;
    MaxWidth: byte;
    AverageWidth: integer;
    Spacing: byte;
    destructor Free; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
    procedure SaveToStream(AStream: PStream); virtual;
    procedure SaveToFile(const AFilename: string); virtual;
    procedure LoadFromStream(AStream: PStream); virtual;
    procedure LoadFromFile(const AFilename: string); virtual;
    function CharWidth(AChar: char): integer; virtual;
    function TextWidthAny(AText: PChar; ALength: word): longint; virtual;
    function TextWidth(const AText: string): longint; virtual;
    function TextWidthLarge(AText: PChar): longint; virtual;
    function Proportional: boolean; virtual;
    function FontData: PWord; virtual;
    function FontDataSize: word; virtual;
  end;

  TMonospaceFont = object(TFont)
  private
  public
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    destructor Free; virtual;
  end;

  TProportionalFont = object(TFont)
  private
  public
    CharWidths: TByteArray;
    constructor CreateSize(AMaxWidth, AHeight: byte);
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure SaveToStream(AStream: PStream); virtual;
    procedure SaveToFile(const AFilename: string); virtual;
    procedure LoadFromStream(AStream: PStream); virtual;
    procedure LoadFromFile(const AFilename: string); virtual;
    procedure SetCharWidths; virtual;
    function TextWidthAny(AText: PChar; ALength: word): longint; virtual;
    function CharWidth(AChar: char): integer; virtual;
    function Proportional: boolean; virtual;
    destructor Free; virtual;
  end;

  TSystemFont = object(TMonospaceFont)
  private
  public
    function CharWidth(AChar: char): integer; virtual;
    function TextWidthAny(AText: PChar; ALength: word): longint; virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TGraphicsState = object(TObject)
  private
  public
    ForeColor: longint;
    BackColor: longint;
    XPos, YPos: integer;
    Font: PFont;
    ViewPort: TRect;
    FrameBuffer: PByte;
    BufferMode: boolean;
    Region: PRegion;
    RegionMode: TRegionMode;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TGraphicsDriver = object(TExceptionObject)
  private
    FOldMode: byte;
  public
    State: TGraphicsState;
    StateStack: TObjectStack;
    Modes: TGraphicsModeList;
    Mode: PGraphicsMode;
    function GetPixel(AX, AY: integer): byte; virtual;
    function ForeColor: longint; virtual;
    function BackColor: longint; virtual;
    function XPos: byte; virtual;
    function YPos: byte; virtual;
    function GetScreenPointer(AX, AY: integer; var AOffset: longint): PByte; virtual;
    function GetBufferPointer(AX, AY: integer; var AOffset: longint): PByte; virtual;
    function GetDrawPointer(AX, AY: integer; var AOffset: longint): PByte;
    procedure BeginDrawBuffer(var ABuffer: PByte; var ABounds: TRect); virtual;
    procedure GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte); virtual;
    procedure GetImageRect(ARect: TRect; ABuffer: PByte); virtual;
    procedure GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream); virtual;
    procedure GetImageStreamRect(ARect: TRect; AStream: PStream); virtual;
    procedure SetForeColor(AColor: longint); virtual;
    procedure SetBackColor(AColor: longint); virtual;
    procedure SetMode(AMode: PGraphicsMode); virtual;
    procedure SetPixel(AX, AY: integer); virtual;
    procedure MoveTo(AX, AY: integer); virtual;
    procedure LineTo(AX, AY: integer); virtual;
    procedure Line(AX1, AY1, AX2, AY2: integer); virtual;
    procedure HLine(AX, AY, AWidth: integer); virtual;
    procedure VLine(AX, AY, AHeight: integer); virtual;
    procedure Rectangle(ARect: TRect); virtual;
    procedure FillRect(ARect: TRect); virtual;
    procedure RenderText(AX, AY, ALength: integer; AText: PChar); virtual;
    procedure DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte); virtual;
    procedure DrawImageRect(ARect: TRect; AImage: PByte); virtual;
    procedure DrawImageRectT(ARect: TRect; AImage: PByte); virtual;
    procedure DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamRect(ARect: TRect; AStream: PStream); virtual;
    procedure DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream); virtual;
    procedure DrawImageStreamRectT(ARect: TRect; AStream: PStream); virtual;
    procedure DrawImageStreamSection(ASourceRect: TRect; ADestX, ADestY: integer); virtual;
    procedure DrawImageStreamSectionT(ASourceRect: TRect; ADestX, ADestY: integer); virtual;
    procedure DrawText(AX, AY: integer; AText: string); virtual;
    procedure DrawTextLarge(AX, AY: integer; AText: PChar); virtual;
    procedure GetImageDrawRects(AX, AY, AWidth, AHeight: longint;
      var AImageRect, ADrawRect: TRect); virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure EndDrawBuffer; virtual;
    procedure Init; virtual;
    procedure WaitForVSync; virtual;
    procedure ResetMode; virtual;
    destructor Free; virtual;
  end;

  TFontList = Object(TIdentifiableList)
  public
    function ToString: string; virtual;
    function IndexOf(AItem: PFont): integer;
    function GetItemById(AId: string): PFont;
    function GetItem(AIndex: integer): PFont;
    function Add(AItem: PFont): integer;
    procedure Init; virtual;
    procedure Insert(AIndex: integer; AItem: PFont);
  end;

var
  Graph: PGraphicsDriver;

implementation

uses
  Compress,
  Lzw;

var
  PreviousExitProc: PProc;

procedure TGraphicsDriver.Init;
var
  oldMode: byte;
begin
  inherited Init;
  asm
    mov ah, 0Fh
    int 10h
    mov [oldMode], al
  end;
  FOldMode := oldMode;
  Modes.Create;
  Mode := nil;
  State.Create;
  StateStack.Create;
  MoveTo(0, 0);
end;

procedure TGraphicsDriver.RenderText(AX, AY, ALength: integer; AText: PChar);
begin
end;

function TGraphicsDriver.GetScreenPointer(AX, AY: integer; var AOffset: longint): PByte;
begin
end;

function TGraphicsDriver.GetBufferPointer(AX, AY: integer; var AOffset: longint): PByte;
var
  screen: PByte;
begin
  screen := State.FrameBuffer;
  AOffset := longint(AY) * State.ViewPort.Width + AX;
  Inc(screen, AOffset);
  GetBufferPointer := screen;
end;

function TGraphicsDriver.GetDrawPointer(AX, AY: integer; var AOffset: longint): PByte;
begin
  if State.BufferMode then
    GetDrawPointer := GetBufferPointer(AX, AY, AOffset)
  else
    GetDrawPointer := GetScreenPointer(AX, AY, AOffset);
end;

function TGraphicsDriver.ForeColor: longint;
begin
  ForeColor := State.ForeColor;
end;

function TGraphicsDriver.BackColor: longint;
begin
  BackColor := State.BackColor;
end;

function TGraphicsDriver.XPos: byte;
begin
  XPos := State.XPos;
end;

function TGraphicsDriver.YPos: byte;
begin
  YPos := State.YPos;
end;

procedure TGraphicsDriver.SetForeColor(AColor: longint);
begin
  State.ForeColor := AColor;
end;

procedure TGraphicsDriver.SetBackColor(AColor: longint);
begin
  State.BackColor := AColor;
end;

function TGraphicsDriver.GetPixel(AX, AY: integer): byte;
begin
end;

procedure TGraphicsDriver.ResetMode;
var
  oldMode: byte;
begin
  oldMode := FOldMode;
  asm
    mov ah, 0
    mov al, [oldMode]
    int 10h
  end;
end;

procedure TGraphicsDriver.SetMode(AMode: PGraphicsMode);
begin
  Mode := AMode;
  State.ViewPort.SetDims(0, 0, Mode^.Width, Mode^.Height);
  Mode^.Bounds.SetRect(State.ViewPort);
end;

procedure TGraphicsDriver.SetPixel(AX, AY: integer);
begin
end;

procedure TGraphicsDriver.MoveTo(AX, AY: integer);
begin
  State.XPos := AX;
  State.YPos := AY;
end;

procedure TGraphicsDriver.LineTo(AX, AY: integer);
begin
  Line(State.XPos, State.YPos, AX, AY);
  State.XPos := AX;
  State.YPos := AY;
end;

procedure TGraphicsDriver.Line(AX1, AY1, AX2, AY2: integer);
begin
end;

procedure TGraphicsDriver.Rectangle(ARect: TRect);
begin
  HLine(ARect.X, ARect.Y, ARect.Width);
  HLine(ARect.X, ARect.Bottom, ARect.Width);
  VLine(ARect.X, ARect.Y, ARect.Height);
  VLine(ARect.Right, ARect.Y, ARect.Height);
end;

procedure TGraphicsDriver.HLine(AX, AY, AWidth: integer);
begin
end;

procedure TGraphicsDriver.VLine(AX, AY, AHeight: integer);
begin
end;

procedure TGraphicsDriver.FillRect(ARect: TRect);
var
  index: integer;
  tempColor: longint;
  rect: PRect;
begin
  tempColor := State.ForeColor;
  State.ForeColor := State.BackColor;
  if ARect.IsEmpty then
    exit;
  for index := ARect.Y to ARect.Bottom do
    HLine(ARect.X, index, ARect.Width);
  State.ForeColor := tempColor;
end;

procedure TGraphicsDriver.DrawText(AX, AY: integer; AText: string);
var
  ptr: PChar;
begin
  if not Assigned(State.Font) then
    exit;
  if Length(AText) = 0 then
    exit;
  ptr := @AText[1];
  RenderText(AX, AY, Length(AText), ptr);
end;

procedure TGraphicsDriver.DrawTextLarge(AX, AY: integer; AText: PChar);
var
  len: word;
begin
  if not Assigned(State.Font) then
    exit;
  if not Assigned(AText) then
    exit;
  len := StrLen(AText);
  if len = 0 then
    exit;
  RenderText(AX, AY, len, AText);
end;

procedure TGraphicsDriver.GetImage(AX, AY, AWidth, AHeight: longint; ABuffer: PByte);
begin
end;

procedure TGraphicsDriver.GetImageRect(ARect: TRect; ABuffer: PByte);
begin
  GetImage(ARect.X, ARect.Y, ARect.Width, ARect.Height, ABuffer);
end;

procedure TGraphicsDriver.GetImageStream(AX, AY, AWidth, AHeight: longint; AStream: PStream);
begin
end;

procedure TGraphicsDriver.GetImageStreamRect(ARect: TRect; AStream: PStream);
begin
  GetImageStream(ARect.X, ARect.Y, ARect.Width, ARect.Height, AStream);
end;

procedure TGraphicsDriver.DrawImage(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TGraphicsDriver.DrawImageT(AX, AY, AWidth, AHeight: integer; AImage: PByte);
begin
end;

procedure TGraphicsDriver.DrawImageRectT(ARect: TRect; AImage: PByte);
begin
  DrawImageT(ARect.X, ARect.Y, ARect.Width, ARect.Height, AImage);
end;

procedure TGraphicsDriver.DrawImageRect(ARect: TRect; AImage: PByte);
begin
  DrawImage(ARect.X, ARect.Y, ARect.Width, ARect.Height, AImage);
end;

procedure TGraphicsDriver.DrawImageStream(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TGraphicsDriver.DrawImageStreamRect(ARect: TRect; AStream: PStream);
begin
  DrawImageStream(ARect.X, ARect.Y, ARect.Width, ARect.Height, AStream);
end;

procedure TGraphicsDriver.DrawImageStreamT(AX, AY, AWidth, AHeight: integer; AStream: PStream);
begin
end;

procedure TGraphicsDriver.DrawImageStreamRectT(ARect: TRect; AStream: PStream);
begin
  DrawImageStreamT(ARect.X, ARect.Y, ARect.Width, ARect.Height, AStream);
end;

procedure TGraphicsDriver.DrawImageStreamSection(ASourceRect: TRect; ADestX, ADestY: integer);
begin
end;

procedure TGraphicsDriver.DrawImageStreamSectionT(ASourceRect: TRect; ADestX, ADestY: integer);
begin
end;

procedure TGraphicsDriver.GetImageDrawRects(AX, AY, AWidth, AHeight: longint;
  var AImageRect, ADrawRect: TRect);
begin
  AImageRect.CreateDims(AX, AY, AWidth, AHeight);
  Mode^.Bounds.GetIntersection(State.ViewPort, ADrawRect);
  ADrawRect.Intersect(AImageRect);
  AImageRect.X := ADrawRect.X - AImageRect.X;
  AImageRect.Y := ADrawRect.Y - AImageRect.Y;
end;

procedure TGraphicsDriver.PushState;
var
  newState: PGraphicsState;
begin
  newState := New(PGraphicsState, Create);
  newState^.Assign(State);
  StateStack.Push(newState);
end;

procedure TGraphicsDriver.BeginDrawBuffer(var ABuffer: PByte; var ABounds: TRect);
var
  size: word;
begin
  size := ABounds.Width * ABounds.Height;
  GetMem(ABuffer, size);
  if not Assigned(ABuffer) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  ABounds.TranslateToOrigin;
  State.FrameBuffer := ABuffer;
  State.ViewPort.Assign(ABounds);
  State.BufferMode := true;
end;

procedure TGraphicsDriver.EndDrawBuffer;
begin
  State.BufferMode := false;
  State.FrameBuffer := Mode^.FrameBuffer;
end;

procedure TGraphicsDriver.PopState;
var
  oldState: PGraphicsState;
begin
  oldState := PGraphicsState(StateStack.Pop);
  if not Assigned(oldState) then
    exit;
  State.Assign(oldState^);
  FreeAndNil(oldState);
end;

destructor TGraphicsDriver.Free;
begin
  ResetMode;
  Modes.Free;
  State.Free;
  StateStack.DisposeObjects := true;
  StateStack.Free;
  inherited Free;
end;

procedure TGraphicsDriver.WaitForVSync;
begin
end;

procedure TGraphicsMode.Init;
begin
  inherited Init;
  Width := 0;
  Height := 0;
  MaxX := 0;
  MaxY := 0;
  Bpp := 0;
  NumPages := 1;
  Bounds.Create;
  ModeIndex := 0;
  BytesPerScanLine := 0;
  HelpText := nil;
  Description := nil;
  FrameBuffer := nil;
  HelpText := nil;
end;

destructor TGraphicsMode.Free;
begin
  TString.Free(HelpText);
  TString.Free(Description);
  inherited Free;
end;

procedure TGraphicsMode.Assign(var ASource: TObject);
var
  mode: PGraphicsMode;
begin
  inherited Assign(ASource);
  mode := PGraphicsMode(@ASource);
  Width := mode^.Width;
  Height := mode^.Height;
  NumPages := mode^.NumPages;
  MaxX := mode^.MaxX;
  MaxY := mode^.MaxY;
  Bounds.SetRect(mode^.Bounds);
  Bpp := mode^.Bpp;
  ModeIndex := mode^.ModeIndex;
  TString.Free(Description);
  TString.Free(HelpText);
  TString.Free(Id);
  Description := TString.Copy(mode^.Description);
  HelpText:= TString.Copy(mode^.HelpText);
  BytesPerScanLine := mode^.BytesPerScanLine;
  FrameBuffer := mode^.FrameBuffer;
end;

function TGraphicsModeList.GetItem(AIndex: integer): PGraphicsMode;
begin
  GetItem := PGraphicsMode(inherited GetItem(AIndex));
end;

function TGraphicsModeList.GetItemById(const AId: string): PGraphicsMode;
begin
  GetItemById := PGraphicsMode(inherited GetItemById(AId));
end;

function TGraphicsModeList.IndexOfId(const AId: string): integer;
begin
  IndexOfId := inherited IndexOfId(AId);
end;

function TGraphicsModeList.IndexOf(AItem: PGraphicsMode): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TGraphicsModeList.Add(AItem: PGraphicsMode): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TGraphicsModeList.Insert(AIndex: integer; AItem: PGraphicsMode);
begin
  inherited Insert(AIndex, AItem);
end;

destructor TFont.Free;
begin
  if Assigned(FFontData) then
    FreeMem(FFontData, FFontDataSize);
  inherited Free;
end;

procedure TFont.Assign(var ASource: TObject);
var
  source: PFont;
begin
  inherited Assign(ASource);
  source := PFont(@ASource);
  Version := source^.Version;
  TransparentColor := source^.TransparentColor;
  Transparent := source^.Transparent;
  Height := source^.Height;
  MaxWidth := source^.MaxWidth;
  if Assigned(FFontData) then
    FreeMem(FFontData, FFontDataSize);
  FFontDataSize := source^.FFontDataSize;
  GetMem(FFontData, source^.FFontDataSize);
  Move(source^.FFontData^, FFontData^, source^.FFontDataSize);
end;

procedure TFont.Init;
begin
  inherited Init;
  Version := 1.0;
  TransparentColor := 0;
  Transparent := true;
  Height := 0;
  AverageWidth := 0;
  MaxWidth := 0;
  FFontData := nil;
  FFontDataSize := 0;
  Spacing := 2;
end;

function TFont.Proportional: boolean;
begin
  Proportional := false;
end;

function TFont.CharWidth(AChar: char): integer;
begin
end;

function TFont.TextWidthAny(AText: PChar; ALength: word): longint;
begin
end;

function TFont.TextWidth(const AText: string): longint;
var
  textPtr: PChar;
begin
  TextWidth := 0;
  if Length(AText) = 0 then
    exit;
  textPtr := @AText[1];
  TextWidth := TextWidthAny(textPtr, Length(AText));
end;

function TFont.TextWidthLarge(AText: PChar): longint;
begin
  TextWidthLarge := TextWidthAny(AText, StrLen(AText));
end;

function TFont.FontData: PWord;
begin
  FontData := FFontData;
end;

function TFont.FontDataSize: word;
begin
  FontDataSize := FFontDataSize;
end;

procedure TFont.SaveToStream(AStream: PStream);
begin
end;

procedure TFont.SaveToFile(const AFilename: string);
begin
end;

procedure TFont.LoadFromStream(AStream: PStream);
begin
end;

procedure TFont.LoadFromFile(const AFilename: string);
begin
end;

procedure TMonospaceFont.Init;
begin
  inherited Init;
  MaxWidth := 8;
  AverageWidth := 8;
end;

destructor TMonospaceFont.Free;
begin
  inherited Free;
end;

procedure TMonospaceFont.Assign(var ASource: TObject);
var
  source: PMonospaceFont;
begin
  inherited Assign(ASource);
  source := PMonospaceFont(@ASource);
end;

constructor TProportionalFont.CreateSize(AMaxWidth, AHeight: byte);
begin
  inherited Create;
  MaxWidth := AMaxWidth;
  Height := AHeight;
  FillChar(CharWidths, SizeOf(CharWidths), MaxWidth);
  FFontDataSize := Height * 256 * 2;
  GetMem(FFontData, FontDataSize);
  FillChar(FFontData^, FontDataSize, 0);
end;

procedure TProportionalFont.Init;
begin
  inherited Init;
  MaxWidth := 8;
  AverageWidth := 0;
  FillChar(CharWidths, SizeOf(CharWidths), 0);
end;

function TProportionalFont.Proportional: boolean;
begin
  Proportional := true;
end;

destructor TProportionalFont.Free;
begin
  inherited Free;
end;

function TProportionalFont.TextWidthAny(AText: PChar; ALength: word): longint;
var
  index: word;
  total: longint;
  ptr: PChar;
begin
  total := 0;
  ptr := AText;
  for index := 1 to ALength do begin
    Inc(total, CharWidths[Ord(ptr^)]);
    Inc(ptr);
  end;
  TextWidthAny := total;
end;

procedure TProportionalFont.Assign(var ASource: TObject);
var
  source: PProportionalFont;
begin
  inherited Assign(ASource);
  source := PProportionalFont(@ASource);
  CharWidths := source^.CharWidths;
end;

function TProportionalFont.CharWidth(AChar: char): integer;
begin
  CharWidth := CharWidths[Ord(AChar)];
end;

procedure TProportionalFont.SetCharWidths;
var
  charIndex, xIndex, yIndex: integer;
  linePtr: PWord;
  total: integer;
  avgCount: integer;
  avgTotal: integer;
  width: word;
begin
  total := 0;
  avgCount := 0;
  avgTotal := 0;
  for charIndex := 0 to High(byte) do begin
    width := 0;
    linePtr := FFontData;
    Inc(linePtr, charIndex * Height);
    for yIndex := 0 to Height - 1 do begin
      for xIndex := 0 to MaxWidth - 1 do begin
        if (linePtr^ and (32768 shr xIndex)) > 0 then
          width := MaxWord(xIndex + 1, width);
      end;
      Inc(linePtr);
    end;
    if width = 0 then
      width := MaxWidth
    else begin
      Inc(AvgTotal);
      Inc(AvgCount, width + Spacing);
    end;
    Inc(width, Spacing);
    CharWidths[charIndex] := width;
    Inc(total, width);
  end;
  if AvgTotal = 0 then
    AverageWidth := MaxWidth
  else
    AverageWidth := Round(avgCount / avgTotal);
  CharWidths[32] := Trunc(total / High(byte)) div 2;
  CharWidths[0] := CharWidths[32];
end;

procedure TProportionalFont.SaveToStream(AStream: PStream);
var
  header: TFontHeader;
  lzw: TLzw;
  stream: TMemoryStream;
begin
  lzw.CreateBitSize(13);
  FillChar(header, SizeOf(header), 0);
  header.MajorVersion := FontMajorVersion;
  header.MinorVersion := FontMinorVersion;
  header.Name := GetId;
  header.DataSize := FFontDataSize;
  header.MaxWidth := MaxWidth;
  header.Height := Height;
  header.Compression := fcLzw;
  header.Spacing := Spacing;

  SetCharWidths;

  stream.Create(FFontDataSize);
  stream.Write(PByte(FFontData), FFontDataSize);
  stream.Seek(0, soFromBeginning);
  if stream.HasException then
    Raise(stream.Exception^.Code)
  else begin
    AStream^.Write(@header, SizeOf(header));
    if AStream^.HasException then
      Raise(AStream^.Exception^.Code)
    else begin
      lzw.CompressStream(@stream, AStream, FFontDataSize);
      if lzw.HasException then
        Raise(lzw.Exception^.Code);
      lzw.Free;
    end;
  end;
  stream.Free;
end;

procedure TProportionalFont.SaveToFile(const AFilename: string);
var
  fileStream: TFileStream;
begin
  fileStream.Create(AFilename, fmWrite);
  SaveToStream(@fileStream);
  fileStream.Free;
end;

procedure TProportionalFont.LoadFromStream(AStream: PStream);
var
  header: TFontHeader;
  stream: TMemoryStream;
  lzw: TLzw;
  index: integer;
  lineIndex: integer;
  ptr: PByte;
begin
  AStream^.Read(@header, SizeOf(header));
  if AStream^.HasException then begin
    Raise(AStream^.Exception^.Code);
    exit;
  end;
  if (header.MajorVersion > FontMajorVersion) or (header.MinorVersion > FontMinorVersion) then begin
    Raise(ecFontVersionNotSupported);
    exit;
  end;
  if Assigned(FFontData) then
    FreeMem(FFontData, FontDataSize);
  GetMem(FFontData, header.DataSize);
  if not Assigned(FFontData) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  FFontDataSize := header.DataSize;
  SetId(header.Name);
  stream.Create(header.DataSize);
  if stream.HasException then begin
    FreeMem(FFontData, header.DataSize);
    Raise(stream.Exception^.Code);
  end
  else begin
    case header.Compression of
      fcNone: begin
      end;
      fcLzw: begin
        lzw.CreateBitSize(13);
        lzw.DecompressStream(AStream, @stream);
        if lzw.HasException then
          Raise(lzw.Exception^.Code);
        lzw.Free;
        stream.Seek(0, soFromBeginning);
        stream.Read(PByte(FFontData), header.DataSize);
        if stream.HasException then
          Raise(stream.Exception^.Code)
        else begin
          Height := header.Height;
          Spacing := header.Spacing;
          MaxWidth := header.MaxWidth;
          SetCharWidths;
        end;
      end
      else
        Raise(ecFontCompressionNotSupported)
    end;
  end;
  stream.Free;
end;

procedure TProportionalFont.LoadFromFile(const AFilename: string);
var
  fileStream: TFileStream;
begin
  fileStream.Create(AFilename, fmRead);
  LoadFromStream(@fileStream);
  fileStream.Free;
end;

function TSystemFont.TextWidthAny(AText: PChar; ALength: word): longint;
begin
  if not Assigned(AText) then begin
    TextWidthAny := 0;
    exit;
  end;
  TextWidthAny := longint(ALength) * 8;
end;

procedure TSystemFont.Init;
var
  fontPtr: PByte;
  segm, offs: word;
  regs: Registers;
begin
  inherited Init;
  Id := TString.New('SystemFont');
  Height := 16;
  MaxWidth := 8;
  AverageWidth := 8;
  fontPtr := Ptr(segm, offs);
  regs.Ax := $1130;
  regs.Bh := $06;
  Intr($10, regs);
  fontPtr := Ptr(regs.Es, regs.Bp);
  FFontDataSize := 256 * Height;
  GetMem(FFontData, FFontDataSize);
  Move(fontPtr^, FFontData^, FFontDataSize);
end;

destructor TSystemFont.Free;
begin
  inherited Free;
end;

function TSystemFont.CharWidth(AChar: char): integer;
begin
  CharWidth := 8;
end;

procedure TGraphicsState.Init;
begin
  inherited Init;
  ForeColor := 0;
  BackColor := 0;
  XPos := 0;
  YPos := 0;
  Font := nil;
  ViewPort.Create;
  BufferMode := false;
  FrameBuffer := nil;
  Region := nil;
  RegionMode := rmInclude;
end;

procedure TGraphicsState.Assign(var ASource: TObject);
var
  state: PGraphicsState;
begin
  inherited Assign(ASource);
  state := PGraphicsState(@ASource);
  ForeColor := state^.ForeColor;
  BackColor := state^.BackColor;
  XPos := state^.XPos;
  YPos := state^.YPos;
  Font := state^.Font;
  FrameBuffer := state^.FrameBuffer;
  ViewPort.SetRect(state^.ViewPort);
  BufferMode := state^.BufferMode;
  Region := state^.Region;
  RegionMode := state^.RegionMode;
end;

function TFontList.ToString: string;
begin
  ToString := 'TFontList';
end;

function TFontList.GetItem(AIndex: integer): PFont;
begin
  GetItem := PFont(inherited GetItem(AIndex));
end;

function TFontList.GetItemById(AId: string): PFont;
begin
  GetItemById := PFont(inherited GetItemById(AId));
end;

function TFontList.IndexOf(AItem: PFont): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TFontList.Add(AItem: PFont): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TFontList.Init;
begin
  inherited init;
end;

procedure TFontList.Insert(AIndex: integer; AItem: PFont);
begin
  inherited Insert(AIndex, AItem);
end;

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  if Assigned(Graph) then
    FreeAndNil(Graph);
  WriteLn('Graphics driver uninstalled.');
end;

begin
  Graph := nil;
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
