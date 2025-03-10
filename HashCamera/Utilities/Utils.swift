//
//  Utils.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/24/24.
//

import UIKit
import os.log

class Utils {
    
    // 특정 요소를 다른 위치로 이동하는 함수
    static func moveItem<T>(array: inout [T], fromIndex: Int, toIndex: Int) {
        let element = array.remove(at: fromIndex)
        array.insert(element, at: toIndex)
    }
    
    ///앱 SandBox documnets 디렉토리 URL, nil일 때는 '/' path를 반환한다.
    static var documentsFolderURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/")
    }
    
}


//MARK: - 로그
func hcLog(_ message: String?, file: String = #file, functionName: String = #function , line: UInt = #line) {
    
#if RELEASE
    return
#endif
    
    let className = (file as NSString).lastPathComponent
    os_log("%@",type:.default ,"\(Timestamp.timestamp())<\(className)> \(functionName) [#\(line)] \(message ?? "")")
}

func hcLog(_ message: String?, file: String = #file, functionName: String = #function , line: UInt = #line, error: Error?) {
    
#if RELEASE
    return
#endif
    if let error {
        let className = (file as NSString).lastPathComponent
        os_log("%@",type:.default ,"\(Timestamp.timestamp())<\(className)> \(functionName) [#\(line)] \(message ?? "") | \(error) | \(error.localizedDescription)")
    } else {
        hcLog(message,file: file, functionName: functionName, line: line)
    }
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


//MARK: - UIColor+Utils
extension UIColor {
    static func by(r: Int, g: Int, b: Int, a: CGFloat = 1) -> UIColor {
        let d = CGFloat(255)
        return UIColor(red: CGFloat(r) / d, green: CGFloat(g) / d, blue: CGFloat(b) / d, alpha: a)
    }
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

//MARK: - TableView
extension UITableView {
    func reloadData(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0, animations: {
            self.reloadData()
        }) { _ in
            completion()
        }
    }
}


//MARK: - 배열 OutOfBound 체크
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


//MARK: - 뷰 레이아웃
extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}


//MARK: - UserDefaults
extension UserDefaults {

    ///커스텀 Object 저장
    func setObject<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            self.set(data, forKey: key)
        } catch {
            hcLog("Failed to encode \(T.self): \(error)")
        }
    }
    
    ///커스텀 Object 조회
    func getObject<T: Codable>(forKey key: String, objectType: T.Type) -> T? {
        guard let data = self.data(forKey: key) else { return nil }
        do {
            let object = try JSONDecoder().decode(objectType, from: data)
            return object
        } catch {
            hcLog("Failed to decode \(T.self): \(error)")
            return nil
        }
    }
}

