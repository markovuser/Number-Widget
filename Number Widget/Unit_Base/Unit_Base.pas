Unit Unit_Base;

Interface

Uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Winsock, IniFiles, Vcl.Menus, Registry,
  WindowsDarkMode, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnPopup, Vcl.Themes,
  Vcl.Styles, Vcl.Imaging.pngimage, System.ImageList, Vcl.ImgList, Translation,
  IdComponent, IdBaseComponent, IdTCPConnection, IdTCPClient, IdHTTP, ShellAPI,
  Vcl.ComCtrls, Vcl.ToolWin, ActiveX, ComObj, DateUtils, ShlObj, Math, JPEG,
  System.Types, FileInfoUtils;

Type
  TWmMoving = Record
    Msg: Cardinal;
    fwSide: Cardinal;
    lpRect: PRect;
    Result: Integer;
  End;

  TForm1 = Class(TForm)
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

    Procedure MenuExitClick(Sender: TObject);
    Procedure LoadNastr;
    Procedure SaveNastr;
    Procedure Globload;
    Procedure CleanTranslationsLikeGlobload;
    Procedure LoadLanguage;
    Procedure FontApply;
    Procedure ApplyScale;
    Procedure UnCheckTheme;
    Procedure WMMoving(Var Msg: TWmMoving); Message WM_MOVING;
    Procedure FormCreate(Sender: TObject);
    Procedure PopupMenu1Popup(Sender: TObject);
    Procedure TrayIcon1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    Procedure MenuAboutClick(Sender: TObject);
    Procedure FormClose(Sender: TObject; Var Action: TCloseAction);
    Procedure SettingsClick(Sender: TObject);
    Procedure TrayIcon1DblClick(Sender: TObject);
    Procedure MenuCheckUpdateClick(Sender: TObject);
    Procedure ThemeAutoClick(Sender: TObject);
    Procedure ThemeLightClick(Sender: TObject);
    Procedure ThemeDarkClick(Sender: TObject);
    Function IsWindows10Or11: Boolean;
    Function PortablePath: String;
    Function GetAppDataRoamingPath: String;
    Procedure Timer1Timer(Sender: TObject);
    Procedure WMEraseBkgnd(Var Msg: TWmEraseBkgnd); Message WM_ERASEBKGND;
    Procedure KeepFormInWorkArea;
    Procedure Timer2Timer(Sender: TObject);
    Procedure UpdateCursorForAllLabels;

  Private
    Color: TColor;
    FIsProcessingWallpaper: Boolean;
    FIsProcessingWallpaperA: Boolean;
    FLastWallpaperPath: String;
    FCachedDesktopColor: TColor;
    FLastUpdateTime: Cardinal;
    FOriginalWidth: Integer;
    FOriginalHeight: Integer;
    NewDesktopColor: TColor;
    FProcessPrioritySet: Boolean;
    Procedure WMExitSizeMove(Var Msg: TMessage); Message WM_EXITSIZEMOVE;
    Procedure WMSettingChange(Var Message: TWMSettingChange); Message WM_SETTINGCHANGE;
    Procedure WMMove(Var Msg: TWMMove); Message WM_MOVE;
    Procedure WMSysColorChange(Var Message: TMessage); Message WM_SYSCOLORCHANGE;
    Procedure LanguageMenuItemClick(Sender: TObject);
    Procedure SetAsBackgroundProcess;
    Function GetDesktopColor: TColor;
    Function GetContrastColor(Color: TColor): TColor;
   // Function GetCurrentWallpaper: Boolean;
    Procedure GetDesktopColorAsync;
    Procedure GetDesktopColorAsyncA;
    Procedure LabelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

  Protected
    Procedure CreateParams(Var Params: TCreateParams); Override;

  Public
    Constructor Create(AOwner: TComponent); Override;
  End;

Var
  Form1: TForm1;
  FontName: String;
  portable: Boolean;
  LangCode: String;
  LangLocal: String;

Const
  ServerName = 'Number-Widget';
  ApiGithub = 'https://api.github.com/repos/markovuser/' + ServerName + '/releases/latest';
  DEFAULT_SCALE = 100;

Implementation

Uses
  Unit_About, Unit_Settings, Unit_Update;

{$R *.dfm}

{ TForm1 }

Procedure TForm1.WMEraseBkgnd(Var Msg: TWmEraseBkgnd);
Begin
  // Запрещаем полное стирание фона окна
  Msg.Result := 1;
End;

Constructor TForm1.Create(AOwner: TComponent);
Begin
  Inherited Create(AOwner);
  FProcessPrioritySet := False;
End;

