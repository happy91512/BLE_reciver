import Foundation
import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift


struct FireStoreView: View {
    @StateObject private var viewModel = MedicalDataViewModel()
    @State private var selectedDeviceType: DeviceType = .bloodPressure

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Device Type", selection: $selectedDeviceType) {
                    Text("Blood Pressure").tag(DeviceType.bloodPressure)
                    Text("SPO2").tag(DeviceType.SPO2)
                    Text("Thermometer").tag(DeviceType.thermometer)
                    Text("Scale").tag(DeviceType.scale)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                Button(action: {
                    switch selectedDeviceType {
                    case .bloodPressure:
                        let now = Date()
                        let bpData = bloodPressure(diastolic: 80, systolic: 120, meanArterialPressure: 100, pulseRate: 70, timestamp: now)
                        createMedicalRecord(deviceType: .bloodPressure, deviceData: bpData)
                    case .SPO2:
                        let now = Date()
                        let spo2Data = SPO2(SPO2: 98, pulseRate: 70, timestamp: now)
                        createMedicalRecord(deviceType: .SPO2, deviceData: spo2Data)
                    case .thermometer:
                        let now = Date()
                        let thermometerData = thermometer(temperature: 36.5, timestamp: now)
                        createMedicalRecord(deviceType: .thermometer, deviceData: thermometerData)
                    case .scale:
                        let now = Date()
                        let scaleData = scale(weight: 70.0, impedence: 1400.0, timestamp: now)
                        createMedicalRecord(deviceType: .scale, deviceData: scaleData)
                    }
                }) {
                    Text("Add Data")
                }
                
                Button(action: {
                    viewModel.fetchAllData()
//                    switch selectedDeviceType {
//                    case .bloodPressure:
//                        viewModel.fetchData(deviceType: .bloodPressure, dataType: bloodPressure.self)
//                    case .SPO2:
//                        viewModel.fetchData(deviceType: .SPO2, dataType: SPO2.self)
//                    case .thermometer:
//                        viewModel.fetchData(deviceType: .thermometer, dataType: thermometer.self)
//                    case .scale:
//                        viewModel.fetchData(deviceType: .scale, dataType: scale.self)
//                    }
                }) {
                    Text("Fetch Data")
                }
                       
                List {
                    switch selectedDeviceType {
                    case .bloodPressure:
                        ForEach(viewModel.bloodPressureData.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                Text("Diastolic: \(viewModel.bloodPressureData[index].diastolic)")
                                Text("Systolic: \(viewModel.bloodPressureData[index].systolic)")
                                Text("Mean Arterial Pressure: \(viewModel.bloodPressureData[index].meanArterialPressure)")
                                Text("Pulse Rate: \(viewModel.bloodPressureData[index].pulseRate)")
                                Text("Timestamp: \(viewModel.bloodPressureData[index].timestamp)")
                            }
                        }
                    case .SPO2:
                        ForEach(viewModel.spo2Data.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                Text("SPO2: \(viewModel.spo2Data[index].SPO2)")
                                Text("Pulse Rate: \(viewModel.spo2Data[index].pulseRate)")
                                Text("Timestamp: \(viewModel.spo2Data[index].timestamp)")
                            }
                        }
                    case .thermometer:
                        ForEach(viewModel.thermometerData.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                Text("Temperature: \(viewModel.thermometerData[index].temperature)")
                                Text("Timestamp: \(viewModel.thermometerData[index].timestamp)")
                            }
                        }
                    case .scale:
                        ForEach(viewModel.scaleData.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                Text("Weight: \(viewModel.scaleData[index].weight)")
                                Text("Impedance: \(viewModel.scaleData[index].impedence)")
                                Text("Timestamp: \(viewModel.scaleData[index].timestamp)")
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Firestore Testing")
        }
    }
}

struct TryView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



func createMedicalRecord<T: Codable>(deviceType: DeviceType, deviceData: T) {
    let db = Firestore.firestore()
    do {
        let deviceRef = try db.collection(deviceType.rawValue).addDocument(from: deviceData)
        print("\(deviceType.rawValue.capitalized) document ID: \(deviceRef.documentID)")
    } catch {
        print(error)
    }
}


class MedicalDataViewModel: ObservableObject {
    @Published var bloodPressureData: [bloodPressure] = []
    @Published var spo2Data: [SPO2] = []
    @Published var thermometerData: [thermometer] = []
    @Published var scaleData: [scale] = []
    init() {
            fetchAllData()
        }

    func fetchAllData() {
        fetchData(deviceType: .bloodPressure, dataType: bloodPressure.self)
        fetchData(deviceType: .SPO2, dataType: SPO2.self)
        fetchData(deviceType: .thermometer, dataType: thermometer.self)
        fetchData(deviceType: .scale, dataType: scale.self)
    }
    func fetchData<T: Codable>(deviceType: DeviceType, dataType: T.Type) {
        let db = Firestore.firestore()
        db.collection(deviceType.rawValue).getDocuments { snapshot, error in
            guard let snapshot = snapshot else {
                if let error = error {
                    print("Error getting documents: \(error)")
                }
                return
            }

            let data = snapshot.documents.compactMap { document in
                try? document.data(as: dataType)
            }

            DispatchQueue.main.async {
                switch deviceType {
                case .bloodPressure:
                    if let bpData = data as? [bloodPressure] {
                        self.bloodPressureData = bpData
                    }
                case .SPO2:
                    if let spo2Data = data as? [SPO2] {
                        self.spo2Data = spo2Data
                    }
                case .thermometer:
                    if let thermometerData = data as? [thermometer] {
                        self.thermometerData = thermometerData
                    }
                case .scale:
                    if let scaleData = data as? [scale] {
                        self.scaleData = scaleData
                    }
                }
            }
        }
    }
}

struct bloodPressure: Codable{
    let diastolic: Int
    let systolic: Int
    let meanArterialPressure: Int
    let pulseRate: Int
    let timestamp: Date
}

struct SPO2: Codable {
    let SPO2: Int
    let pulseRate: Int
    let timestamp: Date
}

struct thermometer: Codable {
    let temperature: Double
    let timestamp: Date
}

struct scale: Codable {
    let weight: Double
    let impedence: Double
    let timestamp: Date
}

enum DeviceType: String {
    case bloodPressure
    case SPO2
    case thermometer
    case scale
}
