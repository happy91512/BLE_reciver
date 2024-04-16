import SwiftUI
import Foundation

struct AccountView: View {
    @Binding var selectedTab: Int
    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var gender = 0
    @State private var errorMessage = ""
    @State private var isLoginned = UserDefaults.standard.bool(forKey: "isLoggedIn")

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
                TextField("Height(cm)", text: $height)
                    .keyboardType(.decimalPad)
                Picker(selection: $gender, label: Text("Gender")) {
                    Text("Male").tag(0)
                    Text("Female").tag(1)
                }
                Button(action: createAccount) {
                    Text("Create/Modify Account")
                }
                .navigationTitle("User Information")
                .alert(isPresented: Binding<Bool>(
                    get: { self.errorMessage != "" },
                    set: { if !$0 { self.errorMessage = "" } }
                )) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
            }
            
        }
        .navigationTitle("User Information")
       
        
    }
    
    func createAccount() {
        guard !name.isEmpty else {
            errorMessage = "Name cannot be empty."
            return
        }

        guard let ageValue = Int(age), (0...110).contains(ageValue) else {
            errorMessage = "Please enter a valid age between 0 and 110."
            return
        }

        guard let heightValue = Double(height), (50...250).contains(heightValue) else {
            errorMessage = "Please enter a valid height between 50 and 250."
            return
        }
        errorMessage = ""
        _ = gender == 0 ? "Male" : "Female"
        
        UserDefaults.standard.set(name, forKey: "UserName")
        UserDefaults.standard.set(ageValue, forKey: "UserAge")
        UserDefaults.standard.set(heightValue, forKey: "UserHeight")
        UserDefaults.standard.set(gender, forKey: "UserGender")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        isLoginned = true
        selectedTab = 0
    }
}

