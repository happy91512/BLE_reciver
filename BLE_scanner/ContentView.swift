import SwiftUI
import CoreGraphics
import CoreBluetooth
import Lottie

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isAnimationCompleted = false
    
    let persistenceController = PersistenceController.shared
    
    var body: some View {
        ZStack {
            if !isAnimationCompleted {
                VStack{
                    LottieView(animation: .named("loading2"))
                        .playing(loopMode: .loop)
                        .frame(width: 400, height: 400)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    isAnimationCompleted = true
                                }
                            }
                        }
                    Text("Loading...")
                        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .bold()
                }
            } else {
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
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)

                    AccountView(selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: "person")
                            Text("Account")
                        }
                        .tag(2)
                }
            }
        }
    }
}



//struct AccountView: View {
//    var body: some View {
//        Text("Account Page")
//    }
//}







    
    

