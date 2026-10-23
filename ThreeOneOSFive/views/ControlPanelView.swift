import SwiftUI
import UIKit

// MARK: - Modelo de toggle

struct PatchToggle: Identifiable {
    let id: String
    let displayName: String
    let patchFilename: String
    let icon: String
    let category: PatchCategory
    
    var isDynamic: Bool = false
    var isBlocked: Bool = false
    var blockMessage: String? = nil
    var downloadURL: String? = nil
    var remoteID: String? = nil
    
    var fullFilename: String { "\(patchFilename).3105" }
    var normalizedName: String { Self.normalize(patchFilename) }
    
    static func normalize(_ name: String) -> String {
        var result = name
        if result.lowercased().hasSuffix(".3105") {
            result = String(result.dropLast(5))
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: " -_"))
        result = result.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return result.uppercased()
    }
}

enum PatchCategory: String, CaseIterable, Identifiable {
    case aimbot = "Aimbot"
    case hologramas = "Hologramas"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .aimbot: return "scope"
        case .hologramas: return "cube.transparent"
        }
    }
    
    /// Nombre de la pestaña
    var tabName: String {
        switch self {
        case .aimbot: return "Patches"
        case .hologramas: return "Visuals"
        }
    }
    
    var tabIcon: String {
        switch self {
        case .aimbot: return "slider.horizontal.3"
        case .hologramas: return "sparkles"
        }
    }
    
    var sectionSubtitle: String {
        switch self {
        case .aimbot: return "Controles de aim"
        case .hologramas: return "Hologramas de arma"
        }
    }
    
    var itemLabel: String {
        switch self {
        case .aimbot: return "Aim"
        case .hologramas: return "Holo arma"
        }
    }
}

// MARK: - Registro de parches por modo (hardcodeados)

enum PatchRegistry {
    static func toggles(for mode: FFMode) -> [PatchToggle] {
        return []
    }
}

// MARK: - Panel principal

