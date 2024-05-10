import Foundation
import Get
import Models

extension HumaneCenterService {
    public static func live() -> Self {
        let delegate = ClientDelegate()
        let client = APIClient(baseURL: API.rootUrl) {
            $0.delegate = delegate
            $0.decoder = {
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                return decoder
            }()
            $0.encoder = {
                let decoder = JSONEncoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateEncodingStrategy = .formatted(dateFormatter)
                return decoder
            }()
        }
        return Self(
            notes: {
                try await client.send(API.notes(page: $0, size: $1)).value
            },
            captures: { 
                try await client.send(API.captures(page: $0, size: $1)).value
            },
            events: {
                try await client.send(API.events(domain: $0, page: $1, size: $2)).value
            },
            featureFlag: {
                try await client.send(API.featureFlag($0)).value
            },
            subscription: {
                try await client.send(API.subscription()).value
            },
            detailedDeviceInformation: {
                let string = try await client.send(API.retrieveDetailedDeviceInfo()).value
                return DetailedDeviceInfo(
                    id: extractValue(from: string, forKey: "deviceID") ?? "UNKNOWN",
                    iccid: extractValue(from: string, forKey: "iccid") ?? "UNKNOWN",
                    serialNumber: extractValue(from: string, forKey: "deviceSerialNumber") ?? "UNKNOWN",
                    sku: extractValue(from: string, forKey: "sku") ?? "UNKNOWN",
                    color: extractValue(from: string, forKey: "deviceColor") ?? "UNKNOWN"
                )
            },
            create: {
                try await client.send(API.create(note: $0)).value
            },
            update: {
                try await client.send(API.update(note: $0)).value
            },
            search: {
                try await client.send(API.search(query: $0, domain: $1)).value
            },
            deleteEvent: {
                try await client.send(API.delete(eventUUID: $0)).value
            },
            memory: {
                try await client.send(API.memory(uuid: $0)).value
            },
            toggleFeatureFlag: {
                let result = try await client.send(API.toggleFeatureFlag($0, isEnabled: $1)).value
                return FeatureFlagEnvelope(state: result.lowercased().starts(with: "e") ? .enabled : .disabled)
            },
            lostDeviceStatus: {
                try await client.send(API.lostDeviceStatus(deviceId: $0)).value
            },
            toggleLostDeviceStatus: {
                try await client.send(API.toggleLostDeviceStatus(deviceId: $0, isLost: $1)).value
            },
            deviceIdentifiers: {
                try await client.send(API.deviceIdentifiers()).value
            },
            deleteAllNotes: {
                try await client.send(API.deleteAllNotes())
            },
            bulkFavorite: {
                try await client.send(API.favorite(memoryUUIDs: $0)).value
            },
            bulkUnfavorite: {
                try await client.send(API.unfavorite(memoryUUIDs: $0)).value
            },
            bulkRemove: {
                try await client.send(API.delete(memoryUUIDs: $0)).value
            },
            download: {
                try await client.send(API.download(memoryUUID: $0, asset: $1)).data
            },
            feedback: { category, event in
                if delegate.userId == nil {
                    let result = try await client.send(API.session()).value
                    delegate.userId = result.user.id
                }
                guard let userId = delegate.userId else {
                    throw APIError.unacceptableStatusCode(403)
                }
                let id = try await client.send(API.feedback(category: category, event: event, userId: userId)).value.dropFirst().dropLast()
                guard let uuid = UUID(uuidString: String(id)) else {
                    throw Error.feedbackError
                }
                return uuid
            }
        )
    }
    
    enum Error: Swift.Error {
        case feedbackError
    }
}
