//
//  LocationService.swift
//  Florida Tides
//
//  Created by Barry Hayes on 10/8/25.
//

import Foundation
import MapKit
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [MKMapItem] = []
    @Published var selectedLocation: Location?
    @Published var isSearching = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchTask: Task<Void, Never>?
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func searchForLocations(_ query: String) {
        searchText = query
        
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                isSearching = true
            }
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918),
                span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
            )
            
            let search = MKLocalSearch(request: request)
            
            do {
                let response = try await search.start()
                await MainActor.run {
                    self.searchResults = response.mapItems
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                }
            }
        }
    }
    
    func selectLocation(_ mapItem: MKMapItem) {
        let coordinate = mapItem.location.coordinate
        let name = mapItem.name ?? "Unknown Location"
        
        // Call the fullAddress function with parameters
        let addressString = mapItem.formattedAddress
        let displayName = addressString.isEmpty ? name : "\(name), \(addressString)"
        
        let location = Location(
            name: displayName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            stationId: nil
        )
        
        selectedLocation = location
        searchText = location.displayName
        searchResults = []
    }

    
    func loadSavedLocation() {
        if let data = UserDefaults.standard.data(forKey: "savedLocation"),
           let location = try? JSONDecoder().decode(Location.self, from: data) {
            selectedLocation = location
            searchText = location.displayName
        }
    }
    
    func saveLocation() {
        guard let location = selectedLocation else { return }
        
        if let data = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(data, forKey: "savedLocation")
        }
    }
}

extension LocationService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // handled by searchForLocations()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
}

