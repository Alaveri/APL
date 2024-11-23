{$I COMPILER.INC}
unit DateTime;

interface

uses
  AplObj,
  AplUtils,
  Dos;

const
  DateTimeFormat = 'M/DD/YYYY HH:mm:ss am';
  LongDateFormat = 'M/DD/YYYY';
  ShortDateFormat = 'M/DD/YY';
  ShortDateFormatD = 'M-DD-YY';
  LongDashFormatD = 'M-DD-YYYY';
  LongDMYDateFormat = 'D/M/YYYY';
  LongDMYDateFormatD = 'D-M-YYYY';
  ShortDMYFormat = 'D/M/YY';
  ShortDMYDateFormatD = 'D-MM-YY';
  DefaultTimeFormat = 'H:mm:ss am';
  Time24HourFormat = 'HH:mm:ss';

var
  DefaultDateFormat: string;

type
  PDateTime = ^TDateTime;
  PTimeSpan = ^TTimeSpan;

  TWeekDay = (Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday);
  TWeekDays = set of TWeekDay;

  TDateTime = object(TObject)
  private
  public
    Ticks: double; { 1/100th seconds since Jan 1, 0001 12:00 am }
    constructor CreateDateTime(AYear, AMonth, ADay, AHour, AMinute, ASecond,
      AHundredths: integer);
    constructor CreateNow;
    constructor CreateTicks(ATicks: double);
    destructor Free; virtual;
    procedure Init; virtual;
    procedure AddDays(ADays: double);
    procedure AddYears(AYears: double);
    procedure AddMonths(AMonths: double);
    procedure AddHours(AHours: double);
    procedure AddMinutes(AMinutes: double);
    procedure AddSeconds(ASeconds: double);
    procedure AddHundredths(AHundredths: double);
    procedure AddTicks(ATickCount: double);
    procedure Add(ASpan: PTimeSpan);
    procedure GetDateParts(var AYear: word; var AMonth: byte; var ADay: byte);
    procedure GetTimeParts(var AHour, AMinute, ASecond, AHundredth: byte);
    procedure SetNow;
    procedure Assign(var ASource: TObject); virtual;
    function ToString: string; virtual;
    function ToStringFormat(const AFormat: string): string;
    function GetTicks(AYear, AMonth, ADay, AHour, AMinute, ASecond,
      AHundredth: integer): double;
    function IsLeapYear(AYear: integer): boolean;
    function DaysToYear(AYear: integer): double;
    function DayOfWeek: TWeekDay;
    function Year: word;
    function Month: byte;
    function Day: byte;
    function Hour: byte;
    function Minute: byte;
    function Second: byte;
    function Hundredth: byte;
  end;

  TTimeSpan = object(TDateTime)
  public
    constructor CreateSpan(ATimeSpan: TTimeSpan);
    constructor CreateHours(AHours: double);
    constructor CreateMinutes(AMinutes: double);
    constructor CreateSeconds(ASeconds: double);
    constructor CreateHundredths(AHundredths: double);
    constructor CreateTicks(ATicks: double);
    constructor CreateAll(ADays, AHours, AMinutes, ASeconds, AHundredths: double);
    function TotalHundredths: double;
    function TotalSeconds: double;
    function TotalMinutes: double;
    function TotalHours: double;
    function TotalDays: double;
    function ToString: string; virtual;
    procedure Add(ATimeSpan: TTimeSpan);
    procedure AddHundredths(AHundredths: double);
    procedure AddTicks(ATicks: double);
    procedure AddSeconds(ASeconds: double);
    procedure AddMinutes(AMinutes: double);
    procedure AddHours(AHours: double);
    procedure AddDays(ADays: double);
    procedure Init; virtual;
    procedure GetDuration(var ATimeSpan: TTimeSpan);
  public
  end;

  TStopWatch = object(TObject)
  private
  public
    StartTime: TDateTime;
    EndTime: TDateTime;
    function ElapsedTicks: double;
    procedure Init; virtual;
    procedure GetElapsed(var ATimeSpan: TTimeSpan);
    procedure Start;
    procedure Stop;
    procedure Reset;
  end;

