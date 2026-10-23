import SwiftUI
import UIKit

// MARK: - Tema Joker (negro / hueso / ámbar brasa)
// Archivo compartido: colores, fondo, tarjetas, icono y firma.
// Agrégalo al proyecto una sola vez; lo usan Login, ModeSelection y ControlPanel.

enum JokerTheme {
    /// Foto del Joker para el icono junto al título (Assets.xcassets).
    /// Si no existe, se muestra la máscara de teatro como respaldo.
    static let iconImageName = "JokerIcon"

    static let bg = Color(red: 0.035, green: 0.035, blue: 0.045)
    static let bone = Color(red: 0.94, green: 0.90, blue: 0.80)

    static let text = Color.white
    static let textSoft = Color(red: 0.94, green: 0.90, blue: 0.80).opacity(0.60)
    static let textFaint = Color(red: 0.94, green: 0.90, blue: 0.80).opacity(0.38)

    /// Acento: ámbar de la brasa del puro
    static let accent = Color(red: 0.97, green: 0.69, blue: 0.24)
    static let accentDeep = Color(red: 0.78, green: 0.36, blue: 0.10)

    static let ok = Color(red: 0.30, green: 0.80, blue: 0.45)
    static let warning = Color(red: 0.95, green: 0.45, blue: 0.18)
    static let danger = Color(red: 0.92, green: 0.30, blue: 0.30)

    static let cardBase = Color(red: 0.09, green: 0.085, blue: 0.095)
    static let cardStroke = Color.white.opacity(0.09)

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Fondo

struct JokerBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.065, blue: 0.07), JokerTheme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [JokerTheme.accent.opacity(0.14), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea()

            // Velo inferior para que el contenido siempre se lea
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: JokerTheme.bg.opacity(0.55), location: 0.5),
                    .init(color: JokerTheme.bg.opacity(0.92), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Tarjeta

struct JokerCard: ViewModifier {
    var radius: CGFloat = 22
    var stroke: Color = JokerTheme.cardStroke
    var fill: Color = Color.white.opacity(0.06)

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(JokerTheme.cardBase.opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [fill, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1)
            )
    }
}

extension View {
    func jokerCard(radius: CGFloat = 22,
                   stroke: Color = JokerTheme.cardStroke,
                   fill: Color = Color.white.opacity(0.06)) -> some View {
        modifier(JokerCard(radius: radius, stroke: stroke, fill: fill))
    }
}

// MARK: - Icono de la app (reemplaza al icono de Apple Music)

struct JokerAppIcon: View {
    var size: CGFloat = 56
    var symbol: String = "theatermasks.fill"
    /// true = muestra la foto del Joker (asset "JokerIcon"); false = usa el símbolo
    var photo: Bool = true

    private var hasPhoto: Bool {
        photo && UIImage(named: JokerTheme.iconImageName) != nil
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.19, green: 0.18, blue: 0.19), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if hasPhoto {
                Image(JokerTheme.iconImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.46, weight: .bold))
                    .foregroundStyle(JokerTheme.bone)
            }

            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .strokeBorder(JokerTheme.accentGradient, lineWidth: max(1.5, size * 0.03))
        }
        .frame(width: size, height: size)
        .shadow(color: JokerTheme.accent.opacity(0.35), radius: size * 0.22, y: size * 0.06)
    }
}

// MARK: - Firma (al final de cada pantalla)

struct JokerSignature: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Hecho por")
                .foregroundStyle(JokerTheme.textSoft)

            Link(destination: URL(string: "https://t.me/didierxit7")!) {
                Text("@didierxit7")
                    .foregroundStyle(JokerTheme.accent)
                    .underline()
            }

            Text("y")
                .foregroundStyle(JokerTheme.textSoft)

            Link(destination: URL(string: "https://t.me/Angel333_57")!) {
                Text("@angelx7")
                    .foregroundStyle(JokerTheme.accent)
                    .underline()
            }
        }
        .font(.system(size: 12, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}