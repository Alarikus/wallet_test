//
//  ViewController.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import UIKit
import Alamofire
import Combine

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
    
    private lazy var footerActivityIndicator = UIActivityIndicatorView()
    
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
        tableView.isPrefetchingEnabled = true
        tableView.prefetchDataSource = self
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.alwaysBounceVertical = true
        
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
                
                switch state {
                case .loaded(let wallets, let history, let page):
                    var snapshot = self.dataSource.snapshot()
                    if page == 1 {
                        snapshot = Snapshot()
                        snapshot.appendSections([.wallets, .history])
                        snapshot.appendItems(wallets.map({ MainViewModel.Row.wallet($0) }), toSection: .wallets)
                        snapshot.appendItems(history.map({ MainViewModel.Row.history($0) }), toSection: .history)
                        self.dataSource.applySnapshotUsingReloadData(snapshot) {
                            self.refreshControl?.endRefreshing()
                        }
                    } else {
                        snapshot.appendItems(history.map({ MainViewModel.Row.history($0) }), toSection: .history)
                        self.dataSource.apply(snapshot, animatingDifferences: true)
                    }
                    self.footerActivityIndicator.stopAnimating()
                case .error(let error):
                    print(error)
                    self.footerActivityIndicator.stopAnimating()
                default:
                    break
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
    
}

extension MainViewController: UITableViewDataSourcePrefetching {
    
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
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: {
            $0.row > dataSource.snapshot().numberOfItems(inSection: .history) - 2 && $0.section == 1
        }) {
            viewModel.send(event: .onLoadNextPage())
            self.footerActivityIndicator.startAnimating()
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
        guard section == 1 else { return nil }
        footerActivityIndicator.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50)
        return footerActivityIndicator
    }
    
}
