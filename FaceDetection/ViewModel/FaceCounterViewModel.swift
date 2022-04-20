//
//  FaceCounterViewModel.swift
//  FaceDetection
//
//  Created by J on 2022-04-19.
//

/*
 Abstract:
 A view model that binds the state and the view on a view controller. Receives values through Combine's PassthroughSubject and executes tasks accordingly, ultimately sending a message back to
 the view controller using CurrentValueSubject.
 */

import Foundation
import Combine

final class FaceCounterViewModel {
    /// Counter represents the number of faces currently detected
    private struct State {
        var counter: Int = 0
    }

    /// Action created by a view controller
    enum Action {
        case initialize /// When a view controller is newly loaded
        case updateCounter(numberOfFaces: Int) /// Number of face detected by a camera
        case counterError /// Detection error
    }
    
    /// The resulting state from the action to be reflected in the UI
    enum StateEffect {
        case initialized /// When a view controller is newly loaded, the UI will reflect 0 face detected
        case updateCounter(numberOfFaces: Int) /// The number of face detected by a camera will be showned on  the UILabel
    }

    /// Value only has to be passed once per state change
    var stateEffectSubject = CurrentValueSubject<StateEffect, Never>(.initialized)
    /// Continuous action execution depending on the number of face detected
    var actionSubject = PassthroughSubject<Action, Never>()

    private var state = State()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupCancellables()
    }

    private func setupCancellables() {
        /// Listens to the actions sent by the view controller
        actionSubject
            .sink { [weak self] action in
                guard let self = self else { return }

                switch action {
                case .initialize:
                    self.state.counter = 0
                case .updateCounter(let num):
                    self.state.counter = num
                case .counterError:
                    self.state.counter = 0
                }
                
                /// Send the number of face currently detected to the view controller for the UI
                self.stateEffectSubject.send(
                    .updateCounter(numberOfFaces: self.state.counter)
                )
            }
            .store(in: &cancellables)
    }
}
