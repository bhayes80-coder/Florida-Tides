//
//  LocationSearchView.swift
//  Florida Tides
//
//  Created by Barry Hayes on 10/8/25.
//

import SwiftUI
import MapKit
import Contacts

struct LocationSearchView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var tideService: NOAATideService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Location")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for a location", text: $locationService.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: locationService.searchText) { newValue, _ in
                            locationService.searchForLocations(newValue)
                        }
                }
                
                if locationService.isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Searching...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !locationService.searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(locationService.searchResults, id: \.self) { mapItem in
                                LocationRowView(mapItem: mapItem) {
                                    locationService.selectLocation(mapItem)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if let selectedLocation = locationService.selectedLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text(selectedLocation.displayName)
                        .font(.subheadline)
                    Spacer()
                    Button("Change") {
                        locationService.searchText = ""
                        locationService.searchResults = []
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

extension MKMapItem {
    var formattedAddress: String {
        if #available(iOS 26.0, *) {
            // Use new API for best format
            return self.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true) ?? ""
        } else {
            // Fallback to empty or legacy solutions
            return ""
        }
    }
}

struct LocationRowView: View {
    let mapItem: MKMapItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mapItem.name ?? "Unknown Location")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    if !mapItem.formattedAddress.isEmpty {
                        Text(mapItem.formattedAddress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LocationSearchView(
        locationService: LocationService(),
        tideService: NOAATideService()
    )
}