Procedure TForm1.CreateParams(Var Params: TCreateParams);
Begin
  Inherited CreateParams(Params);

  Params.ExStyle := Params.ExStyle Or WS_EX_TOOLWINDOW;
  Params.ExStyle := Params.ExStyle Or WS_EX_NOACTIVATE;
  Params.WndParent := GetDesktopWindow;
End;

Procedure TForm1.SetAsBackgroundProcess;
Var
  ProcessHandle: THandle;
Begin
  If FProcessPrioritySet Then
    Exit;

  ProcessHandle := OpenProcess(PROCESS_SET_INFORMATION, False, GetCurrentProcessId);
  If ProcessHandle <> 0 Then
  Try
    SetPriorityClass(ProcessHandle, BELOW_NORMAL_PRIORITY_CLASS);
    FProcessPrioritySet := True;
  Finally
    CloseHandle(ProcessHandle);
  End;
End;

Function TForm1.IsWindows10Or11: Boolean;
Begin
  Result := (TOSVersion.Major = 10) And (TOSVersion.Build >= 10240);
End;

Procedure TForm1.WMSettingChange(Var Message: TWMSettingChange);
Begin
  if Message.Flag = SPI_SETWORKAREA then
  begin
    Form2.TrackBarScale.Position := Form2.TrackBarScale.Position + 1;
    Form2.TrackBarScale.Position := Form2.TrackBarScale.Position - 1;
  end;
  If ThemeAuto.Checked Then
  Begin
    Try
      If DarkModeIsEnabled Then
        SetSpecificThemeMode(True, 'Windows11 Modern Dark', 'Windows11 Modern Light')
      Else
        SetSpecificThemeMode(True, 'Windows11 Modern Light', 'Windows11 Modern Dark');
    Except
    End;
  End;

  Try
    If Assigned(Form2) Then
      Form2.MenuColorTrayIconClick(Self);
  Except
  End;
End;

Procedure TForm1.Globload;
Var
  i: Integer;
  Internat: TTranslation;
  Ini: TMemIniFile;
  lang, lang_file: String;
Begin
  For i := 0 To Screen.FormCount - 1 Do
  Begin
    Ini := TMemIniFile.Create(PortablePath);
    Try
      lang := Ini.ReadString('Language', 'Language', '');
      lang_file := ExtractFilePath(ParamStr(0)) + 'Language\' + lang + '.ini';
    Finally
      Ini.Free;
    End;

    If FileExists(lang_file) Then
    Begin
      Ini := TMemIniFile.Create(lang_file);
      Try
        If Ini.SectionExists(Application.Title) Then
        Begin
          Internat.Execute(Screen.Forms[i], Application.Title);
        End;
      Finally
        Ini.Free;
      End;
    End;
  End;
End;

Procedure TForm1.FormClose(Sender: TObject; Var Action: TCloseAction);
Begin
  SaveNastr;
End;

Function LoadResourceFontByName(Const ResourceName: String; ResType: PChar): Boolean;
Var
  ResStream: TResourceStream;
  FontsCount: DWORD;
Begin
  ResStream := TResourceStream.Create(hInstance, ResourceName, ResType);
  Try
    Result := (AddFontMemResourceEx(ResStream.Memory, ResStream.Size, Nil, @FontsCount) <> 0);
  Finally
    ResStream.Free;
  End;
End;

Function LoadResourceFontByID(ResourceID: Integer; ResType: PChar): Boolean;
Var
  ResStream: TResourceStream;
  FontsCount: DWORD;
Begin
  ResStream := TResourceStream.CreateFromID(hInstance, ResourceID, ResType);
  Try
    Result := (AddFontMemResourceEx(ResStream.Memory, ResStream.Size, Nil, @FontsCount) <> 0);
  Finally
    ResStream.Free;
  End;
End;

Procedure TForm1.FontApply;
Begin
  Try
    If Form2.ComboBoxFont.ItemIndex = 0 Then
    Begin
      If LoadResourceFontByID(1, RT_FONT) Then
        Form1.Labelnumber.Font.Name := 'Digital Display Regular';
    End;
    If Form2.ComboBoxFont.ItemIndex = 1 Then
    Begin
      If LoadResourceFontByID(2, RT_FONT) Then
        Form1.Labelnumber.Font.Name := 'Typo Digit Demo';
    End;
    If Form2.ComboBoxFont.ItemIndex = 2 Then
    Begin
      If LoadResourceFontByID(3, RT_FONT) Then
        Form1.Labelnumber.Font.Name := 'MOSCOW2024';
    End;
    If Form2.ComboBoxFont.ItemIndex = 3 Then
    Begin
      If LoadResourceFontByID(4, RT_FONT) Then
        Form1.Labelnumber.Font.Name := 'DJB Get Digital';
    End;

    If Form2.ComboBoxFont.ItemIndex = 4 Then
    Begin
      Form1.Labelnumber.Font.Name := 'Segoe UI';
    End;
  Except
  End;

