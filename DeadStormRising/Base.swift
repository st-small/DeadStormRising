//
//  Base.swift
//  DeadStormRising
//
//  Created by Stanly Shiyanovskiy on 07.10.2020.
//

import SpriteKit
import UIKit

public final class Base: GameItem {

    private var hasBuilt = false

    public func reset() {
        hasBuilt = false
    }

    public func setOwner(_ owner: Player) {
        self.owner = owner
        hasBuilt = true
        self.colorBlendFactor = 0.9

        if owner == .red {
            color = UIColor(red: 1, green: 0.4, blue: 0.1, alpha: 1)
        } else {
            color = UIColor(red: 0.1, green: 0.5, blue: 1, alpha: 1)
        }
    }

    public func buildUnit() -> Unit? {
        // 1: ensure bases build only one thing per turn
        guard hasBuilt == false else { return nil }
        hasBuilt = true

        // 2: create the new unit
        let unit: Unit

        if owner == .red {
            unit = Unit(imageNamed: "tankRed")
        } else {
            unit = Unit(imageNamed: "tankBlue")
        }

        // 3: mark it as having moved and fired already
        unit.hasMoved = true
        unit.hasFired = true

        // 4 give it the same owner and position as this base
        unit.owner = owner
        unit.position = position

        // 5: give it the correct Z position
        unit.zPosition = zPositions.unit

        // 6: send it back to the caller
        return unit
    }
}
