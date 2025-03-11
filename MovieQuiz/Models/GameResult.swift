import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    func isBetter(than other: GameResult) -> Bool {
        
        guard other.total > 0 else { return true }
        let currentAccuracy = Double(correct) / Double(total)
        let otherAccuracy = Double(other.correct) / Double(other.total)
        
        return currentAccuracy > otherAccuracy
    }
}
