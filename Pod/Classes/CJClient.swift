import Foundation
import SwiftCJ
import Security
import AFNetworking
import BrightFutures

let SWIFTCJ_SERVICE_ERROR = "CJClient_service_error"

class CJClient {

    let extMan: AFHTTPSessionManager
    let cjMan: AFHTTPSessionManager

    typealias SuccessInterceptor = (CJClient, NSHTTPURLResponse) -> Bool

    init(extMan: AFHTTPSessionManager, cjMan: AFHTTPSessionManager) {
        self.extMan = extMan
        self.cjMan = cjMan
    }

    func toURLString(href: NSURL) -> String {
        //let url = NSURL(string: href.relativeString!, relativeToURL: cjMan.baseURL)!.absoluteString!
        let url = href.relativeString!
        println("url = \(url)")
        return url
    }

    func get(href: NSURL) -> Future<CJCollection, NSError> {
        let promise = Promise<CJCollection, NSError>()
        let task = self.cjMan.GET(toURLString(href), parameters: nil, success: self.successHandler(promise), failure: CJClient.failureHandler(promise))
        task.resume()
        return promise.future
    }

    func delete(href: NSURL) -> Future<Bool, NSError> {
        let promise = Promise<Bool, NSError>()
        let task = self.cjMan.DELETE(toURLString(href), parameters: nil, success: CJClient.deleteSuccessHandler(promise), failure: CJClient.failureHandler(promise))
        task.resume()
        return promise.future
    }

    func query(query: CJQuery) -> Future<CJCollection, NSError> {
        let promise = Promise<CJCollection, NSError>()
        let task = self.cjMan.GET(toURLString(query.href), parameters: query.data?.dict, success: self.successHandler(promise), failure: CJClient.failureHandler(promise))
        task.resume()
        return promise.future
    }

    func put(href: NSURL, template: CJTemplate) -> Future<CJCollection, NSError> {
        let promise = Promise<CJCollection, NSError>()
        let task = self.cjMan.PUT(toURLString(href), parameters: template, success: self.putSuccessHandler(href, promise: promise), failure: CJClient.failureHandler(promise))
        task.resume()
        return promise.future
    }

    func post(href: NSURL, template: CJTemplate) -> Future<CJCollection, NSError> {
        let promise = Promise<CJCollection, NSError>()
        let task = self.cjMan.POST(toURLString(href), parameters: template, success: self.successHandler(promise), failure: CJClient.failureHandler(promise))
        task.resume()
        return promise.future
    }

    func postIntercept(href: NSURL, template: CJTemplate, successInterceptor: SuccessInterceptor) -> Future<CJCollection,NSError> {
        let promise = Promise<CJCollection, NSError>()
        let task = self.cjMan.POST(toURLString(href), parameters: template, success: self.successHandler(promise, successInterceptor: successInterceptor), failure: CJClient.failureHandler(promise))
        task.resume()
        return promise.future
    }

    func upload(href: NSURL, data: NSData) -> Future<String?, NSError> {
        let promise = Promise<CJCollection,NSError>()
        let task = self.cjMan.POST(toURLString(href), parameters: CJBlobEntity(data: data, mime: nil), success: self.successHandler(promise), failure: CJClient.failureHandler(promise))
        task.resume()
        return promise.future.map { $0.items.first?.data?.dict["eTag"] as? String }
    }

    func download(href: NSURL) -> Future<NSData, NSError> {
        let promise = Promise<NSData,NSError>()
        let (urlString, manager) = (href.host != nil && href.host! != self.cjMan.baseURL?.host) ? (href.absoluteString!, self.extMan) : (self.toURLString(href), self.cjMan)

        let task = manager.GET(urlString, parameters: nil, success: CJClient.downloadSuccessHandler(promise), failure: CJClient.failureHandler(promise))
        task.resume()
        return promise.future
    }

    func successHandler(promise: Promise<CJCollection, NSError>) -> (task: NSURLSessionDataTask!, entity: AnyObject!) -> Void {
        return successHandler(promise, successInterceptor: nil)
    }

    func successHandler(promise: Promise<CJCollection, NSError>, successInterceptor: SuccessInterceptor?) -> (task: NSURLSessionDataTask!, entity: AnyObject!) -> Void {
        return { (task: NSURLSessionDataTask!, entity: AnyObject!) -> Void in
            if let response = task.response as? NSHTTPURLResponse {
                if let cj = entity as? CJCollection {
                    if successInterceptor != nil {
                        successInterceptor!(self, response)
                    }
                    promise.success(cj)
                } else  {
                    if let location = response.allHeaderFields["location"] as? String {
                        if successInterceptor != nil {
                            successInterceptor!(self, response)
                        }
                        let redirect = self.cjMan.GET(location, parameters: nil, success: self.successHandler(promise), failure: CJClient.failureHandler(promise))
                        redirect.resume()
                    } else {
                        promise.failure(NSError(domain: "CJClient_expected_CJCollection", code: 1337, userInfo: nil))
                    }
                }
            } else {
                promise.failure(NSError(domain: "CJClient_expected_NSHTTPURLResponse", code: 1337, userInfo: nil))
            }

        }
    }

    func putSuccessHandler(href: NSURL, promise: Promise<CJCollection, NSError>) -> (task: NSURLSessionDataTask!, entity: AnyObject!) -> Void {
        return { (task: NSURLSessionDataTask!, entity: AnyObject!) -> Void in
            if let response = task.response as? NSHTTPURLResponse {
                if let cj = entity as? CJCollection {
                    promise.success(cj)
                } else  {
                    if response.statusCode == 200 {
                        promise.completeWith(self.get(href))
                    } else {
                        promise.failure(NSError(domain: "CJClient_expected_CJCollection", code: 1337, userInfo: nil))
                    }
                }
            } else {
                promise.failure(NSError(domain: "CJClient_expected_NSHTTPURLResponse", code: 1337, userInfo: nil))
            }
        }
    }

    class func deleteSuccessHandler(promise: Promise<Bool, NSError>) -> (task: NSURLSessionDataTask!, entity: AnyObject!) -> Void {
        return { (task: NSURLSessionDataTask!, entity: AnyObject!) -> Void in
            if let response = task.response as? NSHTTPURLResponse {
                if let error = (entity as? CJCollection)?.error {
                    promise.failure(CJClient.toNSError(error, httpCode: response.statusCode))
                } else {
                    promise.success(response.statusCode == 204)
                }
            } else {
                promise.failure(NSError(domain: "CJClient_expected_NSHTTPURLResponse", code: 1337, userInfo: nil))
            }
        }
    }

    class func downloadSuccessHandler(promise: Promise<NSData, NSError>) -> (task: NSURLSessionDataTask!, entity: AnyObject!) -> Void {
        return { (task: NSURLSessionDataTask!, entity: AnyObject!) -> Void in

            if let response = task.response as? NSHTTPURLResponse {
                response
            } else {
                promise.failure(NSError(domain: "CJClient_expected_NSHTTPURLResponse", code: 1337, userInfo: nil))
            }
        }
    }

    class func failureHandler<U>(promise: Promise<U,NSError>) -> (task: NSURLSessionDataTask!, error: NSError!) -> Void {
        return { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
            promise.failure(error)
        }
    }
    
    class func toNSError(error: CJError, httpCode: Int = -1) -> NSError {
        return NSError(domain: SWIFTCJ_SERVICE_ERROR, code: error.code?.toInt() ?? -1, userInfo: ["title": error.title ?? "", "message": error.message ?? "", "status": httpCode, "code": error.code ?? ""])
    }
}
