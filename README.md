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

*   The application does not currently read or display existing `pmset` schedules that were set previously. It can only be used for setting new schedules or overwriting existing ones.