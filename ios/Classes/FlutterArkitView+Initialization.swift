import ARKit

extension FlutterArkitView {
    func initalize(_ arguments: [String: Any], _: FlutterResult) {
        if let showStatistics = arguments["showStatistics"] as? Bool {
            sceneView.showsStatistics = showStatistics
        }

        if let autoenablesDefaultLighting = arguments["autoenablesDefaultLighting"] as? Bool {
            sceneView.autoenablesDefaultLighting = autoenablesDefaultLighting
        }

        if let forceUserTapOnCenter = arguments["forceUserTapOnCenter"] as? Bool {
            forceTapOnCenter = forceUserTapOnCenter
        }

        initalizeGesutreRecognizers(arguments)

        sceneView.debugOptions = parseDebugOptions(arguments)
        Task {
            let allImages = arguments["detectionImages"] as? [[String: Any]] ?? []
            if(allImages.count > 100) {
                let imageBatches = stride(from: 0, to: allImages.count, by: 100).map {
                            Array(allImages[$0..<min($0 + 100, allImages.count)])
                        }

                        DispatchQueue.main.async {
                            self.runImageDetectionBatches(
                                baseArguments: arguments,
                                imageBatches: imageBatches,
                                isInitialization: true
                            )
                        }
            } else {
                configuration = parseConfiguration(arguments)
                DispatchQueue.main.async {
                    if let config = self.configuration {
                        self.sceneView.session.run(config)
                        self.sendToFlutter("onInitialized", arguments: nil)
                    } else {
                        logPluginError("Failed to create ARConfiguration", toChannel: self.channel)
                    }
                }
            }
            
        }
        
    }
    
    private func runImageDetectionBatches(
        baseArguments: [String: Any],
        imageBatches: [[Any]],
        batchIndex: Int = 0,
        isInitialization: Bool = false
    ) {
        let batchImages = imageBatches[batchIndex]
        var arguments = baseArguments
        arguments["detectionImages"] = batchImages
        configuration = parseConfiguration(arguments)

        sceneView.session.run(configuration!, options: [.resetTracking])
        if(isInitialization) {
            self.sendToFlutter("onInitialized", arguments: nil)
        }

        // Allocate time per batch (Apple-approved behavior)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.runImageDetectionBatches(
                baseArguments: baseArguments,
                imageBatches: imageBatches,
                batchIndex: batchIndex == imageBatches.count - 1 ? 0 : batchIndex + 1
            )
        }
    }

    func parseDebugOptions(_ arguments: [String: Any]) -> SCNDebugOptions {
        var options = ARSCNDebugOptions().rawValue
        if let showFeaturePoint = arguments["showFeaturePoints"] as? Bool {
            if showFeaturePoint {
                options |= ARSCNDebugOptions.showFeaturePoints.rawValue
            }
        }
        if let showWorldOrigin = arguments["showWorldOrigin"] as? Bool {
            if showWorldOrigin {
                options |= ARSCNDebugOptions.showWorldOrigin.rawValue
            }
        }
        return ARSCNDebugOptions(rawValue: options)
    }

    func parseConfiguration(_ arguments: [String: Any]) -> ARConfiguration? {
        let configurationType = arguments["configuration"] as! Int
        var configuration: ARConfiguration?

        switch configurationType {
        case 0:
            configuration = createWorldTrackingConfiguration(arguments)
        case 1:
            #if !DISABLE_TRUEDEPTH_API
                configuration = createFaceTrackingConfiguration(arguments)
            #else
                logPluginError("TRUEDEPTH_API disabled", toChannel: channel)
            #endif
        case 2:
            if #available(iOS 12.0, *) {
                configuration = createImageTrackingConfiguration(arguments)
            } else {
                logPluginError("configuration is not supported on this device", toChannel: channel)
            }
        case 3:
            if #available(iOS 13.0, *) {
                configuration = createBodyTrackingConfiguration(arguments)
            } else {
                logPluginError("configuration is not supported on this device", toChannel: channel)
            }
        case 4:
            if #available(iOS 14.0, *) {
                configuration = createDepthTrackingConfiguration(arguments)
            } else {
                logPluginError("configuration is not supported on this device", toChannel: channel)
            }
        default:
            break
        }
        configuration?.worldAlignment = parseWorldAlignment(arguments)
        return configuration
    }

    func parseWorldAlignment(_ arguments: [String: Any]) -> ARConfiguration.WorldAlignment {
        if let worldAlignment = arguments["worldAlignment"] as? Int {
            if worldAlignment == 0 {
                return .gravity
            }
            if worldAlignment == 1 {
                return .gravityAndHeading
            }
        }
        return .camera
    }
}
