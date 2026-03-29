import SwiftUI

struct SettingsPageView: View {
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case shortcut = "Shortcut"
        case models = "Models"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 4) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            switch selectedTab {
            case .general:  GeneralSettingsView()
            case .shortcut: ShortcutSettingsView()
            case .models:   ModelsSettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func tabButton(_ tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab
        Button(tab.rawValue) { selectedTab = tab }
            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(isSelected ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear), in: RoundedRectangle(cornerRadius: 6))
            .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            .buttonStyle(.plain)
    }
}
