//
//  HistoryViewController.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import UIKit
import Cartography
import Combine

class HistoryDetailViewController: UIViewController {

    var viewModel: HistoryDetailViewModel!
    private var bindings = Set<AnyCancellable>()
    
    let backButton = UIButton()
    @Published var backButtonPublisher: AnyPublisher<UIControl, Never>!

    private lazy var stackView = UIStackView()
    private lazy var titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBindings()
        viewModel.onLoadView()
        setUpUI()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    private func setUpUI() {
        self.title = "History Details"
        view.backgroundColor = UIColor.systemBackground
        view.addSubview(stackView)
        view.addSubview(backButton)
        
        constrain(stackView, backButton) { stackView, backButton in
            stackView.top == stackView.superview!.safeAreaLayoutGuide.top + 45
            stackView.left == stackView.superview!.left + 30
            stackView.right == stackView.superview!.right - 30
            stackView.height == 320
            
            backButton.left == stackView.left
            backButton.right == stackView.right
            backButton.bottom == backButton.superview!.safeAreaLayoutGuide.bottom - 30
            backButton.height == 50
        }
        
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.spacing = 12
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline).withSize(20)
        titleLabel.textAlignment = .left
        stackView.addArrangedSubview(titleLabel)
        
        let detailsHeader = UILabel()
        detailsHeader.font = UIFont.preferredFont(forTextStyle: .headline).withSize(18)
        detailsHeader.textAlignment = .left
        detailsHeader.text = "Details:"
        stackView.addArrangedSubview(detailsHeader)
        
        backButton.configuration = UIButton.Configuration.borderedTinted()
        backButton.tintColor = .label
        backButton.setTitleColor(.label, for: .normal)
        backButton.setTitle("Back", for: .normal)
    }
    
    private func generateDetailStackView(key: String, value: String) -> UIStackView {
        let keyLabel = UILabel()
        keyLabel.font = UIFont.systemFont(ofSize: 17)
        keyLabel.textAlignment = .left
        keyLabel.text = key
        
        let valueLabel = UILabel()
        valueLabel.font = UIFont.boldSystemFont(ofSize: 17)
        valueLabel.textAlignment = .right
        valueLabel.text = value
        
        let stackView = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
        stackView.distribution = .fillProportionally
        stackView.alignment = .fill
        stackView.axis = .horizontal
        stackView.spacing = 12
        
        return stackView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    private func setUpBindings() {
        func bindViewToViewModel() {
            viewModel.$title
                .combineLatest(viewModel.$details)
                .receive(on: DispatchQueue.main)
                .sink { [unowned self] title, details in
                    
                    self.titleLabel.text = title
                    for (key, value) in details ?? [:] {
                        let stack = self.generateDetailStackView(key: key, value: value)
                        self.stackView.addArrangedSubview(stack)
                    }
                }.store(in: &bindings)
        }
        
        self.backButtonPublisher = self.backButton.publisher(for: .touchUpInside).eraseToAnyPublisher()
        
        bindViewToViewModel()
    }

}
