# PowerOn

A user-friendly macOS application for scheduling your Mac's wake-up and shutdown times.

## Features

*   **Schedule Power On/Off:** Easily set daily schedules for your Mac to automatically wake up or shut down.
*   **Intuitive Interface:** Use a simple graphical interface to select times and days of the week for your power schedules.
*   **Command Preview:** See the exact `pmset` command that will be run before applying any changes.
*   **Built with SwiftUI:** A modern, native macOS application.
*   **Internationalization:** Available in English, French, German, Italian, and Japanese.

## How to Use

1.  **Enable a schedule:** Toggle the switch for "Power On" or "Shutdown".
2.  **Set the time:** Use the time picker to choose the desired hour and minute.
3.  **Select the days:** Toggle the switches for each day of the week you want the schedule to be active.
4.  **Apply:** Click the "Apply" button. A confirmation dialog will show you the command that will be executed. Confirm to apply the schedule.

## Project Goal

The goal of this project is to create a user-friendly macOS application that provides a graphical interface for the `pmset` command-line utility. This allows users to easily schedule their Mac to wake up or shut down at specific times without using the terminal.

## `pmset` Summary

`pmset` is a command-line utility in macOS used to manage power management settings. It allows for scheduling of events like wake, sleep, and shutdown. All modifications to `pmset` settings require root privileges, which is why the application will prompt for your password when applying changes.

### Common Commands

*   `pmset -g sched`: View the currently scheduled events.
*   `sudo pmset repeat cancel`: Cancel all scheduled events.
*   `sudo pmset repeat wakeorpoweron MTWRFSU 08:00:00`: Schedule the computer to wake at 8:00 AM every day.
*   `sudo pmset repeat shutdown MTWRFSU 22:00:00`: Schedule the computer to shut down at 10:00 PM every day.

## Known Limitations

*   The application can only be used for setting new schedules or overwriting existing ones.

## Build Instructions

The project can be built and packaged into a `.app` bundle and a `.dmg` installer using the provided `build_release.sh` script.

1.  **Build and Create DMG:**

    ```bash
    ./build_release.sh
    ```

    This script will:
    *   Build the application in release configuration.
    *   Create the `PowerOnGadget.app` bundle in the project root.
    *   Create a `PowerOnGadget.dmg` installer file.

    **Note on Info.plist:** The `Info.plist` file is now configured with copyright information for "Naimi Cyril" and the year "2025".

2.  **Adding an Application Icon (Optional):**
    To include a custom application icon:
    *   Create an `.icns` file (e.g., `AppIcon.icns`) from your image assets. You can use `iconutil` on macOS:
        ```bash
        mkdir AppIcon.iconset
        # Place your PNGs (e.g., icon_16x16.png, icon_32x32.png, etc.) inside AppIcon.iconset
        iconutil -c icns AppIcon.iconset -o AppIcon.icns
        ```
    *   Place the generated `AppIcon.icns` file in `Sources/poweron_gadget/Resources/`.
    *   The `build_release.sh` script will automatically copy this icon into the application bundle.

## Handling `pmset` Privileges

The `pmset` commands require root privileges to execute. In a production macOS application, directly using `sudo` via `Process` is not secure or reliable. The recommended and secure approach for privilege escalation is to implement a **Privileged Helper Tool (XPC Service)**.

### Plan for Privilege Escalation:

1.  **Create a Privileged Helper Tool:**
    *   This will be a separate, small executable that runs with root privileges.
    *   It will expose an XPC interface for the main application to communicate with it.
    *   It will be responsible for executing the `pmset` commands.

2.  **Implement XPC Communication:**
    *   The main `PowerOnGadget` application will establish a connection with the Privileged Helper Tool via XPC.
    *   The application will send requests (e.g., "set schedule") to the helper tool.
    *   The helper tool will execute the `pmset` command with its elevated privileges and return the result to the main application.

3.  **Code Signing and Installation:**
    *   Both the main application and the helper tool must be properly code-signed.
    *   The helper tool needs to be installed in a secure location (e.g., `/Library/PrivilegedHelperTools/`) and registered with `SMJobBless` to ensure it launches with root privileges.

This approach ensures that the main application does not need root privileges, enhancing security and adhering to macOS best practices. Implementing a Privileged Helper Tool is a complex task that requires careful attention to security and system integration.
