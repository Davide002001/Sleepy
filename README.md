# Sleepy App

## Introduction
Sleepy is an iOS application that integrates with HealthKit to fetch and manage sleep data. It allows users to synchronize their sleep details with a remote server.

## Prerequisites
Ensure you have the following installed on your system:
- macOS with the latest updates
- Xcode (latest version recommended)
- Swift and SwiftUI
- An Apple Developer Account (if testing on a physical device)
- A valid HealthKit-enabled device (or simulator with HealthKit debugging enabled)

## Setup Instructions
### 1. Clone the Repository
```bash
git clone https://github.com/Davide002001/Sleepy.git
cd Sleepy
```

### 2. Open in Xcode
- Open the `Sleepy.xcodeproj` file in Xcode.
- Ensure the target is set to an iOS device or simulator.

### 3. Configure Signing & Capabilities
- Go to `Signing & Capabilities` in the Xcode project settings.
- Ensure that your Apple Developer Team is set up correctly.
- Add the `HealthKit` capability.
- Ensure permissions for sleep data are enabled.

### 4. Setup API Integration
- Navigate to `NetworkManager.swift`.
- Update the API base URL and authentication keys if necessary.

### 5. Run the App on Your iPhone
- Connect your iPhone to your Mac.
- Open Xcode and select your iPhone as the target device.
- Ensure you have a valid Apple Developer Account signed in under `Signing & Capabilities`.
- Press `Cmd + R` or click the `Run` button in Xcode to launch the app on your device.
- **Note:** On the first launch, you may encounter an error. To resolve this:
  1. Open **Settings** on your iPhone.
  2. Navigate to **General** → **VPN & Device Management**.
  3. Tap on your **Developer Profile** and confirm it.
  4. Restart the app.

## Features
- Fetch sleep data from HealthKit.
- Sync sleep details with a remote server.
- Display API responses in the UI.
- Handle success and error messages efficiently.

## Troubleshooting
### HealthKit Permissions Issue
- Go to iPhone **Settings** → **Privacy & Security** → **Health** → Select your App → Enable Sleep Data access.

### API Connection Issues
- Ensure the API server is running.
- Verify network connectivity.
- Check the API base URL in `NetworkManager.swift`.

## Contributing
Feel free to submit issues or pull requests. Follow standard Git branching and commit guidelines.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

