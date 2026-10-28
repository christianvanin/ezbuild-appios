import Foundation
import SceneKit
import UIKit

public class WeaponSystem {
    private weak var controller: FirstPersonController?
    public let inventory: InventoryManager

    private var weaponModels: [WeaponKind: SCNNode] = [:]
    private var muzzleFlashLight: SCNLight?
    private var muzzleFlashNode: SCNNode?

    private var lastFireTime: TimeInterval = 0
    public private(set) var isReloading: Bool = false

    public init(controller: FirstPersonController, inventory: InventoryManager) {
        self.controller = controller
        self.inventory = inventory
        setupMuzzleFlash()
        preloadWeaponModels()
        equipCurrentWeapon()

        self.inventory.onInventoryUpdated = { [weak self] in
            self?.equipCurrentWeapon()
        }
    }

    private func setupMuzzleFlash() {
        let flashLight = SCNLight()
        flashLight.type = .omni
        flashLight.color = UIColor(red: 1.0, green: 0.85, blue: 0.40, alpha: 1.0)
        flashLight.intensity = 0
        flashLight.attenuationEndDistance = 7.0
        self.muzzleFlashLight = flashLight

        let flashNode = SCNNode()
        flashNode.light = flashLight
        flashNode.position = SCNVector3(0.18, -0.05, -0.60)
        controller?.cameraNode.addChildNode(flashNode)
        self.muzzleFlashNode = flashNode
    }

    private func preloadWeaponModels() {
        for kind in WeaponKind.allCases {
            if let url = Bundle.main.url(forResource: kind.modelResourceName, withExtension: "obj"),
               let scene = try? SCNScene(url: url, options: [.checkConsistency: false]) {
                let node = SCNNode()
                for child in scene.rootNode.childNodes {
                    node.addChildNode(child.clone())
                }
                node.scale = SCNVector3(0.5, 0.5, 0.5)
                weaponModels[kind] = node
            }
        }
    }

    public func equipCurrentWeapon() {
        guard let mount = controller?.weaponMountNode else { return }
        mount.childNodes.forEach { $0.removeFromParentNode() }

        guard let current = inventory.currentWeapon else { return }
        if let model = weaponModels[current.kind] {
            mount.addChildNode(model)
        }
    }

    public func canFire() -> Bool {
        guard let weapon = inventory.currentWeapon else { return false }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastFireTime >= weapon.kind.fireCooldown, !isReloading else { return false }

        if weapon.kind == .revolver {
            return weapon.currentMag > 0
        } else if weapon.kind == .dynamite {
            return weapon.reserveAmmo > 0
        } else {
            return weapon.currentMag > 0
        }
    }

    public func fire(onHit: ((Float, WeaponItem) -> Void)?, onThrowExplosive: ((SCNVector3, Float) -> Void)?) -> Bool {
        guard let weapon = inventory.currentWeapon else { return false }

        guard canFire() else {
            if weapon.currentMag == 0 && !isReloading {
                reload()
            }
            return false
        }

        lastFireTime = ProcessInfo.processInfo.systemUptime

        if weapon.kind == .dynamite {
            weapon.reserveAmmo = max(0, weapon.reserveAmmo - 1)
            triggerMuzzleFlash(color: UIColor.orange, intensity: 1800)
            controller?.applyRecoil(intensity: 0.8)

            // Posizione di lancio dinamite
            if let cam = controller?.cameraNode {
                let camPos = cam.convertPosition(SCNVector3(0, 0, -1.0), to: nil)
                onThrowExplosive?(camPos, weapon.damage)
            }
            return true
        }

        weapon.currentMag -= 1

        let recoilMultiplier: Float = {
            switch weapon.kind {
            case .revolver: return 1.0
            case .shotgun: return 2.4
            case .rifle: return 1.3
            case .sniper: return 3.0
            case .dynamite: return 0.5
            }
        }()

        controller?.applyRecoil(intensity: recoilMultiplier)
        triggerMuzzleFlash(color: weapon.rarity == .legendary ? UIColor.systemYellow : UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0), intensity: 3600)
        onHit?(weapon.damage, weapon)
        return true
    }

    public func reload() {
        guard let weapon = inventory.currentWeapon, !isReloading else { return }
        if weapon.kind == .revolver {
            if weapon.currentMag < weapon.maxMag {
                isReloading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + weapon.reloadDuration) { [weak self] in
                    weapon.currentMag = weapon.maxMag
                    self?.isReloading = false
                }
            }
        } else if weapon.kind != .dynamite {
            if weapon.currentMag < weapon.maxMag && weapon.reserveAmmo > 0 {
                isReloading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + weapon.reloadDuration) { [weak self] in
                    guard let self = self else { return }
                    let needed = weapon.maxMag - weapon.currentMag
                    let toLoad = min(needed, weapon.reserveAmmo)
                    weapon.currentMag += toLoad
                    weapon.reserveAmmo -= toLoad
                    self.isReloading = false
                }
            }
        }
    }

    private func triggerMuzzleFlash(color: UIColor, intensity: CGFloat) {
        muzzleFlashLight?.color = color
        muzzleFlashLight?.intensity = intensity
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.muzzleFlashLight?.intensity = 0
        }
    }

    public var currentWeaponDisplay: String {
        guard let w = inventory.currentWeapon else { return "Nessuna Arma" }
        return "\(w.kind.iconSymbol) \(w.displayName)"
    }

    public var ammoDisplayText: String {
        return inventory.currentWeapon?.ammoDisplay ?? "--"
    }
}
