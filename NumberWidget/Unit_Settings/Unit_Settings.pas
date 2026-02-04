Unit Unit_Settings;

Interface

Uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, ShellApi, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, WindowsDarkMode, IniFiles, Registry,
  Vcl.Samples.Spin, Vcl.Grids, Vcl.Buttons, Vcl.Menus, StrUtils, WinSvc,
  System.UITypes, Vcl.NumberBox, ComCtrls;

Type
  TTrackBar = Class(ComCtrls.TTrackBar)
  Protected
    Procedure MouseDown(Button: TMouseButton; Shift: TShiftState; x, y: Integer); Override;
    Function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; Override;
    Procedure CreateParams(Var Params: TCreateParams); Override;
  End;

Type
  TForm2 = Class(TForm)
    TabControlButtons: TTabControl;
    ButtonSave: TButton;
    TabControlBody: TTabControl;
    GroupBox3: TGroupBox;
    RadioButtonDefaultPosition: TRadioButton;
    RadioButtonLastPosition: TRadioButton;
    GroupBox2: TGroupBox;
    MenuColorTrayIcon: TCheckBox;
    GroupBoxScale: TGroupBox;
    TrackBarScale: TTrackBar;
    GroupBoxFont: TGroupBox;
    CheckNumberFontBold: TCheckBox;
    ColorBoxNumber: TColorBox;
    ComboBoxFont: TComboBox;
    GroupBox4: TGroupBox;
    MenuAutostart: TCheckBox;
    GroupBoxNumber: TGroupBox;
    SpinEditNumber: TSpinEdit;
    SpinEditScale: TSpinEdit;
    CheckBoxAutoColor: TCheckBox;
    CheckBoxIgnoreMouse: TCheckBox;
    Procedure FormCreate(Sender: TObject);
    Procedure ButtonSaveClick(Sender: TObject);
    Procedure RadioButtonDefaultPositionClick(Sender: TObject);
    Procedure RadioButtonLastPositionClick(Sender: TObject);
    Procedure LoadNastr;
    Procedure CheckAutoStart;
    Procedure CreateAutoStart(Enabled: Boolean);
    Procedure ApplyScaleImmediately;
    Procedure MenuColorTrayIconClick(Sender: TObject);
    Procedure MenuAutostartClick(Sender: TObject);
    Procedure SpinEditNumberFontSizeKeyPress(Sender: TObject; Var Key: Char);
    Procedure CheckNumberFontBoldClick(Sender: TObject);
    Procedure SpinEditNumberChange(Sender: TObject);
    Procedure ColorBoxNumberClick(Sender: TObject);
    Procedure ComboBoxFontChange(Sender: TObject);
    Procedure TrackBarScaleChange(Sender: TObject);
    Procedure SpinEditNumberKeyDown(Sender: TObject; Var Key: Word; Shift: TShiftState);
    Procedure SpinEditNumberKeyPress(Sender: TObject; Var Key: Char);
    Procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; Var Handled: Boolean);
    Procedure SpinEditScaleChange(Sender: TObject);
    Procedure SpinEditScaleKeyDown(Sender: TObject; Var Key: Word; Shift: TShiftState);
    Procedure SpinEditScaleKeyPress(Sender: TObject; Var Key: Char);
    Procedure CheckBoxAutoColorClick(Sender: TObject);
    Function IsMouseIgnored: Boolean;
    Procedure CheckBoxIgnoreMouseClick(Sender: TObject);

  Private
    { Private declarations }
    FCurrentScale: Integer;
  Public
    { Public declarations }
  Protected

  End;

Var
  Form2: TForm2;
  i: Int64;

Const
  DEFAULT_SCALE = 100;

Implementation

{$R *.dfm}

Uses
  Unit_Base;

Procedure TTrackBar.CreateParams(Var Params: TCreateParams);
Begin
  Inherited;
  Params.Style := Params.Style;
End;

Function TTrackBar.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
Begin
  Position := Position + WheelDelta Div 120;
  Result := True;
End;

Procedure TTrackBar.MouseDown(Button: TMouseButton; Shift: TShiftState; x, y: Integer);
Var
  GlobalPos, LocalPos: TPoint;
