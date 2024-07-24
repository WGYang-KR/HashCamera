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
    os_log("%@",type:.default ,"\(Timestamp.timestamp())<\(className)> \(functionName) [#\(line)] \(message ?? "")")
}

class Timestamp {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy/MM/dd HH:mm:ss.SSS "
        return formatter
    }()

    static func timestamp() -> String{
        return dateFormatter.string(from: Date())
    }
}
