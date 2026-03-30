import SwiftUI

enum NavItem: String, Hashable {
    case home = "Home"
    case dictionary = "Dictionary"
    case snippets = "Snippets"
    // Settings group
    case general = "General"
    case shortcut = "Shortcuts"
    case models = "Models"
    // Help group
    case howToUse = "How to Use"
    case about = "About"

    var icon: String {
        switch self {
        case .home:       return "house"
        case .dictionary: return "character.book.closed"
        case .snippets:   return "text.alignleft"
        case .general:    return "slider.horizontal.3"
        case .shortcut:   return "keyboard"
        case .models:     return "cpu"
        case .howToUse:   return "questionmark.circle"
        case .about:      return "info.circle"
        }
    }
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: NavItem? = .home

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Home", systemImage: NavItem.home.icon).tag(NavItem.home)
                Label("Dictionary", systemImage: NavItem.dictionary.icon).tag(NavItem.dictionary)
                Label("Snippets", systemImage: NavItem.snippets.icon).tag(NavItem.snippets)

                Section("Settings") {
                    Label("General", systemImage: NavItem.general.icon).tag(NavItem.general)
                    Label("Shortcut", systemImage: NavItem.shortcut.icon).tag(NavItem.shortcut)
                    Label("Models", systemImage: NavItem.models.icon).tag(NavItem.models)
                }

                Section("Help") {
                    Label("How to Use", systemImage: NavItem.howToUse.icon).tag(NavItem.howToUse)
                    Label("About", systemImage: NavItem.about.icon).tag(NavItem.about)
                }
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 200)
            .safeAreaInset(edge: .bottom) {
                Text("Wave v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                    .font(.system(size: 11))
                    .foregroundStyle(.quaternary)
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
                case .general:    GeneralSettingsView()
                case .shortcut:   ShortcutSettingsView()
                case .models:     ModelsSettingsView()
                case .howToUse:   HowToUseView()
                case .about:      AboutView()
                }
            }
            .frame(minWidth: 340)
        }
        .navigationTitle(selection?.rawValue ?? "Home")
        .toolbarBackground(.hidden, for: .windowToolbar)
        .accentColor(.brand)
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
