//
//  TideGraphView.swift
//  Florida Tides
//
//  Created by Barry Hayes on 10/8/25.
//

import SwiftUI
import Charts

struct TideGraphView: View {
    let tideData: [TideData]
    let currentHeight: Double?
    
    @State private var selectedTime: Date?
    
    // Computed property to get zoomed data showing current + one high/low on each side
    private var zoomedTideData: [TideData] {
        guard !tideData.isEmpty else { return tideData }
        
        let now = Date()
        let currentTime = now
        
        // Find the closest data point to current time
        let sortedByTime = tideData.sorted { abs($0.time.timeIntervalSince(currentTime)) < abs($1.time.timeIntervalSince(currentTime)) }
        guard let closestIndex = tideData.firstIndex(where: { $0.id == sortedByTime.first?.id }) else { return tideData }
        
        // Find high and low tides around current time
        let highs = tideData.enumerated().compactMap { index, tide in
            tide.type == .high ? (index: index, tide: tide) : nil
        }
        let lows = tideData.enumerated().compactMap { index, tide in
            tide.type == .low ? (index: index, tide: tide) : nil
        }
        
        // Find the closest high and low before current time
        let previousHigh = highs.last { $0.tide.time <= currentTime }
        let previousLow = lows.last { $0.tide.time <= currentTime }
        
        // Find the closest high and low after current time
        let nextHigh = highs.first { $0.tide.time > currentTime }
        let nextLow = lows.first { $0.tide.time > currentTime }
        
        // Collect all relevant indices
        var relevantIndices = Set<Int>()
        
        if let prevHigh = previousHigh { relevantIndices.insert(prevHigh.index) }
        if let prevLow = previousLow { relevantIndices.insert(prevLow.index) }
        if let nextHigh = nextHigh { relevantIndices.insert(nextHigh.index) }
        if let nextLow = nextLow { relevantIndices.insert(nextLow.index) }
        
        // Add some context points around current time
        let contextRange = 2
        for i in max(0, closestIndex - contextRange)...min(tideData.count - 1, closestIndex + contextRange) {
            relevantIndices.insert(i)
        }
        
        // Return sorted data
        return relevantIndices.sorted().compactMap { tideData.indices.contains($0) ? tideData[$0] : nil }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tide Chart")
                    .font(.headline)
                
                Text("Focused view around current time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if tideData.isEmpty {
                Text("No tide data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            } else {
                Chart {
                    // Draw the smooth curve for zoomed tide data
                    ForEach(zoomedTideData) { tide in
                        LineMark(
                            x: .value("Time", tide.time),
                            y: .value("Height", tide.height)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                    
                    // Mark high tides in zoomed data
                    ForEach(zoomedTideData.filter { $0.type == .high }) { tide in
                        PointMark(
                            x: .value("Time", tide.time),
                            y: .value("Height", tide.height)
                        )
                        .foregroundStyle(.red)
                        .symbolSize(100)
                    }
                    
                    // Mark low tides in zoomed data
                    ForEach(zoomedTideData.filter { $0.type == .low }) { tide in
                        PointMark(
                            x: .value("Time", tide.time),
                            y: .value("Height", tide.height)
                        )
                        .foregroundStyle(.green)
                        .symbolSize(100)
                    }
                    
                    // Current tide height indicator
                    if let currentHeight = currentHeight {
                        PointMark(
                            x: .value("Time", Date()),
                            y: .value("Height", currentHeight)
                        )
                        .foregroundStyle(.orange)
                        .symbolSize(150)
                        .symbol(.circle)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let height = value.as(Double.self) {
                                Text("\(height, specifier: "%.1f") ft")
                            }
                        }
                    }
                }
                .frame(height: 300)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("High Tide")
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Low Tide")
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                    Text("Current")
                        .font(.caption)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    TideGraphView(
        tideData: [
            TideData(time: Date().addingTimeInterval(-3600), height: 2.1, type: .low),
            TideData(time: Date().addingTimeInterval(-1800), height: 3.5, type: .high),
            TideData(time: Date(), height: 2.8, type: .low),
            TideData(time: Date().addingTimeInterval(1800), height: 4.2, type: .high),
            TideData(time: Date().addingTimeInterval(3600), height: 3.1, type: .low)
        ],
        currentHeight: 2.8
    )
}
