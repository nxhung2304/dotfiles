#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
home_dir="$work_dir/home"
mkdir -p "$work_dir/bin" "$home_dir"
export STUB_LOG_DIR="$work_dir"

cat >"$work_dir/bin/xcrun" <<'EOF'
#!/usr/bin/env bash
if [[ $* == "simctl list runtimes -j" ]]; then
    echo '{"runtimes":[
        {"name":"iOS 18.0","identifier":"com.apple.CoreSimulator.SimRuntime.iOS-18-0","platform":"iOS","isAvailable":true,
         "supportedDeviceTypes":[
            {"name":"iPhone 16","identifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-16"},
            {"name":"iPad Air","identifier":"com.apple.CoreSimulator.SimDeviceType.iPad-Air"}]},
        {"name":"iOS 16.0","identifier":"com.apple.CoreSimulator.SimRuntime.iOS-16-0","platform":"iOS","isAvailable":false,
         "supportedDeviceTypes":[]},
        {"name":"watchOS 11.0","identifier":"com.apple.CoreSimulator.SimRuntime.watchOS-11-0","platform":"watchOS","isAvailable":true,
         "supportedDeviceTypes":[{"name":"Watch","identifier":"com.apple.CoreSimulator.SimDeviceType.Watch"}]}]}'
elif [[ $1 == "simctl" && $2 == "create" ]]; then
    echo "$*" >>"$STUB_LOG_DIR/xcrun_calls"
    echo "NEW-UDID"
elif [[ $* == "simctl list devices available -j" || $* == "simctl list devices -j" ]]; then
    unavailable_count=$(cat "$STUB_LOG_DIR/unavailable_count" 2>/dev/null || echo 0)
    jq -n --argjson unavailable_count "$unavailable_count" '{devices:{
        "com.apple.CoreSimulator.SimRuntime.iOS-18-0":[
            {udid:"UDID-1",name:"iPhone 16",state:"Shutdown",isAvailable:true,
             deviceTypeIdentifier:"com.apple.CoreSimulator.SimDeviceType.iPhone-16",dataPathSize:5242880,dataPath:"/data/UDID-1"},
            {udid:"UDID-2",name:"iPhone 16 Pro",state:"Booted",isAvailable:true,
             deviceTypeIdentifier:"com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",dataPathSize:0,dataPath:"/data/UDID-2"}],
        "com.apple.CoreSimulator.SimRuntime.watchOS-11-0":[
            {udid:"WATCH-1",name:"Watch",state:"Shutdown",isAvailable:true}],
        "com.apple.CoreSimulator.SimRuntime.iOS-16-0":
            [range($unavailable_count) | {udid:"BROKEN-\(.)",name:"Broken",state:"Shutdown",isAvailable:false}]}}'
elif [[ $* == "simctl delete unavailable" ]]; then
    echo "$*" >>"$STUB_LOG_DIR/xcrun_calls"
    echo 0 >"$STUB_LOG_DIR/unavailable_count"
else
    echo "$*" >>"$STUB_LOG_DIR/xcrun_calls"
fi
EOF
cat >"$work_dir/bin/open" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$STUB_LOG_DIR/open_calls"
EOF
cat >"$work_dir/bin/avdmanager" <<'EOF'
#!/usr/bin/env bash
if [[ $* == "list avd" ]]; then
    printf 'Available Android Virtual Devices:\n    Name: Pixel_8\n  Device: pixel_8 (Google)\n---------\n    Name: Pixel_Tablet\n  Device: pixel_tablet (Google)\n'
else
    echo "$*" >>"$STUB_LOG_DIR/avdmanager_calls"
fi
EOF
cat >"$work_dir/bin/sleep" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$STUB_LOG_DIR/sleep_calls"
EOF
cat >"$work_dir/bin/emulator" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == "-list-avds" ]]; then
    printf 'Pixel_8\nPixel_Tablet\n'
else
    echo "$*" >>"$STUB_LOG_DIR/emulator_calls"
fi
EOF
cat >"$work_dir/bin/adb" <<'EOF'
#!/usr/bin/env bash
case "$*" in
    "devices") printf 'List of devices attached\nemulator-5554\tdevice\n\n' ;;
    "-s emulator-5554 emu avd name") printf 'Pixel_8\r\nOK\r\n' ;;
esac
EOF
cat >"$work_dir/bin/fzf" <<'EOF'
#!/usr/bin/env bash
pick_number=$(($(cat "$STUB_LOG_DIR/pick_count" 2>/dev/null || echo 0) + 1))
echo "$pick_number" >"$STUB_LOG_DIR/pick_count"
cat >"$STUB_LOG_DIR/candidates.$pick_number"
echo "$*" >"$STUB_LOG_DIR/fzf_args.$pick_number"
pattern=$(sed -n 1p "$STUB_LOG_DIR/picked")
tail -n +2 "$STUB_LOG_DIR/picked" >"$STUB_LOG_DIR/picked.next"
mv "$STUB_LOG_DIR/picked.next" "$STUB_LOG_DIR/picked"
[[ -n $pattern ]] || exit 130
IFS='|' read -ra patterns <<<"$pattern"
for single_pattern in "${patterns[@]}"; do
    grep -F -m1 -- "$single_pattern" "$STUB_LOG_DIR/candidates.$pick_number"
