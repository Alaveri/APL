{$I COMPILER.INC}
unit Errors;

interface

uses
  AplObj;

type
  PCustomErrorMessageProc = ^TCustomErrorMessageProc;

  TCustomErrorMessageProc = function(AErrorCode: integer; var found: boolean): string;

  TExceptionCode = word;

  TExceptionSeverity =
  (
    esNone,
    esHint,
    esWarning,
    esError,
    esFatal
  );

const
  ecNone = 0;

  { IO Codes }
  ecFileNotFound = 101;
  ecFileCreateError = 102;
  ecFileOpenError = 103;
  ecFileReadError = 104;
  ecFileWriteError = 105;
  ecFileVersionError = 106;
  ecFileTypeError = 106;
  ecFileInvalid = 107;
  ecMouseError = 108;

  { Graphics errors }
  ecGraphicsNotSupported = 201;
  ecGraphicsDriverError = 202;
  ecGraphicsModeNotFound = 203;
  ecUnsupportedPaletteFormat = 204;
  ecInvalidPalette = 205;

  { Memory errors }
  ecMemoryReferenceNotFound = 301;
  ecInvalidMemoryReference = 302;
  ecNotEnoughMemory = 303;
  ecInvalidAllocSize = 304;
  ecXmsNotInitialized = 305;
  ecXmsNotSupported = 306;
  ecXmsError = 307;

  { Stream errors }
  ecSeekPastStreamEnd = 400;
  ecWritePastStreamEnd = 401;
  ecReadPastStreamEnd = 402;
  ecStreamSeekNotSupported = 403;
  ecStreamWriteNotSupported = 404;
  ecStreamReadNotSupported = 405;
  ecStreamNotOpen = 406;
  ecStreamCloseError = 407;
  ecStreamOpenError = 408;
  ecStreamReadError = 409;
  ecStreamWriteError = 410;
  ecStreamSeekError = 411;
  ecStreamFormatNotSupported = 412;

  { Text errors }
  ecTextDriverNotSupported = 501;
  ecTextDriverError = 502;
  ecTextModeNotFound = 503;

  { Compression errors }
  ecInvalidCompressionSource = 601;
  ecCompressionBitSizeError = 602;
  ecCompressorNotSpecified = 603;

  { List Errors }
  ecListCapacityOverflow = 701;
  ecIndexOutOfBounds = 702;

  { Image errors }
  ecImageBppNotSupported = 801;
  ecInvalidImage = 802;
  ecImageCompressionNotSupported = 803;
  ecImageVersionNotSupported = 804;

  { Font Errors }
  ecFontVersionNotSupported = 901;
  ecFontCompressionNotSupported = 902;

  { File Errors }
  ecPathNotFound = 1001;
  ecFileAccessDenied = 1003;
  ecFileInvalidHandle = 1004;
  ecFileInvalidEnvironment = 1005;
  ecFileInvalidFormat = 1006;
  ecDirChangeError = 1007;
  ecFileInvalidVersion = 1008;

  { System errors }
  ecNullParameter = 1101;
  ecInvalidOperation = 1102;

  { User defined errors }
  ecUser = 5000;

  { Status codes }
  sOk = 0;
  sHint = 1;
  sWarning = 2;
  sException = 3;
  sFileStatus = 100;
  sUserStatus = 1000;

type
  PException = ^TException;
  PStatusObject = ^TStatusObject;

  TObjectStatus = integer;

  TException = object(TIdentifiable)
  private
  public
    Code: TExceptionCode;
    Severity: TExceptionSeverity;
    InnerException: PException;
    constructor Create(ACode: TExceptionCode);
    procedure Init; virtual;
    procedure Clear;
    procedure Assign(var ASource: TObject); virtual;
    destructor Free; virtual;
  end;

  TStatusObject = object(TIdentifiable)
  private
  public
    Exception: PException;
    Status: TObjectStatus;
    procedure Init; virtual;
    {$IFDEF DOS}
    procedure Raise(ACode: TExceptionCode);
    {$ENDIF}
    procedure RaiseNullParameter(AParam: string);
    procedure RaiseInvalidOperation(AMessage: string);
    procedure RaiseWarning(ACode: TExceptionCode);
    procedure RaiseHint(ACode: TExceptionCode);
    procedure Reraise(AObject: PStatusObject);
    procedure RaiseSeverity(ACode: TExceptionCode; ASeverity: TExceptionSeverity);
    procedure ClearException;
    procedure Assign(var ASource: TObject); virtual;
    function HasException: boolean;
    function NoException: boolean;
    function GetBaseException: PException;
    function CheckReraise(AObject: PStatusObject): boolean;
    function IsNilPtr(APtr: pointer; ACode: TExceptionCode): boolean;
    function IsNilPtrSeverity(APtr: pointer; ACode: TExceptionCode;
      ASeverity: TExceptionSeverity): boolean;
    destructor Free; virtual;
  end;

