import Foundation

enum WeaponKind {
    case blade
    case bow
    case axe
    case polearm
    case dagger
    case blunt
    case staff
    case crossbow
    case chain
    case scythe
    case whip
    case handgun
    case longGun
    case shotgun
    case heavy
    case grenade
    case rocket
    case energy
    case flame
    case boomerang
}

struct CursorWeapon {
    let name: String
    let kind: WeaponKind
}

enum WeaponCatalog {
    static let all: [CursorWeapon] = [
        CursorWeapon(name: "sword", kind: .blade),
        CursorWeapon(name: "bow", kind: .bow),
        CursorWeapon(name: "axe", kind: .axe),
        CursorWeapon(name: "spear", kind: .polearm),
        CursorWeapon(name: "dagger", kind: .dagger),
        CursorWeapon(name: "mace", kind: .blunt),
        CursorWeapon(name: "staff", kind: .staff),
        CursorWeapon(name: "crossbow", kind: .crossbow),
        CursorWeapon(name: "flail", kind: .chain),
        CursorWeapon(name: "halberd", kind: .polearm),
        CursorWeapon(name: "scythe", kind: .scythe),
        CursorWeapon(name: "whip", kind: .whip),
        CursorWeapon(name: "club", kind: .blunt),
        CursorWeapon(name: "katana", kind: .blade),
        CursorWeapon(name: "handgun", kind: .handgun),
        CursorWeapon(name: "musket", kind: .longGun),
        CursorWeapon(name: "blunderbuss", kind: .shotgun),
        CursorWeapon(name: "pistol", kind: .handgun),
        CursorWeapon(name: "revolver", kind: .handgun),
        CursorWeapon(name: "rifle", kind: .longGun),
        CursorWeapon(name: "shotgun", kind: .shotgun),
        CursorWeapon(name: "cannon", kind: .heavy),
        CursorWeapon(name: "grenade", kind: .grenade),
        CursorWeapon(name: "rocket launcher", kind: .rocket),
        CursorWeapon(name: "laser gun", kind: .energy),
        CursorWeapon(name: "plasma rifle", kind: .energy),
        CursorWeapon(name: "railgun", kind: .energy),
        CursorWeapon(name: "flamethrower", kind: .flame),
        CursorWeapon(name: "minigun", kind: .heavy),
        CursorWeapon(name: "sniper rifle", kind: .longGun),
        CursorWeapon(name: "submachine gun", kind: .longGun),
        CursorWeapon(name: "assault rifle", kind: .longGun),
        CursorWeapon(name: "machine gun", kind: .heavy),
        CursorWeapon(name: "bazooka", kind: .rocket),
        CursorWeapon(name: "tomahawk", kind: .axe),
        CursorWeapon(name: "boomerang", kind: .boomerang),
        CursorWeapon(name: "ak-47", kind: .longGun),
        CursorWeapon(name: "uzi", kind: .handgun),
        CursorWeapon(name: "mp5", kind: .longGun),
        CursorWeapon(name: "glock", kind: .handgun),
        CursorWeapon(name: "desert eagle", kind: .handgun),
        CursorWeapon(name: "colt 1911", kind: .handgun),
        CursorWeapon(name: "m16", kind: .longGun),
        CursorWeapon(name: "m4 carbine", kind: .longGun),
        CursorWeapon(name: "scar-l", kind: .longGun),
        CursorWeapon(name: "famas", kind: .longGun),
        CursorWeapon(name: "galil", kind: .longGun),
        CursorWeapon(name: "aug", kind: .longGun),
        CursorWeapon(name: "sig sauer p226", kind: .handgun),
        CursorWeapon(name: "beretta 92fs", kind: .handgun),
        CursorWeapon(name: "hk usp", kind: .handgun),
        CursorWeapon(name: "fn p90", kind: .longGun),
        CursorWeapon(name: "steyr aug a3", kind: .longGun),
        CursorWeapon(name: "heckler & koch g36c", kind: .longGun),
        CursorWeapon(name: "fn fal", kind: .longGun),
        CursorWeapon(name: "l85a2", kind: .longGun),
        CursorWeapon(name: "ar-15", kind: .longGun),
        CursorWeapon(name: "ar-10", kind: .longGun),
        CursorWeapon(name: "ar-18", kind: .longGun),
        CursorWeapon(name: "ar-70/90", kind: .longGun)
    ]
}
