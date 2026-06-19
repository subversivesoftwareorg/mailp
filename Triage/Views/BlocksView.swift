import SwiftUI

struct BlocksView: View {
    @State private var blocks: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let queryService = MailQueryService()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Blocked Senders & Domains")
                    .font(.title2.bold())
                Spacer()
                Button {
                    Task { await loadBlocks() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
            }
            .padding()

            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Divider()

            if blocks.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No blocked senders or domains")
                        .foregroundStyle(.secondary)
                    Text("Press B on a selected message to block the sender,\nor Shift+B to block the entire domain.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(blocks, id: \.self) { expression in
                        HStack {
                            Image(systemName: expression.hasPrefix("@") ? "globe" : "person")
                                .foregroundStyle(expression.hasPrefix("@") ? .orange : .blue)
                                .frame(width: 20)
                            VStack(alignment: .leading) {
                                Text(expression)
                                    .font(.body.monospaced())
                                Text(expression.hasPrefix("@") ? "Domain" : "Sender")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Unblock") {
                                Task { await unblock(expression) }
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                            .font(.caption)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task { await loadBlocks() }
    }

    private func loadBlocks() async {
        isLoading = true
        defer { isLoading = false }
        do {
            blocks = try await queryService.listBlocks()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func unblock(_ expression: String) async {
        do {
            try await queryService.removeBlock(expression: expression)
            blocks.removeAll { $0 == expression }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
