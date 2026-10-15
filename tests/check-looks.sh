#!/bin/sh
# Static checks over every look shipped by this source package.
# Run from the top of the source tree (debian/rules runs it at build time).
set -eu

LOOK_ROOT=usr/share/regolith-look
status=0
count=0

for dir in "$LOOK_ROOT"/*/; do
    look=$(basename "$dir")
    root="$dir/root"
    count=$((count + 1))

    if [ ! -f "$root" ]; then
        echo "FAIL $look: missing root" >&2
        status=1
        continue
    fi

    # GTK4/libadwaita apps only follow org.gnome.desktop.interface color-scheme,
    # which the look loader sets from gtk.color_scheme.
    scheme=$(sed -n 's/^gtk\.color_scheme:[[:space:]]*\([^[:space:]]*\)[[:space:]]*$/\1/p' "$root")
    case "$scheme" in
        default|prefer-dark|prefer-light) echo "ok   $look: gtk.color_scheme $scheme" ;;
        "") echo "FAIL $look: gtk.color_scheme is not set" >&2; status=1 ;;
        *) echo "FAIL $look: invalid gtk.color_scheme '$scheme'" >&2; status=1 ;;
    esac
done

if [ "$count" -eq 0 ]; then
    echo "FAIL no looks found under $LOOK_ROOT" >&2
    exit 1
fi

exit "$status"
