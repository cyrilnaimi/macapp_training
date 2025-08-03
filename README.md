# PowerOn

A secure, user-friendly macOS application for scheduling your Mac's wake-up and shutdown times using proper macOS authorization mechanisms.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.5+-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.2-green)

## ✨ Features

### Core Functionality
*   **🔌 Schedule Power On/Off**: Set daily schedules for automatic wake-up and shutdown
*   **🎯 Intuitive Interface**: Clean SwiftUI interface with time pickers and day selectors
*   **🛡️ Security First**: Uses macOS authorization services and privileged helper tool
*   **🔍 Command Preview**: Preview exact `pmset` commands before execution
*   **📊 Current Schedule Display**: Automatically loads and displays existing power schedules
*   **⚡ Real-time Validation**: Built-in checks to prevent problematic configurations

### User Experience
*   **🌍 Multi-language Support**: Available in 5 languages (English, French, German, Italian, Japanese)
*   **📱 Loading States**: Progress indicators for all async operations
*   **🚨 Error Handling**: Comprehensive error messages with recovery suggestions
*   **⚠️ Conflict Detection**: Warns about potential scheduling conflicts
*   **💾 Default Values**: Sensible defaults (Power On: 6:00 AM, Shutdown: 11:00 PM)

## 🎯 How It Works

### Power Scheduling Logic

The application provides two independent scheduling systems:

1. **🟢 Power On Schedule**: 
   - Wakes or powers on your Mac at specified times
   - Uses `pmset repeat wakeorpoweron` command
   - Can be enabled/disabled independently

2. **🔴 Shutdown Schedule**: 
   - Gracefully shuts down your Mac at specified times
   - Uses `pmset repeat shutdown` command
   - Can be enabled/disabled independently

### Toggle Button Logic

Each schedule has three components that work together:

1. **Toggle Switch**: 
   - Enables/disables the entire schedule
   - When OFF: Schedule is ignored even if time/days are set
   - When ON: Schedule becomes active based on time/days settings

2. **Time Picker**: 
   - Sets the exact time for the schedule
   - 24-hour format internally, displayed in user's preferred format
   - Changes are stored but not applied until "Apply" button is pressed

3. **Day Selectors**: 
   - Individual toggles for each day of the week
   - At least one day must be selected for an enabled schedule
   - Uses pmset day codes: M,T,W,R,F,S,U (Monday through Sunday)

### User Interface Flow

```
App Launch → Load Current Schedules → Display UI
     ↓
User Modifies Settings → Validate Configuration → Show Confirmation
     ↓
User Confirms → Install Helper (if needed) → Execute pmset Command → Show Result
```

### Default Behavior on Startup

When the app starts:
1. **Loading Phase**: Shows progress indicator while fetching current schedules
2. **Schedule Detection**: Queries system for existing `pmset` schedules
3. **UI Population**: 
   - If schedules exist: Populates UI with current settings
   - If no schedules: Shows default times but keeps toggles OFF
   - On error: Uses default times, allows user to set new schedules

## 🚀 Installation

### Option 1: From DMG (Recommended)

1. Download the latest `PowerOnGadget.dmg` from releases
2. Double-click to mount the DMG
3. Drag `PowerOnGadget.app` to your Applications folder
4. **Important**: Run the app from Applications (not from the DMG)
5. On first run, you'll be prompted for administrator privileges

### Option 2: Building from Source

```bash
# Clone the repository
git clone https://github.com/cyrilnaimi/poweron.git
cd poweron

# Build the release
./build_release.sh

# The script creates:
# - PowerOnGadget.app (application bundle)
# - PowerOnGadget.dmg (installer disk image)
```

## 📋 Usage Guide

### Basic Usage

1. **Launch the app** from Applications folder
2. **Enable desired schedules** using the toggle switches
3. **Set times** using the time pickers (24-hour format supported)
4. **Select days** by toggling individual day switches
5. **Click Apply** to preview the command
6. **Confirm** to execute the changes

### Advanced Configuration

