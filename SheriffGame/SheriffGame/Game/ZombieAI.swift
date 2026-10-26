import Foundation
import SceneKit
import UIKit

enum ZombieState {
    case patrol
    case chase
    case attack
    case dead
}

class ZombieEntity {
    let node: SCNNode
    var health: Float = 100.0
    var isDead: Bool = false
    var state: ZombieState = .patrol

    var walkSpeed: Float
    let detectionRadius: Float = 22.0
    let attackRadius: Float = 1.7
    let attackDamage: Float = 14.0

    private var lastAttackTime: TimeInterval = 0
    private var patrolTarget: SCNVector3
    private var patrolTimer: Float = 0

    init(node: SCNNode, startPos: SCNVector3, isFast: Bool = false) {
        self.node = node
        self.node.position = startPos
        self.walkSpeed = isFast ? 3.5 : 2.2
        self.patrolTarget = startPos
    }

    func update(playerPosition: SCNVector3, deltaTime: Float, onAttackPlayer: ((Float) -> Void)?) {
        guard !isDead else { return }

        let dx = playerPosition.x - node.position.x
        let dz = playerPosition.z - node.position.z
        let distToPlayer = sqrt(dx * dx + dz * dz)

        // Macchina a stati
        if distToPlayer < attackRadius {
            state = .attack
        } else if distToPlayer < detectionRadius {
            state = .chase
        } else if state == .chase && distToPlayer > detectionRadius * 1.5 {
            state = .patrol
        }

        switch state {
        case .patrol:
            updatePatrol(deltaTime: deltaTime)

        case .chase:
            // Rotazione verso il giocatore (orientamento Y)
            let angle = atan2(dx, dz)
            node.eulerAngles = SCNVector3(0, angle, 0)

            // Avanzamento
            let moveStep = walkSpeed * deltaTime
            let stepX = sin(angle) * moveStep
            let stepZ = cos(angle) * moveStep
            node.position = SCNVector3(node.position.x + stepX, 0, node.position.z + stepZ)

        case .attack:
            let angle = atan2(dx, dz)
            node.eulerAngles = SCNVector3(0, angle, 0)

            let now = ProcessInfo.processInfo.systemUptime
            if now - lastAttackTime > 1.2 {
                lastAttackTime = now
                // Animazione attacco a scatto in avanti
                let strike = SCNAction.moveBy(x: CGFloat(sin(angle) * 0.3), y: 0, z: CGFloat(cos(angle) * 0.3), duration: 0.1)
                let back = SCNAction.moveBy(x: CGFloat(-sin(angle) * 0.3), y: 0, z: CGFloat(-cos(angle) * 0.3), duration: 0.25)
                node.runAction(SCNAction.sequence([strike, back]))
                onAttackPlayer?(attackDamage)
            }

        case .dead:
            break
        }
    }

    private func updatePatrol(deltaTime: Float) {
        patrolTimer -= deltaTime
        if patrolTimer <= 0 {
            patrolTimer = Float.random(in: 4.0...8.0)
            let offset = Float.random(in: -10.0...10.0)
            patrolTarget = SCNVector3(node.position.x + offset, 0, node.position.z + offset)
        }

        let dx = patrolTarget.x - node.position.x
        let dz = patrolTarget.z - node.position.z
        let dist = sqrt(dx * dx + dz * dz)

        if dist > 0.5 {
            let angle = atan2(dx, dz)
            node.eulerAngles = SCNVector3(0, angle, 0)
            let speed = walkSpeed * 0.4 * deltaTime
            node.position = SCNVector3(
                node.position.x + sin(angle) * speed,
                0,
                node.position.z + cos(angle) * speed
            )
        }
    }

    func takeDamage(amount: Float) -> Bool {
        guard !isDead else { return false }
        health -= amount

        // Lampeggio rosso di impatto
        node.childNodes.forEach { child in
            child.geometry?.firstMaterial?.emission.contents = UIColor.red
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.node.childNodes.forEach { child in
                child.geometry?.firstMaterial?.emission.contents = UIColor.black
            }
        }

        if health <= 0 {
            die()
            return true
        }
        return false
    }

