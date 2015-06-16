import Foundation

public class CJBlobEntity {
    public let data: NSData
    public let mime: String
    
    public init(data: NSData, mime: String?) {
        self.data = data
        self.mime = mime ?? "application/octet-stream"
    }
}
