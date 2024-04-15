//
//  ScanningStationViewModel.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import Foundation

/// View model responsible for managing scanning stations.
class ScanningStationViewModel: ObservableObject {
    static let shared: ScanningStationViewModel = {
        let instance = ScanningStationViewModel()
        // Start fetching stations as soon as the instance is accessed
        Task {
            await instance.fetchStations()
        }
        return instance
    }()
    
    // MARK: - Properties
    
    /// Published property for the list of stations.
    @Published var stations = [ScanningStation]() {
        didSet {
            print("Stations updated at \(Date()): \(stations.map { $0.name })")
        }
    }
    
    /// Tracks the currently selected station.
    @Published var selectedStation: ScanningStation? {
        didSet {
            print("Selected station changed to: \(String(describing: selectedStation?.name))")
        }
    }
    
    // MARK: - Initialization
    
    /// Initializes the view model with an optional initial list of stations.
    /// - Parameter stations: An optional array of `ScanningStation` objects representing scanning stations.
    init(stations: [ScanningStation] = []) {
        self.stations = stations
    }
    
    // MARK: - Public Methods
    
    /// Fetches scanning stations from the backend asynchronously.
    func fetchStations() async {
        // Endpoint URL for fetching scanning stations
        guard let url = URL(string: "https://prod-89.westeurope.logic.azure.com:443/workflows/599922b823604bbabf699b4565d23685/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=2B_Y4DPyYhRXSeSi1CusPeUci39MVcDZ04N9whOsxrg") else {
            print("Invalid URL")
            return
        }
        
        // Attempt to fetch data from the URL
        do {
            // Perform the URL request asynchronously
            let (data, _) = try await URLSession.shared.data(from: url)
            // Decode the received data into an array of ScanningStation objects
            let decodedStations = try JSONDecoder().decode([ScanningStation].self, from: data)
            // Update the stations array on the main thread
            DispatchQueue.main.async {
                self.stations = decodedStations
            }
            // Output the count of received stations for debugging
            print(decodedStations.count)
            print("Received \(decodedStations.count) stations.")
        } catch {
            // Handle errors that occurred during fetching and decoding
            print("Error fetching stations: \(error.localizedDescription)")
        }
    }
    
    /// Selects a scanning station.
    /// - Parameter station: The scanning station to select.
    func selectStation(_ station: ScanningStation) {
        selectedStation = station
    }
}
