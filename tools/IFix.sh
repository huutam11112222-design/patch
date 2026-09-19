#!/bin/sh
set -eu

SRC="asset/cache_res"
OUT="cache_res-patch.bytes"

echo "========================================"
echo "              IFix Builder"
echo "========================================"

if [ ! -f "$SRC" ]; then
    echo "[ERROR] Khong tim thay $SRC"
    exit 1
fi

SRC_SIZE=$(wc -c < "$SRC" | tr -d " ")
echo "[IFix] Source: $SRC"
echo "[IFix] Size: $SRC_SIZE bytes"

OLD="bone_Hips"
NEW="bone_Neck"

OLD_COUNT=$(grep -a -o "$OLD" "$SRC" 2>/dev/null | wc -l | tr -d " ")
NEW_COUNT=$(grep -a -o "$NEW" "$SRC" 2>/dev/null | wc -l | tr -d " ")

echo "[IFix] $OLD found: $OLD_COUNT"
echo "[IFix] $NEW found: $NEW_COUNT"

if [ "$OLD_COUNT" -eq 0 ]; then
    echo "[ERROR] Khong tim thay $OLD"
    exit 2
fi

rm -f "$OUT"
echo "[IFix] Creating patch..."
sed "s/$OLD/$NEW/g" "$SRC" > "$OUT"

if [ ! -f "$OUT" ]; then
    echo "[ERROR] Khong tao duoc output"
    exit 3
fi

OUT_SIZE=$(wc -c < "$OUT" | tr -d " ")
echo "[IFix] Output size: $OUT_SIZE bytes"

if [ "$SRC_SIZE" != "$OUT_SIZE" ]; then
    echo "[ERROR] Kich thuoc file thay doi"
    rm -f "$OUT"
    exit 4
fi

echo "========================================"
echo "[SUCCESS] IFix completed"
echo "[SUCCESS] $OLD -> $NEW"
echo "[SUCCESS] Output: $OUT"
echo "[SUCCESS] Size: $OUT_SIZE bytes"
echo "========================================"
