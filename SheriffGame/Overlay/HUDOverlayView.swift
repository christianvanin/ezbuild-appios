import UIKit

public protocol HUDDelegate: AnyObject {
    func hudDidMove(forward: Float, strafe: Float)
    func hudDidLook(deltaYaw: Float, deltaPitch: Float)
    func hudDidPressFire()
    func hudDidPressReload()
    func hudDidSelectSlot(index: Int)
    func hudDidToggleFlashlight()
    func hudDidPressAction()
    func hudDidTogglePause()
    func hudDidResume()
    func hudDidRestartGame()
    func hudDidChangeSensitivity(multiplier: Float)
}

public class HUDOverlayView: UIView {
    public weak var delegate: HUDDelegate?

    // Elementi Top Bar
    private let healthBarContainer = UIView()
    private let healthBarFill = UIView()
    private let healthLabel = UILabel()
    private let waveBadgeContainer = UIView()
    private let waveLabel = UILabel()
    private let enemiesLabel = UILabel()
    private let bountyLabel = UILabel()
    private let pauseButton = UIButton(type: .system)

    // Mirino Crosshair FPS
    private let crosshairView = UIView()

    // Joystick Virtuale
    private let joystickBase = UIView()
    private let joystickKnob = UIView()
    private var joystickCenter = CGPoint.zero
    private var joystickTouch: UITouch?

    // Touch per la visuale
    private var lookTouch: UITouch?
    private var lastLookPoint = CGPoint.zero

    // Hotbar Minecraft-style in basso al centro
    private let hotbarContainer = UIStackView()
    private var hotbarSlotViews: [UIButton] = []
    private var hotbarSlotSublabels: [UILabel] = []

    // Pulsanti Azione e Utility (Destra)
    private let fireButton = UIButton(type: .custom)
    private let reloadButton = UIButton(type: .custom)
    private let flashlightButton = UIButton(type: .custom)
    private let backpackButton = UIButton(type: .custom)
    private let actionButton = UIButton(type: .custom)
    private let toastLabel = UILabel()

    // Modale Menu di Pausa
    private let pauseModal = UIView()
    private let pauseTitleLabel = UILabel()
    private let resumeButton = UIButton(type: .system)
    private let restartButton = UIButton(type: .system)
    private let sensitivityLabel = UILabel()
    private let sensMinusButton = UIButton(type: .system)
    private let sensPlusButton = UIButton(type: .system)
    private var currentSens: Float = 1.0

    // Modale Inventario
    private let inventoryModal = UIView()
    private let inventoryTitleLabel = UILabel()
    private let inventoryDetailsLabel = UILabel()
    private let closeInventoryButton = UIButton(type: .system)

    // Modali End Game
    private let endModal = UIView()
    private let endTitleLabel = UILabel()
    private let endDescLabel = UILabel()
    private let endRestartButton = UIButton(type: .system)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Mirino centrale
        crosshairView.translatesAutoresizingMaskIntoConstraints = false
        crosshairView.backgroundColor = .clear
        addSubview(crosshairView)

        let hLine = UIView()
        hLine.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        hLine.translatesAutoresizingMaskIntoConstraints = false
        crosshairView.addSubview(hLine)

        let vLine = UIView()
        vLine.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        vLine.translatesAutoresizingMaskIntoConstraints = false
        crosshairView.addSubview(vLine)

        // 1. Barra Salute (Top Left)
        healthBarContainer.translatesAutoresizingMaskIntoConstraints = false
        healthBarContainer.backgroundColor = UIColor(white: 0.12, alpha: 0.75)
        healthBarContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        healthBarContainer.layer.borderWidth = 1.5
        healthBarContainer.layer.cornerRadius = 6
        healthBarContainer.clipsToBounds = true
        addSubview(healthBarContainer)

        healthBarFill.backgroundColor = UIColor(red: 0.20, green: 0.82, blue: 0.35, alpha: 1.0)
        healthBarFill.translatesAutoresizingMaskIntoConstraints = false
        healthBarContainer.addSubview(healthBarFill)

        healthLabel.text = "100 HP"
        healthLabel.textColor = .white
        healthLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        healthLabel.translatesAutoresizingMaskIntoConstraints = false
        healthBarContainer.addSubview(healthLabel)

