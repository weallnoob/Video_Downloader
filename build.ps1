param(
  [switch]$SkipInstall,
  [switch]$SkipDownload,
  [switch]$SkipBuild,
  [switch]$SkipInstaller,
  [switch]$OfflineMode
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

function Resolve-IsccPath {
  $candidate = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
  if ($candidate) {
    return $candidate.Source
  }

  $paths = @(
    "${env:ProgramFiles(x86)}\\Inno Setup 6\\ISCC.exe",
    "$env:ProgramFiles\\Inno Setup 6\\ISCC.exe",
    "${env:ProgramFiles(x86)}\\Inno Setup 5\\ISCC.exe",
    "$env:ProgramFiles\\Inno Setup 5\\ISCC.exe",
    "$env:LOCALAPPDATA\\Programs\\Inno Setup 6\\ISCC.exe",
    "$env:LOCALAPPDATA\\Programs\\Inno Setup 5\\ISCC.exe"
  )

  foreach ($path in $paths) {
    if (Test-Path $path) {
      return $path
    }
  }

  $regRoots = @(
    "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*",
    "HKLM:\\Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*"
  )
  foreach ($root in $regRoots) {
    $items = Get-ItemProperty $root -ErrorAction SilentlyContinue
    foreach ($item in $items) {
      if ($item.DisplayName -and $item.DisplayName -like "*Inno*Setup*") {
        $installLocation = "$($item.InstallLocation)".Trim()
        if ($installLocation) {
          $iscc = Join-Path $installLocation "ISCC.exe"
          if (Test-Path $iscc) {
            return $iscc
          }
        }
      }
    }
  }

  return $null
}

function Invoke-IsccCompile {
  param(
    [string]$IsccPath,
    [string]$OutputDir,
    [string]$OutputBaseName,
    [switch]$NoSetupIcon
  )

  $arguments = @(
    "/Qp",
    "/O$OutputDir",
    "/F$OutputBaseName"
  )

  if ($NoSetupIcon) {
    $arguments += "/DNoSetupIcon=1"
  }

  $arguments += "installer.iss"

  & $IsccPath @arguments | Out-Host
  return [int]$LASTEXITCODE
}

function Test-PythonModuleInstalled {
  param(
    [string]$ModuleName
  )

  python -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('$ModuleName') else 1)" | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Stop-ProcessIfRunning {
  param(
    [string]$ProcessName
  )

  $procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
  if ($null -ne $procs) {
    $procs | Stop-Process -Force -ErrorAction SilentlyContinue
  }
}

function Remove-PathWithRetry {
  param(
    [string]$TargetPath
  )

  if (-not (Test-Path $TargetPath)) {
    return
  }

  for ($i = 0; $i -lt 5; $i++) {
    try {
      Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
      return
    }
    catch {
      Start-Sleep -Milliseconds (300 * ($i + 1))
    }
  }

  if (Test-Path $TargetPath) {
    throw "경로를 삭제하지 못했습니다: $TargetPath"
  }
}

function Invoke-PyInstallerBuild {
  param(
    [string]$SpecFile
  )

  $timeTag = Get-Date -Format "yyyyMMdd_HHmmss"
  $pyiRoot = Join-Path $env:TEMP "VideoDownloaderPyInstaller"
  $pyiWork = Join-Path $pyiRoot "work_$timeTag"
  $pyiDist = Join-Path $pyiRoot "dist_$timeTag"
  New-Item -Path $pyiWork -ItemType Directory -Force | Out-Null
  New-Item -Path $pyiDist -ItemType Directory -Force | Out-Null

  for ($attempt = 1; $attempt -le 2; $attempt++) {
    python -m PyInstaller --noconfirm --clean --workpath $pyiWork --distpath $pyiDist $SpecFile
    if ($LASTEXITCODE -eq 0) {
      return @{ ExitCode = 0; DistPath = $pyiDist }
    }
    Write-Warning "PyInstaller 실패(시도 $attempt/2, 코드: $LASTEXITCODE). 잠시 후 재시도합니다."
    Start-Sleep -Seconds (1 + $attempt)
  }

  return @{ ExitCode = $LASTEXITCODE; DistPath = $pyiDist }
}

function Rotate-ExistingDistAppDir {
  param(
    [string]$TargetPath
  )

  if (-not (Test-Path $TargetPath)) {
    return
  }

  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $backupPath = "${TargetPath}_old_$stamp"
  Rename-Item -Path $TargetPath -NewName (Split-Path $backupPath -Leaf) -Force
  Write-Warning "잠금된 기존 산출물을 백업으로 이동했습니다: $backupPath"
}

if (-not $SkipInstall) {
  if ($OfflineMode) {
    Write-Host "오프라인 모드: Python 패키지 자동 설치를 건너뜁니다."
  }
  else {
    python -m pip install -r requirements-build.txt
  }
}

if (-not (Test-Path "bin")) {
  New-Item -ItemType Directory -Path "bin" | Out-Null
}

