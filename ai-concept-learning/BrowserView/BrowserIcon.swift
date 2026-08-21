//
//  BrowserIcon.swift
//  ai-concept-learning
//
//  Small representation icon for a browser: an SF Symbol on a rounded, tinted
//  background derived from the browser's admin-configured color.
//

import SwiftUI

struct BrowserIcon: View {

    let systemName: String
    let colorHex: String

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(hex: colorHex) ?? .accentColor)
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}

extension Color {

    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            return nil
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}

#Preview {
    BrowserIcon(systemName: "flame.fill", colorHex: "#FF6611")
}
