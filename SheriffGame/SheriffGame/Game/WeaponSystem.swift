import Foundation
import SceneKit
import UIKit

enum WeaponType: String {
    case revolver = "Revolver .45"
    case shotgun = "Doppietta Cal. 12"
}

class WeaponSystem {
    private weak var controller: FirstPersonController?
    private var revolverNode: SCNNode?
    private var shotgunNode: SCNNode?
    private var muzzleFlashLight: SCNLight?
    private var muzzleFlashNode: SCNNode?

    private(set) var currentType: WeaponType = .revolver
    private(set) var hasShotgun: Bool = false

    // Munizioni
    var revolverMag: Int = 6
    let revolverMagCapacity: Int = 6

    var shotgunMag: Int = 2
    var shotgunReserve: Int = 12
    let shotgunMagCapacity: Int = 2

    private var lastShotTime: TimeInterval = 0
    private var isReloading: Bool = false

    init(controller: FirstPersonController) {
        self.controller = controller
        setupMuzzleFlash()
        loadWeaponModels()
        equip(type: .revolver)
    }

    private func setupMuzzleFlash() {
        let flashLight = SCNLight()
        flashLight.type = .omni
        flashLight.color = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
        flashLight.intensity = 0
        flashLight.attenuationEndDistance = 6.0
        self.muzzleFlashLight = flashLight

        let flashNode = SCNNode()
        flashNode.light = flashLight
        flashNode.position = SCNVector3(0.18, -0.05, -0.65)
        controller?.cameraNode.addChildNode(flashNode)
        self.muzzleFlashNode = flashNode
    }

    private func loadWeaponModels() {
        if let revUrl = Bundle.main.url(forResource: "fps_revolver", withExtension: "obj"),
           let scene = try? SCNScene(url: revUrl, options: [.checkConsistency: false]) {
            let node = SCNNode()
            for child in scene.rootNode.childNodes {
                node.addChildNode(child.clone())
            }
            node.scale = SCNVector3(0.5, 0.5, 0.5)
            self.revolverNode = node
        }

        if let shotUrl = Bundle.main.url(forResource: "fps_shotgun", withExtension: "obj"),
           let scene = try? SCNScene(url: shotUrl, options: [.checkConsistency: false]) {
            let node = SCNNode()
            for child in scene.rootNode.childNodes {
                node.addChildNode(child.clone())
            }
            node.scale = SCNVector3(0.5, 0.5, 0.5)
            self.shotgunNode = node
        }
    }

    func unlockShotgun() {
        hasShotgun = true
        shotgunReserve += 12
        equip(type: .shotgun)
    }

    func equip(type: WeaponType) {
        currentType = type
        guard let mount = controller?.weaponMountNode else { return }

        mount.childNodes.forEach { $0.removeFromParentNode() }

        switch type {
        case .revolver:
            if let node = revolverNode {
                mount.addChildNode(node)
            }
        case .shotgun:
            if let node = shotgunNode {
                mount.addChildNode(node)
            }
        }
    }

    func toggleWeapon() {
        guard hasShotgun else { return }
        equip(type: currentType == .revolver ? .shotgun : .revolver)
    }

    func canFire() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        let cooldown: TimeInterval = currentType == .revolver ? 0.35 : 0.75
        guard now - lastShotTime >= cooldown, !isReloading else { return false }

        switch currentType {
        case .revolver:
            return revolverMag > 0
        case .shotgun:
            return shotgunMag > 0
        }
    }

    func fire(onHitTarget: ((Float) -> Void)?) -> Bool {
        guard canFire() else {
            if (currentType == .revolver && revolverMag == 0) || (currentType == .shotgun && shotgunMag == 0) {
                reload()
            }
            return false
        }

        lastShotTime = ProcessInfo.processInfo.systemUptime

        switch currentType {
        case .revolver:
            revolverMag -= 1
            controller?.applyRecoil(intensity: 1.0)
            triggerMuzzleFlash()
            onHitTarget?(45.0) // 45 danni per colpo singolo

        case .shotgun:
            shotgunMag -= 1
            controller?.applyRecoil(intensity: 2.2)
            triggerMuzzleFlash()
            // Shotgun spara rosa di pallettoni
            onHitTarget?(110.0) // Danno devastante a corto raggio
        }

        return true
    }

    func reload() {
        guard !isReloading else { return }

        switch currentType {
        case .revolver:
            if revolverMag < revolverMagCapacity {
                isReloading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    self?.revolverMag = self?.revolverMagCapacity ?? 6
                    self?.isReloading = false
                }
            }
        case .shotgun:
            if shotgunMag < shotgunMagCapacity && shotgunReserve > 0 {
                isReloading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
                    guard let self = self else { return }
                    let needed = self.shotgunMagCapacity - self.shotgunMag
                    let toLoad = min(needed, self.shotgunReserve)
                    self.shotgunMag += toLoad
                    self.shotgunReserve -= toLoad
                    self.isReloading = false
                }
            }
        }
    }

    private func triggerMuzzleFlash() {
        muzzleFlashLight?.intensity = 3500
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            self?.muzzleFlashLight?.intensity = 0
        }
    }

    var ammoText: String {
        switch currentType {
        case .revolver:
            return "🔫 \(revolverMag) / ∞"
        case .shotgun:
            return "💥 \(shotgunMag) / \(shotgunReserve)"
        }
    }
}
