unit MainFormU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Data.DB,
  Vcl.ExtCtrls,
  Vcl.FileCtrl,
  Vcl.ComCtrls,
  Vcl.Grids,
  Vcl.DBGrids,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Vcl.OleCtrls,
  SHDocVw,
  System.Generics.Collections;

type
  TDataItem = class
  private
    fProp2: string;
    fProp3: string;
    fProp1: string;
    fPropInt: Integer;
  public
    constructor Create(const Value1, Value2, Value3: string; const IntValue: Integer);
    property Prop1: string read fProp1 write fProp1;
    property Prop2: string read fProp2 write fProp2;
    property Prop3: string read fProp3 write fProp3;
    property PropInt: Integer read fPropInt write fPropInt;
  end;

  TCategory = class
  private
    fName: string;
    fIcon: string;
  public
    constructor Create(const AName, AIcon: string);
    property Name: string read fName write fName;
    property Icon: string read fIcon write fIcon;
  end;

  TProduct = class
  private
    fId: Integer;
    fName: string;
    fPrice: Double;
    fStock: Integer;
    fCategory: TCategory;
    fOnSale: Boolean;
    fDescription: string;
    fRating: Double;
  public
    constructor Create(AId: Integer; const AName: string; APrice: Double;
      AStock: Integer; ACategory: TCategory; AOnSale: Boolean;
      const ADescription: string; ARating: Double);
    destructor Destroy; override;
    property Id: Integer read fId write fId;
    property Name: string read fName write fName;
    property Price: Double read fPrice write fPrice;
    property Stock: Integer read fStock write fStock;
    property Category: TCategory read fCategory write fCategory;
    property OnSale: Boolean read fOnSale write fOnSale;
    property Description: string read fDescription write fDescription;
    property Rating: Double read fRating write fRating;
  end;

  TStatistic = class
  private
    fTitle: string;
    fValue: Integer;
    fIcon: string;
    fColor: string;
    fTrend: Double;
  public
    constructor Create(const ATitle: string; AValue: Integer;
      const AIcon, AColor: string; ATrend: Double);
    property Title: string read fTitle write fTitle;
    property Value: Integer read fValue write fValue;
    property Icon: string read fIcon write fIcon;
    property Color: string read fColor write fColor;
    property Trend: Double read fTrend write fTrend;
  end;

  TMainForm = class(TForm)
    ds1: TFDMemTable;
    ds1name: TStringField;
    FileListBox1: TFileListBox;
    Panel1: TPanel;
    btnExecute: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    chkOpenGeneratedFile: TCheckBox;
    ds2: TFDMemTable;
    ds1id: TIntegerField;
    ds2id: TIntegerField;
    ds2contact: TStringField;
    ds2contact_type: TStringField;
    ds2id_person: TIntegerField;
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    TabSheet3: TTabSheet;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    ds1country: TStringField;
    MemoTemplate: TMemo;
    MemoOutput: TMemo;
    Panel2: TPanel;
    mmErrors: TMemo;
    procedure btnExecuteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FileListBox1DblClick(Sender: TObject);
  private
    fProducts: TObjectList<TObject>;
    fStats: TObjectList<TObject>;
    fCategories: TObjectList<TCategory>;
    function GetItems: TObjectList<TObject>;
    procedure ExecuteTemplate(const aTemplateString: string);
    procedure CreateProductsAndStats;
  public
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}


uses
  System.IOUtils,
  Winapi.Shellapi,
  RandomTextUtilsU,
  TemplatePro,
  Winapi.ActiveX;

procedure TMainForm.btnExecuteClick(Sender: TObject);
begin
  ExecuteTemplate(MemoTemplate.Lines.Text);
end;

procedure TMainForm.FileListBox1DblClick(Sender: TObject);
begin
  PageControl1.ActivePageIndex := 0;
  if tfile.Exists(FileListBox1.FileName) then
    MemoTemplate.Lines.LoadFromFile(FileListBox1.FileName, TEncoding.UTF8);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  I: Integer;
  J: Integer;
  lName: string;
  lLastName: string;
begin
  ds1.Open;
  ds2.Open;

  for I := 1 to 10 do
  begin
    lName := GetRndFirstName;
    lLastName := getrndlastname;
    ds1.AppendRecord([I, lName + ' ' + lLastName, GetRndCountry]);
    for J := 1 to Random(10) + 2 do
    begin
      ds2.AppendRecord([I * 100 + J, I, Format('%s.%s@%s.com', [lName.Substring(0, 1).ToLower,
        lLastName.ToLower, GetRndCountry.ToLower]), 'email']);
    end;
  end;
  ds1.First;
  ds2.First;

  // Create products and statistics data
  CreateProductsAndStats;
