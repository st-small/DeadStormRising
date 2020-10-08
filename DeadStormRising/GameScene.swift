//
//  GameScene.swift
//  DeadStormRising
//
//  Created by Stanly Shiyanovskiy on 07.10.2020.
//

import SpriteKit
import GameplayKit

public enum Player {
    case none, red, blue
}

public enum zPositions {
    static let base: CGFloat = 10
    static let bullet: CGFloat = 20
    static let unit: CGFloat = 30
    static let smoke: CGFloat = 40
    static let fire: CGFloat = 50
    static let selectionMarker: CGFloat = 60
    static let menuBar: CGFloat = 100
}

public final class GameScene: SKScene {
    
    private var lastTouch = CGPoint.zero
    private var originalTouch = CGPoint.zero
    private var cameraNode: SKCameraNode!
    
    private var menuBar: SKSpriteNode!
    private var menuBarPlayer: SKSpriteNode!
    private var menuBarEndTurn: SKSpriteNode!
    private var menuBarCapture: SKSpriteNode!
    private var menuBarBuild: SKSpriteNode!
    
    private var currentPlayer = Player.red
    private var bases = [Base]()
    private var units = [Unit]()
    
    private var selectedItem: GameItem? {
        didSet {
            selectedItemChanged()
        }
    }
    
    private var selectionMarker: SKSpriteNode!
    private var moveSquares = [SKSpriteNode]()
    
    public override func didMove(to view: SKView) {
        cameraNode = camera!
        
        for _ in 0 ..< 41 {
            // we need exactly 41 squares to highlight all possible moves
            let moveSquare = SKSpriteNode(color: UIColor.white, size: CGSize(width: 64, height: 64))
            moveSquare.alpha = 0
            moveSquare.name = "move"
            moveSquares.append(moveSquare)
            addChild(moveSquare)
        }

        selectionMarker = SKSpriteNode(imageNamed: "selectionMarker")
        selectionMarker.zPosition = zPositions.selectionMarker
        addChild(selectionMarker)
        hideSelectionMarker()

        createStartingLayout()
        createMenuBar()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastTouch = touch.location(in: self.view)
        originalTouch = lastTouch
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self.view)

        let newX = cameraNode.position.x + (lastTouch.x - touchLocation.x)
        let newY = cameraNode.position.y + (touchLocation.y - lastTouch.y)
        cameraNode.position = CGPoint(x: newX, y: newY)

        lastTouch = touchLocation
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchesMoved(touches, with: event)

        let distance = originalTouch.manhattanDistance(to: lastTouch)

