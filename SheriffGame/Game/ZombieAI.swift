import Foundation
import SceneKit
import UIKit

public enum ZombieKind: String, CaseIterable {
    case walker = "Zombi Walker"
    case runner = "Zombi Runner"
    case brute = "Zombi Brute"

    public var baseHealth: Float {
        switch self {
        case .walker: return 90.0
        case .runner: return 55.0
        case .brute: return 260.0
        }
    }

    public var walkSpeed: Float {
        switch self {
        case .walker: return 2.3
        case .runner: return 4.1
        case .brute: return 1.5
        }
    }

    public var attackDamage: Float {
        switch self {
        case .walker: return 14.0
        case .runner: return 18.0
        case .brute: return 36.0
        }
    }

    public var attackCooldown: TimeInterval {
        switch self {
        case .walker: return 1.2
        case .runner: return 0.8
        case .brute: return 1.8
        }
    }

    public var hitboxRadius: Float {
        switch self {
        case .walker: return 0.65
        case .runner: return 0.55
        case .brute: return 0.95
        }
    }

    public var modelName: String {
        switch self {
        case .walker: return "zombie_walker"
        case .runner: return "zombie_runner"
        case .brute: return "zombie_brute"
        }
    }

    public var goldReward: Int {
        switch self {
        case .walker: return 15
        case .runner: return 25
        case .brute: return 60
        }
    }
}

public enum ZombieState {
    case patrol
    case chase
    case attack
    case dead
}

public class ZombieEntity {
    public let node: SCNNode
    public let kind: ZombieKind
    public var health: Float
    public var isDead: Bool = false
    public var state: ZombieState = .patrol

    public let walkSpeed: Float
    public let detectionRadius: Float
    public let attackRadius: Float
    public let attackDamage: Float

    private var lastAttackTime: TimeInterval = 0
    private var patrolTarget: SCNVector3
    private var patrolTimer: Float = 0

    public init(node: SCNNode, startPos: SCNVector3, kind: ZombieKind) {
        self.node = node
        self.node.position = startPos
        self.kind = kind
        self.health = kind.baseHealth
        self.walkSpeed = kind.walkSpeed
        self.detectionRadius = kind == .runner ? 28.0 : 22.0
        self.attackRadius = kind == .brute ? 2.2 : 1.7
        self.attackDamage = kind.attackDamage
        self.patrolTarget = startPos
    }

