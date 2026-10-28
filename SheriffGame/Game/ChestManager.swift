import Foundation
import SceneKit
import UIKit

public enum ChestLootReward {
    case weapon(item: WeaponItem)
    case medkitAndAmmo(hp: Float, bonusAmmo: Int)
}

public struct ChestItem {
    public let id: Int
    public let position: SCNVector3
    public let baseNode: SCNNode
    public let lidNode: SCNNode
    public let loot: ChestLootReward
    public var isOpen: Bool = false
}

public class ChestManager {
    private let scene: SCNScene
    public private(set) var chests: [ChestItem] = []

    public init(scene: SCNScene, locations: [(position: SCNVector3, id: Int)]) {
        self.scene = scene
        spawnChests(locations: locations)
    }

    private func spawnChests(locations: [(position: SCNVector3, id: Int)]) {
        for loc in locations {
            let chestRoot = SCNNode()
            chestRoot.name = "ChestRoot_\(loc.id)"
            chestRoot.position = loc.position

            let base = loadChestPart(named: "chest_base")
            chestRoot.addChildNode(base)

            // Il coperchio incernierato sul retro (z = 0.25, y = 0.40)
            let lid = loadChestPart(named: "chest_lid")
            lid.position = SCNVector3(0, 0.40, 0.25)
            chestRoot.addChildNode(lid)

            // Luce dorata interna al forziere
            let chestLight = SCNLight()
            chestLight.type = .omni
            chestLight.color = UIColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 1.0)
            chestLight.intensity = 0
            chestLight.attenuationEndDistance = 4.5

            let lightNode = SCNNode()
            lightNode.name = "ChestLight"
            lightNode.light = chestLight
            lightNode.position = SCNVector3(0, 0.35, 0)
            chestRoot.addChildNode(lightNode)

            scene.rootNode.addChildNode(chestRoot)

            // Assegnazione bottino tematico
            let reward: ChestLootReward = {
                switch loc.id {
                case 1:
                    // Saloon: Doppietta rara o epica
                    return .weapon(item: WeaponItem(kind: .shotgun, rarity: .rare))
                case 2:
                    // Ufficio Sceriffo: Winchester 1873
                    return .weapon(item: WeaponItem(kind: .rifle, rarity: .rare))
                case 3:
                    // Cimitero: Fucile da cecchino Sharps epico
                    return .weapon(item: WeaponItem(kind: .sniper, rarity: .epic))
                case 4:
                    // Miniera d'Oro: Candelotto di Dinamite Leggendario
                    return .weapon(item: WeaponItem(kind: .dynamite, rarity: .legendary))
                default:
                    return .medkitAndAmmo(hp: 50, bonusAmmo: 24)
                }
            }()

            let item = ChestItem(id: loc.id, position: loc.position, baseNode: base, lidNode: lid, loot: reward, isOpen: false)
            chests.append(item)
        }
    }

    public func checkNearbyChest(playerPosition: SCNVector3, radius: Float = 2.8) -> ChestItem? {
        for chest in chests where !chest.isOpen {
            let dx = playerPosition.x - chest.position.x
            let dz = playerPosition.z - chest.position.z
            let dy = playerPosition.y - chest.position.y
            let dist = sqrt(dx * dx + dz * dz + dy * dy)
            if dist < radius {
                return chest
            }
        }
        return nil
    }

    public func openChest(id: Int, completion: @escaping (ChestLootReward) -> Void) {
        guard let index = chests.firstIndex(where: { $0.id == id && !$0.isOpen }) else { return }
        chests[index].isOpen = true

        let lid = chests[index].lidNode

        // Animazione rotazione coperchio
        let openAction = SCNAction.rotateBy(x: CGFloat(-Float.pi * 0.48), y: 0, z: 0, duration: 0.55)
        openAction.timingMode = .easeOut
        lid.runAction(openAction)

        // Luce oro ad alta intensità
        if let lightNode = lid.parent?.childNode(withName: "ChestLight", recursively: false) {
            lightNode.light?.intensity = 1800
        }

        let loot = chests[index].loot
        completion(loot)
    }

    public func resetChests() {
        for i in 0..<chests.count {
            if chests[i].isOpen {
                chests[i].isOpen = false
                chests[i].lidNode.eulerAngles = SCNVector3Zero
                if let lightNode = chests[i].lidNode.parent?.childNode(withName: "ChestLight", recursively: false) {
                    lightNode.light?.intensity = 0
                }
            }
        }
    }

    private func loadChestPart(named name: String) -> SCNNode {
        if let url = Bundle.main.url(forResource: name, withExtension: "obj") {
            if let objScene = try? SCNScene(url: url, options: [.checkConsistency: false]) {
                let wrapper = SCNNode()
                for child in objScene.rootNode.childNodes {
                    wrapper.addChildNode(child.clone())
                }
                return wrapper
            }
        }
        let box = SCNBox(width: 0.9, height: 0.5, length: 0.6, chamferRadius: 0.02)
        return SCNNode(geometry: box)
    }
}
