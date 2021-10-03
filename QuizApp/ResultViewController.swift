//
//  ResultViewController.swift
//  QuizApp
//
//  Created by Ewen on 2021/8/5.
//

import UIKit

protocol ResultViewControllerProtocol {
    func dialogDismissed()
}

class ResultViewController: UIViewController {
    var resultTitleText: String!
    var feedbackText: String!
    var buttonText: String!
    
    // 宣告 ResultViewController 的 delegate（將是 view controller）
    var delegate: ResultViewControllerProtocol?
    
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var dialogView: UIView!
    @IBOutlet weak var resultTitleLabel: UILabel!
    @IBOutlet weak var feedbackTextView: UITextView!
    @IBOutlet weak var nextButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        dialogView.layer.cornerRadius = 10
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //顯示
        resultTitleLabel.text = resultTitleText
        feedbackTextView.text = feedbackText
        nextButton.setTitle(buttonText, for: .normal)
        
        /// 先隱藏 UI 元件
        dimView.alpha = 0
        resultTitleLabel.alpha = 0
        feedbackTextView.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        /// 淡入元件
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.dimView.alpha = 1
            self.resultTitleLabel.alpha = 1
            self.feedbackTextView.alpha = 1
        }, completion: nil)
    }
    
    
    @IBAction func nextTapped(_ sender: Any) {
        /// 淡出元件
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
            self.dimView.alpha = 0
        }) { completed in
            self.dismiss(animated: true, completion: nil)
            self.delegate?.dialogDismissed()
        }
    }
}