#### Validation Rules
- At least one schedule must be enabled when applying
- Each enabled schedule must have at least one day selected
- Shutdown time cannot be within 5 minutes of power on time
- All validation errors show helpful messages with solutions

#### Day Selection Logic
- **Individual Control**: Each day can be toggled independently
- **Multiple Days**: Select any combination of days
- **Day Codes**: Internally uses M,T,W,R,F,S,U format
- **Validation**: At least one day required for enabled schedules

#### Time Handling
- **Default Times**: Power On (6:00 AM), Shutdown (11:00 PM)
- **Format**: 24-hour format stored, displayed in user preference
- **Precision**: Minute-level precision (seconds set to 00)
- **Validation**: Conflict detection for overlapping times

### Example Scenarios

#### Scenario 1: Weekday Work Schedule
```
Power On:  ✅ Enabled, 6:00 AM, Monday-Friday
Shutdown:  ✅ Enabled, 11:00 PM, Monday-Friday
Result:    pmset repeat wakeorpoweron MTWRF 06:00:00 shutdown MTWRF 23:00:00
```

#### Scenario 2: Weekend Only
```
Power On:  ✅ Enabled, 9:00 AM, Saturday-Sunday  
Shutdown:  ❌ Disabled
Result:    pmset repeat wakeorpoweron SU 09:00:00
```

#### Scenario 3: Clear All Schedules
```
Power On:  ❌ Disabled
Shutdown:  ❌ Disabled
Result:    pmset repeat cancel
```

## 🔒 Security Implementation

This application follows macOS security best practices:

### Architecture Overview
```
Main App (User Space)
    ↕ XPC Communication
Privileged Helper Tool (Root)
    ↕ System Calls
macOS pmset Command
```

### Security Components

1. **🛡️ Privileged Helper Tool**: 
   - Separate executable (`PowerOnHelper`) runs with root privileges
   - Handles all `pmset` command execution
   - Isolated from main application logic

2. **🔐 XPC Communication**: 
   - Secure inter-process communication between app and helper
   - Type-safe message passing with error handling
   - No direct sudo usage in main application

3. **🔑 Authorization Services**: 
   - Proper macOS authentication prompts
   - Uses `SMJobBless` for helper installation
   - Respects user's security preferences

4. **📝 Code Signing**: 
   - Both main app and helper tool are signed
   - Entitlements properly configured
   - Runtime hardening enabled

### First Run Experience

1. **Helper Installation**: On first use, the app will:
   - Request administrator credentials
   - Install the helper tool to `/Library/PrivilegedHelperTools/`
   - Register with system launch daemon
   - Create necessary authorization rights

2. **Subsequent Runs**: 
   - No additional prompts needed
   - Helper tool launches automatically when needed
   - Secure communication via XPC

## 🛠️ Technical Details

### System Requirements
- **macOS**: 12.0 (Monterey) or later
- **Architecture**: x86_64 (Intel) and Apple Silicon supported
- **Privileges**: Administrator access for helper tool installation

### Project Structure

```
Sources/
├── poweron_gadget/          # Main SwiftUI application
│   ├── PowerOnApp.swift     # App entry point
│   ├── ContentView.swift    # Main UI with scheduling interface  
│   ├── PMSetManager.swift   # XPC communication & authorization
│   └── Resources/           # Localizations and assets
├── PowerOnHelper/           # Privileged helper tool
│   ├── PowerOnHelper.swift  # XPC service implementation
│   ├── main.swift          # Helper tool entry point
│   └── Info.plist          # Helper tool configuration
└── PowerOnShared/           # Shared protocols
    └── PowerOnHelperProtocol.swift  # XPC interface definition
```

### Build System

The project uses Swift Package Manager with custom build script:

```bash
# Development build
swift build

# Release build with app bundle
./build_release.sh
```

The build script:
- Compiles both main app and helper tool
- Creates proper app bundle structure
- Handles code signing with entitlements
- Configures SMJobBless requirements
- Creates DMG installer

### Localization Support

All user-facing strings are localized in 5 languages:

