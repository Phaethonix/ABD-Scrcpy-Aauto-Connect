show_error() {
    zenity --error --title="Connection Error" --text="$1" 2>/dev/null
}

show_info() {
    zenity --info --title="Connection Info" --text="$1" 2>/dev/null
}

echo "Restarting ADB server..."
adb kill-server
adb start-server

echo "Attempting to connect to 192.168.1.82:5555..."
if adb connect 192.168.1.82:5555; then
    nohup scrcpy --no-video --no-control > /dev/null 2>&1 &
    show_info "Successfully connected via Wi-Fi!"
    exit 0
else
    echo "Wi-Fi connection failed. Checking USB connection..."

    USB_DEVICES=$(adb devices | grep -v "List of devices attached" | wc -l)
    if [ "$USB_DEVICES" -eq 0 ]; then
        show_error "Connection failed. Please:\n1. Connect to Wi-Fi\n2. Or connect device via USB\n3. Ensure USB debugging is enabled"
        exit 1
    fi

    echo "USB device detected. Switching to TCP/IP mode..."
    if ! adb tcpip 5555; then
        show_error "Failed to switch to TCP/IP mode. Ensure device is unlocked and USB debugging is enabled."
        exit 1
    fi

    PHONE_IP=$(adb shell ip -f inet addr show wlan0 | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+')

    if [[ ! "$PHONE_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        show_error "Could not retrieve valid IP address. Ensure Wi-Fi is connected."
        exit 1
    fi

    if ! adb connect "$PHONE_IP:5555"; then
        show_error "Failed to connect to $PHONE_IP:5555. Verify network connection."
        exit 1
    fi

    show_info "Successfully connected via USB and switched to Wi-Fi mode at $PHONE_IP:5555"
fi

"Attempting to start audio capture in background..."
nohup scrcpy --no-video --no-control > /dev/null 2>&1 &

echo "Scrcpy audio capture started in background"