    private func die() {
        isDead = true
        state = .dead

        // Animazione caduta all'indietro e dissolvenza
        let fallBack = SCNAction.rotateBy(x: CGFloat(-Float.pi / 2), y: 0, z: 0, duration: 0.4)
        let sink = SCNAction.moveBy(x: 0, y: -0.8, z: 0, duration: 1.0)
        let fade = SCNAction.fadeOut(duration: 1.0)
        let remove = SCNAction.removeFromParentNode()

        let sequence = SCNAction.sequence([fallBack, SCNAction.group([sink, fade]), remove])
        node.runAction(sequence)
    }

    func alertToPlayerPosition() {
        if !isDead && state == .patrol {
            state = .chase
        }
    }
}

class ZombieManager {
    private let scene: SCNScene
    var zombies: [ZombieEntity] = []

    init(scene: SCNScene) {
        self.scene = scene
        spawnInitialZombies()
    }

    private func spawnInitialZombies() {
        let spawnPoints: [(x: Float, z: Float, isFast: Bool)] = [
            (-15, -8, false),
            (12, -12, false),
            (-32, -5, true),
            (30, -8, false),
            (-8, -32, false),
            (18, -38, true),
            (-22, 10, false),
            (24, 15, false),
            (5, 28, false),
            (-28, 30, true),
            (28, 32, false),
            (-12, -45, true),
            (10, -48, false),
            (0, -25, false)
        ]

        for pt in spawnPoints {
            let zombieNode = loadZombieNode()
            let entity = ZombieEntity(node: zombieNode, startPos: SCNVector3(pt.x, 0, pt.z), isFast: pt.isFast)
            scene.rootNode.addChildNode(zombieNode)
            zombies.append(entity)
        }
    }

    func update(playerPosition: SCNVector3, deltaTime: Float, onAttackPlayer: ((Float) -> Void)?) {
        for zombie in zombies {
            zombie.update(playerPosition: playerPosition, deltaTime: deltaTime, onAttackPlayer: onAttackPlayer)
        }
        // Rimuove zombi morti rimossi dalla scena
        zombies.removeAll { $0.isDead && $0.node.parent == nil }
    }

    func alertAllZombiesInRange(center: SCNVector3, radius: Float) {
        for zombie in zombies {
            let dx = zombie.node.position.x - center.x
            let dz = zombie.node.position.z - center.z
            if sqrt(dx * dx + dz * dz) < radius {
                zombie.alertToPlayerPosition()
            }
        }
    }

    func checkRayHit(from start: SCNVector3, direction: SCNVector3, maxDistance: Float, damage: Float) -> Bool {
        var closestZombie: ZombieEntity?
        var minDistance: Float = maxDistance

        for zombie in zombies where !zombie.isDead {
            // Sfera di collisione attorno al torace dello zombi
            let zombieCenter = SCNVector3(zombie.node.position.x, 1.2, zombie.node.position.z)
            let toZombie = SCNVector3(zombieCenter.x - start.x, zombieCenter.y - start.y, zombieCenter.z - start.z)

            // Proiezione del vettore sul raggio di sparo
            let dot = toZombie.x * direction.x + toZombie.y * direction.y + toZombie.z * direction.z
            if dot > 0.5 && dot < minDistance {
                let projPoint = SCNVector3(start.x + direction.x * dot, start.y + direction.y * dot, start.z + direction.z * dot)
                let perpDist = sqrt(pow(projPoint.x - zombieCenter.x, 2) + pow(projPoint.y - zombieCenter.y, 2) + pow(projPoint.z - zombieCenter.z, 2))

                if perpDist < 0.65 { // Raggio hitbox zombi
                    minDistance = dot
                    closestZombie = zombie
                }
            }
        }

        if let hit = closestZombie {
            _ = hit.takeDamage(amount: damage)
            return true
        }
        return false
    }

    private func loadZombieNode() -> SCNNode {
        if let url = Bundle.main.url(forResource: "zombie", withExtension: "obj"),
           let scene = try? SCNScene(url: url, options: [.checkConsistency: false]) {
            let wrapper = SCNNode()
            for child in scene.rootNode.childNodes {
                wrapper.addChildNode(child.clone())
            }
            return wrapper
        }
        let box = SCNBox(width: 0.5, height: 1.8, length: 0.5, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.green
        return SCNNode(geometry: box)
    }
}