done
EOF
chmod +x "$work_dir"/bin/*

run_menu() {
    local action=$1
    shift
    rm -f "$work_dir"/{xcrun_calls,open_calls,emulator_calls,avdmanager_calls,sleep_calls,pick_count} "$work_dir"/candidates.* "$work_dir"/fzf_args.*
    printf '%s\n' "$@" >"$work_dir/picked"
    printf '%s\n' "${typed_text:-}" | PATH="$work_dir/bin:$PATH" HOME="$home_dir" bash "$repo_dir/scripts/herdr/sim-menu" "$action" >"$work_dir/output" 2>&1
}

recorded() {
    local file=$work_dir/$1
    local attempt
    for attempt in 1 2 3 4 5 6 7 8 9 10; do
        [[ -s $file ]] && break
        sleep 0.1
    done
    cat "$file" 2>/dev/null || echo "nothing"
}

candidate_labels() {
    cut -f1 "$work_dir/candidates.$1" | sed "s/$(printf '\033')\[[0-9;]*m//g" | paste -sd, - | sed 's/  */ /g'
}

candidate_ids() {
    cut -f3 "$work_dir/candidates.1" | paste -sd, -
}

candidate_kinds() {
    cut -f2 "$work_dir/candidates.1" | paste -sd, -
}

check "action list" "Boot device,Create iOS simulator,Delete device,Delete unavailable simulators" \
    "$(bash "$repo_dir/scripts/herdr/sim-menu" --list | paste -sd, -)"

run_menu "Boot device" "UDID-1"
check "boot lists running devices first, then stopped ones, no watchOS" "UDID-2,Pixel_8,UDID-1,Pixel_Tablet" \
    "$(candidate_ids)"
check "boot puts the state first as a group column" \
    "Booted iOS 18.0 iPhone 16 Pro,Booted Android Pixel_8,Shutdown iOS 18.0 iPhone 16,Shutdown Android Pixel_Tablet" \
    "$(candidate_labels 1)"
check "boot colors the state" "1" "$(grep -c -- '--ansi' "$work_dir/fzf_args.1")"
check "boot shows a preview of the highlighted device" "1" \
    "$(grep -c -- "--preview '$repo_dir/scripts/herdr/sim-menu' --preview {2} {3}" "$work_dir/fzf_args.1")"
check "boot iOS starts the chosen simulator" "simctl boot UDID-1" "$(recorded xcrun_calls)"
check "boot iOS opens Simulator on that device" "-a Simulator --args -CurrentDeviceUDID UDID-1" \
    "$(recorded open_calls)"

check "boot iOS announces the device before closing" "Booting iPhone 16..." \
    "$(grep -a 'Booting' "$work_dir/output")"
check "boot iOS keeps the notice on screen" "1" "$(recorded sleep_calls)"

run_menu "Boot device" "UDID-2"
check "already booted iOS simulator is not booted again" "nothing" "$(recorded xcrun_calls)"
check "already booted iOS simulator is brought to front" "-a Simulator --args -CurrentDeviceUDID UDID-2" \
    "$(recorded open_calls)"

run_menu "Boot device" "Pixel_Tablet"
check "boot Android starts the chosen AVD" "-avd Pixel_Tablet" "$(recorded emulator_calls)"
check "boot Android announces the device before closing" "Booting Pixel_Tablet... (log: $home_dir/.local/state/herdr-sim/Pixel_Tablet.log)" \
    "$(grep -a 'Booting' "$work_dir/output")"
check "boot Android keeps the notice on screen" "1" "$(recorded sleep_calls)"

run_menu "Boot device" ""
check "cancelled picker boots nothing" "nothing" "$(recorded emulator_calls)"

run_menu "Create iOS simulator" "iOS 18.0" "iPad Air" "Close"
check "create offers only available iOS runtimes" "iOS 18.0" "$(candidate_labels 1)"
check "create offers only device types of the runtime" "iPhone 16,iPad Air" "$(candidate_labels 2)"
check "create defaults the name to the device type" \
    "simctl create iPad Air com.apple.CoreSimulator.SimDeviceType.iPad-Air com.apple.CoreSimulator.SimRuntime.iOS-18-0" \
    "$(recorded xcrun_calls)"
check "create offers boot or close with the result as header" "Boot it now,Close" "$(candidate_labels 3)"
check "create shows the created device" "1" "$(grep -c 'Created iPad Air (NEW-UDID)' "$work_dir/fzf_args.3")"
check "close after create does not boot" "nothing" "$(recorded open_calls)"

