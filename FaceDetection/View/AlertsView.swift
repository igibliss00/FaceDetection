//
//  AlertsView.swift
//  FaceDetection
//
//  Created by J on 2022-04-19.
//

import UIKit

class Alerts {
    func show(_ error: Error?, for controller: UIViewController?) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        controller?.present(alert, animated: true, completion: nil)
    }
}