if (-not $SkipDownload) {
  if ($OfflineMode) {
    Write-Host "오프라인 모드: 빌드 단계 바이너리 자동 다운로드를 건너뜁니다. (설치 시 온라인 설치 필요)"
  }
  else {
    Write-Host "빌드 단계에서는 yt-dlp/aria2c를 번들링하지 않습니다. 설치 시 온라인으로 구성됩니다."
  }
}

# 용량 절감을 위해 실행에 필수적이지 않은 FFmpeg 보조 바이너리는 번들에서 제외
$optionalBinaries = @("bin\\ffprobe.exe", "bin\\ffplay.exe")
foreach ($optionalBinary in $optionalBinaries) {
  if (Test-Path $optionalBinary) {
    Remove-Item $optionalBinary -Force
    Write-Host "제거됨(용량 절감): $optionalBinary"
  }
}

if (-not $SkipBuild -and $OfflineMode) {
  if (-not (Test-PythonModuleInstalled "PyInstaller")) {
    throw "PyInstaller 모듈이 설치되어 있지 않습니다. 오프라인 모드에서는 자동 설치를 수행하지 않습니다."
  }
}

if (-not $SkipBuild) {
  Stop-ProcessIfRunning -ProcessName "VideoDownloader"
  Stop-ProcessIfRunning -ProcessName "QtWebEngineProcess"
  Stop-ProcessIfRunning -ProcessName "yt-dlp"
  Stop-ProcessIfRunning -ProcessName "ffmpeg"
  Stop-ProcessIfRunning -ProcessName "aria2c"

  $pyiResult = Invoke-PyInstallerBuild -SpecFile "VideoDownloader.spec"
  if ($pyiResult.ExitCode -ne 0) {
    throw "앱 빌드 실패 (PyInstaller 종료 코드: $($pyiResult.ExitCode))"
  }

  $builtAppPath = Join-Path $pyiResult.DistPath "VideoDownloader\\VideoDownloader.exe"
  if (-not (Test-Path $builtAppPath)) {
    throw "앱 빌드 결과물을 찾지 못했습니다: $builtAppPath"
  }

  if (-not (Test-Path "dist")) {
    New-Item -Path "dist" -ItemType Directory -Force | Out-Null
  }
  try {
    Remove-PathWithRetry -TargetPath "dist\\VideoDownloader"
  }
  catch {
    Rotate-ExistingDistAppDir -TargetPath "dist\\VideoDownloader"
  }
  Copy-Item -Path (Join-Path $pyiResult.DistPath "VideoDownloader") -Destination "dist" -Recurse -Force

  Write-Host "앱 빌드 완료: dist\\VideoDownloader\\VideoDownloader.exe"
}

if (-not $SkipInstaller) {
  if (-not (Test-Path "dist\\VideoDownloader\\VideoDownloader.exe")) {
    throw "설치 파일 생성을 위해 dist\\VideoDownloader\\VideoDownloader.exe가 필요합니다."
  }

  $isccPath = Resolve-IsccPath
  if (-not $isccPath) {
    throw "Inno Setup 6 (ISCC.exe)를 찾지 못했습니다. 설치 후 다시 실행하세요."
  }

  $tempOutputDir = Join-Path $env:TEMP "VideoDownloaderInstallerBuild"
  New-Item -ItemType Directory -Path $tempOutputDir -Force | Out-Null

  $primaryBaseName = "VideoDownloaderInstaller"
  $fallbackBaseName = "VideoDownloaderInstaller_{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss")
  $compiledBaseName = $primaryBaseName

  Write-Host "ISCC 컴파일 시작: OutputDir=$tempOutputDir, OutputBaseFilename=$primaryBaseName"
  $compileExitCode = Invoke-IsccCompile -IsccPath $isccPath -OutputDir $tempOutputDir -OutputBaseName $primaryBaseName

  if ($compileExitCode -ne 0) {
    Write-Warning "1차 ISCC 컴파일 실패(코드: $compileExitCode). 아이콘 제외 모드로 1회 재시도합니다."
    Start-Sleep -Seconds 2
    $compiledBaseName = $fallbackBaseName
    $compileExitCode = Invoke-IsccCompile -IsccPath $isccPath -OutputDir $tempOutputDir -OutputBaseName $fallbackBaseName -NoSetupIcon
  }

  if ($compileExitCode -ne 0) {
    throw "설치 파일 생성 실패 (ISCC 종료 코드: $compileExitCode). 위 ISCC 로그를 확인해 installer.iss 지시어/문법을 먼저 점검하세요. EndUpdateResource 관련 오류일 때만 백신 예외 처리가 필요합니다."
  }

  $compiledInstallerPath = Join-Path $tempOutputDir "$compiledBaseName.exe"
  if (-not (Test-Path $compiledInstallerPath)) {
    throw "설치 파일은 컴파일되었지만 결과물을 찾지 못했습니다: $compiledInstallerPath"
  }

  if (-not (Test-Path "dist")) {
    New-Item -ItemType Directory -Path "dist" | Out-Null
  }
  $finalInstallerPath = Join-Path $PSScriptRoot "dist\\VideoDownloaderInstaller.exe"
  Copy-Item -Path $compiledInstallerPath -Destination $finalInstallerPath -Force

  Write-Host "설치 파일 생성 완료: $finalInstallerPath"
}
