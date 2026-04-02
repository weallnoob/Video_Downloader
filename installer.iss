[Setup]
AppId={{94B2AB15-91BE-4E31-9E2C-6079DE0C8F5A}
AppName=Video Downloader
AppVersion=1.1.1
AppPublisher=Video Downloader Project
DefaultDirName={autopf}\VideoDownloader
DefaultGroupName=Video Downloader
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=VideoDownloaderInstaller
#ifndef NoSetupIcon
SetupIconFile=assets\app_icon.ico
#endif
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
CloseApplications=yes
RestartApplications=no
CloseApplicationsFilter=VideoDownloader.exe,QtWebEngineProcess.exe

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Tasks]
Name: "desktopicon"; Description: "바탕 화면 바로가기 생성"; GroupDescription: "추가 작업:"; Flags: unchecked

[Files]
Source: "dist\VideoDownloader\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "bin\ffmpeg.exe,bin\ffprobe.exe,bin\ffplay.exe,bin\yt-dlp.exe,bin\aria2c.exe,_internal\bin\yt-dlp.exe,_internal\bin\aria2c.exe,_internal\yt_dlp\*,_internal\cryptography\*,_internal\curl_cffi\*"

[Icons]
Name: "{autoprograms}\Video Downloader"; Filename: "{app}\VideoDownloader.exe"
Name: "{autodesktop}\Video Downloader"; Filename: "{app}\VideoDownloader.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\VideoDownloader.exe"; Description: "{cm:LaunchProgram,Video Downloader}"; Flags: nowait postinstall skipifsilent

[Code]
const
  BuyMeACoffeeUrl = 'https://www.buymeacoffee.com/aminora';
  YtdlpExeUrl = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
  Aria2PrimaryZipUrl = 'https://github.com/aria2/aria2/releases/latest/download/aria2-1.37.0-win-64bit-build1.zip';
  Aria2FallbackZipUrl = 'https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip';
  FfmpegPrimaryZipUrl = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';
  FfmpegFallbackZipUrl = 'https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip';
  RuntimeProgressGaugeMax = 1000;
  RuntimeProgressGaugeStart = 800;
  RuntimeProgressGaugeEnd = 995;

var
  InstallingSupportButton: TNewButton;
  RuntimeDownloadPlannedFiles: Integer;
  RuntimeDownloadCompletedFiles: Integer;
  RuntimeDownloadCompletedBytes: Int64;
  RuntimeDownloadCurrentBytes: Int64;
  RuntimeDownloadCurrentTotalBytes: Int64;
  RuntimeDownloadCurrentLabel: string;

procedure OpenBuyMeACoffee(Sender: TObject);
var
  ErrorCode: Integer;
