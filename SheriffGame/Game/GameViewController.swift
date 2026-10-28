import UIKit
import SceneKit

public class GameViewController: UIViewController, SCNSceneRendererDelegate, HUDDelegate {
    private var scnView: SCNView!
    private var forestScene: ForestScene!
    private var fpsController: FirstPersonController!
    private var inventoryManager: InventoryManager!
    private var weaponSystem: WeaponSystem!
    private var zombieManager: ZombieManager!
    private var chestManager: ChestManager!
    private var waveManager: WaveManager!
    private var hudView: HUDOverlayView!

    private var playerHealth: Float = 100.0
    private let maxPlayerHealth: Float = 100.0
    private var isPlayerDead: Bool = false
    private var isGamePaused: Bool = false

    private var lastUpdateTime: TimeInterval = 0
    private var currentMoveForward: Float = 0
    private var currentMoveStrafe: Float = 0

    private var activeNearbyChest: ChestItem?

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
        setupHUD()
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    private func setupGame() {
        // 1. Scena 3D & PBR
        forestScene = ForestScene()

        // 2. SCNView con HDR e Antialiasing
        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.scene = forestScene.scene
        scnView.delegate = self
        scnView.isPlaying = true
        scnView.loops = true
        scnView.preferredFramesPerSecond = 60
        scnView.antialiasingMode = .multisampling4X
        view.addSubview(scnView)

        // 3. Controller Telecamera & Torcia
        fpsController = FirstPersonController()
        forestScene.scene.rootNode.addChildNode(fpsController.playerNode)
        scnView.pointOfView = fpsController.cameraNode

        // 4. Inventario, Armi & Forzieri
        inventoryManager = InventoryManager()
        weaponSystem = WeaponSystem(controller: fpsController, inventory: inventoryManager)
        zombieManager = ZombieManager(scene: forestScene.scene)
        chestManager = ChestManager(scene: forestScene.scene, locations: forestScene.chestLocations)

        // 5. Wave Manager (Survival Horde)
        waveManager = WaveManager()
        waveManager.onSpawnRequest = { [weak self] kind, count in
            guard let self = self else { return }
            self.zombieManager.spawnZombies(kind: kind, count: count, playerPosition: self.fpsController.playerNode.position)
        }

        waveManager.onRewardGranted = { [weak self] message in
            DispatchQueue.main.async {
                self?.hudView.showToast(message: message)
            }
        }
    }

    private func setupHUD() {
        hudView = HUDOverlayView(frame: view.bounds)
        hudView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hudView.delegate = self
        view.addSubview(hudView)

        refreshHUDState()
        hudView.showToast(message: "Sopravvivi alle orde! Esplora la città ed equipaggia nuove armi.")
    }

    private func refreshHUDState() {
        hudView.updateHealth(hp: playerHealth)
        hudView.updateBounty(gold: waveManager.goldBounty)
        hudView.updateHotbar(slots: inventoryManager.hotbar, activeIndex: inventoryManager.activeIndex)
        hudView.updateInventoryDetails(weapons: inventoryManager.backpack)
        hudView.setFlashlightState(isOn: fpsController.isFlashlightOn)
    }

