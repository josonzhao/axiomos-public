# AxiomOS Proxy 一键安装脚本 (Windows PowerShell)
# 用法: irm https://raw.githubusercontent.com/josonzhao/axiomos/main/proxy/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Red = "Red"

function Write-Info($msg) { Write-Host "[AxiomOS] $msg" -ForegroundColor $Cyan }
function Write-OK($msg) { Write-Host "✓ $msg" -ForegroundColor $Green }
function Write-Warn($msg) { Write-Host "⚠ $msg" -ForegroundColor $Yellow }
function Write-ErrorMsg($msg) { Write-Host "✗ $msg" -ForegroundColor $Red; exit 1 }

Write-Info "AxiomOS Proxy 安装器"
""

# 解析参数
$SERVER = ""
$TOKEN = ""
for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq "--server" -and $i+1 -lt $args.Count) { $SERVER = $args[$i+1]; $i++ }
    elseif ($args[$i] -eq "--token" -and $i+1 -lt $args.Count) { $TOKEN = $args[$i+1]; $i++ }
}

# 检测平台
$PLATFORM = "win-x64"
Write-Info "检测到平台: $PLATFORM"

# 从 GitHub Releases 下载
$REPO = if ($env:AXIOMOS_REPO) { $env:AXIOMOS_REPO } else { "josonzhao/axiomos" }
$VERSION = if ($env:AXIOMOS_PROXY_VERSION) { $env:AXIOMOS_PROXY_VERSION } else { "latest" }

$BINARY_NAME = "axiomos-proxy-win-x64.exe"

if ($VERSION -eq "latest") {
    $DOWNLOAD_URL = "https://github.com/$REPO/releases/latest/download/$BINARY_NAME"
} else {
    $DOWNLOAD_URL = "https://github.com/$REPO/releases/download/$VERSION/$BINARY_NAME"
}

# 安装目录
$INSTALL_DIR = "$env:LOCALAPPDATA\Programs\AxiomOS"
if (!(Test-Path $INSTALL_DIR)) { New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null }

# 下载
$TMP_FILE = [System.IO.Path]::GetTempFileName() + ".exe"
Write-Info "下载 $BINARY_NAME ..."
Write-Info "  来源: $DOWNLOAD_URL"

try {
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $TMP_FILE -ErrorAction Stop
    Write-OK "下载完成"
} catch {
    Write-ErrorMsg "下载失败: $_"
}

# 安装
Write-Info "安装到 $INSTALL_DIR ..."
Copy-Item $TMP_FILE "$INSTALL_DIR\axiomos-proxy.exe" -Force
Remove-Item $TMP_FILE -Force

# 添加到 PATH
$env:PATH += ";$INSTALL_DIR"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$INSTALL_DIR*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$INSTALL_DIR", "User")
    Write-OK "已添加到 PATH 环境变量（重启终端后生效）"
}

Write-OK "安装成功: $INSTALL_DIR\axiomos-proxy.exe"
""

Write-Info "启动 Proxy:"
if ($SERVER -and $TOKEN) {
    Write-OK "运行以下命令连接云端 Agent:"
    ""
    "  axiomos-proxy start --server $SERVER --token $TOKEN"
    ""
} else {
    Write-Warn "请提供 --server 和 --token 参数来启动代理"
    ""
    "  示例:"
    "    axiomos-proxy start --server ws://your-server:3722 --token YOUR_TOKEN"
    ""
}
