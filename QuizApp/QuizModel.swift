//
//  QuizModel.swift
//  QuizApp
//
//  Created by Ewen on 2021/8/5.
//

import Foundation

protocol QuizProtocol {
    func questionsRetrieved(_ questions:[Question])
}

class QuizModel {
    // 宣告 delegate 屬性（將是 ViewController）
    var delegate: QuizProtocol?
    
    /*
     抓題目的方法。
     若要利用 background thread 從網路抓題目，不知道要花多久，所以不能用 return 的方式傳資料給 ViewController。
     所以要用 delegate 屬性，搭配自訂 Protocol 的方法傳資料給 ViewController。
     
     在此我只實現如何抓本地 JSON file。
     若要抓遠端 JSON ，只需再寫一個新方法，並在 getQuestions() 呼叫它即可。
     */
    
    func getQuestions() {
        getLocalJsonFile()
    }
    
    func getLocalJsonFile() {
        // 得到 json file 的 bundle path，且保證 path 不為 nil
        guard let path = Bundle.main.path(forResource: "QuestionData", ofType: "json") else {
            print("Cannot find json file.")
            return
        }
        
        // 傳進 path，創造 URL 物件： url
        let url = URL(fileURLWithPath: path)
        
        do {
            // 從 url 取得 data
            let data = try Data(contentsOf: url)
            
            // 用 JSON Decoder 物件把 data decode 成 Question struct 物件陣列
            let array = try JSONDecoder().decode([Question].self, from: data)
            
            // delegate 使用 questionRetrieved() 方法得到題目、顯示題目
            delegate?.questionsRetrieved(array)
        }
        catch {
            print("無法從 url 取得 data")
        }
    }
}
