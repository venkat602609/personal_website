import Foundation

final class ScenarioStore: ObservableObject {
    @Published var mortgageScenarios: [MortgageScenario] = [] {
        didSet { saveMortgageScenarios() }
    }

    @Published var investmentScenarios: [InvestmentScenario] = [] {
        didSet { saveInvestmentScenarios() }
    }

    private let mortgageKey = "savedMortgageScenarios"
    private let investmentKey = "savedInvestmentScenarios"

    init() {
        mortgageScenarios = load([MortgageScenario].self, forKey: mortgageKey)
        investmentScenarios = load([InvestmentScenario].self, forKey: investmentKey)
    }

    func saveMortgageScenario(name: String, input: MortgageInput) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        mortgageScenarios.insert(MortgageScenario(name: trimmed, input: input), at: 0)
        mortgageScenarios = Array(mortgageScenarios.prefix(10))
    }

    func saveInvestmentScenario(name: String, input: InvestmentInput) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        investmentScenarios.insert(InvestmentScenario(name: trimmed, input: input), at: 0)
        investmentScenarios = Array(investmentScenarios.prefix(10))
    }

    func deleteMortgageScenarios(at offsets: IndexSet) {
        mortgageScenarios.remove(atOffsets: offsets)
    }

    func deleteInvestmentScenarios(at offsets: IndexSet) {
        investmentScenarios.remove(atOffsets: offsets)
    }

    private func saveMortgageScenarios() {
        save(mortgageScenarios, forKey: mortgageKey)
    }

    private func saveInvestmentScenarios() {
        save(investmentScenarios, forKey: investmentKey)
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let value = try? JSONDecoder().decode(type, from: data)
        else {
            if let empty = [] as? T {
                return empty
            }
            fatalError("Unsupported default load for \(type)")
        }

        return value
    }
}
