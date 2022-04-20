//
//  FaceCounterViewModel.swift
//  FaceDetection
//
//  Created by J on 2022-04-19.
//

import Foundation
import Combine

final class FaceCounterViewModel {
    private struct State {
        var counter: Int = 0
    }

    enum Action {
        case initialize
        case updateCounter(numberOfFaces: Int)
        case counterError
    }
    
    enum StateEffect {
        case initialized
        case updateCounter(numberOfFaces: Int)
    }

    var stateEffectSubject = CurrentValueSubject<StateEffect, Never>(.initialized)
    var actionSubject = PassthroughSubject<Action, Never>()

    private var state = State()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupCancellables()
    }

    private func setupCancellables() {
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
                
                self.stateEffectSubject.send(
                    .updateCounter(numberOfFaces: self.state.counter)
                )
            }
            .store(in: &cancellables)
    }
}
