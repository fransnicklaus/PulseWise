param(
  [switch]$SkipBuild,
  [switch]$SkipDeploy
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step {
  param([string]$Message)

  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Require-Command {
  param([string]$Name)

  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Command '$Name' was not found in PATH."
  }
}

function Restore-VercelLink {
  param(
    [string]$SourceDir,
    [string]$TargetDir
  )

  if (-not (Test-Path $SourceDir)) {
    return
  }

  if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
  }

  Copy-Item -Path (Join-Path $SourceDir '*') -Destination $TargetDir -Recurse -Force
}

function Sync-WebSupportFiles {
  param(
    [string]$SourceDir,
    [string]$TargetDir
  )

  $supportFiles = @(
    'vercel.json'
  )

  foreach ($fileName in $supportFiles) {
    $sourcePath = Join-Path $SourceDir $fileName
    if (-not (Test-Path $sourcePath)) {
      continue
    }

    $targetPath = Join-Path $TargetDir $fileName
    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
  }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$webRootDir = Join-Path $repoRoot 'web'
$buildWebDir = Join-Path $repoRoot 'build\web'
$vercelDir = Join-Path $buildWebDir '.vercel'
$projectJsonPath = Join-Path $vercelDir 'project.json'
$vercelBackupDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pulsewise-vercel-link-" + [Guid]::NewGuid().ToString('N'))
$hadVercelLink = Test-Path $vercelDir

try {
  Set-Location $repoRoot

  if (-not $SkipBuild) {
    Require-Command 'flutter'

    if ($hadVercelLink) {
      Write-Step 'Backing up build/web/.vercel link metadata'
      Copy-Item -Path $vercelDir -Destination $vercelBackupDir -Recurse -Force
    }

    $flutterArgs = @(
      'build',
      'web',
      '--release'
    )

    $dartDefineKeys = @(
      'API_BASE_URL',
      'GOOGLE_WEB_CLIENT_ID',
      'GOOGLE_CLIENT_ID',
      'GOOGLE_SERVER_CLIENT_ID',
      'CLOUDINARY_FOLDER'
    )

    foreach ($key in $dartDefineKeys) {
      $value = [Environment]::GetEnvironmentVariable($key)
      if ([string]::IsNullOrWhiteSpace($value)) {
        continue
      }

      $flutterArgs += "--dart-define=$key=$value"
    }

    Write-Step 'Building Flutter web release'
    & flutter @flutterArgs

    Write-Step 'Syncing web support files to build/web'
    Sync-WebSupportFiles -SourceDir $webRootDir -TargetDir $buildWebDir

    if ($hadVercelLink -and -not (Test-Path $vercelDir)) {
      Write-Step 'Restoring build/web/.vercel link metadata'
      Restore-VercelLink -SourceDir (Join-Path $vercelBackupDir '.vercel') -TargetDir $vercelDir
    }
  }

  if ($SkipDeploy) {
    Write-Step 'Skipping Vercel deploy as requested'
    return
  }

  Require-Command 'npx'

  if (-not (Test-Path $buildWebDir)) {
    throw "build/web was not found. Run the script without -SkipBuild first."
  }

  if (-not (Test-Path $projectJsonPath)) {
    throw "Vercel link metadata was not found at build/web/.vercel/project.json. Run 'cd build/web; npx vercel' once to link this output folder, then rerun the script."
  }

  Write-Step 'Deploying build/web to Vercel production'
  Push-Location $buildWebDir
  try {
    & npx vercel --prod --yes
  } finally {
    Pop-Location
  }
}
finally {
  if (Test-Path $vercelBackupDir) {
    Remove-Item -LiteralPath $vercelBackupDir -Recurse -Force
  }
}
