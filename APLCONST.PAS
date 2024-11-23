{$I COMPILER.INC}
unit AplConst;

interface

type
  PCustomErrorMessageProc = ^TCustomErrorMessageProc;
  PProc = ^TProc;

  TCustomErrorMessageProc = function(AErrorCode: integer; var found: boolean): string;
  TProc = procedure;

  String1 = string[1];
  String2 = string[2];
  String3 = string[3];
  String4 = string[4];
  String5 = string[5];
  String6 = string[6];
  String7 = string[7];
  String8 = string[8];
  String9 = string[9];
  String10 = string[10];
  String11 = string[11];
  String12 = string[12];
  String13 = string[13];
  String14 = string[14];
  String15 = string[15];
  String16 = string[16];
  String17 = string[17];
  String18 = string[18];
  String19 = string[19];
  String20 = string[20];
  String25 = string[25];
  String30 = string[30];
  String35 = string[35];
  String40 = string[40];
  String45 = string[45];
  String50 = string[50];
  String75 = string[75];
  String80 = string[80];
  String85 = string[80];
  String90 = string[80];
  String100 = string[100];

const
  HexDigits: string16 = '0123456789ABCDEF';
  PointerSize: longint = SizeOf(Pointer);
  MaxVarSize = $FFF8;

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
  ecImageTooLarge = 805;

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
  ecInvalidArgument = 1103;

  { User defined errors }
  ecUser = 5000;

  { Status codes }
  sOk = 0;
  sHint = 1;
  sWarning = 2;
  sException = 3;
  sFileStatus = 100;
  sUserStatus = 1000;

function ErrorMessage(AErrorCode: word): string; far;

var
  CustomErrorMessageProc: PCustomErrorMessageProc;

implementation

function ErrorMessage(AErrorCode: word): string;
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
    ecInvalidArgument: ErrorMessage := 'Invalid argument';
    ecUnsupportedPaletteFormat: ErrorMessage := 'Unsupported palette format';
    ecInvalidPalette: ErrorMessage := 'Invalid palette';
    ecCompressionBitSizeError: ErrorMessage := 'Compression bit size too large';
    ecCompressorNotSpecified: ErrorMessage := 'Compressor not specified';
    ecImageTooLarge: ErrorMessage := 'Image too large';
    else begin
      if AErrorCode >= ecUser then begin
        if Assigned(CustomErrorMessageProc) then begin
          ErrorMessage := TCustomErrorMessageProc(CustomErrorMessageProc)(AErrorCode, found);
          if found then
            exit;
        end;
      end;
      ErrorMessage := 'Unknown error';
    end;
  end;
end;

begin
  CustomErrorMessageProc := nil;
end.