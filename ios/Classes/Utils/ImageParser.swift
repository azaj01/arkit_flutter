import Foundation

func getImageByName(_ name: String) -> UIImage? {
    if let img = UIImage(named: name) {
        return img
    }
    if let path = Bundle.main.path(forResource: SwiftArkitPlugin.registrar!.lookupKey(forAsset: name), ofType: nil) {
        let img = UIImage(named: path)
        if img == nil {
            debugPrint("getImageByName: failed to load asset image at path \(path) for \(name)")
        }
        return img
    }
    if let url = URL(string: name) {
        let (data, response, error) = fetchUrlData(url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let httpURLString = http.url?.absoluteString ?? ""
            debugPrint("getImageByName: network non-2xx status \(http.statusCode) url \(httpURLString)")
        }

        if let error = error {
            let nsError = error as NSError
            debugPrint(
                "getImageByName: network load failed for \(name) (\(url)) " +
                "error: \(nsError.localizedDescription) " +
                "domain: \(nsError.domain) code: \(nsError.code) " +
                "userInfo: \(nsError.userInfo)"
            )
            return nil
        }

        guard let data = data else {
            debugPrint("getImageByName: network returned no data for \(name)")
            return nil
        }

        let img = UIImage(data: data)
        if img == nil {
            debugPrint("getImageByName: network data not decodable as image for \(name) (bytes: \(data.count))")
        }
        return img
    }
    if let base64 = Data(base64Encoded: name, options: .ignoreUnknownCharacters) {
        let img = UIImage(data: base64)
        if img == nil {
            debugPrint("getImageByName: base64 data not decodable as image (bytes: \(base64.count))")
        }
        return img
    }
    debugPrint("getImageByName: failed to resolve image for \(name)")
    return nil
}

private func fetchUrlData(_ url: URL) -> (Data?, URLResponse?, Error?) {
    let sessionConfig = URLSessionConfiguration.ephemeral
    sessionConfig.timeoutIntervalForRequest = 15
    sessionConfig.timeoutIntervalForResource = 20

    let session = URLSession(configuration: sessionConfig)
    var request = URLRequest(url: url)
    request.cachePolicy = .reloadIgnoringLocalCacheData
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

    let semaphore = DispatchSemaphore(value: 0)
    var resultData: Data?
    var resultResponse: URLResponse?
    var resultError: Error?

    let task = session.dataTask(with: request) { data, response, error in
        resultData = data
        resultResponse = response
        resultError = error
        semaphore.signal()
    }
    task.resume()

    let waitResult = semaphore.wait(timeout: .now() + 20)
    if waitResult == .timedOut {
        let timeoutError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "URLSession timed out"]
        )
        return (nil, nil, timeoutError)
    }

    return (resultData, resultResponse, resultError)
}