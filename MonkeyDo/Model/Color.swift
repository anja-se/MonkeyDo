//
//  Color.swift
//  MonkeyDo
//
//  Created by Anja Seidel on 11.09.23.
//

import Foundation

struct Color {
    static let colors = ["BlueColor", "PinkColor", "YellowColor", "PurpleColor", "MintColor"]
    
    static func getColor(without lastColor: String? = nil) -> String {
        let range = lastColor == nil ? 0...4 : 0...3
        let randomIndex = Int.random(in: range)
        
        if lastColor == nil {
            return Color.colors[randomIndex]
        } else {
            let colors = Color.colors.filter { $0 != lastColor }
            return colors[randomIndex]
        }
    }
}
