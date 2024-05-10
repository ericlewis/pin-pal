import Foundation
import Models

extension MemoryContentEnvelope {
    public func videoDownloadUrl() -> URL? {
        guard let cap: CaptureEnvelope = self.get(), let vid = cap.video else {
            return nil
        }
        return URL.videoDownloadUrl(uuid: id, fileUUID: vid.fileUUID, accessToken: vid.accessToken)
    }
}
