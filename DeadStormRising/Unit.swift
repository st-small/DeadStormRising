//
//  Unit.swift
//  DeadStormRising
//
//  Created by Stanly Shiyanovskiy on 07.10.2020.
//

import SpriteKit
import UIKit

public final class Unit: GameItem {
    
    public var hasMoved = false
    public var hasFired = false
    public var isAlive = true
    
    // give each unit 3 health points by default
    private var health = 3 {
        didSet {
            // remove any existing flashing for this unit
            removeAllActions()

            // if we still have health...
            if health > 0 {
                // make fade out and fade in actions
                let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.25 * Double(health))
                let fadeIn = SKAction.fadeAlpha(to: 1, duration: 0.25 * Double(health))

                // put them together and make them repeat forever
                let sequence = SKAction.sequence([fadeOut, fadeIn])
                let repeatForever = SKAction.repeatForever(sequence)
                run(repeatForever)
            } else {
                // if the tank is destroyed, change its texture to a burnt out tank
                texture = SKTexture(imageNamed: "tankDead")

                // force it to have 100% alpha
                alpha = 1

                // mark it as dead so it can't be moved any more
                isAlive = false
            }
        }
    }
    
    public func move(to target: SKNode) {
        // 1: refuse to let this unit move twice
        guard hasMoved == false else { return }
        hasMoved = true

        var sequence = [SKAction]()

        // 2: if we need to move along the X axis now, calculate that movement and add it to the sequence array
        if position.x != target.position.x {
            let path = UIBezierPath()
            path.move(to: CGPoint.zero)
            path.addLine(to: CGPoint(x: target.position.x - position.x, y: 0))
            sequence.append(SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: 200))
        }

        // 3: repeat for the Y axis
        if position.y != target.position.y {
            let path = UIBezierPath()
            path.move(to: CGPoint.zero)
            path.addLine(to: CGPoint(x: 0, y: target.position.y - position.y))
            sequence.append(SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: 200))
        }

        // run the complete sequence of moves
        run(SKAction.sequence(sequence))
    }

    public func attack(target: Unit) {
        // 1: make sure this unit hasn't fired already
        guard hasFired == false else { return }
        hasFired = true

        // 2: turn it to face its target
        rotate(toFace: target)

        // 3: create a new bullet and give it the same color as this tank
        let bullet: SKSpriteNode

        if owner == .red {
            bullet = SKSpriteNode(imageNamed: "bulletRed")
        } else {
            bullet = SKSpriteNode(imageNamed: "bulletBlue")
        }

        // 4: place the bullet underneath the unit so it looks like it comes from inside the barrel
        bullet.zPosition = zPositions.bullet

        // 5: add the bullet to our parent – i.e. the game scene
        parent?.addChild(bullet)

        // 6: draw a path from the bullet to the target
        let path = UIBezierPath()
        path.move(to: position)
        path.addLine(to: target.position)

        // 7: create an action for that movement
        let move = SKAction.follow(path.cgPath, asOffset: false, orientToPath: true, speed: 500)

        // 8: create an action that makes the target take damage
        let damageTarget = SKAction.run { [unowned target] in
            target.takeDamage()
        }

        // 9: create an action for the smoke and fire particle emitters
        let createExplosion = SKAction.run { [unowned self] in
            // create the smoke emitter
            if let smoke = SKEmitterNode(fileNamed: "Smoke") {
                smoke.position = target.position
                smoke.zPosition = zPositions.smoke
                self.parent?.addChild(smoke)
            }

            // create the fire emitter over the smoke emitter
            if let fire = SKEmitterNode(fileNamed: "Fire") {
                fire.position = target.position
                fire.zPosition = zPositions.fire
                self.parent?.addChild(fire)
            }
        }

        // 10: create a combined sequence: bullet moves, target takes damage
        // explosion is created, then the bullet is removed from the game
        let sequence = [move, damageTarget, createExplosion, SKAction.removeFromParent()]

        // 11: run that sequence on the bullet
        bullet.run(SKAction.sequence(sequence))
    }
    
    private func takeDamage() {
        health -= 1
    }

    private func rotate(toFace node: SKNode) {
        let angle = atan2(node.position.y - position.y, node.position.x - position.x)
        zRotation = angle - (CGFloat.pi / 2)
    }

    public func reset() {
        if isAlive == true {
            hasFired = false
            hasMoved = false
        } else {
            let fadeAway = SKAction.fadeOut(withDuration: 0.5)
            let sequence = [fadeAway, SKAction.removeFromParent()]
            run(SKAction.sequence(sequence))
        }
    }
}
