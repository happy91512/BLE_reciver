import CoreBluetooth
import SwiftUI
import CoreData
import Foundation
enum thermometer_reciever {
    struct PersistenceController {
        static let shared = PersistenceController()

        static var preview: PersistenceController = {
            let result = PersistenceController(inMemory: true)
            let viewContext = result.container.viewContext
            for _ in 0..<10 {
                let newItem = Item(context: viewContext)
                newItem.timestamp = Date()
            }
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            return result
        }()

        let container: NSPersistentContainer

        init(inMemory: Bool = false) {
            container = NSPersistentContainer(name: "Dev")
            if inMemory {
                container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            }
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
    
    // BLEManager class is responsible for managing all Bluetooth Low Energy (BLE) operations,
    // including scanning for devices, connecting to peripherals, and handling data communication.
    class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
        // CBCentralManager instance to manage the Bluetooth operations
        var centralManager: CBCentralManager!
        // CBPeripheral instance representing the peripheral device that the app connects to
        var peripheral: CBPeripheral?

        // Published properties to notify the UI about status and data changes
        @Published var statusMessage = "Ready"
        @Published var receivedData = "Waiting for data..."

        // UUIDs for filtering devices and characteristics
        let deviceName = "RM_FH"
        let characteristicUUIDs = [CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb")]

        // Initializer to set up the CBCentralManager instance
        override init() {
            super.init()
            centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        }

        // Function to start scanning for peripheral devices
        func startScanning() {
            if centralManager.state == .poweredOn {
                statusMessage = "Scanning..."
                // Delay the scanning process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.centralManager.scanForPeripherals(withServices: nil, options: nil)
                }
            } else {
                statusMessage = "Bluetooth is not ready."
            }
        }

        // Delegate method to handle updates in the Bluetooth state
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            switch central.state {
            case .poweredOn:
                statusMessage = "Bluetooth is On."
            case .poweredOff:
                statusMessage = "Bluetooth is Off."
            default:
                statusMessage = "Unknown Bluetooth status."
            }
        }