End;

Procedure TForm1.LoadLanguage;
Var
  Ini: TMemIniFile;
  LangFiles: TStringList;
  i: Integer;
  MenuItem: TMenuItem;
  FileName, DisplayName, MenuCaption: String;
  SearchRec: TSearchRec;
Begin
  Ini := TMemIniFile.Create(PortablePath);
  Try
    LangLocal := Ini.ReadString('Language', 'Language', '');
  Finally
    Ini.Free;
  End;

  While LanguageMenu.Count > 0 Do
    LanguageMenu.Items[0].Free;

  LangFiles := TStringList.Create;
  Try
    If FindFirst(ExtractFilePath(ParamStr(0)) + 'Language\*.ini', faAnyFile, SearchRec) = 0 Then
    Begin
      Repeat
        If (SearchRec.Name <> '.') And (SearchRec.Name <> '..') Then
          LangFiles.Add(SearchRec.Name);
      Until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    End;

    LangFiles.Sort;

    For i := 0 To LangFiles.Count - 1 Do
    Begin
      FileName := LangFiles[i];
      LangCode := ChangeFileExt(FileName, '');
      DisplayName := LangCode;

      Try
        Ini := TMemIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Language\' + FileName);
        Try
          DisplayName := Ini.ReadString('Language information', 'LANGNAME', LangCode);
        Finally
          Ini.Free;
        End;
      Except
      End;

      MenuCaption := LangCode + #9#9 + DisplayName;
      MenuItem := TMenuItem.Create(LanguageMenu);
      MenuItem.RadioItem := True;
      MenuItem.Caption := MenuCaption;
      MenuItem.AutoHotkeys := maManual;
      MenuItem.AutoCheck := True;

      If SameText(LangCode, LangLocal) Or SameText(LangCode + '.ini', LangLocal) Then
        MenuItem.Checked := True;

      MenuItem.OnClick := LanguageMenuItemClick;
      LanguageMenu.Add(MenuItem);
    End;
  Finally
    LangFiles.Free;
  End;
End;

Procedure TForm1.LanguageMenuItemClick(Sender: TObject);
Var
  MenuItem: TMenuItem;
  Ini: TMemIniFile;
  i: Integer;
