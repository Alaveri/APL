{$I COMPILER.INC}
unit Files;

interface

uses
  {$IFDEF DOS}
  Strings,
  Dos,
  {$ENDIF}
  AplObj,
  AplTypes,
  Lists,
  StrUtils,
  Common,
  DateTime,
  Errors;

type
  PDirectoryContents = ^TDirectoryContents;
  PFile = ^TFile;
  PFileList = ^TFileList;
  PFileListProc = ^TFileListProc;


  TFileAttribute = (
    faReadOnly,
    faHidden,
    faSystem,
    faVolumeID,
    faDirectory,
    faArchive
  );

  TFileAttributes = set of TFileAttribute;
  TFileListProc = procedure(ASender: PObject; AItem: PFile);
  TFile = object(TObject)
  private
  public
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
  private
  public
    Files: PFileList;
    Path: string;
    Directory: string;
    Filter: string;
    procedure Init; virtual;
    procedure Sort(ASort: TDirSort; ADirection: TDirSortDirection; ADirsFirst: boolean);
    destructor Free; virtual;
  end;

  TFileList = object(TObjectList)
  private
  public
    function GetItem(AIndex: longint): PFile;
    function Find(const AFilename: string): PFile;
    function Add(AItem: PFile): integer;
    function IndexOf(AItem: PFile): integer;
    procedure ForEach(AProc: PFileListProc);
    procedure SetItem(AIndex: integer; AItem: PFile);
    procedure Insert(AIndex: integer; AItem: PFile);
  end;

  TDirectoryManager = object(TStatusObject)
  private
    function HandleError(AError: integer): boolean;
    procedure SetFileInfo(AFile: PFile; ASearch: SearchRec);
  public
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
  PreviousExitProc: PProc;

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
  error: integer;
begin
  result := New(PDirectoryContents, Create);
  result^.Path := FExpand(Trim(APath));
  result^.Directory := IncludeBackslash(ExtractDirectory(result^.Path));
  if DirectoryExists(result^.Directory) then
    ChangeDirectory(result^.Directory);
  if HasWildCard(APath) then
    result^.Filter := ExtractFullname(APath)
  else
    result^.Filter := '*.*';
  result^.Name := TString.New(ExtractDirectory(APath));
  GetDirectory := result;
  attributes := [];

  FindFirst(result^.Path, byte(attributes), search);
  more := HandleError(DosError);
  if HasException then
    exit;
  while more do begin
    if not (faDirectory in TFileAttributes(search.Attr)) then begin
      afile := New(PFile, Create);
      SetFileInfo(afile, search);
      result^.Files^.Add(afile);
    end;
    FindNext(search);
    error := DosError;
    more := HandleError(error);
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
    FindNext(search);
    error := DosError;
    more := HandleError(error);
  end;
end;

procedure TDirectoryContents.Init;
begin
  inherited Init;
  Files := New(PFileList, Create);
  Path := '';
  Directory := '';
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
    dsFilename: Files^.SetComparer(FilenameCompare);
    dsSize: Files^.SetComparer(FileSizeCompare);
    dsTime: Files^.SetComparer(FileTimeCompare);
  end;
  Files^.Sort;
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

function TFileList.Add(AItem: PFile): integer;
begin
  Add := inherited Add(AItem);
end;

function TFileList.IndexOf(AItem: PFile): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

procedure TFileList.ForEach(AProc: PFileListProc);
begin
  TList.ForEach(PListProc(AProc));
end;

procedure TFileList.SetItem(AIndex: integer; AItem: PFile);
begin
  inherited SetItem(AIndex, AItem);
end;

procedure TFileList.Insert(AIndex: integer; AItem: PFile);
begin
  inherited Insert(AIndex, AItem);
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

procedure Finalize; far;
begin
  ExitProc := PreviousExitProc;
  TDirectory.Free;
end;

begin
  TDirectory.Create;
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.