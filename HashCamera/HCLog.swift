//
//  HCLog.swift
//  HashCamera
//
//  Created by WG-MacHome on 10/28/23.
//

import Foundation
import os.log

public func hcLog(_ message: String?, file: String = #file, functionName: String = #function , line: UInt = #line) {
    
    
#if RELEASE
    return
#endif
    
    
    let className = (file as NSString).lastPathComponent
    os_log("%@",type:.default ,"[\(message ?? "")] <\(className)> \(functionName) [#\(line)]")
}
