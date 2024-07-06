# BLE Receiver

## Introduction

<<<<<<< HEAD
BLE Receiver is a SwiftUI application that allows users to scan, connect, and interact with Bluetooth Low Energy (BLE) devices. The app is integrated with Firebase Firestore for cloud data storage, and uses Core Data for local storage, providing a experience for managing BLE device data.
=======
BLE Receiver is a SwiftUI application that allows users to scan, connect, and interact with Bluetooth Low Energy (BLE) devices. The app is integrated with Firebase Firestore for data storage and retrieval, providing a seamless experience for managing BLE device data.
>>>>>>> c44a4d8d5e911d93235f951c821a711bc8c4dac8

## Features

- **Scan for BLE Devices**: Discover nearby BLE devices.
- **Connect to Devices**: Establish a connection with selected BLE devices.
- **Read and Write Data**: Interact with the BLE devices by reading and writing data.
<<<<<<< HEAD
- **Local Storage**: Store device data locally using Core Data.
- **Cloud Storage**: Store device data in Firebase Firestore for persistent cloud storage.
- **User Interface**: A clean and intuitive SwiftUI-based user interface.

## Supported Devices

The app currently supports the following devices:
- Blood Pressure Monitor (Rossmax-x3)
- SPO2 Monitor (Rossmax SB210)
- Thermometer (Rossmax HC700)
- Body Fat Scale (Xiaomi Body Fat Scale 2)

To add support for new devices, you need to search for the target BLE characteristic or service and implement the corresponding decoding logic.

=======
- **Data Storage**: Store device data in Firebase Firestore for persistent storage.
- **User Interface**: A clean and intuitive SwiftUI-based user interface.

>>>>>>> c44a4d8d5e911d93235f951c821a711bc8c4dac8
## Installation

To run the project locally, follow these steps:

1. **Clone the Repository**:
<<<<<<< HEAD
    ```
    https://cfhclouddevops@dev.azure.com/cfhclouddevops/CSD-FMIntern/_git/BLE_APP.git
=======
    ```sh
    git clone https://github.com/yourusername/BLE_reciver.git
    cd BLE_reciver
>>>>>>> c44a4d8d5e911d93235f951c821a711bc8c4dac8
    ```

2. **Open the Project in Xcode**:
    Open `BLE_scanner.xcodeproj` in Xcode.

3. **Install Dependencies**:
<<<<<<< HEAD
    If you are using Swift Package Manager, the dependencies should be resolved automatically when you open the project in Xcode.
=======
    Ensure you have CocoaPods installed. Then, run:
    ```sh
    pod install
    ```
>>>>>>> c44a4d8d5e911d93235f951c821a711bc8c4dac8

4. **Firebase Configuration**:
    Make sure the `GoogleService-Info.plist` file is correctly placed in the project directory.

5. **Build and Run**:
    Select your target device or simulator and click the run button in Xcode.

## Usage

<<<<<<< HEAD
1. **Connecting to a Device**:
    - Tap on a device from the list to establish a connection.
    - The app will connect to the device and display available services and characteristics.

2. **Interacting with Devices**:
    - Read data to the connected BLE device as needed.
    - The data is automatically stored in Core Data locally and in Firebase Firestore for cloud storage.

## Project Structure

- `BLE_scanner`: Contains the main Swift code for the BLE Receiver app.
    - `ContentView.swift`: 
    The main entry point for the SwiftUI app, setting up the main view.
    - `AccountView.swift`: 
    Manages user account interactions and displays user-related information.
    - `MeasureView.swift`: 
    Displays measurement data from the connected BLE devices.
    - `Reciver.swift`: 
    Handles the BLE communication logic, including scanning, connecting, and data transfer.
    - `MonitorView.swift`: 
    Monitors real-time data from connected BLE devices and displays it.
    - `coredata_tool.swift`: 
    Provides utility functions and extensions for working with CoreData.
    - `try_page.swift`: 
    A sample page for firestore.
    
- `BLE_scannerTests`: Contains unit tests for the app.
- `BLE_scannerUITests`: Contains UI tests for the app.
- `BLE_scanner.xcodeproj`: Xcode project file.
- `GoogleService-Info.plist`: Firebase configuration file.
- `images/`: Contains images used in the project.


## Acknowledgements
- [Core Data](https://developer.apple.com/documentation/coredata)
- [Firebase](https://firebase.google.com/)
- [Apple Developer](https://developer.apple.com/)
=======
1. **Scanning for Devices**:
    - Launch the app.
    - Tap on the "Scan" button to start scanning for nearby BLE devices.
    - The app will list all the discoverable devices.

2. **Connecting to a Device**:
    - Tap on a device from the list to establish a connection.
    - The app will connect to the device and display available services and characteristics.

3. **Interacting with Devices**:
    - Read or write data to the connected BLE device as needed.
    - The data is automatically stored in Firebase Firestore.

## Project Structure

- `BLE_scanner/`: Contains the main Swift code for the BLE Receiver app.
- `BLE_scannerTests/`: Contains unit tests for the app.
- `BLE_scannerUITests/`: Contains UI tests for the app.
- `BLE_scanner.xcodeproj/`: Xcode project file.
- `GoogleService-Info.plist`: Firebase configuration file.
- `LICENSE`: Project license.
- `images/`: Contains images used in the project.
- `.gitignore`: Specifies which files should be ignored by Git.
- `.git/`: Contains Git repository data.

## Contributing

We welcome contributions! Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature-name`).
3. Make your changes and commit them (`git commit -m 'Add some feature'`).
4. Push to the branch (`git push origin feature/your-feature-name`).
5. Open a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [Firebase](https://firebase.google.com/)
- [Apple Developer](https://developer.apple.com/)

---
>>>>>>> c44a4d8d5e911d93235f951c821a711bc8c4dac8