struct ControlPanelView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var supabase: SupabaseService
    @EnvironmentObject private var patchesStore: PatchesStore
    @EnvironmentObject private var announcementsStore: AnnouncementsStore
    @State private var selectedCategory: PatchCategory = .aimbot
    @State private var activeToggles: Set<String> = []
    @State private var processingToggles: Set<String> = []
    @State private var toast: ToastMessage? = nil
    @State private var showSettings = false
    @State private var alert: PatchStoreAlert? = nil
    @State private var showLogoutConfirmation = false
    @State private var appeared = false
    
    private var mode: FFMode { session.selectedMode ?? .normal }
    
    private var allToggles: [PatchToggle] {
        let hardcoded = PatchRegistry.toggles(for: mode)
        let dynamic = buildDynamicToggles(for: mode)
        return hardcoded + dynamic
    }
    
    private var toggles: [PatchToggle] {
        allToggles.filter { $0.category == selectedCategory }
    }
    
    private func buildDynamicToggles(for mode: FFMode) -> [PatchToggle] {
        let modeString = (mode == .normal) ? "normal" : "max"
        
        return patchesStore.remotePatches.compactMap { remote in
            guard remote.mode == modeString || remote.mode == "both" else {
                return nil
            }
            
            let category: PatchCategory
            switch remote.category.lowercased() {
            case "aimbot":
                category = .aimbot
            case "hologramas", "hologram":
                category = .hologramas
            default:
                category = .aimbot
            }
            
            return PatchToggle(
                id: remote.patchKey,
                displayName: remote.displayName,
                patchFilename: remote.patchFilename,
                icon: remote.icon,
                category: category,
                isDynamic: true,
                isBlocked: remote.isBlocked,
                blockMessage: remote.blockMessage,
                downloadURL: remote.downloadUrl,
                remoteID: remote.id
            )
        }
    }
    
    var body: some View {
        ZStack {
            JokerBackground()
            
            VStack(spacing: 0) {
                topBar
                    .padding(.top, 8)
                
                if !announcementsStore.visibleBanners.isEmpty {
                    AnnouncementBannersContainer(
                        announcements: announcementsStore.visibleBanners,
                        onDismiss: { id in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                announcementsStore.dismiss(id)
                            }
                        }
                    )
                    .padding(.top, 8)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        heroCard
                        patchesCard
                        accessCard
                        
                        JokerSignature()
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            
            if let toast {
                VStack {
                    Spacer()
                    ToastView(message: toast)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.titleKey),
                message: Text(alert.messageKey),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Cerrar sesión",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cerrar sesión", role: .destructive) {
                performLogout()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Si cierras sesión deberás ingresar tu key de nuevo.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            syncToggleStates()
            Task {
                await loadDynamicPatchesIfNeeded()
            }
        }
    }
    
    // MARK: - Top bar
    
    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    session.selectedMode = nil
                    activeToggles.removeAll()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JokerTheme.text)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().strokeBorder(JokerTheme.cardStroke, lineWidth: 1))
            }
            
            JokerAppIcon(size: 46)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ANGEL EXTERNAL")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(JokerTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("PATCH LIBRARY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(JokerTheme.textSoft)
            }
            
            Spacer(minLength: 4)
            
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
    }
    
    // MARK: - Hero card
    
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Panel")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(JokerTheme.text)
            
            HStack(spacing: 16) {
                JokerAppIcon(size: 84, symbol: "slider.horizontal.3", photo: false)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tu biblioteca de parches")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(JokerTheme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(allToggles.count) módulos listos")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JokerTheme.textSoft)
                    Text(accessTitle)
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(keyStatusColor)
                }
                
                Spacer(minLength: 0)
            }
            
            statusChips
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .jokerCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.05), value: appeared)
    }
    
    private var statusChips: some View {
        HStack(spacing: 8) {
            chipView(icon: "gamecontroller.fill", text: mode.displayName, iconColor: JokerTheme.accent)
            chipView(icon: "applelogo", text: "iOS \(UIDevice.current.systemVersion)", iconColor: JokerTheme.textSoft)
            chipView(icon: "iphone", text: deviceModelIdentifier, iconColor: JokerTheme.textSoft)
            Spacer(minLength: 0)
        }
    }
    
    private func chipView(icon: String, text: String, iconColor: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(JokerTheme.text.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.07)))
        .overlay(Capsule().strokeBorder(JokerTheme.cardStroke, lineWidth: 1))
    }
    
    /// Identificador del modelo real (ej: iPhone12,1)
    private var deviceModelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    // MARK: - Patches card (tabs + lista)
    
    private var patchesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedCategory.tabName)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(JokerTheme.text)
                    Text(selectedCategory.sectionSubtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JokerTheme.textSoft)
                }
                Spacer()
                Text("\(activeToggles.count)/\(allToggles.count) ACTIVOS")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.5)
                    .foregroundStyle(JokerTheme.accent)
                    .padding(.top, 6)
            }
            
            categoryTabs
            
            patchesList
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .jokerCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
    }
    
    private var categoryTabs: some View {
        HStack(spacing: 10) {
            ForEach(PatchCategory.allCases) { category in
                let selected = selectedCategory == category
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: category.tabIcon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(category.tabName)
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(selected ? Color.black.opacity(0.88) : JokerTheme.textSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                selected
                                    ? AnyShapeStyle(JokerTheme.accentGradient)
                                    : AnyShapeStyle(Color.white.opacity(0.07))
                            )
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            selected ? Color.clear : JokerTheme.cardStroke,
                            lineWidth: 1
                        )
                    )
                }
            }
        }
    }
    
    private var patchesList: some View {
        VStack(spacing: 6) {
            if toggles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(JokerTheme.textFaint)
                    Text("No hay parches disponibles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(JokerTheme.textSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(toggles) { toggle in
                    ToggleRow(
                        toggle: toggle,
                        isOn: activeToggles.contains(toggle.id),
                        isProcessing: processingToggles.contains(toggle.id),
                        onToggle: { newValue in
                            handleToggle(toggle, isOn: newValue)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Access card
    
    private var accessTitle: String {
        guard let key = supabase.currentKey else { return "SIN ACCESO" }
        if key.isBanned { return "CLAVE BANEADA" }
        if daysRemainingText == "Expirada" { return "CLAVE EXPIRADA" }
        return "ACCESO ACTIVO"
    }
    
    private var accessIcon: String {
        accessTitle == "ACCESO ACTIVO" ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
    }
    
    private var accessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: accessIcon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(keyStatusColor)
                Text(accessTitle)
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(0.5)
                    .foregroundStyle(keyStatusColor)
                Spacer()
                Text(daysRemainingText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(keyStatusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(keyStatusColor.opacity(0.14)))
                    .overlay(Capsule().strokeBorder(keyStatusColor.opacity(0.45), lineWidth: 1))
            }
            
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(JokerTheme.bone)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(supabase.currentKey?.keyValue ?? "SIN KEY")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(JokerTheme.text)
                        .lineLimit(1)
                    Text(supabase.currentKey?.label ?? "Usuario")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(JokerTheme.textSoft)
                        .lineLimit(1)
                }
                Spacer()
            }
            
            HStack(spacing: 10) {
                Button {
                    withAnimation {
                        session.selectedMode = nil
                        activeToggles.removeAll()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Cambiar versión")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(JokerTheme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                    .overlay(Capsule().strokeBorder(JokerTheme.cardStroke, lineWidth: 1))
                }
                
                Button {
                    showLogoutConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Cerrar sesión")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(JokerTheme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(JokerTheme.danger.opacity(0.10)))
                    .overlay(Capsule().strokeBorder(JokerTheme.danger.opacity(0.4), lineWidth: 1))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .jokerCard(stroke: keyStatusColor.opacity(0.35))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
    }
    
    // MARK: - Cargar parches dinámicos
    
    private func loadDynamicPatchesIfNeeded() async {
        if !patchesStore.remotePatches.isEmpty { return }
        
        do {
            let patches = try await patchesStore.fetchPatches()
            log("panel: \(patches.count) parches dinámicos cargados")
            await patchesStore.downloadAllPatches(patches)
        } catch {
            log("panel: error cargando parches dinámicos: \(error)")
        }
    }
    
    // MARK: - Key Helpers
    
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
    
    // MARK: - Lógica de toggle (SIN CAMBIOS)
    
    private func handleToggle(_ toggle: PatchToggle, isOn: Bool) {
        guard !processingToggles.contains(toggle.id) else { return }
        
        if toggle.isBlocked && isOn {
            showBlockAlert(toggle)
            return
        }
        
        if isOn {
            let conflictingToggles = toggles.filter {
                $0.category == toggle.category && activeToggles.contains($0.id)
            }
            
            if !conflictingToggles.isEmpty {
                for conflict in conflictingToggles {
                    deactivatePatchSilently(conflict)
                }
            }
            
            activatePatch(toggle)
        } else {
            deactivatePatch(toggle)
        }
    }
    
    private func showBlockAlert(_ toggle: PatchToggle) {
        alert = PatchStoreAlert(
            titleKey: "Opción en mantenimiento",
            messageKey: toggle.blockMessage ?? "Esta opción no está disponible en este momento."
        )
    }
    
    private func activatePatch(_ toggle: PatchToggle) {
        processingToggles.insert(toggle.id)
        
        Task.detached(priority: .userInitiated) {
            do {
                guard let item = await findLibraryItem(for: toggle) else {
                    await MainActor.run {
                        processingToggles.remove(toggle.id)
                        showToast(
                            "Parche no encontrado: \(toggle.fullFilename)",
                            icon: "exclamationmark.triangle.fill",
                            color: JokerTheme.danger
                        )
                    }
                    return
                }
                
                let project: PatchProject
                if item.summary.schemaVersion >= 2 && item.canInspectContents {
                    project = try PatchProjectLibrary.synchronizeWorkspace(item: item)
                } else {
                    guard let p = item.project else {
                        throw PatchPackageError.invalidProject
                    }
                    project = p
                }
                
                _ = try DevicePatchService.apply(project: project)
                
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    activeToggles.insert(toggle.id)
                    patchStore.reload()
                    showToast(
                        "Parche activado con éxito",
                        icon: "checkmark.circle.fill",
                        color: JokerTheme.ok
                    )
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error: \(error.localizationKey)",
                        icon: "exclamationmark.triangle.fill",
                        color: JokerTheme.danger
                    )
                }
            } catch {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error al activar el parche",
                        icon: "exclamationmark.triangle.fill",
                        color: JokerTheme.danger
                    )
                }
            }
        }
    }
    
    private func deactivatePatch(_ toggle: PatchToggle) {
        processingToggles.insert(toggle.id)
        
        Task.detached(priority: .userInitiated) {
            do {
                guard let item = await findLibraryItem(for: toggle) else {
                    await MainActor.run {
                        processingToggles.remove(toggle.id)
                        activeToggles.remove(toggle.id)
                        showToast(
                            "Parche desactivado",
                            icon: "xmark.circle.fill",
                            color: JokerTheme.textSoft
                        )
                    }
                    return
                }
                
                guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else {
                    await MainActor.run {
                        processingToggles.remove(toggle.id)
                        activeToggles.remove(toggle.id)
                        showToast(
                            "Parche desactivado",
                            icon: "xmark.circle.fill",
                            color: JokerTheme.textSoft
                        )
                    }
                    return
                }
                
                try DevicePatchService.restore(receipt: receipt)
                
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    activeToggles.remove(toggle.id)
                    patchStore.reload()
                    showToast(
                        "Parche desactivado",
                        icon: "xmark.circle.fill",
                        color: JokerTheme.textSoft
                    )
                }
            } catch {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error al desactivar",
                        icon: "exclamationmark.triangle.fill",
                        color: JokerTheme.danger
                    )
                }
            }
        }
    }
    
    private func deactivatePatchSilently(_ toggle: PatchToggle) {
        Task.detached(priority: .userInitiated) {
            guard let item = await findLibraryItem(for: toggle) else { return }
            guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else { return }
            try? DevicePatchService.restore(receipt: receipt)
            await MainActor.run {
                activeToggles.remove(toggle.id)
                patchStore.reload()
            }
        }
    }
    
    private func findLibraryItem(for toggle: PatchToggle) async -> PatchLibraryItem? {
        let targetNormalized = toggle.normalizedName
        return await MainActor.run {
            patchStore.items.first { item in
                let fileNormalized = PatchToggle.normalize(item.packageURL.lastPathComponent)
                return fileNormalized == targetNormalized
            }
        }
    }
    
    private func syncToggleStates() {
        var active: Set<String> = []
        for toggle in allToggles {
            let targetNormalized = toggle.normalizedName
            if let item = patchStore.items.first(where: {
                PatchToggle.normalize($0.packageURL.lastPathComponent) == targetNormalized
            }), DevicePatchService.latestReceipt(projectID: item.id) != nil {
                active.insert(toggle.id)
            }
        }
        activeToggles = active
    }
    
    private func showToast(_ message: String, icon: String, color: Color) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            toast = ToastMessage(message: message, icon: icon, color: color)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                toast = nil
            }
        }
    }
    
    // MARK: - Logout
    
    private func performLogout() {
        supabase.disconnect()
        activeToggles.removeAll()
        processingToggles.removeAll()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            session.selectedMode = nil
            session.isAuthenticated = false
        }
    }
}

