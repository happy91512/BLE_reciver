import SwiftUI
import CoreGraphics
import CoreBluetooth

struct MeasureView: View {
    @Binding var selectedTab: Int
    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var gender = 0
    @State private var isLoginned = UserDefaults.standard.bool(forKey: "isLoggedIn")
    @State private var errorMessage = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoginned {
                    DeviceTypeSelectView(selectedTab: $selectedTab, name: $name, age: $age, height: $height, gender: $gender, isLoginned: $isLoginned)
                } else {
                    Text("Please loggin first!")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Fill the entire screen
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            isLoginned = UserDefaults.standard.bool(forKey: "isLoggedIn")
        }
    }
}

struct DeviceTypeSelectView: View {
    @Binding var selectedTab: Int
    @Binding var name: String
    @Binding var age: String
    @Binding var height: String
    @Binding var gender: Int
    @Binding var isLoginned: Bool
    @State private var isNavigatingToContentView = false
    @Environment(\.presentationMode) var presentationMode
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    let devices = ["Blood Oxygen Monitor", "Forehead Thermometer", "Body Fat Calculator", "Blood Pressure Monitor"]
    
    var body: some View {
        NavigationView {
            VStack{
                HStack{
                    Text("User：\(UserDefaults.standard.string(forKey: "UserName")!.description)")
                    Button(action: {
                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
                        selectedTab = 2}){
                        Text("Logout")
                    }
                }
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                        ForEach(devices, id: \.self) { device in
                            DeviceReceiveView(device_type: device)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Device Selection")
        }
        .background(Color.clear)
    }
    func back2UserInfo() {
           isNavigatingToContentView = true
    }
}

struct DeviceReceiveView: View {
    let device_type: String
    var body: some View {
        VStack {
            NavigationLink(destination: DeviceModelView(device_type: device_type)) {
                VStack{
                    Image(device_type)
                        .resizable()
                        .scaledToFit()
                    Text(device_type)
                        .padding()
                }
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct DeviceModelView: View {
    let device_type: String
    @State private var selectedDevice: String?
    
    var device_list: [String] {
        switch device_type {
        case "Body Fat Calculator":
            return ["XiaoMi scale 2", "scale2", "scale3", "scale4", "scale5", "scale6"]
        case "Blood Pressure Monitor":
            return ["Rossmax X3", "PressureMonitor2", "PressureMonitor3"]
        case "Blood Oxygen Monitor":
            return ["Rossmax SB210", "OxygenMonitor2", "OxygenMonitor3"]
        case "Forehead Thermometer":
            return ["Rossmax HC700", "Thermometer2", "Thermometer3"]
            
        default:
            return [""]
        }
    }
    
    var body: some View {
        HStack{
            Spacer(minLength: 20)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(device_list, id: \.self) { item in
                        NavigationLink(destination: ReceiveView(deviceName: item)) {
                            VStack{
                                Image(device_type)
                                    .resizable()
                                    .scaledToFit()
                                Text(item)
                                    .padding()
                            }
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .onTapGesture {
                            selectedDevice = item
                        }
                    }
                }
            }
            Spacer(minLength: 20)
        }
    }
}


struct ReceiveView: View {
    let deviceName: String
    let persistenceController = BLE_scanner.thermometer_reciever.PersistenceController.shared
    var body: some View {
        switch deviceName {
        case "Rossmax HC700":
            thermometer_reciever.ContentView()
                .environment(\.managedObjectContext, thermometer_reciever.PersistenceController.shared.container.viewContext)
        case "Rossmax SB210":
            OP_reciever.ContentView()
                .environment(\.managedObjectContext, OP_reciever.PersistenceController.shared.container.viewContext)
        case "XiaoMi scale 2":
            scale_reciever.ContentView()
                .environment(\.managedObjectContext, scale_reciever.PersistenceController.shared.container.viewContext)
        case "Rossmax X3":
            blood_pressure_reciever.ContentView()
                .environment(\.managedObjectContext, blood_pressure_reciever.PersistenceController.shared.container.viewContext)
        default:Text("Device not supported")
        }
    }
}
