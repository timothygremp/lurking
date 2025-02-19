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
    @Published var isLoading = false
    
    func fetchOffenders(location: CLLocationCoordinate2D, distance: String, state: String = "ID", zip: String = "83702") {
        isLoading = true
        
        let request = OffenderRequest(
            zip: zip,
            longitude: location.longitude,
            latitude: loca