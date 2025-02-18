import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        // Initialize authorization status before super.init
        if #available(iOS 14.0, *) {
            authorizationStatus = CLLocationManager().authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        super.init()
        
        print("LocationManager: Initializing with status \(authorizationStatus.rawValue)")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Add these lines to reduce update frequency
        locationManager.distanceFilter = 10  // Only update if moved more than 10 meters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Request authorization if not determined
        if authorizationStatus == .notDetermined {
            print("LocationManager: Requesting authorization")
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("LocationManager: Already authorized, starting updates")
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let newStatus = manager.authorizationStatus
            print("LocationManager: Authorization changed from \(self.authorizationStatus.rawValue) to \(newStatus.rawValue)")
            self.authorizationStatus = newStatus
            
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                print("LocationManager: Starting location updates")
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only update if the new location is significantly different
        if let currentLocation = self.location {
            let distance = location.distance(from: currentLocation)
            if distance < 5 { // Less than 5 meters difference
                return
            }
        }
        
        print("LocationManager: Location updated: \(location.coordinate)")
        DispatchQueue.main.async { [weak self] in
            self?.location = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Failed with error: \(error.localizedDescription)")
        if let clError = error as? CLError {
            print("LocationManager: CLError code: \(clError.code.rawValue)")
        }
    }
} 