import SwiftUI
import Charts

struct CompoundInterestView: View {
    @EnvironmentObject private var scenarioStore: ScenarioStore
    @State private var input = InvestmentInput()
    @State private var showingSavePrompt = false
    @State private var scenarioName = ""

    private var summary: InvestmentSummary {
        InvestmentCalculator.summarize(input)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    savedScenariosSection
                    inputSection
                    summarySection
                    chartSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Investing")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Reset") {
                        input = InvestmentInput()
                    }

                    Button("Save") {
                        scenarioName = ""
                        showingSavePrompt = true
                    }
                }
            }
        }
        .alert("Save Investment Scenario", isPresented: $showingSavePrompt) {
            TextField("Scenario name", text: $scenarioName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                scenarioStore.saveInvestmentScenario(name: scenarioName, input: input)
            }
        } message: {
            Text("Save this investing setup so you can compare it again later.")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compound interest growth")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Compare lower, base, and higher return scenarios and visualize long-term growth.")
                .foregroundStyle(.secondary)
        }
    }

    private var savedScenariosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved scenarios")
                    .font(.headline)
                Spacer()
                if !scenarioStore.investmentScenarios.isEmpty {
                    Text("\(scenarioStore.investmentScenarios.count)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color("AccentColor").opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if scenarioStore.investmentScenarios.isEmpty {
                Text("No saved investment scenarios yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(scenarioStore.investmentScenarios.enumerated()), id: \.element.id) { index, scenario in
                    HStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(scenario.name)
                                    .foregroundStyle(.primary)
                                    .fontWeight(.semibold)
                                Text("\(scenario.input.years) yrs • \(Formatters.percent(scenario.input.annualReturn)) base return")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(Color("AccentColor"))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            input = scenario.input
                        }

                        Button {
                            scenarioStore.investmentScenarios.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()
                }
            }
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Inputs")
                .font(.headline)

            currencyField("Initial investment", value: $input.initialInvestment)
            currencyField("Monthly contribution", value: $input.monthlyContribution)
            Stepper("Time period: \(input.years) years", value: $input.years, in: 1...50)
            numberField("Expected annual return (%)", value: $input.annualReturn)
            numberField("Return variance (%)", value: $input.variance)

            Picker("Compounding", selection: $input.compoundsPerYear) {
                Text("Monthly").tag(12)
                Text("Quarterly").tag(4)
                Text("Yearly").tag(1)
            }
            .pickerStyle(.segmented)
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var summarySection: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricCard("Total contributed", value: summary.totalContributed.formatted(Formatters.currency))
                metricCard("Base ending value", value: summary.baseEndingValue.formatted(Formatters.currency))
                metricCard("Investment gain", value: summary.investmentGain.formatted(Formatters.currency))
                metricCard("Base annual return", value: Formatters.percent(input.annualReturn))
            }

            VStack(spacing: 14) {
                insightRow("Lower scenario", value: summary.lowEndingValue.formatted(Formatters.currency))
                insightRow("Higher scenario", value: summary.highEndingValue.formatted(Formatters.currency))
                insightRow("Variance band", value: "\(Formatters.percent(summary.lowReturn)) to \(Formatters.percent(summary.highReturn))")
            }
            .padding(18)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Growth over time")
                .font(.headline)

            Chart {
                ForEach(summary.points) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Lower", point.lowValue)
                    )
                    .foregroundStyle(Color(red: 0.54, green: 0.66, blue: 0.62))

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Base", point.baseValue)
                    )
                    .foregroundStyle(Color("AccentColor"))
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Higher", point.highValue)
                    )
                    .foregroundStyle(Color(red: 0.72, green: 0.43, blue: 0.23))
                }
            }
            .frame(height: 280)

            Text("Lower, base, and higher return paths over \(input.years) years.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func metricCard(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func insightRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func currencyField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number.precision(.fractionLength(0)))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func numberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    CompoundInterestView()
        .environmentObject(ScenarioStore())
}
