//
//  Question.swift
//  QuizApp
//
//  Created by Ewen on 2021/8/5.
//

import Foundation

struct Question: Codable {
    var questionName: String?
    var choices:[String]?
    var correctAnswerIndex: Int?
    var feedback: String?
}
