import UIKit

final class MovieQuizViewController: UIViewController , QuestionFactoryDelegate {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let factory = QuestionFactory()
        factory.delegate = self
        self.questionFactory = factory
        
        statisticService = StatisticService()
        
        factory.requestNextQuestion()
    }
    // MARK: - QuestionFactoryDelegate

    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }

        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLable.text = step.question
        counterLable.text = step.questionNumber
    }
    
    
    private var currentQuestionIndex = 0
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var correctAnswers = 0
    private var statisticService: StatisticServiceProtocol!
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
                    image: UIImage(named: model.image) ?? UIImage(),
                    question: model.text,
                    questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }

        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
          
            self.imageView.layer.borderWidth = 0
            self.imageView.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    private func showQuizResults() {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        let bestGameDate = statisticService.bestGame.date.dateTimeString
        let messageText = """
        Ваш результат: \(correctAnswers)/\(questionsAmount)
        Количество сыгранных квизов: \(statisticService.gamesCount)
        Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(bestGameDate))
        Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
        """
        let boldFont = UIFont(name: "YPDisplay-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20)
        let mediumFont = UIFont(name: "YPDisplay-Medium", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .medium)
        let ypBlack = UIColor.ypBlack
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: boldFont,
            .foregroundColor: ypBlack
        ]
        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: mediumFont,
            .foregroundColor: ypBlack
        ]
        let attributedTitle = NSAttributedString(string: "Этот раунд окончен!", attributes: titleAttributes)
        let attributedMessage = NSAttributedString(string: messageText, attributes: messageAttributes)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.setValue(attributedTitle, forKey: "attributedTitle")
        alert.setValue(attributedMessage, forKey: "attributedMessage")
        
        let action = UIAlertAction(title: "Сыграть ещё раз", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            self.questionFactory?.requestNextQuestion()
        }
        alert.addAction(action)
        
        UIButton.appearance(whenContainedInInstancesOf: [UIAlertController.self]).titleLabel?.font = boldFont

        present(alert, animated: true, completion: nil)
    }


    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            showQuizResults()
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
    }
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLable: UILabel!
    @IBOutlet private var counterLable: UILabel!
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
}
