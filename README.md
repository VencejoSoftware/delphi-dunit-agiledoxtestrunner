## DUnit-AgiledoxTestRunner

Agiledox output format for DUnit console runner.

Based on Agiledox project (http://agiledox.sourceforge.net), your tested method should document them selves, like this:

---
    procedure TestTMyClass.TestIsSingleton;
    procedure TestTMyClass.TestAReallyLongNameIsAGoodThing;
    procedure TestTMyClassUnderscore.TestIs_Singleton
    procedure TestTMyClassUnderscore.TestA_Really_Long_Name_Is_A_Good_Thing;
---

Should output this:

----
    TestTMyClass
      - is singleton
      - a really long name is a good thing

    TestTMyClassUnderscore
      - Is Singleton
      - A Really Long Name Is A Good Thing
---


## Installation

Just add **AgiledoxTestRunner.pas** to your path so you project recognizes it.

## Usage

You basically only have to update your project file to use **AgiledoxTestRunner** as the runner.

First you add it to your `uses` clause:

----
    uses
      ..., AgiledoxTestRunner;
----

Then you add, or replace, the console part of your project, like this:

----
    Application.Initialize;

    if IsConsole then
    begin
      with AgiledoxTestRunner.RunRegisteredTests(mnpUnderscore, cnpPrefix) do
        Free;
---

And it's done!

## License

MPL v2