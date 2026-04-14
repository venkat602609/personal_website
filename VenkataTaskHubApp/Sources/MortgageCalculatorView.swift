import SwiftUI

struct MortgageCalculatorView: View {
    @EnvironmentObject private var scenarioStore: ScenarioStore
    @State private var input = MortgageInput()
    @State private var isLoanAmountManual = false
    @State private var showingSavePrompt = false
    @State private var scenarioName = ""

    private var summary: MortgageSummary {
        MortgageCalculator.summarize(input)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    savedScenariosSection
                    inputSection
                    summarySection
                    insightSection
                    scheduleSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mortgage")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Reset") {
                        resetInput()
                    }

                    Button("Save") {
                        scenarioName = ""
                        showingSavePrompt = true
                    }
                }
            }
        }
        .onChange(of: input.homePrice) { _, _ in syncLoanAmount() }
        .onChange(of: input.downPayment) { _, _ in syncLoanAmount() }
        .alert("Save Mortgage Scenario", isPresented: $showingSavePrompt) {
            TextField("Scenario name", text: $scenarioName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                scenarioStore.saveMortgageScenario(name: scenarioName, input: input)
            }
        } message: {
            Text("Save this mortgage setup so you can reopen it later.")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mortgage amortization")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Estimate monthly cost, interest paid, payoff timing, and the full amortization schedule.")
                .foregroundStyle(.secondary)
        }
    }

    private var savedScenariosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved scenarios")
                    .font(.headline)
                Spacer()
                if !scenarioStore.mortgageScenarios.isEmpty {
                    Text("\(scenarioStore.mortgageScenarios.count)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color("AccentColor").opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if scenarioStore.mortgageScenarios.isEmpty {
                Text("No saved mortgage scenarios yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(scenarioStore.mortgageScenarios.enumerated()), id: \.element.id) { index, scenario in
                    HStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(scenario.name)
                                    .foregroundStyle(.primary)
                                    .fontWeight(.semibold)
                                Text("\(scenario.input.termYears) yrs • \(scenario.input.loanAmount.formatted(Formatters.currency)) at \(Formatters.percent(scenario.input.interestRate))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .foregroundStyle(Color("AccentColor"))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            input = scenario.input
                            isLoanAmountManual = true
                        }

                        Button {
                            scenarioStore.mortgageScenarios.remove(at: index)
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

            Group {
                currencyField("Home price", value: $input.homePrice)
                currencyField("Down payment", value: $input.downPayment)
                currencyField("Loan amount", value: Binding(
                    get: { input.loanAmount },
                    set: {
                        input.loanAmount = $0
                        isLoanAmountManual = true
                    }
                ))
                percentField("Interest rate (%)", value: $input.interestRate)
                Stepper("Loan term: \(input.termYears) years", value: $input.termYears, in: 1...40)
                currencyField("Extra monthly payment", value: $input.extraPayment)
                currencyField("Annual property tax", value: $input.annualPropertyTax)
                currencyField("Annual insurance", value: $input.annualInsurance)
                currencyField("Monthly HOA", value: $input.monthlyHOA)
                DatePicker("Start date", selection: $input.startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var summarySection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard("Monthly P&I", value: summary.monthlyPI.formatted(Formatters.currency))
            metricCard("Monthly total", value: summary.monthlyTotal.formatted(Formatters.currency))
            metricCard("Total interest", value: summary.totalInterest.formatted(Formatters.currency))
            metricCard("Payoff date", value: summary.payoffDate?.formatted(Formatters.monthYear) ?? "-")
        }
    }

    private var insightSection: some View {
        VStack(spacing: 14) {
            insightRow("Down payment ratio", value: Formatters.percent(summary.downPaymentRatio * 100))
            insightRow("Total of all payments", value: summary.totalPaid.formatted(Formatters.currency))
            insightRow("Estimated months saved", value: "\(summary.monthsSaved)")
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amortization schedule")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 8) {
                    HStack(spacing: 18) {
                        headerText("Month", width: 56)
                        headerText("Date", width: 92)
                        headerText("Payment", width: 94)
                        headerText("Principal", width: 94)
                        headerText("Interest", width: 94)
                        headerText("Balance", width: 94)
                    }

                    ForEach(summary.rows.prefix(120)) { row in
                        HStack(spacing: 18) {
                            cellText("\(row.month)", width: 56)
                            cellText(row.date.formatted(Formatters.monthYear), width: 92)
                            cellText(row.payment.formatted(Formatters.currency), width: 94)
                            cellText(row.principal.formatted(Formatters.currency), width: 94)
                            cellText(row.interest.formatted(Formatters.currency), width: 94)
                            cellText(row.balance.formatted(Formatters.currency), width: 94)
                        }
                        .padding(.vertical, 8)
                        Divider()
                    }
                }
            }
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

    private func percentField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number.precision(.fractionLength(2)))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func headerText(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
    }

    private func cellText(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.footnote)
            .frame(width: width, alignment: .leading)
    }

    private func syncLoanAmount() {
        guard !isLoanAmountManual else { return }
        input.loanAmount = max(input.homePrice - input.downPayment, 0)
    }

    private func resetInput() {
        isLoanAmountManual = false
        input = MortgageInput()
    }
}

#Preview {
    MortgageCalculatorView()
        .environmentObject(ScenarioStore())
}
