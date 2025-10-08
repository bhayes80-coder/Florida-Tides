//
//  TideData.swift
//  Florida Tides
//
//  Created by Barry Hayes on 10/8/25.
//

import Foundation

struct TideData: Codable, Identifiable {
    let id: UUID
    let time: Date
    let height: Double
    let type: TideType
    
    enum TideType: String, Codable, CaseIterable {
        case high = "H"
        case low = "L"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, time, height, type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        time = try container.decode(Date.self, forKey: .time)
        height = try container.decode(Double.self, forKey: .height)
        type = try container.decode(TideType.self, forKey: .type)
    }
    
    init(id: UUID = UUID(), time: Date, height: Double, type: TideType) {
        self.id = id
        self.time = time
        self.height = height
        self.type = type
    }
}

struct Location: Codable, Identifiable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let stationId: String?
    
    var displayName: String {
        return name
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, stationId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        stationId = try container.decodeIfPresent(String.self, forKey: .stationId)
    }
}

struct TideResponse: Codable {
    let data: [TideDataPoint]
}

struct TideDataPoint: Codable {
    let t: String // time
    let v: String // value
    let type: String?
    
    var tideData: TideData? {
        guard let date = ISO8601DateFormatter().date(from: t),
              let height = Double(v) else {
            return nil
        }
        
        let tideType: TideData.TideType
        if let type = type, type == "H" {
            tideType = .high
        } else if let type = type, type == "L" {
            tideType = .low
        } else {
            // Determine type based on height comparison with nearby points
            tideType = .high // Default, will be corrected by algorithm
        }
        
        return TideData(time: date, height: height, type: tideType)
    }
}

