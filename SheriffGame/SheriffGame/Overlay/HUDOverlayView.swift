import UIKit
import SceneKit

protocol HUDDelegate: AnyObject {
    func hudDidMove(forward: Float, strafe: Float)
    func hudDidLook(deltaYaw: Float, deltaPitch: Float)
    func hudDidPressFire()
    func hudDidPressReload()
    func hudDidPressSwitchWeapon()
    func hudDidPressAction()
    func hudDidRestartGame()
}

class HUDOverlayView: UIView {
    weak var delegate: HUDDelegate?

    // Elementi UI Superiori
    private let healthBarContainer = UIView()
    private let healthBarFill = UIView()
    private let healthLabel = UILabel()
    private let keysLabel = UILabel()
    private let ammoLabel = UILabel()
    private let toastLabel = UILabel()

    // Mirino centrale (Crosshair stile FPS / Minecraft)
    private let crosshairView = UIView()

    // Joystick Virtuale (Sinistra)
    private let joystickBase = UIView()
    private let joystickKnob = UIView()
    private var joystickCenter = CGPoint.zero
    private var isDraggingJoystick = false
    private var joystickTouch: UITouch?

    // Touch per la visuale (Destra)
    private var lookTouch: UITouch?
    private var lastLookPoint = CGPoint.zero

    // Pulsanti Azione (Destra)
    private let fireButton = UIButton(type: .custom)
    private let reloadButton = UIButton(type: .custom)
    private let switchWeaponButton = UIButton(type: .custom)
    private let actionButton = UIButton(type: .custom) // "APRI BAULE" / "SBLOCCA"

    // Schermate End Game
    private let overlayModal = UIView()
    private let modalTitleLabel = UILabel()
    private let modalDescLabel = UILabel()
    private let restartButton = UIButton(type: .system)

