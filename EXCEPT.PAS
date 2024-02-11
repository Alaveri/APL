{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Except;

interface

uses
  Objects;

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

  { Collection Errors }
  ecCollectionCapacityOverflow = 701;

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

  { User defined errors }
  ecUser = 5000;
type
  PException = ^TException;
  PExceptionObject = ^TExceptionObject;

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

  TExceptionObject = object(TIdentifiable)
  private
  public
    Exception: PException;
    procedure Init; virtual;
    procedure Raise(ACode: TExceptionCode);
    procedure RaiseWarning(ACode: TExceptionCode);
    procedure RaiseHint(ACode: TExceptionCode);
    procedure ClearException;
    procedure Assign(var ASource: TObject); virtual;
    function HasException: boolean;
    function NoException: boolean;
    function GetBaseException: PException;
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
  	ecCollectionCapacityOverflow: ErrorMessage := 'Collection capacity overflow';
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

procedure TExceptionObject.Init;
begin
  inherited Init;
  Exception := nil;
end;

function TExceptionObject.GetBaseException: PException;
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

function TExceptionObject.HasException: boolean;
begin
  HasException := Assigned(Exception);
end;

function TExceptionObject.NoException: boolean;
begin
  NoException := not Assigned(Exception);
end;

procedure TExceptionObject.Raise(ACode: TExceptionCode);
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
end;

procedure TExceptionObject.RaiseWarning(ACode: TExceptionCode);
begin
  Raise(ACode);
  Exception^.Severity := esWarning;
end;

procedure TExceptionObject.RaiseHint(ACode: TExceptionCode);
begin
  Raise(ACode);
  Exception^.Severity := esHint;
end;

procedure TExceptionObject.ClearException;
begin
  FreeAndNil(Exception);
end;

destructor TExceptionObject.Free;
begin
  ClearException;
  inherited Free;
end;

procedure TExceptionObject.Assign(var ASource: TObject);
var
  source: PExceptionObject;
begin
  inherited Assign(ASource);
  source := PExceptionObject(@ASource);
  ClearException;
  Exception := New(PException, Create(ecNone));
  Exception^.Assign(source^.Exception^);
end;

begin
  CustomErrorMessage := nil;
end.