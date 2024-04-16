import SwiftUI
import CoreGraphics
import CoreBluetooth

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MeasureView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Measurement")
                }
                .tag(0)


            MonitorView()
                .tabItem {
                    Image(systemName: "display")
                    Text("Monitor")
                }
                .tag(1)

            AccountView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "person")
                    Text("Account")
                }
                .tag(2)
        }
    }
}


//struct AccountView: View {
//    var body: some View {
//        Text("Account Page")
//    }
//}







    
    

