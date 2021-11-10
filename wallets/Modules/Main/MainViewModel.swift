//
//  MainViewModel.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import Foundation
import Combine
import Alamofire

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
        case loaded(wallets: [Wallet]? = nil, history: [History]? = nil, page: Int? = nil)
        case error(DefinedError)
        case transition(History)
    }
    
    enum Event {
        case onLoadView
        case onAppear
        case onReload
        case onLoaded([Wallet], [History], Int)
        case onLoadNextPage(page: Int)
        case onFailedToLoadData(AFError)
        case onSelectHistory(History)
    }
    
}

// MARK: - State Machine
extension MainViewModel {
    static func reduce(_ state: State, _ event: Event) -> State {
        var isLoadingAvailable: Bool {
            switch state {
            case .loading, .error, .transition: return false
            default: return true
            }
        }
        
        var isTransitionAvailable: Bool {
            switch state {
            case .transition: return false
            default: return true
            }
        }
        
        switch event {
        case .onLoadView, .onReload:
            return isLoadingAvailable ? .loading(page: 1) : .loaded()
            
        case .onAppear:
            return .loaded()
            
        case .onLoaded(let wallets, let histories, let page):
            return .loaded(wallets: wallets, history: histories, page: page)
            
        case .onLoadNextPage(let page):
            return isLoadingAvailable ? .loading(page: page + 1) : .loaded()
            
        case .onFailedToLoadData(let error):
            
            if let myError = error.underlyingError as? DefinedError {
                print("myError: \(myError)")
                return .error(myError)
            }
            
            return .error(.unknown)
        case .onSelectHistory(let selectedHistory):
            return isTransitionAvailable ? .transition(selectedHistory) : .loaded()
        }
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