Begin
  If self.Name = 'TrackBarScale' Then
  Begin
    If Button = mbLeft Then
    Begin
      GetCursorPos(GlobalPos);
      LocalPos := Form2.TrackBarScale.ScreenToClient(GlobalPos);
      Form2.TrackBarScale.Position := Round((Form2.TrackBarScale.Max / (Form2.TrackBarScale.Width - 28)) * (LocalPos.x - 14));
    End;
  End;
End;


Procedure TForm2.ButtonSaveClick(Sender: TObject);
Begin
  Form1.SaveNastr;
  application.ProcessMessages;
  Form2.Close;
End;

Procedure TForm2.CheckAutoStart;
Var
  Reg: TRegistry;
  AutoStartPath: String;
Begin
  // Инициализируем состояние как неотмеченное
  Form2.MenuAutostart.Checked := False;

  Reg := TRegistry.Create;
  Try
    Reg.RootKey := HKEY_CURRENT_USER;

    // Открываем ключ автозагрузки (только чтение)
    If Reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Run') Then
    Begin
      Try
        // Проверяем существование записи для нашего приложения
        If Reg.ValueExists(Application.Title) Then
        Begin
          AutoStartPath := Reg.ReadString(Application.Title);

          // Нормализуем пути для корректного сравнения
          If SameText(Trim(AutoStartPath), Trim(ParamStr(0))) Then
          Begin
            Form2.MenuAutostart.Checked := True;
          End
          // Дополнительная проверка: может быть путь в кавычках
          Else If SameText(Trim(AutoStartPath), '"' + Trim(ParamStr(0)) + '"') Then
          Begin
            Form2.MenuAutostart.Checked := True;
          End
          // Или путь с аргументами
          Else If Pos(Trim(ParamStr(0)), AutoStartPath) > 0 Then
          Begin
            // Проверяем, что путь - это начало строки
            If SameText(Copy(AutoStartPath, 1, Length(ParamStr(0))), ParamStr(0)) Then
            Begin
              Form2.MenuAutostart.Checked := True;
            End;
          End;
        End;
      Finally
        Reg.CloseKey;
      End;
    End;
  Finally
    Reg.Free;
  End;
End;

Procedure TForm2.CheckBoxAutoColorClick(Sender: TObject);
Begin
  ColorBoxNumber.Enabled := Not CheckBoxAutoColor.Checked;
  ColorBoxNumberClick(self);
  Form1.Timer2.Enabled := CheckBoxAutoColor.Checked;
End;

Procedure TForm2.LoadNastr;
Var
  Ini: TMemIniFile;
Begin
  CheckAutoStart;
  Ini := TMemIniFile.Create(Form1.PortablePath);
  // Шрифт

  Form2.TrackBarScale.Position := Ini.ReadInteger('Option', Form2.TrackBarScale.Name, 0);
  FCurrentScale := Form2.TrackBarScale.Position;
  Form2.TrackBarScaleChange(self);

  Form2.ComboBoxFont.ItemIndex := Ini.ReadInteger('Option', Form2.ComboBoxFont.Name, 0);
  Form2.ComboBoxFontChange(self);
  // Положение окна
  Form2.RadioButtonDefaultPosition.Checked := Ini.ReadBool('Option', Form2.RadioButtonDefaultPosition.Name, false);
  If Form2.RadioButtonDefaultPosition.Checked = TRUE Then
  Begin
    Form2.RadioButtonDefaultPositionClick(self);
  End;

  Form2.RadioButtonLastPosition.Checked := Ini.ReadBool('Option', Form2.RadioButtonLastPosition.Name, false);
  If Form2.RadioButtonLastPosition.Checked = TRUE Then
  Begin
    Form2.RadioButtonLastPositionClick(self);
  End;


  //RestoreStringInfo;

  application.ProcessMessages;

  // Цветная иконка
  Form2.MenuColorTrayIcon.Checked := Ini.ReadBool('Option', Form2.MenuColorTrayIcon.Name, false);
  Try
    If Form2.MenuColorTrayIcon.Checked = TRUE Then
    Begin
      Form1.TrayIcon1.IconIndex := 2;
      application.ProcessMessages;
    End;

    If Form2.MenuColorTrayIcon.Checked = false Then
    Begin
      If DarkModeIsEnabled = TRUE Then
      Begin
        If SystemUsesLightTheme = false Then
          Form1.TrayIcon1.IconIndex := 1;
        If SystemUsesLightTheme = TRUE Then
          Form1.TrayIcon1.IconIndex := 0;
        application.ProcessMessages;
      End;

      If DarkModeIsEnabled = false Then
      Begin
        If SystemUsesLightTheme = TRUE Then
          Form1.TrayIcon1.IconIndex := 0;
        If SystemUsesLightTheme = false Then
          Form1.TrayIcon1.IconIndex := 1;
        application.ProcessMessages;
      End;
    End;
  Except
  End;

  // Блокировка положения окна
  Form2.CheckBoxIgnoreMouse.Checked := Ini.ReadBool('Option', CheckBoxIgnoreMouse.Name, false);
  Form2.CheckBoxIgnoreMouseClick(Self);

  SpinEditNumber.Value := Ini.ReadInteger('Option', SpinEditNumber.Name, Trunc(SpinEditNumber.Value));
  Form2.SpinEditNumberChange(self);

  Form2.CheckNumberFontBold.Checked := Ini.ReadBool('Option', Form2.CheckNumberFontBold.Name, false);
  Form2.CheckNumberFontBoldClick(self);

  Form2.CheckBoxAutoColor.Checked := Ini.ReadBool('Option', Form2.CheckBoxAutoColor.Name, false);
  Form2.CheckBoxAutoColorClick(self);

  If Form2.CheckBoxAutoColor.Checked = false Then
  Begin
    Form2.ColorBoxNumber.Selected := Ini.ReadInteger('Option', Form2.ColorBoxNumber.Name, clWhite);
    Form2.ColorBoxNumberClick(Self);
  End;

  Ini.Free;
