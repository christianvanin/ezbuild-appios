import Foundation
import SceneKit
import UIKit

class EscapeGameMode {
    var playerHealth: Float = 100.0
    let maxHealth: Float = 100.0
    var keysFound: Int = 0
    let totalKeysRequired: Int = 3
    var zombiesKilled: Int = 0

    var isGameOver: Bool = false
    var isVictory: Bool = false

    var onHealthChanged: ((Float) -> Void)?
    var onKeysChanged: ((Int, Int) -> Void)?
    var onGameOver: (() -> Void)?
    var onVictory: (() -> Void)?

    func applyDamage(amount: Float) {
        guard !isGameOver && !isVictory else { return }
        playerHealth = max(0, playerHealth - amount)
        onHealthChanged?(playerHealth)

        if playerHealth <= 0 {
            isGameOver = true
            onGameOver?()
        }
    }

    func heal(amount: Float) {
        guard !isGameOver && !isVictory else { return }
        playerHealth = min(maxHealth, playerHealth + amount)
        onHealthChanged?(playerHealth)
    }

    func addKey(count: Int = 1) {
        keysFound = min(totalKeysRequired, keysFound + count)
        onKeysChanged?(keysFound, totalKeysRequired)
    }

    func recordKill() {
        zombiesKilled += 1
    }

    func isNearGate(playerPosition: SCNVector3, gatePosition: SCNVector3) -> Bool {
        let dx = playerPosition.x - gatePosition.x
        let dz = playerPosition.z - gatePosition.z
        return sqrt(dx * dx + dz * dz) < 4.5
    }

    func tryUnlockGate() -> (success: Bool, message: String) {
        if keysFound >= totalKeysRequired {
            isVictory = true
            onVictory?()
            return (true, "Cancello sbloccato! Sei fuggito dalla foresta!")
        } else {
            let missing = totalKeysRequired - keysFound
            return (false, "Il cancello è sigillato! Trova ancora \(missing) chiave/i nei bauli delle case.")
        }
    }
}
