#!/bin/sh
# Static checks over every look shipped by this source package.
# Run from the top of the source tree (debian/rules runs it at build time).
set -eu

LOOK_ROOT=usr/share/regolith-look
status=0
count=0
# Nerd Fonts 3 dropped the legacy Material Design range (nf-mdi-*,
# U+F500-U+FD46): its code points render as tofu or as another icon.
# This matches their UTF-8 encoding, EF 94 80 to EF B5 86.
LEGACY_MDI=$(printf '\357[\224-\264][\200-\277]|\357\265[\200-\206]')

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

    # A gtklock stylesheet the look selects must ship with it
    gtklock=$(sed -n 's/^gtklock\.stylesheet:[[:space:]]*\([^[:space:]]*\)[[:space:]]*$/\1/p' "$dir"* | tail -n 1)
    if [ -n "$gtklock" ]; then
        if [ -f "${gtklock#/}" ]; then
            echo "ok   $look: gtklock stylesheet $gtklock"
        else
            echo "FAIL $look: gtklock stylesheet $gtklock is not in this package" >&2
            status=1
        fi
    fi

    # Glyphs must use the Nerd Fonts 3 code points (nf-md-* is U+F0001 and up).
    legacy=$(LC_ALL=C grep -rnI -E "$LEGACY_MDI" "$dir" || true)
    if [ -n "$legacy" ]; then
        echo "FAIL $look: legacy Nerd Fonts Material Design code points (U+F500-U+FD46):" >&2
        printf '%s\n' "$legacy" >&2
        status=1
    else
        echo "ok   $look: no legacy Nerd Fonts Material Design code points"
    fi

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