function ErrorMessage(AErrorCode: TExceptionCode): string;

var
  CustomErrorMessage: PCustomErrorMessageProc;

implementation

uses
  MemDrv;

function ErrorMessage(AErrorCode: TExceptionCode): string;
var
  found: boolean;
begin
  case AErrorCode of
    ecFileNotFound: ErrorMessage := 'File not found';
	  ecFileCreateError: ErrorMessage := 'File could not be created';
  	ecFileOpenError: ErrorMessage := 'File could not be opened';
  	ecFileReadError: ErrorMessage := 'Error writing file';
  	ecFileWriteError: ErrorMessage := 'Error writing file';
  	ecFileVersionError: ErrorMessage := 'File version mismatch';
  	ecFileTypeError: ErrorMessage := 'File type not supported';
  	ecFileInvalid: ErrorMessage := 'File is invalid';
  	ecGraphicsNotSupported: ErrorMessage := 'Graphics type not supported';
  	ecTextDriverNotSupported: ErrorMessage := 'Text type not supported';
  	ecTextDriverError: ErrorMessage := 'Text driver error';
  	ecTextModeNotFound: ErrorMessage := 'Text mode not found';
  	ecMemoryReferenceNotFound: ErrorMessage := 'Memory reference not found';
  	ecInvalidMemoryReference: ErrorMessage := 'Invalid memory reference';
  	ecNotEnoughMemory: ErrorMessage := 'Not enough memory';
  	ecInvalidAllocSize: ErrorMessage := 'Invalid allocation size';
  	ecGraphicsDriverError: ErrorMessage := 'Graphics mode not supported';
  	ecStreamSeekNotSupported: ErrorMessage := 'Stream does not support seeking';
  	ecStreamWriteNotSupported: ErrorMessage := 'Stream does not support writing';
  	ecStreamReadNotSupported: ErrorMessage := 'Stream does not support reading';
  	ecSeekPastStreamEnd: ErrorMessage := 'Seek past end of stream';
  	ecWritePastStreamEnd: ErrorMessage := 'Write past end of stream';
  	ecReadPastStreamEnd: ErrorMessage := 'Read past end of stream';
  	ecStreamNotOpen: ErrorMessage := 'Stream is not open';
  	ecXmsNotInitialized: ErrorMessage := 'XMS memory could not be initialized';
  	ecXmsNotSupported: ErrorMessage := 'XMS memory is not supported';
  	ecStreamCloseError: ErrorMessage := 'Error closing stream';
  	ecStreamOpenError: ErrorMessage := 'Error opening stream';
  	ecStreamReadError: ErrorMessage := 'Error reading stream';
  	ecStreamWriteError: ErrorMessage := 'Error writing stream';
  	ecStreamSeekError: ErrorMessage := 'Stream seek error';
  	ecGraphicsModeNotFound: ErrorMessage := 'Graphics mode not found';
  	ecInvalidCompressionSource: ErrorMessage := 'Compression source is invalid';
  	ecImageBppNotSupported: ErrorMessage := 'Image bit depth not supported';
  	ecListCapacityOverflow: ErrorMessage := 'List capacity overflow';
  	ecInvalidImage: ErrorMessage := 'Invalid image data';
  	ecImageCompressionNotSupported: ErrorMessage := 'Image compression not supported';
  	ecImageVersionNotSupported: ErrorMessage := 'Image version not supported';
    ecStreamFormatNotSupported: ErrorMessage := 'Stream format not supported';
    ecFontVersionNotSupported: ErrorMessage := 'Font version not supported';
    ecPathNotFound: ErrorMessage := 'Path not found';
    ecFileAccessDenied: ErrorMessage := 'File access denied';
    ecFileInvalidHandle: ErrorMessage := 'Invalid file handle';
    ecFileInvalidEnvironment: ErrorMessage := 'Invalid environment';
    ecFileInvalidFormat: ErrorMessage := 'Invalid file format';
    ecDirChangeError: ErrorMessage := 'Error changing directory';
    ecIndexOutOfBounds: ErrorMessage := 'List index out of bounds';
    ecFileInvalidVersion: ErrorMessage := 'Unsupported file version';
    ecNullParameter: ErrorMessage := 'Null parameter';
    ecInvalidOperation: ErrorMessage := 'Invalid operation';
    ecUnsupportedPaletteFormat: ErrorMessage := 'Unsupported palette format';
    ecInvalidPalette: ErrorMessage := 'Invalid palette';
    ecCompressionBitSizeError: ErrorMessage := 'Compression bit size too large';
    ecCompressorNotSpecified: ErrorMessage := 'Compressor not specified';
    else begin
      if AErrorCode >= ecUser then begin
        if Assigned(CustomErrorMessage) then begin
          ErrorMessage := TCustomErrorMessageProc(CustomErrorMessage)(AErrorCode, found);
          if found then
            exit;
        end;
      end;
      ErrorMessage := 'Unknown error';
    end;
  end;
