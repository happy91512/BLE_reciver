import Foundation
import DGCharts
import SwiftUI

struct ScatterChartRepresentable: UIViewRepresentable {
    var deviceData: [(testData: [String], unitsSold: [Double], color: Color, shape: ScatterChartDataSet.Shape)]
    var showData: [Bool]
    var ColumnName: [String]

    func makeUIView(context: Context) -> ScatterChartView {
        let scatterChartView = ScatterChartView()
        setChart(scatterChartView: scatterChartView)
        scatterChartView.animate(xAxisDuration: 1.5, easingOption: .easeInCirc)
        return scatterChartView
    }

    func updateUIView(_ uiView: ScatterChartView, context: Context) {
        setChart(scatterChartView: uiView)
    }

    private func setChart(scatterChartView: ScatterChartView) {
        var dataSets: [ScatterChartDataSet] = []

        for (index, data) in deviceData.enumerated() {
            if showData[index] {
                var dataEntries: [ChartDataEntry] = []
                for i in 0..<data.testData.count {
                    let dataEntry = ChartDataEntry(x: Double(i), y: data.unitsSold[i])
                    dataEntries.append(dataEntry)
                }
                let chartDataSet = ScatterChartDataSet(entries: dataEntries, label: ColumnName[index])
                chartDataSet.setScatterShape(data.shape)
                chartDataSet.scatterShapeSize = 10.0
                chartDataSet.setColor(UIColor(data.color))
                dataSets.append(chartDataSet)
            }
        }

        let chartData = ScatterChartData(dataSets: dataSets)
        scatterChartView.data = chartData

        scatterChartView.rightAxis.enabled = false
        scatterChartView.xAxis.labelPosition = .bottom
        if !deviceData.isEmpty {
            scatterChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: deviceData[0].testData)
        }
        scatterChartView.xAxis.granularity = 1
        scatterChartView.xAxis.labelRotationAngle = -45
    }
}

struct LineChartRepresentable: UIViewRepresentable {
    var deviceData: [(testData: [String], unitsSold: [Double], color: Color, shape: ScatterChartDataSet.Shape)]
    var showData: [Bool]
    var ColumnName: [String]

    func makeUIView(context: Context) -> LineChartView {
        let lineChartView = LineChartView()
        setChart(lineChartView: lineChartView)
        lineChartView.animate(xAxisDuration: 1.5, easingOption: .easeInCirc)
        return lineChartView
    }

    func updateUIView(_ uiView: LineChartView, context: Context) {
        setChart(lineChartView: uiView)
    }

    private func setChart(lineChartView: LineChartView) {
        var dataSets: [LineChartDataSet] = []

        for (index, data) in deviceData.enumerated() {
            if showData[index] {
                var dataEntries: [ChartDataEntry] = []
                for i in 0..<data.testData.count {
                    let dataEntry = ChartDataEntry(x: Double(i), y: data.unitsSold[i])
                    dataEntries.append(dataEntry)
                }
                let chartDataSet = LineChartDataSet(entries: dataEntries, label: ColumnName[index])
                chartDataSet.setColor(UIColor(data.color))
                chartDataSet.setCircleColor(UIColor(data.color))
                chartDataSet.circleRadius = 5.0
                chartDataSet.lineWidth = 2.0
                dataSets.append(chartDataSet)
            }
        }

        let chartData = LineChartData(dataSets: dataSets)
        lineChartView.data = chartData

        lineChartView.rightAxis.enabled = false
        lineChartView.xAxis.labelPosition = .bottom
        if !deviceData.isEmpty {
            lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: deviceData[0].testData)
        }
        lineChartView.xAxis.granularity = 1
        lineChartView.xAxis.labelRotationAngle = -45
    }
}

struct ThermoEntity: Identifiable {
    let id = UUID()
    let timestamp: String
    let temperature: Double
}

struct BPEntity: Identifiable{
    let id = UUID()
    let timestamp: String
    let systolic: Int
    let diastolic: Int
    let meanArterialPressure: Int
    let pulseRate: Int
}

