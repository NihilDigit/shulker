# mc-tui installer for Windows.
#
# What it does:
#   1. Detects PROCESSOR_ARCHITECTURE → release-asset triple.
#   2. Asks GitHub for the latest tag.
#   3. Downloads the matching .zip, extracts it, drops `mc-tui.exe` into
#      $env:MC_TUI_INSTALL_DIR (default: $env:LOCALAPPDATA\mc-tui).
#   4. Tells you to add the dir to PATH if it isn't already there.
#
# Usage (PowerShell):
#   irm https://raw.githubusercontent.com/NihilDigit/mc-tui/main/scripts/install.ps1 | iex
#
# To pin a version:
#   $env:MC_TUI_VERSION = "v0.7.0"; irm ... | iex

$ErrorActionPreference = "Stop"

$Repo = "NihilDigit/mc-tui"
$InstallDir = if ($env:MC_TUI_INSTALL_DIR) { $env:MC_TUI_INSTALL_DIR } else { "$env:LOCALAPPDATA\mc-tui" }

# 1. Detect arch
$triple = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "x86_64-pc-windows-msvc" }
    "ARM64" { "aarch64-pc-windows-msvc" }
    default {
        Write-Host "✗ unsupported arch: $env:PROCESSOR_ARCHITECTURE" -ForegroundColor Red
        Write-Host "  Supported: AMD64 (x86_64) and ARM64."
        exit 1
    }
}

# 2. Latest tag via GitHub API (or pinned version)
Write-Host "→ resolving latest mc-tui release for $triple..."
if ($env:MC_TUI_VERSION) {
    $tag = $env:MC_TUI_VERSION
} else {
    try {
        # User-Agent is required by GH API.
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "mc-tui-install" }
        $tag = $rel.tag_name
    } catch {
        Write-Host "✗ failed to resolve latest tag: $_" -ForegroundColor Red
        Write-Host "  Set `$env:MC_TUI_VERSION = 'vX.Y.Z'` to override."
        exit 1
    }
}
Write-Host "→ tag: $tag"

# 3. Download + extract
$asset = "mc-tui-$tag-$triple.zip"
$url = "https://github.com/$Repo/releases/download/$tag/$asset"
$tmp = Join-Path $env:TEMP "mc-tui-install-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    Write-Host "→ downloading $url"
    Invoke-WebRequest -Uri $url -OutFile (Join-Path $tmp $asset) -UseBasicParsing
    Expand-Archive -Path (Join-Path $tmp $asset) -DestinationPath $tmp

    $extracted = Join-Path $tmp "mc-tui-$tag-$triple"
    if (-not (Test-Path (Join-Path $extracted "mc-tui.exe"))) {
        Write-Host "✗ archive is missing mc-tui.exe at $extracted" -ForegroundColor Red
        exit 1
    }

    # 4. Install
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir | Out-Null
    }
    Copy-Item -Path (Join-Path $extracted "mc-tui.exe") -Destination $InstallDir -Force
    Write-Host "✓ installed: $InstallDir\mc-tui.exe"
} finally {
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. PATH check
$paths = $env:PATH -split ";"
if ($paths -notcontains $InstallDir) {
    Write-Host ""
    Write-Host "⚠ $InstallDir is not in your PATH."
    Write-Host "  Add it for this user (one-time):"
    Write-Host "    [Environment]::SetEnvironmentVariable('PATH', '$InstallDir;' + [Environment]::GetEnvironmentVariable('PATH', 'User'), 'User')"
    Write-Host "  Then restart your shell."
}

Write-Host ""
Write-Host "Run:"
Write-Host "  mc-tui --server-dir 'C:\path\to\your\server'"
Write-Host "  mc-tui new 'C:\path\to\fresh\server-dir'   # scaffold a new Paper/Purpur server"
