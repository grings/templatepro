program templateprounittests;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Generics.Collections,
  System.IOUtils,
  System.Rtti,
  System.Classes,
  UtilsU in 'UtilsU.pas',
  TemplatePro in '..\TemplatePro.pas';

const
  TestFileNameFilter = '*'; // '*' means "all files'


function SayHelloFilter(const aValue: TValue; const aParameters: TArray<string>): string;
begin
  Result := 'Hello ' + aValue.AsString;
end;


procedure Main;
var
  lTPro: TTProCompiler;
  lInput: string;
  lItems, lItemsWithFalsy: TObjectList<TDataItem>;
begin
  Writeln('   |---------------------------|');
  Writeln('---| TEMPLATE PRO - UNIT TESTS |---');
  Writeln('   |---------------------------|');
  Writeln;
  var lFailed := False;
  lTPro := TTProCompiler.Create;
  try
    var lInputFileNames := TDirectory.GetFiles('..\test_scripts\', '*.tpro',
      function(const Path: string; const SearchRec: TSearchRec): Boolean
      begin
        Result := (not String(SearchRec.Name).StartsWith('included'))
                   and ((TestFileNameFilter = '*') or String(SearchRec.Name).Contains(TestFileNameFilter))
      end);
    for var lFile in lInputFileNames do
    begin
      try
        lInput := TFile.ReadAllText(lFile);
        Write(TPath.GetFileName(lFile).PadRight(30));
        var lCompiledTemplate := lTPro.Compile(lInput, TPath.Combine(GetModuleName(HInstance), '..', '..', 'test_scripts'));
        lCompiledTemplate.SetData('value0','true');
        lCompiledTemplate.SetData('value1','true');
        lCompiledTemplate.SetData('value2','DANIELE2');
        lCompiledTemplate.SetData('value3','DANIELE3');
        lCompiledTemplate.SetData('value4','DANIELE4');
        lCompiledTemplate.SetData('value5','DANIELE5');
        lCompiledTemplate.SetData('value6','DANIELE6');
        lCompiledTemplate.SetData('myhtml','<div>this <strong>HTML</strong></div>');
        lCompiledTemplate.SetData('valuedate', EncodeDate(2024,8,20));
        lCompiledTemplate.AddTemplateFunction('sayhello', SayHelloFilter);
        lItems := GetItems;
        try
          lItemsWithFalsy := GetItems(True);
          try
          lCompiledTemplate.SetData('obj', lItems[0]);
          var lCustomers := GetCustomersDataset;
          try
            lCompiledTemplate.SetData('customers', lCustomers);
            lCompiledTemplate.SetData('objects', lItems);
            lCompiledTemplate.SetData('objectsb', lItemsWithFalsy);
            var lActualOutput := lCompiledTemplate.Render;
            var lExpectedOutput := TFile.ReadAllText(lFile + '.expected.txt');
            if lActualOutput <> lExpectedOutput then
            begin
              WriteLn(': FAILED');
              lCompiledTemplate.DumpToFile(lFile + '.failed.dump.txt');
              TFile.WriteAllText(lFile + '.failed.txt', lActualOutput);
              lFailed := True;
            end
            else
            begin
              if TFile.Exists(lFile + '.failed.txt') then
              begin
                TFile.Delete(lFile + '.failed.txt');
              end;
              if TFile.Exists(lFile + '.failed.dump.txt') then
              begin
                TFile.Delete(lFile + '.failed.dump.txt');
              end;
              WriteLn(': OK');
            end;
          finally
            lCustomers.Free;
          end;
          finally
            lItemsWithFalsy.Free;
          end;
        finally
          lItems.Free;
        end;
      except
        on E: Exception do
        begin
          Writeln(' : FAIL - ' + E.Message);
          lFailed := True;
        end;
      end;
    end;
  finally
    lTPro.Free;
  end;
  if lFailed or (DebugHook <> 0) then
  begin
    Readln;
  end;
end;


begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.