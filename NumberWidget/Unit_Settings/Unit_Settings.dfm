object Form2: TForm2
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 326
  ClientWidth = 324
  Color = clBtnFace
  Constraints.MinHeight = 365
  Constraints.MinWidth = 340
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesktopCenter
  RoundedCorners = rcOn
  OnCreate = FormCreate
  OnMouseWheel = FormMouseWheel
  TextHeight = 15
  object TabControlButtons: TTabControl
    Left = 0
    Top = 291
    Width = 324
    Height = 35
    Align = alBottom
    TabOrder = 1
    object ButtonSave: TButton
      Left = 4
      Top = 6
      Width = 316
      Height = 25
      Cursor = crHandPoint
      Align = alClient
      Caption = 'Ok'
      TabOrder = 0
      OnClick = ButtonSaveClick
    end
  end
  object TabControlBody: TTabControl
    Left = 0
    Top = 0
    Width = 324
    Height = 291
    Align = alClient
    TabOrder = 0
    object GroupBox3: TGroupBox
      Left = 4
      Top = 200
      Width = 316
      Height = 41
      Align = alTop
      Caption = #1055#1086#1083#1086#1078#1077#1085#1080#1077' '#1086#1082#1085#1072
      TabOrder = 0
      object RadioButtonDefaultPosition: TRadioButton
        Left = 6
        Top = 17
        Width = 145
        Height = 17
        Cursor = crHandPoint
        Caption = #1055#1086' '#1094#1077#1085#1090#1088#1091
        Checked = True
        TabOrder = 0
        TabStop = True
        OnClick = RadioButtonDefaultPositionClick
      end
      object RadioButtonLastPosition: TRadioButton
        Left = 166
        Top = 17
        Width = 145
        Height = 17
        Cursor = crHandPoint
        Caption = #1055#1086#1089#1083#1077#1076#1085#1077#1077
        TabOrder = 1
        OnClick = RadioButtonLastPositionClick
      end
    end
    object GroupBox2: TGroupBox
      Left = 4
      Top = 50
      Width = 316
      Height = 40
      Align = alTop
      Caption = #1042#1080#1076
      TabOrder = 1
      object MenuColorTrayIcon: TCheckBox
        Left = 6
        Top = 17
        Width = 150
        Height = 17
        Cursor = crHandPoint
        Caption = #1062#1074#1077#1090#1085#1072#1103' '#1080#1082#1086#1085#1082#1072
        TabOrder = 0
        OnClick = MenuColorTrayIconClick
      end
      object CheckBoxIgnoreMouse: TCheckBox
        Left = 167
        Top = 17
        Width = 145
        Height = 17
        Cursor = crHandPoint
        Caption = #1048#1075#1085#1086#1088#1080#1088#1086#1074#1072#1090#1100' '#1084#1099#1096#1100
        TabOrder = 1
        OnClick = CheckBoxIgnoreMouseClick
      end
    end
    object GroupBoxScale: TGroupBox
      Left = 4
      Top = 155
      Width = 316
      Height = 45
      Align = alTop
      Caption = #1052#1072#1089#1096#1090#1072#1073
      TabOrder = 2
      object TrackBarScale: TTrackBar
        Left = 6
        Top = 17
        Width = 145
        Height = 24
        Cursor = crHandPoint
        Max = 400
        Min = 30
        Position = 100
        TabOrder = 0
        TickStyle = tsNone
        OnChange = TrackBarScaleChange
      end
      object SpinEditScale: TSpinEdit
        Left = 166
        Top = 15
        Width = 145
        Height = 24
        MaxValue = 0
        MinValue = 0
        TabOrder = 1
        Value = 0
        OnChange = SpinEditScaleChange
        OnKeyDown = SpinEditScaleKeyDown
        OnKeyPress = SpinEditScaleKeyPress
      end
    end
    object GroupBoxFont: TGroupBox
      Left = 4
      Top = 90
      Width = 316
      Height = 65
      Align = alTop
      Caption = #1064#1088#1080#1092#1090
      TabOrder = 3
      object CheckNumberFontBold: TCheckBox
        Left = 6
        Top = 43
        Width = 100
        Height = 17
        Cursor = crHandPoint
        Caption = #1055#1086#1083#1091#1078#1080#1088#1085#1099#1081
        TabOrder = 2
        OnClick = CheckNumberFontBoldClick
      end
      object ColorBoxNumber: TColorBox
        Left = 166
        Top = 17
        Width = 145
        Height = 22
        Cursor = crHandPoint
        DefaultColorColor = clWhite
        NoneColorColor = clWhite
        Selected = clWhite
        TabOrder = 0
        OnClick = ColorBoxNumberClick
      end
      object ComboBoxFont: TComboBox
        Left = 6
        Top = 16
        Width = 145
        Height = 23
        Style = csDropDownList
        TabOrder = 1
        OnChange = ComboBoxFontChange
        Items.Strings = (
          'Digital Display Regular'
          'Digital-7'
          'DJB Get Digital'
          'MOSCOW2024'
          'Seven Segment'
          'Typo Digit Demo'
          'Segoe UI')
      end
      object CheckBoxAutoColor: TCheckBox
        Left = 167
        Top = 43
        Width = 144
        Height = 17
        Cursor = crHandPoint
        Caption = #1040#1074#1090#1086' '#1094#1074#1077#1090
        TabOrder = 3
        OnClick = CheckBoxAutoColorClick
      end
    end
    object GroupBox4: TGroupBox
      Left = 4
      Top = 241
      Width = 316
      Height = 46
      Align = alClient
      Caption = #1040#1074#1090#1086#1079#1072#1075#1088#1091#1079#1082#1072
      TabOrder = 4
      object MenuAutostart: TCheckBox
        Left = 6
        Top = 17
        Width = 305
        Height = 17
        Cursor = crHandPoint
        Caption = #1040#1074#1090#1086#1079#1072#1075#1088#1091#1079#1082#1072' '#1087#1088#1080' '#1089#1090#1072#1088#1090#1077' Windows'
        TabOrder = 0
        OnClick = MenuAutostartClick
      end
    end
    object GroupBoxNumber: TGroupBox
      Left = 4
      Top = 6
      Width = 316
      Height = 44
      Align = alTop
      Caption = #1063#1080#1089#1083#1086
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 5
      object SpinEditNumber: TSpinEdit
        Left = 2
        Top = 17
        Width = 312
        Height = 25
        Cursor = crHandPoint
        Align = alClient
        MaxValue = 5000
        MinValue = 1
        TabOrder = 0
        Value = 1
        OnChange = SpinEditNumberChange
        OnKeyDown = SpinEditNumberKeyDown
        OnKeyPress = SpinEditNumberKeyPress
      end
    end
  end
end
