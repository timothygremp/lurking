import Foundation
import CoreLocation

struct OffenderRequest: Codable {
    let agentCode = "2%n!yQ6#eETHgBy?-7*bVdBXgVWdg4@ySa=r?wLUj5dg4LFTF?V4rt^w42aTU-aFy4kCvkeFxX-kWPnBmv@d!$kyZk8y=qYXNFWP^bT#65RAWS4U3PH=DTuU8EKU+sEQv9mAspt2jW8qD7MaCR?nVq+q%--yPQpA5Bxsqf87EhPY4fz3+x&-pnv-6Vw@bMD=$b%?#t?YJy2G7KV+hYLJJw!S8n*+-juHj5TPG7CBr2CEy6hGFN%WXWaJXk?WmpwW"
    let zip: String
    let longitude: Double
    let latitude: Double
    let distance: String
    let state: String
}

struct OffenderResponse: Codable {
    let statusMessage: String
    let offenders: [OffenderData]
}

struct OffenderData: Codable {
    let name: OffenderName
    let aliases: [AliasName]
    let gender: String
    let age: Int
    let locations: [OffenderLocation]
    let offenderUri: String
    let imageUri: String
    let dob: String
    let absconder: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, aliases, gender, age, locations, offenderUri, imageUri, dob, absconder
    }
}

struct OffenderName: Codable {
    let prefix: String
    let givenName: String
    let middleName: String
    let surName: String
    let suffix: String
}

struct OffenderLocation: Codable {
    let name: String
    let type: String
    let streetAddress: String
    let city: String
    let county: String
    let state: String
    let zipCode: String
    let zipCodeExtension: String
    let latitude: Double?
    let longitude: Double?
}

struct AliasName: Codable {
    let prefix: String?
    let givenName: String?
    let middleName: String?
    let surName: String?
    let suffix: String?
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.prefix = try container.decodeIfPresent(String.self, forKey: .prefix)
            self.givenName = try container.decodeIfPresent(String.self, forKey: .givenName)
            self.middleName = try container.decodeIfPresent(String.self, forKey: .middleName)
            self.surName = try container.decodeIfPresent(String.self, forKey: .surName)
            self.suffix = try container.decodeIfPresent(String.self, forKey: .suffix)
        } else {
            self.prefix = nil
            self.givenName = nil
            self.middleName = nil
            self.surName = nil
            self.suffix = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case prefix, givenName, middleName, surName, suffix
    }
}

class OffenderService: ObservableObject {
    @Published var offenders: [Offender] = []
    @Published var errorMessage: String?
    @Published var isLoading = false  // Add loading state
    
    func fetchOffenders(location: CLLocationCoordinate2D, distance: String, state: String? = nil, zip: String? = nil) {
        isLoading = true  // Set loading state when starting fetch
        
        let request = OffenderRequest(
            zip: zip ?? "83702",
            longitude: location.longitude,
            latitude: location.latitude,
            distance: distance,
            state: state ?? "ID"
        )
        
        guard let url = URL(string: "https://mobile-api-v2.nsopw.org/api/search") else { 
            print("Invalid URL")
            return 
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData
            
            // Print request
            print("Request URL: \(url)")
            print("Request Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
            if let requestString = String(data: requestData, encoding: .utf8) {
                print("Request Body: \(requestString)")
            }
        } catch {
            print("Error encoding request: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching offenders: \(error)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Network error occurred. Please try again."
                    self?.isLoading = false  // Clear loading state on error
                }
                return
            }
            
            // Print response headers
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            // Print response data
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Data: \(responseString)")
            }
            
            do {
                let response = try JSONDecoder().decode(OffenderResponse.self, from: data)
                print("Decoded Response - Status: \(response.statusMessage)")
                print("Found \(response.offenders.count) offenders")
                
                DispatchQueue.main.async {
                    if response.offenders.isEmpty {
                        self?.errorMessage = "No offenders found, please change your search parameters and try again."
                        self?.isLoading = false  // Clear loading state on no offenders
                    } else {
                        self?.errorMessage = nil
                        let markers: [Offender] = response.offenders.flatMap { offender -> [Offender] in
                            let residentialLocations = offender.locations.filter { location in
                                (location.type == "RESIDENTIAL" || location.type == "RESIDENCE") && 
                                location.latitude != nil && 
                                location.longitude != nil
                            }
                            print("Offender \(offender.name.givenName) has \(residentialLocations.count) valid residential locations")
                            print("Location types: \(offender.locations.map { $0.type })")
                            
                            return residentialLocations.compactMap { location in
                                guard let lat = location.latitude,
                                      let lon = location.longitude else {
                                    return nil
                                }
                                
                                print("Creating marker for location: lat: \(lat), lon: \(lon)")
                                return Offender(
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: lat,
                                        longitude: lon
                                    ),
                                    type: .offender,
                                    name: "\(offender.name.givenName) \(offender.name.surName)",
                                    gender: offender.gender,
                                    age: offender.age,
                                    address: location.streetAddress,
                                    fullAddress: "\(location.streetAddress), \(location.city), \(location.state) \(location.zipCode)",
                                    offenderUri: offender.offenderUri
                                )
                            }
                        }
                        print("Created \(markers.count) markers")
                        self?.offenders = markers
                        self?.isLoading = false  // Clear loading state on success
                    }
                }
            } catch {
                print("Error decoding response: \(error)")
                if let decodingError = error as? DecodingError {
                    print("Decoding Error Details: \(decodingError)")
                }
                DispatchQueue.main.async {
                    self?.errorMessage = "Error processing response. Please try again."
                    self?.isLoading = false  // Clear loading state on error
                }
            }
        }.resume()
    }
} 