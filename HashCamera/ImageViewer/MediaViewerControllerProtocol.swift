//
//  MediaViewerControllerProtocol.swift
//  HashCamera
//
//  Created by Anto-Yang on 5/23/25.
//

import UIKit

protocol MediaViewerControllerProtocol: UIViewController {
    var index: Int { get set }
    var imageItem: ImageFileModel! { get set }
    
    func zoomOut()
    func cancelRotate()
    func confirmRotate()
    func rotateLeft()
}
