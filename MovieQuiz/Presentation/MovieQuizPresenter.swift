import Foundation

import UIKit

final class MovieQuizPresenter {
    private weak var viewController: MovieQuizViewControllerProtocol?
    
    private let questionFactory: QuestionFactoryProtocol
    private let statisticService: StatisticServiceProtocol
    private let questionsAmount = 10
    private var currentQuestionIndex = 0
    private var currentQuestion: QuizQuestion?
    private var correctAnswers = 0
    
    init(viewController: MovieQuizViewControllerProtocol,
         questionFactory: QuestionFactoryProtocol = QuestionFactory(moviesLoader: MoviesLoader(), delegate: nil),
         statisticService: StatisticServiceProtocol = StatisticService()) {
        
        self.viewController = viewController
        self.questionFactory = questionFactory
        self.statisticService = statisticService
        
        if let factory = questionFactory as? QuestionFactory {
            factory.delegate = self
        }
    }
    
    // MARK: - Публичные методы
    
    func loadData() {
        viewController?.showLoadingIndicator()
        questionFactory.loadData()
    }
    
    func didAnswer(isYes: Bool) {
        guard let question = currentQuestion else { return }
        
        let isCorrect = (isYes == question.correctAnswer)
        if isCorrect {
            correctAnswers += 1
        }
        
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
        }
    }
    
    func restartGame() {
        resetQuestionIndex()
        correctAnswers = 0
        questionFactory.requestNextQuestion()
    }
    
    // MARK: - Приватные методы
    
    private func showNextQuestionOrResults() {
        if isLastQuestion() {
            let resultsViewModel = makeResultsViewModel()
            viewController?.show(quiz: resultsViewModel)
        } else {
            switchToNextQuestion()
            questionFactory.requestNextQuestion()
        }
    }
    
    private func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    private func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    private func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    private func makeResultsViewModel() -> QuizResultsViewModel {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        
        let bestGameDate = statisticService.bestGame.date.dateTimeString
        let messageText = """
        Ваш результат: \(correctAnswers)/\(questionsAmount)
        Количество сыгранных квизов: \(statisticService.gamesCount)
        Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(bestGameDate))
        Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
        """
        
        return QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: messageText,
            buttonText: "Сыграть ещё раз"
        )
    }
}

// MARK: - QuestionFactoryDelegate

extension MovieQuizPresenter: QuestionFactoryDelegate {
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        viewController?.show(quiz: viewModel)
    }
    
    func didFailToLoadData(with error: Error) {
        viewController?.showNetworkError(message: error.localizedDescription)
    }
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory.requestNextQuestion()
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
}