end;

constructor TException.Create(ACode: TExceptionCode);
begin
  inherited Create;
  Code := ACode;
end;

procedure TException.Init;
begin
  inherited Init;
  Code := ecNone;
  Severity := esError;
  InnerException := nil;
end;

procedure TException.Clear;
begin
  FreeAndNil(InnerException);
  Code := ecNone;
  Severity := esError;
end;

destructor TException.Free;
begin
  Clear;
  inherited Free;
end;

procedure TException.Assign(var ASource: TObject);
var
  source: PException;
begin
  inherited Assign(ASource);
  source := PException(@ASource);
  Clear;
  if Assigned(source^.InnerException) then begin
    InnerException := New(PException, Create(ecNone));
    InnerException^.Assign(source^.InnerException^);
  end;
  Code := source^.Code;
  Severity := source^.Severity;
end;

procedure TStatusObject.Init;
begin
  inherited Init;
  Exception := nil;
  Status := sOk;
end;

function TStatusObject.GetBaseException: PException;
var
  result: PException;
begin
  GetBaseException := Exception;
  if not Assigned(Exception) then
    exit;
  result := Exception;
  while Assigned(Exception^.InnerException) do
    result := result^.InnerException;
  GetBaseException := result;
end;

function TStatusObject.HasException: boolean;
begin
  HasException := Assigned(Exception);
end;

function TStatusObject.NoException: boolean;
begin
  NoException := not Assigned(Exception);
end;

{$IFDEF DOS}
procedure TStatusObject.Raise(ACode: TExceptionCode);
var
  newException: PException;
  prev: PException;
begin
  newException := New(PException, Create(ACode));
  if not Assigned(newException) then
    newException := OutOfMemoryException;
  if not Assigned(Exception) then begin
    Exception := newException;
    exit;
  end;
  prev := Exception;
  Exception := newException;
  Exception^.InnerException := prev;
  Status := sException;
end;
{$ENDIF}

procedure TStatusObject.RaiseSeverity(ACode: TExceptionCode; ASeverity: TExceptionSeverity);
begin
  Raise(ACode);
  Exception^.Severity := ASeverity;
end;

function TStatusObject.CheckReraise(AObject: PStatusObject): boolean;
var
  result: boolean;
begin
  result := false;
  if not Assigned(AObject) then
    exit;
  result := AObject^.HasException;
  if result then begin
    Reraise(AObject);
    AObject^.ClearException;
  end;
  CheckReraise := result;
end;

function TStatusObject.IsNilPtr(APtr: pointer; ACode: TExceptionCode): boolean;
var
  result: boolean;
begin
  result := not Assigned(APtr);
  if result then
    Raise(ACode);
  IsNilPtr := result;
end;

function TStatusObject.IsNilPtrSeverity(APtr: pointer; ACode: TExceptionCode;
  ASeverity: TExceptionSeverity): boolean;
var
  result: boolean;
begin
  result := not Assigned(APtr);
  if result then
    RaiseSeverity(ACode, ASeverity);
  IsNilPtrSeverity := result;
end;

procedure TStatusObject.Reraise(AObject: PStatusObject);
begin
  if not (Assigned(AObject) and AObject^.HasException) then
    exit;
  RaiseSeverity(AObject^.Exception^.Code, AObject^.Exception^.Severity);
  AObject^.ClearException;
end;

procedure TStatusObject.RaiseWarning(ACode: TExceptionCode);
begin
  RaiseSeverity(ACode, esWarning);
end;

procedure TStatusObject.RaiseHint(ACode: TExceptionCode);
begin
  RaiseSeverity(ACode, esHint);
end;

procedure TStatusObject.ClearException;
begin
  FreeAndNil(Exception);
  Status := sOk;
end;

destructor TStatusObject.Free;
begin
  ClearException;
  inherited Free;
end;

procedure TStatusObject.Assign(var ASource: TObject);
var
  source: PStatusObject;
begin
  inherited Assign(ASource);
  source := PStatusObject(@ASource);
  ClearException;
  Exception := New(PException, Create(ecNone));
  Exception^.Assign(source^.Exception^);
  Status := source^.Status;
end;

procedure TStatusObject.RaiseNullParameter(AParam: string);
begin
  Raise(ecNullParameter);
end;

procedure TStatusObject.RaiseInvalidOperation(AMessage: string);
begin
  Raise(ecInvalidOperation);
end;

begin
  CustomErrorMessage := nil;
end.