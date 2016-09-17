(*
 * Copyright (c) 2016 Alessandro Fragnani de Morais
 * 
 * The contents of this file are subject to the Mozilla Public License Version 2 (the "License");
 * you may not use this file except in compliance with the License. You may obtain a copy of the
 * License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
 * ANY KIND, either express or implied. See the License for the specific language governing rights
 * and limitations under the License.
 *
 * The Original Code is DUnit. The Initial Developers of the Original Code are Kent Beck, Erich Gamma,
 * and Juancarlo Añez.
 *
 * You need DUnit installled. You can grab your copy at the original DUnit repository 
 * <http://dunit.sourceforge.net>
 *
 * Just add it at your DUnit package and recompile, or add it to your Test project and used it like
 * this:
 *
 * uses
 *    ..., AgiledoxTestRunner;
 *
 * Application.Initialize;
 *
 * if IsConsole then
 * begin
 *   with AgiledoxTestRunner.RunRegisteredTests(mnpUnderscore, cnpPrefix) do
 *     Free;
 *
 * @author: Alessandro Fragnani de Morais <alefragnani@hotmail.com>
 *)

unit AgiledoxTestRunner;

interface

uses
  Classes,
  TestFramework,
  TextTestRunner;

type
  TMethodNamePattern = (mnpUnderscore, mnpCase);
  TClassNamePattern = (cnpPrefix, cnpSuffix);

  TAgiledoxTestListener = class(TTextTestListener)
  private
    FMethodNamePattern: TMethodNamePattern;
    FClassNamePattern: TClassNamePattern;
    function FormatNameInCasePattern(name: string): string;
    function GetAgiledoxTestName(test: ITest): string;
    function GetAgiledoxSuiteName(suite: ITest): string;
    function GetAgiledoxStringFrom(name: string): string;
    function RemoveTestPrefixFrom(name: string): string;
    function RemoveTestSuffixFrom(name: string): string;
    function GetElapsedTimeString: string;
  protected
    function PrintHeader(r: TTestResult): string; override;
    function PrintErrors(r: TTestResult): string; override;
    function PrintFailures(r: TTestResult): string; override;
    function PrintFailureItems(r: TTestResult): string; override;
    function PrintErrorItems(r: TTestResult): string; override;
  public
    constructor Create; overload;
    constructor Create(MethodNamePattern: TMethodNamePattern;
      ClassNamePattern: TClassNamePattern); overload;

    procedure AddSuccess(test: ITest); override;
    procedure AddError(error: TTestFailure); override;
    procedure AddFailure(failure: TTestFailure); override;
    function ShouldRunTest(test: ITest): boolean; override;
    procedure StartSuite(suite: ITest); override;
    procedure StartTest(test: ITest); override;
    procedure TestingStarts; override;
    procedure TestingEnds(testResult: TTestResult); override;
    class function RunTest(suite: ITest;
      MethodNamePattern: TMethodNamePattern = mnpUnderscore;
      ClassNamePattern: TClassNamePattern = cnpSuffix): TTestResult; overload;
    class function RunRegisteredTests(MethodNamePattern
      : TMethodNamePattern = mnpUnderscore;
      ClassNamePattern: TClassNamePattern = cnpSuffix): TTestResult;
  end;

function RunTest(suite: ITest;
  MethodNamePattern: TMethodNamePattern = mnpUnderscore;
  ClassNamePattern: TClassNamePattern = cnpSuffix): TTestResult;
function RunRegisteredTests(MethodNamePattern
  : TMethodNamePattern = mnpUnderscore;
  ClassNamePattern: TClassNamePattern = cnpSuffix): TTestResult;

implementation

uses
  SysUtils;

const
  CRLF = #13#10;

  { TAgiledoxTestListener }

procedure TAgiledoxTestListener.AddSuccess(test: ITest);
var
  aTestSuite: ITestSuite;
begin
  test.QueryInterface(ITestSuite, aTestSuite);
  if not Assigned(aTestSuite) then
    Write('- ' + GetAgiledoxTestName(test) + CRLF);
end;

constructor TAgiledoxTestListener.Create;
begin
  Create(mnpUnderscore, cnpSuffix);
end;

constructor TAgiledoxTestListener.Create(MethodNamePattern: TMethodNamePattern;
  ClassNamePattern: TClassNamePattern);
begin
  FMethodNamePattern := MethodNamePattern;
  FClassNamePattern := ClassNamePattern;
end;

function TAgiledoxTestListener.FormatNameInCasePattern(name: string): string;
var
  len, i: integer;
  hadLowercase: boolean;
begin
  len := length(name);
  Result := '';

  hadLowercase := true;
  for i := 1 to len do
  begin
    if name[i] in ['A' .. 'Z'] then
    begin
      if hadLowercase then
        Result := Result + ' ';

      Result := Result + AnsiLowerCase(name[i])
    end
    else
      Result := Result + name[i];
  end;

  Delete(Result, 1, 1);
end;

procedure TAgiledoxTestListener.AddError(error: TTestFailure);
begin
  Write('- ' + GetAgiledoxTestName(error.FailedTest) + CRLF);
  Write('  (F) ' + error.ThrownExceptionMessage + CRLF);
end;

procedure TAgiledoxTestListener.AddFailure(failure: TTestFailure);
begin
  Write('- ' + GetAgiledoxTestName(failure.FailedTest) + CRLF);
  Write('  (E) ' + failure.ThrownExceptionMessage + CRLF);
end;

