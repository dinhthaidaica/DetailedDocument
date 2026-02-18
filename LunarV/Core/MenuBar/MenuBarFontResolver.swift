//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit

enum MenuBarFontResolver {
    static func resolve(
        family: String,
        size: CGFloat,
        bold: Bool,
        italic: Bool
    ) -> NSFont {
        let traits: NSFontTraitMask = italic ? .italicFontMask : []
        let weight = bold ? 9 : 5

        if !family.isEmpty,
           let custom = NSFontManager.shared.font(
               withFamily: family,
               traits: traits,
               weight: weight,
               size: size
           ) {
            return custom
        }

        let base = NSFont.menuBarFont(ofSize: size)
        let descriptorTraits = symbolicTraits(for: base.fontDescriptor.symbolicTraits, bold: bold, italic: italic)
        let descriptor = base.fontDescriptor.withSymbolicTraits(descriptorTraits)
        if let resolved = NSFont(descriptor: descriptor, size: size) {
            return resolved
        }
        return base
    }

    private static func symbolicTraits(
        for current: NSFontDescriptor.SymbolicTraits,
        bold: Bool,
        italic: Bool
    ) -> NSFontDescriptor.SymbolicTraits {
        var traits = current
        if bold { traits.insert(.bold) } else { traits.remove(.bold) }
        if italic { traits.insert(.italic) } else { traits.remove(.italic) }
        return traits
    }
}