struct SPO2Entity: Identifiable{
    let id = UUID()
    let timestamp: String
    let spo2: Int
    let pulseRate: Int
}

struct ScaleEntity: Identifiable{
    let id = UUID()
    let timestamp: String
    let weight: Double
    let impedence: Double
}


func convertToThermoEntities(fetchedResults: FetchedResults<Thermo_entity>) -> [ThermoEntity] {
    return fetchedResults.map { entity in
        ThermoEntity(timestamp: entity.timestamp ?? "", temperature: entity.temperature)
    }
}

func convertToBPEntities(fetchedResults: FetchedResults<BP_entity>) -> [BPEntity] {
    return fetchedResults.map { entity in
        BPEntity(timestamp: entity.timestamp ?? "", systolic: Int(entity.systolic), diastolic: Int(entity.diastolic), meanArterialPressure: Int(entity.mean_arterial_pressure), pulseRate: Int(entity.pulse_rate))
    }
}

func convertToSPO2Entities(fetchedResults: FetchedResults<SPO2_entity>) -> [SPO2Entity] {
    return fetchedResults.map { entity in
        SPO2Entity(timestamp: entity.timestamp ?? "", spo2: Int(entity.spo2), pulseRate: Int(entity.pulse_rate))
    }
}

func convertToScaleEntities(fetchedResults: FetchedResults<Scale_entity>) -> [ScaleEntity] {
    return fetchedResults.map { entity in
        ScaleEntity(timestamp: entity.timestamp ?? "", weight: entity.weight, impedence: entity.impedence)
    }
}

func convertToThermoDeviceData(entities: [ThermoEntity]) -> [(testData: [String], unitsSold: [Double], color: Color, shape: ScatterChartDataSet.Shape)] {
    let timestamps = entities.map { $0.timestamp }
    let temperatures = entities.map { $0.temperature }

    return [
        (testData: timestamps, unitsSold: temperatures, color: .blue, shape: .circle)
    ]
}

func convertToBPDeviceData(entities: [BPEntity]) -> [(testData: [String], unitsSold: [Double], color: Color, shape: ScatterChartDataSet.Shape)] {
    let timestamps = entities.map { $0.timestamp }
    let systolicValues = entities.map { Double($0.systolic) }
    let diastolicValues = entities.map { Double($0.diastolic) }
    let meanArterialPressure = entities.map { Double($0.meanArterialPressure) }
    let pulseRate = entities.map { Double($0.pulseRate) }
    

    return [
        (testData: timestamps, unitsSold: systolicValues, color: .blue, shape: .circle),
        (testData: timestamps, unitsSold: diastolicValues, color: .red, shape: .cross),
        (testData: timestamps, unitsSold: meanArterialPressure, color: .brown, shape: .square),
        (testData: timestamps, unitsSold: pulseRate, color: .cyan, shape: .triangle)
    ]
}

func convertToSPO2DeviceData(entities: [SPO2Entity]) -> [(testData: [String], unitsSold: [Double], color: Color, shape: ScatterChartDataSet.Shape)] {
    let timestamps = entities.map { $0.timestamp }
    let spo2 = entities.map { Double($0.spo2) }
    let pulseRate = entities.map { Double($0.pulseRate) }

    return [
        (testData: timestamps, unitsSold: spo2, color: .blue, shape: .circle),
        (testData: timestamps, unitsSold: pulseRate, color: .red, shape: .cross)
    ]
}

func convertToScaleDeviceData(entities: [ScaleEntity]) -> [(testData: [String], unitsSold: [Double], color: Color, shape: ScatterChartDataSet.Shape)] {
    let timestamps = entities.map { $0.timestamp }
    let weight = entities.map { $0.weight }
    let impedence = entities.map { $0.impedence }

    return [
        (testData: timestamps, unitsSold: weight, color: .blue, shape: .circle),
        (testData: timestamps, unitsSold: impedence, color: .red, shape: .cross)
    ]
}







