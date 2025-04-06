# MediSwitch Project

This project contains the Flutter mobile application and Django backend for MediSwitch.

## Development Setup

### Flutter Wi-Fi Debugging (ADB)

To enable debugging your Flutter application on an Android device over Wi-Fi, follow these steps:

**Prerequisites:**

*   Android device with Android 11 or higher.
*   Computer and Android device connected to the **same Wi-Fi network**.
*   Android SDK Platform Tools installed on your computer (includes `adb`). Ensure `adb` is in your system's PATH.

**Steps:**

1.  **Enable Developer Options on Device:**
    *   Go to `Settings` > `About phone`.
    *   Tap `Build number` seven times until you see a message "You are now a developer!".
    *   Go back to `Settings` > `System` > `Developer options`.

2.  **Enable Wireless Debugging:**
    *   Inside `Developer options`, find and enable `Wireless debugging`.
    *   Allow wireless debugging on your network if prompted.

3.  **Pair Device:**
    *   Tap on `Wireless debugging` (the text, not the toggle).
    *   Select `Pair device with pairing code`.
    *   Note the `IP address & Port` and the `Wi-Fi pairing code` displayed on your device.

4.  **Connect from Computer:**
    *   Open a terminal or command prompt on your computer.
    *   Run the following command, replacing `<IP_ADDRESS>`, `<PORT>`, and `<PAIRING_CODE>` with the values from your device:
        ```bash
        adb pair <IP_ADDRESS>:<PORT> <PAIRING_CODE>
        ```
        *(Example: `adb pair 192.168.1.100:41234 123456`)*
    *   You should see a "Successfully paired" message.

5.  **Connect for Debugging:**
    *   On your device, under `Wireless debugging`, find the `IP address & Port` listed (it might be different from the pairing port).
    *   Run the following command on your computer, replacing `<IP_ADDRESS>` and `<DEBUG_PORT>`:
        ```bash
        adb connect <IP_ADDRESS>:<DEBUG_PORT>
        ```
        *(Example: `adb connect 192.168.1.100:37899`)*
    *   You should see a "connected" message.

6.  **Verify Connection:**
    *   Run `adb devices`. You should see your device listed with its IP address and port.
    *   In VS Code or Android Studio, your device should now appear in the device list, ready for debugging over Wi-Fi.

**Troubleshooting:**

*   Ensure both devices are on the same Wi-Fi network.
*   Make sure `adb` is correctly installed and in your PATH.
*   Restart `adb` server (`adb kill-server` then `adb start-server`).
*   Disable and re-enable Wireless Debugging on the device.
*   Forget previous pairings on the device under Wireless Debugging if issues persist.