    override init(frame: CGRect) {
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

        // Linee del mirino a croce
        let hLine = UIView()
        hLine.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        hLine.translatesAutoresizingMaskIntoConstraints = false
        crosshairView.addSubview(hLine)

        let vLine = UIView()
        vLine.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        vLine.translatesAutoresizingMaskIntoConstraints = false
        crosshairView.addSubview(vLine)

        // Barra della Salute (Top Left)
        healthBarContainer.translatesAutoresizingMaskIntoConstraints = false
        healthBarContainer.backgroundColor = UIColor(white: 0.1, alpha: 0.7)
        healthBarContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        healthBarContainer.layer.borderWidth = 1.5
        healthBarContainer.layer.cornerRadius = 6
        healthBarContainer.clipsToBounds = true
        addSubview(healthBarContainer)

        healthBarFill.backgroundColor = UIColor(red: 0.20, green: 0.80, blue: 0.30, alpha: 1.0)
        healthBarFill.translatesAutoresizingMaskIntoConstraints = false
        healthBarContainer.addSubview(healthBarFill)

        healthLabel.text = "SALUTE: 100%"
        healthLabel.textColor = .white
        healthLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        healthLabel.translatesAutoresizingMaskIntoConstraints = false
        healthBarContainer.addSubview(healthLabel)

        // Stato Chiavi e Obiettivo (Top Right)
        keysLabel.text = "🗝️ CHIAVI: 0 / 3"
        keysLabel.textColor = UIColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 1.0)
        keysLabel.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .black)
        keysLabel.textAlignment = .right
        keysLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(keysLabel)

        // Contatore Munizioni (Bottom Right sopra pulsanti)
        ammoLabel.text = "🔫 6 / ∞"
        ammoLabel.textColor = .white
        ammoLabel.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .black)
        ammoLabel.textAlignment = .right
        ammoLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ammoLabel)

        // Toast Notifiche (Top Center)
        toastLabel.text = ""
        toastLabel.textColor = .yellow
        toastLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        toastLabel.textAlignment = .center
        toastLabel.backgroundColor = UIColor(white: 0.0, alpha: 0.75)
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.alpha = 0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toastLabel)

        // Setup Joystick Base & Knob
        joystickBase.frame = CGRect(x: 50, y: bounds.height - 180, width: 130, height: 130)
        joystickBase.backgroundColor = UIColor(white: 1.0, alpha: 0.15)
        joystickBase.layer.cornerRadius = 65
        joystickBase.layer.borderColor = UIColor(white: 1.0, alpha: 0.35).cgColor
        joystickBase.layer.borderWidth = 2
        joystickBase.isUserInteractionEnabled = false
        addSubview(joystickBase)

        joystickKnob.frame = CGRect(x: 40, y: 40, width: 50, height: 50)
        joystickKnob.backgroundColor = UIColor(white: 1.0, alpha: 0.6)
        joystickKnob.layer.cornerRadius = 25
        joystickKnob.isUserInteractionEnabled = false
        joystickBase.addSubview(joystickKnob)

        // Pulsante FUOCO (Grande a destra)
        fireButton.setTitle("💥 FUOCO", for: .normal)
        fireButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        fireButton.backgroundColor = UIColor(red: 0.85, green: 0.25, blue: 0.15, alpha: 0.85)
        fireButton.layer.cornerRadius = 40
        fireButton.layer.borderColor = UIColor.white.cgColor
        fireButton.layer.borderWidth = 2
        fireButton.translatesAutoresizingMaskIntoConstraints = false
        fireButton.addTarget(self, action: #selector(handleFireTapped), for: .touchUpInside)
        addSubview(fireButton)

        // Pulsante Ricarica
        reloadButton.setTitle("🔄 RICARICA", for: .normal)
        reloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        reloadButton.backgroundColor = UIColor(white: 0.2, alpha: 0.75)
        reloadButton.layer.cornerRadius = 22
        reloadButton.layer.borderWidth = 1
        reloadButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.addTarget(self, action: #selector(handleReloadTapped), for: .touchUpInside)
        addSubview(reloadButton)

        // Pulsante Cambio Arma (Nascosto finché non si trova lo shotgun)
        switchWeaponButton.setTitle("⇄ CAMBIA ARMA", for: .normal)
        switchWeaponButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        switchWeaponButton.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.85)
        switchWeaponButton.layer.cornerRadius = 22
        switchWeaponButton.layer.borderWidth = 1
        switchWeaponButton.layer.borderColor = UIColor.white.cgColor
        switchWeaponButton.translatesAutoresizingMaskIntoConstraints = false
        switchWeaponButton.isHidden = true
        switchWeaponButton.addTarget(self, action: #selector(handleSwitchWeaponTapped), for: .touchUpInside)
        addSubview(switchWeaponButton)

        // Pulsante Azione Contestuale ("APRI BAULE" o "SBLOCCA CANCELLO")
        actionButton.setTitle("📦 APRI BAULE", for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        actionButton.backgroundColor = UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 0.95)
        actionButton.setTitleColor(.black, for: .normal)
        actionButton.layer.cornerRadius = 25
        actionButton.layer.borderColor = UIColor.white.cgColor
        actionButton.layer.borderWidth = 2.5
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.isHidden = true
        actionButton.addTarget(self, action: #selector(handleActionTapped), for: .touchUpInside)
        addSubview(actionButton)

        // Schermata Modale Fine Partita (Vittoria o Sconfitta)
        setupEndGameModal()

        // Vincoli Autolayout
        NSLayoutConstraint.activate([
            // Mirino
            crosshairView.centerXAnchor.constraint(equalTo: centerXAnchor),
            crosshairView.centerYAnchor.constraint(equalTo: centerYAnchor),
            crosshairView.widthAnchor.constraint(equalToConstant: 24),
            crosshairView.heightAnchor.constraint(equalToConstant: 24),

            hLine.centerXAnchor.constraint(equalTo: crosshairView.centerXAnchor),
            hLine.centerYAnchor.constraint(equalTo: crosshairView.centerYAnchor),
            hLine.widthAnchor.constraint(equalToConstant: 20),
            hLine.heightAnchor.constraint(equalToConstant: 2),

            vLine.centerXAnchor.constraint(equalTo: crosshairView.centerXAnchor),
            vLine.centerYAnchor.constraint(equalTo: crosshairView.centerYAnchor),
            vLine.widthAnchor.constraint(equalToConstant: 2),
            vLine.heightAnchor.constraint(equalToConstant: 20),

            // Salute
            healthBarContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            healthBarContainer.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            healthBarContainer.widthAnchor.constraint(equalToConstant: 180),
            healthBarContainer.heightAnchor.constraint(equalToConstant: 28),

            healthBarFill.topAnchor.constraint(equalTo: healthBarContainer.topAnchor),
            healthBarFill.leadingAnchor.constraint(equalTo: healthBarContainer.leadingAnchor),
            healthBarFill.bottomAnchor.constraint(equalTo: healthBarContainer.bottomAnchor),
            healthBarFill.widthAnchor.constraint(equalTo: healthBarContainer.widthAnchor),

            healthLabel.centerXAnchor.constraint(equalTo: healthBarContainer.centerXAnchor),
            healthLabel.centerYAnchor.constraint(equalTo: healthBarContainer.centerYAnchor),

            // Chiavi
            keysLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            keysLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),

            // Munizioni
            ammoLabel.bottomAnchor.constraint(equalTo: fireButton.topAnchor, constant: -12),
            ammoLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -30),

            // Toast
            toastLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 60),
            toastLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            toastLabel.heightAnchor.constraint(equalToConstant: 36),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),

            // Pulsante Fuoco
            fireButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -24),
            fireButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -24),
            fireButton.widthAnchor.constraint(equalToConstant: 80),
            fireButton.heightAnchor.constraint(equalToConstant: 80),

            // Pulsante Ricarica
            reloadButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -24),
            reloadButton.trailingAnchor.constraint(equalTo: fireButton.leadingAnchor, constant: -16),
            reloadButton.widthAnchor.constraint(equalToConstant: 100),
            reloadButton.heightAnchor.constraint(equalToConstant: 44),

            // Pulsante Switch Arma
            switchWeaponButton.bottomAnchor.constraint(equalTo: reloadButton.topAnchor, constant: -12),
            switchWeaponButton.trailingAnchor.constraint(equalTo: fireButton.leadingAnchor, constant: -16),
            switchWeaponButton.widthAnchor.constraint(equalToConstant: 120),
            switchWeaponButton.heightAnchor.constraint(equalToConstant: 44),

            // Pulsante Azione (Al centro dello schermo in basso)
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -35),
            actionButton.widthAnchor.constraint(equalToConstant: 180),
            actionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        joystickBase.frame = CGRect(x: safeAreaInsets.left + 35, y: bounds.height - 180 - safeAreaInsets.bottom, width: 130, height: 130)
        joystickCenter = CGPoint(x: 65, y: 65)
    }

    private func setupEndGameModal() {
        overlayModal.backgroundColor = UIColor(white: 0.05, alpha: 0.92)
        overlayModal.layer.cornerRadius = 16
        overlayModal.layer.borderColor = UIColor.white.cgColor
        overlayModal.layer.borderWidth = 2
        overlayModal.translatesAutoresizingMaskIntoConstraints = false
        overlayModal.isHidden = true
        addSubview(overlayModal)

        modalTitleLabel.textColor = .white
        modalTitleLabel.font = UIFont.systemFont(ofSize: 26, weight: .black)
        modalTitleLabel.textAlignment = .center
        modalTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayModal.addSubview(modalTitleLabel)

        modalDescLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        modalDescLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        modalDescLabel.textAlignment = .center
        modalDescLabel.numberOfLines = 0
        modalDescLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayModal.addSubview(modalDescLabel)

        restartButton.setTitle("GIOCA DI NUOVO", for: .normal)
        restartButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        restartButton.backgroundColor = UIColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1.0)
        restartButton.setTitleColor(.black, for: .normal)
        restartButton.layer.cornerRadius = 8
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        restartButton.addTarget(self, action: #selector(handleRestartTapped), for: .touchUpInside)
        overlayModal.addSubview(restartButton)

        NSLayoutConstraint.activate([
            overlayModal.centerXAnchor.constraint(equalTo: centerXAnchor),
            overlayModal.centerYAnchor.constraint(equalTo: centerYAnchor),
            overlayModal.widthAnchor.constraint(equalToConstant: 380),
            overlayModal.heightAnchor.constraint(equalToConstant: 220),

            modalTitleLabel.topAnchor.constraint(equalTo: overlayModal.topAnchor, constant: 24),
            modalTitleLabel.centerXAnchor.constraint(equalTo: overlayModal.centerXAnchor),

            modalDescLabel.topAnchor.constraint(equalTo: modalTitleLabel.bottomAnchor, constant: 14),
            modalDescLabel.leadingAnchor.constraint(equalTo: overlayModal.leadingAnchor, constant: 20),
            modalDescLabel.trailingAnchor.constraint(equalTo: overlayModal.trailingAnchor, constant: -20),

            restartButton.bottomAnchor.constraint(equalTo: overlayModal.bottomAnchor, constant: -24),
            restartButton.centerXAnchor.constraint(equalTo: overlayModal.centerXAnchor),
            restartButton.widthAnchor.constraint(equalToConstant: 180),
            restartButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // GESTIONE DEI TOUCH (Multi-Touch per joystick a sinistra e look a destra)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            // Metà sinistra per il joystick
            if loc.x < bounds.width * 0.45 && joystickTouch == nil {
                joystickTouch = touch
                isDraggingJoystick = true
                updateJoystick(location: touch.location(in: joystickBase))
            }
            // Metà destra (visuale libera)
            else if loc.x >= bounds.width * 0.45 && lookTouch == nil {
                lookTouch = touch
                lastLookPoint = loc
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
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

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == joystickTouch {
                resetJoystick()
            } else if touch == lookTouch {
                lookTouch = nil
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
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

        // normY invertito: su è forward (-dy)
        delegate?.hudDidMove(forward: Float(-normY), strafe: Float(normX))
    }

    private func resetJoystick() {
        joystickTouch = nil
        isDraggingJoystick = false
        joystickKnob.center = joystickCenter
        delegate?.hudDidMove(forward: 0, strafe: 0)
    }

    // AZIONI UTENTE
    @objc private func handleFireTapped() { delegate?.hudDidPressFire() }
    @objc private func handleReloadTapped() { delegate?.hudDidPressReload() }
    @objc private func handleSwitchWeaponTapped() { delegate?.hudDidPressSwitchWeapon() }
    @objc private func handleActionTapped() { delegate?.hudDidPressAction() }
    @objc private func handleRestartTapped() { delegate?.hudDidRestartGame() }

    // METODI DI AGGIORNAMENTO STATO
    func updateHealth(hp: Float) {
        let percent = max(0, min(1.0, hp / 100.0))
        healthLabel.text = "SALUTE: \(Int(hp))%"
        healthBarFill.backgroundColor = hp > 40 ? UIColor(red: 0.20, green: 0.80, blue: 0.30, alpha: 1.0) : UIColor(red: 0.85, green: 0.20, blue: 0.15, alpha: 1.0)
        UIView.animate(withDuration: 0.2) {
            self.healthBarFill.transform = CGAffineTransform(scaleX: CGFloat(percent), y: 1.0)
        }
    }

    func updateKeys(found: Int, total: Int) {
        keysLabel.text = "🗝️ CHIAVI: \(found) / \(total)"
    }

    func updateAmmo(text: String) {
        ammoLabel.text = text
    }

    func showSwitchWeapon(visible: Bool) {
        switchWeaponButton.isHidden = !visible
    }

    func setActionPrompt(title: String?) {
        if let title = title {
            actionButton.setTitle(title, for: .normal)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }
    }

    func showToast(message: String) {
        toastLabel.text = "  \(message)  "
        toastLabel.alpha = 1.0
        UIView.animate(withDuration: 0.5, delay: 2.5, options: .curveEaseInOut) {
            self.toastLabel.alpha = 0.0
        }
    }

    func showVictoryModal(kills: Int) {
        modalTitleLabel.text = "🏆 FUGA COMPLETATA!"
        modalTitleLabel.textColor = UIColor(red: 0.95, green: 0.80, blue: 0.20, alpha: 1.0)
        modalDescLabel.text = "Hai aperto i bauli, sbloccato il cancello ed eliminato \(kills) zombi. La contea è salva!"
        overlayModal.isHidden = false
    }

    func showGameOverModal(kills: Int) {
        modalTitleLabel.text = "💀 SEI MORTO"
        modalTitleLabel.textColor = UIColor(red: 0.90, green: 0.20, blue: 0.15, alpha: 1.0)
        modalDescLabel.text = "L'orda di non-morti ti ha sopraffatto nella foresta. Zombi eliminati: \(kills)."
        overlayModal.isHidden = false
    }

    func hideModal() {
        overlayModal.isHidden = true
    }
}
