import SwiftUI

struct SnippetsPageView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.quote")
                .font(.system(size: 28))
                .foregroundStyle(.quaternary)
            Text("Coming soon")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
