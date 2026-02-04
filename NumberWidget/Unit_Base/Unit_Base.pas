unit Unit_Base;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Winsock, IniFiles, Vcl.Menus, Registry,
  WindowsDarkMode, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, Vcl.Themes,
  Vcl.Styles, Vcl.Imaging.pngimage, System.ImageList, Vcl.ImgList, Translation,
  IdComponent, IdBaseComponent, IdTCPConnection, IdTCPClient, IdHTTP, ShellAPI,
  Vcl.ComCtrls, Vcl.ToolWin, ActiveX, ComObj, DateUtils, ShlObj, Math, JPEG,
  System.Types, FileInfoUtils;

type
  TWmMoving = record
    Msg: Cardinal;
    fwSide: Cardinal;
    lpRect: PRect;
    Result: Integer;
  end;

  TForm1 = class(TForm)
    Timer1: TTimer;
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    MenuExit: TMenuItem;
    N3: TMenuItem;
    MenuAbout: TMenuItem;
    N5: TMenuItem;
    ImageList1: TImageList;
    N1: TMenuItem;
    N6: TMenuItem;
    Settings: TMenuItem;
    MenuCheckUpdate: TMenuItem;
    ThemeMenu: TMenuItem;
    ThemeAuto: TMenuItem;
    ThemeLight: TMenuItem;
    ThemeDark: TMenuItem;
    PopupMenuLanguage: TPopupMenu;
    LangMonday: TMenuItem;
    LangTuesday: TMenuItem;
    LangWednesday: TMenuItem;
    LangThursday: TMenuItem;
    LangFriday: TMenuItem;
    LangSaturday: TMenuItem;
    LangSunday: TMenuItem;
    LangOnlyWindows: TMenuItem;
    LangError: TMenuItem;
    Version: TMenuItem;
    LanguageMenu: TMenuItem;
    LabelNumber: TLabel;
    Timer2: TTimer;
    Name: TMenuItem;

    procedure MenuExitClick(Sender: TObject);
    procedure LoadNastr;
    procedure SaveNastr;
    procedure Globload;
    procedure CleanTranslationsLikeGlobload;
    procedure LoadLanguage;
    procedure FontApply;
    procedure ApplyScale;
    procedure UnCheckTheme;
    procedure WMMoving(var Msg: TWmMoving); message WM_MOVING;
    procedure FormCreate(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure TrayIcon1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MenuAboutClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SettingsClick(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure MenuCheckUpdateClick(Sender: TObject);
    procedure ThemeAutoClick(Sender: TObject);
    procedure ThemeLightClick(Sender: TObject);
    procedure ThemeDarkClick(Sender: TObject);
    function IsWindows10Or11: Boolean;
    function PortablePath: string;
    function GetAppDataRoamingPath: string;
    procedure Timer1Timer(Sender: TObject);
    procedure WMEraseBkgnd(var Msg: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure KeepFormInWorkArea;
    procedure Timer2Timer(Sender: TObject);
    procedure UpdateCursorForAllLabels;

  private
    Color: TColor;
    FIsProcessingWallpaper: Boolean;
    FIsProcessingWallpaperA: Boolean;
    FLastWallpaperPath: string;
    FCachedDesktopColor: TColor;
    FLastUpdateTime: Cardinal;
    FOriginalWidth: Integer;
    FOriginalHeight: Integer;
    NewDesktopColor: TColor;
    FProcessPrioritySet: Boolean;
    procedure WMExitSizeMove(var Msg: TMessage); message WM_EXITSIZEMOVE;
    procedure WMSettingChange(var Message: TWMSettingChange); message WM_SETTINGCHANGE;
    procedure WMMove(var Msg: TWMMove); message WM_MOVE;
    procedure WMSysColorChange(var Message: TMessage); message WM_SYSCOLORCHANGE;
    procedure LanguageMenuItemClick(Sender: TObject);
    procedure SetAsBackgroundProcess;
    function GetDesktopColor: TColor;
    function GetContrastColor(Color: TColor): TColor;
   // Function GetCurrentWallpaper: Boolean;
    procedure GetDesktopColorAsync;
    procedure GetDesktopColorAsyncA;
    procedure LabelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

  protected
    procedure CreateParams(var Params: TCreateParams); override;

  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  Form1: TForm1;
  FontName: string;
  portable: Boolean;
  LangCode: string;
  LangLocal: string;

const
  ServerName = 'Number-Widget';
  ApiGithub = 'https://api.github.com/repos/markovuser/' + ServerName + '/releases/latest';
  DEFAULT_SCALE = 100;

implementation

uses
  Unit_About, Unit_Settings, Unit_Update;

{$R *.dfm}

{ TForm1 }

procedure TForm1.WMEraseBkgnd(var Msg: TWmEraseBkgnd);
begin
  // Запрещаем полное стирание фона окна
  Msg.Result := 1;
end;

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProcessPrioritySet := False;
end;

procedure TForm1.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);

  Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW;
  Params.ExStyle := Params.ExStyle or WS_EX_NOACTIVATE;
  Params.WndParent := GetDesktopWindow;
end;

procedure TForm1.SetAsBackgroundProcess;
var
  ProcessHandle: THandle;
begin
  if FProcessPrioritySet then
    Exit;

  ProcessHandle := OpenProcess(PROCESS_SET_INFORMATION, False, GetCurrentProcessId);
  if ProcessHandle <> 0 then
  try
    SetPriorityClass(ProcessHandle, BELOW_NORMAL_PRIORITY_CLASS);
    FProcessPrioritySet := True;
  finally
    CloseHandle(ProcessHandle);
  end;
end;

function TForm1.IsWindows10Or11: Boolean;
begin
  Result := (TOSVersion.Major = 10) and (TOSVersion.Build >= 10240);
end;

procedure TForm1.WMSettingChange(var Message: TWMSettingChange);
begin
  if Message.Flag = SPI_SETWORKAREA then
  begin
    Form2.TrackBarScale.Position := Form2.TrackBarScale.Position + 1;
    Form2.TrackBarScale.Position := Form2.TrackBarScale.Position - 1;
  end;
  if ThemeAuto.Checked then
  begin
    try
      if DarkModeIsEnabled then
        SetSpecificThemeMode(True, 'Windows11 Modern Dark', 'Windows11 Modern Light')
      else
        SetSpecificThemeMode(True, 'Windows11 Modern Light', 'Windows11 Modern Dark');
    except
    end;
  end;

  try
    if Assigned(Form2) then
      Form2.MenuColorTrayIconClick(Self);
  except
  end;
end;

procedure TForm1.Globload;
var
  i: Integer;
  Internat: TTranslation;
  Ini: TMemIniFile;
  lang, lang_file: string;
begin
  for i := 0 to Screen.FormCount - 1 do
  begin
    Ini := TMemIniFile.Create(PortablePath);
    try
      lang := Ini.ReadString('Language', 'Language', '');
      lang_file := ExtractFilePath(ParamStr(0)) + 'Language\' + lang + '.ini';
    finally
      Ini.Free;
    end;

    if FileExists(lang_file) then
    begin
      Ini := TMemIniFile.Create(lang_file);
      try
        if Ini.SectionExists(Application.Title) then
        begin
          Internat.Execute(Screen.Forms[i], Application.Title);
        end;
      finally
        Ini.Free;
      end;
    end;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveNastr;
end;

function LoadResourceFontByName(const ResourceName: string; ResType: PChar): Boolean;
var
  ResStream: TResourceStream;
  FontsCount: DWORD;
begin
  ResStream := TResourceStream.Create(hInstance, ResourceName, ResType);
  try
    Result := (AddFontMemResourceEx(ResStream.Memory, ResStream.Size, nil, @FontsCount) <> 0);
  finally
    ResStream.Free;
  end;
end;

function LoadResourceFontByID(ResourceID: Integer; ResType: PChar): Boolean;
var
  ResStream: TResourceStream;
  FontsCount: DWORD;
begin
  ResStream := TResourceStream.CreateFromID(hInstance, ResourceID, ResType);
  try
    Result := (AddFontMemResourceEx(ResStream.Memory, ResStream.Size, nil, @FontsCount) <> 0);
  finally
    ResStream.Free;
  end;
end;

procedure TForm1.FontApply;
begin
  try
    if Form2.ComboBoxFont.ItemIndex <> 6 then
    begin
      if LoadResourceFontByID(Form2.ComboBoxFont.ItemIndex + 1, RT_FONT) then
        Form1.Labelnumber.Font.Name := Form2.ComboBoxFont.Text;
    end;
    if Form2.ComboBoxFont.ItemIndex = 6 then
    begin
      Form1.Labelnumber.Font.Name := 'Segoe UI';
    end;
  except
  end;

end;

procedure TForm1.LoadLanguage;
var
  Ini: TMemIniFile;
  LangFiles: TStringList;
  i: Integer;
  MenuItem: TMenuItem;
  FileName, DisplayName, MenuCaption: string;
  SearchRec: TSearchRec;
begin
  Ini := TMemIniFile.Create(PortablePath);
  try
    LangLocal := Ini.ReadString('Language', 'Language', '');
  finally
    Ini.Free;
  end;

  while LanguageMenu.Count > 0 do
    LanguageMenu.Items[0].Free;

  LangFiles := TStringList.Create;
  try
    if FindFirst(ExtractFilePath(ParamStr(0)) + 'Language\*.ini', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          LangFiles.Add(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;

    LangFiles.Sort;

    for i := 0 to LangFiles.Count - 1 do
    begin
      FileName := LangFiles[i];
      LangCode := ChangeFileExt(FileName, '');
      DisplayName := LangCode;

      try
        Ini := TMemIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Language\' + FileName);
        try
          DisplayName := Ini.ReadString('Language information', 'LANGNAME', LangCode);
        finally
          Ini.Free;
        end;
      except
      end;

      MenuCaption := LangCode + #9#9 + DisplayName;
      MenuItem := TMenuItem.Create(LanguageMenu);
      MenuItem.RadioItem := True;
      MenuItem.Caption := MenuCaption;
      MenuItem.AutoHotkeys := maManual;
      MenuItem.AutoCheck := True;

      if SameText(LangCode, LangLocal) or SameText(LangCode + '.ini', LangLocal) then
        MenuItem.Checked := True;

      MenuItem.OnClick := LanguageMenuItemClick;
      LanguageMenu.Add(MenuItem);
    end;
  finally
    LangFiles.Free;
  end;
end;

procedure TForm1.LanguageMenuItemClick(Sender: TObject);
var
  MenuItem: TMenuItem;
  Ini: TMemIniFile;
  i: Integer;
begin
  if Sender is TMenuItem then
  begin
    MenuItem := TMenuItem(Sender);
    LangCode := Copy(MenuItem.Caption, 1, Pos(#9, MenuItem.Caption) - 1);
    LangLocal := LangCode;
    for i := 0 to LanguageMenu.Count - 1 do
      LanguageMenu.Items[i].Checked := False;
    MenuItem.Checked := True;
    Ini := TMemIniFile.Create(PortablePath);
    try
      Ini.WriteString('Language', 'Language', LangLocal);
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
    LoadLanguage;
    Globload;
  end;
end;

procedure TForm1.CleanTranslationsLikeGlobload;
var
  i, j, k, m: Integer;
  Ini: TMemIniFile;
  Sections, Keys: TStringList;
  SearchRec: TSearchRec;
  FindResult: Integer;
  CompPath, FormName, CompName, PropName: string;
  FirstDot, SecondDot: Integer;
  FormExists, CompExists: Boolean;
  CurrentForm: TForm;
  CurrentComponent: TComponent;
  Modified: Boolean;
  IsDuplicate: Boolean;
  n: Integer;
  CompareKey, CompareFormName: string;
  CompareDotPos: Integer;
begin
  // Создаем все формы проекта (если нужно)
  // CreateAllProjectForms;

  FindResult := FindFirst(ExtractFilePath(ParamStr(0)) + 'Language\*.ini', faAnyFile, SearchRec);
  if FindResult = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        Ini := TMemIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Language\' + SearchRec.Name);
        Sections := TStringList.Create;
        Keys := TStringList.Create;
        Modified := False;

        try
          Ini.ReadSections(Sections);

          for i := 0 to Sections.Count - 1 do
          begin
            // ========== ИСКЛЮЧАЕМ ЭТИ СЕКЦИИ ИЗ ОБРАБОТКИ ==========
            if SameText(Sections[i], 'Language information') or SameText(Sections[i], 'DestDir') then
              Continue; // Пропускаем эти секции полностью

            Ini.ReadSection(Sections[i], Keys);

            // Проходим по всем ключам в обратном порядке
            for j := Keys.Count - 1 downto 0 do
            begin
              CompPath := Keys[j];
              FirstDot := Pos('.', CompPath);

              if FirstDot > 0 then
              begin
                FormName := Copy(CompPath, 1, FirstDot - 1);
                FormExists := False;
                CompExists := False;

                // ==================== ПРОВЕРКА СУЩЕСТВОВАНИЯ КОМПОНЕНТА ====================
                // Проверяем ВСЕ формы в Screen
                for k := 0 to Screen.FormCount - 1 do
                begin
                  if SameText(Screen.Forms[k].Name, FormName) then
                  begin
                    FormExists := True;
                    CurrentForm := Screen.Forms[k];

                    // Извлекаем остаток пути после имени формы
                    CompName := Copy(CompPath, FirstDot + 1, Length(CompPath));
                    SecondDot := Pos('.', CompName);

                    if SecondDot > 0 then
                    begin
                      // Есть вложенный компонент: Form1.TrayIcon1.Hint
                      PropName := Copy(CompName, SecondDot + 1, Length(CompName));
                      CompName := Copy(CompName, 1, SecondDot - 1);

                      // Ищем компонент на форме
                      CurrentComponent := CurrentForm.FindComponent(CompName);

                      // Если не нашли через FindComponent, ищем вручную
                      if CurrentComponent = nil then
                      begin
                        for m := 0 to CurrentForm.ComponentCount - 1 do
                        begin
                          if SameText(CurrentForm.Components[m].Name, CompName) then
                          begin
                            CurrentComponent := CurrentForm.Components[m];
                            Break;
                          end;
                        end;
                      end;

                      CompExists := (CurrentComponent <> nil);
                    end
                    else
                    begin
                      // Нет второй точки - это свойство формы (Form1.Caption)
                      CompExists := True;
                    end;

                    Break; // Форма найдена, выходим из цикла
                  end;
                end;

                // ==================== ПРОВЕРКА ДУБЛИКАТОВ ====================
                IsDuplicate := False;
                // Проверяем предыдущие ключи на дубликаты (только внутри той же формы)
                for n := 0 to j - 1 do
                begin
                  CompareKey := Keys[n];
                  CompareDotPos := Pos('.', CompareKey);

                  if CompareDotPos > 0 then
                  begin
                    CompareFormName := Copy(CompareKey, 1, CompareDotPos - 1);

                    // Дубликатом считаем только если:
                    // 1. Имя формы совпадает
                    // 2. Полный путь совпадает (регистронезависимо)
                    if (SameText(FormName, CompareFormName)) and (SameText(CompPath, CompareKey)) then
                    begin
                      IsDuplicate := True;
                      Break;
                    end;
                  end;
                end;

                // ==================== УДАЛЕНИЕ КЛЮЧА ====================
                // Удаляем если:
                // 1. Форма или компонент не существуют ИЛИ
                // 2. Найден дубликат в той же форме
                if (not (FormExists and CompExists)) or IsDuplicate then
                begin
                  Ini.DeleteKey(Sections[i], Keys[j]);
                  Modified := True;
                end;
              end
              else
              begin
                // Некорректный формат - удаляем
                Ini.DeleteKey(Sections[i], Keys[j]);
                Modified := True;
              end;
            end;

            // Проверяем, не пустая ли секция после удаления
            // (кроме исключенных секций)
            if not (SameText(Sections[i], 'Language information') or SameText(Sections[i], 'DestDir')) then
            begin
              Ini.ReadSection(Sections[i], Keys);
              if Keys.Count = 0 then
              begin
                Ini.EraseSection(Sections[i]);
                Modified := True;
              end;
            end;
          end;

          if Modified then
            Ini.UpdateFile;

        finally
          Keys.Free;
          Sections.Free;
          Ini.Free;
        end;
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

function GetApplicationBitness: string;
begin
  {$IFDEF WIN64}
  Result := '(64-bit)';
  {$ELSE}
  Result := '(32-bit)';
  {$ENDIF}
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  portable := fileExists(ExtractFilePath(ParamStr(0)) + 'portable.ini');
  Form1.Caption := Form1.Caption + ' ' + GetFileVersion(ParamStr(0)) + ' ' + GetApplicationBitness;
  if portable then
    Form1.Caption := Form1.Caption + ' Portable';
  Name.Caption := GetFileDescription(ParamStr(0));
  Version.Caption := GetFileVersion(ParamStr(0)) + ' ' + GetApplicationBitness;

  SetWindowPos(Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE or SWP_NOREDRAW or SWP_FRAMECHANGED);
  ShowWindow(Application.Handle, SW_HIDE);
  SetAsBackgroundProcess;
  LoadNastr;
  FontApply;
  LoadLanguage;
  Color := GetDesktopColor;
  LabelNumber.OnMouseDown := LabelMouseDown;
end;

procedure TForm1.LoadNastr;
var
  Ini: TMemIniFile;
  i: Integer;
begin
  Ini := TMemIniFile.Create(PortablePath);
  try
    for i := 0 to ThemeMenu.Count - 1 do
    begin
      ThemeMenu.Items[i].Checked := Ini.ReadBool('Option', ThemeMenu.Items[i].Name, False);
      if ThemeMenu.Items[i].Checked then
        ThemeMenu.Items[i].Click;
    end;
  finally
    Ini.Free;
  end;
end;

function TForm1.GetAppDataRoamingPath: string;
var
  Path: array[0..MAX_PATH] of Char;
begin
  if SUCCEEDED(SHGetFolderPath(0, CSIDL_APPDATA, 0, 0, @Path[0])) then
    Result := IncludeTrailingPathDelimiter(Path)
  else
    Result := '';
end;

function TForm1.PortablePath: string;
begin
  if portable then
    Result := ExtractFilePath(ParamStr(0)) + 'Config\Option.ini'
  else
    Result := IncludeTrailingPathDelimiter(GetAppDataRoamingPath) + IncludeTrailingPathDelimiter(GetCompanyName(ParamStr(0))) + Application.Title + '\Config\Option.ini';
    //Result := ExtractFilePath(ParamStr(0)) + 'Config\Option.ini';
  ForceDirectories(ExtractFilePath(Result));
end;

procedure TForm1.SaveNastr;
var
  Ini: TMemIniFile;
  i: Integer;
begin
  Ini := TMemIniFile.Create(PortablePath);
  try
    Ini.WriteBool('Option', Form10.CheckBoxQuickUpdate.Name, Form10.CheckBoxQuickUpdate.Checked);

    for i := 0 to ThemeMenu.Count - 1 do
      Ini.WriteBool('Option', ThemeMenu.Items[i].Name, ThemeMenu.Items[i].Checked);

    if Assigned(Form2) then
    begin

      Ini.WriteBool('Option', Form2.MenuColorTrayIcon.Name, Form2.MenuColorTrayIcon.Checked);
      Ini.WriteBool('Option', Form2.RadioButtonDefaultPosition.Name, Form2.RadioButtonDefaultPosition.Checked);
      Ini.WriteBool('Option', Form2.RadioButtonLastPosition.Name, Form2.RadioButtonLastPosition.Checked);

      Ini.WriteBool('Option', Form2.CheckBoxIgnoreMouse.Name, Form2.CheckBoxIgnoreMouse.Checked);

      Ini.WriteInteger('Option', Form2.SpinEditNumber.Name, Trunc(Form2.SpinEditNumber.Value));
      Ini.WriteBool('Option', Form2.CheckNumberFontBold.Name, Form2.CheckNumberFontBold.Checked);
      Ini.WriteInteger('Option', Form2.ColorBoxNumber.Name, Form2.ColorBoxNumber.Selected);

      Ini.WriteInteger('Option', Form2.ComboBoxFont.Name, Form2.ComboBoxFont.ItemIndex);
      Ini.WriteInteger('Option', Form2.TrackBarScale.Name, Form2.TrackBarScale.Position);
      Ini.WriteBool('Option', Form2.CheckBoxAutoColor.Name, Form2.CheckBoxAutoColor.Checked);
    end;

    Ini.WriteInteger('Option', 'Top', Top);
    Ini.WriteInteger('Option', 'Left', Left);

    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

procedure TForm1.UpdateCursorForAllLabels;
begin
  if Form2.IsMouseIgnored then
  begin
    // Режим игнорирования - обычный курсор
    LabelNUmber.Cursor := crDefault;
    SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_TRANSPARENT);
  end
  else
  begin
    // Нормальный режим - рука
    LabelNUmber.Cursor := crHandPoint;
    SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and not WS_EX_TRANSPARENT);
  end;
end;

procedure TForm1.LabelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(Form2) and Form2.IsMouseIgnored then
  begin
    // Блокируем всё в режиме игнорирования
    PopupMenu1.AutoPopup := False; // Отключаем авто-показ
    Exit;
  end;

  PopupMenu1.AutoPopup := True; // Включаем авто-показ

  if Button = mbLeft then
  begin
    // Перемещение окна
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, $F012, 0);
  end
  else if Button = mbRight then
  begin
    // Контекстное меню
    SetForegroundWindow(Handle);
    PopupMenu1.PopupComponent := TLabel(Sender);
    PopupMenu1.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

procedure TForm1.MenuAboutClick(Sender: TObject);
begin
  try
    Form8.ShowModal;
  except
  end;
end;

procedure TForm1.MenuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.MenuCheckUpdateClick(Sender: TObject);
begin
  try
    Form10.ShowModal;
  except
  end;
end;

procedure TForm1.SettingsClick(Sender: TObject);
begin
  if Assigned(Form2) then
    Form2.Show;
end;

procedure TForm1.PopupMenu1Popup(Sender: TObject);
begin
  SetWindowPos(Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE or SWP_NOREDRAW);
  ShowWindow(Application.Handle, SW_HIDE);
  application.ProcessMessages;
end;

procedure TForm1.UnCheckTheme;
var
  i: Integer;
begin
  for i := 0 to ThemeMenu.Count - 1 do
  begin
    ThemeMenu.Items[i].Checked := False;
  end;
end;

procedure TForm1.ThemeAutoClick(Sender: TObject);
begin
  UnCheckTheme;
  ThemeAuto.Checked := True;

  if DarkModeIsEnabled then
    SetSpecificThemeMode(True, 'Windows11 Modern Dark', 'Windows11 Modern Light')
  else
    SetSpecificThemeMode(True, 'Windows11 Modern Light', 'Windows11 Modern Dark');
end;

procedure TForm1.ThemeDarkClick(Sender: TObject);
begin
  UnCheckTheme;
  ThemeDark.Checked := True;
  SetSpecificThemeMode(True, 'Windows11 Modern Dark', 'Windows11 Modern Light');
end;

procedure TForm1.ThemeLightClick(Sender: TObject);
begin
  UnCheckTheme;
  ThemeLight.Checked := True;
  SetSpecificThemeMode(True, 'Windows11 Modern Light', 'Windows11 Modern Dark');
end;

{Procedure TForm1.UpdateWindowSize;
Begin
  ClientWidth := LabelNumber.Canvas.TextWidth(LabelNumber.Caption) + 20;
  application.ProcessMessages;
End;   }

procedure TForm1.ApplyScale;
var
  ScaleFactor: Double;
  FontMultiplier: Integer;
  BaseFontSize: Integer;
  NewWidth, NewHeight: Integer;
  ScreenHeight, ScreenWidth, ScalePercent: Integer;
  ScreenResolutionFactor: Double; // Коэффициент для учета разрешения экрана
begin
  case Form2.ComboBoxFont.ItemIndex of
    0:
      FontMultiplier := 8;
    1:
      FontMultiplier := 8;
    2:
      FontMultiplier := 8;
    3:
      FontMultiplier := 6;
    4:
      FontMultiplier := 9;
    5:
      FontMultiplier := 8;
  else
    FontMultiplier := 6;
  end;

  ScalePercent := Form2.TrackBarScale.Position;
  ScaleFactor := ScalePercent / 100;

  // Получаем размеры экрана
  ScreenHeight := Screen.WorkAreaHeight;
  ScreenWidth := Screen.WorkAreaWidth;

  // Определяем коэффициент для учета разрешения экрана
  // Базовое разрешение 1366x768 = 1.0
  // Для Full HD (1920x1080) и выше уменьшаем шрифт
  if ScreenWidth >= 1920 then
    ScreenResolutionFactor := 1.2  // Full HD и выше - уменьшаем на 15%
  else if ScreenWidth >= 1600 then
    ScreenResolutionFactor := 0.9   // 1600x900 - уменьшаем на 10%
  else if ScreenWidth >= 1366 then
    ScreenResolutionFactor := 0.75   // 1366x768 - стандарт
  else if ScreenWidth >= 1280 then
    ScreenResolutionFactor := 0.65   // 1280x720 - увеличиваем на 10%
  else
    ScreenResolutionFactor := 0.65;  // Меньше 1280 - увеличиваем на 20%

  BaseFontSize := 20;
  if FOriginalWidth = 0 then
  begin
    FOriginalWidth := Width;
    FOriginalHeight := Form1.LabelNumber.Height + 20;
    BaseFontSize := 20;
  end;

  // Масштабируем размеры окна
  NewWidth := Round(FOriginalWidth * ScaleFactor);
  NewHeight := Round(FOriginalHeight * ScaleFactor);

  // Ограничиваем максимальную высоту экраном
  if NewHeight > ScreenHeight - 50 then
    NewHeight := ScreenHeight - 50;

  // Ограничиваем максимальную ширину экраном
  if NewWidth > ScreenWidth - 50 then
    NewWidth := ScreenWidth - 50;

  // Устанавливаем ширину
  Width := NewWidth;
  Height := NewHeight;

  // Размер шрифта с учетом разрешения экрана
  if ScalePercent > 80 then
    LabelNumber.Font.Size := Max(8, Round(BaseFontSize * ScaleFactor * FontMultiplier * ScreenResolutionFactor))
  else if (ScalePercent <= 80) and (ScalePercent > 40) then
    LabelNumber.Font.Size := Max(8, Round(BaseFontSize * ScaleFactor * (FontMultiplier - 2) * ScreenResolutionFactor))
  else if ScalePercent <= 40 then
    LabelNumber.Font.Size := Max(8, Round(BaseFontSize * ScaleFactor * (FontMultiplier - 3) * ScreenResolutionFactor));

  Invalidate;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  LockWindowUpdate(handle);
  SetWindowPos(Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE or SWP_NOREDRAW or SWP_FRAMECHANGED);
  ShowWindow(Application.Handle, SW_HIDE);
  //UpdateWindowSize;
  if Form2.RadioButtonDefaultPosition.Checked then
  begin
    Form1.Left := (Screen.WorkAreaWidth - Width - 20) div 2;
    Form1.Top := (Screen.WorkAreaHeight - Height) div 2;
  end;
  InvalidateRect(Handle, nil, False);
  ShowWindow(Application.handle, SW_HIDE);
  Application.ProcessMessages;
  LockWindowUpdate(0);
  invalidate;
  Update;
end;

function TForm1.GetDesktopColor: TColor;
var
  WallpaperPath: array[0..MAX_PATH] of Char;
  Bitmap: TBitmap;
  Jpeg: TJPEGImage;
  Png: TPngImage;
  Ext: string;
  Points: array[0..3] of TPoint;
  I, R, G, B: Integer;
begin
  Result := clWhite;

  if not SystemParametersInfo(SPI_GETDESKWALLPAPER, MAX_PATH, @WallpaperPath, 0) then
    Exit;

  if (WallpaperPath[0] = #0) or not FileExists(string(WallpaperPath)) then
    Exit;

  try
    Bitmap := TBitmap.Create;
    try
      Ext := LowerCase(ExtractFileExt(string(WallpaperPath)));

      // Быстрая загрузка только заголовка
      if (Ext = '.jpg') or (Ext = '.jpeg') then
      begin
        Jpeg := TJPEGImage.Create;
        try
          Jpeg.Scale := jsEighth; // 1/8 размера!
          Jpeg.LoadFromFile(string(WallpaperPath));
          Bitmap.Assign(Jpeg);
        finally
          Jpeg.Free;
        end;
      end
      else if Ext = '.png' then
      begin
        Png := TPngImage.Create;
        try
          // Загружаем как есть (PNG обычно меньше)
          Png.LoadFromFile(string(WallpaperPath));

          // Уменьшаем если очень большое
          if (Png.Width > 100) or (Png.Height > 100) then
          begin
            Bitmap.Width := 100;
            Bitmap.Height := 100;
            Bitmap.Canvas.StretchDraw(Rect(0, 0, 100, 100), Png);
          end
          else
            Bitmap.Assign(Png);
        finally
          Png.Free;
        end;
      end
      else
      begin
        // Для BMP просто загружаем
        Bitmap.LoadFromFile(string(WallpaperPath));
      end;

      // Анализируем только 4 точки (углы)
      R := 0;
      G := 0;
      B := 0;

      // Координаты углов
      Points[0] := Point(0, 0); // Левый верхний
      Points[1] := Point(Bitmap.Width - 1, 0); // Правый верхний
      Points[2] := Point(0, Bitmap.Height - 1); // Левый нижний
      Points[3] := Point(Bitmap.Width - 1, Bitmap.Height - 1); // Правый нижний

      for I := 0 to 3 do
      begin
        if (Points[I].X >= 0) and (Points[I].X < Bitmap.Width) and (Points[I].Y >= 0) and (Points[I].Y < Bitmap.Height) then
        begin
          Result := Bitmap.Canvas.Pixels[Points[I].X, Points[I].Y];
          R := R + GetRValue(Result);
          G := G + GetGValue(Result);
          B := B + GetBValue(Result);
        end;
      end;

      Result := RGB(R div 4, G div 4, B div 4);

    finally
      Bitmap.Free;
    end;
  except
    Result := clWhite;
  end;
end;

function TForm1.GetContrastColor(Color: TColor): TColor;
var
  BGColor: TColor;
  R, G, B, Luma: Integer;
begin
  // Получаем реальный цвет с экрана
  BGColor := Form1.GetDesktopColor;

  // Анализируем
  BGColor := ColorToRGB(BGColor);
  R := GetRValue(BGColor);
  G := GetGValue(BGColor);
  B := GetBValue(BGColor);

  // Формула яркости (YCbCr)
  Luma := Round(R * 0.299 + G * 0.587 + B * 0.114);

  // Очень простая логика
  if Luma > 128 then
    Result := clBlack  // Черный текст на светлом фоне
  else
    Result := clWhite; // Белый текст на темном фоне
end;

{Function TForm1.GetCurrentWallpaper: Boolean;
Var
  Reg: TRegistry;
  WallpaperPath: String;
Begin
  Result := False;
  Reg := TRegistry.Create;
  Try
    Reg.RootKey := HKEY_CURRENT_USER;

    // Для современных версий Windows (8/10/11)
    If Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers', False) Then
    Begin
      WallpaperPath := Reg.ReadString('BackgroundHistoryPath0');
      If WallpaperPath <> '' Then
      Begin
        Result := True;
        Reg.CloseKey;
        Exit;
      End;
      Reg.CloseKey;
    End;

    // Для всех версий Windows (классический способ)
    If Reg.OpenKey('Control Panel\Desktop', False) Then
    Begin
      WallpaperPath := Reg.ReadString('Wallpaper');
      If WallpaperPath <> '' Then
      Begin
        Result := True;
      End;
      Reg.CloseKey;
    End;
  Finally
    Reg.Free;
  End;
End;   }

procedure TForm1.GetDesktopColorAsync;
begin
  if FIsProcessingWallpaper then
    Exit; // Уже в процессе обработки, выходим

  FIsProcessingWallpaper := True;

  TThread.CreateAnonymousThread(
    procedure
    var
      CurrentPath: string;
      WallpaperPath: array[0..MAX_PATH] of Char;
    begin
      try
        // Получаем текущий путь к обоям
        if SystemParametersInfo(SPI_GETDESKWALLPAPER, MAX_PATH, @WallpaperPath, 0) then
          CurrentPath := string(WallpaperPath)
        else
          CurrentPath := '';

        // Проверяем, изменились ли обои
            if (CurrentPath <> '') and (CurrentPath <> FLastWallpaperPath) then
        begin
          Color := GetDesktopColor; // Ваша существующая функция

          TThread.Queue(nil,
            procedure
            begin
              FLastWallpaperPath := CurrentPath;
              FCachedDesktopColor := Color;

              // Обновляем UI
              if Form2.CheckBoxAutoColor.Checked then
              begin
                Form1.LabelNumber.Font.Color := GetContrastColor(NewDesktopColor);
              end;

              FIsProcessingWallpaper := False;
            end);
        end
        else
        begin
          TThread.Queue(nil,
            procedure
            begin
              FIsProcessingWallpaper := False;
            end);
        end;
      except
        TThread.Queue(nil,
          procedure
          begin
            FIsProcessingWallpaper := False;
          end);
      end;
    end).Start;
end;

procedure TForm1.GetDesktopColorAsyncA;
begin
  if FIsProcessingWallpaperA then
    Exit; // Уже в процессе обработки, выходим

  FIsProcessingWallpaperA := True;

  TThread.CreateAnonymousThread(
    procedure
    var
      DesktopColor: TColor;
      Success: Boolean;
    begin
      Success := False;
      DesktopColor := clBlack; // Значение по умолчанию

      try
        try
          // Получаем цвет рабочего стола
          DesktopColor := GetDesktopColor; // Ваша существующая функция
          Success := True;

        except
          Success := False;
        end;

      finally
        TThread.Queue(nil,
          procedure
          begin
            if Success then
            begin
              // Обновляем UI только если получение цвета было успешным
              if Form2.CheckBoxAutoColor.Checked then
              begin
                Form1.LabelNumber.Font.Color := GetContrastColor(DesktopColor);
              end;
            end;

            FIsProcessingWallpaperA := False;
          end);
      end;
    end).Start;
end;

procedure TForm1.WMMove(var Msg: TWMMove);
begin
  inherited;

end;

procedure TForm1.WMSysColorChange(var Message: TMessage);
begin
  inherited;
  Color := GetDesktopColor;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  // Проверяем раз в 5 секунд вместо каждого тика таймера
  if GetTickCount - FLastUpdateTime < 1000 then
    Exit;

  FLastUpdateTime := GetTickCount;

  // Используем кэшированный цвет, если обои не изменились
  if Form2.CheckBoxAutoColor.Checked then
  begin
    // Проверяем обои асинхронно
    GetDesktopColorAsync;
  end;
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  if not Visible then
  begin
    Show;
    BringToFront;
  end
  else
  begin
    Hide;
  end;
end;

procedure TForm1.TrayIcon1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if portable = True then
    TrayIcon1.Hint := getFileDescription(ParamStr(0)) + #13 + GetFileVersion(ParamStr(0)) + ' ' + GetApplicationBitness + #13 + ' Portable'
  else
    TrayIcon1.Hint := getFileDescription(ParamStr(0)) + #13 + GetFileVersion(ParamStr(0)) + ' ' + GetApplicationBitness;
  Application.ProcessMessages;
end;

procedure TForm1.WMMoving(var Msg: TWmMoving);
var
  r: TRect;
begin
  r := Screen.WorkareaRect;
  if Msg.lpRect^.Left < r.Left then
    OffsetRect(Msg.lpRect^, r.Left - Msg.lpRect^.Left, 0);
  if Msg.lpRect^.Top < r.Top then
    OffsetRect(Msg.lpRect^, 0, r.Top - Msg.lpRect^.Top);
  if Msg.lpRect^.Right > r.Right then
    OffsetRect(Msg.lpRect^, r.Right - Msg.lpRect^.Right, 0);
  if Msg.lpRect^.Bottom > r.Bottom then
    OffsetRect(Msg.lpRect^, 0, r.Bottom - Msg.lpRect^.Bottom);
  inherited;
end;

procedure TForm1.WMExitSizeMove(var Msg: TMessage);
begin
  inherited;
  KeepFormInWorkArea;
  GetDesktopColorAsyncA;
end;

procedure TForm1.KeepFormInWorkArea;
var
  r: TRect;
begin
  r := Screen.WorkAreaRect;

  // Если форма выходит за правую границу
  if Left + Width > r.Right then
    Left := r.Right - Width;

  // Если форма выходит за нижнюю границу
  if Top + Height > r.Bottom then
    Top := r.Bottom - Height;

  // Если форма выходит за левую границу
  if Left < r.Left then
    Left := r.Left;

  // Если форма выходит за верхнюю границу
  if Top < r.Top then
    Top := r.Top;
end;

end.

