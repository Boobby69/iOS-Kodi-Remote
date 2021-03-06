//
//  HostFinder.swift
//  iOS-Kodi-Remote
//
//  Created by David Rodrigues on 09/08/2015.
//
//

import Foundation

class HostFinder : NSObject {
    
    var completion:(NSArray) -> Void = { (array) -> Void in }
    var array:NSMutableArray = NSMutableArray()
    
    var running:NSMutableArray = NSMutableArray()
    
    var searchingServices:Bool = false
    
    func searchZeroConfHost(completion: (foundHosts:NSArray) -> Void) {
        self.completion = completion
        
        let netServiceBrowser = NSNetServiceBrowser()
        netServiceBrowser.delegate = self
        
        searchingServices = true
        netServiceBrowser.searchForServicesOfType(DNS_XBMC_SERVICE_NAME, inDomain: "")
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, TIMEOUT), dispatch_get_main_queue(), { () -> Void in
            netServiceBrowser.stop()
        })
    }
    
    func checkIfSearchIsFinished() -> Void {
        if running.count == 0 && self.searchingServices {
            completion(array)
        }
    }

}

extension HostFinder : NSNetServiceBrowserDelegate {
    
    /* Sent to the NSNetServiceBrowser instance's delegate before the instance begins a search. The delegate will not receive this message if the instance is unable to begin a search. Instead, the delegate will receive the -netServiceBrowser:didNotSearch: message.
    */
    func netServiceBrowserWillSearch(aNetServiceBrowser: NSNetServiceBrowser) {
        print(__FUNCTION__)
        array = NSMutableArray()
    }
    
    /* Sent to the NSNetServiceBrowser instance's delegate when the instance's previous running search request has stopped.
    */
    func netServiceBrowserDidStopSearch(aNetServiceBrowser: NSNetServiceBrowser) {
        print(__FUNCTION__)
        checkIfSearchIsFinished()
    }
    
    /* Sent to the NSNetServiceBrowser instance's delegate when an error in searching for domains or services has occurred. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a search has been started successfully.
    */
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("\(__FUNCTION__) \(errorDict)")
        checkIfSearchIsFinished()
    }
    
    /* Sent to the NSNetServiceBrowser instance's delegate for each domain discovered. If there are more domains, moreComing will be YES. If for some reason handling discovered domains requires significant processing, accumulating domains until moreComing is NO and then doing the processing in bulk fashion may be desirable.
    */
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print("\(__FUNCTION__) \(domainString) \(moreComing)")
    }
    
    /* Sent to the NSNetServiceBrowser instance's delegate for each service discovered. If there are more services, moreComing will be YES. If for some reason handling discovered services requires significant processing, accumulating services until moreComing is NO and then doing the processing in bulk fashion may be desirable.
    */
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didFindService aNetService: NSNetService, moreComing: Bool) {
        
        aNetService.delegate = self
        running.addObject(aNetService)
        aNetService.resolveWithTimeout(10)
        
        print("\(__FUNCTION__) \(aNetService) \(moreComing)")
        
        
        if !moreComing {
            aNetServiceBrowser.stop()
        }
    }
    
    /* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered domain is no longer available.
    */
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        print("\(__FUNCTION__) \(domainString) \(moreComing)")
    }
    
    /* Sent to the NSNetServiceBrowser instance's delegate when a previously discovered service is no longer published.
    */
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didRemoveService aNetService: NSNetService, moreComing: Bool) {
        // If the net service was trying to resolve an IP address, we stop it
        aNetService.stop()
        
        let hostInformation = HostInformation(netService: aNetService)
        
        print("\(__FUNCTION__) \(hostInformation) \(moreComing)")
        
        array.removeObject(hostInformation)
    }
    
}

extension HostFinder : NSNetServiceDelegate {
    /* Sent to the NSNetService instance's delegate prior to advertising the service on the network. If for some reason the service cannot be published, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotPublish: method.
    */
    func netServiceWillPublish(sender: NSNetService) {
        print(__FUNCTION__)
    }
    
    /* Sent to the NSNetService instance's delegate when the publication of the instance is complete and successful.
    */
    func netServiceDidPublish(sender: NSNetService) {
        print(__FUNCTION__)
    }
    
    /* Sent to the NSNetService instance's delegate when an error in publishing the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a successful publication.
    */
    func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        print(__FUNCTION__)
    }
    
    /* Sent to the NSNetService instance's delegate prior to resolving a service on the network. If for some reason the resolution cannot occur, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotResolve: method.
    */
    func netServiceWillResolve(sender: NSNetService) {
        print(__FUNCTION__)
    }
    
    /* Sent to the NSNetService instance's delegate when one or more addresses have been resolved for an NSNetService instance. Some NSNetService methods will return different results before and after a successful resolution. An NSNetService instance may get resolved more than once; truly robust clients may wish to resolve again after an error, or to resolve more than once.
    */
    func netServiceDidResolveAddress(sender: NSNetService) {
        print(__FUNCTION__)
        let hostInformation = HostInformation(netService: sender)
        
        array.addObject(hostInformation)
        removeRunningService(sender)
    }
    
    /* Sent to the NSNetService instance's delegate when an error in resolving the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants).
    */
    func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        print("\(__FUNCTION__) \(sender) \(errorDict)")
        let error: Int = errorDict[NSNetServicesErrorCode]!.integerValue
        if error == NSNetServicesError.ActivityInProgress.rawValue {
            print("ActivityInProgress")
        } else if error == NSNetServicesError.BadArgumentError.rawValue {
            print("BadArgumentError")
        } else if error == NSNetServicesError.CancelledError.rawValue {
            print("CancelledError")
        } else if error == NSNetServicesError.CollisionError.rawValue {
            print("CollisionError")
        } else if error == NSNetServicesError.InvalidError.rawValue {
            print("InvalidError")
        } else if error == NSNetServicesError.NotFoundError.rawValue {
            print("NotFoundError")
        } else if error == NSNetServicesError.TimeoutError.rawValue {
            print("TimeoutError")
        } else if error == NSNetServicesError.UnknownError.rawValue {
            print("UnknownError")
        }
        sender.stop()
        removeRunningService(sender)
    }
    
    /* Sent to the NSNetService instance's delegate when the instance's previously running publication or resolution request has stopped.
    */
    func netServiceDidStop(sender: NSNetService) {
        print(__FUNCTION__)
        removeRunningService(sender)
    }
    
    /* Sent to the NSNetService instance's delegate when the instance is being monitored and the instance's TXT record has been updated. The new record is contained in the data parameter.
    */
    func netService(sender: NSNetService, didUpdateTXTRecordData data: NSData) {
        print(__FUNCTION__)
    }
    
    func removeRunningService(aNetService: NSNetService) {
        running.removeObject(aNetService)
        checkIfSearchIsFinished()
    }
}
