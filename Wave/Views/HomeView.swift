import SwiftUI
import PhosphorSwift

enum NavItem: String, Hashable {
    case home = "Home"
    case dictionary = "Dictionary"
    case snippets = "Snippets"
    case help = "Help"
    // Settings group
    case general = "General"
    case shortcut = "Shortcut"
    case models = "Models"

    @ViewBuilder
    var icon: some View {
        switch self {
        case .home:       Ph.house.regular.frame(width: 16, height: 16)
        case .dictionary: Ph.bookOpen.regular.frame(width: 16, height: 16)
        case .snippets:   Ph.textT.regular.frame(width: 16, height: 16)
        case .help:       Ph.question.regular.frame(width: 16, height: 16)
        case .general:    Ph.slidersHorizontal.regular.frame(width: 16, height: 16)
        case .shortcut:   Ph.keyboard.regular.frame(width: 16, height: 16)
        case .models:     Ph.cpu.regular.frame(width: 16, height: 16)
        }
    }
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: NavItem? = .home

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label(title: { Text("Home") }, icon: { NavItem.home.icon }).tag(NavItem.home)
                Label(title: { Text("Dictionary") }, icon: { NavItem.dictionary.icon }).tag(NavItem.dictionary)
                Label(title: { Text("Snippets") }, icon: { NavItem.snippets.icon }).tag(NavItem.snippets)
                Label(title: { Text("Help") }, icon: { NavItem.help.icon }).tag(NavItem.help)

                Section("Settings") {
                    Label(title: { Text("General") }, icon: { NavItem.general.icon }).tag(NavItem.general)
                    Label(title: { Text("Shortcut") }, icon: { NavItem.shortcut.icon }).tag(NavItem.shortcut)
                    Label(title: { Text("Models") }, icon: { NavItem.models.icon }).tag(NavItem.models)
                }
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 200)
            .safeAreaInset(edge: .bottom) {
                Text("Wave \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
        } detail: {
            Group {
                switch selection ?? .home {
                case .home:       HomePageView()
                case .dictionary: DictionaryEditorView()
                case .snippets:   SnippetsPageView()
                case .help:       HelpPageView()
                case .general:    GeneralSettingsView()
                case .shortcut:   ShortcutSettingsView()
                case .models:     ModelsSettingsView()
                }
            }
            .frame(minWidth: 340)
        }
        .navigationTitle(selection?.rawValue ?? "Home")
        .toolbarBackground(.hidden, for: .windowToolbar)
        .frame(minWidth: 520, maxWidth: 520, minHeight: 500, maxHeight: 500)
        .background(WindowConfigurator().frame(width: 0, height: 0))
        .sheet(isPresented: Binding(
            get: { appState.showOnboarding },
            set: { appState.showOnboarding = $0 }
        )) {
            OnboardingView()
                .environment(appState)
        }
    }
}
