//
//  MainViewModel.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import Foundation
import Combine

final class MainViewModel {
    @Published private(set) var state: State = State.idle
    
    private var bindings = Set<AnyCancellable>()
    
    private let input = PassthroughSubject<Event, Never>()
            
    var viewModelProvider: ViewModelProvider
        
    init(_ dataProvider: WalletsDataProviderProtocol & HistoryDataProviderProtocol,
         viewModelProvider: ViewModelProvider) {
        self.viewModelProvider = viewModelProvider
        
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(walletsDataProvider: dataProvider,
                                 historyDataProvider: dataProvider),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bindings)
    }
    
    func send(event: Event) {
        switch event {
        case .onLoadNextPage:
            switch state {
            case .loading(let page), .loaded(_, _, let page):
                input.send(.onLoadNextPage(page: page + 1))
                return
            default: break
            }
        default: break
        }
        
        input.send(event)
    }
    
}

extension MainViewModel {
    
    enum Section: String {
        case wallets = "My Wallets"
        case history = "History"
    }
    
    enum Row: Hashable {        
        case wallet(Wallet)
        case history(History)
    }
    
    enum State {
        case idle
        case loading(page: Int)
        case loaded(wallets: [Wallet], history: [History], page: Int)
        case error(Error)
        case transition(History)
    }
    
    enum Event {
        case onLoadView
        case onReload
        case onLoaded([Wallet], [History], Int)
        case onLoadNextPage(page: Int = 1)
        case onFailedToLoadData(Error)
        case onSelectHistory(History)
    }
    
}

// MARK: - State Machine
extension MainViewModel {
    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle:
            switch event {
            case .onLoadView, .onReload:
                return .loading(page: 1)
            default: break
            }
        case .loading:
            switch event {
            case .onFailedToLoadData(let error):
                return .error(error)
            case .onLoaded(let wallets, let history, let page):
                return .loaded(wallets: wallets, history: history, page: page)
            default: break
            }
        case .loaded:
            switch event {
            case .onLoadNextPage(let page):
                return .loading(page: page)
            case .onReload:
                return .loading(page: 1)
            case .onSelectHistory(let selectedHistory):
                return .transition(selectedHistory)
            default: break
            }
        case .error:
            switch event {
            case .onReload:
                return .loading(page: 1)
            default: break
            }
        case .transition: break
        }
        return state
    }
    
    static func whenLoading(walletsDataProvider: WalletsDataProviderProtocol,
                            historyDataProvider: HistoryDataProviderProtocol) -> Feedback<State, Event> {
        
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading(let page) = state else { return Empty().eraseToAnyPublisher() }
            
            let historyPublisher = historyDataProvider.historyPublisher(page: page)
                .map { $0.data }
            
            let walletsPublisher =  walletsDataProvider.walletsPublisher()
                .map { $0.wallets }
            
            let combinedPublisher = walletsPublisher.combineLatest(historyPublisher)
                .compactMap { Event.onLoaded($0, $1, page) }
                .eraseToAnyPublisher()
                .catch { Just(Event.onFailedToLoadData($0)) }
                .eraseToAnyPublisher()
            
            return combinedPublisher
        }
    }
        
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
