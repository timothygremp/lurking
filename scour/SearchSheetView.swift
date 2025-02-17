import SwiftUI

// Update the sample data structure to include a unique ID
struct RecentSearch: Identifiable {
    let id = UUID()
    let mainText: String
    let subText: String
}

struct SearchSheetView: View {
    @Binding var searchText: String
    @Binding var isPresented: Bool
    @FocusState private var isFocused: Bool
    
    @State private var offset: CGFloat = 0
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
            }
            .padding(.vertical, 15)
            .padding(.horizontal)
            .background(Color(hex: "282928"))
            .cornerRadius(200)
            .padding(.horizontal)
            
            // Recent section
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