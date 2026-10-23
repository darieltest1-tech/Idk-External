import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void
    
    // 🎯 Estados externos (vienen del RootView)
    let externalProgress: Double
    let externalStep: String
    
    // 🎯 Estados internos (animaciones)
    @State private var rotationAngle: Double = 0
    @State private var displayProgress: CGFloat = 0
    @State private var appeared = false
    @State private var glowPulse = false
    @State private var displayStep: String = "INICIANDO SISTEMA..."
    
    private let appName = "ANGEL EXTERNAL"
    
    init(
        externalProgress: Double = 0,
        externalStep: String = "INICIANDO SISTEMA...",
        onFinished: @escaping () -> Void
    ) {
        self.externalProgress = externalProgress
        self.externalStep = externalStep
        self.onFinished = onFinished
    }
    
    var body: some View {
        ZStack {
            JokerBackground()
            
            // Resplandor pulsante detrás del logo
            RadialGradient(
                colors: [
                    JokerTheme.accent.opacity(glowPulse ? 0.22 : 0.10),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.42),
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                logoSection
                
                Spacer().frame(height: 50)
                
                Text(appName)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(JokerTheme.text)
                    .shadow(color: JokerTheme.accent.opacity(0.35), radius: 10)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
                
                Spacer().frame(height: 6)
                
                Text("PATCH LIBRARY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(JokerTheme.textSoft)
                    .opacity(appeared ? 1 : 0)
                
                Spacer().frame(height: 26)
                
                // 🎯 Texto dinámico (paso actual)
                Text(displayStep)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(JokerTheme.accent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .frame(height: 20)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: displayStep)
                    .opacity(appeared ? 1 : 0)
                
                Spacer().frame(height: 14)
                
                // 🎯 Barra de progreso real
                progressBar
                    .padding(.horizontal, 80)
                    .opacity(appeared ? 1 : 0)
                
                Spacer().frame(height: 8)
                
                // 🎯 Porcentaje
                Text("\(Int(displayProgress * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(JokerTheme.textSoft)
                    .opacity(appeared ? 1 : 0)
                
                Spacer()
                Spacer()
                
                JokerSignature()
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: externalProgress) { newValue in
            withAnimation(.easeInOut(duration: 0.4)) {
                displayProgress = CGFloat(min(max(newValue, 0), 1))
            }
        }
        .onChange(of: externalStep) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                displayStep = newValue
            }
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        ZStack {
            // Halo pulsante
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            JokerTheme.accent.opacity(glowPulse ? 0.30 : 0.14),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    )
                )
                .frame(width: 260, height: 260)
            
            // Anillo de puntos girando
            ForEach(0..<28, id: \.self) { i in
                let angle = (Double(i) / 28.0) * 360.0
                let isHighlighted = i % 7 == 0
                
                Circle()
                    .fill(
                        isHighlighted
                            ? JokerTheme.accent
                            : JokerTheme.bone.opacity(0.30)
                    )
                    .frame(
                        width: isHighlighted ? 4 : 2.5,
                        height: isHighlighted ? 4 : 2.5
                    )
                    .shadow(
                        color: isHighlighted ? JokerTheme.accent.opacity(0.7) : .clear,
                        radius: isHighlighted ? 4 : 0
                    )
                    .offset(y: -95)
                    .rotationEffect(.degrees(angle + rotationAngle))
            }
            
            // Anillo conector
            Circle()
                .stroke(JokerTheme.bone.opacity(0.18), lineWidth: 0.5)
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(rotationAngle * 0.5))
            
            // Círculo decorativo
            Circle()
                .stroke(JokerTheme.bone.opacity(0.18), lineWidth: 0.5)
                .frame(width: 148, height: 148)
            
            // Icono con la foto del Joker
            JokerAppIcon(size: 104)
        }
        .frame(height: 260)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .animation(.easeOut(duration: 0.6), value: appeared)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.10))
                .frame(height: 4)
            
            Capsule()
                .fill(JokerTheme.accentGradient)
                .frame(width: displayProgress * 220, height: 4)
                .shadow(color: JokerTheme.accent.opacity(0.6), radius: 6)
        }
        .frame(width: 220)
    }
    
    // MARK: - Animaciones (SIN CAMBIOS)
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.4)) {
            appeared = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
        
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}