        if distance < 44 {
            nodesTapped(at: touch.location(in: self))
        }
    }
    
    private func createStartingLayout() {
        for row in 0 ..< 3 {
            for col in 0 ..< 3 {
                let base = Base(imageNamed: "base")
                base.position = CGPoint(x: -256 + (col * 256), y: -64 + (row * 256))
                base.zPosition = zPositions.base
                //bases.append(base)
                addChild(base)
            }
        }

        for i in 0 ..< 5 {
            let unit = Unit(imageNamed: "tankRed")
            unit.owner = .red
            unit.position = CGPoint(x: -128 + (i * 64), y: -320)
            unit.zPosition = zPositions.unit
            units.append(unit)
            addChild(unit)
        }

        for i in 0 ..< 5 {
            let unit = Unit(imageNamed: "tankBlue")
            unit.owner = .blue
            unit.position = CGPoint(x: -128 + (i * 64), y: -128)
            unit.zPosition = zPositions.unit
            unit.zRotation = CGFloat.pi
            units.append(unit)
            addChild(unit)
        }
    }
    
    private func createMenuBar() {
        menuBar = SKSpriteNode(color: UIColor(white: 0, alpha: 0.66), size: CGSize(width: 1024, height: 60))
        menuBar.position = CGPoint(x: 0, y: 354)
        menuBar.zPosition = zPositions.menuBar
        cameraNode.addChild(menuBar)

        menuBarPlayer = SKSpriteNode(imageNamed: "red")
        menuBarPlayer.anchorPoint = CGPoint(x: 0, y: 0.5)
        menuBarPlayer.position = CGPoint(x: -512 + 20, y: 0)
        menuBar.addChild(menuBarPlayer)

        menuBarEndTurn = SKSpriteNode(imageNamed: "redEndTurn")
        menuBarEndTurn.anchorPoint = CGPoint(x: 1, y: 0.5)
        menuBarEndTurn.position = CGPoint(x: 512 - 20, y: 0)
        menuBarEndTurn.name = "endturn"
        menuBar.addChild(menuBarEndTurn)

        menuBarCapture = SKSpriteNode(imageNamed: "capture")
        menuBarCapture.position = CGPoint(x: 0, y: 0)
        menuBarCapture.name = "capture"
        menuBar.addChild(menuBarCapture)
        hideCaptureMenu()

        menuBarBuild = SKSpriteNode(imageNamed: "build")
        menuBarBuild.position = CGPoint(x: 0, y: 0)
        menuBarBuild.name = "build"
        menuBar.addChild(menuBarBuild)
        hideBuildMenu()
    }
    
    private func nodesTapped(at point: CGPoint) {
        let tappedNodes = nodes(at: point)

        var tappedMove: SKNode!
        var tappedUnit: Unit!
        var tappedBase: Base!

        for node in tappedNodes {
            if node is Unit {
                tappedUnit = node as? Unit
            } else if node is Base {
                tappedBase = node as? Base
            } else if node.name == "move" {
                tappedMove = node
            } else if node.name == "endturn" {
                endTurn()
                return
            } else if node.name == "capture" {
                captureBase()
                return
            } else if node.name == "build" {
                guard let selectedBase = selectedItem as? Base else { return }

                if let unit = selectedBase.buildUnit() {
                    units.append(unit)
                    addChild(unit)
                }

                selectedItem = nil
                return
            }
        }

        if tappedMove != nil {
            // move or attack
            guard let selectedUnit = selectedItem as? Unit else { return }
            let tappedUnits = units.itemsAt(position: tappedMove.position)

            if tappedUnits.count == 0 {
                selectedUnit.move(to: tappedMove)
            } else {
                selectedUnit.attack(target: tappedUnits[0])
            }

            selectedItem = nil
        } else if tappedUnit != nil {
            // user tapped a unit
            if selectedItem != nil && tappedUnit == selectedItem {
                // it was already selected; deselect it
                selectedItem = nil
            } else {
                // don't let us control enemy units or dead units
                if tappedUnit.owner == currentPlayer && tappedUnit.isAlive {
                    selectedItem = tappedUnit
                }
            }
        } else if tappedBase != nil {
            if tappedBase.owner == currentPlayer {
                selectedItem = tappedBase
            }
        } else {
            selectedItem = nil
        }
    }
    
    private func endTurn() {
        if currentPlayer == .red {
            // switch the controlling player
            currentPlayer = .blue

            // update the two textures
            menuBarEndTurn.texture = SKTexture(imageNamed: "blueEndTurn")
            let setTexture = SKAction.setTexture(SKTexture(imageNamed: "blue"), resize: true)
            menuBarPlayer.run(setTexture)
        } else {
            currentPlayer = .red
            menuBarEndTurn.texture = SKTexture(imageNamed: "redEndTurn")
            let setTexture = SKAction.setTexture(SKTexture(imageNamed: "red"), resize: true)
            menuBarPlayer.run(setTexture)
        }

        // reset all bases and units
        bases.forEach { $0.reset() }
        units.forEach { $0.reset() }

        // remove any dead units
        units = units.filter { $0.isAlive }

        // clear whatever was selected
        selectedItem = nil
    }
    
    private func captureBase() {
        guard let item = selectedItem else { return }
        let currentBases = bases.itemsAt(position: item.position)

        if currentBases.count > 0 {
            if currentBases[0].owner != currentPlayer {
                currentBases[0].setOwner(currentPlayer)
                selectedItem = nil
            }
        }
    }
    
    private func showSelectionMarker() {
        guard let item = selectedItem else { return }
        selectionMarker.removeAllActions()

        selectionMarker.position = item.position
        selectionMarker.alpha = 1

        let rotate = SKAction.rotate(byAngle: -CGFloat.pi, duration: 1)
        let repeatForever = SKAction.repeatForever(rotate)
        selectionMarker.run(repeatForever)
    }

    private func hideSelectionMarker() {
        selectionMarker.removeAllActions()
        selectionMarker.alpha = 0
    }
    
    private func selectedItemChanged() {
        hideMoveOptions()
        hideCaptureMenu()
        hideBuildMenu()

        if let item = selectedItem {
            showSelectionMarker()

            if selectedItem is Unit {
                showMoveOptions()

                let currentBases = bases.itemsAt(position: item.position)

                if currentBases.count > 0 {
                    if currentBases[0].owner != currentPlayer {
                        showCaptureMenu()
                    }
                }
            } else {
                showBuildMenu()
            }
        } else {
            hideSelectionMarker()
        }
    }
    
    private func showMoveOptions() {
        guard let selectedUnit = selectedItem as? Unit else { return }
        hideMoveOptions()

        var counter = 0

        for row in -5 ..< 5 {
            for col in -5 ..< 5 {
                let distance = abs(col) + abs(row)
                guard distance <= 4 else { continue }

                let squarePosition = CGPoint(x: selectedUnit.position.x + CGFloat(col * 64), y: selectedUnit.position.y + CGFloat(row * 64))
                let currentUnits = units.itemsAt(position: squarePosition)
                var isAttack = false

                if currentUnits.count > 0 {
                    if currentUnits[0].owner == currentPlayer || currentUnits[0].isAlive == false {
                        continue
                    } else {
                        isAttack = true
                    }
                }

                if isAttack {
                    guard selectedUnit.hasFired == false else { continue }
                    moveSquares[counter].color = UIColor.red
                } else {
                    guard selectedUnit.hasMoved == false else { continue }
                    moveSquares[counter].color = UIColor.white
                }

                moveSquares[counter].position = squarePosition
                moveSquares[counter].alpha = 0.35
                counter += 1
            }
        }
    }
    
    private func hideMoveOptions() {
        moveSquares.forEach {
            $0.alpha = 0
        }
    }

    private func hideCaptureMenu() {
        menuBarCapture.alpha = 0
    }

    private func showCaptureMenu() {
        menuBarCapture.alpha = 1
    }

    private func hideBuildMenu() {
        menuBarBuild.alpha = 0
    }

    private func showBuildMenu() {
        menuBarBuild.alpha = 1
    }
}