implementation

type
  MonthArray = array[1..12] of integer;
  DaysToMonthArray = array[0..12] of integer;

const
  TicksPerSecond = 100;
  TicksPerMinute = TicksPerSecond *  60;
  TicksPerHour = TicksPerMinute * 60;
  TicksPerDay = TicksPerHour * 24;
  TicksPer6Hours = TicksPerHour * 6;

  DaysPerYear = 365;
  DaysPer4Years = DaysPerYear * 4 + 1;
  DaysPer100Years = DaysPer4Years * 25 - 1;
  DaysPer400Years = DaysPer100Years * 4 + 1;
  DaysTo1601 = DaysPer400Years * 4;
  DaysTo1899 = DaysPer400Years * 4 + DaysPer100Years * 3 - 367;
  DaysTo1970 = DaysPer400Years * 4 + DaysPer100Years * 3 + DaysPer4Years * 17 + DaysPerYear;

  DaysInMonth365: MonthArray = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
  DaysInMonth366: MonthArray = (31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

  DaysToMonth365: DaysToMonthArray = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365);
  DaysToMonth366: DaysToMonthArray = (0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366);

constructor TDateTime.CreateDateTime(AYear, AMonth, ADay, AHour, AMinute, ASecond,
  AHundredths: integer);
begin
  inherited Create;
  Ticks := GetTicks(AYear, AMonth, ADay, AHour, AMinute, ASecond, AHundredths);
end;

constructor TDateTime.CreateTicks(ATicks: double);
begin
  inherited Create;
  Ticks := ATicks;
end;

procedure TDateTime.SetNow;
var
  y, m, d, dw, h, mi, s, sh: word;
begin
  GetDate(y, m, d, dw);
  GetTime(h, mi, s, sh);
  Ticks := GetTicks(y, m, d, h, mi, s, sh);
end;

constructor TDateTime.CreateNow;
begin
  inherited Create;
  SetNow;
end;

procedure TDateTime.Init;
begin
  inherited Init;
  Ticks := 0;
end;

destructor TDateTime.Free;
begin
  inherited Free;
end;

function TDateTime.IsLeapYear(AYear: integer): boolean;
begin
  if (AYear and 3 <> 0) then begin
    IsLeapYear := false;
    exit;
  end;
  if (AYear and 15 = 0) then begin
    IsLeapYear := true;
    exit;
  end;
  IsLeapYear := AYear mod 25 <> 0;
end;

function TDateTime.DaysToYear(AYear: integer): double;
var
  y, cent: double;
  days: double;
begin
  y := AYear - 1.0;
  cent := Int(y / 100.0);
  days := Int((y * 1461.0) / 4.0) - cent + Int(cent / 4.0);
  DaysToYear := days;
end;

function TDateTime.GetTicks(AYear, AMonth, ADay, AHour, AMinute, ASecond,
  AHundredth: integer): double;
var
  days: DaysToMonthArray;
  result: double;
begin
  if (IsLeapYear(AYear)) then days := DaysToMonth366
  else days := DaysToMonth365;
  result := DaysToYear(AYear) + days[AMonth - 1] + ADay - 1.0;
  result := result * (TicksPerDay * 1.0);
  result := result + (AHour * 1.0) * TicksPerHour;
  result := result + (AMinute * 1.0) * TicksPerMinute;
  result := result + (ASecond * 1.0) * TicksPerSecond;
  result := result + AHundredth;
  GetTicks := result;
end;

function TDateTime.DayOfWeek: TWeekDay;
begin
  DayOfWeek := TWeekDay((Trunc(Ticks / TicksPerDay) + 1) mod 7);
end;

procedure TDateTime.AddDays(ADays: double);
begin
  Ticks := Ticks + ADays * TicksPerDay;
end;

procedure TDateTime.GetDateParts(var AYear: word; var AMonth: byte; var ADay: byte);
var
  num: double;
  y400, y100, y4, y1: double;
  days: DaysToMonthArray;
  m: word;