Begin
  If Sender Is TMenuItem Then
  Begin
    MenuItem := TMenuItem(Sender);
    LangCode := Copy(MenuItem.Caption, 1, Pos(#9, MenuItem.Caption) - 1);
    LangLocal := LangCode;
    For i := 0 To LanguageMenu.Count - 1 Do
      LanguageMenu.Items[i].Checked := False;
    MenuItem.Checked := True;
    Ini := TMemIniFile.Create(PortablePath);
    Try
      Ini.WriteString('Language', 'Language', LangLocal);
      Ini.UpdateFile;
    Finally
      Ini.Free;
    End;
    LoadLanguage;
    Globload;
  End;
End;

Procedure TForm1.CleanTranslationsLikeGlobload;
Var
  i, j, k, m: Integer;
  Ini: TMemIniFile;
  Sections, Keys: TStringList;
  SearchRec: TSearchRec;
  FindResult: Integer;
  CompPath, FormName, CompName, PropName: String;
  FirstDot, SecondDot: Integer;
  FormExists, CompExists: Boolean;
  CurrentForm: TForm;
  CurrentComponent: TComponent;
  Modified: Boolean;
  IsDuplicate: Boolean;
  n: Integer;
  CompareKey, CompareFormName: String;
  CompareDotPos: Integer;
Begin
  // Создаем все формы проекта (если нужно)
  // CreateAllProjectForms;

  FindResult := FindFirst(ExtractFilePath(ParamStr(0)) + 'Language\*.ini', faAnyFile, SearchRec);
  If FindResult = 0 Then
  Begin
    Repeat
      If (SearchRec.Name <> '.') And (SearchRec.Name <> '..') Then
      Begin
        Ini := TMemIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Language\' + SearchRec.Name);
        Sections := TStringList.Create;
        Keys := TStringList.Create;
        Modified := False;

        Try
          Ini.ReadSections(Sections);

          For i := 0 To Sections.Count - 1 Do
          Begin
            // ========== ИСКЛЮЧАЕМ ЭТИ СЕКЦИИ ИЗ ОБРАБОТКИ ==========
            If SameText(Sections[i], 'Language information') Or SameText(Sections[i], 'DestDir') Then
              Continue; // Пропускаем эти секции полностью

            Ini.ReadSection(Sections[i], Keys);

            // Проходим по всем ключам в обратном порядке
            For j := Keys.Count - 1 Downto 0 Do
            Begin
              CompPath := Keys[j];
              FirstDot := Pos('.', CompPath);

              If FirstDot > 0 Then
              Begin
                FormName := Copy(CompPath, 1, FirstDot - 1);
                FormExists := False;
                CompExists := False;

                // ==================== ПРОВЕРКА СУЩЕСТВОВАНИЯ КОМПОНЕНТА ====================
                // Проверяем ВСЕ формы в Screen
                For k := 0 To Screen.FormCount - 1 Do
                Begin
                  If SameText(Screen.Forms[k].Name, FormName) Then
                  Begin
                    FormExists := True;
                    CurrentForm := Screen.Forms[k];

                    // Извлекаем остаток пути после имени формы
                    CompName := Copy(CompPath, FirstDot + 1, Length(CompPath));
                    SecondDot := Pos('.', CompName);

                    If SecondDot > 0 Then
                    Begin
                      // Есть вложенный компонент: Form1.TrayIcon1.Hint
                      PropName := Copy(CompName, SecondDot + 1, Length(CompName));
                      CompName := Copy(CompName, 1, SecondDot - 1);

                      // Ищем компонент на форме
                      CurrentComponent := CurrentForm.FindComponent(CompName);

                      // Если не нашли через FindComponent, ищем вручную
                      If CurrentComponent = Nil Then
                      Begin
                        For m := 0 To CurrentForm.ComponentCount - 1 Do
                        Begin
                          If SameText(CurrentForm.Components[m].Name, CompName) Then
                          Begin
                            CurrentComponent := CurrentForm.Components[m];
                            Break;
                          End;
                        End;
                      End;

                      CompExists := (CurrentComponent <> Nil);
                    End
                    Else
                    Begin
                      // Нет второй точки - это свойство формы (Form1.Caption)
                      CompExists := True;
                    End;

                    Break; // Форма найдена, выходим из цикла
                  End;
                End;

                // ==================== ПРОВЕРКА ДУБЛИКАТОВ ====================
                IsDuplicate := False;
                // Проверяем предыдущие ключи на дубликаты (только внутри той же формы)
                For n := 0 To j - 1 Do
                Begin
                  CompareKey := Keys[n];
                  CompareDotPos := Pos('.', CompareKey);

                  If CompareDotPos > 0 Then
                  Begin
                    CompareFormName := Copy(CompareKey, 1, CompareDotPos - 1);

                    // Дубликатом считаем только если:
                    // 1. Имя формы совпадает
                    // 2. Полный путь совпадает (регистронезависимо)
                    If (SameText(FormName, CompareFormName)) And (SameText(CompPath, CompareKey)) Then
                    Begin
                      IsDuplicate := True;
                      Break;
                    End;
                  End;
                End;

                // ==================== УДАЛЕНИЕ КЛЮЧА ====================
                // Удаляем если:
                // 1. Форма или компонент не существуют ИЛИ
                // 2. Найден дубликат в той же форме
                If (Not (FormExists And CompExists)) Or IsDuplicate Then
                Begin
                  Ini.DeleteKey(Sections[i], Keys[j]);
                  Modified := True;
                End;
              End
              Else
              Begin
                // Некорректный формат - удаляем
                Ini.DeleteKey(Sections[i], Keys[j]);
                Modified := True;
              End;
            End;

            // Проверяем, не пустая ли секция после удаления
            // (кроме исключенных секций)
            If Not (SameText(Sections[i], 'Language information') Or SameText(Sections[i], 'DestDir')) Then
            Begin
              Ini.ReadSection(Sections[i], Keys);
              If Keys.Count = 0 Then
              Begin
                Ini.EraseSection(Sections[i]);
                Modified := True;
              End;
            End;
          End;

          If Modified Then
            Ini.UpdateFile;

        Finally
          Keys.Free;
          Sections.Free;
          Ini.Free;
        End;
      End;
    Until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  End;
End;

Function GetApplicationBitness: String;
Begin
  {$IFDEF WIN64}
  Result := '(64-bit)';
  {$ELSE}
  Result := '(32-bit)';
  {$ENDIF}
End;

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  portable := fileExists(ExtractFilePath(ParamStr(0)) + 'portable.ini');
  Form1.Caption := Form1.Caption + ' ' + GetFileVersion(ParamStr(0)) + ' ' + GetApplicationBitness;
  If portable Then
    Form1.Caption := Form1.Caption + ' Portable';
  Name.Caption := GetFileDescription(ParamStr(0));
  Version.Caption := GetFileVersion(ParamStr(0)) + ' ' + GetApplicationBitness;

  SetWindowPos(Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE Or SWP_NOMOVE Or SWP_NOSIZE Or SWP_NOREDRAW Or SWP_FRAMECHANGED);
  ShowWindow(Application.Handle, SW_HIDE);
  SetAsBackgroundProcess;
  LoadNastr;
  FontApply;
  LoadLanguage;
  Color := GetDesktopColor;
  LabelNumber.OnMouseDown := LabelMouseDown;
End;

Procedure TForm1.LoadNastr;
Var
  Ini: TMemIniFile;
  i: Integer;
Begin
  Ini := TMemIniFile.Create(PortablePath);
  Try
    For i := 0 To ThemeMenu.Count - 1 Do
    Begin
      ThemeMenu.Items[i].Checked := Ini.ReadBool('Option', ThemeMenu.Items[i].Name, False);
      If ThemeMenu.Items[i].Checked Then
        ThemeMenu.Items[i].Click;
    End;
  Finally
    Ini.Free;
  End;
End;

Function TForm1.GetAppDataRoamingPath: String;
Var
  Path: Array[0..MAX_PATH] Of Char;
Begin
  If SUCCEEDED(SHGetFolderPath(0, CSIDL_APPDATA, 0, 0, @Path[0])) Then
    Result := IncludeTrailingPathDelimiter(Path)
  Else
    Result := '';
End;

Function TForm1.PortablePath: String;
Begin
  If portable Then
    Result := ExtractFilePath(ParamStr(0)) + 'Config\Option.ini'
  Else
    Result := IncludeTrailingPathDelimiter(GetAppDataRoamingPath) + IncludeTrailingPathDelimiter(GetCompanyName(ParamStr(0))) + Application.Title + '\Config\Option.ini';
    //Result := ExtractFilePath(ParamStr(0)) + 'Config\Option.ini';
  ForceDirectories(ExtractFilePath(Result));
End;

Procedure TForm1.SaveNastr;
Var
  Ini: TMemIniFile;
  i: Integer;
Begin
  Ini := TMemIniFile.Create(PortablePath);
  Try
    Ini.WriteBool('Option', Form10.CheckBoxQuickUpdate.Name, Form10.CheckBoxQuickUpdate.Checked);

    For i := 0 To ThemeMenu.Count - 1 Do
      Ini.WriteBool('Option', ThemeMenu.Items[i].Name, ThemeMenu.Items[i].Checked);

    If Assigned(Form2) Then
    Begin

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
    End;

    Ini.WriteInteger('Option', 'Top', Top);
    Ini.WriteInteger('Option', 'Left', Left);

    Ini.UpdateFile;
  Finally
    Ini.Free;
  End;
End;

Procedure TForm1.UpdateCursorForAllLabels;
Begin
  If Form2.IsMouseIgnored Then
  Begin
    // Режим игнорирования - обычный курсор
    LabelNUmber.Cursor := crDefault;
    SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) Or WS_EX_TRANSPARENT);
  End
  Else
  Begin
    // Нормальный режим - рука
    LabelNUmber.Cursor := crHandPoint;
    SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) And Not WS_EX_TRANSPARENT);
  End;
