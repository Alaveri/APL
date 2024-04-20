{$I COMPILER.INC}
unit Lzw;

interface

uses
  Compress,
  Errors,
  Streams,
  Common;

type
  PDictEntry = ^TDictEntry;
  PLzw = ^TLzw;

  TDictEntry = record
    Code: word;
    Prefix: word;
    Char: byte;
  end;

  TLzw = object(TCompressor)
  {$IFDEF VER70}private{$ENDIF}
    FDict: PDictEntry;
    FDictEntries: word;
    FDictSize: word;
    FDecodeBuffer: PByte;
    FCurrentBitSize: byte;
    FMaxCode: word;
    FCurrentMaxCode: word;
    FNextCode: word;
    FOverflow: boolean;
    FHashShift: byte;
    function AllocateDictionary: boolean;
    function AllocateDecodeBuffer: boolean;
    function FindEntry(AIndex: word; AChar: byte): word;
    function DecodeString(ACount: word; ACode: word): word;
    procedure DeallocateDictionary;
    procedure DeallocateDecodeBuffer;
    procedure InitCoder;
    procedure InitCompression; virtual;
  {$IFDEF VER70}public{$ENDIF}
    BitSize: byte;
    constructor CreateBitSize(ABitSize: byte);
    destructor Free; virtual;
    function CompressStream(ASource, ADest: PStream; ALength: longint): longint; virtual;
    function GetOriginalSize(ASource: PStream): longint; virtual;
    procedure Init; virtual;
    procedure DecompressStream(ASource, ADest: PStream); virtual;
  end;

implementation

const
  SupportedBitSizes = [12, 13];

const
  DefaultBitSize = 13;
  StartBitSize = 9;
  EndOfStream = 256;
  IncreaseCodeSize = 257;
  ClearDict = 258;
  EmptyCode = 259;
  FirstCode = 260;

constructor TLzw.CreateBitSize(ABitSize: byte);
begin
  inherited Create;
  if not (ABitSize in [12, 13]) then begin
    Raise(ecStreamFormatNotSupported);
    exit;
  end;
  BitSize := ABitSize;
end;

destructor TLzw.Free;
begin
  DeallocateDecodeBuffer;
  DeallocateDictionary;
  inherited Free;
end;

procedure TLzw.Init;
begin
  inherited Init;
  BitSize := DefaultBitSize;
  FMaxCode := 0;
  FDict := nil;
  FDictEntries := 0;
  FDictSize := 0;
  FDecodeBuffer := nil;
  FOverflow := false;
  FNextCode := 0;
  FCurrentBitSize := BitSize;
end;

function TLzw.AllocateDecodeBuffer: boolean;
begin
  AllocateDecodeBuffer := true;
  DeallocateDecodeBuffer;
  GetMem(FDecodeBuffer, FDictEntries);
  if not Assigned(FDecodeBuffer) then begin
    Raise(ecNotEnoughMemory);
    AllocateDecodeBuffer := false;
  end;
end;

procedure TLzw.DeallocateDecodeBuffer;
begin
  if Assigned(FDecodeBuffer) then
    FreeMem(FDecodeBuffer, FDictEntries);
  FDecodeBuffer := nil;
end;

function TLzw.AllocateDictionary: boolean;
begin
  AllocateDictionary := true;
  DeallocateDictionary;

  GetMem(FDict, FDictSize);

  if not Assigned(FDict) then begin
    Raise(ecNotEnoughMemory);
    AllocateDictionary := false;
  end;
end;

procedure TLzw.DeallocateDictionary;
begin
  if Assigned(FDict) then
    FreeMem(FDict, FDictSize);
  FDict := nil;
end;

function TLzw.FindEntry(AIndex: word; AChar: byte): word;
var
  index, offset: longint;
  entry: PDictEntry;
begin
  index := (AChar shl FHashShift) xor AIndex;
  offset := 1;
  if index <> 0 then
    offset :=  FDictEntries - index;
  repeat
    entry := FDict;
    Inc(entry, index);
    if entry^.Code = EmptyCode then
      break;
    if (entry^.Prefix = AIndex) and (entry^.Char = AChar) then
      break;
    Dec(index, offset);
    if index < 0 then
      Inc(index, FDictEntries);
  until false;
  FindEntry := index;
end;

function TLzw.DecodeString(ACount: word; ACode: word): word;
var
  bufferPtr: PByte;
  entry: PDictEntry;
begin
  bufferPtr := FDecodeBuffer;
  Inc(bufferPtr, ACount);
  while ACode > High(byte) do begin
    entry := FDict;
    Inc(entry, ACode);
    ACode := entry^.Prefix;
    bufferPtr^ := entry^.Char;
    Inc(ACount);
    Inc(bufferPtr);
  end;
  bufferPtr^ := ACode;
  Inc(ACount);
  DecodeString := ACount;
end;

procedure TLzw.InitCompression;
begin
  inherited InitCompression;
  if BitSize = 12 then
    FDictEntries := 5021
  else if BitSize = 13 then
    FDictEntries := 9029
  else if BitSize = 14 then
    FDictEntries := 18041
  else if BitSize = 15 then
    FDictEntries := 49063;
  FHashShift := BitSize - 8;
  FDictSize := FDictEntries * SizeOf(TDictEntry);
  AllocateDictionary;
  InitCoder;
end;

procedure TLzw.InitCoder;
var
  index: word;
  entry: PDictEntry;