End;

Procedure TForm2.CheckBoxIgnoreMouseClick(Sender: TObject);
Begin
  Form1.UpdateCursorForAllLabels;
End;

Function TForm2.IsMouseIgnored: Boolean;
Begin
  Result := CheckBoxIgnoreMouse.Checked;
End;

Procedure TForm2.FormCreate(Sender: TObject);
Begin
  Form1.Globload;
  SpinEditScale.MaxValue := TrackBarScale.Max;
  SpinEditScale.MinValue := TrackBarScale.Min;
  OnMouseWheel := FormMouseWheel;
  //SpinEditNumber по цунтру
  SetWindowLong(SpinEditNumber.Handle, GWL_STYLE, GetWindowLong(SpinEditNumber.Handle, GWL_STYLE) Or ES_CENTER);
  SpinEditNumber.Repaint;
End;

Procedure TForm2.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; Var Handled: Boolean);
Var
  ComponentAtPosition: TControl;
Begin
  // Получаем компонент, находящийся под курсором мыши
  ComponentAtPosition := FindDragTarget(Mouse.CursorPos, False);

  // Проверяем, является ли компонент типом TSpinEdit
  If Assigned(ComponentAtPosition) And (ComponentAtPosition Is TSpinEdit) Then
  Begin
    With TComponent(ComponentAtPosition) As TSpinEdit Do
    Begin
      SetFocus();
      If WheelDelta > 0 Then
        Value := Value + 1
      Else
        Value := Value - 1;

      SelectAll(); // Выделение текста

      Handled := True;
      application.ProcessMessages;
    End;
  End;

End;

Procedure TForm2.ColorBoxNumberClick(Sender: TObject);
Begin
  If CheckBoxAutoColor.Checked = false Then
  Begin
    Form1.LabelNumber.Font.Color := Form2.ColorBoxNumber.Selected;
  End;
End;

Procedure TForm2.ComboBoxFontChange(Sender: TObject);
Begin
  Form1.FontApply;
  TrackBarScaleChange(Sender);
End;

Procedure tForm2.CreateAutoStart(Enabled: Boolean);
Var
  Reg: TRegistry;
Begin
  If Enabled = true Then
  Begin
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', TRUE);
    Reg.WriteString(Application.Title, ParamStr(0));
    Reg.CloseKey;
    Reg.Free;
  End;

  If Enabled = false Then
  Begin
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', TRUE);
    Reg.DeleteValue(Application.Title);
    Reg.CloseKey;
    Reg.Free;
  End;
End;

Procedure TForm2.MenuAutostartClick(Sender: TObject);
Begin
  If MenuAutostart.Checked Then
  Begin
    CreateAutoStart(True);
  End
  Else
  Begin
    CreateAutoStart(false);
  End;
End;

