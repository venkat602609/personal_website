import Foundation

struct MortgageInput: Codable {
    var homePrice: Double = 450_000
    var downPayment: Double = 90_000
    var loanAmount: Double = 360_000
    var interestRate: Double = 6.25
    var termYears: Int = 30
    var extraPayment: Double = 0
    var annualPropertyTax: Double = 5_400
    var annualInsurance: Double = 1_800
    var monthlyHOA: Double = 0
    var startDate: Date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 1)) ?? .now
}

struct MortgageScenario: Identifiable, Codable {
    let id: UUID
    let name: String
    let input: MortgageInput

    init(id: UUID = UUID(), name: String, input: MortgageInput) {
        self.id = id
        self.name = name
        self.input = input
    }
}

struct MortgageRow: Identifiable {
    let id = UUID()
    let month: Int
    let date: Date
    let payment: Double
    let principal: Double
    let interest: Double
    let extra: Double
    let balance: Double
}

struct MortgageSummary {
    let monthlyPI: Double
    let monthlyTotal: Double
    let totalInterest: Double
    let totalPaid: Double
    let payoffDate: Date?
    let downPaymentRatio: Double
    let monthsSaved: Int
    let rows: [MortgageRow]
}

enum MortgageCalculator {
    static func summarize(_ input: MortgageInput) -> MortgageSummary {
        let principal = max(input.loanAmount, 0)
        let totalMonths = max(input.termYears, 1) * 12
        let monthlyRate = max(input.interestRate, 0) / 12 / 100
        let monthlyPI = monthlyPayment(principal: principal, monthlyRate: monthlyRate, totalMonths: totalMonths)
        let monthlyEscrow = max(input.annualPropertyTax, 0) / 12 + max(input.annualInsurance, 0) / 12 + max(input.monthlyHOA, 0)

        var balance = principal
        var totalInterest = 0.0
        var totalPaid = 0.0
        var rows: [MortgageRow] = []

        for month in 1...(totalMonths + 600) {
            guard balance > 0.01 else { break }

            let interest = monthlyRate == 0 ? 0 : balance * monthlyRate
            let scheduledPrincipal = min(monthlyPI - interest, balance)
            let remainingAfterScheduled = balance - scheduledPrincipal
            let appliedExtra = min(max(input.extraPayment, 0), max(remainingAfterScheduled, 0))
            let totalPrincipal = scheduledPrincipal + appliedExtra
            let payment = totalPrincipal + interest

            balance = max(balance - totalPrincipal, 0)
            totalInterest += interest
            totalPaid += payment + monthlyEscrow

            rows.append(
                MortgageRow(
                    month: month,
                    date: Calendar.current.date(byAdding: .month, value: month - 1, to: input.startDate) ?? input.startDate,
                    payment: payment,
                    principal: totalPrincipal,
                    interest: interest,
                    extra: appliedExtra,
                    balance: balance
                )
            )

            if payment <= 0 { break }
        }

        let ratio = input.homePrice > 0 ? input.downPayment / input.homePrice : 0

        return MortgageSummary(
            monthlyPI: monthlyPI,
            monthlyTotal: monthlyPI + monthlyEscrow + max(input.extraPayment, 0),
            totalInterest: totalInterest,
            totalPaid: totalPaid,
            payoffDate: rows.last?.date,
            downPaymentRatio: ratio,
            monthsSaved: max(totalMonths - rows.count, 0),
            rows: rows
        )
    }

    private static func monthlyPayment(principal: Double, monthlyRate: Double, totalMonths: Int) -> Double {
        guard principal > 0, totalMonths > 0 else { return 0 }
        guard monthlyRate > 0 else { return principal / Double(totalMonths) }

        let growth = pow(1 + monthlyRate, Double(totalMonths))
        return principal * ((monthlyRate * growth) / (growth - 1))
    }
}

struct InvestmentInput: Codable {
    var initialInvestment: Double = 25_000
    var monthlyContribution: Double = 1_000
    var years: Int = 20
    var annualReturn: Double = 8
    var variance: Double = 2
    var compoundsPerYear: Int = 12
}

struct InvestmentScenario: Identifiable, Codable {
    let id: UUID
    let name: String
    let input: InvestmentInput

    init(id: UUID = UUID(), name: String, input: InvestmentInput) {
        self.id = id
        self.name = name
        self.input = input
    }
}

struct InvestmentPoint: Identifiable {
    let id = UUID()
    let year: Double
    let label: String
    let lowValue: Double
    let baseValue: Double
    let highValue: Double
}

struct InvestmentSummary {
    let totalContributed: Double
    let baseEndingValue: Double
    let investmentGain: Double
    let lowEndingValue: Double
    let highEndingValue: Double
    let lowReturn: Double
    let highReturn: Double
    let points: [InvestmentPoint]
}

enum InvestmentCalculator {
    static func summarize(_ input: InvestmentInput) -> InvestmentSummary {
        let lowReturn = max(input.annualReturn - input.variance, 0)
        let highReturn = input.annualReturn + input.variance

        let lowSeries = buildSeries(input: input, annualReturn: lowReturn)
        let baseSeries = buildSeries(input: input, annualReturn: input.annualReturn)
        let highSeries = buildSeries(input: input, annualReturn: highReturn)

        let totalContributed = max(input.initialInvestment, 0) + max(input.monthlyContribution, 0) * Double(max(input.years, 1) * 12)

        let points = zip(lowSeries, zip(baseSeries, highSeries)).map { low, pair in
            let (base, high) = pair
            return InvestmentPoint(
                year: base.year,
                label: base.label,
                lowValue: low.value,
                baseValue: base.value,
                highValue: high.value
            )
        }

        return InvestmentSummary(
            totalContributed: totalContributed,
            baseEndingValue: baseSeries.last?.value ?? 0,
            investmentGain: (baseSeries.last?.value ?? 0) - totalContributed,
            lowEndingValue: lowSeries.last?.value ?? 0,
            highEndingValue: highSeries.last?.value ?? 0,
            lowReturn: lowReturn,
            highReturn: highReturn,
            points: points
        )
    }

    private static func buildSeries(input: InvestmentInput, annualReturn: Double) -> [(year: Double, label: String, value: Double)] {
        let years = max(input.years, 1)
        let months = years * 12
        let contribution = max(input.monthlyContribution, 0)
        let compounds = max(input.compoundsPerYear, 1)
        let interval = max(12 / compounds, 1)
        var balance = max(input.initialInvestment, 0)
        var series: [(Double, String, Double)] = [(0, "Start", balance)]

        for month in 1...months {
            balance += contribution
            if month % interval == 0 {
                balance *= 1 + annualReturn / 100 / Double(compounds)
            }

            if month % 12 == 0 || month == months {
                let year = Double(month) / 12
                series.append((year, "Year \(Int(ceil(year)))", balance))
            }
        }

        return series
    }
}