    // GAME LOOP PRINCIPALE (60 FPS)
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
            return
        }
        let deltaTime = Float(min(time - lastUpdateTime, 0.1))
        lastUpdateTime = time

        guard !isPlayerDead && !isGamePaused else { return }

        // 1. Movimento Giocatore entro i confini della mappa (140x140)
        fpsController.updateMovement(forward: currentMoveForward, strafe: currentMoveStrafe, deltaTime: deltaTime) { pos in
            return abs(pos.x) < 72.0 && abs(pos.z) < 72.0
        }

        let playerPos = fpsController.playerNode.position

        // 2. Aggiornamento Ondate
        waveManager.update(deltaTime: deltaTime)

        // 3. Aggiornamento IA Zombi
        zombieManager.update(playerPosition: playerPos, deltaTime: deltaTime) { [weak self] damage in
            guard let self = self, !self.isPlayerDead else { return }
            DispatchQueue.main.async {
                self.playerHealth = max(0, self.playerHealth - damage)
                self.hudView.updateHealth(hp: self.playerHealth)
                self.hudView.showToast(message: "Sei stato colpito! (-\(Int(damage)) HP)")

                if self.playerHealth <= 0 {
                    self.isPlayerDead = true
                    self.hudView.showGameOverModal(
                        wave: self.waveManager.currentWave,
                        kills: self.waveManager.totalKills,
                        bounty: self.waveManager.goldBounty
                    )
                }
            }
        }

        // 4. Controllo Prossimità Bauli
        let nearbyChest = chestManager.checkNearbyChest(playerPosition: playerPos, radius: 2.8)
        self.activeNearbyChest = nearbyChest

        // 5. Aggiornamento HUD
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.activeNearbyChest != nil {
                self.hudView.setActionPrompt(title: "📦 APRI FORZIERE")
            } else {
                self.hudView.setActionPrompt(title: nil)
            }

            switch self.waveManager.state {
            case .preparation(let seconds):
                self.hudView.updateWaveInfo(
                    wave: self.waveManager.currentWave,
                    aliveZombies: self.waveManager.aliveZombies,
                    totalInWave: self.waveManager.totalZombiesInWave,
                    isPrep: true,
                    prepSeconds: seconds
                )
            case .activeWave, .waveCompleted, .gameOver:
                self.hudView.updateWaveInfo(
                    wave: self.waveManager.currentWave,
                    aliveZombies: self.waveManager.aliveZombies,
                    totalInWave: self.waveManager.totalZombiesInWave,
                    isPrep: false,
                    prepSeconds: 0
                )
            }

            self.hudView.updateBounty(gold: self.waveManager.goldBounty)
            self.hudView.updateHotbar(slots: self.inventoryManager.hotbar, activeIndex: self.inventoryManager.activeIndex)
        }
    }

    // HUD DELEGATE HANDLERS
    public func hudDidMove(forward: Float, strafe: Float) {
        currentMoveForward = forward
        currentMoveStrafe = strafe
    }

    public func hudDidLook(deltaYaw: Float, deltaPitch: Float) {
        fpsController.updateRotation(deltaYaw: deltaYaw, deltaPitch: deltaPitch)
    }

    public func hudDidPressFire() {
        guard !isPlayerDead && !isGamePaused else { return }

        let camNode = fpsController.cameraNode
        let startPos = camNode.convertPosition(SCNVector3Zero, to: nil)
        let forwardLocal = SCNVector3(0, 0, -1)
        let endPos = camNode.convertPosition(forwardLocal, to: nil)
        let dir = SCNVector3(endPos.x - startPos.x, endPos.y - startPos.y, endPos.z - startPos.z)
        let len = sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
        let normDir = SCNVector3(dir.x / len, dir.y / len, dir.z / len)

        let fired = weaponSystem.fire(onHit: { [weak self] damage, weapon in
            guard let self = self else { return }
            let hitResult = self.zombieManager.checkRayHit(from: startPos, direction: normDir, maxDistance: 50.0, damage: damage)
            if hitResult.hit {
                if hitResult.killed, let kind = hitResult.kind {
                    self.waveManager.recordZombieKilled(kind: kind)
                    self.hudView.showToast(message: "+\(kind.goldReward)$ \(kind.rawValue) Eliminato!")
                } else {
                    self.hudView.showToast(message: "Colpo a segno! (\(Int(damage)) Dmg)")
                }
            }
        }, onThrowExplosive: { [weak self] spawnPos, maxDmg in
            guard let self = self else { return }
            // Simula esplosione dinamite dopo 1 secondo a 12 metri davanti al giocatore
            let blastCenter = SCNVector3(spawnPos.x + normDir.x * 12.0, 0.5, spawnPos.z + normDir.z * 12.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let affected = self.zombieManager.applyExplosion(center: blastCenter, radius: 10.0, maxDamage: maxDmg)
                for item in affected where item.killed {
                    self.waveManager.recordZombieKilled(kind: item.zombie.kind)
                }
                self.hudView.showToast(message: "💥 BOOM! Dinamite detonata (\(affected.count) nemici colpiti)")
            }
        })

        if fired {
            zombieManager.alertAllZombiesInRange(center: fpsController.playerNode.position, radius: 40.0)
            hudView.updateHotbar(slots: inventoryManager.hotbar, activeIndex: inventoryManager.activeIndex)
        }
    }

    public func hudDidPressReload() {
        weaponSystem.reload()
        hudView.showToast(message: "Ricarica in corso...")
    }

    public func hudDidSelectSlot(index: Int) {
        if inventoryManager.selectSlot(index: index) {
            weaponSystem.equipCurrentWeapon()
            refreshHUDState()
            if let w = inventoryManager.currentWeapon {
                hudView.showToast(message: "Equipaggiato: \(w.displayName)")
            }
        }
    }

    public func hudDidToggleFlashlight() {
        let isOn = fpsController.toggleFlashlight()
        hudView.setFlashlightState(isOn: isOn)
        hudView.showToast(message: isOn ? "🔦 Torcia: Accesa" : "🔦 Torcia: Spenta")
    }

    public func hudDidPressAction() {
        if let chest = activeNearbyChest {
            chestManager.openChest(id: chest.id) { [weak self] reward in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch reward {
                    case .weapon(let item):
                        let result = self.inventoryManager.addWeapon(item)
                        if result.added {
                            self.weaponSystem.equipCurrentWeapon()
                            self.refreshHUDState()
                            self.hudView.showToast(message: "🎁 Trovato: \(item.displayName)!")
                        }

                    case .medkitAndAmmo(let hp, _):
                        self.playerHealth = min(self.maxPlayerHealth, self.playerHealth + hp)
                        self.inventoryManager.restockAmmo()
                        self.refreshHUDState()
                        self.hudView.showToast(message: "🩹 Medkit (+50 HP) e Munizioni ripristinate!")
                    }
                }
            }
        }
    }

    public func hudDidTogglePause() {
        isGamePaused = true
        scnView.isPlaying = false
    }

    public func hudDidResume() {
        isGamePaused = false
        scnView.isPlaying = true
    }

    public func hudDidChangeSensitivity(multiplier: Float) {
        fpsController.sensitivity = multiplier
        hudView.showToast(message: String(format: "Sensibilità impostata a %.1fx", multiplier))
    }

    public func hudDidRestartGame() {
        isGamePaused = false
        isPlayerDead = false
        scnView.isPlaying = true
        playerHealth = 100.0

        fpsController.playerNode.position = SCNVector3(0, fpsController.eyeHeight, 15)
        fpsController.yaw = 0
        fpsController.pitch = 0

        zombieManager.clearAllZombies()
        chestManager.resetChests()
        waveManager.reset()
        inventoryManager = InventoryManager()
        weaponSystem = WeaponSystem(controller: fpsController, inventory: inventoryManager)

        refreshHUDState()
        hudView.hideEndModal()
        hudView.showToast(message: "Nuova partita avviata! Difendi la città.")
    }
}
