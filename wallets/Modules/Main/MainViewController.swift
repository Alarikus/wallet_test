//
//  ViewController.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import UIKit
import Alamofire
import Combine
import Cartography

final class MainViewController: UITableViewController {
    
    private class DataSource: UITableViewDiffableDataSource<MainViewModel.Section, MainViewModel.Row> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return self.snapshot().sectionIdentifiers[section].rawValue
        }

    }
    
    private typealias Snapshot = NSDiffableDataSourceSnapshot<MainViewModel.Section, MainViewModel.Row>

    var viewModel: MainViewModel!
    
    private var bindings = Set<AnyCancellable>()
    private var dataSource: DataSource!
    
    private lazy var footerActivityIndicator = UIActivityIndicatorView(style: .large)
    private lazy var backgroundActivityIndicator = UIActivityIndicatorView(style: .large)
    
    private var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        
        self.title = "Main"
        setUpTableView()
        setUpBindings()

        viewModel.send(event: .onLoadView)
    }
    
    private func setUpTableView() {
        tableView.register(MainTableViewCell.self, forCellReuseIdentifier: MainTableCellViewModel.cellIdentifier)
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.alwaysBounceVertical = true
        
        backgroundActivityIndicator.startAnimating()
        backgroundActivityIndicator.hidesWhenStopped = true
        tableView.backgroundView = backgroundActivityIndicator
        
        footerActivityIndicator.hidesWhenStopped = true
        
        dataSource = DataSource(tableView: tableView, cellProvider: { [weak self] tableView, _, item in
            
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MainTableCellViewModel.cellIdentifier) as? MainTableViewCell
            
            var cellViewModel: MainTableCellViewModel?
            
            switch item {
            case .wallet(let wallet):
                cellViewModel = self?.viewModel.viewModelProvider.mainCellViewModel(wallet: wallet)
            case .history(let history):
                cellViewModel = self?.viewModel.viewModelProvider.mainCellViewModel(history: history)
            }
            
            guard let cell = cell, let viewModel = cellViewModel else { return cell ?? UITableViewCell() }
            
            cell.viewModel = viewModel
           
            return cell
        })
    }
    
    private func setUpBindings() {
        func bindViewToViewModel() {
            viewModel.$state.sink { [weak self] state in
                guard let self = self else { return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() +
                                              (self.viewModel.isRequestsWithDelayEnabled ? 5.0 : 0)) {
                    switch state {
                    case .loaded(let wallets, let history, let page, let err):
                        self.processLoadedData(wallets, history, page: page, err)
                        
                    case .error(let error):
                        self.isLoading = false
                        self.footerActivityIndicator.stopAnimating()
                        
                        guard error != .pageNotFound else { return }
                        var snapshot = Snapshot()
                        snapshot.appendSections([.wallets, .history])
                        self.dataSource.applySnapshotUsingReloadData(snapshot) {
                            self.refreshControl?.endRefreshing()
                        }
                    default:
                        break
                    }
                }
            }.store(in: &bindings)
            
            viewModel.$isPaginationAvailable
                .receive(on: DispatchQueue.main)
                .sink { isPaginationAvailable in
                    if !isPaginationAvailable {
                        self.footerActivityIndicator.removeFromSuperview()
                    }
                }.store(in: &bindings)
        }
        
        func bindModelToView() {
            refreshControl?
                .publisher(for: .valueChanged)
                .sink(receiveValue: { [weak self] _ in
                    self?.viewModel.send(event: .onReload)
                    self?.refreshControl?.beginRefreshing()
                }).store(in: &bindings)
        }
        
        bindModelToView()
        bindViewToViewModel()
    }
        
    private func processLoadedData(_ wallets: [Wallet]?, _ histories: [History]?, page: Int?, _ error: DefinedError?) {
        var snapshot = self.dataSource.snapshot()
                
        guard let page = page else { return }
        
        self.backgroundActivityIndicator.stopAnimating()
        isLoading = false
        self.footerActivityIndicator.stopAnimating()
        
        if page == 1 {
            snapshot = Snapshot()
            if let wallets = wallets {
                snapshot.appendSections([.wallets])
                snapshot.appendItems(wallets.map({ MainViewModel.Row.wallet($0) }), toSection: .wallets)
            }
            
            if let history = histories {
                snapshot.appendSections([.history])
                snapshot.appendItems(history.map({ MainViewModel.Row.history($0) }), toSection: .history)
            }
            
            self.dataSource.applySnapshotUsingReloadData(snapshot) {
                self.refreshControl?.endRefreshing()
            }
        } else if let histories = histories {
            snapshot.appendItems(histories.map({ MainViewModel.Row.history($0) }), toSection: .history)
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
}

extension MainViewController {
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard
            let header = view as? UITableViewHeaderFooterView,
            let currentFontSize = header.textLabel?.font.pointSize
        else { return }
        
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: (currentFontSize * 1.2).rounded())
    }
        
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
        
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard
            self.dataSource.snapshot().sectionIdentifiers.contains(.history),
                viewModel.isPaginationAvailable
        else { return }

        let historiesCount = dataSource.snapshot().numberOfItems(inSection: .history)

        if scrollView.contentOffset.y < 0 {
            return
        } else if scrollView.contentOffset.y >= (scrollView.contentSize.height - view.bounds.size.height) &&
                    isLoading == false &&
                    viewModel.isPaginationAvailable {
            isLoading = true
            viewModel.send(event: .onLoadNextPage(page: Int(historiesCount/8)))
            footerActivityIndicator.startAnimating()
        }
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let items = self.dataSource.snapshot().itemIdentifiers(inSection: .history)
        guard indexPath.section == 1,
              indexPath.row < items.count
        else { return }
        
        let selectedHistory = items[indexPath.row]
        switch selectedHistory {
        case .history(let selectedHistory):
            viewModel.send(event: .onSelectHistory(selectedHistory))
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard (section == 1 && dataSource.snapshot().numberOfSections == 2) ||
                (section == 0 && dataSource.snapshot().numberOfSections == 1),
                viewModel.isPaginationAvailable else { return nil }
        let footerView = UIView(frame: .zero)
        footerView.backgroundColor = .clear
        
        footerView.addSubview(footerActivityIndicator)
        constrain(footerActivityIndicator, footerView) { activityIndicator, root in
            activityIndicator.center == root.center
        }
        
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard (section == 1 && dataSource.snapshot().numberOfSections == 2) ||
                (section == 0 && dataSource.snapshot().numberOfSections == 1),
                viewModel.isPaginationAvailable else { return super.tableView(tableView, heightForFooterInSection: section) }
        
        return viewModel.isPaginationAvailable ? 70 : 0
    }
    
}