        // 2. Wave Badge & Enemies (Top Center)
        waveBadgeContainer.translatesAutoresizingMaskIntoConstraints = false
        waveBadgeContainer.backgroundColor = UIColor(white: 0.08, alpha: 0.82)
        waveBadgeContainer.layer.borderColor = UIColor(red: 0.95, green: 0.65, blue: 0.15, alpha: 0.9).cgColor
        waveBadgeContainer.layer.borderWidth = 1.5
        waveBadgeContainer.layer.cornerRadius = 8
        addSubview(waveBadgeContainer)

        waveLabel.text = "🔥 ONDATA 1"
        waveLabel.textColor = UIColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 1.0)
        waveLabel.font = UIFont.systemFont(ofSize: 15, weight: .black)
        waveLabel.textAlignment = .center
        waveLabel.translatesAutoresizingMaskIntoConstraints = false
        waveBadgeContainer.addSubview(waveLabel)

        enemiesLabel.text = "ZOMBI: 7/7"
        enemiesLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        enemiesLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        enemiesLabel.textAlignment = .center
        enemiesLabel.translatesAutoresizingMaskIntoConstraints = false
        waveBadgeContainer.addSubview(enemiesLabel)

        // 3. Taglia Oro & Tasto Pausa (Top Right)
        bountyLabel.text = "💰 $0"
        bountyLabel.textColor = UIColor(red: 1.0, green: 0.84, blue: 0.2, alpha: 1.0)
        bountyLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .black)
        bountyLabel.textAlignment = .right
        bountyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bountyLabel)

        pauseButton.setTitle("⏸️", for: .normal)
        pauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        pauseButton.backgroundColor = UIColor(white: 0.15, alpha: 0.8)
        pauseButton.layer.cornerRadius = 18
        pauseButton.layer.borderWidth = 1.5
        pauseButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.addTarget(self, action: #selector(handlePauseTapped), for: .touchUpInside)
        addSubview(pauseButton)

        // 4. Joystick Virtuale
        joystickBase.frame = CGRect(x: 45, y: bounds.height - 180, width: 130, height: 130)
        joystickBase.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
        joystickBase.layer.cornerRadius = 65
        joystickBase.layer.borderColor = UIColor(white: 1.0, alpha: 0.3).cgColor
        joystickBase.layer.borderWidth = 2
        joystickBase.isUserInteractionEnabled = false
        addSubview(joystickBase)

        joystickKnob.frame = CGRect(x: 40, y: 40, width: 50, height: 50)
        joystickKnob.backgroundColor = UIColor(white: 1.0, alpha: 0.6)
        joystickKnob.layer.cornerRadius = 25
        joystickKnob.isUserInteractionEnabled = false
        joystickBase.addSubview(joystickKnob)

        // 5. Hotbar Rapida (In basso al centro, stile Minecraft)
        hotbarContainer.axis = .horizontal
        hotbarContainer.spacing = 8
        hotbarContainer.distribution = .fillEqually
        hotbarContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hotbarContainer)

        for i in 0..<4 {
            let slot = UIButton(type: .custom)
            slot.backgroundColor = UIColor(white: 0.08, alpha: 0.85)
            slot.layer.cornerRadius = 8
            slot.layer.borderWidth = 2.0
            slot.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
            slot.tag = i
            slot.titleLabel?.font = UIFont.systemFont(ofSize: 20)
            slot.addTarget(self, action: #selector(handleSlotTapped(_:)), for: .touchUpInside)

            let sublabel = UILabel()
            sublabel.textColor = .white
            sublabel.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .heavy)
            sublabel.textAlignment = .center
            sublabel.translatesAutoresizingMaskIntoConstraints = false
            slot.addSubview(sublabel)

            NSLayoutConstraint.activate([
                sublabel.bottomAnchor.constraint(equalTo: slot.bottomAnchor, constant: -3),
                sublabel.centerXAnchor.constraint(equalTo: slot.centerXAnchor)
            ])

            hotbarSlotViews.append(slot)
            hotbarSlotSublabels.append(sublabel)
            hotbarContainer.addArrangedSubview(slot)
        }

        // 6. Pulsanti Fuoco & Ricarica (Destra)
        fireButton.setTitle("💥 FUOCO", for: .normal)
        fireButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .heavy)
        fireButton.backgroundColor = UIColor(red: 0.88, green: 0.22, blue: 0.15, alpha: 0.9)
        fireButton.layer.cornerRadius = 40
        fireButton.layer.borderColor = UIColor.white.cgColor
        fireButton.layer.borderWidth = 2
        fireButton.translatesAutoresizingMaskIntoConstraints = false
        fireButton.addTarget(self, action: #selector(handleFireTapped), for: .touchUpInside)
        addSubview(fireButton)

        reloadButton.setTitle("🔄 RICARICA", for: .normal)
        reloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        reloadButton.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
        reloadButton.layer.cornerRadius = 22
        reloadButton.layer.borderWidth = 1
        reloadButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.addTarget(self, action: #selector(handleReloadTapped), for: .touchUpInside)
        addSubview(reloadButton)

        flashlightButton.setTitle("🔦 TORCIA", for: .normal)
        flashlightButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        flashlightButton.backgroundColor = UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 0.85)
        flashlightButton.setTitleColor(.black, for: .normal)
        flashlightButton.layer.cornerRadius = 22
        flashlightButton.layer.borderWidth = 1
        flashlightButton.layer.borderColor = UIColor.white.cgColor
        flashlightButton.translatesAutoresizingMaskIntoConstraints = false
        flashlightButton.addTarget(self, action: #selector(handleFlashlightTapped), for: .touchUpInside)
        addSubview(flashlightButton)

        backpackButton.setTitle("🎒 ZAINO", for: .normal)
        backpackButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        backpackButton.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
        backpackButton.layer.cornerRadius = 22
        backpackButton.layer.borderWidth = 1
        backpackButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        backpackButton.translatesAutoresizingMaskIntoConstraints = false
        backpackButton.addTarget(self, action: #selector(handleBackpackTapped), for: .touchUpInside)
        addSubview(backpackButton)

        // 7. Pulsante Azione Centrale ("APRI FORZIERE")
        actionButton.setTitle("📦 APRI FORZIERE", for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .heavy)
        actionButton.backgroundColor = UIColor(red: 0.96, green: 0.75, blue: 0.15, alpha: 0.95)
        actionButton.setTitleColor(.black, for: .normal)
        actionButton.layer.cornerRadius = 24
        actionButton.layer.borderColor = UIColor.white.cgColor
        actionButton.layer.borderWidth = 2
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.isHidden = true
        actionButton.addTarget(self, action: #selector(handleActionTapped), for: .touchUpInside)
        addSubview(actionButton)

        // 8. Toast notifica
        toastLabel.text = ""
        toastLabel.textColor = .yellow
        toastLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        toastLabel.textAlignment = .center
        toastLabel.backgroundColor = UIColor(white: 0.0, alpha: 0.8)
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.alpha = 0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toastLabel)

        setupModals()

        // Setup Vincoli Layout
        NSLayoutConstraint.activate([
            // Crosshair
            crosshairView.centerXAnchor.constraint(equalTo: centerXAnchor),
            crosshairView.centerYAnchor.constraint(equalTo: centerYAnchor),
            crosshairView.widthAnchor.constraint(equalToConstant: 24),
            crosshairView.heightAnchor.constraint(equalToConstant: 24),

            hLine.centerXAnchor.constraint(equalTo: crosshairView.centerXAnchor),
            hLine.centerYAnchor.constraint(equalTo: crosshairView.centerYAnchor),
            hLine.widthAnchor.constraint(equalToConstant: 18),
            hLine.heightAnchor.constraint(equalToConstant: 2),

            vLine.centerXAnchor.constraint(equalTo: crosshairView.centerXAnchor),
            vLine.centerYAnchor.constraint(equalTo: crosshairView.centerYAnchor),
            vLine.widthAnchor.constraint(equalToConstant: 2),
            vLine.heightAnchor.constraint(equalToConstant: 18),

            // Health Bar
            healthBarContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 14),
            healthBarContainer.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 18),
            healthBarContainer.widthAnchor.constraint(equalToConstant: 160),
            healthBarContainer.heightAnchor.constraint(equalToConstant: 26),

            healthBarFill.topAnchor.constraint(equalTo: healthBarContainer.topAnchor),
            healthBarFill.leadingAnchor.constraint(equalTo: healthBarContainer.leadingAnchor),
            healthBarFill.bottomAnchor.constraint(equalTo: healthBarContainer.bottomAnchor),
            healthBarFill.widthAnchor.constraint(equalTo: healthBarContainer.widthAnchor),

            healthLabel.centerXAnchor.constraint(equalTo: healthBarContainer.centerXAnchor),
            healthLabel.centerYAnchor.constraint(equalTo: healthBarContainer.centerYAnchor),

            // Wave Badge
            waveBadgeContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            waveBadgeContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            waveBadgeContainer.widthAnchor.constraint(equalToConstant: 190),
            waveBadgeContainer.heightAnchor.constraint(equalToConstant: 44),

            waveLabel.topAnchor.constraint(equalTo: waveBadgeContainer.topAnchor, constant: 3),
            waveLabel.centerXAnchor.constraint(equalTo: waveBadgeContainer.centerXAnchor),

            enemiesLabel.bottomAnchor.constraint(equalTo: waveBadgeContainer.bottomAnchor, constant: -4),
            enemiesLabel.centerXAnchor.constraint(equalTo: waveBadgeContainer.centerXAnchor),

            // Pause & Bounty
            pauseButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 14),
            pauseButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -18),
            pauseButton.widthAnchor.constraint(equalToConstant: 38),
            pauseButton.heightAnchor.constraint(equalToConstant: 38),

            bountyLabel.centerYAnchor.constraint(equalTo: pauseButton.centerYAnchor),
            bountyLabel.trailingAnchor.constraint(equalTo: pauseButton.leadingAnchor, constant: -14),

            // Hotbar (In basso al centro)
            hotbarContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            hotbarContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -14),
            hotbarContainer.widthAnchor.constraint(equalToConstant: 260),
            hotbarContainer.heightAnchor.constraint(equalToConstant: 58),

            // Pulsanti Fuoco & Utility (Destra)
            fireButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fireButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            fireButton.widthAnchor.constraint(equalToConstant: 80),
            fireButton.heightAnchor.constraint(equalToConstant: 80),

            reloadButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            reloadButton.trailingAnchor.constraint(equalTo: fireButton.leadingAnchor, constant: -14),
            reloadButton.widthAnchor.constraint(equalToConstant: 96),
            reloadButton.heightAnchor.constraint(equalToConstant: 42),

            flashlightButton.bottomAnchor.constraint(equalTo: reloadButton.topAnchor, constant: -10),
            flashlightButton.trailingAnchor.constraint(equalTo: fireButton.leadingAnchor, constant: -14),
            flashlightButton.widthAnchor.constraint(equalToConstant: 96),
            flashlightButton.heightAnchor.constraint(equalToConstant: 40),

            backpackButton.bottomAnchor.constraint(equalTo: flashlightButton.topAnchor, constant: -10),
            backpackButton.trailingAnchor.constraint(equalTo: fireButton.leadingAnchor, constant: -14),
            backpackButton.widthAnchor.constraint(equalToConstant: 96),
            backpackButton.heightAnchor.constraint(equalToConstant: 38),

            // Action Button
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: hotbarContainer.topAnchor, constant: -12),
            actionButton.widthAnchor.constraint(equalToConstant: 180),
            actionButton.heightAnchor.constraint(equalToConstant: 46),

            // Toast
            toastLabel.topAnchor.constraint(equalTo: waveBadgeContainer.bottomAnchor, constant: 12),
            toastLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            toastLabel.heightAnchor.constraint(equalToConstant: 36),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 220)
        ])
    }

    private func setupModals() {
        // --- 1. MODALE PAUSA ---
        pauseModal.backgroundColor = UIColor(white: 0.06, alpha: 0.94)
        pauseModal.layer.cornerRadius = 16
        pauseModal.layer.borderWidth = 2
        pauseModal.layer.borderColor = UIColor.white.cgColor
        pauseModal.translatesAutoresizingMaskIntoConstraints = false
        pauseModal.isHidden = true
        addSubview(pauseModal)

        pauseTitleLabel.text = "⏸️ GIOCO IN PAUSA"
        pauseTitleLabel.textColor = .white
        pauseTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .black)
        pauseTitleLabel.textAlignment = .center
        pauseTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pauseModal.addSubview(pauseTitleLabel)

        resumeButton.setTitle("▶ RIPRENDI", for: .normal)
        resumeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        resumeButton.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        resumeButton.setTitleColor(.white, for: .normal)
        resumeButton.layer.cornerRadius = 8
        resumeButton.translatesAutoresizingMaskIntoConstraints = false
        resumeButton.addTarget(self, action: #selector(handleResumeTapped), for: .touchUpInside)
        pauseModal.addSubview(resumeButton)

        restartButton.setTitle("🔄 RIAVVIA PARTITA", for: .normal)
        restartButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        restartButton.backgroundColor = UIColor(white: 0.25, alpha: 1.0)
        restartButton.setTitleColor(.white, for: .normal)
        restartButton.layer.cornerRadius = 8
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        restartButton.addTarget(self, action: #selector(handleRestartTapped), for: .touchUpInside)
        pauseModal.addSubview(restartButton)

        sensitivityLabel.text = "SENSIBILITÀ: 1.0x"
        sensitivityLabel.textColor = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        sensitivityLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        sensitivityLabel.textAlignment = .center
        sensitivityLabel.translatesAutoresizingMaskIntoConstraints = false
        pauseModal.addSubview(sensitivityLabel)

        sensMinusButton.setTitle("➖", for: .normal)
        sensMinusButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        sensMinusButton.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        sensMinusButton.layer.cornerRadius = 6
        sensMinusButton.translatesAutoresizingMaskIntoConstraints = false
        sensMinusButton.addTarget(self, action: #selector(handleSensMinus), for: .touchUpInside)
        pauseModal.addSubview(sensMinusButton)

        sensPlusButton.setTitle("➕", for: .normal)
        sensPlusButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        sensPlusButton.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        sensPlusButton.layer.cornerRadius = 6
        sensPlusButton.translatesAutoresizingMaskIntoConstraints = false
        sensPlusButton.addTarget(self, action: #selector(handleSensPlus), for: .touchUpInside)
        pauseModal.addSubview(sensPlusButton)

        NSLayoutConstraint.activate([
            pauseModal.centerXAnchor.constraint(equalTo: centerXAnchor),
            pauseModal.centerYAnchor.constraint(equalTo: centerYAnchor),
            pauseModal.widthAnchor.constraint(equalToConstant: 320),
            pauseModal.heightAnchor.constraint(equalToConstant: 250),

            pauseTitleLabel.topAnchor.constraint(equalTo: pauseModal.topAnchor, constant: 18),
            pauseTitleLabel.centerXAnchor.constraint(equalTo: pauseModal.centerXAnchor),

            resumeButton.topAnchor.constraint(equalTo: pauseTitleLabel.bottomAnchor, constant: 16),
            resumeButton.centerXAnchor.constraint(equalTo: pauseModal.centerXAnchor),
            resumeButton.widthAnchor.constraint(equalToConstant: 220),
            resumeButton.heightAnchor.constraint(equalToConstant: 42),

            sensitivityLabel.topAnchor.constraint(equalTo: resumeButton.bottomAnchor, constant: 14),
            sensitivityLabel.centerXAnchor.constraint(equalTo: pauseModal.centerXAnchor),

            sensMinusButton.centerYAnchor.constraint(equalTo: sensitivityLabel.centerYAnchor),
            sensMinusButton.trailingAnchor.constraint(equalTo: sensitivityLabel.leadingAnchor, constant: -12),
            sensMinusButton.widthAnchor.constraint(equalToConstant: 36),
            sensMinusButton.heightAnchor.constraint(equalToConstant: 32),

            sensPlusButton.centerYAnchor.constraint(equalTo: sensitivityLabel.centerYAnchor),
            sensPlusButton.leadingAnchor.constraint(equalTo: sensitivityLabel.trailingAnchor, constant: 12),
            sensPlusButton.widthAnchor.constraint(equalToConstant: 36),
            sensPlusButton.heightAnchor.constraint(equalToConstant: 32),

            restartButton.topAnchor.constraint(equalTo: sensitivityLabel.bottomAnchor, constant: 16),
            restartButton.centerXAnchor.constraint(equalTo: pauseModal.centerXAnchor),
            restartButton.widthAnchor.constraint(equalToConstant: 220),
            restartButton.heightAnchor.constraint(equalToConstant: 38)
        ])

        // --- 2. MODALE INVENTARIO ---
        inventoryModal.backgroundColor = UIColor(white: 0.08, alpha: 0.95)
        inventoryModal.layer.cornerRadius = 16
        inventoryModal.layer.borderWidth = 2
        inventoryModal.layer.borderColor = UIColor(red: 0.95, green: 0.65, blue: 0.15, alpha: 0.9).cgColor
        inventoryModal.translatesAutoresizingMaskIntoConstraints = false
        inventoryModal.isHidden = true
        addSubview(inventoryModal)

        inventoryTitleLabel.text = "🎒 INVENTARIO ARMI"
        inventoryTitleLabel.textColor = UIColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 1.0)
        inventoryTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .black)
        inventoryTitleLabel.textAlignment = .center
        inventoryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        inventoryModal.addSubview(inventoryTitleLabel)

        inventoryDetailsLabel.textColor = .white
        inventoryDetailsLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        inventoryDetailsLabel.numberOfLines = 0
        inventoryDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        inventoryModal.addSubview(inventoryDetailsLabel)

        closeInventoryButton.setTitle("CHIUDI", for: .normal)
        closeInventoryButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        closeInventoryButton.backgroundColor = UIColor(white: 0.25, alpha: 1.0)
        closeInventoryButton.setTitleColor(.white, for: .normal)
        closeInventoryButton.layer.cornerRadius = 6
        closeInventoryButton.translatesAutoresizingMaskIntoConstraints = false
        closeInventoryButton.addTarget(self, action: #selector(handleCloseInventory), for: .touchUpInside)
        inventoryModal.addSubview(closeInventoryButton)

        NSLayoutConstraint.activate([
            inventoryModal.centerXAnchor.constraint(equalTo: centerXAnchor),
            inventoryModal.centerYAnchor.constraint(equalTo: centerYAnchor),
            inventoryModal.widthAnchor.constraint(equalToConstant: 360),
            inventoryModal.heightAnchor.constraint(equalToConstant: 260),

            inventoryTitleLabel.topAnchor.constraint(equalTo: inventoryModal.topAnchor, constant: 16),
            inventoryTitleLabel.centerXAnchor.constraint(equalTo: inventoryModal.centerXAnchor),

            inventoryDetailsLabel.topAnchor.constraint(equalTo: inventoryTitleLabel.bottomAnchor, constant: 14),
            inventoryDetailsLabel.leadingAnchor.constraint(equalTo: inventoryModal.leadingAnchor, constant: 18),
            inventoryDetailsLabel.trailingAnchor.constraint(equalTo: inventoryModal.trailingAnchor, constant: -18),

            closeInventoryButton.bottomAnchor.constraint(equalTo: inventoryModal.bottomAnchor, constant: -16),
            closeInventoryButton.centerXAnchor.constraint(equalTo: inventoryModal.centerXAnchor),
            closeInventoryButton.widthAnchor.constraint(equalToConstant: 140),
            closeInventoryButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        // --- 3. MODALE FINE PARTITA ---
        endModal.backgroundColor = UIColor(white: 0.05, alpha: 0.94)
        endModal.layer.cornerRadius = 16
        endModal.layer.borderWidth = 2
        endModal.layer.borderColor = UIColor.white.cgColor
        endModal.translatesAutoresizingMaskIntoConstraints = false
        endModal.isHidden = true
        addSubview(endModal)

        endTitleLabel.textColor = .white
        endTitleLabel.font = UIFont.systemFont(ofSize: 26, weight: .black)
        endTitleLabel.textAlignment = .center
        endTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        endModal.addSubview(endTitleLabel)

        endDescLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        endDescLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        endDescLabel.textAlignment = .center
        endDescLabel.numberOfLines = 0
        endDescLabel.translatesAutoresizingMaskIntoConstraints = false
        endModal.addSubview(endDescLabel)

        endRestartButton.setTitle("GIOCA DI NUOVO", for: .normal)
        endRestartButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        endRestartButton.backgroundColor = UIColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1.0)
        endRestartButton.setTitleColor(.black, for: .normal)
        endRestartButton.layer.cornerRadius = 8
        endRestartButton.translatesAutoresizingMaskIntoConstraints = false
        endRestartButton.addTarget(self, action: #selector(handleRestartTapped), for: .touchUpInside)
        endModal.addSubview(endRestartButton)

        NSLayoutConstraint.activate([
            endModal.centerXAnchor.constraint(equalTo: centerXAnchor),
            endModal.centerYAnchor.constraint(equalTo: centerYAnchor),
            endModal.widthAnchor.constraint(equalToConstant: 360),
            endModal.heightAnchor.constraint(equalToConstant: 220),

            endTitleLabel.topAnchor.constraint(equalTo: endModal.topAnchor, constant: 24),
            endTitleLabel.centerXAnchor.constraint(equalTo: endModal.centerXAnchor),

            endDescLabel.topAnchor.constraint(equalTo: endTitleLabel.bottomAnchor, constant: 14),
            endDescLabel.leadingAnchor.constraint(equalTo: endModal.leadingAnchor, constant: 20),
            endDescLabel.trailingAnchor.constraint(equalTo: endModal.trailingAnchor, constant: -20),

            endRestartButton.bottomAnchor.constraint(equalTo: endModal.bottomAnchor, constant: -24),
            endRestartButton.centerXAnchor.constraint(equalTo: endModal.centerXAnchor),
            endRestartButton.widthAnchor.constraint(equalToConstant: 180),
            endRestartButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        joystickBase.frame = CGRect(x: safeAreaInsets.left + 35, y: bounds.height - 180 - safeAreaInsets.bottom, width: 130, height: 130)
        joystickCenter = CGPoint(x: 65, y: 65)
    }

    // Touch Handling per movimento joystick e visuale
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            if loc.x < bounds.width * 0.45 && joystickTouch == nil {
                joystickTouch = touch
                updateJoystick(location: touch.location(in: joystickBase))
            } else if loc.x >= bounds.width * 0.45 && lookTouch == nil {
                lookTouch = touch
                lastLookPoint = loc
            }
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == joystickTouch {
                updateJoystick(location: touch.location(in: joystickBase))
            } else if touch == lookTouch {
                let currentPoint = touch.location(in: self)
                let deltaX = Float(currentPoint.x - lastLookPoint.x) * 0.005
                let deltaY = Float(currentPoint.y - lastLookPoint.y) * 0.005
                lastLookPoint = currentPoint
                delegate?.hudDidLook(deltaYaw: deltaX, deltaPitch: deltaY)
            }
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == joystickTouch {
                resetJoystick()
            } else if touch == lookTouch {
                lookTouch = nil
            }
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func updateJoystick(location: CGPoint) {
        let dx = Float(location.x - joystickCenter.x)
        let dy = Float(location.y - joystickCenter.y)
        let maxRadius: Float = 50.0

        let dist = sqrt(dx * dx + dy * dy)
        let clampedDist = min(dist, maxRadius)
        let angle = atan2(dy, dx)

        let knobX = CGFloat(Float(joystickCenter.x) + cos(angle) * clampedDist)
        let knobY = CGFloat(Float(joystickCenter.y) + sin(angle) * clampedDist)
        joystickKnob.center = CGPoint(x: knobX, y: knobY)

        let normX = (knobX - joystickCenter.x) / CGFloat(maxRadius)
        let normY = (knobY - joystickCenter.y) / CGFloat(maxRadius)

        delegate?.hudDidMove(forward: Float(-normY), strafe: Float(normX))
    }

    private func resetJoystick() {
        joystickTouch = nil
        joystickKnob.center = joystickCenter
        delegate?.hudDidMove(forward: 0, strafe: 0)
    }

    // Handlers
    @objc private func handleFireTapped() { delegate?.hudDidPressFire() }
    @objc private func handleReloadTapped() { delegate?.hudDidPressReload() }
    @objc private func handleFlashlightTapped() { delegate?.hudDidToggleFlashlight() }
    @objc private func handleActionTapped() { delegate?.hudDidPressAction() }
    @objc private func handlePauseTapped() {
        pauseModal.isHidden = false
        delegate?.hudDidTogglePause()
    }
    @objc private func handleResumeTapped() {
        pauseModal.isHidden = true
        delegate?.hudDidResume()
    }
    @objc private func handleRestartTapped() {
        pauseModal.isHidden = true
        endModal.isHidden = true
        delegate?.hudDidRestartGame()
    }
    @objc private func handleBackpackTapped() {
        inventoryModal.isHidden = false
    }
    @objc private func handleCloseInventory() {
        inventoryModal.isHidden = true
    }
    @objc private func handleSlotTapped(_ sender: UIButton) {
        delegate?.hudDidSelectSlot(index: sender.tag)
    }
    @objc private func handleSensMinus() {
        currentSens = max(0.4, currentSens - 0.2)
        sensitivityLabel.text = String(format: "SENSIBILITÀ: %.1fx", currentSens)
        delegate?.hudDidChangeSensitivity(multiplier: currentSens)
    }
    @objc private func handleSensPlus() {
        currentSens = min(2.4, currentSens + 0.2)
        sensitivityLabel.text = String(format: "SENSIBILITÀ: %.1fx", currentSens)
        delegate?.hudDidChangeSensitivity(multiplier: currentSens)
    }

    // Metodi di Aggiornamento Stato HUD
    public func updateHealth(hp: Float) {
        let percent = max(0, min(1.0, hp / 100.0))
        healthLabel.text = "\(Int(hp)) HP"
        healthBarFill.backgroundColor = hp > 40 ? UIColor(red: 0.20, green: 0.82, blue: 0.35, alpha: 1.0) : UIColor(red: 0.88, green: 0.22, blue: 0.15, alpha: 1.0)
        UIView.animate(withDuration: 0.2) {
            self.healthBarFill.transform = CGAffineTransform(scaleX: CGFloat(percent), y: 1.0)
        }
    }

    public func updateWaveInfo(wave: Int, aliveZombies: Int, totalInWave: Int, isPrep: Bool, prepSeconds: Float) {
        if isPrep {
            waveLabel.text = "⏳ PREPARATI: \(Int(prepSeconds))s"
            enemiesLabel.text = "PROSSIMA ONDATA: \(wave)"
        } else {
            waveLabel.text = "🔥 ONDATA \(wave)"
            enemiesLabel.text = "ZOMBI: \(aliveZombies)/\(totalInWave)"
        }
    }

    public func updateBounty(gold: Int) {
        bountyLabel.text = "💰 $\(gold)"
    }

    public func updateHotbar(slots: [WeaponItem?], activeIndex: Int) {
        for i in 0..<hotbarSlotViews.count {
            let btn = hotbarSlotViews[i]
            let sub = hotbarSlotSublabels[i]

            if i < slots.count, let weapon = slots[i] {
                btn.setTitle(weapon.kind.iconSymbol, for: .normal)
                btn.layer.borderColor = weapon.rarity.color.cgColor
                sub.text = weapon.currentMag == 999 ? "∞" : "\(weapon.currentMag)"
            } else {
                btn.setTitle("", for: .normal)
                btn.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                sub.text = ""
            }

            if i == activeIndex {
                btn.layer.borderWidth = 3.5
                btn.backgroundColor = UIColor(white: 0.25, alpha: 0.95)
            } else {
                btn.layer.borderWidth = 1.8
                btn.backgroundColor = UIColor(white: 0.08, alpha: 0.85)
            }
        }
    }

    public func updateInventoryDetails(weapons: [WeaponItem]) {
        var text = ""
        for (idx, w) in weapons.enumerated() {
            text += "#\(idx + 1) \(w.displayName)\n"
            text += "Danno: \(Int(w.damage)) | Munizioni: \(w.ammoDisplay)\n\n"
        }
        if text.isEmpty {
            text = "Nessuna arma nello zaino. Apri i forzieri per trovare armi rare!"
        }
        inventoryDetailsLabel.text = text
    }

    public func setFlashlightState(isOn: Bool) {
        flashlightButton.backgroundColor = isOn ? UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 0.9) : UIColor(white: 0.25, alpha: 0.8)
        flashlightButton.setTitleColor(isOn ? .black : .white, for: .normal)
    }

    public func setActionPrompt(title: String?) {
        if let title = title {
            actionButton.setTitle(title, for: .normal)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }
    }

    public func showToast(message: String) {
        toastLabel.text = "  \(message)  "
        toastLabel.alpha = 1.0
        UIView.animate(withDuration: 0.4, delay: 2.2, options: .curveEaseInOut) {
            self.toastLabel.alpha = 0.0
        }
    }

    public func showGameOverModal(wave: Int, kills: Int, bounty: Int) {
        endTitleLabel.text = "💀 SEI MORTO"
        endTitleLabel.textColor = UIColor(red: 0.90, green: 0.20, blue: 0.15, alpha: 1.0)
        endDescLabel.text = "Sei sopravvissuto fino all'Ondata \(wave).\nZombi abbattuti: \(kills)\nTaglia accumulata: $\(bounty)"
        endModal.isHidden = false
    }

    public func hideEndModal() {
        endModal.isHidden = true
    }
}
