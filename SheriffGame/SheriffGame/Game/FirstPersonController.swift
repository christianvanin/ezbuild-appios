import Foundation
import SceneKit
import UIKit

class FirstPersonController {
    let playerNode: SCNNode
    let cameraNode: SCNNode
    let flashlightNode: SCNNode
    let weaponMountNode: SCNNode

    var yaw: Float = 0.0          // Rotazione orizzontale (attorno asse Y)
    var pitch: Float = 0.0        // Rotazione verticale (su/giù, asse X)
    let eyeHeight: Float = 1.7
    var moveSpeed: Float = 5.0

    private var bobbingTimer: Float = 0.0
    private let defaultWeaponPos = SCNVector3(0.05, -0.05, -0.15)

    init() {
        // Nodo radice del giocatore (gestisce posizione X/Z nel mondo)
        playerNode = SCNNode()
        playerNode.name = "Player"
        playerNode.position = SCNVector3(0, eyeHeight, 20)

        // Telecamera in prima persona
        let camera = SCNCamera()
        camera.zNear = 0.05
        camera.zFar = 120.0
        camera.fieldOfView = 68.0
        camera.wantsHDR = true
        camera.exposureOffset = 0.5

        cameraNode = SCNNode()
        cameraNode.name = "Camera"
        cameraNode.camera = camera
        playerNode.addChildNode(cameraNode)

        // Torcia dello Sceriffo (Spotlight montata sulla camera)
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.spotInnerAngle = 35.0
        spotLight.spotOuterAngle = 55.0
        spotLight.color = UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        spotLight.intensity = 1800
        spotLight.castsShadow = true
        spotLight.shadowMode = .deferred
        spotLight.shadowSampleCount = 4

        flashlightNode = SCNNode()
        flashlightNode.name = "Flashlight"
        flashlightNode.light = spotLight
        flashlightNode.position = SCNVector3(0.15, -0.1, 0)
        cameraNode.addChildNode(flashlightNode)

        // Supporto per arma in prima persona (Viewmodel)
        weaponMountNode = SCNNode()
        weaponMountNode.name = "WeaponMount"
        weaponMountNode.position = defaultWeaponPos
        cameraNode.addChildNode(weaponMountNode)
    }

    func updateRotation(deltaYaw: Float, deltaPitch: Float) {
        yaw -= deltaYaw
        pitch -= deltaPitch
        // Clamp pitch tra circa -65° e +65°
        pitch = max(-1.15, min(1.15, pitch))

        playerNode.eulerAngles = SCNVector3(0, yaw, 0)
        cameraNode.eulerAngles = SCNVector3(pitch, 0, 0)
    }

    func updateMovement(forward: Float, strafe: Float, deltaTime: Float, obstacleChecker: ((SCNVector3) -> Bool)? = nil) {
        let isMoving = abs(forward) > 0.05 || abs(strafe) > 0.05

        if isMoving {
            let speed = moveSpeed * deltaTime
            // Calcolo direzione nello spazio globale basato sullo Yaw
            let sinY = sin(yaw)
            let cosY = cos(yaw)

            let dx = (-sinY * forward + cosY * strafe) * speed
            let dz = (-cosY * forward - sinY * strafe) * speed

            let newPos = SCNVector3(
                playerNode.position.x + dx,
                playerNode.position.y,
                playerNode.position.z + dz
            )

            // Controllo ostacoli/confini foresta
            if let checker = obstacleChecker {
                if checker(newPos) {
                    playerNode.position = newPos
                }
            } else {
                playerNode.position = newPos
            }

            // Head & Weapon bobbing (oscillazione passo)
            bobbingTimer += deltaTime * 8.0
            let bobX = cos(bobbingTimer * 0.5) * 0.008
            let bobY = sin(bobbingTimer) * 0.012
            weaponMountNode.position = SCNVector3(
                defaultWeaponPos.x + Float(bobX),
                defaultWeaponPos.y + Float(bobY),
                defaultWeaponPos.z
            )
        } else {
            // Ritorno morbido alla posizione di riposo
            weaponMountNode.position = defaultWeaponPos
        }
    }

    func applyRecoil(intensity: Float) {
        let kickZ = 0.06 * intensity
        let kickRotX = 0.15 * intensity

        let actionUp = SCNAction.moveBy(x: 0, y: CGFloat(kickZ * 0.5), z: CGFloat(kickZ), duration: 0.05)
        let rotUp = SCNAction.rotateBy(x: CGFloat(kickRotX), y: 0, z: 0, duration: 0.05)
        let groupUp = SCNAction.group([actionUp, rotUp])

        let actionDown = SCNAction.moveBy(x: 0, y: CGFloat(-kickZ * 0.5), z: CGFloat(-kickZ), duration: 0.18)
        let rotDown = SCNAction.rotateBy(x: CGFloat(-kickRotX), y: 0, z: 0, duration: 0.18)
        let groupDown = SCNAction.group([actionDown, rotDown])

        weaponMountNode.runAction(SCNAction.sequence([groupUp, groupDown]))
    }
}
