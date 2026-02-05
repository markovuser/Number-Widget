unit Unit_Settings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, ShellApi, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, WindowsDarkMode, IniFiles, Registry,
  Vcl.Samples.Spin, Vcl.Grids, Vcl.Buttons, Vcl.Menus, StrUtils, WinSvc,
  System.UITypes, Vcl.NumberBox, ComCtrls;

type
  TTrackBar = class(ComCtrls.TTrackBar)
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; x, y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure CreateParams(var Params: TCreateParams); override;
  end;

type
  TForm2 = class(TForm)
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
    procedure FormCreate(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure RadioButtonDefaultPositionClick(Sender: TObject);
    procedure RadioButtonLastPositionClick(Sender: TObject);
    procedure LoadNastr;
    procedure CheckAutoStart;
    procedure CreateAutoStart(Enabled: Boolean);
    procedure ApplyScaleImmediately;
    procedure MenuColorTrayIconClick(Sender: TObject);
    procedure MenuAutostartClick(Sender: TObject);
    procedure SpinEditNumberFontSizeKeyPress(Sender: TObject; var Key: Char);
    procedure CheckNumberFontBoldClick(Sender: TObject);
    procedure SpinEditNumberChange(Sender: TObject);
    procedure ColorBoxNumberClick(Sender: TObject);
    procedure ComboBoxFontChange(Sender: TObject);
    procedure TrackBarScaleChange(Sender: TObject);
    procedure SpinEditNumberKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SpinEditNumberKeyPress(Sender: TObject; var Key: Char);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure SpinEditScaleChange(Sender: TObject);
    procedure SpinEditScaleKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SpinEditScaleKeyPress(Sender: TObject; var Key: Char);
    procedure CheckBoxAutoColorClick(Sender: TObject);
    function IsMouseIgnored: Boolean;
    procedure CheckBoxIgnoreMouseClick(Sender: TObject);

  private
    { Private declarations }
    FCurrentScale: Integer;
  public
    { Public declarations }
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

var
  Form2: TForm2;
  i: Int64;

const
  DEFAULT_SCALE = 100;

implementation

{$R *.dfm}

uses
  Unit_Base;

procedure TForm2.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
  Params.WndParent := GetDesktopWindow;
end;

procedure TTrackBar.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := Params.Style;
end;

function TTrackBar.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Position := Position + WheelDelta div 120;
  Result := True;
end;

procedure TTrackBar.MouseDown(Button: TMouseButton; Shift: TShiftState; x, y: Integer);
var
  GlobalPos, LocalPos: TPoint;
begin
  if self.Name = 'TrackBarScale' then
  begin
    if Button = mbLeft then
    begin
      GetCursorPos(GlobalPos);
      LocalPos := Form2.TrackBarScale.ScreenToClient(GlobalPos);
      Form2.TrackBarScale.Position := Round((Form2.TrackBarScale.Max / (Form2.TrackBarScale.Width - 28)) * (LocalPos.x - 14));
    end;
  end;
end;

procedure TForm2.ButtonSaveClick(Sender: TObject);
begin
  Form1.SaveNastr;
  application.ProcessMessages;
  Form2.Close;
end;

procedure TForm2.CheckAutoStart;
var
  Reg: TRegistry;
  AutoStartPath: string;
begin
  // Инициализируем состояние как неотмеченное
  Form2.MenuAutostart.Checked := False;

  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;

    // Открываем ключ автозагрузки (только чтение)
    if Reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Run') then
    begin
      try
        // Проверяем существование записи для нашего приложения
        if Reg.ValueExists(Application.Title) then
        begin
          AutoStartPath := Reg.ReadString(Application.Title);

          // Нормализуем пути для корректного сравнения
          if SameText(Trim(AutoStartPath), Trim(ParamStr(0))) then
          begin
            Form2.MenuAutostart.Checked := True;
          end
          // Дополнительная проверка: может быть путь в кавычках
          else if SameText(Trim(AutoStartPath), '"' + Trim(ParamStr(0)) + '"') then
          begin
            Form2.MenuAutostart.Checked := True;
          end
          // Или путь с аргументами
          else if Pos(Trim(ParamStr(0)), AutoStartPath) > 0 then
          begin
            // Проверяем, что путь - это начало строки
            if SameText(Copy(AutoStartPath, 1, Length(ParamStr(0))), ParamStr(0)) then
            begin
              Form2.MenuAutostart.Checked := True;
            end;
          end;
        end;
      finally
        Reg.CloseKey;
      end;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TForm2.CheckBoxAutoColorClick(Sender: TObject);
begin
  ColorBoxNumber.Enabled := not CheckBoxAutoColor.Checked;
  ColorBoxNumberClick(self);
  Form1.Timer2.Enabled := CheckBoxAutoColor.Checked;
end;

procedure TForm2.LoadNastr;
var
  Ini: TMemIniFile;
begin
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
  if Form2.RadioButtonDefaultPosition.Checked = TRUE then
  begin
    Form2.RadioButtonDefaultPositionClick(self);
  end;

  Form2.RadioButtonLastPosition.Checked := Ini.ReadBool('Option', Form2.RadioButtonLastPosition.Name, false);
  if Form2.RadioButtonLastPosition.Checked = TRUE then
  begin
    Form2.RadioButtonLastPositionClick(self);
  end;


  //RestoreStringInfo;

  application.ProcessMessages;

  // Цветная иконка
  Form2.MenuColorTrayIcon.Checked := Ini.ReadBool('Option', Form2.MenuColorTrayIcon.Name, false);
  try
    if Form2.MenuColorTrayIcon.Checked = TRUE then
    begin
      Form1.TrayIcon1.IconIndex := 2;
      application.ProcessMessages;
    end;

    if Form2.MenuColorTrayIcon.Checked = false then
    begin
      if DarkModeIsEnabled = TRUE then
      begin
        if SystemUsesLightTheme = false then
          Form1.TrayIcon1.IconIndex := 1;
        if SystemUsesLightTheme = TRUE then
          Form1.TrayIcon1.IconIndex := 0;
        application.ProcessMessages;
      end;

      if DarkModeIsEnabled = false then
      begin
        if SystemUsesLightTheme = TRUE then
          Form1.TrayIcon1.IconIndex := 0;
        if SystemUsesLightTheme = false then
          Form1.TrayIcon1.IconIndex := 1;
        application.ProcessMessages;
      end;
    end;
  except
  end;

  // Блокировка положения окна
  Form2.CheckBoxIgnoreMouse.Checked := Ini.ReadBool('Option', CheckBoxIgnoreMouse.Name, false);
  Form2.CheckBoxIgnoreMouseClick(Self);

  SpinEditNumber.Value := Ini.ReadInteger('Option', SpinEditNumber.Name, Trunc(SpinEditNumber.Value));
  Form2.SpinEditNumberChange(self);

  Form2.CheckNumberFontBold.Checked := Ini.ReadBool('Option', Form2.CheckNumberFontBold.Name, false);
  Form2.CheckNumberFontBoldClick(self);

  Form2.CheckBoxAutoColor.Checked := Ini.ReadBool('Option', Form2.CheckBoxAutoColor.Name, false);
  Form2.CheckBoxAutoColorClick(self);

  if Form2.CheckBoxAutoColor.Checked = false then
  begin
    Form2.ColorBoxNumber.Selected := Ini.ReadInteger('Option', Form2.ColorBoxNumber.Name, clWhite);
    Form2.ColorBoxNumberClick(Self);
  end;

  Ini.Free;
end;

procedure TForm2.CheckBoxIgnoreMouseClick(Sender: TObject);
begin
  Form1.UpdateCursorForAllLabels;
end;

function TForm2.IsMouseIgnored: Boolean;
begin
  Result := CheckBoxIgnoreMouse.Checked;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Form1.Globload;
  SpinEditScale.MaxValue := TrackBarScale.Max;
  SpinEditScale.MinValue := TrackBarScale.Min;
  OnMouseWheel := FormMouseWheel;
  //SpinEditNumber по цунтру
  SetWindowLong(SpinEditNumber.Handle, GWL_STYLE, GetWindowLong(SpinEditNumber.Handle, GWL_STYLE) or ES_CENTER);
  SpinEditNumber.Repaint;
end;

procedure TForm2.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  ComponentAtPosition: TControl;
begin
  // Получаем компонент, находящийся под курсором мыши
  ComponentAtPosition := FindDragTarget(Mouse.CursorPos, False);

  // Проверяем, является ли компонент типом TSpinEdit
  if Assigned(ComponentAtPosition) and (ComponentAtPosition is TSpinEdit) then
  begin
    with TComponent(ComponentAtPosition) as TSpinEdit do
    begin
      SetFocus();
      if WheelDelta > 0 then
        Value := Value + 1
      else
        Value := Value - 1;

      SelectAll(); // Выделение текста

      Handled := True;
      application.ProcessMessages;
    end;
  end;

end;

procedure TForm2.ColorBoxNumberClick(Sender: TObject);
begin
  if CheckBoxAutoColor.Checked = false then
  begin
    Form1.LabelNumber.Font.Color := Form2.ColorBoxNumber.Selected;
  end;
end;

procedure TForm2.ComboBoxFontChange(Sender: TObject);
begin
  Form1.FontApply;
  TrackBarScaleChange(Sender);
end;

procedure tForm2.CreateAutoStart(Enabled: Boolean);
var
  Reg: TRegistry;
begin
  if Enabled = true then
  begin
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', TRUE);
    Reg.WriteString(Application.Title, ParamStr(0));
    Reg.CloseKey;
    Reg.Free;
  end;

  if Enabled = false then
  begin
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', TRUE);
    Reg.DeleteValue(Application.Title);
    Reg.CloseKey;
    Reg.Free;
  end;
end;

procedure TForm2.MenuAutostartClick(Sender: TObject);
begin
  if MenuAutostart.Checked then
  begin
    CreateAutoStart(True);
  end
  else
  begin
    CreateAutoStart(false);
  end;
end;

procedure TForm2.MenuColorTrayIconClick(Sender: TObject);
begin
  try
    if Form2.MenuColorTrayIcon.Checked = TRUE then
    begin
      Form1.TrayIcon1.IconIndex := 2;
      application.ProcessMessages;
    end;

    if Form2.MenuColorTrayIcon.Checked = false then
    begin
      if DarkModeIsEnabled = TRUE then
      begin
        if SystemUsesLightTheme = false then
          Form1.TrayIcon1.IconIndex := 1;
        if SystemUsesLightTheme = TRUE then
          Form1.TrayIcon1.IconIndex := 0;
        application.ProcessMessages;
      end;

      if DarkModeIsEnabled = false then
      begin
        if SystemUsesLightTheme = TRUE then
          Form1.TrayIcon1.IconIndex := 0;
        if SystemUsesLightTheme = false then
          Form1.TrayIcon1.IconIndex := 1;
        application.ProcessMessages;
      end;
    end;
  except
  end;
end;

procedure TForm2.RadioButtonDefaultPositionClick(Sender: TObject);
begin
  RadioButtonDefaultPosition.Checked := TRUE;
  RadioButtonLastPosition.Checked := false;
  {Form1.Left := (Screen.WorkAreaWidth - Width - 20) Div 2;
  Form1.Top := (Screen.WorkAreaHeight - Height) Div 2;}
  application.ProcessMessages;
end;

procedure TForm2.RadioButtonLastPositionClick(Sender: TObject);
var
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(Form1.PortablePath);
  RadioButtonLastPosition.Checked := TRUE;
  RadioButtonDefaultPosition.Checked := false;
  Form1.Top := Ini.ReadInteger('Option', 'Top', Form1.Top);
  Form1.Left := Ini.ReadInteger('Option', 'Left', Form1.Left);
  Form1.KeepFormInWorkArea;
  Ini.Free;
end;

procedure TForm2.TrackBarScaleChange(Sender: TObject);
begin
  FCurrentScale := TrackBarScale.Position;
  Form2.SpinEditScale.Value := TrackBarScale.Position;
  TrackBarScale.ShowHint := true;
  TrackBarScale.Hint := inttostr(TrackBarScale.Position);
  ApplyScaleImmediately;
  Application.ProcessMessages;
end;

procedure TForm2.ApplyScaleImmediately;
begin
  if Assigned(Form1) then
  begin
    // Применяем масштаб к главному окну
    Form1.ApplyScale;
  end;
end;

procedure TForm2.SpinEditNumberChange(Sender: TObject);
begin
  Form1.LabelNumber.Caption := inttostr(SpinEditNumber.Value);
end;

procedure TForm2.SpinEditNumberFontSizeKeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm2.SpinEditNumberKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key in [VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_BACK, VK_DELETE] then
    Exit
  else if not (Key in [VK_TAB, VK_RETURN, VK_ESCAPE]) then
    Key := 0;
end;

procedure TForm2.SpinEditNumberKeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm2.SpinEditScaleChange(Sender: TObject);
begin
  TrackBarScale.Position := Form2.SpinEditScale.Value;
end;

procedure TForm2.SpinEditScaleKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key in [VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_BACK, VK_DELETE] then
    Exit
  else if not (Key in [VK_TAB, VK_RETURN, VK_ESCAPE]) then
    Key := 0;
end;

procedure TForm2.SpinEditScaleKeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TForm2.CheckNumberFontBoldClick(Sender: TObject);
begin

  if CheckNumberFontBold.Checked then
  begin
    Form1.Canvas.Font.Style := Form1.Canvas.Font.Style + [fsBold];
  end;

  if CheckNumberFontBold.Checked = false then
  begin
    Form1.Canvas.Font.Style := Form1.Canvas.Font.Style - [fsBold];
  end;
end;

end.

