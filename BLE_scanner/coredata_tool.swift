//
//  coredata_tool.swift
//  BLE_scanner
//
//  Created by 邱泰銓 on 2024/4/23.
//

import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BLE_scanner")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

let persistenceController = PersistenceController.shared
struct BPStat: Identifiable, Equatable {
    let id = UUID()
    let Timestamp: String
    let Systolic: Int
    let Diastolic: Int
    let MeanArterialPressure: Int
    let PulseRate: Int
}
struct SPO2Stat: Identifiable, Equatable {
    let id = UUID()
    let Timestamp: String
    let SPO2: Int
    let PulseRate: Int
}
struct ThermoStat: Identifiable, Equatable {
    let id = UUID()
    let Timestamp: String
    let Temperature: Double
}
struct ScaleStat: Identifiable, Equatable {
    let id = UUID()
    let Timestamp: String
    let Weight: Double
    let Impedence: Double
}
let BPstats: [BPStat] = [
    BPStat(Timestamp: "2024-05-01 00:00:00", Systolic: 120, Diastolic: 70, MeanArterialPressure: 50, PulseRate: 65),
    BPStat(Timestamp: "2024-05-02 00:00:00", Systolic: 125, Diastolic: 72, MeanArterialPressure: 52, PulseRate: 68),
    BPStat(Timestamp: "2024-05-03 00:00:00", Systolic: 118, Diastolic: 68, MeanArterialPressure: 49, PulseRate: 63)
]

let SPO2stats: [SPO2Stat] = [
    SPO2Stat(Timestamp: "2024-05-01 00:00:00", SPO2: 95, PulseRate: 65),
    SPO2Stat(Timestamp: "2024-05-02 00:00:00", SPO2: 97, PulseRate: 68),
    SPO2Stat(Timestamp: "2024-05-03 00:00:00", SPO2: 96, PulseRate: 67)
]

let Thermostats: [ThermoStat] = [
    ThermoStat(Timestamp: "2024-05-01 00:00:00", Temperature: 36.5),
    ThermoStat(Timestamp: "2024-05-02 00:00:00", Temperature: 36.6),
    ThermoStat(Timestamp: "2024-05-03 00:00:00", Temperature: 36.7)
]

let Scalestats: [ScaleStat] = [
    ScaleStat(Timestamp: "2024-05-01 00:00:00", Weight: 70.2, Impedence: 1500.45),
    ScaleStat(Timestamp: "2024-05-02 00:00:00", Weight: 71.5, Impedence: 1550.60),
    ScaleStat(Timestamp: "2024-05-03 00:00:00", Weight: 72.0, Impedence: 1600.75)
]


func insertData() {
    let context = persistenceController.container.viewContext
    
    // Insert BP stats
    for bpStat in BPstats {
        let newBPData = BP_entity(context: context)
        newBPData.timestamp = bpStat.Timestamp
        newBPData.diastolic = Int16(bpStat.Diastolic)
        newBPData.mean_arterial_pressure = Int16(bpStat.MeanArterialPressure)
        newBPData.pulse_rate = Int16(bpStat.PulseRate)
        newBPData.systolic = Int16(bpStat.Systolic)
    }
    
    // Insert SPO2 stats
    for spo2Stat in SPO2stats {
        let newSPO2Data = SPO2_entity(context: context)
        newSPO2Data.timestamp = spo2Stat.Timestamp
        newSPO2Data.spo2 = Int16(spo2Stat.SPO2)
        newSPO2Data.pulse_rate = Int16(spo2Stat.PulseRate)
    }
    
    // Insert Thermo stats
    for thermoStat in Thermostats {
        let newThermoData = Thermo_entity(context: context)
        newThermoData.timestamp = thermoStat.Timestamp
        newThermoData.temperature = thermoStat.Temperature
    }
    
    // Insert Scale stats
    for scaleStat in Scalestats {
        let newScaleData = Scale_entity(context: context)
        newScaleData.timestamp = scaleStat.Timestamp
        newScaleData.weight = scaleStat.Weight
        newScaleData.impedence = scaleStat.Impedence
    }

    // Save changes
    do {
        try context.save()
    } catch {
        print("Error saving data: \(error)")
    }
}

func deleteData(entity: NSManagedObject) {
    let context = PersistenceController.shared.container.viewContext
    context.delete(entity)
    
    do {
        try context.save()
    } catch {
        print("Error deleting item: \(error.localizedDescription)")
    }
}

