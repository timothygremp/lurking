//
//  ContentView.swift
//  scour
//
//  Created by Alaryce Patterson on 2/14/25.
//

import SwiftUI
import MapKit
import CoreLocation

// Update the existing Offender struct
struct Offender: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let type: MarkerType
    // Add new properties
    let name: String
    let gender: String
    let age: Int
    let address: String
    let fullAddress: String
    let offenderUri: String
    
    enum MarkerType {
        case offender
        case search
    }
    
    init(id: UUID = UUID(),
         coordinate: CLLocationCoordinate2D,
         type: MarkerType = .offender,
         name: String = "",
         gender: String = "",
         age: Int = 0,
         address: String = "",
         fullAddress: String = "",
         offenderUri: String = "") {
        self.id = id
        self.coordinate = coordinate
        self.type = type
        self.name = name
        self.gender = gender
        self.age = age
        self.address = address
        self.fullAddress = fullAddress
        self.offenderUri = offenderUri
    }
    
    static func searchMarker(coordinate: CLLocationCoordinate2D) -> Offender {
        Offender(coordinate: coordinate, type: .search)
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var showingSearchSheet = false
    @State private var selectedDistance: String = "0.5"  // Change default to "0.5"
    @State private var region = MKCoordinateRegion(
        // Start with a wider view of US
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    @StateObject private var offenderService = OffenderService()
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    // Update offenders to use the service's data
    var offenders: [Offender] {
        offenderService.offenders
    }
    
    // Add these state variables inside ContentView
    @State private var showingOffenderDetail = false
    @State private var selectedOffender: Offender?
    
    // Add this gesture state
    @GestureState private var dragOffset = CGSize.zero
    @State private var dismissOffset = CGSize.zero
    
    // Add a state variable to store the user's location separately from the location manager
    @State private var userLocation: CLLocationCoordinate2D?
    
    // Add this to track if initial location is set
    @State private var hasSetInitialLocation = false
    
    // Add a state for the displayed marker position
    @State private var displayedMarkerLocation: CLLocationCoordinate2D?
    @State private var isTrackingLocation = true  // Add this to track if we're following location
    
    // Add state for selected search location
    @State private var selectedSearchLocation: SearchLocation?
    
    // Add a computed property to get the reference location for distance calculations
    private var referenceLocation: CLLocationCoordinate2D? {
        // If there's a search location, use that, otherwise use user location
        if let searchLocation = selectedSearchLocation {
            return searchLocation.coordinate
        }
        return userLocation
    }
    
    // Update the computed property to use 'any AnnotationItem'
    private var allAnnotations: [Offender] {
        var items = offenders
        if let searchLocation = selectedSearchLocation {
            let searchMarker = Offender(
                id: searchLocation.id,
                coordinate: searchLocation.coordinate,
                type: .search,
                name: searchLocation.title,
                gender: "",
                age: 0,
                address: searchLocation.subtitle,
                fullAddress: searchLocation.subtitle,
                offenderUri: ""
            )
            items.append(searchMarker)
        }
        return items
    }
    
    // Add this computed property
    private var displaySearchText: String {
        if let location = selectedSearchLocation {
            return location.title + ", " + location.subtitle
        }
        return "Search here"
    }
    
    private func fetchOffendersForCurrentSelection() {
        if let searchLocation = selectedSearchLocation,
           let state = searchLocation.state,
           let zip = searchLocation.zip {
            // Use search location with its state/zip
            offenderService.fetchOffenders(
                location: searchLocation.coordinate,
                distance: selectedDistance,
                state: state,
                zip: zip
            )
        } else if let location = locationManager.location {  // Change back to actual location
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let state = placemarks?.first?.administrativeArea {
                    // Check if state is unsupported
                    if let fullStateName = self.unsupportedStates[state] {
                        DispatchQueue.main.async {
                            self.unsupportedStateName = fullStateName
                            self.showingUnsupportedStateAlert = true
                        }
                        return
                    }
                    
                    // State is supported, proceed with API call
                    self.offenderService.fetchOffenders(
                        location: location.coordinate,
                        distance: self.selectedDistance
                    )
                }
            }
        }
    }
    
    @State private var showingUnsupportedStateAlert = false
    @State private var unsupportedStateName = ""
    
    private let unsupportedStates = [
        "AR": "Arkansas",
        "DE": "Delaware", 
        "IL": "Illinois",
        "MN": "Minnesota",
        "NH": "New Hampshire",
        "NY": "New York",
        "OR": "Oregon",
        "TX": "Texas",
        "VT": "Vermont",
        "WV": "West Virginia"
    ]
    
    private func checkStateSupport(state: String) -> Bool {
        if let fullStateName = unsupportedStates[state] {
            unsupportedStateName = fullStateName
            showingUnsupportedStateAlert = true
            return false
        }
        return true
    }
    
    // Add this with other @State variables
    @State private var showingPaywall = false
    
    // Add this near your other @State variables at the top
    @State private var showingErrorAlert = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map with only offender markers
            Map(coordinateRegion: $region,
                showsUserLocation: false,
                annotationItems: allAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    if item.type == .search {
                        SearchLocationMarker()
                            .id(item.id)  // Add this to maintain identity
                    } else {
                        // Regular offender marker
                        VStack(spacing: 0) {
                            // Wolf icon with red background and white stroke
                            ZStack {
                                Capsule()
                                    .fill(Color.red)
                                    .frame(width: 65, height: 55)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.white, lineWidth: 1.25)
                                    )
                                
                                Text("🐺")
                                    .font(.system(size: 40))
                                    .offset(y: -1)
                                    .modifier(BreathingModifier())  // Add breathing animation
                            }
                            
                            // Triangle pointer with stroke
                            ZStack {
                                Image(systemName: "triangle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                
                                Image(systemName: "triangle")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            .offset(y: -5)
                            .rotationEffect(.degrees(180))
                        }
                        .modifier(SwayingModifier())
                        .modifier(DroppingModifier(index: offenders.firstIndex(where: { $0.id == item.id }) ?? 0))
                        .onTapGesture {
                            selectedOffender = item
                            showingOffenderDetail = true
                        }
                        .zIndex(0)
                        .id(item.id)  // Add this to maintain identity
                    }
                }
            }
            .overlay {
                // Simpler overlay for YouMarker
                if let location = userLocation {
                    YouMarker()
                        .position(
                            x: CGFloat((location.longitude - region.center.longitude) / region.span.longitudeDelta + 0.5) * UIScreen.main.bounds.width,
                            y: CGFloat(0.5 - (location.latitude - region.center.latitude) / region.span.latitudeDelta) * UIScreen.main.bounds.height
                        )
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { _ in
                        isTrackingLocation = false
                    }
            )
            .onChange(of: locationManager.location) { newLocation in
                if let location = newLocation {
                    if !hasSetInitialLocation {
                        withAnimation {
                            region = MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            )
                            hasSetInitialLocation = true
                        }
                    }
                    if isTrackingLocation {
                        userLocation = location.coordinate
                        // Only fetch offenders if we're using current location (no search location)
                        if selectedSearchLocation == nil {
                            fetchOffendersForCurrentSelection()
                        }
                    }
                }
            }
            .onAppear {
                if let location = locationManager.location {
                    userLocation = location.coordinate
                }
            }
            .ignoresSafeArea()
            
            // Top overlays
            VStack {
                HStack {
                    // Scour pill
                    HStack {
                        Text("🐺")
                            .font(.system(size: 30))
                            .modifier(BreathingModifier())  // Add breathing animation
                        Text("Lurking")
                            .foregroundColor(.white)
                            .font(.system(size: 28, weight: .medium))
                    }
                    .frame(height: 52)
                    .padding(.horizontal, 18)
                    .background(Color(hex: "282928"))
                    .cornerRadius(200)
                    
                    Spacer()
                    
                    // Location pill
                    HStack {
                        Image(systemName: "location.north.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 26))
                            .rotationEffect(.degrees(45))
                            .padding(.leading, 4)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(height: 52)
                    .frame(width: 34)
                    .padding(.horizontal, 20)
                    .background(Color(hex: "282928"))
                    .cornerRadius(200)
                    .onTapGesture {
                        if let location = locationManager.location {
                            withAnimation {
                                // Reset region to user location
                                region = MKCoordinateRegion(
                                    center: location.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                )
                                // Reset tracking
                                isTrackingLocation = true
                                userLocation = location.coordinate
                                
                                // Clear search location and text
                                selectedSearchLocation = nil
                                searchText = ""
                                
                                // Reset to default radius and fetch offenders
                                selectedDistance = "0.5"
                                offenderService.fetchOffenders(
                                    location: location.coordinate,
                                    distance: "0.5"
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Bottom UI Stack
            VStack(spacing: 10) {
                // Distance markers
                HStack(spacing: 15) {
                    DistanceMarker(distance: "3", isSelected: selectedDistance == "3")
                        .onTapGesture {
                            selectedDistance = "3"
                            fetchOffendersForCurrentSelection()
                        }
                    DistanceMarker(distance: "2", isSelected: selectedDistance == "2")
                        .onTapGesture {
                            selectedDistance = "2"
                            fetchOffendersForCurrentSelection()
                        }
                    DistanceMarker(distance: "1", isSelected: selectedDistance == "1")
                        .onTapGesture {
                            selectedDistance = "1"
                            fetchOffendersForCurrentSelection()
                        }
                    DistanceMarker(distance: "0.5", isSelected: selectedDistance == "0.5")
                        .onTapGesture {
                            selectedDistance = "0.5"
                            fetchOffendersForCurrentSelection()
                        }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Search Bar
                HStack {
                    Text("🕵️‍♂️")
                        .font(.system(size: 30))
                    TextField(displaySearchText, text: $searchText)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .accentColor(.white)
                        .disabled(true)
                }
                .padding(.vertical, 15)
                .padding(.horizontal)
                .background(Color(hex: "282928"))
                .cornerRadius(200)
                .padding(.horizontal)
                .onTapGesture {
                    showingSearchSheet = true
                }  // Move the tap gesture here
            }
            .padding(.bottom, 30)
            
            // Sheet presentation
            if showingOffenderDetail {
                // Dark overlay
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingOffenderDetail = false
                    }
                    .transition(.opacity)
                    .animation(
                        .easeInOut(duration: 0.5),  // Increased from 0.3 for smoother fade
                        value: showingOffenderDetail
                    )
                
                // Offender detail card
                VStack(alignment: .leading, spacing: 16) {
                    // Add drag indicator at the top
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 40, height: 4)
                        .cornerRadius(2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    
                    // Header with wolf and name
                    HStack {
                        Text("🐺")
                            .font(.system(size: 40))
                            .modifier(BreathingModifier())
                        
                        VStack(alignment: .leading) {
                            Text(selectedOffender?.name ?? "Unknown")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                            if let offenderLocation = selectedOffender?.coordinate,
                               let reference = referenceLocation {
                                Text(reference.formattedDistance(to: offenderLocation) + " away")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            } else {
                                Text("Distance unknown")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Info grid
                    HStack(spacing: 40) {
                        VStack(alignment: .leading) {
                            Text("Age:")
                                .foregroundColor(.gray)
                            Text("\(selectedOffender?.age ?? 0)")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Sex:")
                                .foregroundColor(.gray)
                            Text(selectedOffender?.gender ?? "")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Address section
                    VStack(alignment: .leading) {
                        Text("Address:")
                            .foregroundColor(.gray)
                        Text(selectedOffender?.address ?? "")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                        Text(selectedOffender?.fullAddress ?? "")
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Update the button to open the offender URI
                    if let offenderUri = selectedOffender?.offenderUri,
                       let url = URL(string: offenderUri) {
                        Button(action: {
                            Task {
                                await subscriptionService.updateSubscriptionStatus()
                                if subscriptionService.checkSubscription() {
                                    await UIApplication.shared.open(url)
                                } else {
                                    showingPaywall = true
                                }
                            }
                        }) {
                            Text("See Photo & Crimes")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    Capsule()
                                        .fill(Color.red)
                                )
                        }
                        .modifier(ButtonPulseModifier())
                    }
                }
                .padding(20)
                .frame(height: 340)
                .background(Color(hex: "1C1C1E"))
                .offset(y: max(0, dragOffset.height + dismissOffset.height))
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 100
                            if value.translation.height > threshold {
                                showingOffenderDetail = false
                            } else {
                                dismissOffset = .zero
                            }
                        }
                )
                .transition(.move(edge: .bottom))
                .animation(
                    .spring(
                        response: 0.7,
                        dampingFraction: 0.9,
                        blendDuration: 0.5
                    ),
                    value: showingOffenderDetail
                )
            }
            
            if offenderService.isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(true)
                
                GeometryReader { geometry in
                    VStack {
                        Text("🐺")
                            .font(.system(size: 100))
                            .modifier(BreathingModifier())
                        
                        Text("Searching...")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(Color(hex: "282928"))
                    .cornerRadius(20)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSearchSheet) {
            SearchSheetView(
                searchText: $searchText,
                isPresented: $showingSearchSheet,
                region: $region,
                selectedLocation: $selectedSearchLocation,
                offenderService: offenderService
            )
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {
                offenderService.errorMessage = nil
            }
        } message: {
            Text(offenderService.errorMessage ?? "")
        }
        .alert("Unable to Search", isPresented: $showingUnsupportedStateAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The state of \(unsupportedStateName) currently does not support location based search")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

struct DistanceMarker: View {
    let distance: String
    let isSelected: Bool
    
    var body: some View {
        Text("\(distance) mi")
            .foregroundColor(.white)
            .font(.system(size: 18, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color(hex: "282928"))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white, lineWidth: isSelected ? 1 : 0)
                    )
            )
    }
}

#Preview {
    ContentView()
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Add this struct for the swaying animation
struct SwayingModifier: ViewModifier {
    @State private var isSwaying = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isSwaying ? 6 : -6), anchor: .bottom)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isSwaying
            )
            .onAppear {
                isSwaying = true
            }
    }
}

// Add this new modifier for the breathing/pulsing effect
struct BreathingModifier: ViewModifier {
    @State private var isBreathing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? 1.1 : 0.9)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

// Modify DroppingModifier to use the index
struct DroppingModifier: ViewModifier {
    @State private var hasDropped = false
    let index: Int
    
    func body(content: Content) -> some View {
        content
            .offset(y: hasDropped ? 0 : -1000)
            .opacity(hasDropped ? 1 : 0)
            .animation(
                Animation.spring(
                    response: 0.6,
                    dampingFraction: 0.6,
                    blendDuration: 0
                ),
                value: hasDropped
            )
            .onAppear {
                // Delay based on index (0.3s initial + 0.2s per marker)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(index) * 0.2) {
                    hasDropped = true
                }
            }
    }
}

// Add this new view for the "You" pill
struct YouMarker: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("You")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))
                .modifier(BreathingModifier())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(hex: "282928"))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white, lineWidth: 1)
                        )
                )
            
            // Triangle pointer with stroke
            ZStack {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "282928"))
                
                Image(systemName: "triangle")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .offset(y: -5)
            .rotationEffect(.degrees(180))
        }
    }
}