End;

Procedure TForm1.LabelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Begin
  If Assigned(Form2) And Form2.IsMouseIgnored Then
  Begin
    // Блокируем всё в режиме игнорирования
    PopupMenu1.AutoPopup := False; // Отключаем авто-показ
    Exit;
  End;

  PopupMenu1.AutoPopup := True; // Включаем авто-показ

  If Button = mbLeft Then
  Begin
    // Перемещение окна
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, $F012, 0);
  End
  Else If Button = mbRight Then
  Begin
    // Контекстное меню
    SetForegroundWindow(Handle);
    PopupMenu1.PopupComponent := TLabel(Sender);
    PopupMenu1.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  End;
End;

Procedure TForm1.MenuAboutClick(Sender: TObject);
Begin
  Try
    Form8.ShowModal;
  Except
  End;
End;

Procedure TForm1.MenuExitClick(Sender: TObject);
Begin
  Close;
End;

Procedure TForm1.MenuCheckUpdateClick(Sender: TObject);
Begin
  Try
    Form10.ShowModal;
  Except
  End;
End;

Procedure TForm1.SettingsClick(Sender: TObject);
Begin
  If Assigned(Form2) Then
    Form2.Show;
End;

Procedure TForm1.PopupMenu1Popup(Sender: TObject);
Begin
  SetWindowPos(Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE Or SWP_NOMOVE Or SWP_NOSIZE Or SWP_NOREDRAW);
  ShowWindow(Application.Handle, SW_HIDE);
  application.ProcessMessages;
End;

Procedure TForm1.UnCheckTheme;
Var
  i: Integer;
Begin
  For i := 0 To ThemeMenu.Count - 1 Do
  Begin
    ThemeMenu.Items[i].Checked := False;
  End;
End;

