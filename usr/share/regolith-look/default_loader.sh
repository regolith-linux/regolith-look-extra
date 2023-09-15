#! /bin/bash

# This script updates the desktop UI configuration based on Xresources
set -eE -u -o pipefail

RESOURCE_GETTER="xrescat"
if [[ $XDG_SESSION_TYPE == "wayland" ]]; then
    RESOURCE_GETTER="trawlcat"
fi

load_look() {
    # Set GNOME interface options from Xresources values if specifed by Xresources
    GTK_THEME=$($RESOURCE_GETTER gtk.theme_name || :)
    if [[ -n ${GTK_THEME:-} ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME}"
    fi

    ICON_THEME=$($RESOURCE_GETTER gtk.icon_theme_name || :)
    if [[ -n ${ICON_THEME:-} ]]; then
        gsettings set org.gnome.desktop.interface icon-theme "${ICON_THEME}"
    fi

    WM_FONT=$($RESOURCE_GETTER gtk.font_name || :)
    if [[ -n ${WM_FONT:-} ]]; then
        gsettings set org.gnome.desktop.interface font-name "${WM_FONT}"
    fi

    DOC_FONT=$($RESOURCE_GETTER gtk.document_font_name || :)
    if [[ -n ${DOC_FONT:-} ]]; then
        gsettings set org.gnome.desktop.interface document-font-name "${DOC_FONT}"
    fi

    MONO_FONT=$($RESOURCE_GETTER gtk.monospace_font_name || :)
    if [[ -n ${MONO_FONT:-} ]]; then
        gsettings set org.gnome.desktop.interface monospace-font-name "${MONO_FONT}"
    fi
    
    # Set the wallpaper
    WALLPAPER_FILE=$($RESOURCE_GETTER regolith.wallpaper.file || :)
    WALLPAPER_FILE_RESOLVED=$(realpath -e "${WALLPAPER_FILE/#~/${HOME}}" 2>/dev/null || :)
    WALLPAPER_FILE_OPTIONS=$($RESOURCE_GETTER regolith.wallpaper.options || :)
    WALLPAPER_PRIMARY_COLOR=$($RESOURCE_GETTER regolith.wallpaper.color.primary || :)

    if [[ -f ${WALLPAPER_FILE_RESOLVED:-} ]]; then
        gsettings set org.gnome.desktop.background picture-uri "file://${WALLPAPER_FILE_RESOLVED}"
        gsettings set org.gnome.desktop.background picture-options "${WALLPAPER_FILE_OPTIONS:-wallpaper}"
    elif [[ -n ${WALLPAPER_FILE:-} ]]; then
        printf 'Path to wallpaper file ('%s') is invalid"' "${WALLPAPER_FILE}" >&2
    elif [[ -n ${WALLPAPER_PRIMARY_COLOR:-} ]]; then
        gsettings set org.gnome.desktop.background picture-options none
        gsettings set org.gnome.desktop.background picture-uri none        
        gsettings set org.gnome.desktop.background primary-color "${WALLPAPER_PRIMARY_COLOR}"

        WALLPAPER_SECONDARY_COLOR=$($RESOURCE_GETTER regolith.wallpaper.color.secondary || :)
        WALLPAPER_COLOR_SHADE_TYPE=$($RESOURCE_GETTER regolith.wallpaper.color.shading.type || :)

        if [[ -n ${WALLPAPER_SECONDARY_COLOR:-} ]] && [[ -n ${WALLPAPER_COLOR_SHADE_TYPE} ]]; then
            gsettings set org.gnome.desktop.background secondary-color "${WALLPAPER_SECONDARY_COLOR}"
            gsettings set org.gnome.desktop.background color-shading-type "${WALLPAPER_COLOR_SHADE_TYPE}"
        else
            gsettings set org.gnome.desktop.background color-shading-type 'solid'
        fi
    fi

    # Set the lockscreen (screensaver) wallpaper
    LOCKSCREEN_WALLPAPER_FILE=$($RESOURCE_GETTER regolith.lockscreen.wallpaper.file || :)
    LOCKSCREEN_WALLPAPER_FILE_RESOLVED=$(realpath -e "${LOCKSCREEN_WALLPAPER_FILE/#~/${HOME}}" 2>/dev/null || :)
    LOCKSCREEN_WALLPAPER_FILE_OPTIONS=$($RESOURCE_GETTER regolith.lockscreen.wallpaper.options || :)
    LOCKSCREEN_WALLPAPER_PRIMARY_COLOR=$($RESOURCE_GETTER regolith.lockscreen.wallpaper.color.primary || :)

    if [[ -f ${LOCKSCREEN_WALLPAPER_FILE_RESOLVED:-} ]]; then
        gsettings set org.gnome.desktop.screensaver picture-uri "file://${LOCKSCREEN_WALLPAPER_FILE_RESOLVED}"
        gsettings set org.gnome.desktop.screensaver picture-options "${LOCKSCREEN_WALLPAPER_FILE_OPTIONS:-wallpaper}"
    elif [[ -n ${LOCKSCREEN_WALLPAPER_FILE:-} ]]; then
        printf 'Path to lockscreen wallpaper file ('%s') is invalid"' "${WALLPAPER_FILE}" >&2
    elif [[ -n ${LOCKSCREEN_WALLPAPER_PRIMARY_COLOR:-} ]]; then
        gsettings set org.gnome.desktop.screensaver picture-options none
        gsettings set org.gnome.desktop.screensaver picture-uri none        
        gsettings set org.gnome.desktop.screensaver primary-color "${LOCKSCREEN_WALLPAPER_PRIMARY_COLOR}"

        LOCKSCREEN_WALLPAPER_SECONDARY_COLOR=$($RESOURCE_GETTER regolith.lockscreen.wallpaper.color.secondary || :)
        LOCKSCREEN_WALLPAPER_COLOR_SHADE_TYPE=$($RESOURCE_GETTER regolith.lockscreen.wallpaper.color.shading.type || :)

        if [[ -n ${LOCKSCREEN_WALLPAPER_SECONDARY_COLOR:-} ]] && [[ -n ${LOCKSCREEN_WALLPAPER_COLOR_SHADE_TYPE} ]]; then
            gsettings set org.gnome.desktop.screensaver secondary-color "${LOCKSCREEN_WALLPAPER_SECONDARY_COLOR}"
            gsettings set org.gnome.desktop.screensaver color-shading-type "${LOCKSCREEN_WALLPAPER_COLOR_SHADE_TYPE}"
        else
            gsettings set org.gnome.desktop.screensaver color-shading-type 'solid'
        fi
    fi

    # Configure the gnome-terminal profile
    if command -v gnome-terminal &>/dev/null; then # check if gnome-terminal is in ${PATH}
        UPDATE_TERM_FLAG=$($RESOURCE_GETTER gnome.terminal.update true || :) # if unspecified, default to true
        if [[ "${UPDATE_TERM_FLAG:-}" == 'true' ]] && \
           [[ -f '/usr/share/regolith-ftue/regolith-init-term-profile' ]] ; then
            /usr/share/regolith-ftue/regolith-init-term-profile
        fi
    fi
}