begin
  if not ShellExec('open', BuyMeACoffeeUrl, '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode) then
    MsgBox('웹 브라우저를 열 수 없습니다.'#13#10 + BuyMeACoffeeUrl, mbError, MB_OK);
end;

procedure RepositionInstallingSupportControls;
var
  Host: TWinControl;
  StartTop: Integer;
  MinTop: Integer;
begin
  Host := WizardForm.ProgressGauge.Parent;

  StartTop := (Host.ClientHeight - InstallingSupportButton.Height) div 2;
  MinTop := WizardForm.ProgressGauge.Top + WizardForm.ProgressGauge.Height + ScaleY(8);
  if StartTop < MinTop then
    StartTop := MinTop;

  InstallingSupportButton.Left := (Host.ClientWidth - InstallingSupportButton.Width) div 2;
  InstallingSupportButton.Top := StartTop;
end;

procedure TerminateProcessIfRunning(const ImageName: string);
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /T /IM "' + ImageName + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function EscapePsSingleQuoted(const Value: string): string;
var
  S: string;
begin
  S := Value;
  StringChangeEx(S, '''', '''''', True);
  Result := S;
end;

function FormatBytes(const Bytes: Int64): string;
var
  Whole: Int64;
  Decimal: Int64;
begin
  if Bytes >= 1024 * 1024 then
  begin
    Whole := Bytes div (1024 * 1024);
    Decimal := ((Bytes mod (1024 * 1024)) * 10) div (1024 * 1024);
    Result := IntToStr(Whole) + '.' + IntToStr(Decimal) + ' MB';
  end
  else if Bytes >= 1024 then
  begin
    Result := IntToStr(Bytes div 1024) + ' KB';
  end
  else
  begin
    Result := IntToStr(Bytes) + ' B';
  end;
end;

procedure StartRuntimeDownloadProgress(const PlannedFiles: Integer);
begin
  RuntimeDownloadPlannedFiles := PlannedFiles;
  RuntimeDownloadCompletedFiles := 0;
  RuntimeDownloadCompletedBytes := 0;
  RuntimeDownloadCurrentBytes := 0;
  RuntimeDownloadCurrentTotalBytes := 0;
  RuntimeDownloadCurrentLabel := '';

  WizardForm.ProgressGauge.Max := RuntimeProgressGaugeMax;
  WizardForm.ProgressGauge.Position := RuntimeProgressGaugeStart;
end;

procedure UpdateRuntimeDownloadProgressUi;
var
  CurrentFraction: Extended;
  OverallFraction: Extended;
  Position: Integer;
  KnownTotalBytes: Int64;
  DownloadedBytes: Int64;
  Percent: Integer;
  CurrentDisplayFiles: Integer;
  ShowKnownTotal: Boolean;
  MessageText: string;
begin
  if RuntimeDownloadPlannedFiles <= 0 then
    Exit;

  if RuntimeDownloadCurrentTotalBytes > 0 then
    CurrentFraction := RuntimeDownloadCurrentBytes / RuntimeDownloadCurrentTotalBytes
  else
    CurrentFraction := 0.0;

  if CurrentFraction < 0.0 then
    CurrentFraction := 0.0
  else if CurrentFraction > 1.0 then
    CurrentFraction := 1.0;

  OverallFraction := (RuntimeDownloadCompletedFiles + CurrentFraction) / RuntimeDownloadPlannedFiles;
  if OverallFraction < 0.0 then
    OverallFraction := 0.0
  else if OverallFraction > 1.0 then
    OverallFraction := 1.0;

  Position := RuntimeProgressGaugeStart + Round((RuntimeProgressGaugeEnd - RuntimeProgressGaugeStart) * OverallFraction);
  if Position < RuntimeProgressGaugeStart then
    Position := RuntimeProgressGaugeStart;
  if Position > RuntimeProgressGaugeEnd then
    Position := RuntimeProgressGaugeEnd;
  WizardForm.ProgressGauge.Position := Position;

  DownloadedBytes := RuntimeDownloadCompletedBytes + RuntimeDownloadCurrentBytes;
  KnownTotalBytes := RuntimeDownloadCompletedBytes + RuntimeDownloadCurrentTotalBytes;
  if KnownTotalBytes < DownloadedBytes then
    KnownTotalBytes := DownloadedBytes;

  Percent := Round(OverallFraction * 100.0);
  CurrentDisplayFiles := RuntimeDownloadCompletedFiles;
  if RuntimeDownloadCurrentBytes > 0 then
    Inc(CurrentDisplayFiles);

  MessageText := '필수 요소 다운로드중... ' + IntToStr(Percent) + '% (' +
    IntToStr(CurrentDisplayFiles) + '/' + IntToStr(RuntimeDownloadPlannedFiles) + ', ' +
    FormatBytes(DownloadedBytes);
  ShowKnownTotal := (RuntimeDownloadCurrentTotalBytes > 0) or (RuntimeDownloadCompletedFiles >= RuntimeDownloadPlannedFiles);
  if ShowKnownTotal and (KnownTotalBytes > 0) then
    MessageText := MessageText + ' / ' + FormatBytes(KnownTotalBytes);
  MessageText := MessageText + ')';
  if RuntimeDownloadCurrentLabel <> '' then
    MessageText := MessageText + ' - ' + RuntimeDownloadCurrentLabel;

  WizardForm.StatusLabel.Caption := MessageText;
end;

function OnRuntimeDownloadProgress(const Url, FileName: string; const Progress, ProgressMax: Int64): Boolean;
begin
  RuntimeDownloadCurrentBytes := Progress;
  if ProgressMax > 0 then
    RuntimeDownloadCurrentTotalBytes := ProgressMax;
  UpdateRuntimeDownloadProgressUi;
  Result := True;
end;

function DownloadToTempFile(
  const PrimaryUrl: string;
  const FallbackUrl: string;
  const TempBaseName: string;
  const DisplayName: string;
  var TempPath: string;
  var ErrorText: string
): Boolean;
var
  DownloadedSize: Int64;
begin
  Result := False;
  ErrorText := '';
  TempPath := ExpandConstant('{tmp}\' + TempBaseName);

  if FileExists(TempPath) then
    DeleteFile(TempPath);

  RuntimeDownloadCurrentLabel := DisplayName;
  RuntimeDownloadCurrentBytes := 0;
  RuntimeDownloadCurrentTotalBytes := 0;
  UpdateRuntimeDownloadProgressUi;

  try
    DownloadTemporaryFile(PrimaryUrl, TempBaseName, '', @OnRuntimeDownloadProgress);
    Result := True;
  except
    ErrorText := GetExceptionMessage;
  end;

  if (not Result) and (FallbackUrl <> '') then
  begin
    if FileExists(TempPath) then
      DeleteFile(TempPath);
    RuntimeDownloadCurrentBytes := 0;
    RuntimeDownloadCurrentTotalBytes := 0;
    UpdateRuntimeDownloadProgressUi;

    try
      DownloadTemporaryFile(FallbackUrl, TempBaseName, '', @OnRuntimeDownloadProgress);
      Result := True;
    except
      ErrorText := GetExceptionMessage;
    end;
  end;

  if not Result then
    Exit;

  if not FileExists(TempPath) then
  begin
    Result := False;
    ErrorText := '다운로드 파일을 찾을 수 없습니다: ' + TempPath;
    Exit;
  end;

  DownloadedSize := RuntimeDownloadCurrentBytes;
  if DownloadedSize < 0 then
    DownloadedSize := 0;

  RuntimeDownloadCompletedBytes := RuntimeDownloadCompletedBytes + DownloadedSize;
  RuntimeDownloadCompletedFiles := RuntimeDownloadCompletedFiles + 1;
  RuntimeDownloadCurrentBytes := 0;
  RuntimeDownloadCurrentTotalBytes := 0;
  UpdateRuntimeDownloadProgressUi;
end;

function ExtractExeFromZipWithPowerShell(const ZipPath, ExeFilter, TargetPath: string): Boolean;
var
  PsExe: string;
  ScriptPath: string;
  ExtractPath: string;
  ScriptContent: string;
  ResultCode: Integer;
begin
  Result := False;
  PsExe := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
  ScriptPath := ExpandConstant('{tmp}\extract_runtime_zip.ps1');
  ExtractPath := ExpandConstant('{tmp}\runtime_deps_extract');

  ScriptContent :=
    '$ErrorActionPreference = ''Stop'''#13#10 +
    '$zip = ''' + EscapePsSingleQuoted(ZipPath) + ''''#13#10 +
    '$extract = ''' + EscapePsSingleQuoted(ExtractPath) + ''''#13#10 +
    '$filter = ''' + EscapePsSingleQuoted(ExeFilter) + ''''#13#10 +
    '$target = ''' + EscapePsSingleQuoted(TargetPath) + ''''#13#10 +
    'try {'#13#10 +
    '  if (-not (Test-Path $zip)) { throw ''archive not found'' }'#13#10 +
    '  if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }'#13#10 +
    '    Expand-Archive -Path $zip -DestinationPath $extract -Force'#13#10 +
    '  $exe = Get-ChildItem -Path $extract -Recurse -Filter $filter | Select-Object -First 1'#13#10 +
    '  if (-not $exe) { throw ''target exe not found'' }'#13#10 +
    '  New-Item -Path (Split-Path $target) -ItemType Directory -Force | Out-Null'#13#10 +
    '  Copy-Item $exe.FullName $target -Force'#13#10 +
    '} finally {'#13#10 +
    '  if (Test-Path $extract) { Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue }'#13#10 +
    '}'#13#10;

  if not SaveStringToFile(ScriptPath, ScriptContent, False) then
  begin
    Result := False;
    Exit;
  end;

  Result := Exec(PsExe, '-NoProfile -ExecutionPolicy Bypass -File "' + ScriptPath + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0) and FileExists(TargetPath);
  DeleteFile(ScriptPath);
end;

function InstallRuntimeBinariesOnline: Boolean;
var
  BinDir: string;
  FfmpegTargetPath: string;
  YtdlpTargetPath: string;
  Aria2TargetPath: string;
  NeedYtdlp: Boolean;
  NeedAria2: Boolean;
  NeedFfmpeg: Boolean;
  PlannedFiles: Integer;
  TempPath: string;
  ErrorText: string;
begin
  Result := False;
  BinDir := ExpandConstant('{app}\bin');
  FfmpegTargetPath := ExpandConstant('{app}\bin\ffmpeg.exe');
  YtdlpTargetPath := ExpandConstant('{app}\bin\yt-dlp.exe');
  Aria2TargetPath := ExpandConstant('{app}\bin\aria2c.exe');

  NeedYtdlp := not FileExists(YtdlpTargetPath);
  NeedAria2 := not FileExists(Aria2TargetPath);
  NeedFfmpeg := not FileExists(FfmpegTargetPath);

  PlannedFiles := 0;
  if NeedYtdlp then
    Inc(PlannedFiles);
  if NeedAria2 then
    Inc(PlannedFiles);
  if NeedFfmpeg then
    Inc(PlannedFiles);

  if PlannedFiles = 0 then
  begin
    Result := True;
    Exit;
  end;

  if (not DirExists(BinDir)) and (not ForceDirectories(BinDir)) then
    Exit;

  StartRuntimeDownloadProgress(PlannedFiles);
  UpdateRuntimeDownloadProgressUi;

  if NeedYtdlp then
  begin
    if not DownloadToTempFile(YtdlpExeUrl, '', 'runtime_yt-dlp.exe', 'yt-dlp', TempPath, ErrorText) then
      Exit;
    if not FileCopy(TempPath, YtdlpTargetPath, False) then
      Exit;
    DeleteFile(TempPath);
  end;

  if NeedAria2 then
  begin
    if not DownloadToTempFile(Aria2PrimaryZipUrl, Aria2FallbackZipUrl, 'runtime_aria2.zip', 'aria2c', TempPath, ErrorText) then
      Exit;
    if not ExtractExeFromZipWithPowerShell(TempPath, 'aria2c.exe', Aria2TargetPath) then
      Exit;
    DeleteFile(TempPath);
  end;

  if NeedFfmpeg then
  begin
    if not DownloadToTempFile(FfmpegPrimaryZipUrl, FfmpegFallbackZipUrl, 'runtime_ffmpeg.zip', 'ffmpeg', TempPath, ErrorText) then
      Exit;
    if not ExtractExeFromZipWithPowerShell(TempPath, 'ffmpeg.exe', FfmpegTargetPath) then
      Exit;
    DeleteFile(TempPath);
  end;

  WizardForm.ProgressGauge.Position := RuntimeProgressGaugeMax;
  WizardForm.StatusLabel.Caption := '필수 요소 다운로드 완료';
  Result := FileExists(FfmpegTargetPath) and FileExists(YtdlpTargetPath) and FileExists(Aria2TargetPath);
end;

procedure CurPageChanged(CurPageID: Integer);
var
  VisibleOnInstalling: Boolean;
begin
  VisibleOnInstalling := CurPageID = wpInstalling;
  InstallingSupportButton.Visible := VisibleOnInstalling;
  if VisibleOnInstalling then
    RepositionInstallingSupportControls;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    TerminateProcessIfRunning('VideoDownloader.exe');
    TerminateProcessIfRunning('QtWebEngineProcess.exe');
    TerminateProcessIfRunning('yt-dlp.exe');
    TerminateProcessIfRunning('aria2c.exe');
    TerminateProcessIfRunning('ffmpeg.exe');
  end;

  if CurStep = ssPostInstall then
  begin
    WizardForm.StatusLabel.Caption := '필수 요소 다운로드중...';
    if not InstallRuntimeBinariesOnline then
    begin
      MsgBox(
        '필수 요소 다운로드에 실패했습니다.'#13#10 +
        '네트워크 연결을 확인한 후 다시 설치해 주세요.',
        mbError,
        MB_OK
      );
      RaiseException('runtime dependency online install failed');
    end;
  end;
end;

procedure InitializeWizard;
var
  Host: TWinControl;
begin
  Host := WizardForm.ProgressGauge.Parent;

  InstallingSupportButton := TNewButton.Create(WizardForm);
  InstallingSupportButton.Parent := Host;
  InstallingSupportButton.Caption := 'Buy Me a Coffee';
  InstallingSupportButton.Width := ScaleX(170);
  InstallingSupportButton.Height := ScaleY(28);
  InstallingSupportButton.Visible := False;
  InstallingSupportButton.OnClick := @OpenBuyMeACoffee;

  RepositionInstallingSupportControls;
end;
