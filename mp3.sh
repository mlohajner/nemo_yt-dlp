#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
TARGET_DIR="${1:-/tmp/nemo_yt-dlp}"

# ==============================================================================
# COMMON PREPARATIONS
# ==============================================================================
. "<absolute_path_to>/common.sh"

# ==============================================================================
# DOWNLOAD AUDIO AND TRANSCODE
# ==============================================================================
# Generates unique file format: yt-dlp-<id>.wav
LOG_DIR="/tmp"
LOG_FILE="${LOG_DIR}/yt-dlp-$$.log"
yt-dlp $YTDLP_OPTS -x --audio-format mp3 --audio-quality 0 -o "$TARGET_DIR/yt-dlp-%(id)s.%(ext)s" "$URL" >"$LOG_FILE" 2>&1 &
PID_AUDIO=$!
# ==============================================================================
# WAIT FOR COMPLETION
# ==============================================================================
wait $PID_AUDIO
STATUS=$?
if [ $STATUS -ne 0 ]; then
	ERR_LINE="$(grep -m1 -E '^(ERROR|WARNING):' "$LOG_FILE")"
	notify-send -u critical "yt-dlp: download failed" "${ERR_LINE:-Unknown error (code $STATUS)}"
	rm -f "$LOG_FILE"
	exit $STATUS
fi
rm -f "$LOG_FILE"
nemo --self "$TARGET_DIR"
exit 0
