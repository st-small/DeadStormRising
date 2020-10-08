//
//  CGPoint+Additions.swift
//  DeadStormRising
//
//  Created by Stanly Shiyanovskiy on 07.10.2020.
//

import UIKit

extension CGPoint {
    func manhattanDistance(to: CGPoint) -> CGFloat {
        return (abs(x - to.x) + abs(y - to.y))
    }
}
