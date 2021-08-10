//
//  ViewController.swift
//  QuizApp
//
//  Created by Ewen on 2021/8/5.
//

import UIKit

class ViewController: UIViewController, QuizProtocol, UITableViewDelegate, UITableViewDataSource, ResultViewControllerProtocol {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var questionImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!

    // For Animation
    @IBOutlet weak var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rootStackView: UIStackView!
    
    
    var model = QuizModel()
    var questions = [Question]()
    
    // 目前在第幾題
    var currentQuestionIndex = 0
    // 目前答對題數
    var numQuestionCorrect = 0
    
    // 宣告 resultDialogVC
    var resultDialogVC: ResultViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //畫漸層背景
        createGradientBackground()
        
        // 設定 ViewController 為 tableView 的 delegate 和 dataSource
        tableView.delegate = self
        tableView.dataSource = self
        
        // 遇到 cell 沒有因應文字變多而自動變高的解決方法
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
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
        // 吃到問題的圖片
        questionImageView.image = UIImage(imageLiteralResourceName: "\(currentQuestionIndex+1)")
        
        // 吃到問題的 text
        questionLabel.text = questions[currentQuestionIndex].questionName
        
        // table view 重新載入資料
        tableView.reloadData()
        
        /// slide in the questions
        slideInQuestion()
    }
    
    
    // MARK: - QuizProtocol Methods
    func questionsRetrieved(_ questions: [Question]) {
        
        print("收到題目！")
        
        // ViewController 的 questions 屬性接收參數的陣列
        self.questions = questions
        
        /// 檢查是否有已儲存的 savedIndex, savedNumCorrect
        let savedIndex = StateManager.retrieveValue(key: StateManager.questionIndexKey) as? Int
        if savedIndex != nil, savedIndex! < self.questions.count {
            // 設定問題指標為儲存的 savedIndex
            currentQuestionIndex = savedIndex!
        }
        let savedNumCorrect = StateManager.retrieveValue(key: StateManager.numCorrectKey) as? Int
        if savedNumCorrect != nil {
            // 設定已答對題數為儲存的 savedNumCorrect
            numQuestionCorrect = savedNumCorrect!
        }
        
        // 顯示問題
        displayQuestion()
    }
    
    // MARK: - UITableViewDelegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // 確保 questions 陣列至少包含一個 Question
        guard questions.count > 0 else {
            return 0
        }
        
        // return 這個問題的 choices 數
        let currentQuestion = questions[currentQuestionIndex]
        
        if currentQuestion.choices != nil {
            return currentQuestion.choices!.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 獲得 cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChoiceCell", for: indexPath)
        
        // Label Tag 為 1 的 cell 轉型成 label
        let label = cell.viewWithTag(1) as? UILabel
        
        // 設定標籤的選項文字
        if label != nil {
            let question = questions[currentQuestionIndex]
            if question.choices != nil && indexPath.row < question.choices!.count {
                label!.text = question.choices![indexPath.row]
            }
        }
        
        // return cell
        return cell
    }
    
    // MARK: - UITableViewDatasource Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var titleText = ""
        let question = questions[currentQuestionIndex]
        
        // 使用者點到一個 row，檢查是否為正解
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
                    
        // resultDialogVC 的 properties 們被傳入資料
        resultDialogVC?.resultTitleText = titleText
        resultDialogVC?.feedbackText = question.feedback
        
        if currentQuestionIndex == questions.count - 1 {
            resultDialogVC?.buttonText = "查看結果"
        } else if currentQuestionIndex < questions.count - 1 {
            resultDialogVC?.buttonText = "下一題"
        }
        
        // Show the popup
        DispatchQueue.main.async {
            self.present(self.resultDialogVC!, animated: true, completion: nil)
        }
    }
    
    // MARK: - ResultViewControllerProtocol Methods
    func dialogDismissed() {
        
        // 題目指標 + 1
        currentQuestionIndex += 1
        
        if currentQuestionIndex == questions.count {
            // 沒下一題了
            
            // resultDialogVC 的 properties 們被傳入資料
            resultDialogVC?.resultTitleText = "測驗結果"
            resultDialogVC?.feedbackText = "您在 \(questions.count) 題中，答對了 \(numQuestionCorrect) 題。總分為 \(numQuestionCorrect * 5) 分。"
            resultDialogVC?.buttonText = "再玩一次"
                
            // 顯示總結對話窗
            present(resultDialogVC!, animated: true, completion: nil)
            
            /// 跳出總結對話窗後，清除已儲存狀態
            StateManager.clearState()
            
        } else if currentQuestionIndex > questions.count {
            // 在總結對話窗按"Restart"之後，要回到第一題
            
            // 指標回到第1題
            currentQuestionIndex = 0
            // 答對題數歸零
            numQuestionCorrect = 0
            // 顯示問題
            displayQuestion()
            
        } else if currentQuestionIndex < questions.count {
            // 顯示問題
            displayQuestion()
            
            /// 顯示問題之後，儲存答對題數和題目index
            StateManager.saveState(numCorrect: numQuestionCorrect, questionIndex: currentQuestionIndex)
        }
    }
}
