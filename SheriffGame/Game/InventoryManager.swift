import Foundation
import UIKit

public enum WeaponRarity: String, CaseIterable {
    case common = "Comune"
    case rare = "Raro"
    case epic = "Epico"
    case legendary = "Leggendario"

    public var color: UIColor {
        switch self {
        case .common:
            return UIColor(white: 0.85, alpha: 1.0)
        case .rare:
            return UIColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0)
        case .epic:
            return UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 1.0)
        case .legendary:
            return UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0)
        }
    }

    public var damageMultiplier: Float {
        switch self {
        case .common: return 1.0
        case .rare: return 1.25
        case .epic: return 1.50
        case .legendary: return 2.00
        }
    }

    public var reloadSpeedMultiplier: Float {
        switch self {
        case .common: return 1.0
        case .rare: return 0.85
        case .epic: return 0.75
        case .legendary: return 0.60
        }
    }

    public var magazineBonus: Int {
        switch self {
        case .common: return 0
        case .rare: return 0
        case .epic: return 2
        case .legendary: return 4
        }
    }
}

public enum WeaponKind: String, CaseIterable {
    case revolver = "Colt .45"
    case shotgun = "Doppietta Cal. 12"
    case rifle = "Winchester 1873"
    case sniper = "Sharps Sniper"
    case dynamite = "Dinamite"

    public var baseDamage: Float {
        switch self {
        case .revolver: return 45.0
        case .shotgun: return 110.0
        case .rifle: return 75.0
        case .sniper: return 190.0
        case .dynamite: return 260.0
        }
    }

    public var baseMagCapacity: Int {
        switch self {
        case .revolver: return 6
        case .shotgun: return 2
        case .rifle: return 12
        case .sniper: return 1
        case .dynamite: return 1
        }
    }

    public var defaultReserveAmmo: Int {
        switch self {
        case .revolver: return 999
        case .shotgun: return 16
        case .rifle: return 36
        case .sniper: return 10
        case .dynamite: return 3
        }
    }

    public var fireCooldown: TimeInterval {
        switch self {
        case .revolver: return 0.32
        case .shotgun: return 0.70
        case .rifle: return 0.22
        case .sniper: return 1.10
        case .dynamite: return 1.40
        }
    }

    public var baseReloadTime: TimeInterval {
        switch self {
        case .revolver: return 1.2
        case .shotgun: return 1.6
        case .rifle: return 1.8
        case .sniper: return 1.4
        case .dynamite: return 0.5
        }
    }

    public var modelResourceName: String {
        switch self {
        case .revolver: return "fps_revolver"
        case .shotgun: return "fps_shotgun"
        case .rifle: return "fps_rifle"
        case .sniper: return "fps_sniper"
        case .dynamite: return "fps_dynamite"
        }
    }

    public var iconSymbol: String {
        switch self {
        case .revolver: return "🔫"
        case .shotgun: return "💥"
        case .rifle: return "⚡"
        case .sniper: return "🎯"
        case .dynamite: return "🧨"
        }
    }
}

public class WeaponItem {
    public let id = UUID()
    public let kind: WeaponKind
    public let rarity: WeaponRarity

    public var currentMag: Int
    public var maxMag: Int
    public var reserveAmmo: Int

    public var damage: Float {
        return kind.baseDamage * rarity.damageMultiplier
    }

    public var reloadDuration: TimeInterval {
        return kind.baseReloadTime * Double(rarity.reloadSpeedMultiplier)
    }

    public init(kind: WeaponKind, rarity: WeaponRarity) {
        self.kind = kind
        self.rarity = rarity
        self.maxMag = kind.baseMagCapacity + (kind == .dynamite || kind == .sniper ? 0 : rarity.magazineBonus)
        self.currentMag = self.maxMag
        self.reserveAmmo = kind.defaultReserveAmmo
    }

    public var displayName: String {
        return "\(kind.rawValue) [\(rarity.rawValue)]"
    }

    public var ammoDisplay: String {
        if kind == .revolver {
            return "\(currentMag) / ∞"
        } else if kind == .dynamite {
            return "\(reserveAmmo) pz."
        } else {
            return "\(currentMag) / \(reserveAmmo)"
        }
    }
}

public class InventoryManager {
    public private(set) var hotbar: [WeaponItem?] = [nil, nil, nil, nil]
    public private(set) var backpack: [WeaponItem] = []
    public private(set) var activeIndex: Int = 0

    public var onInventoryUpdated: (() -> Void)?

    public init() {
        // Arma iniziale: Colt .45 Peacemaker Comune
        let starter = WeaponItem(kind: .revolver, rarity: .common)
        hotbar[0] = starter
        activeIndex = 0
    }

    public var currentWeapon: WeaponItem? {
        guard activeIndex >= 0 && activeIndex < hotbar.count else { return nil }
        return hotbar[activeIndex]
    }

    public func selectSlot(index: Int) -> Bool {
        guard index >= 0 && index < hotbar.count else { return false }
        if hotbar[index] != nil {
            activeIndex = index
            onInventoryUpdated?()
            return true
        }
        return false
    }

    public func addWeapon(_ weapon: WeaponItem) -> (added: Bool, slotIndex: Int?) {
        // Cerca primo slot libero nell'hotbar
        for i in 0..<hotbar.count {
            if hotbar[i] == nil {
                hotbar[i] = weapon
                onInventoryUpdated?()
                return (true, i)
            }
        }
        // Se l'hotbar è piena, aggiunge al backpack o sostituisce l'attiva se peggiore
        if let current = currentWeapon, weapon.damage > current.damage {
            backpack.append(current)
            hotbar[activeIndex] = weapon
            onInventoryUpdated?()
            return (true, activeIndex)
        }
        backpack.append(weapon)
        onInventoryUpdated?()
        return (true, nil)
    }

    public func restockAmmo() {
        for item in hotbar.compactMap({ $0 }) {
            item.reserveAmmo += item.kind.defaultReserveAmmo
            item.currentMag = item.maxMag
        }
        onInventoryUpdated?()
    }
}