begin
  num := Int(Ticks / TicksPerDay);
  y400 := Int(num / DaysPer400Years);
  num := num - y400 * DaysPer400Years;
  y100 := Int(num / DaysPer100Years);
  if (y100 = 4) then y100 := 3;
  num := Int(num - y100 * DaysPer100Years);
  y4 := Int(num / DaysPer4Years);
  num := Int(num - y4 * DaysPer4Years);
  y1 := Int(num / DaysPerYear);
  if (y1 = 4) then y1 := 3;
  AYear := Trunc(y400 * 400 + y100 * 100 + y4 * 4 + y1 + 1);

  num := num - y1 * DaysPerYear;
  if (Trunc(y1) = 3) and ((Trunc(y4) <> 24) or (Trunc(y100) = 3)) then
    days := DaysToMonth366
  else
    days := DaysToMonth365;
  m := Trunc(num) shr 5 + 1;
  while num >= days[m] do
    Inc(m);
  AMonth := byte(m);

  ADay := Trunc(num - days[m - 1] + 1);
end;

procedure TDateTime.GetTimeParts(var AHour, AMinute, ASecond, AHundredth: byte);
var
  time: double;
begin
  time := Frac(Ticks / TicksPerDay) * 24;
  AHour := Trunc(time);
  time := (time - AHour) * 60;
  AMinute := Trunc(time);
  time := (time - AMinute) * 60;
  ASecond := Trunc(time);
  time := (time - ASecond) * 100;
  AHundredth := Round(time);
end;

procedure TDateTime.AddYears(AYears: double);
var
  aYear: word;
  aMonth, aDay: byte;
  y, m, d: integer;
  n: double;
begin
  Init;
  GetDateParts(aYear, aMonth, aDay);
  y := aYear + Round(AYears);
  n := DaysToYear(Round(y));
  m := month - 1;
  d := day - 1;
  if IsLeapYear(Round(y)) then
    n := n + DaysInMonth366[aMonth]
  else begin
    if (d = 28) or (m = 1) then
      Dec(d);
    n := n + DaysInMonth365[aMonth];
  end;
  n := n +  d;
  Ticks := n * TicksPerDay;
end;

procedure TDateTime.AddMonths(AMonths: double);
var
  aYear: word;
  aMonth, aDay: byte;
  y, m, d, q, dayCount: integer;
  n: double;
  days: DaysToMonthArray;
  daysToMonth: integer;
begin
  GetDateParts(aYear, aMonth, aDay);
  y := aYear;
  d := aDay;
  m := aMonth + Round(AMonths);
  if m > 0 then
    q := (m - 1) div 12
  else
    q := m div 12 - 1;
  Inc(y, q);
  Dec(m, q * 12);
  if (IsLeapYear(y)) then
    days := DaysToMonth366
  else
    days := DaysToMonth365;
  daysToMonth := days[m - 1];
  dayCount := days[m] - daysToMonth;
  if (d > dayCount) then
    d := dayCount;
  n := DaysToYear(y) + daysToMonth + d - 1;
  Ticks := TicksPerDay * (n + Frac(Ticks / TicksPerDay));
end;

procedure TDateTime.AddHours(AHours: double);
begin
  Ticks := Ticks + AHours * TicksPerHour;
end;

procedure TDateTime.AddMinutes(AMinutes: double);
begin
  Ticks := Ticks + AMinutes * TicksPerMinute;
end;

procedure TDateTime.AddSeconds(ASeconds: double);
begin
  Ticks := Ticks + ASeconds * TicksPerSecond;
end;

procedure TDateTime.AddHundredths(AHundredths: double);
begin
  Ticks := Ticks + AHundredths;
end;

procedure TDateTime.AddTicks(ATickCount: double);
begin
  Ticks := Ticks + ATickCount;
end;

procedure TDateTime.Add(ASpan: PTimeSpan);
begin
  Ticks := Ticks + ASpan^.Ticks;
end;

function TDateTime.Year: word;
var
  aYear: word;
  aMonth, aDay: byte;
begin
  GetDateParts(aYear, aMonth, aDay);
  Year := aYear;
end;