end;

// http://www.cryer.co.uk/brian/delphi/twebbrowser/put_HTML.htm
procedure LoadHtmlIntoBrowser(browser: TWebBrowser; const html: string);
var
  lSWriter: TStreamWriter;
begin
  // -------------------
  // Load a blank page.
  // -------------------
  browser.Navigate('about:blank');
  while browser.ReadyState <> READYSTATE_COMPLETE do
  begin
    Sleep(5);
    Application.ProcessMessages;
  end;
  // ---------------
  // Load the html.
  // ---------------
  lSWriter := TStreamWriter.Create(TMemoryStream.Create);
  try
    lSWriter.OwnStream;
    lSWriter.Write(html);
    lSWriter.BaseStream.Position := 0;
    (browser.Document as IPersistStreamInit).Load(
      TStreamAdapter.Create(lSWriter.BaseStream));
  finally
    lSWriter.Free;
  end;
end;

procedure TMainForm.ExecuteTemplate(const aTemplateString: string);
var
  lCompiler: TTProCompiler;
  lTemplate: string;
  lOutputFileName: string;
  lOutput: string;
  lItems: TObjectList<TObject>;
  lCompiledTmpl: ITProCompiledTemplate;
begin
  lTemplate := aTemplateString;
  lCompiler := TTProCompiler.Create;
  try
    mmErrors.Lines.Clear;
    try
      lCompiledTmpl := lCompiler.Compile(aTemplateString);
      mmErrors.Lines.Add('Compiled with no errors');
    except
      on E: Exception do
      begin
        mmErrors.Lines.Add('Error: ' + E.ClassName);
        mmErrors.Lines.Add(E.Message);
        raise;
      end;
    end;
    lItems := GetItems;
    try
      lCompiledTmpl.SetData('first_name', 'Daniele');
      lCompiledTmpl.SetData('last_name', 'Teti');
      lCompiledTmpl.SetData('today', DateToStr(date));
      lCompiledTmpl.SetData('people', ds1);
      lCompiledTmpl.SetData('contacts', ds2);
      lCompiledTmpl.SetData('items', lItems);
      // Standard variables for demos
      lCompiledTmpl.SetData('value1', 'true');
      lCompiledTmpl.SetData('value2', 'Hello World');
      lCompiledTmpl.SetData('intvalue10', 10);
      lCompiledTmpl.SetData('floatvalue', 1234.5678);
      lCompiledTmpl.SetData('valuedate', Now);
      lCompiledTmpl.SetData('myhtml', '<b>Bold</b> and <i>Italic</i>');
      // New data for expanded demos
      lCompiledTmpl.SetData('products', fProducts);
      lCompiledTmpl.SetData('stats', fStats);
      lCompiledTmpl.SetData('categories', fCategories);
      // Boolean and additional values
      lCompiledTmpl.SetData('is_logged_in', True);
      lCompiledTmpl.SetData('is_admin', False);
      lCompiledTmpl.SetData('show_sidebar', True);
      lCompiledTmpl.SetData('app_name', 'TemplatePro Playground');
      lCompiledTmpl.SetData('app_version', '1.0');
      lCompiledTmpl.SetData('discount_rate', 0.15);
      lCompiledTmpl.SetData('tax_rate', 0.21);
      lOutput := lCompiledTmpl.Render;
    finally
      lItems.Free;
    end;
    TDirectory.CreateDirectory(ExtractFilePath(Application.ExeName) + 'output');
    lOutputFileName := ExtractFilePath(Application.ExeName) + 'output\' +
      'last_output.html';
    TFile.WriteAllText(lOutputFileName, lOutput, TEncoding.UTF8);
    MemoOutput.Lines.LoadFromFile(lOutputFileName);
  finally
    lCompiler.Free;
  end;
  if chkOpenGeneratedFile.Checked then
    ShellExecute(0, pchar('open'), pchar(lOutputFileName), nil, nil, SW_NORMAL);
  PageControl1.ActivePageIndex := 1;
end;

function TMainForm.GetItems: TObjectList<TObject>;
begin
  Result := TObjectList<TObject>.Create(True);
  Result.Add(TDataItem.Create('value1.1', 'value2.1', 'value3.1', 1));
  Result.Add(TDataItem.Create('value1.2', 'value2.2', 'value3.2', 2));
  Result.Add(TDataItem.Create('value1.3', 'value2.3', 'value3.3', 3));