function TAgiledoxTestListener.GetAgiledoxSuiteName(suite: ITest): string;
begin
  if FClassNamePattern = cnpPrefix then
    Result := RemoveTestPrefixFrom(suite.name)
  else
    Result := RemoveTestSuffixFrom(suite.name);
end;

function TAgiledoxTestListener.GetAgiledoxTestName(test: ITest): string;
begin
  Result := GetAgiledoxStringFrom(test.name);
end;

function TAgiledoxTestListener.GetElapsedTimeString: string;
var
  hh, mm, ss, ms: Word;
begin
  Result := '';
  endTime := now;
  runTime := endTime - startTime;
  DecodeTime(runTime, hh, mm, ss, ms);

  if hh <> 0 then
    Result := Format('%dh ', [hh]);

  if mm <> 0 then
    Result := Result + Format('%dm ', [mm]);

  if ss <> 0 then
    Result := Result + Format('%ds ', [ss]);

  if ms <> 0 then
    Result := Result + Format('%dms ', [ms]);

  if Result = '' then
    Result := '0ms';
end;

function TAgiledoxTestListener.PrintHeader(r: TTestResult): string;
var
  hadErrors, hadFailures: boolean;
  withFE, withFailures, withErrors, withConnection, withTime: string;
begin
  Result := '';
  withTime := GetElapsedTimeString;

  if r.WasSuccessful then
  begin
    Result := CRLF + Format('Ran %d tests successfully in %s' + CRLF,
      [r.runCount, withTime]);
    Exit;
  end;

  if not r.WasSuccessful then
  begin
    withFailures := '';
    withErrors := '';
    withConnection := '';

    hadErrors := r.errorCount > 0;
    hadFailures := r.FailureCount > 0;

    if hadFailures then
      withFailures := Format(' %d failure(s)', [r.FailureCount]);

    if hadErrors then
      withErrors := Format(' %d error(s)', [r.errorCount]);

    if hadFailures and hadErrors then
      withConnection := ' and';

    withFE := withFailures + withConnection + withErrors;
    Result := CRLF + Format('Ran %d tests with%s in %s',
      [r.runCount, withFE, withTime]);
  end;
end;

function TAgiledoxTestListener.GetAgiledoxStringFrom(name: string): string;
begin
  Result := name;

  Result := RemoveTestPrefixFrom(Result);

  if FMethodNamePattern = mnpUnderscore then
    Result := StringReplace(Result, '_', ' ', [rfReplaceAll])
  else
  begin
    Result := FormatNameInCasePattern(Result);
  end;
end;

function TAgiledoxTestListener.RemoveTestPrefixFrom(name: string): string;
begin
  Result := name;

  if Pos('Test', Result) = 1 then
    Result := copy(Result, 5, length(Result));
end;

function TAgiledoxTestListener.RemoveTestSuffixFrom(name: string): string;
begin
  Result := name;

  if copy(Result, length(Result) - 3, 4) = 'Test' then
    Result := copy(Result, 1, length(Result) - 4);
end;

procedure TAgiledoxTestListener.TestingEnds(testResult: TTestResult);
begin
  writeln(Report(testResult));
end;

procedure TAgiledoxTestListener.TestingStarts;
begin
  writeln;
  writeln;
  startTime := now;
end;

class function TAgiledoxTestListener.RunTest(suite: ITest;
  MethodNamePattern: TMethodNamePattern = mnpUnderscore;
  ClassNamePattern: TClassNamePattern = cnpSuffix): TTestResult;
begin
  Result := TestFramework.RunTest(suite,
    [TAgiledoxTestListener.Create(MethodNamePattern, ClassNamePattern)]);
end;

class function TAgiledoxTestListener.RunRegisteredTests(MethodNamePattern
  : TMethodNamePattern = mnpUnderscore;
  ClassNamePattern: TClassNamePattern = cnpSuffix): TTestResult;
begin
  Result := RunTest(registeredTests, MethodNamePattern, ClassNamePattern);
end;

function RunTest(suite: ITest;
  MethodNamePattern: TMethodNamePattern = mnpUnderscore;
  ClassNamePattern: TClassNamePattern = cnpSuffix): TTestResult;
begin
  Result := TestFramework.RunTest(suite,
    [TAgiledoxTestListener.Create(MethodNamePattern, ClassNamePattern)]);
end;

function RunRegisteredTests(MethodNamePattern
  : TMethodNamePattern = mnpUnderscore;
  ClassNamePattern: TClassNamePattern = cnpSuffix): TTestResult;
begin
  Result := RunTest(registeredTests, MethodNamePattern, ClassNamePattern);
end;

function TAgiledoxTestListener.ShouldRunTest(test: ITest): boolean;
begin
  Result := test.Enabled;
end;

procedure TAgiledoxTestListener.StartSuite(suite: ITest);
begin
  //if CompareText(suite.name, ExtractFileName(Application.ExeName)) = 0 then
  //  Exit;

  Write(CRLF + GetAgiledoxSuiteName(suite) + CRLF);
end;

procedure TAgiledoxTestListener.StartTest(test: ITest);
begin
  // do nothing
end;

function TAgiledoxTestListener.PrintErrorItems(r: TTestResult): string;
begin
  // do nothing
end;

function TAgiledoxTestListener.PrintErrors(r: TTestResult): string;
begin
  // do nothing
end;

function TAgiledoxTestListener.PrintFailureItems(r: TTestResult): string;
begin
  // do nothing
end;

function TAgiledoxTestListener.PrintFailures(r: TTestResult): string;
begin
  // do nothing
end;

end.
