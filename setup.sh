#!/usr/bin/env bash

# ==========================================================================
# Script: setup.sh
# Mục tiêu: Thiết lập phân quyền bảo mật tối ưu cho thư mục web tĩnh /var/www/ptit-web/
# Phân quyền: Owner là devops (rw-), Group là www-data (r--), Other không có quyền (---)
# Best Practice áp dụng: Sử dụng SetGID để tự động kế thừa group cho file mới tạo.
# ==========================================================================

set -euo pipefail

# Khai báo các hằng số
WEB_DIR="/var/www/ptit-web"
HTML_DIR="${WEB_DIR}/html"
DEV_USER="devops"
WEB_GROUP="www-data"

echo "[+] Bắt đầu cấu hình phân quyền hệ thống..."

# 1. Đảm bảo nhóm www-data tồn tại
if ! getent group "${WEB_GROUP}" > /dev/null 2>&1; then
    echo "[!] Group ${WEB_GROUP} chưa tồn tại, đang tiến hành tạo..."
    groupadd "${WEB_GROUP}"
fi

# 2. Đảm bảo user devops tồn tại
if ! id -u "${DEV_USER}" > /dev/null 2>&1; then
    echo "[!] User ${DEV_USER} chưa tồn tại, đang tiến hành tạo..."
    useradd -m -s /bin/bash "${DEV_USER}"
    # Thêm devops vào group www-data để đồng bộ quyền
    usermod -aG "${WEB_GROUP}" "${DEV_USER}"
fi

# 3. Tạo cấu trúc thư mục giả định nếu chưa tồn tại
if [ ! -d "${HTML_DIR}" ]; then
    echo "[+] Tạo thư mục web tại ${HTML_DIR}..."
    mkdir -p "${HTML_DIR}"
    echo "<h1>Welcome to PTIT Web Static Site</h1>" > "${HTML_DIR}/index.html"
fi

# 4. Thay đổi quyền sở hữu (Owner & Group)
echo "[+] Thiết lập chủ sở hữu là '${DEV_USER}' và nhóm sở hữu là '${WEB_GROUP}'..."
chown -R "${DEV_USER}:${WEB_GROUP}" "${WEB_DIR}"

# 5. Phân quyền chi tiết bảo mật theo tiêu chuẩn Least Privilege
echo "[+] Phân quyền đệ quy cho Thư mục (750) và File (640)..."
# Thư mục: Owner có toàn quyền (rwx), Group chỉ đọc/truy cập (r-x), Others không có quyền (---)
find "${WEB_DIR}" -type d -exec chmod 750 {} +

# File: Owner có quyền đọc/ghi (rw-), Group chỉ đọc (r--), Others không có quyền (---)
find "${WEB_DIR}" -type f -exec chmod 640 {} +

# 6. Thiết lập SetGID (Set Group ID) cho các thư mục
# Việc này đảm bảo các file/thư mục con tạo mới bởi user devops sau này sẽ tự động thuộc sở hữu của group www-data
echo "[+] Kích hoạt thuộc tính SetGID để kế thừa Group ID tự động..."
find "${WEB_DIR}" -type d -exec chmod g+s {} +

echo "[+] Cấu hình hoàn tất! Kiểm tra lại thông tin phân quyền dưới đây:"
ls -la "${WEB_DIR}"
ls -la "${HTML_DIR}"
