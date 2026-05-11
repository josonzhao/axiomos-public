#!/usr/bin/env bash
# AxiomOS Proxy 一键安装脚本
# 用法: curl -sSL https://raw.githubusercontent.com/josonzhao/axiomos-public/main/install.sh | bash -s -- --server ws://xxx --token yyy
# 注意: 需要先构建并上传二进制到公开位置，或修改下面的 BASE_URL

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[AxiomOS]${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

info "AxiomOS Proxy 安装器"
echo ""

# 解析参数
EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --server)  SERVER="$2";  shift 2 ;;
    --token)   TOKEN="$2";   shift 2 ;;
    --url)     BASE_URL="$2"; shift 2 ;;
    *)         EXTRA_ARGS+=("$1"); shift ;;
  esac
done

# 检测平台
detect_platform() {
  local OS ARCH
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"

  case "$OS" in
    darwin) OS="mac" ;;
    linux)   OS="linux" ;;
    msys*|cygwin*|mingw*) OS="win" ;;
    *) error "不支持的操作系统: $OS" ;;
  esac

  case "$ARCH" in
    arm64|aarch64) ARCH="arm64" ;;
    x86_64|amd64) ARCH="x64" ;;
    *) error "不支持的架构: $ARCH" ;;
  esac

  echo "${OS}-${ARCH}"
}

PLATFORM="$(detect_platform)"
info "检测到平台: $PLATFORM"

BINARY_NAME="axiomos-proxy-${PLATFORM}"
[ "$PLATFORM" = "win-x64" ] && BINARY_NAME="${BINARY_NAME}.exe"

# 二进制下载地址 — 请修改为你的实际公开地址
# 选项1: 使用 GitHub Releases (需要单独公开 repo)
# 选项2: 使用对象存储 (AWS S3 / 阿里云 OSS / 腾讯云 COS)
# 选项3: 使用 Vercel/Netlify 等静态托管
BASE_URL="${BASE_URL:-https://axiomos.s3.amazonaws.com}"
DOWNLOAD_URL="${BASE_URL}/${BINARY_NAME}"

info "下载 ${BINARY_NAME} ..."
info "  来源: ${DOWNLOAD_URL}"

TMP_FILE="$(mktemp /tmp/axiomos-proxy.XXXXXX)"
if command -v curl &>/dev/null; then
  curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE" || error "下载失败，请检查网络连接或联系管理员"
elif command -v wget &>/dev/null; then
  wget -q "$DOWNLOAD_URL" -O "$TMP_FILE" || error "下载失败，请检查网络连接或联系管理员"
else
  error "需要 curl 或 wget 来下载文件"
fi
ok "下载完成"

# 安装
INSTALL_DIR="/usr/local/bin"
if [ "$PLATFORM" = "win-x64" ]; then
  INSTALL_DIR="$HOME/AppData/Local/Programs/AxiomOS"
fi

info "安装到 ${INSTALL_DIR} ..."

if [ "$PLATFORM" = "win-x64" ]; then
  mkdir -p "$INSTALL_DIR"
  mv "$TMP_FILE" "${INSTALL_DIR}/axiomos-proxy.exe"
else
  chmod +x "$TMP_FILE"
  if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP_FILE" "${INSTALL_DIR}/axiomos-proxy"
  else
    sudo mv "$TMP_FILE" "${INSTALL_DIR}/axiomos-proxy"
  fi
fi

ok "安装成功: ${INSTALL_DIR}/axiomos-proxy"

if command -v axiomos-proxy &>/dev/null; then
  ok "AxiomOS Proxy 已安装并可执行"
else
  warn "请手动将 ${INSTALL_DIR} 添加到 PATH 环境变量"
fi

echo ""
info "启动 Proxy:"
if [ -n "$SERVER" ] && [ -n "$TOKEN" ]; then
  ok "运行以下命令连接云端 Agent:"
  echo ""
  echo "  axiomos-proxy start --server ${SERVER} --token ${TOKEN} ${EXTRA_ARGS[*]}"
  echo ""
else
  warn "请提供 --server 和 --token 参数来启动代理"
  echo ""
  echo "  示例:"
  echo "    axiomos-proxy start --server ws://your-server:3722 --token YOUR_TOKEN"
  echo ""
fi
