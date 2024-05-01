import SwiftUI
import OSLog

@Observable public final class SettingsRepository {
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let logger = Logger()
    
    var subscription: Subscription? {
        didSet {
            try? UserDefaults.standard.setValue(encoder.encode(subscription), forKey: Constants.SUBSCRIPTION_INFO_CACHE)
        }
    }
    
    var extendedInfo: DetailedDeviceInfo? {
        didSet {
            try? UserDefaults.standard.setValue(encoder.encode(extendedInfo), forKey: Constants.EXTENDED_INFO_CACHE)
        }
    }
    
    var isLoading = false
    
    var isVisionBetaEnabled = false {
        willSet {
            if isLoading { return }
            Task {
                try await self.service.toggleFeatureFlag(.visionAccess)
            }
        }
    }
    var isDeviceLost = false {
        willSet {
            if isLoading { return }
            if let id = extendedInfo?.id {
                Task {
                    try await self.service.toggleLostDeviceStatus(id)
                }
            }
        }
    }
    
    var service: HumaneCenterService
    var observationTask: Task<Void, Never>?
    
    public init(service: HumaneCenterService) {
        self.service = service
    }
    
    func initial() async {
        // Hydrate
        if let subscriptionData = UserDefaults.standard.data(forKey: Constants.SUBSCRIPTION_INFO_CACHE), let subscription = try? decoder.decode(Subscription.self, from: subscriptionData) {
            self.subscription = subscription
        }
        
        if let extendedData = UserDefaults.standard.data(forKey: Constants.EXTENDED_INFO_CACHE), let extendedInfo = try? decoder.decode(DetailedDeviceInfo.self, from: extendedData) {
            self.extendedInfo = extendedInfo
        }
        
        await load()
    }
    
    func load() async {
        isLoading = true
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [loadFeatureFlags] in
                await loadFeatureFlags()
            }
            group.addTask { [loadExtendedInfo] in
                await loadExtendedInfo()
            }
            group.addTask { [loadSubscription] in
                await loadSubscription()
            }
        }
        isLoading = false
    }
    
    func loadSubscription() async {
        do {
            let sub = try await service.subscription()
            withAnimation {
                self.subscription = sub
            }
        } catch {
            logger.debug("\(error)")
        }
    }
    
    func loadFeatureFlags() async {
        do {
            let flag = try await service.featureFlag(.visionAccess)
            self.isVisionBetaEnabled = flag.isEnabled
        } catch {
            logger.debug("\(error)")
        }
    }
    
    func loadExtendedInfo() async {
        do {
            let extendedInfo = try await service.detailedDeviceInformation()
            withAnimation {
                self.extendedInfo = extendedInfo
            }
            let status = try await service.lostDeviceStatus(extendedInfo.id)
            self.isDeviceLost = status.isLost
        } catch {
            logger.debug("\(error)")
        }
    }
    
    func reload() async {
        await load()
    }
    
    func deleteAllNotes() async {
        try? await service.deleteAllNotes()
    }

    deinit {
        self.observationTask?.cancel()
    }
}
