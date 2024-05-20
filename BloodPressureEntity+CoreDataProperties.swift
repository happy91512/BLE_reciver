//
//  BloodPressureEntity+CoreDataProperties.swift
//  BLE_scanner
//
//  Created by 邱泰銓 on 2024/4/22.
//
//

import Foundation
import CoreData


extension BloodPressureEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BloodPressureEntity> {
        return NSFetchRequest<BloodPressureEntity>(entityName: "BloodPressureEntity")
    }

    @NSManaged public var user_id: Int16
    @NSManaged public var systolic_mmHg: Int16
    @NSManaged public var diastolic_mmHg: Int16
    @NSManaged public var mean_arterial_pressure: Int16
    @NSManaged public var pulse_rate: Int16
    @NSManaged public var timestamp: String?

}

extension BloodPressureEntity : Identifiable {

}