run_menu "Create iOS simulator" "iOS 18.0" "iPhone 16" "Boot it now"
check "boot after create starts the new device" \
    "simctl create iPhone 16 com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-18-0
simctl boot NEW-UDID" "$(recorded xcrun_calls)"
check "boot after create announces the new device" "Booting iPhone 16..." "$(grep -a 'Booting' "$work_dir/output")"
check "boot after create opens Simulator on the new device" \
    "-a Simulator --args -CurrentDeviceUDID NEW-UDID" "$(recorded open_calls)"

typed_text="My Phone"
run_menu "Create iOS simulator" "iOS 18.0" "iPhone 16"
typed_text=""
check "create uses the typed name" \
    "simctl create My Phone com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-18-0" \
    "$(recorded xcrun_calls)"

run_menu "Create iOS simulator" "iOS 18.0" ""
check "cancel at device type creates nothing" "nothing" "$(recorded xcrun_calls)"

run_menu "Delete device" "UDID-1" "Yes"
check "delete allows selecting several devices" "1" "$(grep -c -- '--multi' "$work_dir/fzf_args.1")"
check "delete asks to confirm with the device name" "1" "$(grep -c 'Delete iPhone 16?' "$work_dir/fzf_args.2")"
check "delete iOS simulator" "simctl delete UDID-1" "$(recorded xcrun_calls)"
check "delete announces the device" "Deleted iPhone 16" "$(grep -a 'Deleted' "$work_dir/output")"

run_menu "Delete device" "UDID-2" "Yes"
check "delete booted iOS simulator shuts it down first" "simctl shutdown UDID-2
simctl delete UDID-2" "$(recorded xcrun_calls)"

run_menu "Delete device" "Pixel_Tablet" "Yes"
check "delete Android AVD" "delete avd -n Pixel_Tablet" "$(recorded avdmanager_calls)"

run_menu "Delete device" "Pixel_8" "Yes" || true
check "running Android emulator is not deleted" "nothing" "$(recorded avdmanager_calls)"
check "running Android emulator explains why" "1" "$(grep -ac 'Close the running emulator Pixel_8 first' "$work_dir/output")"

run_menu "Delete device" "UDID-1" "No"
check "declining the confirmation deletes nothing" "nothing" "$(recorded xcrun_calls)"

run_menu "Delete device" "UDID-1" ""
check "cancelling the confirmation deletes nothing" "nothing" "$(recorded xcrun_calls)"

run_menu "Delete device" "UDID-1|Pixel_Tablet" "Yes"
check "delete several devices asks once with every name" "1" \
    "$(grep -c 'Delete iPhone 16,Pixel_Tablet?' "$work_dir/fzf_args.2")"
check "delete several devices removes the iOS one" "simctl delete UDID-1" "$(recorded xcrun_calls)"
check "delete several devices removes the Android one" "delete avd -n Pixel_Tablet" "$(recorded avdmanager_calls)"

run_menu "Delete device" "UDID-1|Pixel_8" "Yes" || true
check "a running emulator in the selection stops the whole deletion" "nothing" "$(recorded xcrun_calls)"

echo 3 >"$work_dir/unavailable_count"
run_menu "Delete unavailable simulators" "Yes"
check "delete unavailable asks with the count" "1" "$(grep -c 'Delete 3 unavailable simulators?' "$work_dir/fzf_args.1")"
check "delete unavailable runs simctl" "simctl delete unavailable" "$(recorded xcrun_calls)"
check "delete unavailable reports the number removed" "Deleted 3 unavailable simulators" \
    "$(grep -a 'Deleted' "$work_dir/output")"

echo 3 >"$work_dir/unavailable_count"
run_menu "Delete unavailable simulators" "No"
check "declining keeps unavailable simulators" "nothing" "$(recorded xcrun_calls)"

echo 0 >"$work_dir/unavailable_count"
run_menu "Delete unavailable simulators"
check "nothing to delete is reported" "No unavailable simulators" "$(grep -a 'No unavailable' "$work_dir/output")"
check "nothing to delete runs no deletion" "nothing" "$(recorded xcrun_calls)"

preview_output() {
    PATH="$work_dir/bin:$PATH" HOME="$home_dir" bash "$repo_dir/scripts/herdr/sim-menu" --preview "$@"
}

check "iOS preview shows name, state and size" "Name:   iPhone 16
State:  Shutdown
UDID:   UDID-1
Type:   iPhone-16
Data:   5 MB
Path:   /data/UDID-1" "$(preview_output ios UDID-1)"

check "Android preview shows only the highlighted AVD" "    Name: Pixel_Tablet
  Device: pixel_tablet (Google)" "$(preview_output android Pixel_Tablet)"

finish_tests