function TDateTime.Month: byte;
var
  aYear: word;
  aMonth, aDay: byte;
begin
  GetDateParts(aYear, aMonth, aDay);
  Month := aMonth;
end;

function TDateTime.Day: byte;
var
  aYear: word;
  aMonth, aDay: byte;
begin
  GetDateParts(aYear, aMonth, aDay);
  Day := aDay;
end;

function TDateTime.Hour: byte;
var
  aHour, aMinute, aSecond, aHundredth: byte;
begin
  GetTimeParts(aHour, aMinute, aSecond, aHundredth);
  Hour := aHour;
end;

function TDateTime.Minute: byte;
var
  aHour, aMinute, aSecond, aHundredth: byte;
begin
  GetTimeParts(aHour, aMinute, aSecond, aHundredth);
  Minute := aMinute;
end;

function TDateTime.Second: byte;
var
  aHour, aMinute, aSecond, aHundredth: byte;
begin
  GetTimeParts(aHour, aMinute, aSecond, aHundredth);
  Second := aSecond;
end;

function TDateTime.Hundredth: byte;
var
  aHour, aMinute, aSecond, aHundredth: byte;
begin
  GetTimeParts(aHour, aMinute, aSecond, aHundredth);
  Hundredth := aHundredth;
end;

function TDateTime.ToString: string;
begin
  ToString := ToStringFormat(DateTimeFormat);
end;

procedure TDateTime.Assign(var ASource: TObject);
var
  source: PDateTime;
begin
  inherited Assign(ASource);
  source := PDateTime(@ASource);
  Ticks := source^.Ticks;
end;

function TDateTime.ToStringFormat(const AFormat: string): string;
var
  result: string;
  aYear: word;
  aMonth, aDay: byte;
  aHour, aMinute, aSecond, aHundredth: byte;
  am: boolean;
  amPos, pmPos: byte;
  amPmString: string;
  is24Hour: boolean;
begin
  result := AFormat;
  GetDateParts(aYear, aMonth, aDay);
  GetTimeParts(aHour, aMinute, aSecond, aHundredth);
  am := false;
  amPos := Pos('AM', result);
  pmPos := Pos('PM', result);
  is24Hour := true;
  if (amPos > 0) or (pmPos > 0) then begin
    amPmString := 'PM';
    if am then
      amPmString := 'AM';
    result := Replace(result, 'AM', '{AP}');
    is24Hour := false;
  end;
  amPos := Pos('am', result);
  pmPos := Pos('pm', result);
  if (amPos > 0) or (pmPos > 0) then begin
    amPmString := 'pm';
    if am then
      amPmString := 'pm';
    result := Replace(result, 'am', '{AP}');
    is24Hour := false;
  end;
  if (not is24Hour) and (aHour > 12) then begin
    Dec(aHour, 12);
    am := true;
  end;
  result := Replace(result, 'YYYY', ZeroPad(aYear, 4));
  result := Replace(result, 'YY', ZeroPad(aYear mod 100, 2));
  result := Replace(result, 'MM', ZeroPad(aMonth, 2));
  result := Replace(result, 'M', IntToStr(aMonth));
  result := Replace(result, 'DD', ZeroPad(aDay, 2));
  result := Replace(result, 'D', IntToStr(aDay));
  result := Replace(result, 'HH', ZeroPad(aHour, 2));
  result := Replace(result, 'H', IntToStr(aHour));
  result := Replace(result, 'mm', ZeroPad(aMinute, 2));
  result := Replace(result, 'm', IntToStr(aMinute));
  result := Replace(result, 'ss', ZeroPad(aSecond, 2));
  result := Replace(result, 's', IntToStr(aSecond));
  result := Replace(result, 'hh', ZeroPad(aHundredth, 2));
  result := Replace(result, 'h', IntToStr(aHundredth));
  result := Replace(result, '{AP}', amPmString);
  ToStringFormat := result;
end;

constructor TTimeSpan.CreateSpan(ATimeSpan: TTimeSpan);
begin
  inherited Create;
  Ticks := ATimeSpan.Ticks;
end;