        // Delegate method to handle discovery of a peripheral device
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
            if peripheral.name != nil{
                print(peripheral.name!, peripheral.identifier.uuidString)
            }
            if peripheral.name == deviceName {
                self.peripheral = peripheral
                centralManager.stopScan()
                statusMessage = "Found device, connecting to \(peripheral.name ?? "")"
                // Delay the connection process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.centralManager.connect(peripheral, options: nil)
                }
            }
        }

        // Delegate method to handle successful connection to a peripheral device
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            statusMessage = "Connected to \(peripheral.name ?? "")"
            peripheral.delegate = self
            // Delay the service discovery process by 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                peripheral.discoverServices([CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")])
            }
        }

        // Delegate method to handle the discovery of services for a connected peripheral
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard let services = peripheral.services else { return }
            let interestedCharacteristicUUIDs = [CBUUID(string: "fff1")]
            for service in services {
                statusMessage = ("Discovered service: \(service.uuid)")
                // Delay the characteristic discovery process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    peripheral.discoverCharacteristics(interestedCharacteristicUUIDs, for: service)
                }
            }
        }
        
        // Delegate method to handle the discovery of characteristics for a service
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            guard let characteristics = service.characteristics else { return }
            for characteristic in characteristics {
                statusMessage = ("Characteristic UUID: \(characteristic.uuid), properties: \(characteristic.properties)")
                if characteristic.properties.contains(.read) {
                    statusMessage = ("Characteristic \(characteristic.uuid) is readable")
                    peripheral.readValue(for: characteristic)
                } else if characteristic.properties.contains(.notify) {
                    statusMessage = ("Characteristic \(characteristic.uuid) supports notifications. Subscribing...")
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }

        // Delegate method to handle updates in the value of a characteristic
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            if let value = characteristic.value, characteristic.uuid == CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb") {
                let hexString = value.map { String(format: "%02hhx", $0) }.joined()
                
                DispatchQueue.main.async {
                    if let convertedData = self.processHexString(hexString) {
                        self.receivedData = String(format: "%.2f°C", convertedData)
                        self.statusMessage = "Received raw data: \(hexString)"
                    } else {
                        self.statusMessage = "Error in processing data."
                    }
                }
            }
        }
        
        // Utility function to process the received hex string data
        func processHexString(_ hexString: String) -> Double? {
            // Ensure the string length is at least 8 characters
            guard hexString.count >= 8 else { return nil }

            // Extract and convert the substring "233b" (from index 10 to 13)
            let startIndex = hexString.index(hexString.startIndex, offsetBy: 10)
            let endIndex = hexString.index(hexString.startIndex, offsetBy: 13)
            let subString = String(hexString[startIndex...endIndex]) // "233b"

            // Extract and convert "23" and "3b"
            if let firstPart = Int(subString.prefix(2), radix: 16),
               let secondPart = Int(subString.suffix(2), radix: 16) {
                // Calculate the final result
                return Double(secondPart) * 0.01 + Double(firstPart)
            } else {
                return nil
            }
        }
    }

    // SwiftUI view to display the app UI
    struct ContentView: View {
        @ObservedObject var bleManager = BLEManager()

        var body: some View {
            ZStack {
//                Color(red: 0.68, green: 0.85, blue: 1).edgesIgnoringSafeArea(.all)
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    Spacer()

                    // App title
                    Text("BLE Device Subscriber")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.label))

                    // Status and Data display with visual enhancements
                    VStack {
                        // Display connection status
                        Text("Status: \(bleManager.statusMessage)")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.yellow.opacity(0.85))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )

                        // Display received data
                        Text("Data: \(bleManager.receivedData)")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.black.opacity(0.55))
                            .padding()
                            .background(Color.green.opacity(0.55))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .frame(width: 300, height: 60)
                    }
                    .padding()
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)

                    // Start scanning button with 3D effect
                    Button(action: {
                        withAnimation {
                            bleManager.startScanning()
                        }
                    }) {
                        Text("Start Scanning")
                            .font(.title2)
                            .foregroundColor(.white)
                            .bold()
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(20)
                            .shadow(color: .blue, radius: 2, x: 2, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 1)
                                    .shadow(color: .white, radius: 2, x: -2, y: -2)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            )
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

enum OP_reciever {
    struct PersistenceController {
        static let shared = PersistenceController()

        static var preview: PersistenceController = {
            let result = PersistenceController(inMemory: true)
            let viewContext = result.container.viewContext
            for _ in 0..<10 {
                let newItem = Item(context: viewContext)
                newItem.timestamp = Date()
            }
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            return result
        }()

        let container: NSPersistentContainer

        init(inMemory: Bool = false) {
            container = NSPersistentContainer(name: "Dev")
            if inMemory {
                container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            }
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
    
    // BLEManager class is responsible for managing all Bluetooth Low Energy (BLE) operations,
    // including scanning for devices, connecting to peripherals, and handling data communication.
    class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
        // CBCentralManager instance to manage the Bluetooth operations
        var centralManager: CBCentralManager!
        // CBPeripheral instance representing the peripheral device that the app connects to
        var peripheral: CBPeripheral?

        // Published properties to notify the UI about status and data changes
        @Published var statusMessage = "Ready"
        @Published var receivedData = "Waiting for data..."

        // UUIDs for filtering devices and characteristics
        let deviceName = "RM_SPO2"
        let characteristicUUIDs = [CBUUID(string: "6E40F682-B5A3-F393-E0A9-E50E24DCCA9E")]

        // Initializer to set up the CBCentralManager instance
        override init() {
            super.init()
            centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        }

        // Function to start scanning for peripheral devices
        func startScanning() {
            if centralManager.state == .poweredOn {
                statusMessage = "Scanning..."
                // Delay the scanning process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.centralManager.scanForPeripherals(withServices: nil, options: nil)
                }
            } else {
                statusMessage = "Bluetooth is not ready."
            }
        }

        // Delegate method to handle updates in the Bluetooth state
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            switch central.state {
            case .poweredOn:
                statusMessage = "Bluetooth is On."
            case .poweredOff:
                statusMessage = "Bluetooth is Off."
            default:
                statusMessage = "Unknown Bluetooth status."
            }
        }

