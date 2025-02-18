import SwiftUI
import MapKit
import Combine

// Update the sample data structure to include a unique ID
struct RecentSearch: Identifiable {
    let id = UUID()
    let mainText: String
    let subText: String
}

// Add new struct for search results
struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct SearchSheetView: View {
    @Binding var searchText: String
    @Binding var isPresented: Bool
    @FocusState private var isFocused: Bool
    
    @State private var offset: CGFloat = 0
    @State private var searchResults: [SearchResult] = []
    @StateObject private var searchCompleter = SearchCompleter()
    
    let dismissThreshold: CGFloat = 100
    
    // Updated sample data
    let recentSearches = [
        RecentSearch(mainText: "1422 N. 5th St.", subText: "1422 N. 5th St., Boise, ID 83702"),
        RecentSearch(mainText: "1422 N. 5th St.", subText: "1422 N. 5th St., Boise, ID 83702"),
        RecentSearch(mainText: "1422 N. 5th St.", subText: "1422 N. 5th St., Boise, ID 83702")
    ]
    
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
                        }
                    }
                } else {
                    // Show search results
                    ForEach(searchCompleter.results) { result in
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "2C2C2E"))
                                        .frame(width: 48, height: 48)
                                    
                                    Text("📍")  // Changed to map pin emoji
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
                            
                            Rectangle()
                                .fill(Color(hex: "38383A"))
                                .frame(height: 1)
                                .padding(.leading, 80)
                        }
                    }
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
        
        results = usResults.map { result in
            SearchResult(
                title: result.title,
                subtitle: result.subtitle
            )
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
} 