import Foundation
import SceneKit
import UIKit

public class FirstPersonController {
    public let playerNode: SCNNode
    public let cameraNode: SCNNode
    public let flashlightNode: SCNNode
    public let flashlight: SCNLight
    public let weaponMountNode: SCNNode

    public var yaw: Float = 0.0
    public var pitch: Float = 0.0
    public let eyeHeight: Float = 1.75
    public var moveSpeed: Float = 5.2
    public var sensitivity: Float = 1.0

    public private(set) var isFlashlightOn: Bool = true
    private var bobbingTimer: Float = 0.0
    private let defaultWeaponPos = SCNVector3(0.06, -0.06, -0.16)

    public init() {
        playerNode = SCNNode()
        playerNode.name = "Player"
        playerNode.position = SCNVector3(0, eyeHeight, 15)

        // Telecamera HDR cinematica
        let camera = SCNCamera()
        camera.zNear = 0.05
        camera.zFar = 160.0
        camera.fieldOfView = 68.0
        camera.wantsHDR = true
        camera.exposureOffset = 0.4

        // Post-processing: Bloom & Vignette
        camera.bloomIntensity = 1.25
        camera.bloomThreshold = 0.65
        camera.bloomBlurRadius = 14.0
        camera.vignettingIntensity = 0.60
        camera.vignettingPower = 1.20

        cameraNode = SCNNode()
        cameraNode.name = "Camera"
        cameraNode.camera = camera
        playerNode.addChildNode(cameraNode)

        // Torcia dello Sceriffo (Ottimizzata: senza self-shadow buggati e con fascio caldo concentrato)
        flashlight = SCNLight()
        flashlight.type = .spot
        flashlight.spotInnerAngle = 22.0
        flashlight.spotOuterAngle = 48.0
        flashlight.color = UIColor(red: 1.0, green: 0.95, blue: 0.82, alpha: 1.0)
        flashlight.intensity = 2200
        flashlight.attenuationStartDistance = 1.2
        flashlight.attenuationEndDistance = 44.0
        flashlight.attenuationFalloffExponent = 2.0
        flashlight.castsShadow = false // Evita artefatti neri di self-shadowing sull'arma e sulla vista

        flashlightNode = SCNNode()
        flashlightNode.name = "Flashlight"
        flashlightNode.light = flashlight
        // Posizionata leggermente avanzata rispetto alla telecamera per non illuminare l'interno della testa
        flashlightNode.position = SCNVector3(0.14, -0.08, -0.22)
        cameraNode.addChildNode(flashlightNode)

        // Supporto per il modello dell'arma in prima persona (Viewmodel)
        weaponMountNode = SCNNode()
        weaponMountNode.name = "WeaponMount"
        weaponMountNode.position = defaultWeaponPos
        cameraNode.addChildNode(weaponMountNode)
    }

    public func toggleFlashlight() -> Bool {
        isFlashlightOn.toggle()
        flashlight.intensity = isFlashlightOn ? 2200 : 0
        return isFlashlightOn
    }

    public func updateRotation(deltaYaw: Float, deltaPitch: Float) {
        yaw -= deltaYaw * sensitivity
        pitch -= deltaPitch * sensitivity
        pitch = max(-1.18, min(1.18, pitch)) // Circa -68° a +68°

        playerNode.eulerAngles = SCNVector3(0, yaw, 0)
        cameraNode.eulerAngles = SCNVector3(pitch, 0, 0)
    }

    public func updateMovement(forward: Float, strafe: Float, deltaTime: Float, boundaryChecker: ((SCNVector3) -> Bool)? = nil) {
        let isMoving = abs(forward) > 0.05 || abs(strafe) > 0.05

        if isMoving {
            let speed = moveSpeed * deltaTime
            let sinY = sin(yaw)
            let cosY = cos(yaw)

            let dx = (-sinY * forward + cosY * strafe) * speed
            let dz = (-cosY * forward - sinY * strafe) * speed

            let newPos = SCNVector3(
                playerNode.position.x + dx,
                playerNode.position.y,
                playerNode.position.z + dz
            )

            if let checker = boundaryChecker {
                if checker(newPos) {
                    playerNode.position = newPos
                }
            } else {
                playerNode.position = newPos
            }

            // Oscillazione arma e passo realistica
            bobbingTimer += deltaTime * 8.5
            let bobX = cos(bobbingTimer * 0.5) * 0.007
            let bobY = sin(bobbingTimer) * 0.010
            weaponMountNode.position = SCNVector3(
                defaultWeaponPos.x + Float(bobX),
                defaultWeaponPos.y + Float(bobY),
                defaultWeaponPos.z
            )
        } else {
            weaponMountNode.position = defaultWeaponPos
        }
    }

    public func applyRecoil(intensity: Float) {
        let kickZ = 0.05 * intensity
        let kickRotX = 0.12 * intensity

        let actionUp = SCNAction.moveBy(x: 0, y: CGFloat(kickZ * 0.4), z: CGFloat(kickZ), duration: 0.04)
        let rotUp = SCNAction.rotateBy(x: CGFloat(kickRotX), y: 0, z: 0, duration: 0.04)
        let groupUp = SCNAction.group([actionUp, rotUp])

        let actionDown = SCNAction.moveBy(x: 0, y: CGFloat(-kickZ * 0.4), z: CGFloat(-kickZ), duration: 0.16)
        let rotDown = SCNAction.rotateBy(x: CGFloat(-kickRotX), y: 0, z: 0, duration: 0.16)
        let groupDown = SCNAction.group([actionDown, rotDown])

        weaponMountNode.runAction(SCNAction.sequence([groupUp, groupDown]))
    }
}
