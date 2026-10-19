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

    # The picom config the look selects must ship with it and load in every
    # picom the releases install: Regolith's 11.2.4 build and the
    # distributions' 12.x and 13.x.
    picom=$(sed -n 's/^regolith\.compositor\.picom\.config:[[:space:]]*\([^[:space:]]*\)[[:space:]]*$/\1/p' "$root")
    [ -n "$picom" ] || continue
    conf="${picom#/}"
    if [ ! -f "$conf" ]; then
        echo "FAIL $look: picom config $picom is not in this package" >&2
        status=1
        continue
    fi
    # Options picom 12 or 13 report as deprecated.
    deprecated=$(grep -nE '^[[:space:]]*(xinerama-shadow-crop|glx-no-stencil|glx-no-rebind-pixmap)[[:space:]]*=' "$conf" || true)
    # picom 11 cannot parse a window rule target without its type
    # ("Target type cannot be determined"); picom 12+ only warns about it.
    untyped=$(grep -nE '^[^#]*"[^"]*[A-Za-z0-9_]@([^:]|$)' "$conf" || true)
    if [ -n "$deprecated" ]; then
        echo "FAIL $look: deprecated picom options in $picom:" >&2
        printf '%s\n' "$deprecated" >&2
        status=1
    elif [ -n "$untyped" ]; then
        echo "FAIL $look: picom rule targets without a type in $picom:" >&2
        printf '%s\n' "$untyped" >&2
        status=1
    else
        echo "ok   $look: picom config $picom"
    fi
done

if [ "$count" -eq 0 ]; then
    echo "FAIL no looks found under $LOOK_ROOT" >&2
    exit 1
fi

exit "$status"