| Language | Code | Status |
|----------|------|--------|
| English  | en   | ✅ Complete |
| French   | fr   | ✅ Complete |
| German   | de   | ✅ Complete |
| Italian  | it   | ✅ Complete |
| Japanese | ja   | ✅ Complete |

New strings added in v1.2:
- Error messages and validation feedback
- Loading state indicators
- Enhanced confirmation dialogs
- Configuration warnings

## 🐛 Troubleshooting

### Common Issues

#### "Helper tool not found" Error
```bash
# Check if helper is installed
sudo launchctl list | grep com.naimicyril.poweron.helper

# If not found, try reinstalling by running app from /Applications
```

#### Permission Denied Errors
- Ensure app is run from `/Applications` folder
- Check that helper tool installation completed successfully
- Try removing and reinstalling the app

#### Schedules Not Working
```bash
# Check current system schedules
pmset -g sched

# Verify power management settings
pmset -g
```

### Debug Commands

#### View Helper Tool Logs
```bash
log show --predicate 'subsystem == "com.naimicyril.poweron.helper"' --info --last 1h
```

#### Manual Helper Removal
```bash
sudo launchctl unload /Library/LaunchDaemons/com.naimicyril.poweron.helper.plist
sudo rm /Library/LaunchDaemons/com.naimicyril.poweron.helper.plist  
sudo rm /Library/PrivilegedHelperTools/com.naimicyril.poweron.helper
```

#### Code Signing Verification
```bash
codesign -dv PowerOnGadget.app
codesign -dv PowerOnGadget.app/Contents/Library/LaunchServices/PowerOnHelper
```

### Known Limitations

- **Single Schedule Per Type**: Only one power on and one shutdown schedule supported
- **Same Time All Days**: Selected days use the same time (no per-day customization)
- **Application Location**: Must run from `/Applications` for helper tool functionality
- **macOS Restrictions**: Some Macs may not support scheduled wake from full shutdown

## 🚀 Development

### Requirements
- **Xcode**: 13.0 or later
- **Swift**: 5.5 or later  
- **macOS SDK**: 12.0 or later

### Development Workflow

```bash
# Clone and setup
git clone https://github.com/yourusername/poweron.git
cd poweron

# Development build
swift build

# Run tests (when available)
swift test

# Create release
./build_release.sh
```

### Code Signing for Distribution

For development, the build uses ad-hoc signing. For distribution:

1. **Update Build Script**:
   ```bash
   # In build_release.sh, replace:
   SIGNING_IDENTITY="-"
   # With your Developer ID:
   SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
   ```

2. **Notarization** (for distribution outside Mac App Store):
   ```bash
   # After building, notarize the app
   xcrun notarytool submit PowerOnGadget.dmg --keychain-profile "notary-profile"
   ```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following the existing code style
4. Add localization strings for any new user-facing text
5. Test on multiple macOS versions if possible
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

#### Translation Guidelines

When adding new strings:
1. Add to `en.lproj/Localizable.strings` first
2. Update all other language files (fr, de, it, ja)
3. Use descriptive keys that indicate context
4. Test with different languages to ensure UI layout works

## 📝 Changelog

### Version 1.2 (Current)
- ✅ **Security**: Replaced direct sudo with privileged helper tool
- ✅ **Authorization**: Implemented proper macOS authorization services  
- ✅ **XPC**: Added secure inter-process communication
- ✅ **Validation**: Comprehensive input validation and error handling
- ✅ **UI**: Loading states and progress indicators
- ✅ **Defaults**: Sensible default times (6:00 AM / 11:00 PM)
- ✅ **Localization**: Fixed translation bugs, added new strings
- ✅ **Build**: Enhanced build script with proper code signing

### Version 1.1 (Previous)
- Basic scheduling functionality
- Direct sudo usage (deprecated)
- Multi-language support
- SwiftUI interface

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple Documentation**: SMJobBless and Authorization Services guides
- **SwiftUI Community**: Modern macOS app development patterns
- **Open Source**: Inspired by the need for secure power management tools
- **Translators**: Community contributions for internationalization
- **Security Research**: macOS privilege escalation best practices


---

Built with ❤️ using SwiftUI for a native macOS experience.