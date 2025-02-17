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
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6160, longitude: -116.2043)),
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6140, longitude: -116.2013)),
        Offender(coordinate: CLLocationCoordinate2D(latitude: 43.6130, longitude: -116.2033))
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map View
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: offenders) { offender in
                MapAnnotation(coordinate: offender.coordinate) {
                    Image("wolf-marker")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.red)
                                .frame(width: 44, height: 44)
                        )
                }
            }
            .ignoresSafeArea()
            
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
