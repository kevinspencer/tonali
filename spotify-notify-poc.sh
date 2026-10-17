#!/bin/bash
#
#	spotify-notify.sh — macOS notification when the Spotify track changes.
#
#	Polls Spotify's AppleScript interface and posts a notification (with album
#	art) whenever the track id changes. Notifications appear top-right, which is
#	wherever macOS puts them — that position is not script-controllable.
#
#	Usage:  ./spotify-notify.sh            run in the foreground
#	        ./spotify-notify.sh &          background
#	        see the launchd plist below for run-at-login
#
#	Requires: terminal-notifier  (brew install terminal-notifier)

set -u

POLL_SECONDS=2
ART_DIR="${TMPDIR:-/tmp}/spotify-notify"
GROUP_ID="spotify-now-playing"        # reuses one notification slot instead of stacking

mkdir -p "$ART_DIR"

last_id=""

#	NOTE: `tell application "Spotify"` will LAUNCH Spotify if it is not running,
#	which is not what you want from a background poller. Guard with pgrep first.
spotify_running() { pgrep -x Spotify >/dev/null 2>&1; }

get_track() {
	osascript <<-'APPLESCRIPT' 2>/dev/null
		tell application "Spotify"
			set pState to player state as text
			if pState is "playing" then
				return (id of current track) & "\t" & ¬
				       (name of current track) & "\t" & ¬
				       (artist of current track) & "\t" & ¬
				       (album of current track) & "\t" & ¬
				       (artwork url of current track)
			else
				return ""
			end if
		end tell
	APPLESCRIPT
}

while true; do

	if ! spotify_running; then
		last_id=""           # so the next play re-notifies
		sleep "$POLL_SECONDS"
		continue
	fi

	line=$(get_track)

	if [ -z "$line" ]; then          # paused or stopped
		sleep "$POLL_SECONDS"
		continue
	fi

	IFS=$'\t' read -r tid title artist album art <<< "$line"

	if [ -n "$tid" ] && [ "$tid" != "$last_id" ]; then

		last_id="$tid"

		#	album art: cache per track id so a repeat play does not re-download
		art_file=""
		if [ -n "$art" ]; then
			art_file="$ART_DIR/${tid##*:}.jpg"
			[ -s "$art_file" ] || curl -fsS --max-time 5 -o "$art_file" "$art" || art_file=""
		fi

		#	NOTE: do NOT add `-sender com.spotify.client`. It makes terminal-notifier
		#	2.0.0 hang indefinitely instead of returning, which stalls this loop.
		#	Tested: -group and -contentImage are fine, -sender is not.
		#	`-activate` gives the click-to-open-Spotify behaviour without hanging.
		if [ -n "$art_file" ] && [ -s "$art_file" ]; then
			terminal-notifier -title "$title" -subtitle "$artist" -message "$album" \
				-contentImage "$art_file" -group "$GROUP_ID" -activate com.spotify.client
		else
			terminal-notifier -title "$title" -subtitle "$artist" -message "$album" \
				-group "$GROUP_ID" -activate com.spotify.client
		fi

	fi

	sleep "$POLL_SECONDS"

done
