import SwiftUI
import UIKit

// MARK: - Login

struct LoginView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var supabase: SupabaseService
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = "Clave incorrecta"
    @State private var shakeOffset: CGFloat = 0
    @State private var glowAnimation = false
    @State private var appeared = false
    @State private var rotationAngle: Double = 0
    @State private var isVerifying = false
    
    var body: some View {
        ZStack {
            JokerBackground()
            
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 24)
                        
                        topBadge
                        
                        // Deja ver la foto del Joker arriba
                        Spacer(minLength: 200)
                        
                        loginPanel
                        
                        Spacer().frame(height: 20)
                        
                        JokerSignature()
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.5), value: appeared)
                        
                        Spacer().frame(height: 24)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Top Badge
    
    private var topBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(JokerTheme.ok)
                .frame(width: 6, height: 6)
                .shadow(color: JokerTheme.ok.opacity(0.7), radius: 4)
            Text("SISTEMA ACTIVO")
                .font(.system(size: 10, weight: .heavy))
                .tracking(2)
                .foregroundStyle(JokerTheme.text.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(JokerTheme.cardBase.opacity(0.85)))
        .overlay(Capsule().strokeBorder(JokerTheme.cardStroke, lineWidth: 1))
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }
    
    // MARK: - Panel de login
    
    private var loginPanel: some View {
        VStack(spacing: 18) {
            panelHeader
            
            welcomeCard
            
            passwordField
            
            loginButton
            
            if showError {
                errorMessageView
            }
            
            statusIndicators
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .padding(.bottom, 20)
        .jokerCard(radius: 28)
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(.easeOut(duration: 0.6).delay(0.25), value: appeared)
    }
    
    // MARK: - Panel Header
    
    private var panelHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                JokerTheme.accent.opacity(glowAnimation ? 0.35 : 0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 14,
                            endRadius: 56
                        )
                    )
                    .frame(width: 112, height: 112)
                
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                JokerTheme.accent.opacity(0),
                                JokerTheme.accent.opacity(0.9),
                                JokerTheme.accent.opacity(0),
                                JokerTheme.bone.opacity(0.6),
                                JokerTheme.accent.opacity(0)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 8])
                    )
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(rotationAngle))
                
                JokerAppIcon(size: 66)
            }
            .frame(height: 108)
            
            Text("ANGEL EXTERNAL")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(JokerTheme.text)
        }
    }
    
    // MARK: - Welcome Card
    
    private var welcomeCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(JokerTheme.accent.opacity(0.15))
                    .overlay(Circle().strokeBorder(JokerTheme.accent.opacity(0.4), lineWidth: 1))
                    .frame(width: 40, height: 40)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(JokerTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Acceso restringido")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JokerTheme.text)
                Text("Introduce tu clave para continuar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(JokerTheme.textSoft)
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .jokerCard(radius: 16, fill: Color.white.opacity(0.04))
    }
    
    // MARK: - Password Field
    
    private var passwordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .foregroundStyle(JokerTheme.bone.opacity(0.8))
                .font(.system(size: 15))
            
            SecureField(
                "",
                text: $password,
                prompt: Text("Introduce tu clave...").foregroundStyle(JokerTheme.textFaint)
            )
            .textFieldStyle(.plain)
            .foregroundStyle(JokerTheme.text)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.go)
            .onSubmit(attemptLogin)
            .disabled(isVerifying)
            
            if !password.isEmpty && !isVerifying {
                Button {
                    password = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(JokerTheme.textFaint)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .jokerCard(
            radius: 16,
            stroke: showError ? JokerTheme.danger.opacity(0.7) : JokerTheme.cardStroke,
            fill: Color.white.opacity(0.08)
        )
        .offset(x: shakeOffset)
    }
    
    // MARK: - Login Button
    
    private var loginButton: some View {
        Button(action: attemptLogin) {
            HStack(spacing: 10) {
                if isVerifying {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.9)
                    Text("VERIFICANDO...")
                        .font(.system(size: 15, weight: .heavy))
                        .tracking(2)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                    Text("ENTRAR")
                        .font(.system(size: 15, weight: .heavy))
                        .tracking(2)
                }
            }
            .foregroundStyle(Color.black.opacity(0.88))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(JokerTheme.accentGradient)
                    .shadow(color: JokerTheme.accent.opacity(0.4), radius: 14, y: 6)
            )
        }
        .disabled(password.isEmpty || isVerifying)
        .opacity((password.isEmpty || isVerifying) ? 0.45 : 1.0)
        .scaleEffect(password.isEmpty ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: password.isEmpty)
    }
    
    // MARK: - Error Message
    
    private var errorMessageView: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text(errorMessage)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(JokerTheme.danger)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(JokerTheme.danger.opacity(0.12))
                .overlay(Capsule().stroke(JokerTheme.danger.opacity(0.35), lineWidth: 1))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Status Indicators
    
    private var statusIndicators: some View {
        HStack(spacing: 20) {
            statusDot(color: supabase.isConnected ? JokerTheme.ok : .gray, label: "Online")
            statusDot(color: JokerTheme.accent, label: "v2.0")
            statusDot(color: JokerTheme.bone.opacity(0.6), label: "Beta")
        }
    }
    
    private func statusDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.6), radius: 3)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(JokerTheme.textSoft)
        }
    }
    
    // MARK: - Login Logic (SIN CAMBIOS)
    
    private func attemptLogin() {
        guard !isVerifying else { return }
        guard !password.isEmpty else { return }
        
        isVerifying = true
        showError = false
        
        Task {
            do {
                let key = try await supabase.verifyKey(password)
                log("login: key verificada — \(key.label ?? "sin label")")
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                await MainActor.run {
                    isVerifying = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        session.isAuthenticated = true
                    }
                }
                
            } catch let error as SupabaseError {
                await MainActor.run {
                    isVerifying = false
                    handleLoginError(error)
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    errorMessage = "Error de conexión"
                    showError = true
                    shakePasswordField()
                }
            }
        }
    }
    
    // MARK: - Handle Login Error (SIN CAMBIOS)
    
    private func handleLoginError(_ error: SupabaseError) {
        // Vibración de error
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Mensaje específico según el error
        switch error {
        case .keyNotFound:
            errorMessage = "Clave no encontrada"
        case .keyBanned:
            errorMessage = "Esta clave fue baneada"
        case .keyExpired:
            errorMessage = "Esta clave expiró"
        case .keyInactive:
            errorMessage = "Esta clave está desactivada"
        case .deviceLimitReached:
            errorMessage = "Límite de dispositivos alcanzado"
        case .deviceBanned:
            errorMessage = "Este dispositivo fue baneado"
        case .networkError:
            errorMessage = "Error de conexión"
        case .invalidURL, .noData, .decodingFailed:
            errorMessage = "Error del servidor"
        }
        
        showError = true
        shakePasswordField()
    }
    
    // MARK: - Shake Animation (SIN CAMBIOS)
    
    private func shakePasswordField() {
        withAnimation(.default) { shakeOffset = -10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { shakeOffset = 10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { shakeOffset = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.default) { shakeOffset = 8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.default) { shakeOffset = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showError = false }
            password = ""
        }
    }
}