        // Delegate method to handle discovery of a peripheral device
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
            if peripheral.name != nil{
                print(peripheral.name!, peripheral.identifier.uuidString)
            }
            if peripheral.name == deviceName {
                self.peripheral = peripheral
                centralManager.stopScan()
                statusMessage = "Found device, connecting to \(peripheral.name ?? "")"
                // Delay the connection process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.centralManager.connect(peripheral, options: nil)
                }
            }
        }

        // Delegate method to handle successful connection to a peripheral device
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            statusMessage = "Connected to \(peripheral.name ?? "")"
            peripheral.delegate = self
            // Delay the service discovery process by 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                peripheral.discoverServices([CBUUID(string: "6e40f680-b5a3-f393-e0a9-e50e24dcca9e")])
            }
        }

        // Delegate method to handle the discovery of services for a connected peripheral
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard let services = peripheral.services else { return }
            let interestedCharacteristicUUIDs = [CBUUID(string: "6E40F682-B5A3-F393-E0A9-E50E24DCCA9E")]
            for service in services {
                statusMessage = ("Discovered service: \(service.uuid)")
                // Delay the characteristic discovery process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    peripheral.discoverCharacteristics(interestedCharacteristicUUIDs, for: service)
                }
            }
        }
        
        // Delegate method to handle the discovery of characteristics for a service
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            guard let characteristics = service.characteristics else { return }
            for characteristic in characteristics {
                statusMessage = ("Characteristic UUID: \(characteristic.uuid), properties: \(characteristic.properties)")
                if characteristic.properties.contains(.read) {
                    statusMessage = ("Characteristic \(characteristic.uuid) is readable")
                    peripheral.readValue(for: characteristic)
                } else if characteristic.properties.contains(.notify) {
                    statusMessage = ("Characteristic \(characteristic.uuid) supports notifications. Subscribing...")
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }

        // Delegate method to handle updates in the value of a characteristic
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            if let value = characteristic.value, characteristic.uuid == CBUUID(string: "6E40F682-B5A3-F393-E0A9-E50E24DCCA9E") {
                let hexString = value.map { String(format: "%02hhx", $0) }.joined()
                
                DispatchQueue.main.async {
                    if let convertedData = self.processHexString(hexString) {
                        self.receivedData = String(convertedData)
                        self.statusMessage = "Received raw data: \(hexString)"
                    } 
                    else {
                        self.statusMessage = "Error in processing data."
                    }
                }
            }
        }
        
        // Utility function to process the received hex string data
        func processHexString(_ hexString: String) -> String? {
            guard hexString.count >= 6 else { return nil } // 確保字符串長度至少為6個字符
            
            // 將十六進制字符串轉換為字節數組
            var byteArray = [UInt8]()
            var index = hexString.startIndex
            while index < hexString.endIndex {
                let byteString = String(hexString[index..<hexString.index(index, offsetBy: 2)])
                if let byte = UInt8(byteString, radix: 16) {
                    byteArray.append(byte)
                } else {
                    return nil // 解析字節失敗
                }
                index = hexString.index(index, offsetBy: 2)
            }
            
            // 解碼字節數組
            let measureStatus = byteArray[0] == 0x00 ? "未偵測到手指" : "偵測到手指"
            let oxygenPercentage = byteArray[1]
            let heartRate = byteArray[2]
            
            // 生成結果字符串
            let result = "status: \(measureStatus)\n" +
            "OP: \(oxygenPercentage)\n" +
            "heart_rate: \(heartRate) bpm"
            
            return result
        }
    }
    

    // SwiftUI view to display the app UI
    struct ContentView: View {
        @ObservedObject var bleManager = BLEManager()

        var body: some View {
            ZStack {
//                Color(red: 0.68, green: 0.85, blue: 1).edgesIgnoringSafeArea(.all)
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    Spacer()

                    // App title
                    Text("BLE Device Subscriber")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.label))

                    // Status and Data display with visual enhancements
                    VStack {
                        // Display connection status
                        Text("Status: \(bleManager.statusMessage)")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.yellow.opacity(0.85))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )

                        // Display received data
                        Text("Data: \(bleManager.receivedData)")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.black.opacity(0.55))
                            .padding()
                            .background(Color.green.opacity(0.55))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .frame(width: 300, height: 160)
                    }
                    .padding()
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)

                    // Start scanning button with 3D effect
                    Button(action: {
                        withAnimation {
                            bleManager.startScanning()
                        }
                    }) {
                        Text("Start Scanning")
                            .font(.title2)
                            .foregroundColor(.white)
                            .bold()
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(20)
                            .shadow(color: .blue, radius: 2, x: 2, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 1)
                                    .shadow(color: .white, radius: 2, x: -2, y: -2)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            )
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
                .padding()
            }
        }
    }
}

