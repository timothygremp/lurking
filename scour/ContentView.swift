//
//  ContentView.swift
//  scour
//
//  Created by Alaryce Patterson on 2/14/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var selectedDistance: String = ".5 mi"  // Default selected distance
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.6150, longitude: -116.2023), // Boise coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    // Sample offender data for demonstration
    @State private var offenders = [
        // Two offenders above "You" (at different distances)
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6190, longitude: -116.2003)),  // Northeast, further out
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6175, longitude: -116.2053)),  // Northwest, closer
        
        // Two offenders below "You" (at different distances)
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6120, longitude: -116.1993)),  // Southeast, further out
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6135, longitude: -116.2043)),  // Southwest, closer
    ]
    
    // Add these state variables inside ContentView
    @State private var showingOffenderDetail = false
    @State private var selectedOffender: Offender?
    
    // Add this gesture state
    @GestureState private var dragOffset = CGSize.zero
    @State private var dismissOffset = CGSize.zero
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map View
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: offenders) { offender in
                MapAnnotation(coordinate: offender.coordinate) {
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
                    .modifier(SwayingModifier())  // Add swaying animation
                    .modifier(DroppingModifier(index: offenders.firstIndex(where: { $0.id == offender.id }) ?? 0))
                    .onTapGesture {
                        selectedOffender = offender
                        showingOffenderDetail = true
                    }
                }
            }
            .overlay(
                // Center "You" marker
                YouMarker()
                    .offset(y: -10)  // Adjust position if needed
                , alignment: .center
            )
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
                            .padding(.leading, 4)  // Add a little padding to move icon right
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(height: 52)
                    .frame(width: 34)  // Set a wider width for pill shape
                    .padding(.horizontal, 20)
                    .background(Color(hex: "282928"))
                    .cornerRadius(200)
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
                    TextField("Search here", text: $searchText)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "A4A4AB"))
                        .accentColor(Color(hex: "A4A4AB"))
                }
                .padding(.vertical, 15)
                .padding(.horizontal)
                .background(Color(hex: "282928"))
                .cornerRadius(200)
                .padding(.horizontal)
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
