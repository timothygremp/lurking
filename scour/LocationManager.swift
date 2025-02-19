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
        locationManager.distanceFilter = 10  // Only update