enum scale_reciever {
    struct PersistenceController {
        static let shared = PersistenceController()

        static var preview: PersistenceController = {
            let result = PersistenceController(inMemory: true)
            let viewContext = result.container.viewContext
            for _ in 0..<10 {
                let newItem = Item(context: viewContext)
                newItem.timestamp = Date()
            }
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            return result
        }()

        let container: NSPersistentContainer

        init(inMemory: Bool = false) {
            container = NSPersistentContainer(name: "Dev")
            if inMemory {
                container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            }
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
    
    // BLEManager class is responsible for managing all Bluetooth Low Energy (BLE) operations,
    // including scanning for devices, connecting to peripherals, and handling data communication.
    class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
        // CBCentralManager instance to manage the Bluetooth operations
        var centralManager: CBCentralManager!
        // CBPeripheral instance representing the peripheral device that the app connects to
        var peripheral: CBPeripheral?
        var advertisementData: [String: Any]?
        //        var timer: Timer?
        // Published properties to notify the UI about status and data changes
        @Published var statusMessage = "Ready"
        @Published var receivedData = "Waiting for data..."
        
        // UUIDs for filtering devices and characteristics
        let deviceName = "MIBFS"
        let serviceUUIDs = [CBUUID(string: "0000181b-0000-1000-8000-00805f9b34fb")]
        let serviceIdentifier: String? = "Body Composition"
        
        // Initializer to set up the CBCentralManager instance
        override init() {
            super.init()
            centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
            //            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(extractAdvertisementData), userInfo: nil, repeats: true)
        }
        
        // Function to start scanning for peripheral devices
        func startScanning() {
            if centralManager.state == .poweredOn {
                statusMessage = "Scanning..."
                // Delay the scanning process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.centralManager.scanForPeripherals(withServices: nil, options: nil)
                }
            } else {
                statusMessage = "Bluetooth is not ready."
            }
        }
        
        // Delegate method to handle updates in the Bluetooth state
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            switch central.state {
            case .poweredOn:
                statusMessage = "Bluetooth is On."
            case .poweredOff:
                statusMessage = "Bluetooth is Off."
            default:
                statusMessage = "Unknown Bluetooth status."
            }
        }
        
        // Delegate method to handle discovery of a peripheral device
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
            
