//
//  HomeViewController.swift
//  QuizApp
//
//  Created by Ewen on 2021/8/8.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()        
    }
    
    @IBAction func startGame() {
        let vc = storyboard?.instantiateViewController(identifier: "view") as! ViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
}
