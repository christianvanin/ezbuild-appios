import Foundation
import SceneKit
import UIKit

enum ChestLoot {
    case shotgun
    case keyAndMedkit(keyNumber: Int)
    case finalKeys(key1: Int, key2: Int)
}

struct ChestItem {
    let id: Int
    let position: SCNVector3
    let baseNode: SCNNode
    let lidNode: SCNNode
    let loot: ChestLoot
    var isOpen: Bool = false
}

class ChestManager {
    private let scene: SCNScene
    var chests: [ChestItem] = []

    init(scene: SCNScene, locations: [(position: SCNVector3, cabinIndex: Int)]) {
        self.scene = scene
        spawnChests(locations: locations)
    }

    private func spawnChests(locations: [(position: SCNVector3, cabinIndex: Int)]) {
        let loots: [ChestLoot] = [
            .shotgun,
            .keyAndMedkit(keyNumber: 1),
            .finalKeys(key1: 2, key2: 3)
        ]

        for (idx, loc) in locations.enumerated() {
            let chestRoot = SCNNode()
            chestRoot.name = "ChestRoot_\(idx + 1)"
            chestRoot.position = loc.position

            let base = loadChestPart(named: "chest_base")
            chestRoot.addChildNode(base)

            // Il coperchio è posizionato con il cardine posteriore su z = 0.25, y = 0.40
            let lid = loadChestPart(named: "chest_lid")
            lid.position = SCNVector3(0, 0.40, 0.25)
            chestRoot.addChildNode(lid)

            // Luce dorata interna al baule (inizialmente spenta)
            let chestLight = SCNLight()
            chestLight.type = .omni
            chestLight.color = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
            chestLight.intensity = 0
            chestLight.attenuationEndDistance = 4.0

            let lightNode = SCNNode()
            lightNode.name = "ChestLight"
            lightNode.light = chestLight
            lightNode.position = SCNVector3(0, 0.35, 0)
            chestRoot.addChildNode(lightNode)

            scene.rootNode.addChildNode(chestRoot)

            let loot = idx < loots.count ? loots[idx] : .keyAndMedkit(keyNumber: idx + 1)
            let item = ChestItem(id: idx + 1, position: loc.position, baseNode: base, lidNode: lid, loot: loot, isOpen: false)
            chests.append(item)
        }
    }

    func checkNearbyChest(playerPosition: SCNVector3, radius: Float = 2.4) -> ChestItem? {
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

    func openChest(id: Int, completion: @escaping (ChestLoot) -> Void) {
        guard let index = chests.firstIndex(where: { $0.id == id && !$0.isOpen }) else { return }
        chests[index].isOpen = true

        let lid = chests[index].lidNode

        // Animazione rotazione cardine coperchio
        let openAction = SCNAction.rotateBy(x: CGFloat(-Float.pi * 0.48), y: 0, z: 0, duration: 0.55)
        openAction.timingMode = .easeOut
        lid.runAction(openAction)

        // Accensione luce tesoro
        if let lightNode = lid.parent?.childNode(withName: "ChestLight", recursively: false) {
            lightNode.light?.intensity = 1500
        }

        let loot = chests[index].loot
        completion(loot)
    }

    private func loadChestPart(named partName: String) -> SCNNode {
        if let url = Bundle.main.url(forResource: partName, withExtension: "obj"),
           let scene = try? SCNScene(url: url, options: [.checkConsistency: false]) {
            let wrapper = SCNNode()
            for child in scene.rootNode.childNodes {
                wrapper.addChildNode(child.clone())
            }
            return wrapper
        }
        let box = SCNBox(width: 0.8, height: 0.4, length: 0.5, chamferRadius: 0.02)
        return SCNNode(geometry: box)
    }
}
