import Foundation

protocol StatisticServiceProtocol: AnyObject {
    var gamesCount: Int { get set }
    var bestGame: GameResult { get set }
    var totalAccuracy: Double { get }
    var overallStatistic: String { get }
    
    func store(correct count: Int, total amount: Int)
}