Procedure TForm1.ThemeAutoClick(Sender: TObject);
Begin
  UnCheckTheme;
  ThemeAuto.Checked := True;

  If DarkModeIsEnabled Then
    SetSpecificThemeMode(True, 'Windows11 Modern Dark', 'Windows11 Modern Light')
  Else
    SetSpecificThemeMode(True, 'Windows11 Modern Light', 'Windows11 Modern Dark');
End;

Procedure TForm1.ThemeDarkClick(Sender: TObject);
Begin
  UnCheckTheme;
  ThemeDark.Checked := True;
  SetSpecificThemeMode(True, 'Windows11 Modern Dark', 'Windows11 Modern Light');
End;

Procedure TForm1.ThemeLightClick(Sender: TObject);
Begin
  UnCheckTheme;
  ThemeLight.Checked := True;
  SetSpecificThemeMode(True, 'Windows11 Modern Light', 'Windows11 Modern Dark');
End;

{Procedure TForm1.UpdateWindowSize;
Begin
  ClientWidth := LabelNumber.Canvas.TextWidth(LabelNumber.Caption) + 20;
  application.ProcessMessages;
End;   }

Procedure TForm1.ApplyScale;
Var
  ScaleFactor: Double;
  FontMultiplier: Integer;
  BaseFontSize: Integer;
  NewWidth, NewHeight: Integer;
  ScreenHeight, ScreenWidth, ScalePercent: Integer;
  ScreenResolutionFactor: Double; // Коэффициент для учета разрешения экрана
Begin
  Case Form2.ComboBoxFont.ItemIndex Of
    0:
      FontMultiplier := 8;
    1:
      FontMultiplier := 8;
    2:
      FontMultiplier := 6;
    3:
      FontMultiplier := 8;
    4:
      FontMultiplier := 6;
  Else
    FontMultiplier := 6;
  End;

  ScalePercent := Form2.TrackBarScale.Position;
  ScaleFactor := ScalePercent / 100;

  // Получаем размеры экрана
  ScreenHeight := Screen.WorkAreaHeight;
  ScreenWidth := Screen.WorkAreaWidth;

  // Определяем коэффициент для учета разрешения экрана
  // Базовое разрешение 1366x768 = 1.0
  // Для Full HD (1920x1080) и выше уменьшаем шрифт
  If ScreenWidth >= 1920 Then
    ScreenResolutionFactor := 1.2  // Full HD и выше - уменьшаем на 15%
  Else If ScreenWidth >= 1600 Then
    ScreenResolutionFactor := 0.9   // 1600x900 - уменьшаем на 10%
  Else If ScreenWidth >= 1366 Then
    ScreenResolutionFactor := 0.75   // 1366x768 - стандарт
  Else If ScreenWidth >= 1280 Then
    ScreenResolutionFactor := 0.65   // 1280x720 - увеличиваем на 10%
  Else
    ScreenResolutionFactor := 0.65;  // Меньше 1280 - увеличиваем на 20%

  BaseFontSize := 20;
  If FOriginalWidth = 0 Then
  Begin
    FOriginalWidth := Width;
    FOriginalHeight := Form1.LabelNumber.Height + 20;
    BaseFontSize := 20;
  End;

  // Масштабируем размеры окна
  NewWidth := Round(FOriginalWidth * ScaleFactor);
  NewHeight := Round(FOriginalHeight * ScaleFactor);

  // Ограничиваем максимальную высоту экраном
  If NewHeight > ScreenHeight - 50 Then
    NewHeight := ScreenHeight - 50;

  // Ограничиваем максимальную ширину экраном
  If NewWidth > ScreenWidth - 50 Then
    NewWidth := ScreenWidth - 50;

  // Устанавливаем ширину
  Width := NewWidth;
  Height := NewHeight;

  // Размер шрифта с учетом разрешения экрана
  If ScalePercent > 80 Then
    LabelNumber.Font.Size := Max(8, Round(BaseFontSize * ScaleFactor * FontMultiplier * ScreenResolutionFactor))
  Else If (ScalePercent <= 80) And (ScalePercent > 40) Then
    LabelNumber.Font.Size := Max(8, Round(BaseFontSize * ScaleFactor * (FontMultiplier - 2) * ScreenResolutionFactor))
  Else If ScalePercent <= 40 Then
    LabelNumber.Font.Size := Max(8, Round(BaseFontSize * ScaleFactor * (FontMultiplier - 3) * ScreenResolutionFactor));

  Invalidate;
End;

