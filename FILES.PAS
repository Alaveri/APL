{$I COMPILER.INC}
unit Files;

interface

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  Objects,
  Lists,
  StrUtils,
  Common,
  DateTime,
  Errors;

type
  PDirectoryContents = ^TDirectoryContents;
  PFile = ^TFile;
  PFileList = ^TFileList;

  TFileAttribute = (
    faReadOnly,
    faHidden,
    faSystem,
    faVolumeID,
    faDirectory,
    faArchive
  );

  TFileAttributes = set of TFileAttribute;

  TFile = object(TObject)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
    Name: PChar;
    Attr: TFileAttributes;
    Time: TDateTime;
    Size: Longint;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TDirSort = (dsFilename, dsSize, dsTime);
  TDirSortDirection = (dsAsc, dsDesc);

  TDirectoryContents = object(TFile)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
    Files: PFileList;
    Path: string;
    Filter: string;
    procedure Init; virtual;
    procedure Sort(ASort: TDirSort; ADirection: TDirSortDirection; ADirsFirst: boolean);
    destructor Free; virtual;
  end;

  TFileList = object(TObjectList)
  {$IFDEF VER70}private{$ENDIF}
  {$IFDEF VER70}public{$ENDIF}
    function GetItem(AIndex: longint): PFile;
    function IndexOf(AItem: PFile): longint;
    function Find(const AFilename: string): PFile;
    function Add(AItem: PFile): integer;
    procedure Insert(AIndex: longint; AItem: PFile);
  end;

  TDirectoryManager = object(TExceptionObject)
  {$IFDEF VER70}private{$ENDIF}
    function HandleError(AError: integer): boolean;
    procedure SetFileInfo(AFile: PFile; ASearch: SearchRec);
  {$IFDEF VER70}public{$ENDIF}
    DefaultFileAttributes: TFileAttributes;
    DefaultDirAttributes: TFileAttributes;
    procedure Init; virtual;
    function GetDirectory(const APath: string): PDirectoryContents;
  end;

const
  faAny: TFileAttributes = [
    faReadOnly,
    faHidden,
    faSystem,
    faVolumeID,
    faDirectory
  ];

  ValidDosChars = [
    'A'..'Z',
    'a'..'z',
    '0'..'9',
    '.',
    '!', '#', '$', '%', '&', ',', '(', ')', '-', '@', '^', '_',
    '`', '{', '}', '~', '*', '?'
  ];

var
  TDirectory: TDirectoryManager;

implementation

var
  SortDirection: TDirSortDirection;
  SortDirsFirst: boolean;
  PreviousExitProc: PFunc;

function FilenameCompare(AItem1, AItem2: pointer): integer;
var
  file1, file2, temp: PFile;
  result: integer;
  isDir1, isDir2: boolean;
  filename1, filename2: string[12];
begin
  file1 := PFile(AItem1);
  file2 := PFile(AItem2);
  if SortDirection = dsDesc then
    SwapPointer(pointer(file1), pointer(file2));
  filename1 := StrPas(file1^.Name);
  filename2 := StrPas(file2^.Name);
  isDir1 := false;
  isDir2 := false;
  if SortDirsFirst then begin
    isDir1 := faDirectory in file1^.Attr;
    isDir2 := faDirectory in file2^.Attr;
  end;
  if isDir1 and not isDir2 then
    result := -1
  else if isDir2 and not isDir1 then
    result := 1
  else if filename1 < filename2 then
    result := -1
  else if fileName1 > filename2 then
    result := 1
  else if file1^.Time.Ticks < file2^.Time.Ticks then
    result := -1
  else if file1^.Time.Ticks > file2^.Time.Ticks then
    result := 1
  else if file1^.Size < file2^.Size then
    result := -1
  else if file1^.Size > file1^.Size then
    result := 1
  else
    result := 0;
  FilenameCompare := result;
end;

function FileSizeCompare(AItem1, AItem2: pointer): integer;
var
  file1, file2, temp: PFile;
  result: integer;
  isDir1, isDir2: boolean;
  filename1, filename2: string[12];
begin
  file1 := PFile(AItem1);
  file2 := PFile(AItem2);
  if SortDirection = dsDesc then
    SwapPointer(pointer(file1), pointer(file2));
  filename1 := StrPas(file1^.Name);
  filename2 := StrPas(file2^.Name);
  isDir1 := false;
  isDir2 := false;
  if SortDirsFirst then begin
    isDir1 := faDirectory in file1^.Attr;
    isDir2 := faDirectory in file2^.Attr;
  end;
  if isDir1 and not isDir2 then
    result := -1
  else if isDir2 and not isDir2 then
    result := 1
  else if file1^.Size < file2^.Size then
    result := -1
  else if file1^.Size > file1^.Size then
    result := 1
  else if filename1 < filename2 then
    result := -1
  else if fileName1 > filename2 then
    result := 1
  else if file1^.Time.Ticks < file2^.Time.Ticks then
    result := -1
  else if file1^.Time.Ticks > file2^.Time.Ticks then
    result := 1
  else
    result := 0;
  FileSizeCompare := result;
end;

function FileTimeCompare(AItem1, AItem2: pointer): integer;
var
  file1, file2, temp: PFile;
  result: integer;
  isDir1, isDir2: boolean;
  filename1, filename2: string[12];
