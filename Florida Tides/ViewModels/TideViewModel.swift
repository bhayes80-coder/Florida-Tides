//
//  TideViewModel.swift
//  Florida Tides
//
//  Created by Barry Hayes on 10/8/25.
//

import Foundation
import CoreLocation
import Combine

class TideViewModel: ObservableObject {
    @Published var tideData: [TideData] = []
    @Published var currentTideHeight: Double?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedLocation: Location?
    
    private let tideService = NOAATideService()
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadSavedLocation()
    }
    
    private func setupBindings() {
        // Listen for location changes
        locationService.$selectedLocation
            .sink { [weak self] location in
                self?.selectedLocation = location
                if let location = location {
                    self?.fetchTideData(for: location)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadSavedLocation() {
        locationService.loadSavedLocation()
        selectedLocation = locationService.selectedLocation
    }
    
    func fetchTideData(for location: Location) {
        guard let stationId = location.stationId else {
            // If no station ID, try to find nearby stations
            Task {
                await findAndSetNearestStation(for: location)
            }
            return
        }
        
        Task {
            await performTideDataFetch(stationId: stationId)
        }
    }
    
    private func findAndSetNearestStation(for location: Location) async {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        do {
            let stations = try await tideService.searchStations(near: clLocation)
            if let nearestStation = stations.first {
                var updatedLocation = location
                updatedLocation = Location(
                    name: location.name,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    stationId: nearestStation.stationId
                )
                
                await MainActor.run {
                    self.selectedLocation = updatedLocation
                    self.locationService.selectedLocation = updatedLocation
                    self.locationService.saveLocation()
                }
                
                await performTideDataFetch(stationId: nearestStation.stationId ?? "")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to find tide station: \(error.localizedDescription)"
            }
        }
    }
    
    private func performTideDataFetch(stationId: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let data = try await tideService.fetchTideData(for: stationId)
            
            await MainActor.run {
                self.tideData = data
                self.currentTideHeight = self.calculateCurrentTideHeight(from: data)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch tide data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func calculateCurrentTideHeight(from data: [TideData]) -> Double? {
        let now = Date()
        
        // Find the two closest data points to current time
        let sortedData = data.sorted { abs($0.time.timeIntervalSince(now)) < abs($1.time.timeIntervalSince(now)) }
        
        guard sortedData.count >= 2 else {
            return sortedData.first?.height
        }
        
        let point1 = sortedData[0]
        let point2 = sortedData[1]
        
        // Linear interpolation between the two points
        let timeDiff = point2.time.timeIntervalSince(point1.time)
        let currentTimeDiff = now.timeIntervalSince(point1.time)
        
        guard timeDiff != 0 else {
            return point1.height
        }
        
        let ratio = currentTimeDiff / timeDiff
        let heightDiff = point2.height - point1.height
        
        return point1.height + (heightDiff * ratio)
    }
    
    func getLocationService() -> LocationService {
        return locationService
    }
    
    func refreshTideData() {
        guard let location = selectedLocation else { return }
        fetchTideData(for: location)
    }
}

// Extension to make Location conform to Equatable for proper binding
extension Location: Equatable {
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id
    }
}
