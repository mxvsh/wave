import SwiftUI

enum NavItem: String, CaseIterable, Hashable {
    case home = "Home"
    case dictionary = "Dictionary"
    case snippets = "Snippets"
    case help = "Help"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: return "house"
        case .dictionary: return "character.book.closed"
        case .snippets: return "text.quote"
        case .help: return "questionmark.circle"
        case .settings: return "gearshape"
        }
    }
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: NavItem? = .home

    var body: some View {
        NavigationSplitView {
            List(NavItem.allCases, id: \.self, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
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
                case .home:
                    HomePageView()
                case .dictionary:
                    DictionaryEditorView()
                case .snippets:
                    SnippetsPageView()
                case .help:
                    HelpPageView()
                case .settings:
                    SettingsPageView()
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
