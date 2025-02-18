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
    
    enum MarkerType {
        case offender
        case search
    }
    
    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D, type: MarkerType = .offender) {
        self.id = id
        self.coordinate = coordinate
        self.type = type
    }
    
    static func searchMarker(coordinate: CLLocationCoordinate2D) -> Offender {
        Offender(coordinate: coordinate, type: .search)
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var showingSearchSheet = false
    @State private var selectedDistance: String = ".5 mi"  // Default selected distance
    @State private var region = MKCoordinateRegion(
        // Start with a wider view of US
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    // Sample offender data for demonstration
    @State private var offenders = [
        // Two offenders above "You" (at different distances)
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6190, longitude: -116.2003), type: .offender),  // Northeast, further out
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6175, longitude: -116.2053), type: .offender),  // Northwest, closer
        
        // Two offenders below "You" (at different distances)
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6120, longitude: -116.1993), type: .offender),  // Southeast, further out
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6135, longitude: -116.2043), type: .offender),  // Southwest, closer
    ]
    
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
    
    // Update the computed property to use 'any AnnotationItem'
    private var allAnnotations: [Offender] {
        var items = offenders
        if let searchLocation = selectedSearchLocation {
            let searchMarker = Offender(
                id: searchLocation.id,
                coordinate: searchLocation.coordinate,
                type: .search
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
                        Text("Scour")
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
                                region = MKCoordinateRegion(
                                    center: location.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                )
                                userLocation = location.coordinate
                                isTrackingLocation = true
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
                    DistanceMarker(distance: "3 mi", isSelected: selectedDistance == "3 mi")
                        .onTapGesture { selectedDistance = "3 mi" }
                    DistanceMarker(distance: "2 mi", isSelected: selectedDistance == "2 mi")
                        .onTapGesture { selectedDistance = "2 mi" }
                    DistanceMarker(distance: "1 mi", isSelected: selectedDistance == "1 mi")
                        .onTapGesture { selectedDistance = "1 mi" }
                    DistanceMarker(distance: ".5 mi", isSelected: selectedDistance == ".5 mi")
                        .onTapGesture { selectedDistance = ".5 mi" }
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
                            Text("Harvey Weinstein")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                            Text("500 ft away from you")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Info grid
                    HStack(spacing: 40) {
                        VStack(alignment: .leading) {
                            Text("Age:")
                                .foregroundColor(.gray)
                            Text("55")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Sex:")
                                .foregroundColor(.gray)
                            Text("M")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Address section
                    VStack(alignment: .leading) {
                        Text("Address:")
                            .foregroundColor(.gray)
                        Text("1422 N. 5th St.")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                        Text("1422 N. 5th St., Boise, ID 83702")
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // See Photo & Crimes button
                    Button(action: {
                        // Action for viewing photos and crimes
                    }) {
                        Text("See Photo & Crimes")
                            .font(.system(size: 22, weight: .bold))  // Bigger, bolder text
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)  // More vertical padding
                            .background(
                                Capsule()  // Pill shape
                                    .fill(Color.red)
                            )
                    }
                    .modifier(ButtonPulseModifier())  // Add pulsing animation
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
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSearchSheet) {
            SearchSheetView(
                searchText: $searchText,
                isPresented: $showingSearchSheet,
                region: $region,
                selectedLocation: $selectedSearchLocation
            )
        }
    }
}

struct DistanceMarker: View {
    let distance: String
    let isSelected: Bool
    
    var body: some View {
        Text(distance)
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


