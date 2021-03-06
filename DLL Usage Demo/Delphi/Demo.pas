unit Demo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    DateTimePicker1: TDateTimePicker;
    CheckBox1: TCheckBox;
    procedure FormShow(Sender: TObject);
    procedure Recalc(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    Initialized: boolean;
    procedure FillComboboxes;
    function HistoricDate: TDate;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  Math, VtsCurConvDLLHeader;

const
  MaxAge = 1*60*60;
  Flags = CONVERT_FALLBACK_TO_CACHE;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  tmp: integer;
begin
  if Key = VK_F5 then
  begin
    tmp := ComboBox1.ItemIndex;
    ComboBox1.ItemIndex := ComboBox2.ItemIndex;
    ComboBox2.ItemIndex := tmp;
    Recalc(Sender);
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  FillComboboxes;
  ComboBox1.ItemIndex := Max(0, ComboBox1.Items.IndexOf('USD'));
  ComboBox2.ItemIndex := Max(0, ComboBox2.Items.IndexOf('EUR'));
  Edit1.Text := '';
  Edit2.Text := '';
  Edit1.SetFocus;
  Edit1.Text := '1';
  Edit1.SelectAll;

  Initialized := true;
  Recalc(Sender);
end;

function TForm1.HistoricDate: TDate;
begin
  if CheckBox1.Checked then
    result := DateTimePicker1.Date
  else
    result := 0;
end;

procedure TForm1.Recalc(Sender: TObject);
var
  s: string;
  d: double;
begin
  if not Initialized then exit;  
  s := Edit1.Text;
  if TryStrToFloat(s, d) and (ComboBox1.Text <> '') and (ComboBox2.Text <> '') then
    Edit2.Text := Format('%.2f', [Convert(d, PChar(ComboBox1.Text), PChar(ComboBox2.Text), MaxAge, Flags, HistoricDate)])
  else
    Edit2.Text := '';
end;

procedure TForm1.FillComboboxes;
var
  num: integer;
  s: string;
  i: integer;
begin
  num := AcceptedCurrencies(nil, MaxAge, Flags, HistoricDate);
  SetLength(s, 3*num+1);
  num := AcceptedCurrencies(PChar(s), MaxAge, Flags, HistoricDate);
  ComboBox1.Clear;
  ComboBox2.Clear;
  for i := 0 to num - 1 do
  begin
    ComboBox1.Items.Add(Copy(s, i*3+1, 3));
    ComboBox2.Items.Add(Copy(s, i*3+1, 3));
  end;
end;

end.
