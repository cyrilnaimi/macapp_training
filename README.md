# poweron_gadget

A macOS application to schedule wake-up and shutdown times.

## Features

*   View the current `pmset` schedule.
*   Set a new schedule for wake-up, and shutdown.
*   Built with SwiftUI.

## Project Goal

The goal of this project is to create a user-friendly macOS application that provides a graphical interface for the `pmset` command-line utility. This will allow users to easily schedule their Mac to wake up or shut down at specific times without using the terminal.

## `pmset` Summary

`pmset` is a command-line utility in macOS used to manage power management settings. It allows for scheduling of events like wake, sleep, and shutdown. All modifications to `pmset` settings require root privileges.

### Common Commands

*   `pmset -g` or `pmset -g sched`: View the currently scheduled events.
*   `sudo pmset repeat cancel`: Cancel all scheduled events.
*   `sudo pmset repeat wakeorpoweron MTWRF 08:00:00`: Schedule the computer to wake at 8:00 AM on weekdays.
*   `sudo pmset repeat shutdown MTWRF 22:00:00`: Schedule the computer to shut down at 10:00 PM on weekdays.

## Internationalization

This application will support the following languages in future releases:

*   English (Default)
*   French
*   German
*   Italian
*   Japanese