end;

{ TDataItem }

constructor TDataItem.Create(const Value1, Value2, Value3: string; const IntValue: Integer);
begin
  inherited Create;
  fProp1 := Value1;
  fProp2 := Value2;
  fProp3 := Value3;
  fPropInt := IntValue;
end;

{ TCategory }

constructor TCategory.Create(const AName, AIcon: string);
begin
  inherited Create;
  fName := AName;
  fIcon := AIcon;
end;

{ TProduct }

constructor TProduct.Create(AId: Integer; const AName: string; APrice: Double;
  AStock: Integer; ACategory: TCategory; AOnSale: Boolean;
  const ADescription: string; ARating: Double);
begin
  inherited Create;
  fId := AId;
  fName := AName;
  fPrice := APrice;
  fStock := AStock;
  fCategory := ACategory;
  fOnSale := AOnSale;
  fDescription := ADescription;
  fRating := ARating;
end;

destructor TProduct.Destroy;
begin
  // Category is owned by fCategories list, don't free here
  inherited;
end;

{ TStatistic }

constructor TStatistic.Create(const ATitle: string; AValue: Integer;
  const AIcon, AColor: string; ATrend: Double);
begin
  inherited Create;
  fTitle := ATitle;
  fValue := AValue;
  fIcon := AIcon;
  fColor := AColor;
  fTrend := ATrend;
end;

{ TMainForm - Additional methods }

destructor TMainForm.Destroy;
begin
  fProducts.Free;
  fStats.Free;
  fCategories.Free;
  inherited;
end;

procedure TMainForm.CreateProductsAndStats;
var
  lCatElectronics, lCatClothing, lCatBooks, lCatHome: TCategory;
begin
  // Create categories (owned separately)
  fCategories := TObjectList<TCategory>.Create(True);
  lCatElectronics := TCategory.Create('Electronics', '');
  lCatClothing := TCategory.Create('Clothing', '');
  lCatBooks := TCategory.Create('Books', '');
  lCatHome := TCategory.Create('Home & Garden', '');
  fCategories.Add(lCatElectronics);
  fCategories.Add(lCatClothing);
  fCategories.Add(lCatBooks);
  fCategories.Add(lCatHome);

  // Create products
  fProducts := TObjectList<TObject>.Create(True);
  fProducts.Add(TProduct.Create(1, 'Wireless Headphones', 79.99, 150, lCatElectronics, True,
    'Premium noise-cancelling wireless headphones with 30h battery life', 4.5));
  fProducts.Add(TProduct.Create(2, 'Cotton T-Shirt', 24.99, 500, lCatClothing, False,
    'Comfortable 100% cotton t-shirt in various colors', 4.2));
  fProducts.Add(TProduct.Create(3, 'Programming Delphi', 49.99, 75, lCatBooks, True,
    'Complete guide to modern Delphi development', 4.8));
  fProducts.Add(TProduct.Create(4, 'Smart Watch', 199.99, 80, lCatElectronics, True,
    'Feature-rich smartwatch with health monitoring', 4.6));
  fProducts.Add(TProduct.Create(5, 'Garden Tools Set', 89.99, 45, lCatHome, False,
    'Complete set of essential garden tools', 4.3));
  fProducts.Add(TProduct.Create(6, 'Winter Jacket', 129.99, 200, lCatClothing, True,
    'Warm and stylish winter jacket with hood', 4.7));
  fProducts.Add(TProduct.Create(7, 'LED Desk Lamp', 34.99, 300, lCatHome, False,
    'Adjustable LED desk lamp with touch controls', 4.4));
  fProducts.Add(TProduct.Create(8, 'Clean Code Book', 39.99, 120, lCatBooks, False,
    'A handbook of agile software craftsmanship', 4.9));

  // Create statistics
  fStats := TObjectList<TObject>.Create(True);
  fStats.Add(TStatistic.Create('Total Users', 12458, 'users', '#3498db', 12.5));
  fStats.Add(TStatistic.Create('Revenue', 84250, 'dollar', '#2ecc71', 8.3));
  fStats.Add(TStatistic.Create('Orders', 1847, 'shopping-cart', '#9b59b6', -2.1));
  fStats.Add(TStatistic.Create('Visitors', 45892, 'eye', '#e74c3c', 15.7));
end;

end.