Procedure TForm2.MenuColorTrayIconClick(Sender: TObject);
Begin
  Try
    If Form2.MenuColorTrayIcon.Checked = TRUE Then
    Begin
      Form1.TrayIcon1.IconIndex := 2;
      application.ProcessMessages;
    End;

    If Form2.MenuColorTrayIcon.Checked = false Then
    Begin
      If DarkModeIsEnabled = TRUE Then
      Begin
        If SystemUsesLightTheme = false Then
          Form1.TrayIcon1.IconIndex := 1;
        If SystemUsesLightTheme = TRUE Then
          Form1.TrayIcon1.IconIndex := 0;
        application.ProcessMessages;
      End;

      If DarkModeIsEnabled = false Then
      Begin
        If SystemUsesLightTheme = TRUE Then
          Form1.TrayIcon1.IconIndex := 0;
        If SystemUsesLightTheme = false Then
          Form1.TrayIcon1.IconIndex := 1;
        application.ProcessMessages;
      End;
    End;
  Except
  End;
End;

Procedure TForm2.RadioButtonDefaultPositionClick(Sender: TObject);
Begin
  RadioButtonDefaultPosition.Checked := TRUE;
  RadioButtonLastPosition.Checked := false;
  {Form1.Left := (Screen.WorkAreaWidth - Width - 20) Div 2;
  Form1.Top := (Screen.WorkAreaHeight - Height) Div 2;}
  application.ProcessMessages;
End;

Procedure TForm2.RadioButtonLastPositionClick(Sender: TObject);
Var
  Ini: TMemIniFile;
Begin
  Ini := TMemIniFile.Create(Form1.PortablePath);
  RadioButtonLastPosition.Checked := TRUE;
  RadioButtonDefaultPosition.Checked := false;
  Form1.Top := Ini.ReadInteger('Option', 'Top', Form1.Top);
  Form1.Left := Ini.ReadInteger('Option', 'Left', Form1.Left);
  Form1.KeepFormInWorkArea;
  Ini.Free;
End;

Procedure TForm2.TrackBarScaleChange(Sender: TObject);
Begin
  FCurrentScale := TrackBarScale.Position;
  Form2.SpinEditScale.Value := TrackBarScale.Position;
  TrackBarScale.ShowHint := true;
  TrackBarScale.Hint := inttostr(TrackBarScale.Position);
  ApplyScaleImmediately;
  Application.ProcessMessages;
End;

Procedure TForm2.ApplyScaleImmediately;
Begin
  If Assigned(Form1) Then
  Begin
    // Применяем масштаб к главному окну
    Form1.ApplyScale;
  End;
End;

Procedure TForm2.SpinEditNumberChange(Sender: TObject);
Begin
  Form1.LabelNumber.Caption := inttostr(SpinEditNumber.Value);
End;

Procedure TForm2.SpinEditNumberFontSizeKeyPress(Sender: TObject; Var Key: Char);
Begin
  Key := #0;
End;

Procedure TForm2.SpinEditNumberKeyDown(Sender: TObject; Var Key: Word; Shift: TShiftState);
Begin
  If Key In [VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_BACK, VK_DELETE] Then
    Exit
  Else If Not (Key In [VK_TAB, VK_RETURN, VK_ESCAPE]) Then
    Key := 0;
End;

Procedure TForm2.SpinEditNumberKeyPress(Sender: TObject; Var Key: Char);
Begin
  Key := #0;
End;

Procedure TForm2.SpinEditScaleChange(Sender: TObject);
Begin
  TrackBarScale.Position := Form2.SpinEditScale.Value;
End;

Procedure TForm2.SpinEditScaleKeyDown(Sender: TObject; Var Key: Word; Shift: TShiftState);
Begin
  If Key In [VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_BACK, VK_DELETE] Then
    Exit
  Else If Not (Key In [VK_TAB, VK_RETURN, VK_ESCAPE]) Then
    Key := 0;
End;

Procedure TForm2.SpinEditScaleKeyPress(Sender: TObject; Var Key: Char);
Begin
  Key := #0;
End;

Procedure TForm2.CheckNumberFontBoldClick(Sender: TObject);
Begin

  If CheckNumberFontBold.Checked Then
  Begin
    Form1.Canvas.Font.Style := Form1.Canvas.Font.Style + [fsBold];
  End;

  If CheckNumberFontBold.Checked = false Then
  Begin
    Form1.Canvas.Font.Style := Form1.Canvas.Font.Style - [fsBold];
  End;
End;

End.

