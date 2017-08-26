object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Currency converter'
  ClientHeight = 114
  ClientWidth = 381
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnKeyUp = FormKeyUp
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 184
    Top = 23
    Width = 11
    Height = 18
    Caption = '='
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object ComboBox1: TComboBox
    Left = 111
    Top = 24
    Width = 58
    Height = 21
    Style = csDropDownList
    TabOrder = 1
    OnChange = Recalc
  end
  object ComboBox2: TComboBox
    Left = 303
    Top = 24
    Width = 58
    Height = 21
    Style = csDropDownList
    TabOrder = 3
    OnChange = Recalc
  end
  object Edit1: TEdit
    Left = 24
    Top = 24
    Width = 81
    Height = 21
    TabOrder = 0
    Text = 'Edit1'
    OnChange = Recalc
  end
  object Edit2: TEdit
    Left = 216
    Top = 24
    Width = 81
    Height = 21
    TabStop = False
    Color = clBtnFace
    ReadOnly = True
    TabOrder = 2
    Text = 'Edit1'
  end
  object CheckBox1: TCheckBox
    Left = 24
    Top = 80
    Width = 89
    Height = 17
    TabStop = False
    Caption = 'Historic date:'
    TabOrder = 5
    OnClick = Recalc
  end
  object DateTimePicker1: TDateTimePicker
    Left = 119
    Top = 76
    Width = 97
    Height = 21
    Date = 42973.608142604160000000
    Time = 42973.608142604160000000
    TabOrder = 4
    TabStop = False
    OnChange = Recalc
  end
end
