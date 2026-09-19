#!/usr/bin/env bash
set -euo pipefail

SRC="${2:-asset/cache_res}"
PATCH="${3:-cache_res-patch.bytes}"
OLD="${OLD_NAME:-bone_Hips}"
NEW="${NEW_NAME:-bone_Neck}"

case "${1:-}" in
build)
    test -f "$SRC"

    old_hex=$(printf '%s' "$OLD" | xxd -p -c 999999)
    new_hex=$(printf '%s' "$NEW" | xxd -p -c 999999)

    [ "${#old_hex}" = "${#new_hex}" ] || {
        echo "[ERROR] OLD/NEW khac kich thuoc"
        exit 1
    }

    size=$(wc -c < "$SRC" | tr -d ' ')
    sha=$(sha256sum "$SRC" | awk '{print $1}')

    grep -aobF "$OLD" "$SRC" 2>/dev/null |
        cut -d: -f1 > /tmp/ifix_offsets || true

    test -s /tmp/ifix_offsets || {
        echo "[ERROR] Khong tim thay $OLD"
        exit 2
    }

    : > /tmp/ifix_payload

    while read -r off; do
        printf '%08x' "$off" | xxd -r -p >> /tmp/ifix_payload
        printf '%08x' "$((${#old_hex}/2))" | xxd -r -p >> /tmp/ifix_payload
        printf '%08x' "$((${#new_hex}/2))" | xxd -r -p >> /tmp/ifix_payload
        printf '%s' "$old_hex" | xxd -r -p >> /tmp/ifix_payload
        printf '%s' "$new_hex" | xxd -r -p >> /tmp/ifix_payload
    done < /tmp/ifix_offsets

    gzip -n -9 -c /tmp/ifix_payload > /tmp/ifix_payload.gz

    : > "$PATCH"

    printf 'IFXB' >> "$PATCH"
    printf '\001\000' >> "$PATCH"
    printf '\001\000' >> "$PATCH"

    printf '%s' "$size" |
        awk '{printf "%016x",$1}' |
        xxd -r -p >> "$PATCH"

    count=$(wc -l < /tmp/ifix_offsets | tr -d ' ')
    printf '%s' "$count" |
        awk '{printf "%08x",$1}' |
        xxd -r -p >> "$PATCH"

    cat /tmp/ifix_payload.gz >> "$PATCH"

    echo "[IFix] Binary patch created:"
    ls -lh "$PATCH"
    xxd -l 32 "$PATCH"
    ;;

*)
    echo "Usage:"
    echo "$0 build [asset] [patch]"
    exit 1
    ;;
esac
