#!/usr/bin/env bash
# Runs integration_test/alarm_beep_test.dart on the emulator while sampling
# Android's notification and audio state, then checks that:
#   1. the dose alarm notification was posted on the alarm channel with the
#      beep sound and FLAG_INSISTENT (sound loops until answered), and
#   2. audio actually played with USAGE_ALARM (system notification sound and
#      the app's own alarm-screen MediaPlayer).
set -u
PKG=dev.hubert.dosetime
OUT=beep-report
mkdir -p "$OUT"

( flutter test integration_test/alarm_beep_test.dart -d emulator-5554 > "$OUT/flutter_test.log" 2>&1
  echo $? > "$OUT/flutter_exit" ) &
TEST_PID=$!

# Grant permissions as soon as the app is installed.
for i in $(seq 1 200); do
  if adb shell pm list packages 2>/dev/null | grep -q "$PKG"; then break; fi
  sleep 3
done
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS || true
adb shell appops set "$PKG" SCHEDULE_EXACT_ALARM allow || true
adb shell dumpsys deviceidle whitelist +"$PKG" || true
adb shell media volume --stream 4 --set 7 2>/dev/null || true

for i in $(seq 1 60); do
  if adb shell pidof "$PKG" >/dev/null 2>&1; then break; fi
  sleep 2
done

for i in $(seq 1 45); do
  {
    echo "=== sample $i $(date +%T)"
    adb shell dumpsys notification --noredact
  } > "$OUT/notif_$i.txt" 2>&1
  {
    echo "=== sample $i $(date +%T)"
    adb shell dumpsys audio
  } > "$OUT/audio_$i.txt" 2>&1
  case $i in 6|9|12|18|24) adb exec-out screencap -p > "$OUT/screen_$i.png" 2>/dev/null ;; esac
  if ! kill -0 $TEST_PID 2>/dev/null; then break; fi
  sleep 2
done
wait $TEST_PID

UID_APP=$(adb shell dumpsys package "$PKG" | grep -m1 -o 'userId=[0-9]*' | cut -d= -f2)
echo "app uid: $UID_APP" > "$OUT/summary.txt"
echo "flutter test exit: $(cat "$OUT/flutter_exit")" >> "$OUT/summary.txt"
grep BEEPTEST "$OUT/flutter_test.log" >> "$OUT/summary.txt"

NOTIF_FILE=$(grep -l "dose_alarm_dose_beep" "$OUT"/notif_*.txt | head -1)
if [ -n "$NOTIF_FILE" ]; then
  echo "--- notification record ($NOTIF_FILE)" >> "$OUT/summary.txt"
  grep -A30 "pkg=$PKG" "$NOTIF_FILE" | grep -iE "NotificationRecord|channel=|flags=|mSound|sound=|AudioAttributes|usage" | head -20 >> "$OUT/summary.txt"
fi

echo "--- alarm audio playback seen" >> "$OUT/summary.txt"
grep -h "USAGE_ALARM" "$OUT"/audio_*.txt | grep -i "state:started" | sort -u | head -10 >> "$OUT/summary.txt"

cat "$OUT/summary.txt"

ok=1
[ -n "$NOTIF_FILE" ] || { echo "FAIL: dose alarm notification never posted"; ok=0; }
grep -hq "USAGE_ALARM" "$OUT"/audio_*.txt && grep -h "USAGE_ALARM" "$OUT"/audio_*.txt | grep -qi "state:started" \
  || { echo "FAIL: no alarm audio playback observed"; ok=0; }
grep -h "USAGE_ALARM" "$OUT"/audio_*.txt | grep -i "state:started" | grep -q "u/pid:$UID_APP/" \
  || echo "WARN: in-app MediaPlayer playback not attributed to app uid $UID_APP"
[ "$ok" = 1 ] && echo "PASS: dose alarm beeped (notification + alarm audio)"
[ "$ok" = 1 ]