// MARK: - Fila (un toque activa / desactiva)

private struct ToggleRow: View {
    let toggle: PatchToggle
    let isOn: Bool
    let isProcessing: Bool
    let onToggle: (Bool) -> Void
    
    private var tileColors: [Color] {
        if toggle.isBlocked {
            return [JokerTheme.warning.opacity(0.25), JokerTheme.warning.opacity(0.10)]
        }
        if isOn {
            return [JokerTheme.accent.opacity(0.32), JokerTheme.accentDeep.opacity(0.14)]
        }
        return [Color.white.opacity(0.09), Color.white.opacity(0.04)]
    }
    
    private var iconColor: Color {
        if toggle.isBlocked { return JokerTheme.warning }
        return isOn ? JokerTheme.accent : JokerTheme.bone.opacity(0.8)
    }
    
    var body: some View {
        Button {
            onToggle(!isOn)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: tileColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    if isProcessing {
                        ProgressView()
                            .tint(JokerTheme.accent)
                            .scaleEffect(0.8)
                    } else if toggle.isBlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(JokerTheme.warning)
                    } else {
                        Image(systemName: toggle.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(toggle.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(toggle.isBlocked ? JokerTheme.textFaint : JokerTheme.text)
                        .lineLimit(1)
                    Text(toggle.isBlocked ? "En mantenimiento" : toggle.category.itemLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(toggle.isBlocked ? JokerTheme.warning : JokerTheme.textSoft)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                Text(isOn ? "ON" : "OFF")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(isOn ? Color.black.opacity(0.88) : JokerTheme.textSoft)
                    .frame(minWidth: 44)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 6)
                    .background(
                        Capsule().fill(
                            isOn
                                ? AnyShapeStyle(JokerTheme.accentGradient)
                                : AnyShapeStyle(Color.white.opacity(0.09))
                        )
                    )
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(JokerTheme.textFaint)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isOn ? JokerTheme.accent.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - Toast

struct ToastMessage: Equatable {
    let message: String
    let icon: String
    let color: Color
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.message == rhs.message
    }
}

private struct ToastView: View {
    let message: ToastMessage
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: message.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(message.color)
            Text(message.message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(JokerTheme.text)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(JokerTheme.cardBase))
        .overlay(Capsule().strokeBorder(JokerTheme.cardStroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 14, y: 6)
    }
}