            if peripheral.name == deviceName {
                self.peripheral = peripheral
//                statusMessage = "Found device, connecting to \(peripheral.name ?? "")"
            }
            
            
            if let serviceData = advertisementData["kCBAdvDataServiceData"] as? [CBUUID: Data],
               let bodyCompositionData = serviceData[CBUUID(string: "0000181b-0000-1000-8000-00805f9b34fb")] {
                let hexString = bodyCompositionData.map { String(format: "%02x", $0) }.joined()
                DispatchQueue.main.async {
                    if let convertedData = self.decodeBodyCompositionData(hexString) {
                        self.receivedData = String(convertedData)
                        self.statusMessage = "Received raw data: \(hexString)"
                    }
                    else {
                        self.statusMessage = "Error in processing data."
                    }
                }
            }
            
        }
        
        // Utility function to process the received hex string data
        func decodeBodyCompositionData(_ hexString: String) -> String? {
            let data = "1b18" + hexString
            var byteArray = [UInt8]()
            var index = hexString.startIndex
            while index < hexString.endIndex {
                let byteString = String(hexString[index..<hexString.index(index, offsetBy: 2)])
                if let byte = UInt8(byteString, radix: 16) {
                    byteArray.append(byte)
                } else {
                    return nil // 解析字節失敗
                }
                index = hexString.index(index, offsetBy: 2)
            }
            
            let ctrlByte1 = byteArray[1]
            let isStabilized = (ctrlByte1 & (1 << 5)) != 0 // 检查 bit 10
            let hasImpedance = (ctrlByte1 & (1 << 1)) != 0 // 检查 bit 14
            
            if let index1 = data.index(data.startIndex, offsetBy: 26, limitedBy: data.endIndex),
               let index2 = data.index(data.startIndex, offsetBy: 28, limitedBy: data.endIndex) {
                
                let substring1 = data[index1..<data.index(index1, offsetBy: 2)]
                let substring2 = data[index2..<data.index(index2, offsetBy: 2)]
                
                let value1 = Int(substring1, radix: 16)!
                let value2 = Int(substring2, radix: 16)!
                var measured = Double(value2 << 8 | value1) * 0.01 / 2
                

                let start = data.index(data.startIndex, offsetBy: 4)
                let end = data.index(start, offsetBy: 2)
                let measunit = String(data[start..<end])
                    
                let body_weight = String(format: "%.2f", measured)
                let miimpedance = "NaN"
                if hasImpedance{
                    let miimpedance = String((Int(byteArray[8]) << 8) + Int(byteArray[9])) // 提取阻抗值
                }
                
                let result = "\nisStabilized: \(isStabilized)\n" +
                "Measured: \(body_weight) kg\n" +
                "Impedance: \(miimpedance) ohm"
                return result
            }
            else{
                return "ERROR"
            }
        }
    }
    
    // SwiftUI view to display the app UI
    struct ContentView: View {
        @ObservedObject var bleManager = BLEManager()
        
        var body: some View {
            ZStack {
                //                Color(red: 0.68, green: 0.85, blue: 1).edgesIgnoringSafeArea(.all)
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    Spacer()
                    
                    // App title
                    Text("BLE Device Subscriber")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.label))
                    
                    // Status and Data display with visual enhancements
                    VStack {
                        // Display connection status
                        Text("Status: \(bleManager.statusMessage)")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.yellow.opacity(0.85))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        // Display received data
                        Text("Data: \(bleManager.receivedData)")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.black.opacity(0.55))
                            .padding()
                            .background(Color.green.opacity(0.55))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .frame(width: 300, height: 260)
                    }
                    .padding()
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
                    
                    // Start scanning button with 3D effect
                    Button(action: {
                        withAnimation {
                            bleManager.startScanning()
                        }
                    }) {
                        Text("Start Scanning")
                            .font(.title2)
                            .foregroundColor(.white)
                            .bold()
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(20)
                            .shadow(color: .blue, radius: 2, x: 2, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 1)
                                    .shadow(color: .white, radius: 2, x: -2, y: -2)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

enum blood_pressure_reciever {
    struct PersistenceController {
        static let shared = PersistenceController()
        
        static var preview: PersistenceController = {
            let result = PersistenceController(inMemory: true)
            let viewContext = result.container.viewContext
            for _ in 0..<10 {
                let newItem = Item(context: viewContext)
                newItem.timestamp = Date()
            }
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            return result
        }()
        
        let container: NSPersistentContainer
        
        init(inMemory: Bool = false) {
            container = NSPersistentContainer(name: "Dev")
            if inMemory {
                container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            }
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
    
    // BLEManager class is responsible for managing all Bluetooth Low Energy (BLE) operations,
    // including scanning for devices, connecting to peripherals, and handling data communication.
    class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
        // CBCentralManager instance to manage the Bluetooth operations
        var centralManager: CBCentralManager!
        // CBPeripheral instance representing the peripheral device that the app connects to
        var peripheral: CBPeripheral?
        
        // Published properties to notify the UI about status and data changes
        @Published var statusMessage = "Ready"
        @Published var receivedData = "Waiting for data..."
        
        // UUIDs for filtering devices and characteristics
        let deviceName = "RM_BPM"
        let characteristicUUIDs = [CBUUID(string: "00002a35-0000-1000-8000-00805f9b34fb")]
        
        // Initializer to set up the CBCentralManager instance
        override init() {
            super.init()
            centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        }
        
        // Function to start scanning for peripheral devices
        func startScanning() {
            if centralManager.state == .poweredOn {
                statusMessage = "Scanning..."
                // Delay the scanning process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.centralManager.scanForPeripherals(withServices: nil, options: nil)
                }
            } else {
                statusMessage = "Bluetooth is not ready."
            }
        }
        
        // Delegate method to handle updates in the Bluetooth state
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            switch central.state {
            case .poweredOn:
                statusMessage = "Bluetooth is On."
            case .poweredOff:
                statusMessage = "Bluetooth is Off."
            default:
                statusMessage = "Unknown Bluetooth status."
            }
        }
        
        // Delegate method to handle discovery of a peripheral device
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
            if peripheral.name != nil{
                print(peripheral.name!, peripheral.identifier.uuidString)
            }
            if peripheral.name == deviceName {
                self.peripheral = peripheral
                centralManager.stopScan()
                statusMessage = "Found device, connecting to \(peripheral.name ?? "")"
                // Delay the connection process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.centralManager.connect(peripheral, options: nil)
                }
            }
        }
        
        // Delegate method to handle successful connection to a peripheral device
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            statusMessage = "Connected to \(peripheral.name ?? "")"
            peripheral.delegate = self
            // Delay the service discovery process by 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                peripheral.discoverServices([CBUUID(string: "00001810-0000-1000-8000-00805f9b34fb")])
            }
        }
        
        // Delegate method to handle the discovery of services for a connected peripheral
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard let services = peripheral.services else { return }
            let interestedCharacteristicUUIDs = [CBUUID(string: "00002a35-0000-1000-8000-00805f9b34fb")]
            for service in services {
                statusMessage = ("Discovered service: \(service.uuid)")
                // Delay the characteristic discovery process by 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    peripheral.discoverCharacteristics(interestedCharacteristicUUIDs, for: service)
                }
            }
        }
        
        // Delegate method to handle the discovery of characteristics for a service
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            guard let characteristics = service.characteristics else { return }
            for characteristic in characteristics {
                statusMessage = ("Characteristic UUID: \(characteristic.uuid), properties: \(characteristic.properties)")
                print(characteristic.properties)
                if characteristic.properties.contains(.read) {
                    statusMessage = ("Characteristic \(characteristic.uuid) is readable")
                    peripheral.readValue(for: characteristic)
                } else if characteristic.properties.contains(.notify) {
                    statusMessage = ("Characteristic \(characteristic.uuid) supports notifications. Subscribing...")
                    peripheral.setNotifyValue(true, for: characteristic)
                }else if characteristic.properties.contains(.indicate) {
                    statusMessage = ("Characteristic \(characteristic.uuid) can be indicated")
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
        
        // Delegate method to handle updates in the value of a characteristic
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            if let value = characteristic.value, characteristic.uuid == CBUUID(string: "00002a35-0000-1000-8000-00805f9b34fb") {
                
                let hexString = value.map { String(format: "%02hhx", $0) }.joined()

                DispatchQueue.main.async {
                    if let convertedData = self.decodeBloodPressure(hexString: hexString) {
                        self.receivedData = String(convertedData)
                        self.statusMessage = "Received raw data: \(hexString)"
                    }
                    else {
                        self.statusMessage = "Error in processing data."
                    }
                }
            }
        }
        func convertStatusString(_ statusString: String) -> String {
            let components = statusString.split(separator: " ")
            var binaryString = ""
            for component in components {
                if let intValue = Int(component, radix: 16) {
                    let binaryValue = String(intValue, radix: 2)
                    let paddedBinaryValue = String(repeating: "0", count: 8 - binaryValue.count) + binaryValue
                    binaryString += paddedBinaryValue
                }
            }
            return binaryString
        }

        func timeDecode(timestampBytes: [UInt8]) -> String {
            guard timestampBytes.count >= 7 else {
                return "Invalid timestamp bytes"
            }
            let year = Int(timestampBytes[0]) + (Int(timestampBytes[1]) << 8)
            let month = Int(timestampBytes[2])
            let day = Int(timestampBytes[3])
            let hours = Int(timestampBytes[4])
            let minutes = Int(timestampBytes[5])
            let seconds = Int(timestampBytes[6])
            
            return "\(year)-\(month)-\(day) \(hours):\(minutes):\(seconds)"
        }
        func bloodPressureDecode(dataBytes: [UInt8]) -> String {
            let flags = dataBytes[0]
            let bit0Set = flags & 0b00000001 != 0
            let bit1Set = flags & 0b00000010 != 0
            let bit2Set = flags & 0b00000100 != 0
            let bit3Set = flags & 0b00001000 != 0
            let bit4Set = flags & 0b00010000 != 0
            
            let systolicMmHg = !bit0Set ? Int(dataBytes[1]) + (Int(dataBytes[2]) << 8) : 0
            let diastolicMmHg = !bit0Set ? Int(dataBytes[3]) + (Int(dataBytes[4]) << 8) : 0
            let meanArterialPressureMmHg = !bit0Set ? Int(dataBytes[5]) + (Int(dataBytes[6]) << 8) : 0
            let timestamp = bit1Set ? timeDecode(timestampBytes: Array(dataBytes[7..<14])) : ""
            let pulseRate = bit2Set ? Int(dataBytes[14]) + (Int(dataBytes[15]) << 8) : 0
            let userId = bit3Set ? Int(dataBytes[16]) : 0
            let measurementStatus = bit4Set ? "\(String(format: "%02x", dataBytes[17])) \(String(format: "%02x", dataBytes[16]))" : ""
            
            let result = """
                Systolic: \(systolicMmHg) mmHg
                Diastolic: \(diastolicMmHg) mmHg
                Pulse Rate: \(pulseRate)/min
                Mean Arterial Pressure: \(meanArterialPressureMmHg) mmHg
                Timestamp: \(timestamp)
                User ID: \(userId)
                Measurement Status: \(convertStatusString(measurementStatus))
                """

                return result
        }
        

        func decodeBloodPressure(hexString: String) -> String? {
            guard let data = Data(fromHexEncodedString: hexString) else {
                print("Invalid hex string")
                return nil
            }
            
            let byteArray = [UInt8](data)
            return bloodPressureDecode(dataBytes: byteArray)
        }
       
        
        
        
        // SwiftUI view to display the app UI
        
        
    }
    struct ContentView: View {
        @ObservedObject var bleManager = BLEManager()
        
        var body: some View {
            ZStack {
                //                Color(red: 0.68, green: 0.85, blue: 1).edgesIgnoringSafeArea(.all)
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    Spacer()
                    
                    // App title
                    Text("BLE Device Subscriber")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.label))
                    
                    // Status and Data display with visual enhancements
                    VStack {
                        // Display connection status
                        Text("Status: \(bleManager.statusMessage)")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.yellow.opacity(0.85))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        // Display received data
                        Text("Data: \(bleManager.receivedData)")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.black.opacity(0.55))
                            .padding()
                            .background(Color.green.opacity(0.55))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .frame(width: 320, height: 240)
                    }
                    .padding()
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
                    
                    // Start scanning button with 3D effect
                    Button(action: {
                        withAnimation {
                            bleManager.startScanning()
                        }
                    }) {
                        Text("Start Scanning")
                            .font(.title2)
                            .foregroundColor(.white)
                            .bold()
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(20)
                            .shadow(color: .blue, radius: 2, x: 2, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 1)
                                    .shadow(color: .white, radius: 2, x: -2, y: -2)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}
extension Data {
    init?(fromHexEncodedString string: String) {
        var hexString = string
        // 去掉可能存在的前綴 0x
        if hexString.hasPrefix("0x") {
            hexString = String(hexString.dropFirst(2))
        }

        guard hexString.count % 2 == 0 else { return nil }

        self.init(capacity: hexString.count / 2)

        var index = hexString.startIndex
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if let byte = UInt8(hexString[index..<nextIndex], radix: 16) {
                self.append(byte)
            } else {
                return nil
            }
            index = nextIndex
        }
    }
}
