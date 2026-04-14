import SwiftUI

struct AboutAppView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Venkata Task Hub")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("Personal finance tools for mortgage planning and investment growth.")
                            .foregroundStyle(.secondary)
                        Text("Built for quick, repeatable calculations with a clean native iPhone experience.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Current Tools") {
                    featureRow(
                        icon: "house",
                        title: "Mortgage Calculator",
                        detail: "Amortization schedule, payoff timing, and monthly cost breakdown."
                    )
                    featureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Compound Interest",
                        detail: "Scenario-based growth modeling with variance bands and a chart."
                    )
                }

                Section("App Direction") {
                    Label("Saved scenarios for repeat use", systemImage: "square.stack")
                    Label("Offline-first calculations", systemImage: "wifi.slash")
                    Label("Expandable tool categories later", systemImage: "square.grid.2x2")
                }

                Section("Privacy") {
                    Text("This version stores saved scenarios only on-device using local app storage.")
                        .foregroundStyle(.secondary)
                    Text("No account, analytics, or cloud sync has been added yet.")
                        .foregroundStyle(.secondary)
                }

                Section("Next Release Candidates") {
                    Label("PMI and additional mortgage cost options", systemImage: "plus.circle")
                    Label("Inflation-adjusted investment returns", systemImage: "arrow.triangle.2.circlepath")
                    Label("Better chart interaction and export", systemImage: "square.and.arrow.up")
                }
            }
            .navigationTitle("About")
        }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AboutAppView()
}
