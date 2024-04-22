//
//  ViewModel.swift
//  TestingTreeYo
//
//  Created by Matthew Rispler on 9/4/2024.
//

import Foundation
import Observation

enum FlowState {
    case idle
    case intro
    case projectileFlying
}

@Observable
class ViewModel {

    var flowState = FlowState.idle

}
