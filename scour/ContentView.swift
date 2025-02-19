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

// Add this struct for the loading overlay
struct LoadingOverlay: View {
    // Add the breathing animation
    @State private var isBreathing = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("🐺")
                    .font(.system(size: 100))
                    .scaleEffect(isBreathing ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isBreathing
                    )
                
                Text("Searching...")
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .medium))
                    .scaleEffect(isBreathing ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isBreathing
                    )
            }
            .frame(width: 200, height: 200)
            .background(Color(hex: "282928"))
            .cornerRadius(20)
            .onAppear {
                isBreathing = true
            }
        }
        .ignoresSafeArea()
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
        } else if let location = locationManager.location {
            // Use current location with default state/zip
            offenderService.fetchOffenders(
                location: location.coordinate,
                distance: selectedDistance
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Existing map view
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
                            Text("Lurk")
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
                            Link(destination: url) {
                                Text("See Photo & Crimes")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .disabled(offenderService.isLoading)
            
            if offenderService.isLoading {
                LoadingOverlay()
            }
        }
    }
}
