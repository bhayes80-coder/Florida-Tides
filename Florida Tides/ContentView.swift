//
//  ContentView.swift
//  Florida Tides
//
//  Created by Barry Hayes on 10/8/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TideViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Florida Tides")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Real-time tide information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Location Search
                    LocationSearchView(
                        locationService: viewModel.getLocationService(),
                        tideService: NOAATideService()
                    )
                    
                    // Current Tide Info
                    if let currentHeight = viewModel.currentTideHeight {
                        VStack(spacing: 12) {
                            Text("Current Tide Height")
                                .font(.headline)
                            
                            HStack {
                                Text("\(currentHeight, specifier: "%.2f")")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.blue)
                                
                                Text("feet")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let location = viewModel.selectedLocation {
                                Text("at \(location.displayName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Tide Chart
                    if !viewModel.tideData.isEmpty {
                        TideGraphView(
                            tideData: viewModel.tideData,
                            currentHeight: viewModel.currentTideHeight
                        )
                    }
                    
                    // Loading and Error States
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading tide data...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .font(.title2)
                            
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                viewModel.refreshTideData()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Instructions
                    if viewModel.tideData.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                        VStack(spacing: 12) {
                            Image(systemName: "location.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("Select a location to view tide information")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("Search for a location above to get started with real-time tide data and predictions.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                viewModel.refreshTideData()
            }
        }
    }
}

#Preview {
    ContentView()
}
