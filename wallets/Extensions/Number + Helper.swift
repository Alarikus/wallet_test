//
//  Number + Helper.swift
//  photo-editor
//
//  Created by Bogdan Redkin on 28/07/2019.
//  Copyright © 2019 Bogdan Redkin. All rights reserved.
//

import CoreGraphics
import Foundation

extension Int {

    var float: Float {
        return Float(self)
    }

    var double: Double {
        return Double(self)
    }

    var cgFloat: CGFloat {
        return CGFloat(self)
    }

    var string: String {
        return String(describing: self)
    }

}

extension Double {
    var float: Float {
        return Float(self)
    }

    var int: Int {
        return Int(self)
    }

    var cgFloat: CGFloat {
        return CGFloat(self)
    }

    var string: String {
        return String(describing: self)
    }
    
    var formattedDecimal: String {
        let number = NSNumber(value: self)
        return number.formattedDecimal
    }
}

extension NSNumber {
    
    var formattedDecimal: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: self) ?? String(describing: self)
    }
    
}