constructor TTimeSpan.CreateHours(AHours: double);
begin
  inherited Create;
  Ticks := AHours * TicksPerHour;
end;

constructor TTimeSpan.CreateMinutes(AMinutes: double);
begin
  inherited Create;
  Ticks := AMinutes * TicksPerMinute;
end;

constructor TTimeSpan.CreateSeconds(ASeconds: double);
begin
  inherited Create;
  Ticks := ASeconds * TicksPerSecond;
end;

constructor TTimeSpan.CreateHundredths(AHundredths: double);
begin
  inherited Create;
  Ticks := AHundredths;
end;

constructor TTimeSpan.CreateTicks(ATicks: double);
begin
  inherited Create;
  Ticks := ATicks;
end;

constructor TTimeSpan.CreateAll(ADays, AHours, AMinutes, ASeconds, AHundredths: double);
begin
  inherited Create;
  Ticks := 0;
  Ticks := ADays * TicksPerDay;
  Ticks := Ticks + AHours * TicksPerHour;
  Ticks := Ticks + AMinutes * TicksPerMinute;
  Ticks := Ticks + ASeconds * TicksPerSecond;
  Ticks := Ticks + AHundredths;
end;

function TTimeSpan.TotalHundredths: double;
begin
  TotalHundredths := Ticks;
end;

function TTimeSpan.TotalSeconds: double;
begin
  TotalSeconds := Ticks / TicksPerSecond;
end;

function TTimeSpan.TotalMinutes: double;
begin
  TotalMinutes := Ticks / TicksPerMinute;
end;

function TTimeSpan.TotalHours: double;
begin
  TotalHours := Ticks / TicksPerHour;
end;

function TTimeSpan.TotalDays: double;
begin
  TotalDays := Ticks / TicksPerDay;
end;

procedure TTimeSpan.Add(ATimeSpan: TTimeSpan);
begin
  Ticks := Ticks + ATimeSpan.Ticks;
end;

procedure TTimeSpan.AddHundredths(AHundredths: double);
begin
  Ticks := Ticks + AHundredths;
end;

procedure TTimeSpan.AddTicks(ATicks: double);
begin
  Ticks := Ticks + ATicks;
end;

procedure TTimeSpan.AddSeconds(ASeconds: double);
begin
  Ticks := Ticks + ASeconds * TicksPerSecond;
end;

procedure TTimeSpan.AddMinutes(AMinutes: double);
begin
  Ticks := Ticks + AMinutes * TicksPerMinute;
end;

procedure TTimeSpan.AddHours(AHours: double);
begin
  Ticks := Ticks + AHours * TicksPerHour;
end;

procedure TTimeSpan.AddDays(ADays: double);
begin
  Ticks := Ticks + ADays * TicksPerDay;
end;

procedure TTimeSpan.Init;
begin
  inherited Init;
  Ticks := 0;
end;

procedure TTimeSpan.GetDuration(var ATimeSpan: TTimeSpan);
begin
  ATimeSpan.Ticks := Abs(Ticks);
end;

function TTimeSpan.ToString: string;
begin
  ToString := ToStringFormat('HH:mm:ss:hh');
end;

function TStopWatch. ElapsedTicks: double;
begin
  ElapsedTicks := EndTime.Ticks - StartTime.Ticks;
end;

procedure TStopWatch.GetElapsed(var ATimeSpan: TTimeSpan);
begin
  EndTime.SetNow;
  ATimeSpan.Ticks := EndTime.Ticks - StartTime.Ticks;
end;

procedure TStopWatch.Init;
begin
  inherited Init;
  StartTime.CreateTicks(0);
  EndTime.CreateTicks(0);
end;

procedure TStopWatch.Start;
begin
  StartTime.CreateNow;
  EndTime.CreateTicks(StartTime.Ticks);
end;

procedure TStopWatch.Stop;
begin
  EndTime.CreateNow;
end;

procedure TStopWatch.Reset;
begin
  StartTime.CreateTicks(0);
  EndTime.CreateTicks(0);
end;

begin
 DefaultDateFormat := LongDateFormat;
end.