# tonali

something wicked this way comes

---

macOS desktop notifications when the Spotify track changes — track, artist, album and
album art. Proof of concept: `spotify-notify-poc.sh` polls Spotify's AppleScript
interface every two seconds and fires `terminal-notifier` when the track id changes.
Needs the Spotify desktop app and `brew install terminal-notifier`. Run it with
`./spotify-notify-poc.sh &`. Note that Spotify already does a basic version of this
natively under Settings → Display, so this is only worth running if you want more
than that.