    public func update(playerPosition: SCNVector3, deltaTime: Float, onAttackPlayer: ((Float) -> Void)?) {
        guard !isDead else { return }

        let dx = playerPosition.x - node.position.x
        let dz = playerPosition.z - node.position.z
        let distToPlayer = sqrt(dx * dx + dz * dz)

        // Macchina a stati
        if distToPlayer < attackRadius {
            state = .attack
        } else if distToPlayer < detectionRadius {
            state = .chase
        } else if state == .chase && distToPlayer > detectionRadius * 1.6 {
            state = .patrol
        }

        switch state {
        case .patrol:
            updatePatrol(deltaTime: deltaTime)

        case .chase:
            let angle = atan2(dx, dz)
            node.eulerAngles = SCNVector3(0, angle, 0)

            let moveStep = walkSpeed * deltaTime
            let stepX = sin(angle) * moveStep
            let stepZ = cos(angle) * moveStep
            node.position = SCNVector3(node.position.x + stepX, 0, node.position.z + stepZ)

        case .attack:
            let angle = atan2(dx, dz)
            node.eulerAngles = SCNVector3(0, angle, 0)

            let now = ProcessInfo.processInfo.systemUptime
            if now - lastAttackTime > kind.attackCooldown {
                lastAttackTime = now

                // Scatto d'attacco in avanti in base alla stazza
                let lunge = kind == .runner ? 0.5 : 0.3
                let strike = SCNAction.moveBy(x: CGFloat(sin(angle) * Float(lunge)), y: 0, z: CGFloat(cos(angle) * Float(lunge)), duration: 0.1)
                let back = SCNAction.moveBy(x: CGFloat(-sin(angle) * Float(lunge)), y: 0, z: CGFloat(-cos(angle) * Float(lunge)), duration: 0.25)
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
            patrolTimer = Float.random(in: 4.0...7.0)
            let offset = Float.random(in: -12.0...12.0)
            patrolTarget = SCNVector3(node.position.x + offset, 0, node.position.z + offset)
        }

        let dx = patrolTarget.x - node.position.x
        let dz = patrolTarget.z - node.position.z
        let dist = sqrt(dx * dx + dz * dz)

        if dist > 0.5 {
            let angle = atan2(dx, dz)
            node.eulerAngles = SCNVector3(0, angle, 0)
            let speed = walkSpeed * 0.45 * deltaTime
            node.position = SCNVector3(
                node.position.x + sin(angle) * speed,
                0,
                node.position.z + cos(angle) * speed
            )
        }
    }

    public func takeDamage(amount: Float) -> Bool {
        guard !isDead else { return false }
        health -= amount

        // Lampeggio di impatto su tutti i materiali
        node.enumerateChildNodes { child, _ in
            child.geometry?.firstMaterial?.emission.contents = UIColor.red
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.node.enumerateChildNodes { child, _ in
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

        let fallBack = SCNAction.rotateBy(x: CGFloat(-Float.pi / 2), y: 0, z: 0, duration: 0.35)
        let sink = SCNAction.moveBy(x: 0, y: -0.9, z: 0, duration: 0.8)
        let fade = SCNAction.fadeOut(duration: 0.8)
        let remove = SCNAction.removeFromParentNode()

        let sequence = SCNAction.sequence([fallBack, SCNAction.group([sink, fade]), remove])
        node.runAction(sequence)
    }

    public func alertToPlayer() {
        if !isDead && state == .patrol {
            state = .chase
        }
    }
}

public class ZombieManager {
    private let scene: SCNScene
    public private(set) var zombies: [ZombieEntity] = []

    public init(scene: SCNScene) {
        self.scene = scene
    }

    public func spawnZombies(kind: ZombieKind, count: Int, playerPosition: SCNVector3) {
        for _ in 0..<count {
            let angle = Float.random(in: 0...(Float.pi * 2))
            let dist = Float.random(in: 25.0...48.0)
            let sx = playerPosition.x + cos(angle) * dist
            let sz = playerPosition.z + sin(angle) * dist

            // Clampa entro il confine della mappa
            let clampedX = max(-70.0, min(70.0, sx))
            let clampedZ = max(-70.0, min(70.0, sz))

            let zNode = loadZombieNode(named: kind.modelName)
            let entity = ZombieEntity(node: zNode, startPos: SCNVector3(clampedX, 0, clampedZ), kind: kind)
            scene.rootNode.addChildNode(zNode)
            zombies.append(entity)
        }
    }

    public func update(playerPosition: SCNVector3, deltaTime: Float, onAttackPlayer: ((Float) -> Void)?) {
        for zombie in zombies {
            zombie.update(playerPosition: playerPosition, deltaTime: deltaTime, onAttackPlayer: onAttackPlayer)
        }
        zombies.removeAll { $0.isDead && $0.node.parent == nil }
    }

    public func alertAllZombiesInRange(center: SCNVector3, radius: Float) {
        for zombie in zombies {
            let dx = zombie.node.position.x - center.x
            let dz = zombie.node.position.z - center.z
            if sqrt(dx * dx + dz * dz) < radius {
                zombie.alertToPlayer()
            }
        }
    }

    public func checkRayHit(from start: SCNVector3, direction: SCNVector3, maxDistance: Float, damage: Float) -> (hit: Bool, killed: Bool, kind: ZombieKind?) {
        var closestZombie: ZombieEntity?
        var minDistance: Float = maxDistance

        for zombie in zombies where !zombie.isDead {
            let zombieCenter = SCNVector3(zombie.node.position.x, 1.2, zombie.node.position.z)
            let toZombie = SCNVector3(zombieCenter.x - start.x, zombieCenter.y - start.y, zombieCenter.z - start.z)

            let dot = toZombie.x * direction.x + toZombie.y * direction.y + toZombie.z * direction.z
            if dot > 0.5 && dot < minDistance {
                let projPoint = SCNVector3(start.x + direction.x * dot, start.y + direction.y * dot, start.z + direction.z * dot)
                let perpDist = sqrt(pow(projPoint.x - zombieCenter.x, 2) + pow(projPoint.y - zombieCenter.y, 2) + pow(projPoint.z - zombieCenter.z, 2))

                if perpDist < zombie.kind.hitboxRadius {
                    minDistance = dot
                    closestZombie = zombie
                }
            }
        }

        if let hitZombie = closestZombie {
            let wasKilled = hitZombie.takeDamage(amount: damage)
            return (true, wasKilled, hitZombie.kind)
        }
        return (false, false, nil)
    }

    public func applyExplosion(center: SCNVector3, radius: Float, maxDamage: Float) -> [(zombie: ZombieEntity, killed: Bool)] {
        var results: [(ZombieEntity, Bool)] = []
        for zombie in zombies where !zombie.isDead {
            let dx = zombie.node.position.x - center.x
            let dz = zombie.node.position.z - center.z
            let dist = sqrt(dx * dx + dz * dz)
            if dist < radius {
                let falloff = 1.0 - (dist / radius)
                let damage = maxDamage * max(0.2, falloff)
                let killed = zombie.takeDamage(amount: damage)
                results.append((zombie, killed))
            }
        }
        return results
    }

    public func clearAllZombies() {
        for z in zombies {
            z.node.removeFromParentNode()
        }
        zombies.removeAll()
    }

    private func loadZombieNode(named name: String) -> SCNNode {
        if let url = Bundle.main.url(forResource: name, withExtension: "obj") {
            if let objScene = try? SCNScene(url: url, options: [.checkConsistency: false]) {
                let wrapper = SCNNode()
                for child in objScene.rootNode.childNodes {
                    wrapper.addChildNode(child.clone())
                }
                return wrapper
            }
        }
        // Fallback voxel
        let box = SCNBox(width: 0.6, height: 1.8, length: 0.6, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.systemGreen
        return SCNNode(geometry: box)
    }
}