Procedure TForm1.Timer1Timer(Sender: TObject);
Begin
  LockWindowUpdate(handle);
  SetWindowPos(Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE Or SWP_NOMOVE Or SWP_NOSIZE Or SWP_NOREDRAW Or SWP_FRAMECHANGED);
  ShowWindow(Application.Handle, SW_HIDE);
  //UpdateWindowSize;
  If Form2.RadioButtonDefaultPosition.Checked Then
  Begin
    Form1.Left := (Screen.WorkAreaWidth - Width - 20) Div 2;
    Form1.Top := (Screen.WorkAreaHeight - Height) Div 2;
  End;
  InvalidateRect(Handle, Nil, False);
  ShowWindow(Application.handle, SW_HIDE);
  Application.ProcessMessages;
  LockWindowUpdate(0);
  invalidate;
  Update;
End;

Function TForm1.GetDesktopColor: TColor;
Var
  WallpaperPath: Array[0..MAX_PATH] Of Char;
  Bitmap: TBitmap;
  Jpeg: TJPEGImage;
  Png: TPngImage;
  Ext: String;
  Points: Array[0..3] Of TPoint;
  I, R, G, B: Integer;
Begin
  Result := clWhite;

  If Not SystemParametersInfo(SPI_GETDESKWALLPAPER, MAX_PATH, @WallpaperPath, 0) Then
    Exit;

  If (WallpaperPath[0] = #0) Or Not FileExists(String(WallpaperPath)) Then
    Exit;

  Try
    Bitmap := TBitmap.Create;
    Try
      Ext := LowerCase(ExtractFileExt(String(WallpaperPath)));

      // Быстрая загрузка только заголовка
      If (Ext = '.jpg') Or (Ext = '.jpeg') Then
      Begin
        Jpeg := TJPEGImage.Create;
        Try
          Jpeg.Scale := jsEighth; // 1/8 размера!
          Jpeg.LoadFromFile(String(WallpaperPath));
          Bitmap.Assign(Jpeg);
        Finally
          Jpeg.Free;
        End;
      End
      Else If Ext = '.png' Then
      Begin
        Png := TPngImage.Create;
        Try
          // Загружаем как есть (PNG обычно меньше)
          Png.LoadFromFile(String(WallpaperPath));

          // Уменьшаем если очень большое
          If (Png.Width > 100) Or (Png.Height > 100) Then
          Begin
            Bitmap.Width := 100;
            Bitmap.Height := 100;
            Bitmap.Canvas.StretchDraw(Rect(0, 0, 100, 100), Png);
          End
          Else
            Bitmap.Assign(Png);
        Finally
          Png.Free;
        End;
      End
      Else
      Begin
        // Для BMP просто загружаем
        Bitmap.LoadFromFile(String(WallpaperPath));
      End;

      // Анализируем только 4 точки (углы)
      R := 0;
      G := 0;
      B := 0;

      // Координаты углов
      Points[0] := Point(0, 0); // Левый верхний
      Points[1] := Point(Bitmap.Width - 1, 0); // Правый верхний
      Points[2] := Point(0, Bitmap.Height - 1); // Левый нижний
      Points[3] := Point(Bitmap.Width - 1, Bitmap.Height - 1); // Правый нижний

      For I := 0 To 3 Do
      Begin
        If (Points[I].X >= 0) And (Points[I].X < Bitmap.Width) And (Points[I].Y >= 0) And (Points[I].Y < Bitmap.Height) Then
        Begin
          Result := Bitmap.Canvas.Pixels[Points[I].X, Points[I].Y];
          R := R + GetRValue(Result);
          G := G + GetGValue(Result);
          B := B + GetBValue(Result);
        End;
      End;

      Result := RGB(R Div 4, G Div 4, B Div 4);

    Finally
      Bitmap.Free;
    End;
  Except
    Result := clWhite;
  End;
End;

Function TForm1.GetContrastColor(Color: TColor): TColor;
Var
  BGColor: TColor;
  R, G, B, Luma: Integer;
Begin
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
  If Luma > 128 Then
    Result := clBlack  // Черный текст на светлом фоне
  Else
    Result := clWhite; // Белый текст на темном фоне
End;

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

Procedure TForm1.GetDesktopColorAsync;
Begin
  If FIsProcessingWallpaper Then
    Exit; // Уже в процессе обработки, выходим

  FIsProcessingWallpaper := True;

  TThread.CreateAnonymousThread(
    Procedure
    Var
      CurrentPath: String;
      WallpaperPath: Array[0..MAX_PATH] Of Char;
    Begin
      Try
        // Получаем текущий путь к обоям
        If SystemParametersInfo(SPI_GETDESKWALLPAPER, MAX_PATH, @WallpaperPath, 0) Then
          CurrentPath := String(WallpaperPath)
        Else
          CurrentPath := '';

        // Проверяем, изменились ли обои
            If (CurrentPath <> '') And (CurrentPath <> FLastWallpaperPath) Then
        Begin
          Color := GetDesktopColor; // Ваша существующая функция

          TThread.Queue(Nil,
            Procedure
            Begin
              FLastWallpaperPath := CurrentPath;
              FCachedDesktopColor := Color;

              // Обновляем UI
              If Form2.CheckBoxAutoColor.Checked Then
              Begin
                Form1.LabelNumber.Font.Color := GetContrastColor(NewDesktopColor);
              End;

              FIsProcessingWallpaper := False;
            End);
        End
        Else
        Begin
          TThread.Queue(Nil,
            Procedure
            Begin
              FIsProcessingWallpaper := False;
            End);
        End;
      Except
        TThread.Queue(Nil,
          Procedure
          Begin
            FIsProcessingWallpaper := False;
          End);
      End;
    End).Start;
End;

Procedure TForm1.GetDesktopColorAsyncA;
Begin
  If FIsProcessingWallpaperA Then
    Exit; // Уже в процессе обработки, выходим

  FIsProcessingWallpaperA := True;

  TThread.CreateAnonymousThread(
    Procedure
    Var
      DesktopColor: TColor;
      Success: Boolean;
    Begin
      Success := False;
      DesktopColor := clBlack; // Значение по умолчанию

      Try
        Try
          // Получаем цвет рабочего стола
          DesktopColor := GetDesktopColor; // Ваша существующая функция
          Success := True;

        Except
          Success := False;
        End;

      Finally
        TThread.Queue(Nil,
          Procedure
          Begin
            If Success Then
            Begin
              // Обновляем UI только если получение цвета было успешным
              If Form2.CheckBoxAutoColor.Checked Then
              Begin
                Form1.LabelNumber.Font.Color := GetContrastColor(DesktopColor);
              End;
            End;

            FIsProcessingWallpaperA := False;
          End);
      End;
    End).Start;
End;

Procedure TForm1.WMMove(Var Msg: TWMMove);
Begin
  Inherited;

End;

Procedure TForm1.WMSysColorChange(Var Message: TMessage);
Begin
  Inherited;
  Color := GetDesktopColor;
End;

Procedure TForm1.Timer2Timer(Sender: TObject);
Begin
  // Проверяем раз в 5 секунд вместо каждого тика таймера
  If GetTickCount - FLastUpdateTime < 1000 Then
    Exit;

  FLastUpdateTime := GetTickCount;

  // Используем кэшированный цвет, если обои не изменились
  If Form2.CheckBoxAutoColor.Checked Then
  Begin
    // Проверяем обои асинхронно
    GetDesktopColorAsync;
  End;
End;

Procedure TForm1.TrayIcon1DblClick(Sender: TObject);
Begin
  If Not Visible Then
  Begin
    Show;
    BringToFront;
  End
  Else
  Begin
    Hide;
  End;
End;

Procedure TForm1.TrayIcon1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
Begin
  If portable = True Then
    TrayIcon1.Hint := getFileDescription(ParamStr(0)) + #13 + GetFileVersion(ParamStr(0)) + ' ' + GetApplicationBitness + #13 + ' Portable'
  Else
    TrayIcon1.Hint := getFileDescription(ParamStr(0)) + #13 + GetFileVersion(ParamStr(0)) + ' ' + GetApplicationBitness;
  Application.ProcessMessages;
End;

Procedure TForm1.WMMoving(Var Msg: TWmMoving);
Var
  r: TRect;
Begin
  r := Screen.WorkareaRect;
  If Msg.lpRect^.Left < r.Left Then
    OffsetRect(Msg.lpRect^, r.Left - Msg.lpRect^.Left, 0);
  If Msg.lpRect^.Top < r.Top Then
    OffsetRect(Msg.lpRect^, 0, r.Top - Msg.lpRect^.Top);
  If Msg.lpRect^.Right > r.Right Then
    OffsetRect(Msg.lpRect^, r.Right - Msg.lpRect^.Right, 0);
  If Msg.lpRect^.Bottom > r.Bottom Then
    OffsetRect(Msg.lpRect^, 0, r.Bottom - Msg.lpRect^.Bottom);
  Inherited;
End;

Procedure TForm1.WMExitSizeMove(Var Msg: TMessage);
Begin
  Inherited;
  KeepFormInWorkArea;
  GetDesktopColorAsyncA;
End;

Procedure TForm1.KeepFormInWorkArea;
Var
  r: TRect;
Begin
  r := Screen.WorkAreaRect;

  // Если форма выходит за правую границу
  If Left + Width > r.Right Then
    Left := r.Right - Width;

  // Если форма выходит за нижнюю границу
  If Top + Height > r.Bottom Then
    Top := r.Bottom - Height;

  // Если форма выходит за левую границу
  If Left < r.Left Then
    Left := r.Left;

  // Если форма выходит за верхнюю границу
  If Top < r.Top Then
    Top := r.Top;
End;

End.

