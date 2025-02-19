import SwiftUI
import MapKit
import Combine

// Update the sample data structure to include a unique ID
struct RecentSearch: Identifiable, Codable {
    let id: UUID
    let mainText: String
    let subText: String
    let state: String
    let zip: String
    
    init(mainText: String, subText: String, state: String, zip: String) {
        self.id = UUID()
        self.mainText = mainText
        self.subText = subText
        self.state = state
        self.zip = zip
    }
    
    enum CodingKeys: String, CodingKey {
        case id, mainText, subText, state, zip
    }
}

// Add new struct for search results
struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    var location: CLLocationCoordinate2D?
}

// Add this struct for search locations
struct SearchLocation: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let state: String?
    let zip: String?
}

struct SearchSheetView: View {
    @Binding var searchText: String
    @Binding var isPresented: Bool
    @Binding var region: MKCoordinateRegion
    @Binding var selectedLocation: SearchLocation?
    let offenderService: OffenderService
    @FocusState private var isFocused: Bool
    
    @State private var offset: CGFloat = 0
    @State private var searchResults: [SearchResult] = []
    @StateObject private var searchCompleter = SearchCompleter()
    @StateObject private var recentSearchManager = RecentSearchManager()
    
    let dismissThreshold: CGFloat = 100
    
    // Updated sample data
    var recentSearches: [RecentSearch] {
        recentSearchManager.recentSearches
    }
    
    // Add this computed property to simplify the view
    private var resultsList: some View {
        ForEach(searchCompleter.results) { result in
            SearchResultRow(result: result) {
                handleSelection(result)
            }
        }
    }
    
    // Move the selection logic to a separate function
    private func handleSelection(_ result: SearchResult) {
        searchCompleter.geocodeAddress(for: result) { coordinate, addressComponents in
            if let location = coordinate,
               let state = addressComponents?.state,
               let zip = addressComponents?.postalCode {
                withAnimation {
                    region = MKCoordinateRegion(
                        center: location,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    selectedLocation = SearchLocation(
                        title: result.title,
                        subtitle: result.subtitle,
                        coordinate: location,
                        state: state,
                        zip: zip
                    )
                    
                    // Add the API call here with the correct state and zip
                    offenderService.fetchOffenders(
                        location: location,
                        distance: "0.5",
                        state: state,
                        zip: zip
                    )
                    
                    // Add to recent searches with state and zip
                    recentSearchManager.addSearch(
                        title: result.title,
                        subtitle: result.subtitle,
                        state: state,
                        zip: zip
                    )
                    isPresented = false
                }
            }
        }
    }
    
    // Add this function to handle recent search selection
    private func handleRecentSelection(_ search: RecentSearch) {
        searchCompleter.geocodeAddress(forAddress: search.mainText + ", " + search.subText) { coordinate in
            if let location = coordinate {
                withAnimation {
                    region = MKCoordinateRegion(
                        center: location,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    selectedLocation = SearchLocation(
                        title: search.mainText,
                        subtitle: search.subText,
                        coordinate: location,
                        state: search.state,
                        zip: search.zip
                    )
                    
                    // Use the saved state and zip
                    offenderService.fetchOffenders(
                        location: location,
                        distance: "0.5",
                        state: search.state,
                        zip: search.zip
                    )
                    
                    isPresented = false
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .cornerRadius(2.5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            // Search bar
            HStack {
                Text("🕵️‍♂️")
                    .font(.system(size: 30))
                TextField("Search here", text: $searchText)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .focused($isFocused)
                    .onChange(of: searchText) { newValue in
                        searchCompleter.searchTerm = newValue
                    }
                
                // Add cancel button
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchCompleter.searchTerm = ""
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: searchText)
                }
            }
            .padding(.vertical, 15)
            .padding(.horizontal)
            .background(Color(hex: "282928"))
            .cornerRadius(200)
            .padding(.horizontal)
            
            // Results list
            ScrollView {
                if searchText.isEmpty {
                    // Show recent searches when no input
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Recent")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        ForEach(recentSearches) { search in
                            VStack(spacing: 0) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "2C2C2E"))
                                            .frame(width: 48, height: 48)
                                        
                                        Text("🕐")
                                            .font(.system(size: 26))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(search.mainText)
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                        Text(search.subText)
                                            .foregroundColor(Color(hex: "8E8E93"))
                                            .font(.system(size: 15))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                
                                Rectangle()
                                    .fill(Color(hex: "38383A"))
                                    .frame(height: 1)
                                    .padding(.leading, 80)
                            }
                            .onTapGesture {
                                handleRecentSelection(search)
                            }
                        }
                    }
                } else {
                    resultsList  // Use the computed property here
                }
            }
            
            Spacer()
        }
        .background(Color(hex: "1C1C1E"))
        .offset(y: offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    let translation = gesture.translation.height
                    offset = translation > 0 ? translation : 0
                }
                .onEnded { gesture in
                    if gesture.translation.height > dismissThreshold {
                        isPresented = false
                    } else {
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                }
        )
        .onAppear {
            isFocused = true
        }
    }
}

// Add this as a separate view
struct SearchResultRow: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "2C2C2E"))
                        .frame(width: 48, height: 48)
                    
                    Text("📍")
                        .font(.system(size: 26))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.title)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                    Text(result.subtitle)
                        .foregroundColor(Color(hex: "8E8E93"))
                        .font(.system(size: 15))
                }
                
                Spacer()
             