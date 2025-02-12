//
//  GlobalViewModel.swift
//  Real app
//
//  Created by Harikrishnan V on 2025-02-07.
//

import Foundation
import Observation

@Observable
class GlobalViewModel {
    var selectedCoin: UserHolding = UserHolding(email: "", coin: CoinDetails(id: 1, coinName: "Bitcoin", coinSymbol: "BTCUSDT", imageUrl: ""), quantity: 2)
    var selectedUser: User = User(email: " ", username: "", password: "" , profilePicture: "")
    
    var session: User = User(email: " ", username: "Krishnan", password: "" , profilePicture: "")
    
    var wsManager = WebSocketManager()
}


