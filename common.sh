# ==============================================================================
# DEPENDENCY CHECK
# ==============================================================================
if ! command -v yt-dlp >/dev/null 2>&1; then
	notify-send -u critical "yt-dlp not found" "Install yt-dlp to use this script"
	exit 1
fi
# ==============================================================================
# INPUT VALIDATION
# ==============================================================================
get_clipboard() {
	if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]; then
		if command -v wl-paste >/dev/null 2>&1; then
			wl-paste -n 2>/dev/null
			return
		fi
	fi
	if command -v xclip >/dev/null 2>&1; then
		xclip -selection clipboard -o 2>/dev/null
		return
	fi
	if command -v wl-paste >/dev/null 2>&1; then
		wl-paste -n 2>/dev/null
		return
	fi
	# no clipboard tool available at all
	return 1
}
if [ -n "$2" ]; then
	URL="$2"
else
	if ! command -v xclip >/dev/null 2>&1 && ! command -v wl-paste >/dev/null 2>&1; then
		notify-send -u critical "Clipboard tool missing" "Install xclip (X11) or wl-clipboard (Wayland)"
		exit 1
	fi
	URL="$(get_clipboard)"
	if [ -z "$URL" ]; then
		notify-send -u critical "Clipboard read failed" "Could not read a URL from the clipboard"
		exit 1
	fi
fi
if [[ ! "$URL" =~ ^https?:// ]]; then
	exit 0
fi

# ==============================================================================
# YT-DLP SETUP
# ==============================================================================
# --download-sections "*from-url" handles video cutting via timestamp automatically
YTDLP_OPTS="--quiet --no-warnings --no-playlist --ignore-errors --download-sections *from-url"
# Optional custom parameters:
#   &t=33          -> plain seconds
#   &t=33s         -> seconds with suffix
#   &t=1m30s       -> minutes and seconds
#   &t=1h5m10s     -> hours, minutes and seconds
#   &t=33&e=80     -> download from 33s to 80s
#   &t=33&d=20     -> download 20s starting from 33s
#
# All three components (h/m/s) are optional and can be combined in any order
# that makes sense (h before m before s). A plain number is treated as seconds.
# YouTube ignores e/d; they are interpreted only by this script.
get_url_param() {
	printf '%s' "$URL" | tr '&' '\n' | sed -n "s/^${1}=//p" | head -n1
}
parse_time_to_seconds() {
	local val="$1"
	local h=0
	local m=0
	local s=0
	if [ -z "$val" ]; then
		return
	fi
	if [[ "$val" =~ ^[0-9]+$ ]]; then
		printf '%s' "$val"
		return
	fi
	if [[ "$val" =~ ^([0-9]+h)?([0-9]+m)?([0-9]+s)?$ ]]; then
		[[ "$val" =~ ([0-9]+)h ]] && h="${BASH_REMATCH[1]}"
		[[ "$val" =~ ([0-9]+)m ]] && m="${BASH_REMATCH[1]}"
		[[ "$val" =~ ([0-9]+)s ]] && s="${BASH_REMATCH[1]}"
		printf '%s' "$((h * 3600 + m * 60 + s))"
	fi
}
START="$(parse_time_to_seconds "$(get_url_param "t")")"
END="$(parse_time_to_seconds "$(get_url_param "e")")"
DURATION="$(parse_time_to_seconds "$(get_url_param "d")")"
# Duration has priority over explicit end
if [ -n "$START" ] && [ -n "$DURATION" ]; then
	END=$((START + DURATION))
fi
# Use explicit section only when both start and end are available
if [ -n "$START" ] && [ -n "$END" ]; then
	YTDLP_OPTS="--quiet --no-warnings --no-playlist --ignore-errors --download-sections *${START}-${END}"
fi
