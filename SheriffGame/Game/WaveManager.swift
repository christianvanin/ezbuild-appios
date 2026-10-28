import Foundation

public enum WaveState: Equatable {
    case preparation(secondsRemaining: Float)
    case activeWave
    case waveCompleted
    case gameOver
}

public struct WaveConfig {
    public let waveIndex: Int
    public let walkers: Int
    public let runners: Int
    public let brutes: Int

    public var totalCount: Int {
        return walkers + runners + brutes
    }

    public static func config(for wave: Int) -> WaveConfig {
        switch wave {
        case 1:
            return WaveConfig(waveIndex: 1, walkers: 7, runners: 0, brutes: 0)
        case 2:
            return WaveConfig(waveIndex: 2, walkers: 10, runners: 4, brutes: 0)
        case 3:
            return WaveConfig(waveIndex: 3, walkers: 12, runners: 6, brutes: 2)
        case 4:
            return WaveConfig(waveIndex: 4, walkers: 16, runners: 10, brutes: 3)
        case 5:
            return WaveConfig(waveIndex: 5, walkers: 22, runners: 14, brutes: 6) // Boss Wave
        default:
            let extra = wave - 5
            return WaveConfig(
                waveIndex: wave,
                walkers: 20 + extra * 4,
                runners: 12 + extra * 3,
                brutes: 5 + extra * 2
            )
        }
    }
}

public class WaveManager {
    public private(set) var currentWave: Int = 1
    public private(set) var state: WaveState = .preparation(secondsRemaining: 8.0)
    public private(set) var aliveZombies: Int = 0
    public private(set) var totalZombiesInWave: Int = 0
    public private(set) var totalKills: Int = 0
    public private(set) var goldBounty: Int = 0

    private var prepTimer: Float = 8.0
    private let defaultPrepDuration: Float = 10.0

    public var onWaveStateChanged: ((WaveState) -> Void)?
    public var onSpawnRequest: ((ZombieKind, Int) -> Void)?
    public var onRewardGranted: ((String) -> Void)?

    public init() {
        prepTimer = 6.0
        state = .preparation(secondsRemaining: prepTimer)
    }

    public func update(deltaTime: Float) {
        switch state {
        case .preparation(_):
            prepTimer -= deltaTime
            if prepTimer <= 0 {
                startActiveWave()
            } else {
                state = .preparation(secondsRemaining: prepTimer)
                onWaveStateChanged?(state)
            }

        case .activeWave:
            if aliveZombies <= 0 && totalZombiesInWave > 0 {
                completeWave()
            }

        case .waveCompleted, .gameOver:
            break
        }
    }

    public func startActiveWave() {
        let config = WaveConfig.config(for: currentWave)
        totalZombiesInWave = config.totalCount
        aliveZombies = config.totalCount
        state = .activeWave
        onWaveStateChanged?(state)

        // Richieste di spawn dei differenti nemici
        if config.walkers > 0 { onSpawnRequest?(.walker, config.walkers) }
        if config.runners > 0 { onSpawnRequest?(.runner, config.runners) }
        if config.brutes > 0 { onSpawnRequest?(.brute, config.brutes) }
    }

    public func recordZombieKilled(kind: ZombieKind) {
        aliveZombies = max(0, aliveZombies - 1)
        totalKills += 1

        let reward = kind.goldReward
        goldBounty += reward

        if aliveZombies <= 0 && state == .activeWave {
            completeWave()
        }
    }

    private func completeWave() {
        state = .waveCompleted
        onWaveStateChanged?(state)

        let waveBonus = currentWave * 50
        goldBounty += waveBonus
        onRewardGranted?("Ondata \(currentWave) Completata! +$\(waveBonus) Taglia")

        currentWave += 1
        prepTimer = defaultPrepDuration
        state = .preparation(secondsRemaining: prepTimer)
    }

    public func reset() {
        currentWave = 1
        aliveZombies = 0
        totalZombiesInWave = 0
        totalKills = 0
        goldBounty = 0
        prepTimer = 5.0
        state = .preparation(secondsRemaining: prepTimer)
        onWaveStateChanged?(state)
    }
}
