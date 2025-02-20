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
                print("1. List item tapped: \(result.title), \(result.subtitle)")  // Debug print
                handleSelection(result)
            }
        }
    }
    
    // Add this function to handle recent search selection
    private func handleRecentSelection(_ search: RecentSearch) {
        // Check if state is unsupported first
        if let fullStateName = unsupportedStates[search.state] {
            unsupportedStateName = fullStateName
            showingUnsupportedStateAlert = true
            return
        }
        
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
    
    @State private var showingUnsupportedStateAlert = false
    @State private var unsupportedStateName = ""
    
    // Update the selection logic
    private func handleSelection(_ result: SearchResult) {
        print("2. handleSelection called")  // Debug print
        searchCompleter.geocodeAddress(for: result) { coordinate, addressComponents in
            print("3. geocodeAddress completion called")  // Debug print
            guard let state = addressComponents?.state else { 
                print("No state found")  // Debug print
                return 
            }
            
            print("4. State found: \(state)")  // Debug print
            
            // Check if state is unsupported first
            if let fullStateName = unsupportedStates[state] {
                print("5. Unsupported state found: \(fullStateName)")  // Debug print
                DispatchQueue.main.async {
                    unsupportedStateName = fullStateName
                    showingUnsupportedStateAlert = true
                }
                return
            }
            
            print("6. State is supported, continuing with selection")  // Debug print
            // Only proceed if we have all required data and state is supported
            if let location = coordinate,
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
                    
                    offenderService.fetchOffenders(
                        location: location,
                        distance: "0.5",
                        state: state,
                        zip: zip
                    )
                    
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
        .alert("Unable to Search", isPresented: $showingUnsupportedStateAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The state of \(unsupportedStateName) currently does not support location based search")
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
                
                Image(systemName: "arrow.up.left")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .padding(.trailing, 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .onTapGesture(perform: onTap)
            
            Rectangle()
                .fill(Color(hex: "38383A"))
                .frame(height: 1)
                .padding(.leading, 80)
        }
    }
}

// Update SearchCompleter class
class SearchCompleter: NSObject, ObservableObject {
    @Published var searchTerm = ""
    @Published var results: [SearchResult] = []
    
    private var completer: MKLocalSearchCompleter
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        
        // Set region to United States using MKCoordinateRegion
        let usRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of US
            span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60) // Span to cover US
        )
        completer.region = usRegion
        
        // Optional: Set result type to addresses only
        completer.resultTypes = .address
        
        // Set up publisher for search term
        $searchTerm
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] term in
                self?.completer.queryFragment = term
            }
            .store(in: &cancellables)
    }
}

extension SearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter for US addresses
        let usResults = completer.results.filter { result in
            let address = result.subtitle.uppercased()
            return address.contains("USA") || 
                   address.contains(", AL,") || address.contains(", AK,") || 
                   address.contains(", AZ,") || address.contains(", AR,") || 
                   address.contains(", CA,") || address.contains(", CO,") || 
                   address.contains(", CT,") || address.contains(", DE,") || 
                   address.contains(", FL,") || address.contains(", GA,") || 
                   address.contains(", HI,") || address.contains(", ID,") || 
                   address.contains(", IL,") || address.contains(", IN,") || 
                   address.contains(", IA,") || address.contains(", KS,") || 
                   address.contains(", KY,") || address.contains(", LA,") || 
                   address.contains(", ME,") || address.contains(", MD,") || 
                   address.contains(", MA,") || address.contains(", MI,") || 
                   address.contains(", MN,") || address.contains(", MS,") || 
                   address.contains(", MO,") || address.contains(", MT,") || 
                   address.contains(", NE,") || address.contains(", NV,") || 
                   address.contains(", NH,") || address.contains(", NJ,") || 
                   address.contains(", NM,") || address.contains(", NY,") || 
                   address.contains(", NC,") || address.contains(", ND,") || 
                   address.contains(", OH,") || address.contains(", OK,") || 
                   address.contains(", OR,") || address.contains(", PA,") || 
                   address.contains(", RI,") || address.contains(", SC,") || 
                   address.contains(", SD,") || address.contains(", TN,") || 
                   address.contains(", TX,") || address.contains(", UT,") || 
                   address.contains(", VT,") || address.contains(", VA,") || 
                   address.contains(", WA,") || address.contains(", WV,") || 
                   address.contains(", WI,") || address.contains(", WY,")
        }
        
        // Just create the results without coordinates initially
        results = usResults.map { result in
            SearchResult(
                title: result.title,
                subtitle: result.subtitle,
                location: nil
            )
        }
    }
    
    // Add this method to perform the geocoding only when a result is selected
    func geocodeAddress(for result: SearchResult, completion: @escaping (CLLocationCoordinate2D?, AddressComponents?) -> Void) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = result.title + ", " + result.subtitle
        
        print("Searching for address: \(result.title + ", " + result.subtitle)")  // Debug print
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            if let placemark = response?.mapItems.first?.placemark {
                // Debug prints
                print("Found placemark:")
                print("State: \(placemark.administrativeArea ?? "nil")")
                print("State abbreviation: \(placemark.administrativeArea?.uppercased() ?? "nil")")
                print("Zip: \(placemark.postalCode ?? "nil")")
                
                let state = placemark.administrativeArea?.uppercased() ?? "ID"
                let zip = placemark.postalCode ?? "83702"
                
                let components = AddressComponents(
                    state: state,
                    postalCode: zip
                )
                completion(placemark.coordinate, components)
            } else {
                print("No placemark found or error: \(error?.localizedDescription ?? "unknown error")")  // Debug print
                completion(nil, nil)
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
    
    func geocodeAddress(forAddress address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = address
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            if let coordinate = response?.mapItems.first?.placemark.coordinate {
                completion(coordinate)
            } else {
                completion(nil)
            }
        }
    }
}

// Add this struct to hold address components
struct AddressComponents {
    let state: String
    let postalCode: String
} 