#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# LESSHEADACHE – WordPress + Imunify AutoFix
# Autor: AFIXAR
# Compatível: cPanel / WHM (CentOS / CloudLinux)
# ============================================================

if [ "$(id -u)" -ne 0 ]; then
  echo "ERRO: rode como root."
  exit 1
fi

echo "============================================================"
echo "LESSHEADACHE – Instalação"
echo "Autor: AFIXAR"
echo "============================================================"
echo

# ----------------------------
# Perguntar e confirmar e-mail
# ----------------------------
read -p "Informe o e-mail para notificações: " EMAIL1
read -p "Confirme o e-mail: " EMAIL2

if [ "$EMAIL1" != "$EMAIL2" ] || [ -z "$EMAIL1" ]; then
  echo "ERRO: e-mails não conferem ou estão vazios."
  exit 1
fi

TO_EMAIL="$EMAIL1"
echo "E-mail confirmado: $TO_EMAIL"
echo

# ----------------------------
# Perguntar home base
# ----------------------------
read -p "Pasta base dos usuários cPanel [/home]: " HOME_BASE
HOME_BASE="${HOME_BASE:-/home}"

if [ ! -d "$HOME_BASE" ]; then
  echo "ERRO: Diretório $HOME_BASE não existe."
  exit 1
fi

echo "Pasta base confirmada: $HOME_BASE"
echo

# ----------------------------
# Verificar Imunify
# ----------------------------
if command -v imunify360-agent >/dev/null 2>&1; then
  IMU_BIN="imunify360-agent"
elif command -v imunify-antivirus >/dev/null 2>&1; then
  IMU_BIN="imunify-antivirus"
else
  echo "ERRO: Imunify não encontrado. Abortando instalação."
  exit 1
fi

echo "Imunify detectado: $IMU_BIN"
echo

# ----------------------------
# Instalar scripts
# ----------------------------
INSTALL_DIR="/usr/local/bin"
SBIN_DIR="/usr/local/sbin"
CRON_FILE="/etc/cron.d/lessheadache"

mkdir -p "$INSTALL_DIR" "$SBIN_DIR" /var/log/imunify

cp "$(dirname "$0")/scripts/wp-core-refresh" "$INSTALL_DIR/wp-core-refresh"
cp "$(dirname "$0")/scripts/lessheadache-cron.sh" "$SBIN_DIR/lessheadache-cron.sh"

chmod +x "$INSTALL_DIR/wp-core-refresh" "$SBIN_DIR/lessheadache-cron.sh"

# ----------------------------
# Ajustar variáveis no script
# ----------------------------
sed -i "s|__TO_EMAIL__|$TO_EMAIL|g" "$SBIN_DIR/lessheadache-cron.sh"
sed -i "s|__HOME_BASE__|$HOME_BASE|g" "$SBIN_DIR/lessheadache-cron.sh"

# ----------------------------
# Criar cron a cada 3 horas
# ----------------------------
cat > "$CRON_FILE" <<EOF
0 */3 * * * root $SBIN_DIR/lessheadache-cron.sh
EOF

chmod 644 "$CRON_FILE"

echo
echo "============================================================"
echo "LESSHEADACHE instalado com sucesso."
echo "Cron configurado para rodar a cada 3 horas."
echo "Logs em /var/log/imunify/"
echo "============================================================"
