import SwiftUI

struct LLMModel: Identifiable {
    let id: String
    let name: String
    let inputPer1M: String
    let outputPer1M: String
    let context: String
}

// Hardcoded pricing for known models
let llmModels: [LLMModel] = [
    LLMModel(id: "openai/gpt-oss-20b",                            name: "GPT OSS 20B",             inputPer1M: "$0.075", outputPer1M: "$0.30",  context: "131k"),
    LLMModel(id: "openai/gpt-oss-120b",                           name: "GPT OSS 120B",            inputPer1M: "$0.15",  outputPer1M: "$0.60",  context: "131k"),
    LLMModel(id: "meta-llama/llama-4-scout-17b-16e-instruct",     name: "Llama 4 Scout (17B)",     inputPer1M: "$0.11",  outputPer1M: "$0.34",  context: "131k"),
    LLMModel(id: "meta-llama/llama-4-maverick-17b-128e-instruct", name: "Llama 4 Maverick (17B)",  inputPer1M: "$0.20",  outputPer1M: "$0.60",  context: "131k"),
    LLMModel(id: "llama-3.3-70b-versatile",                       name: "Llama 3.3 70B Versatile", inputPer1M: "$0.59",  outputPer1M: "$0.79",  context: "128k"),
    LLMModel(id: "llama-3.1-8b-instant",                          name: "Llama 3.1 8B Instant",    inputPer1M: "$0.05",  outputPer1M: "$0.08",  context: "128k"),
    LLMModel(id: "qwen/qwen3-32b",                                name: "Qwen 3 32B",              inputPer1M: "$0.29",  outputPer1M: "$0.59",  context: "131k"),
    LLMModel(id: "gemma-7b-it",                                   name: "Gemma 7B IT",             inputPer1M: "$0.05",  outputPer1M: "$0.08",  context: "8k"),
    LLMModel(id: "moonshotai/kimi-k2-instruct",                   name: "Kimi K2 Instruct",        inputPer1M: "$1.00",  outputPer1M: "$3.00",  context: "262k"),
]

private let pricingLookup: [String: LLMModel] = Dictionary(uniqueKeysWithValues: llmModels.map { ($0.id, $0) })

struct LLMPickerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    // Merge fetched models with hardcoded pricing; fall back to hardcoded list if none fetched
    private var displayModels: [LLMModel] {
        let fetched = appState.groqFetchedModels
        if fetched.isEmpty { return llmModels }
        return fetched.map { id in
            if let known = pricingLookup[id] { return known }
            // Unknown model — show id without pricing
            let name = id.split(separator: "/").last.map(String.init) ?? id
            return LLMModel(id: id, name: name, inputPer1M: "—", outputPer1M: "—", context: "—")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Model")
                    .font(.title3.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }

            // Header row
            HStack(spacing: 0) {
                Text("Model")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Input/1M")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)
                Text("Output/1M")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 75, alignment: .trailing)
                Text("Context")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)
                Spacer().frame(width: 60)
            }
            .padding(.horizontal, 12)

            Divider()

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(displayModels) { model in
                        modelRow(model)
                    }
                }
            }
            .frame(maxHeight: 340)
        }
        .padding()
    }

    @ViewBuilder
    private func modelRow(_ model: LLMModel) -> some View {
        let isSelected = appState.aiModel == model.id

        HStack(spacing: 0) {
            Text(model.name)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(model.inputPer1M)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
            Text(model.outputPer1M)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 75, alignment: .trailing)
            Text(model.context)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            HStack {
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                } else {
                    Button("Use") {
                        appState.aiModel = model.id
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 60)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(in: RoundedRectangle(cornerRadius: 8))
        .backgroundStyle(isSelected ? AnyShapeStyle(Color.brand.opacity(0.08)) : AnyShapeStyle(.quaternary.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.brand.opacity(0.2) : Color.clear, lineWidth: 1))
    }
}
