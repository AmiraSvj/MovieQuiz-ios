import Foundation

final class StatisticService: StatisticServiceProtocol {
    var overallStatistic: String = ""
    private let storage: UserDefaults = .standard
    
    enum Keys: String {
            case gamesCount
            case bestGameCorrect = "bestGame.correct"
            case bestGameTotal = "bestGame.total"
            case bestGameDate = "bestGame.date"
            case totalCorrectAnswers
        }
    var gamesCount: Int {
            get {
                storage.integer(forKey: Keys.gamesCount.rawValue)
            }
            set {
                storage.set(newValue, forKey: Keys.gamesCount.rawValue)
            }
        }
        
        var bestGame: GameResult {
            get {
                let correct = storage.integer(forKey: Keys.bestGameCorrect.rawValue)
                let total = storage.integer(forKey: Keys.bestGameTotal.rawValue)
                let date = storage.object(forKey: Keys.bestGameDate.rawValue) as? Date ?? Date()
                return GameResult(correct: correct, total: total, date: date)
            }
            set {
                storage.set(newValue.correct, forKey: Keys.bestGameCorrect.rawValue)
                storage.set(newValue.total, forKey: Keys.bestGameTotal.rawValue)
                storage.set(newValue.date, forKey: Keys.bestGameDate.rawValue)
            }
        }
        
        var totalAccuracy: Double {
            let totalGames = gamesCount
            let totalQuestions = totalGames * 10
            guard totalQuestions > 0 else { return 0.0 }
            let totalCorrect = storage.integer(forKey: Keys.totalCorrectAnswers.rawValue)
            return (Double(totalCorrect) / Double(totalQuestions)) * 100.0
        }
    func store(correct count: Int, total amount: Int) {
        let previousCorrect = storage.integer(forKey: Keys.totalCorrectAnswers.rawValue)
        storage.set(previousCorrect + count, forKey: Keys.totalCorrectAnswers.rawValue)
        gamesCount += 1
        
        let newGameResult = GameResult(correct: count, total: amount, date: Date())
        if newGameResult.isBetter(than: bestGame) {
            bestGame = newGameResult
        }
    }
}
