import SwiftUI

// MARK: - Selección de modo

struct ModeSelectionView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var supabase: SupabaseService
    @State private var appeared = false
    @State private var showAdvancedSettings = false
    
    private let subtitle = "Selecciona tu versión del juego"
    
    // MARK: - Key Helpers (SIN CAMBIOS en la lógica)
    
    private var keyDisplayName: String {
        supabase.currentKey?.keyValue ?? "SIN KEY"
    }
    
    private var daysRemainingText: String {
        guard let key = supabase.currentKey else { return "—" }
        
        if key.isBanned {
            return "Baneada"
        }
        
        guard let expiresAt = key.expiresAt,
              let date = parseSupabaseDate(expiresAt) else {
            return "Sin expiración"
        }
        
        let now = Date()
        let diff = date.timeIntervalSince(now)
        
        if diff <= 0 {
            return "Expirada"
        }
        
        let totalMinutes = Int(diff / 60)
        let totalHours = totalMinutes / 60
        let days = totalHours / 24
        let minutes = totalMinutes % 60
        
        if days > 1 {
            return "\(days) días"
        }
        if days == 1 {
            return "1 día"
        }
        if totalHours >= 1 {
            return "\(totalHours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func parseSupabaseDate(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) { return date }
        
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: string) { return date }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = df.date(from: string) { return date }
        
        df.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        if let date = df.date(from: string) { return date }
        
        let fixed = string.replacingOccurrences(of: " ", with: "T")
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: fixed) { return date }
        
        return nil
    }
    
    private var keyStatusColor: Color {
        guard let key = supabase.currentKey else { return JokerTheme.textSoft }
        
        if key.isBanned {
            return JokerTheme.danger
        }
        
        if let expiresAt = key.expiresAt,
           let date = parseSupabaseDate(expiresAt) {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            if days < 0 {
                return JokerTheme.danger
            }
            if days <= 3 {
                return JokerTheme.warning
            }
        }
        
        return JokerTheme.ok
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            JokerBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 16)
                    
                    header
                    
                    // Espacio para dejar ver la foto del Joker
                    Spacer().frame(height: 150)
                    
                    subtitlePill
                    
                    Spacer().frame(height: 18)
                    
                    VStack(spacing: 14) {
                        modeCard(
                            mode: .normal,
                            title: "FREE FIRE TH",
                            subtitle: "Abrir panel de control",
                            gameImageName: "FFNormalLogo",
                            delay: 0.1
                        )
                        
                        modeCard(
                            mode: .max,
                            title: "FREE FIRE MAX",
                            subtitle: "Abrir panel de control",
                            gameImageName: "FFMaxLogo",
                            delay: 0.2
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 16)
                    
                    profileCard
                        .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 20)
                    
                    advancedSettingsButton
                    
                    Spacer().frame(height: 28)
                    
                    JokerSignature()
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
                    
                    Spacer().frame(height: 30)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Header (icono + nombre)
    
    private var header: some View {
        HStack(spacing: 14) {
            JokerAppIcon(size: 56)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("ANGEL EXTERNAL")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(JokerTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("PATCH LIBRARY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(JokerTheme.textSoft)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Circle()
                    .fill(JokerTheme.ok)
                    .frame(width: 8, height: 8)
                    .shadow(color: JokerTheme.ok.opacity(0.7), radius: 4)
                Text("LISTO")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(JokerTheme.ok)
            }
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.05), value: appeared)
    }
    
    // MARK: - Subtítulo
    
    private var subtitlePill: some View {
        Text(subtitle)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(JokerTheme.text.opacity(0.85))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(JokerTheme.cardBase.opacity(0.85)))
            .overlay(Capsule().strokeBorder(JokerTheme.cardStroke, lineWidth: 1))
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }
    
    // MARK: - Mode Card
    
    @ViewBuilder
    private func modeCard(
        mode: FFMode,
        title: String,
        subtitle: String,
        gameImageName: String,
        delay: Double
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                session.selectedMode = mode
            }
        } label: {
            HStack(spacing: 14) {
                gameIcon(name: gameImageName, mode: mode)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(JokerTheme.text)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(JokerTheme.textSoft)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(JokerTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(JokerTheme.accent.opacity(0.14)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .jokerCard(radius: 20)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
    }
    
    @ViewBuilder
    private func gameIcon(name: String, mode: FFMode) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: mode == .normal
                            ? [JokerTheme.warning.opacity(0.30), JokerTheme.warning.opacity(0.10)]
                            : [JokerTheme.accent.opacity(0.30), JokerTheme.accentDeep.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
            
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Image(systemName: mode == .normal ? "flame.fill" : "bolt.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(mode == .normal ? JokerTheme.warning : JokerTheme.accent)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Profile Card
    
    private var profileCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .overlay(Circle().strokeBorder(JokerTheme.cardStroke, lineWidth: 1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(JokerTheme.bone)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(keyDisplayName)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(JokerTheme.text)
                    .lineLimit(1)
                
                Text(supabase.currentKey?.label ?? "Usuario")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(JokerTheme.textSoft)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(daysRemainingText)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(keyStatusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(keyStatusColor.opacity(0.14)))
                .overlay(Capsule().stroke(keyStatusColor.opacity(0.45), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .jokerCard(radius: 20, stroke: keyStatusColor.opacity(0.30))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
    }
    
    // MARK: - Advanced Settings Button
    
    private var advancedSettingsButton: some View {
        Button {
            showAdvancedSettings = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Ajustes avanzados")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(JokerTheme.text.opacity(0.85))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().strokeBorder(JokerTheme.cardStroke, lineWidth: 1))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
        .sheet(isPresented: $showAdvancedSettings) {
            SettingsView()
        }
    }
}

// MARK: - Scale Button Style (SIN CAMBIOS)

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}