// Add this new modifier for the button pulse
struct ButtonPulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)  // Subtle scale change
            .animation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// Add this struct near the bottom of the file
struct SearchLocationMarker: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Capsule()
                    .fill(Color(hex: "282928"))
                    .frame(width: 65, height: 55)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white, lineWidth: 1.25)
                    )
                
                Text("📍")
                    .font(.system(size: 40))
                    .offset(y: -1)
                    .modifier(BreathingModifier())
            }
            
            // Triangle pointer
            ZStack {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "282928"))
                
                Image(systemName: "triangle")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .offset(y: -5)
            .rotationEffect(.degrees(180))
        }
    }
}

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let earthRadius = 6371000.0 // Earth's radius in meters
        
        let lat1 = self.latitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let deltaLat = (coordinate.latitude - self.latitude) * .pi / 180
        let deltaLon = (coordinate.longitude - self.longitude) * .pi / 180
        
        let a = sin(deltaLat/2) * sin(deltaLat/2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon/2) * sin(deltaLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    func formattedDistance(to coordinate: CLLocationCoordinate2D) -> String {
        let distanceInMeters = distance(to: coordinate)
        let miles = distanceInMeters / 1609.34
        
        if miles < 1.0 {
            // Show two decimal places for distances less than 1 mile
            return String(format: "%.2f mi", miles)
        } else {
            // Show one decimal place for distances 1 mile or greater
            return String(format: "%.1f mi", miles)
        }
    }
}
