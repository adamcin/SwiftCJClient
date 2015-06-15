import Foundation

class CJBlobEntity {
    let data: NSData
    let mime: String
    
    init(data: NSData, mime: String?) {
        self.data = data
        self.mime = mime ?? "application/octet-stream"
    }
}
