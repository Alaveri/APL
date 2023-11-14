{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit GraphDrv;

interface

uses
  Objects,
  Except,
  Common,
  Drawing,
  Collects,
  Consts,
  StrUtils,
  MemDrv,
  Strings,
  Dos,
  Streams;

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

  TGraphicsMode = object(TIdentifiable)
  private
  public
    Description: PChar;
    Width, Height: integer;
    MaxX, MaxY: integer;
    Bounds: TRect;
    Bpp: byte;
    HelpText: PChar;
    AdditionalData: integer;
    Pitch: word;
    FrameBuffer: pointer;
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TGraphicsModeList = object(TIdentifiableList)
  public
    function GetItem(AIndex: integer): PGraphicsMode;
    function IndexOf(AItem: PGraphicsMode): integer;
    function GetItemById(const AId: string): PGraphicsMode;
    function IndexOfId(const AId: string): integer;
    function Add(AItem: PGraphicsMode): integer;
    procedure Insert(AIndex: integer; AItem: PGraphicsMode);
    function Where(APredicate: TPredicate; var AValue): PGraphicsModeList;
  end;

  TFontWidthArray = array[byte] of byte;
  TFontCompression = (fcNone, fcLzw);

  TFontHeader = record
    MajorVersion: integer;
    MinorVersion: integer;
    Name: string[50];
    DataSize: longint;
    MaxWidth: byte;
    Height: byte;
    Compression: TFontCompression;
    CharWidths: TFontWidthArray;
  end;

  TFont = object(TExceptionObject)
  private
    FFontData: PByte;
    FFontDataSize: word;
  public
    Version: real;
    TransparentColor: longint;
    Transparent: boolean;
    Initialized: boolean;
    Height: byte;
    MaxWidth: byte;
    destructor Free; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure Init; virtual;
    procedure SaveToStream(AStream: PStream); virtual;
    procedure SaveToFile(const AFilename: string); virtual;
    procedure LoadFromStream(AStream: PStream); virtual;
    procedure LoadFromFile(const AFilename: string); virtual;
    function CharWidth(AChar: char): integer; virtual;
    function TextWidth(AText: string): integer; virtual;
    function TextWidthLarge(AText: PChar): integer; virtual;
    function Proportional: boolean; virtual;
    function FontData: PByte; virtual;
    function FontDataSize: word; virtual;
  end;

  TMonospaceFont = object(TFont)
  private
  public
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    function TextWidth(AText: string): integer; virtual;
    function TextWidthLarge(AText: PChar): integer; virtual;
    destructor Free; virtual;
  end;

  TProportionalFont = object(TFont)
  private
  public
    CharWidths: TFontWidthArray;
    constructor CreateSize(AMaxWidth, AHeight: byte);
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure SaveToStream(AStream: PStream); virtual;
    procedure SaveToFile(const AFilename: string); virtual;
    procedure LoadFromStream(AStream: PStream); virtual;
    procedure LoadFromFile(const AFilename: string); virtual;
    procedure SetCharWidths; virtual;
    function TextWidth(AText: string): integer; virtual;
    function TextWidthLarge(AText: PChar): integer; virtual;
    function CharWidth(AChar: char): integer; virtual;
    function Proportional: boolean; virtual;
    destructor Free; virtual;
  end;

  TSystemFont = object(TMonospaceFont)
  private
  public
    function CharWidth(AChar: char): integer; virtual;
    function TextWidth(AText: string): integer; virtual;
    function TextWidthLarge(AText: PChar): integer; virtual;
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
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

  TGraphicsDriver = object(TExceptionObject)
  private
    FOldMode: byte;
  public
    State: PGraphicsState;
    StateStack: PStack;
    Modes: PGraphicsModeList;
    Mode: PGraphicsMode;
    function GetPixel(AX, AY: integer): byte; virtual;
    function ForeColor: longint; virtual;
    function BackColor: longint; virtual;
    function XPos: byte; virtual;
    function YPos: byte; virtual;
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
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure Init; virtual;
    procedure WaitForVSync; virtual;
    procedure ResetMode; virtual;
    destructor Free; virtual;
  end;

  TFontList = Object(TObjectList)
  public
    function ToString: string; virtual;
    function GetItem(AIndex: integer): PFont;
    function IndexOf(AItem: PFont): integer;
    function GetFont(AId: string): PFont;
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
  Modes := nil;
  Mode := nil;
  State := New(PGraphicsState, Create);
  StateStack := New(PStack, Create);
  MoveTo(0, 0);
end;

procedure TGraphicsDriver.RenderText(AX, AY, ALength: integer; AText: PChar);
begin
end;

function TGraphicsDriver.ForeColor: longint;
begin
  ForeColor := State^.ForeColor;
end;

function TGraphicsDriver.BackColor: longint;
begin
  BackColor := State^.BackColor;
end;

function TGraphicsDriver.XPos: byte;
begin
  XPos := State^.XPos;
end;

function TGraphicsDriver.YPos: byte;
begin
  YPos := State^.YPos;
end;

procedure TGraphicsDriver.SetForeColor(AColor: longint);
begin
  State^.ForeColor := AColor;
end;

procedure TGraphicsDriver.SetBackColor(AColor: longint);
begin
  State^.BackColor := AColor;
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
  State^.ViewPort.SetDims(0, 0, AMode^.Width, AMode^.Height);
  AMode^.Bounds.SetRect(State^.ViewPort);
end;

procedure TGraphicsDriver.SetPixel(AX, AY: integer);
begin
end;

procedure TGraphicsDriver.MoveTo(AX, AY: integer);
begin
  State^.XPos := AX;
  State^.YPos := AY;
end;

procedure TGraphicsDriver.LineTo(AX, AY: integer);
begin
  Line(State^.XPos, State^.YPos, AX, AY);
  State^.XPos := AX;
  State^.YPos := AY;
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
  drawRect: TRect;
  viewRect: TRect;
  tempColor: longint;
begin
  Mode^.Bounds.Intersection(State^.ViewPort, viewRect);
  viewRect.Intersection(ARect, drawRect);

  tempColor := State^.ForeColor;
  State^.ForeColor := State^.BackColor;
  if ARect.IsEmpty then
    exit;
  for index := drawRect.Y to drawRect.Bottom do
    HLine(drawRect.X, index, drawRect.Width);
  State^.ForeColor := tempColor;
end;

procedure TGraphicsDriver.DrawText(AX, AY: integer; AText: string);
var
  ptr: PChar;
begin
  if State^.Font = nil then
    exit;
  if Length(AText) = 0 then
    exit;
  ptr := @AText[1];
  RenderText(AX, AY, Length(AText), ptr);
end;

procedure TGraphicsDriver.DrawTextLarge(AX, AY: integer; AText: PChar);
begin
  if State^.Font = nil then
    exit;
  RenderText(AX, AY, StrLen(AText), AText);
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

procedure TGraphicsDriver.PushState;
var
  newState: PGraphicsState;
begin
  newState := New(PGraphicsState, Create);
  newState^.Assign(State^);
  StateStack^.Push(newState);
end;

procedure TGraphicsDriver.PopState;
var
  oldState: PGraphicsState;
begin
  oldState := PGraphicsState(StateStack^.Pop);
  if oldState = nil then
    exit;
  State^.Assign(oldState^);
  FreeAndNil(oldState);
end;

destructor TGraphicsDriver.Free;
begin
  ResetMode;
  FreeAndNil(Modes);
  FreeAndNil(State);
  StateStack^.DisposeObjects := true;
  FreeAndNil(StateStack);
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
  Bounds.Create;
  AdditionalData := -1;
  Pitch := 0;
  HelpText := nil;
  Description := nil;
  FrameBuffer := nil;
  HelpText := nil;
end;

destructor TGraphicsMode.Free;
begin
  DisposeLargeString(HelpText);
  DisposeLargeString(Description);
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
  MaxX := mode^.MaxX;
  MaxY := mode^.MaxY;
  Bounds.SetRect(mode^.Bounds);
  Bpp := mode^.Bpp;
  AdditionalData := mode^.AdditionalData;
  DisposeLargeString(Description);
  DisposeLargeString(HelpText);
  DisposeLargeString(Id);
  Description := CopyLargeString(mode^.Description);
  HelpText:= CopyLargeString(mode^.HelpText);
  Pitch := mode^.Pitch;
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

function TGraphicsModeList.Where(APredicate: TPredicate; var AValue): PGraphicsModeList;
begin
  Where := PGraphicsModeList(TList.Where(APredicate, AValue));
end;

destructor TFont.Free;
begin
  if FFontData <> nil then
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
  Initialized := source^.Initialized;
  Height := source^.Height;
  MaxWidth := source^.MaxWidth;
  if FFontData <> nil then
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
  Initialized := true;
  Height := 0;
  FFontData := nil;
  FFontDataSize := 0;
end;

function TFont.Proportional: boolean;
begin
  Proportional := false;
end;

function TFont.CharWidth(AChar: char): integer;
begin
end;

function TFont.TextWidth(AText: string): integer;
begin
end;

function TFont.TextWidthLarge(AText: PChar): integer;
begin
end;

function TFont.FontData: PByte;
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
end;

destructor TMonospaceFont.Free;
begin
  inherited Free;
end;

function TMonospaceFont.TextWidth(AText: string): integer;
begin
end;

function TMonospaceFont.TextWidthLarge(AText: PChar): integer;
begin
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
  FFontDataSize := Height * 256;
  GetMem(FFontData, FontDataSize);
  FillChar(FFontData^, FontDataSize, 0);
end;

procedure TProportionalFont.Init;
begin
  inherited Init;
  MaxWidth := 8;
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

function TProportionalFont.TextWidth(AText: string): integer;
var
  index: integer;
  total: integer;
begin
  total := 0;
  for index := 1 to Length(AText) do
    Inc(total, CharWidths[Ord(AText[index])]);
  TextWidth := total;
end;

function TProportionalFont.TextWidthLarge(AText: PChar): integer;
var
  index: integer;
  total: integer;
  ptr: PChar;
begin
  total := 0;
  ptr := AText;
  for index := 1 to StrLen(AText) do begin
    Inc(total, CharWidths[Ord(ptr^)]);
    Inc(ptr);
  end;
  TextWidthLarge := total;
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
  linePtr: PByte;
  total: integer;
  width: byte;
begin
  total := 0;
  for charIndex := 0 to High(byte) do begin
    width := 0;
    linePtr := FFontData;
    Inc(linePtr, charIndex * Height);
    for yIndex := 0 to Height - 1 do begin
      for xIndex := 0 to MaxWidth - 1 do begin
        if (linePtr^ and (128 shr xIndex)) > 0 then
          width := MaxW(xIndex + 1, width);
      end;
      Inc(linePtr);
    end;
    if width = 0 then
      width := MaxWidth;
    Inc(width, 2);
    CharWidths[charIndex] := width;
    Inc(total, width);
  end;
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
  header.MajorVersion := FontMajorVersion;
  header.MinorVersion := FontMinorVersion;
  header.Name := GetId;
  header.DataSize := FFontDataSize;
  header.MaxWidth := MaxWidth;
  header.Height := Height;
  header.CharWidths := CharWidths;
  header.Compression := fcLzw;

  SetCharWidths;
  header.CharWidths := CharWidths;

  stream.Create(FFontDataSize);
  stream.Write(FFontData, FFontDataSize);
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
  if FFontData <> nil then
    FreeMem(FFontData, FontDataSize);
  GetMem(FFontData, header.DataSize);
  if FFontData = nil then begin
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
        stream.Read(FFontData, header.DataSize);
        if stream.HasException then
          Raise(stream.Exception^.Code)
        else begin
          Height := header.Height;
          SetCharWidths;
          MaxWidth := header.MaxWidth;
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

function TSystemFont.TextWidth(AText: string): integer;
var
  width: integer;
begin
  width := Length(AText) * 8;
  TextWidth := width;
end;

function TSystemFont.TextWidthLarge(AText: PChar): integer;
var
  width: integer;
begin
  if AText = nil then begin
    TextWidthLarge := 0;
    exit;
  end;
  width := StrLen(AText) * 8;
  TextWidthLarge := width;
end;

procedure TSystemFont.Init;
var
  fontPtr: PByte;
  segm, offs: word;
  regs: Registers;
begin
  inherited Init;
  Id := NewLargeString('SystemFont');
  Height := 16;
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
  FrameBuffer := nil;
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
end;

function TFontList.ToString: string;
begin
  ToString := 'TFontList';
end;

function TFontList.GetItem(AIndex: integer): PFont;
begin
  GetItem := PFont(inherited GetItem(AIndex));
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

function TFontList.GetFont(AId: string): PFont;
var
  index: integer;
  font: PFont;
begin
  GetFont := nil;
  for index := 0 to Count - 1 do begin
    font := GetItem(index);
    if LowerCase(AId) = LowerCase(StrPas(Font^.Id)) then begin
      GetFont := font;
      exit;
    end;
  end;
end;

procedure TFontList.Insert(AIndex: integer; AItem: PFont);
begin
  inherited Insert(AIndex, AItem);
end;

end.