begin
  file1 := PFile(AItem1);
  file2 := PFile(AItem2);
  if SortDirection = dsDesc then
    SwapPointer(pointer(file1), pointer(file2));
  filename1 := StrPas(file1^.Name);
  filename2 := StrPas(file2^.Name);
  isDir1 := false;
  isDir2 := false;
  if SortDirsFirst then begin
    isDir1 := faDirectory in file1^.Attr;
    isDir2 := faDirectory in file2^.Attr;
  end;
  if isDir1 and not isDir2 then
    result := -1
  else if isDir2 and not isDir2 then
    result := 1
  else if file1^.Time.Ticks < file2^.Time.Ticks then
    result := -1
  else if file1^.Time.Ticks > file2^.Time.Ticks then
    result := 1
  else if filename1 < filename2 then
    result := -1
  else if fileName1 > filename2 then
    result := 1
  else if file1^.Size < file2^.Size then
    result := -1
  else if file1^.Size > file1^.Size then
    result := 1
  else
    result := 0;
  FileTimeCompare := result;
end;

procedure TDirectoryManager.Init;
begin
  inherited Init;
end;

procedure TDirectoryManager.SetFileInfo(AFile: PFile; ASearch: SearchRec);
var
  result: PFile;
  fileTime: Dos.DateTime;
begin
  AFile^.Name := TString.New(ASearch.Name);
  AFile^.Size := ASearch.Size;
  AFile^.Attr := TFileAttributes(ASearch.Attr);
  UnpackTime(ASearch.Time, fileTime);
  AFile^.Time.CreateDateTime(fileTime.Year, fileTime.Month, fileTime.Day,
    fileTime.Hour, fileTime.Min, fileTime.Sec, 1);
end;

function TDirectoryManager.HandleError(AError: integer): boolean;
begin
  HandleError := true;
  case AError of
    2: Raise(ecFileNotFound);
    3: Raise(ecPathNotFound);
    5: Raise(ecFileAccessDenied);
    6: Raise(ecFileInvalidHandle);
    8: Raise(ecNotEnoughMemory);
    10: Raise(ecFileInvalidEnvironment);
    11: Raise(ecFileInvalidFormat);
    18: HandleError := false;
  end;
end;

function TDirectoryManager.GetDirectory(const APath: string): PDirectoryContents;
var
  afile: PFile;
  attributes: TFileAttributes;
  result: PDirectoryContents;
  dirPath: string;
  search: SearchRec;
  more: boolean;
begin
  result := New(PDirectoryContents, Create);
  result^.Path := FExpand(Trim(APath));
  result^.Filter := ExtractFullname(APath);
  result^.Name := TString.New(ExtractDirectory(APath));
  GetDirectory := result;
  attributes := [];

  FindFirst(result^.Path, byte(attributes), search);
  more := HandleError(DosError);
  if HasException then
    exit;
  while more do begin
    afile := New(PFile, Create);
    SetFileInfo(afile, search);
    result^.Files^.Add(afile);
    FindNext(search);
    more := HandleError(DosError);
    if HasException then
      exit;
  end;
  attributes := [faDirectory];
  dirPath := ExtractDirectory(result^.Path) + '*.*';
  FindFirst(dirPath, byte(attributes), search);
  more := HandleError(DosError);
  if HasException then
    exit;
  while more do begin
    if (faDirectory in TFileAttributes(search.Attr))
      and not ((search.Name = '..') and
        (Length(ExtractDirectory(result^.Path)) <= 3))
      and (search.Name <> '.') then begin
      afile := New(PFile, Create);
      SetFileInfo(afile, search);
      result^.Files^.Add(afile);
    end;
    more := HandleError(DosError);
    FindNext(search);
  end;
end;

procedure TDirectoryContents.Init;
begin
  inherited Init;
  Files := New(PFileList, Create);
  Path := '';
  Filter := '';
end;

destructor TDirectoryContents.Free;
begin
  FreeAndNil(Files);
  inherited Free;
end;

procedure TDirectoryContents.Sort(ASort: TDirSort; ADirection: TDirSortDirection; ADirsFirst: boolean);
begin
  SortDirection := ADirection;
  SortDirsFirst := ADirsFirst;
  case ASort of
    dsFilename: Files^.Sort(FilenameCompare);
    dsSize: Files^.Sort(FileSizeCompare);
    dsTime: Files^.Sort(FileTimeCompare);
  end;
end;

procedure TFile.Init;
begin
  inherited Init;
  Size := 0;
  Name := nil;
  Attr := [];
  Time.CreateNow;
end;

destructor TFile.Free;
begin
  TString.Free(Name);
  inherited Free;
end;

function TFileList.GetItem(AIndex: longint): PFile;
begin
  GetItem := PFile(inherited GetItem(AIndex));
end;

function TFileList.Find(const AFilename: string): PFile;
var
  index: integer;
  aFile: PFile;
  result: PFile;
begin
  result := nil;
  for index := 0 to Count - 1 do begin
    aFile := GetItem(index);
    if not (faDirectory in aFile^.Attr)
      and StringsEqualInsensitive(StrPas(aFile^.Name), AFilename) then begin
      result := aFile;
      exit;
    end;
  end;
end;

function TFileList.IndexOf(AItem: PFile): longint;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TFileList.Add(AItem: PFile): integer;
begin
  Add := inherited Add(AItem);
end;

procedure TFileList.Insert(AIndex: longint; AItem: PFile);
begin
  inherited Insert(AIndex, AItem);
end;

procedure DirectoryExitProc; far;
begin
  ExitProc := PreviousExitProc;
  TDirectory.Free;
end;

begin
  TDirectory.Create;
  PreviousExitProc := ExitProc;
  ExitProc := @DirectoryExitProc;
end.