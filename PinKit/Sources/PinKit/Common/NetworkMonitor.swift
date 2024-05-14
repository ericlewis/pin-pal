import Network
import SwiftUI

@Observable final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)

    var isConnected: Bool = false
    var isExpensive: Bool = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            withAnimation {
                self?.isConnected = (path.status == .satisfied)
                self?.isExpensive = path.isExpensive
            }

            if path.status == .satisfied {
                print("We're connected!")
            } else {
                print("No connection.")
            }

            if path.isExpensive {
                print("The connection is using a cellular network.")
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
