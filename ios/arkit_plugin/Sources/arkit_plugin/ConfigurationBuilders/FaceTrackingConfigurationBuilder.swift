import ARKit
import Foundation

#if ENABLE_TRUEDEPTH_API
    func createFaceTrackingConfiguration(_: [String: Any]) -> ARFaceTrackingConfiguration? {
        if ARFaceTrackingConfiguration.isSupported {
            return ARFaceTrackingConfiguration()
        }
        return nil
    }
#endif
