//
//  HealthKitView.swift
//  BLE_scanner
//
//  Created by 邱泰銓 on 2024/7/6.
//

import Foundation
import SwiftUI
import HealthKit

struct HealthKitView: View {
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        VStack {
            Button(action: {
                saveHeartRateData()
            }) {
                Text("Save Heart Rate Data")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .onAppear {
            healthKitManager.requestAuthorization { success, error in
                if success {
                    print("HealthKit authorization granted")
                } else {
                    print("HealthKit authorization denied")
                }
            }
        }
    }

    private func saveHeartRateData() {
        // Replace with actual heart rate value
        let heartRate = 72.0
        healthKitManager.saveHeartRate(heartRate: heartRate) { success, error in
            if success {
                print("Heart rate data saved successfully")
            } else {
                print("Failed to save heart rate data: \(String(describing: error))")
            }
        }
    }
}

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }

        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let typesToShare: Set = [heartRateType]
        let typesToRead: Set = [heartRateType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            completion(success, error)
        }
    }

    func saveHeartRate(heartRate: Double, date: Date = Date(), completion: @escaping (Bool, Error?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: heartRate)
        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, start: date, end: date)

        healthStore.save(heartRateSample) { success, error in
            completion(success, error)
        }
    }
}
