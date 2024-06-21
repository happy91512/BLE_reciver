import SimpleTable
import SwiftUI



struct MonitorView: View {
    @State private var selectedTab = 0
    @State private var isLoginned = UserDefaults.standard.bool(forKey: "isLoggedIn")
    
    @FetchRequest(
        entity: BP_entity.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BP_entity.timestamp, ascending: true)
        ]
    ) var bpEntities: FetchedResults<BP_entity>
    
    @FetchRequest(
        entity: SPO2_entity.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \SPO2_entity.timestamp, ascending: true)
        ]
    ) var spo2Entities: FetchedResults<SPO2_entity>
    
    @FetchRequest(
        entity: Thermo_entity.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Thermo_entity.timestamp, ascending: true)
        ]
    ) var thermoEntities: FetchedResults<Thermo_entity>
    
    @FetchRequest(
        entity: Scale_entity.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Scale_entity.timestamp, ascending: true)
        ]
    ) var scaleEntities: FetchedResults<Scale_entity>
    
    let context = persistenceController.container.viewContext
    
    @State private var showBPData: [Bool] = Array(repeating: true, count: 5)
    @State private var showSPO2Data: [Bool] = Array(repeating: true, count: 3)
    @State private var showThermoData: [Bool] = Array(repeating: true, count: 2)
    @State private var showScaleData: [Bool] = Array(repeating: true, count: 4)


    var body: some View {
        NavigationView {
            if isLoginned {
                TabView(selection: $selectedTab) {
                    let BPEntities_c = convertToBPEntities(fetchedResults: bpEntities)
                    let BPDeviceData = convertToBPDeviceData(entities: BPEntities_c)
                    let BPColumn: [String] = ["Systolic", "Diastolic", "Mean Arterial Pressure", "Pulse Rate"]
                    VStack {
                        Text("血壓計")
                            .font(.title)
                            .bold()
                            
                        HStack {
                            Button(action: {
                                insertData()
                            }) {
                                Text("Add Data")
                            }
                            
                            Menu{
                                ForEach(0..<BPDeviceData.count, id: \.self) { index in
                                    HStack{
                                        Toggle(BPColumn[index], isOn: $showBPData[index])
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }label: {
                                Image(systemName: "ellipsis")
                                    .font(.largeTitle)
                            }
                            
                        }
                        
                        ScatterChartRepresentable(deviceData: BPDeviceData, showData: showBPData, ColumnName: BPColumn)
                            .edgesIgnoringSafeArea(.all)
                            .frame(minWidth: 400)
                        
                        List {
                            ScrollView(.horizontal){
                                Grid{
                                    GridRow {
                                        Text("時間")
                                        Text("舒張壓")
                                        Text("收縮壓")
                                        Text("平均動脈壓力")
                                        Text("心律")
                                        
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .bold()
                                    Divider()
                                    
                                    ForEach(bpEntities) { entity in
                                        GridRow {
                                            Text(entity.timestamp!)
                                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                            Text(entity.diastolic, format: .number)
                                            Text(entity.systolic, format: .number)
                                            Text(entity.mean_arterial_pressure, format: .number)
                                            Text(entity.pulse_rate, format: .number)
                                            Button(action: {
                                                deleteData(entity: entity)
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                        
                                        if entity != bpEntities.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .tag(0)
                    .tabItem {
                        Label("血壓計", systemImage: "1.circle")
                    }
                    let SPO2Entities_c = convertToSPO2Entities(fetchedResults: spo2Entities)
                    let SPO2DeviceData = convertToSPO2DeviceData(entities: SPO2Entities_c)
                    let SPO2Column: [String] = ["SPO2", "Pulse Rate"]
                    VStack {
                        Text("血氧計")
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .bold()
                        HStack {
                            Button(action: {
                                insertData()
                            }) {
                                Text("Add Data")
                            }
                            Menu{
                                ForEach(0..<SPO2DeviceData.count, id: \.self) { index in
                                    HStack{
                                        Toggle(SPO2Column[index], isOn: $showSPO2Data[index])
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }label: {
                                Image(systemName: "ellipsis")
                                    .font(.largeTitle)
                            }
                        }
                        ScatterChartRepresentable(deviceData: SPO2DeviceData, showData: showSPO2Data, ColumnName: SPO2Column)
                            .edgesIgnoringSafeArea(.all)
                            .frame(minWidth: 400)
                        List {
                            ScrollView(.horizontal){
                                Grid{
                                    GridRow {
                                        Text("時間")
                                        Text("血氧")
                                        Text("心律")
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .bold()
                                    Divider()
                                    ForEach(spo2Entities) { entity in
                                        GridRow {
                                            Text(entity.timestamp!)
                                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                            Text(entity.spo2, format: .number)
                                            Text(entity.pulse_rate, format: .number)
                                            Button(action: {
                                                deleteData(entity: entity)
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                        if entity != spo2Entities.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .tag(1)
                    .tabItem {
                        Label("血氧計", systemImage: "2.circle")
                    }
                    let thermoEntities_c = convertToThermoEntities(fetchedResults: thermoEntities)
                    let ThermoDeviceData = convertToThermoDeviceData(entities: thermoEntities_c)
                    let ThermoColumn: [String] = ["Temperature"]
                    VStack {
                        Text("體溫計")
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .bold()
                        HStack {
                            Button(action: {
                                insertData()
                            }) {
                                Text("Add Data")
                            }
                            
 
                        }
                        ScatterChartRepresentable(deviceData: ThermoDeviceData, showData: showThermoData, ColumnName: ThermoColumn)
                            .edgesIgnoringSafeArea(.all)
                            .frame(minWidth: 400)
                                    
                        List {
                            ScrollView(.horizontal){
                                Grid{
                                    GridRow {
                                        Text("時間")
                                        Text("溫度")
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .bold()
                                    Divider()
                                    ForEach(thermoEntities) { entity in
                                        GridRow {
                                            Text(entity.timestamp!)
                                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                            Text(entity.temperature, format: .number)
                                            Button(action: {
                                                deleteData(entity: entity)
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                        if entity != thermoEntities.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .tag(2)
                    .tabItem {
                        Label("體溫計", systemImage: "3.circle")
                    }
                    let scaleEntities_c = convertToScaleEntities(fetchedResults: scaleEntities
                    )
                    let scaleDeviceData = convertToScaleDeviceData(entities: scaleEntities_c)
                    let scaleColumn: [String] = ["Weight", "Impedence"]
                    VStack {
                        Text("體脂計")
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .bold()
                        HStack {
                            Button(action: {
                                insertData()
                            }) {
                                Text("Add Data")
                            }
                            Menu{
                                ForEach(0..<scaleDeviceData.count, id: \.self) { index in
                                    HStack{
                                        Toggle(scaleColumn[index], isOn: $showScaleData[index])
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }label: {
                                Image(systemName: "ellipsis")
                                    .font(.largeTitle)
                            }
                        }
                        LineChartRepresentable(deviceData: scaleDeviceData, showData: showScaleData, ColumnName: scaleColumn)
                            .edgesIgnoringSafeArea(.all)
                            .frame(minWidth: 400)
                        List {
                            ScrollView(.horizontal){
                                Grid{
                                    GridRow {
                                        Text("時間")
                                        Text("體重")
                                        Text("阻值")
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .bold()
                                    Divider()
                                    ForEach(scaleEntities) { entity in
                                        GridRow {
                                            Text(entity.timestamp!)
                                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                            Text(entity.weight, format: .number)
                                            Text(entity.impedence, format: .number)
                                            Button(action: {
                                                deleteData(entity: entity)
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                        if entity != scaleEntities.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .tag(3)
                    .tabItem {
                        Label("體脂計", systemImage: "4.circle")
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            } else {
                Text("Please loggin first!")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            isLoginned = UserDefaults.standard.bool(forKey: "isLoggedIn")
        }
    }
}


struct MultiplicationTableExample_Previews: PreviewProvider {
    static var previews: some View {
        MonitorView()
    }
}
