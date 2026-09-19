#!/system/bin/sh

SRC="asset/cache_res"
OUT="cache_res-patch.bytes"

if [ ! -f "$SRC" ]; then
    echo "[IFix] ERROR: Khong tim thay $SRC"
    exit 1
fi

echo "[IFix] Dang tao patch..."

# Tìm byte-string bone_Root
OLD="bone_Root"
NEW="bone_Neck"

if ! grep -a -q "$OLD" "$SRC"; then
    echo "[IFix] Khong tim thay bone_Root"
    exit 2
fi

# Thay thế trực tiếp, giữ nguyên kích thước
sed "s/$OLD/$NEW/g" "$SRC" > "$OUT"

echo "[IFix] Da tao: $OUT"
ls -lh "$OUT"
