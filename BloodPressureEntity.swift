//
//  BloodPressureEntity.swift
//  BLE_scanner
//
//  Created by 邱泰銓 on 2024/4/22.
//
//

import Foundation
import SwiftData


@Model public class BloodPressureEntity {
    var user_id: Int16? = 0
    var systolic_mmHg: Int16? = 0
    var diastolic_mmHg: Int16? = 0
    var mean_arterial_pressure: Int16? = 0
    var pulse_rate: Int16? = 0
    var timestamp: String?
    public init() {

    }
    
}
