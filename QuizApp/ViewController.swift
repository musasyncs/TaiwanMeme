//
//  ViewController.swift
//  QuizApp
//
//  Created by Ewen on 2021/8/5.
//

import UIKit

class ViewController: UIViewController {
    var model = QuizModel()
    var questions = [Question]()
    var currentQuestionIndex = 0 // 目前在第幾題
    var numQuestionCorrect = 0 // 目前答對題數
    var resultDialogVC: ResultViewController?
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var questionImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    // For Animation
    @IBOutlet weak var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rootStackView: UIStackView!
            
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createGradientBackground()
        
        // 設定 ViewController 為 tableView 的 delegate 和 dataSource
        tableView.delegate = self
        tableView.dataSource = self
        
        // 設定 ViewController 為 QuizModel 的 delegate
        model.delegate = self
        // 使用 QuizModel 的 getQuestions() 抓題目。
        model.getQuestions()
        
        // 初始化 resultDialogVC
        resultDialogVC = storyboard?.instantiateViewController(identifier: "ResultVC") as? ResultViewController
        resultDialogVC?.modalPresentationStyle = .overCurrentContext
        // resultDialogVC 的 delegate 是 ViewController
        resultDialogVC?.delegate = self
    }
    
    func createGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1).cgColor,
            UIColor(red: 69/255, green: 84/255, blue: 97/255, alpha: 1).cgColor,
        ]
        // 決定漸層的方向
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        // 漸層變化範圍
        gradientLayer.locations = [0, 1]
        // 將漸層的 layer 加在最底層。如果用addSublayer加入會把畫面覆蓋掉。
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func slideInQuestion() {
        /// initial state
        stackViewTrailingConstraint.constant = -1000
        stackViewLeadingConstraint.constant = 1000
        rootStackView.alpha = 0
        view.layoutIfNeeded()
        
        /// Animate it to the end state
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.stackViewLeadingConstraint.constant = 0
            self.stackViewTrailingConstraint.constant = 0
            self.rootStackView.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func slideOutQuestion() {
        /// initial state
        stackViewTrailingConstraint.constant = 0
        stackViewLeadingConstraint.constant = 0
        rootStackView.alpha = 1
        view.layoutIfNeeded()
        
        /// Animate it to the end state
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.stackViewLeadingConstraint.constant = -1000
            self.stackViewTrailingConstraint.constant = 1000
            self.rootStackView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func displayQuestion() {
        questionImageView.image = UIImage(imageLiteralResourceName: "\(currentQuestionIndex+1)")
        questionLabel.text      = questions[currentQuestionIndex].questionName
        tableView.reloadData()
        
        /// slide in the questions
        slideInQuestion()
    }
}


// MARK: - UITableViewDatasourse Methods
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let choices = questions[currentQuestionIndex].choices else {
            return 0
        }
        return choices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChoiceCell", for: indexPath)
        let label = cell.viewWithTag(1) as? UILabel // cell(with Label Tag 1) 轉型成 label
        if let label = label,
           let choices = questions[currentQuestionIndex].choices {
            label.text = choices[indexPath.row] // 設定標籤的選項文字
        }
        return cell
    }
}

// MARK: - UITableViewDelegate Methods
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var titleText = ""
        let question = questions[currentQuestionIndex]
        
        // 檢查是否為正解
        if question.correctAnswerIndex! == indexPath.row {
            titleText = "答對了"
            numQuestionCorrect += 1
        } else {
            titleText = "答錯了"
        }
        
        /// slide out the question
        DispatchQueue.main.async {
            self.slideOutQuestion()
        }
        
        // resultDialogVC 的屬性們被傳入資料
        resultDialogVC?.resultTitleText = titleText
        resultDialogVC?.feedbackText    = question.feedback
        
        if currentQuestionIndex == questions.count - 1 {
            resultDialogVC?.buttonText = "查看結果"
        } else if currentQuestionIndex < questions.count - 1 {
            resultDialogVC?.buttonText = "下一題"
        }
        
        DispatchQueue.main.async {
            self.present(self.resultDialogVC!, animated: true, completion: nil)
        }
    }
}

// MARK: - QuizProtocol Methods
extension ViewController: QuizProtocol {
    func questionsRetrieved(_ questions: [Question]) {
        print("收到題目！")
        
        // ViewController 的 questions 屬性接收參數 questions
        self.questions = questions
        
        /// 檢查是否有已儲存的 savedIndex, savedNumCorrect
        let savedIndex = StateManager.retrieveValue(key: StateManager.questionIndexKey) as? Int
        if savedIndex != nil, savedIndex! < self.questions.count {
            // 設定問題指標為儲存的 savedIndex
            currentQuestionIndex = savedIndex!
        }
        let savedNumCorrect = StateManager.retrieveValue(key: StateManager.numCorrectKey) as? Int
        if savedNumCorrect != nil {
            numQuestionCorrect = savedNumCorrect! // 設定已答對題數為儲存的 savedNumCorrect
        }
        
        displayQuestion() // 顯示問題
    }
}

// MARK: - ResultViewControllerProtocol Methods
extension ViewController: ResultViewControllerProtocol {
    func dialogDismissed() {
        currentQuestionIndex += 1
        
        // 沒下一題了，
        if currentQuestionIndex == questions.count {
            resultDialogVC?.resultTitleText = "測驗結果"
            resultDialogVC?.feedbackText = "您在 \(questions.count) 題中，答對了 \(numQuestionCorrect) 題。總分為 \(numQuestionCorrect * 5) 分。"
            resultDialogVC?.buttonText = "再玩一次"
            present(resultDialogVC!, animated: true, completion: nil)
            
            /// 跳出總結對話窗後，清除已儲存狀態
            StateManager.clearState()
            
        } else if currentQuestionIndex > questions.count { // 在總結對話窗按"Restart"之後，要回到第一題
            currentQuestionIndex = 0 // 指標回到第1題
            numQuestionCorrect = 0 // 答對題數歸零
            displayQuestion() // 顯示問題
            
        } else if currentQuestionIndex < questions.count {
            displayQuestion() // 顯示問題
            
            /// 顯示問題之後，儲存答對題數和題目index
            StateManager.saveState(numCorrect: numQuestionCorrect, questionIndex: currentQuestionIndex)
        }
    }
}
