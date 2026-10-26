import UIKit
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate, HUDDelegate {
    private var scnView: SCNView!
    private var forestScene: ForestScene!
    private var fpsController: FirstPersonController!
    private var weaponSystem: WeaponSystem!
    private var zombieManager: ZombieManager!
    private var chestManager: ChestManager!
    private var gameMode: EscapeGameMode!
    private var hudView: HUDOverlayView!

    private var lastUpdateTime: TimeInterval = 0
    private var currentMoveForward: Float = 0
    private var currentMoveStrafe: Float = 0

    private var activeNearbyChest: ChestItem?
    private var isNearGate: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
        setupHUD()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    private func setupGame() {
        // Scena 3D
        forestScene = ForestScene()

        // SCNView
        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.scene = forestScene.scene
        scnView.delegate = self
        scnView.isPlaying = true
        scnView.loops = true
        scnView.preferredFramesPerSecond = 60
        scnView.antialiasingMode = .multisampling4X
        view.addSubview(scnView)

        // Controller Prima Persona (Telecamera + Torcia + Supporto Arma)
        fpsController = FirstPersonController()
        forestScene.scene.rootNode.addChildNode(fpsController.playerNode)
        scnView.pointOfView = fpsController.cameraNode

        // Sistema Armi & Nemici & Bauli
        weaponSystem = WeaponSystem(controller: fpsController)
        zombieManager = ZombieManager(scene: forestScene.scene)
        chestManager = ChestManager(scene: forestScene.scene, locations: forestScene.chestLocations)
        gameMode = EscapeGameMode()

        // Callback GameMode
        gameMode.onHealthChanged = { [weak self] hp in
            DispatchQueue.main.async {
                self?.hudView.updateHealth(hp: hp)
            }
        }

        gameMode.onKeysChanged = { [weak self] found, total in
            DispatchQueue.main.async {
                self?.hudView.updateKeys(found: found, total: total)
            }
        }

        gameMode.onGameOver = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.hudView.showGameOverModal(kills: self.gameMode.zombiesKilled)
            }
        }

        gameMode.onVictory = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.hudView.showVictoryModal(kills: self.gameMode.zombiesKilled)
            }
        }
    }

    private func setupHUD() {
        hudView = HUDOverlayView(frame: view.bounds)
        hudView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hudView.delegate = self
        view.addSubview(hudView)

        hudView.updateHealth(hp: gameMode.playerHealth)
        hudView.updateKeys(found: 0, total: 3)
        hudView.updateAmmo(text: weaponSystem.ammoText)
        hudView.showToast(message: "Esplora la foresta, trova i bauli nelle case per armi e chiavi!")
    }

    // GAME LOOP (60 FPS)
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
            return
        }
        let deltaTime = Float(min(time - lastUpdateTime, 0.1))
        lastUpdateTime = time

        guard !gameMode.isGameOver && !gameMode.isVictory else { return }

        // 1. Aggiornamento Movimento Giocatore
        fpsController.updateMovement(forward: currentMoveForward, strafe: currentMoveStrafe, deltaTime: deltaTime) { pos in
            // Confini della foresta (-50 a +50)
            return abs(pos.x) < 52.0 && abs(pos.z) < 52.0
        }

        let playerPos = fpsController.playerNode.position

        // 2. Aggiornamento IA Zombi
        zombieManager.update(playerPosition: playerPos, deltaTime: deltaTime) { [weak self] damage in
            DispatchQueue.main.async {
                self?.gameMode.applyDamage(amount: damage)
                self?.hudView.showToast(message: "Uno zombi ti ha colpito! (-14 HP)")
            }
        }

        // 3. Controllo Prossimità Bauli
        let nearbyChest = chestManager.checkNearbyChest(playerPosition: playerPos, radius: 2.5)
        self.activeNearbyChest = nearbyChest

        // 4. Controllo Prossimità Cancello di Fuga
        if let gate = forestScene.gateNode {
            self.isNearGate = gameMode.isNearGate(playerPosition: playerPos, gatePosition: gate.position)
        }

        // 5. Aggiornamento Prompt Azione su UI principale
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.activeNearbyChest != nil {
                self.hudView.setActionPrompt(title: "📦 APRI BAULE")
            } else if self.isNearGate {
                self.hudView.setActionPrompt(title: "🚪 SBLOCCA CANCELLO")
            } else {
                self.hudView.setActionPrompt(title: nil)
            }
            self.hudView.updateAmmo(text: self.weaponSystem.ammoText)
        }
    }

    // HUD DELEGATE
    func hudDidMove(forward: Float, strafe: Float) {
        currentMoveForward = forward
        currentMoveStrafe = strafe
    }

    func hudDidLook(deltaYaw: Float, deltaPitch: Float) {
        fpsController.updateRotation(deltaYaw: deltaYaw, deltaPitch: deltaPitch)
    }

    func hudDidPressFire() {
        guard !gameMode.isGameOver && !gameMode.isVictory else { return }

        // Calcolo vettore direzione sparo dalla telecamera in coordinate mondiali
        let camNode = fpsController.cameraNode
        let startPos = camNode.convertPosition(SCNVector3Zero, to: nil)
        let forwardLocal = SCNVector3(0, 0, -1)
        let endPos = camNode.convertPosition(forwardLocal, to: nil)
        let dir = SCNVector3(endPos.x - startPos.x, endPos.y - startPos.y, endPos.z - startPos.z)
        let len = sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
        let normDir = SCNVector3(dir.x / len, dir.y / len, dir.z / len)

        let fired = weaponSystem.fire { [weak self] damage in
            guard let self = self else { return }
            let hit = self.zombieManager.checkRayHit(from: startPos, direction: normDir, maxDistance: 45.0, damage: damage)
            if hit {
                self.gameMode.recordKill()
                self.hudView.showToast(message: "Colpo a segno!")
            }
        }

        if fired {
            // Il rumore dello sparo allerta gli zombi nel raggio di 35 metri!
            zombieManager.alertAllZombiesInRange(center: fpsController.playerNode.position, radius: 35.0)
            hudView.updateAmmo(text: weaponSystem.ammoText)
        }
    }

    func hudDidPressReload() {
        weaponSystem.reload()
        hudView.showToast(message: "Ricarica in corso...")
    }

    func hudDidPressSwitchWeapon() {
        weaponSystem.toggleWeapon()
        hudView.updateAmmo(text: weaponSystem.ammoText)
        hudView.showToast(message: "Arma equipaggiata: \(weaponSystem.currentType.rawValue)")
    }

    func hudDidPressAction() {
        // Se vicino a un baule
        if let chest = activeNearbyChest {
            chestManager.openChest(id: chest.id) { [weak self] loot in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch loot {
                    case .shotgun:
                        self.weaponSystem.unlockShotgun()
                        self.hudView.showSwitchWeapon(visible: true)
                        self.hudView.updateAmmo(text: self.weaponSystem.ammoText)
                        self.hudView.showToast(message: "Hai trovato una Doppietta Cal. 12 nei bauli!")

                    case .keyAndMedkit(let keyNum):
                        self.gameMode.addKey(count: 1)
                        self.gameMode.heal(amount: 40)
                        self.hudView.showToast(message: "Hai trovato la Chiave #\(keyNum) e un Medkit (+40 HP)!")

                    case .finalKeys:
                        self.gameMode.addKey(count: 2)
                        self.hudView.showToast(message: "Hai trovato le ultime due Chiavi del Cancello (3/3)!")
                    }
                }
            }
            return
        }

        // Se vicino al cancello
        if isNearGate {
            let result = gameMode.tryUnlockGate()
            hudView.showToast(message: result.message)
        }
    }

    func hudDidRestartGame() {
        hudView.hideModal()
        // Reset posizione e parametri
        fpsController.playerNode.position = SCNVector3(0, fpsController.eyeHeight, 20)
        fpsController.yaw = 0
        fpsController.pitch = 0
        gameMode = EscapeGameMode()
        setupGame()
        hudView.updateHealth(hp: 100)
        hudView.updateKeys(found: 0, total: 3)
        hudView.showSwitchWeapon(visible: false)
        hudView.showToast(message: "Nuova partita! Trova le chiavi ed evita gli zombi.")
    }
}
