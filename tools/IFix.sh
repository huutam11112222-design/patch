#!/usr/bin/env bash

set -e

SRC="${2:-asset/cache_res}"
PATCH="${3:-cache_res-patch.bytes}"

OLD="bone_Hips"
NEW="bone_Neck"

build_patch() {
    SRC="$1"
    PATCH="$2"

    if [ ! -f "$SRC" ]; then
        echo "[ERROR] Khong tim thay: $SRC"
        exit 1
    fi

    SIZE=$(wc -c < "$SRC" | tr -d ' ')

    echo "========================================"
    echo "             IFix BUILD"
    echo "========================================"
    echo "[IFix] Asset : $SRC"
    echo "[IFix] Size  : $SIZE bytes"
    echo "[IFix] Find  : $OLD"
    echo "[IFix] To    : $NEW"
    echo ""

    OLD_HEX=$(printf '%s' "$OLD" | od -An -tx1 | tr -d ' \n')
    NEW_HEX=$(printf '%s' "$NEW" | od -An -tx1 | tr -d ' \n')

    if [ "${#OLD_HEX}" != "${#NEW_HEX}" ]; then
        echo "[ERROR] Old/New byte length khac nhau"
        exit 2
    fi

    OFFSETS=$(grep -aob "$OLD" "$SRC" 2>/dev/null | cut -d: -f1 || true)

    if [ -z "$OFFSETS" ]; then
        echo "[ERROR] Khong tim thay $OLD"
        exit 3
    fi

    COUNT=$(printf '%s\n' "$OFFSETS" | wc -l | tr -d ' ')

    rm -f "$PATCH"

    {
        printf 'IFXPATCH1\n'
        printf 'SIZE=%s\n' "$SIZE"
        printf 'COUNT=%s\n' "$COUNT"
        printf 'OLD=%s\n' "$OLD_HEX"
        printf 'NEW=%s\n' "$NEW_HEX"

        printf '%s\n' "$OFFSETS" |
        while IFS= read -r OFFSET
        do
            [ -n "$OFFSET" ] || continue
            printf 'OFFSET=%s\n' "$OFFSET"
        done
    } > "$PATCH"

    echo "[IFix] Found : $COUNT"
    echo "[IFix] Patch : $PATCH"
    echo "[IFix] Size  : $(wc -c < "$PATCH") bytes"
    echo ""
    echo "[IFix] SUCCESS"
}

apply_patch() {
    SRC="$1"
    PATCH="$2"
    OUT="$3"

    if [ ! -f "$SRC" ]; then
        echo "[ERROR] Missing AssetBundle: $SRC"
        exit 1
    fi

    if [ ! -f "$PATCH" ]; then
        echo "[ERROR] Missing patch: $PATCH"
        exit 2
    fi

    MAGIC=$(sed -n '1p' "$PATCH")

    if [ "$MAGIC" != "IFXPATCH1" ]; then
        echo "[ERROR] Patch khong hop le"
        exit 3
    fi

    EXPECTED_SIZE=$(sed -n '2p' "$PATCH" | cut -d= -f2)
    COUNT=$(sed -n '3p' "$PATCH" | cut -d= -f2)
    OLD_HEX=$(sed -n '4p' "$PATCH" | cut -d= -f2)
    NEW_HEX=$(sed -n '5p' "$PATCH" | cut -d= -f2)

    ACTUAL_SIZE=$(wc -c < "$SRC" | tr -d ' ')

    if [ "$EXPECTED_SIZE" != "$ACTUAL_SIZE" ]; then
        echo "[ERROR] Asset size mismatch"
        echo "Patch : $EXPECTED_SIZE"
        echo "Asset : $ACTUAL_SIZE"
        exit 4
    fi

    cp "$SRC" "$OUT"

    echo "========================================"
    echo "             IFix APPLY"
    echo "========================================"
    echo "[IFix] Input : $SRC"
    echo "[IFix] Patch : $PATCH"
    echo "[IFix] Count : $COUNT"
    echo ""

    while IFS= read -r LINE
    do
        case "$LINE" in

            OFFSET=*)
                OFFSET="${LINE#OFFSET=}"

                CURRENT=$(
                    dd \
                        if="$OUT" \
                        bs=1 \
                        skip="$OFFSET" \
                        count=9 \
                        2>/dev/null |
                    od -An -tx1 |
                    tr -d ' \n'
                )

                if [ "$CURRENT" != "$OLD_HEX" ]; then
                    echo "[ERROR] Byte mismatch at offset $OFFSET"
                    rm -f "$OUT"
                    exit 5
                fi

                printf '%s' "$NEW_HEX" |
                xxd -r -p |
                dd \
                    of="$OUT" \
                    bs=1 \
                    seek="$OFFSET" \
                    conv=notrunc \
                    2>/dev/null
                ;;

        esac
    done < <(sed -n '6,$p' "$PATCH")

    echo "[IFix] Output: $OUT"
    echo "[IFix] Size  : $(wc -c < "$OUT") bytes"
    echo "[IFix] SUCCESS"
}

case "${1:-}" in

    build)
        build_patch \
            "${2:-asset/cache_res}" \
            "${3:-cache_res-patch.bytes}"
        ;;

    apply)
        if [ "$#" -lt 4 ]; then
            echo "Usage:"
            echo "  $0 apply ASSET PATCH OUTPUT"
            exit 10
        fi

        apply_patch "$2" "$3" "$4"
        ;;

    *)
        echo "IFix"
        echo ""
        echo "Build patch:"
        echo "  $0 build asset/cache_res cache_res-patch.bytes"
        echo ""
        echo "Apply patch:"
        echo "  $0 apply asset/cache_res cache_res-patch.bytes cache_res-fixed"
        exit 10
        ;;

esac
