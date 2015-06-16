import Foundation
import AFNetworking
import SwiftCJ

var CJResponseSerializer_instance: CJResponseSerializer?

@objc
class CJResponseSerializer: AFHTTPResponseSerializer {
    let MIME_CJ = "application/vnd.collection+json"
    override init() {
        super.init()
        if let accTypes = self.acceptableContentTypes {
            self.acceptableContentTypes.insert(MIME_CJ)
        } else {
            self.acceptableContentTypes = Set([MIME_CJ])
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let accTypes = self.acceptableContentTypes {
            self.acceptableContentTypes.insert(MIME_CJ)
        } else {
            self.acceptableContentTypes = Set([MIME_CJ])
        }
    }
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
        println("responseObjectForResponse response: \((response as! NSHTTPURLResponse).statusCode)")
        var stringEncoding = self.stringEncoding
        
        if response.textEncodingName != nil {
            let encoding = CFStringConvertIANACharSetNameToEncoding(response.textEncodingName)
            if encoding != kCFStringEncodingInvalidId {
                stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding)
            }
        }
        
        if data != nil {
            
            let responseString = NSString(data: data, encoding: stringEncoding)
            //println("-- response: \(responseString)")
            var serializationError: NSErrorPointer = nil
            var cj: CJCollection? = nil
            autoreleasepool { () -> () in
                var jsonObj: AnyObject? = nil
                if let respString = responseString as? String {
                    if respString != " " {
                        if let data = respString.dataUsingEncoding(NSUTF8StringEncoding) {
                            if data.length > 0 {
                                jsonObj = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: serializationError)
                            }
                        } else {
                            let userInfo = [
                                NSLocalizedDescriptionKey: "Data failed decoding as a UTF-8 string",
                                NSLocalizedFailureReasonErrorKey: "Could not decode string: \(respString)"
                            ]
                            serializationError.memory = NSError(domain: AFURLResponseSerializationErrorDomain, code: NSURLErrorCannotDecodeContentData, userInfo: userInfo)
                        }
                    }
                }
                if let json = jsonObj as? [NSObject: AnyObject] {
                    var writingError: NSErrorPointer = nil
                    if let dataString = NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted, error: writingError) {
                        println("-- json: \(NSString(data: dataString, encoding: NSUTF8StringEncoding))")
                    }
                    
                    
                    cj = CJCollection.collectionForDictionary(json)
                }
            }
            
            return cj!
        }
        
        return nil
    }

    class func instance() -> CJResponseSerializer {
        if CJResponseSerializer_instance == nil {
            CJResponseSerializer_instance = CJResponseSerializer() as CJResponseSerializer
        }
        return CJResponseSerializer_instance!
    }
    
}
