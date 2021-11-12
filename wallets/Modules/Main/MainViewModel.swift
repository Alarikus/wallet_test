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
    
    var coordinator: MainCoordinator
    let viewModelProvider: ViewModelProvider
    
    @Published var isPaginationAvailable = false
    @Published var requestsWithErrors: [Section]?
    var isRequestsWithDelayEnabled = false
    
    let dataProvider: WalletsDataProviderProtocol & HistoryDataProviderProtocol
    
    init(_ dataProvider: WalletsDataProviderProtocol & HistoryDataProviderProtocol,
         viewModelProvider: ViewModelProvider,
         coordinator: MainCoordinator) {
        self.viewModelProvider = viewModelProvider
        self.dataProvider = dataProvider
        self.coordinator = coordinator
        
        setupBindings()
    }
    
    func setupBindings() {
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(walletsDataProvider: dataProvider,
                                 historyDataProvider: dataProvider),
                Self.userInput(input: input.eraseToAnyPublisher())
            ])
            .assign(to: \.state, on: self)
            .store(in: &bindings)
        
        $state.receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                print("received state: \(String(describing: state))")
                
                switch state {
                case .transition(let history):
                    self.coordinator.openHistoryDetail(history: history)
                    
                case .loaded(_, let history, let page, let error):
                    if let history = history, !history.isEmpty, page == 1 {
                        self.isPaginationAvailable = true
                    }
                    
                    self.handleError(error, page: page ?? 1)
                    
                case .error(let error):
                    self.handleError(error)
                default:
                    break
                }
            }.store(in: &bindings)
        
        $requestsWithErrors.receive(on: RunLoop.main)
            .sink { [weak self] selectedRequests in
                guard
                    let self = self,
                    let requestsWithErrors = selectedRequests
                else { return }
                
                self.dataProvider.enableErrors(types: requestsWithErrors)
                self.send(event: .onReload)
            }.store(in: &bindings)
    }
    
    func send(event: Event) {
        print("send event: \(String(describing: event))")
        
        input.send(event)
    }
    
    private func handleError(_ error: DefinedError?, page: Int = 1) {
        if let error = error {
            if error == .pageNotFound {
                self.isPaginationAvailable = false
            } else if page == 1 {
                self.coordinator.showAlert(title: "Error", message: error.message)
            }
        }
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
        case loaded([Wallet]? = nil, [History]? = nil, page: Int? = nil, DefinedError? = nil)
        case error(DefinedError)
        case transition(History)
    }
    
    enum Event {
        case onLoadView
        case onReload
        case onLoaded(Result<[Wallet], AFError>, Result<[History], AFError>, Int)
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
            case .loading: return false
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
            return isLoadingAvailable ? .loading(page: 1) : .idle
            
        case .onLoaded(let wallets, let histories, let page):
            switch (wallets, histories) {
            case (.success(let wallets), .success(let histories)):
                return .loaded(wallets, histories, page: page)
                
            case (.success(let wallets), .failure(let error)):
                return .loaded(wallets, nil, page: page, DefinedError(from: error))
                
            case (.failure(let error), .success(let history)):
                return .loaded(nil, history, page: page, DefinedError(from: error))
                
            case (.failure(let error), .failure):
                
                return .error(DefinedError(from: error))
            }
            
        case .onLoadNextPage(let page):
            return isLoadingAvailable ? .loading(page: page + 1) : .idle
            
        case .onFailedToLoadData(let error):
            
            return .error(DefinedError(from: error))
        case .onSelectHistory(let selectedHistory):
            return isTransitionAvailable ? .transition(selectedHistory) : .idle
        }
    }
    
    static func whenLoading(walletsDataProvider: WalletsDataProviderProtocol,
                            historyDataProvider: HistoryDataProviderProtocol) -> Feedback<State, Event> {
        
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading(let page) = state else { return Empty().eraseToAnyPublisher() }
            
            typealias EventResult = Result<Any, AFError>
            
            let historyPublisher = historyDataProvider.historyPublisher(page: page)
                .map { Result<[History], AFError>.success($0.data) }
                .catch { Just(Result<[History], AFError>.failure($0)) }
            
            let walletsPublisher =  walletsDataProvider.walletsPublisher()
                .map { Result<[Wallet], AFError>.success($0.wallets) }
                .catch { Just(Result<[Wallet], AFError>.failure($0)) }
            
            let combinedPublisher = walletsPublisher.combineLatest(historyPublisher)
                .tryMap { Event.onLoaded($0, $1, page) }
                .eraseToAnyPublisher()
                .catch { Just(Event.onFailedToLoadData($0.asAFError(orFailWith: "Test message"))) }
                .eraseToAnyPublisher()
            
            return combinedPublisher
        }
    }
    
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
