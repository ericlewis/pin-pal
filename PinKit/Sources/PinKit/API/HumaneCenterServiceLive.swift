import Foundation
import Get

extension HumaneCenterService {
    public static func live() -> Self {
        let client = APIClient(baseURL: API.rootUrl) {
            $0.delegate = ClientDelegate()
            $0.decoder = {
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                return decoder
            }()
        }
        return Self(
            notes: { try await client.send(API.notes(page: $0, size: $1)).value },
            captures: { try await client.send(API.captures(page: $0, size: $1)).value },
            events: { try await client.send(API.events(domain: $0, page: $1, size: $2)).value },
            featureFlag: { try await client.send(API.featureFlag($0)).value },
            subscription: { try await client.send(API.subscription()).value },
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
            create: { try await client.send(API.create(note: $0)).value },
            update: { try await client.send(API.update(note: $1)).value },
            search: { try await client.send(API.search(query: $0, domain: $1)).value },
            deleteEvent: { try await client.send(API.delete(eventUUID: $0)).value },
            memory: { try await client.send(API.memory(uuid: $0)).value },
            toggleFeatureFlag: {
                let result = try await client.send(API.toggleFeatureFlag($0, isEnabled: $1)).value
                return FeatureFlagEnvelope(state: result.lowercased().starts(with: "e") ? .enabled : .disabled)
            },
            lostDeviceStatus: { try await client.send(API.lostDeviceStatus(deviceId: $0)).value }, //
            toggleLostDeviceStatus: { try await client.send(API.toggleLostDeviceStatus(deviceId: $0, isLost: $1)).value }, //
            deviceIdentifiers: { try await client.send(API.deviceIdentifiers()).value },
            deleteAllNotes: { try await client.send(API.deleteAllNotes()) },
            bulkFavorite: { try await client.send(API.favorite(memoryUUIDs: $0)).value },
            bulkUnfavorite: { try await client.send(API.unfavorite(memoryUUIDs: $0)).value },
            bulkRemove: { try await client.send(API.delete(memoryUUIDs: $0)).value }
        )
    }
}
