import Foundation
import AFNetworking

var CJRequestSerializer_instance: CJRequestSerializer?

@objc
class CJRequestSerializer : AFHTTPRequestSerializer {
    
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!, error: NSErrorPointer) -> NSURLRequest! {
        //NSParameterAssert(request)

        if self.HTTPMethodsEncodingParametersInURI.contains(request.HTTPMethod!.uppercaseString) {
            return super.requestBySerializingRequest(request, withParameters: parameters, error: error)
        }
        
        var mRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
        
        for (key, val) in self.HTTPRequestHeaders {
            if let field = key as? String {
                if let value = val as? String {
                    if request.valueForHTTPHeaderField(field) == nil {
                        mRequest.setValue(value, forHTTPHeaderField: field)
                    }
                }
            }
        }
        
        if let params = parameters as? [NSObject: AnyObject] {
            if mRequest.valueForHTTPHeaderField("content-type") == nil {
                mRequest.setValue("application/vnd.collection+json", forHTTPHeaderField: "content-type")
            }
            
            let template = CJTemplate(data: CJData.fromDict(params))
            mRequest.HTTPBody = NSJSONSerialization.dataWithJSONObject(template.toSeri(), options: NSJSONWritingOptions.allZeros, error: error)
        } else if let template = parameters as? CJTemplate {
            if mRequest.valueForHTTPHeaderField("content-type") == nil {
                mRequest.setValue("application/vnd.collection+json", forHTTPHeaderField: "content-type")
            }
            
            mRequest.HTTPBody = NSJSONSerialization.dataWithJSONObject(template.toSeri(), options: NSJSONWritingOptions.allZeros, error: error)
        } else if let entity = parameters as? CJBlobEntity {
            if mRequest.valueForHTTPHeaderField("content-type") == nil {
                mRequest.setValue(entity.mime, forHTTPHeaderField: "content-type")
            }
            
            mRequest.HTTPBody = entity.data
        }
        
        return mRequest
    }

    class func instance() -> CJRequestSerializer {
        if CJRequestSerializer_instance == nil {
            CJRequestSerializer_instance = CJRequestSerializer() as CJRequestSerializer
        }
        return CJRequestSerializer_instance!
    }
}