begin
  FCurrentBitSize := StartBitSize;
  FMaxCode := 1 shl BitSize - 1;
  FCurrentMaxCode := 1 shl FCurrentBitSize - 1;
  FNextCode := FirstCode;
  entry := FDict;
  for index := 0 to FDictEntries - 1 do begin
    entry^.Code := EmptyCode;
    Inc(entry);
  end;
  FOverflow := false;
end;

function TLzw.GetOriginalSize(ASource: PStream): longint;
var
  bits: byte;
  total: longint;
  startPos: longint;
begin
  GetOriginalSize := 0;
  startPos := ASource^.Position;
  ASource^.Read(@bits, SizeOf(byte));
  ASource^.Read(@total, SizeOf(total));
  ASource^.Seek(startPos, soFromBeginning);
  if ASource^.HasException then
    Raise(ASource^.Exception^.Code);
  if HasException then
    exit;
  GetOriginalSize := total;
end;

function TLzw.CompressStream(ASource, ADest: PStream; ALength: longint): longint;
var
  character: byte;
  code: word;
  index: word;
  entry: PDictEntry;
  endPos, startPos: longint;
  total, written: longint;
  bits: byte;
begin
  inherited CompressStream(ASource, ADest, ALength);

  if Source^.Position + ALength > Source^.Size then
    Raise(ecReadPastStreamEnd);
  if HasException then
    exit;

  total := 0;
  bits := BitSize;
  ADest^.Write(@bits, SizeOf(byte));

  startPos := ADest^.Position;
  ADest^.Write(@total, SizeOf(total));
  if ADest^.HasException then begin
    Raise(ADest^.Exception^.Code);
    exit;
  end;

  code := ReadByte;
  if HasException then
    exit;

  while ReadTotal < ALength do begin
    character:= ReadByte;
    if HasException then
      break;

    UpdateProgress(ALength, ReadTotal);
    index := FindEntry(code, character);
    entry := FDict;
    Inc(entry, index);

    if entry^.Code <> EmptyCode then begin
      code := Entry^.Code;
      continue;
    end;

    if FNextCode < FMaxCode then begin
      entry^.Code := FNextCode;
      entry^.Prefix := code;
      entry^.Char := character;
      Inc(FNextCode);
    end
    else
      FOverflow := true;

    if (code >= FCurrentMaxCode) and (FCurrentBitSize < BitSize) then begin
      if not WriteBits(IncreaseCodeSize, FCurrentBitSize) then
        break;
      Inc(FCurrentBitSize);
      FCurrentMaxCode := 1 shl FCurrentBitSize - 1;
    end;

    if not WriteBits(code, FCurrentBitSize) then
      break;

    code := character;

    if FOverflow then begin
      if not WriteBits(ClearDict, FCurrentBitSize) then
        break;
      InitCoder;
    end;
  end;
  WriteBits(code, FCurrentBitSize);
  WriteBits(EndOfStream, FCurrentBitSize);
  EndWriteBits;
  total := ReadTotal;
  endPos := ADest^.Position;
  ADest^.Seek(startPos, soFromBeginning);
  ADest^.Write(@total, SizeOf(total));
  ADest^.Seek(endPos, soFromBeginning);
  UpdateProgress(ALength, ReadTotal);
  CompressStream := WriteTotal;
end;

procedure TLzw.DecompressStream(ASource, ADest: PStream);
var
  oldCode, code: word;
  character: word;
  count, index: word;
  decodePtr: PByte;
  entry: PDictEntry;
  total: longint;
  bits: byte;
begin
  inherited DecompressStream(ASource, ADest);

  if HasException then
    exit;

  bits := 0;
  Source^.Read(@bits, SizeOf(byte));
  if not (bits in SupportedBitSizes) then begin
    Raise(ecStreamFormatNotSupported);
    exit;
  end;
  Source^.Read(@total, SizeOf(total));
  if ASource^.HasException then
    Raise(Source^.Exception^.Code);
  if HasException or (oldCode = EndOfStream) then
    exit;

  BitSize := bits;
  InitCoder;
  AllocateDecodeBuffer;

  if not ReadBits(FCurrentBitSize, oldCode) then
    exit;

  character := oldCode;
  WriteByte(oldCode);
  if HasException then
    exit;

  repeat
    if not ReadBits(FCurrentBitSize, code) then begin
      break;
    end;
    case code of
      IncreaseCodeSize: begin
        Inc(FCurrentBitSize);
        continue;
      end;
      ClearDict: begin
        InitCoder;
        if not ReadBits(FCurrentBitSize, oldCode) or (oldCode = EndOfStream) then
          break;
        WriteByte(oldCode);
        continue;
      end;
      EndOfStream:
        break;
    end;
    if code >= FNextCode then begin
      FDecodeBuffer^ := character;
      count := DecodeString(1, oldCode);
    end
    else
      count := DecodeString(0, code);

    decodePtr := FDecodeBuffer;
    Inc(decodePtr, count - 1);
    character := word(decodePtr^);
    while count > 0 do begin
      WriteByte(decodePtr^);
      Dec(decodePtr);
      Dec(count);
    end;
    if HasException then
      break;
    UpdateProgress(total, WriteTotal);

    if FNextCode <= FMaxCode then begin
      entry := FDict;
      Inc(entry, FNextCode);
      entry^.Prefix := oldCode;
      entry^.Char := character;
      Inc(FNextCode);
    end;
    oldCode := code;
  until false;
  FlushWriteBuffer;
end;

end.
