#!/bin/sh

SRC="asset/cache_res"
OUT="cache_res-patch.bytes"

echo "[IFix] Dang kiem tra asset..."

if [ ! -f "$SRC" ]; then
    echo "[IFix] ERROR: Khong tim thay $SRC"
    exit 1
fi

OLD="bone_Hips"
NEW="bone_Neck"

COUNT=$(grep -a -o "$OLD" "$SRC" | wc -l)

echo "[IFix] bone_Hips: $COUNT"
echo "[IFix] bone_Neck: $(grep -a -o "$NEW" "$SRC" | wc -l)"

if [ "$COUNT" -eq 0 ]; then
    echo "[IFix] ERROR: Khong tim thay bone_Hips"
    exit 2
fi

sed "s/$OLD/$NEW/g" "$SRC" > "$OUT"

SIZE_SRC=$(wc -c < "$SRC")
SIZE_OUT=$(wc -c < "$OUT")

if [ "$SIZE_SRC" != "$SIZE_OUT" ]; then
    echo "[IFix] ERROR: Kich thuoc file da thay doi"
    rm -f "$OUT"
    exit 3
fi

echo "[IFix] SUCCESS"
echo "[IFix] bone_Hips -> bone_Neck"
echo "[IFix] Size: $SIZE_OUT bytes"
echo "[IFix] Output: $OUT"
