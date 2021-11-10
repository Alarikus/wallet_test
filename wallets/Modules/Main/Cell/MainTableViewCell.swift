//
//  MainTableViewCell.swift
//  wallets
//
//  Created by Bogdan Redkin on 10.11.2021.
//

import UIKit
import Combine
import Cartography

final class MainTableViewCell: UITableViewCell {

    var viewModel: MainTableCellViewModel! {
        didSet {
            self.setupBindings()
        }
    }
    
    private lazy var stackView = UIStackView()
    private lazy var descriptionLabel = UILabel()
    private lazy var currencyLabel = UILabel()
    
    private var bindings = Set<AnyCancellable>()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        setupUI()
    }
    
    init(viewModel: MainTableCellViewModel) {
        super.init(style: .default, reuseIdentifier: MainTableCellViewModel.cellIdentifier)
        
        self.viewModel = viewModel
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(stackView)
        constrain(stackView) { stackView in
            stackView.edges == inset(stackView.superview!.edges, 2, 12, 2, 12)
        }
        
        descriptionLabel.font = self.textLabel?.font
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.minimumScaleFactor = 0.7
        stackView.addArrangedSubview(descriptionLabel)
        
        currencyLabel.font = UIFont.boldSystemFont(ofSize: descriptionLabel.font.pointSize)
        currencyLabel.textAlignment = .right
        currencyLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        currencyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.addArrangedSubview(currencyLabel)
        
        stackView.distribution = .fillProportionally
        stackView.alignment = .fill
        stackView.axis = .horizontal
        stackView.spacing = 12
    }
    
    private func setupBindings() {
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.descriptionLabel.text = self?.viewModel.description
                self?.currencyLabel.text = self?.viewModel.amount
            }.store(in: &bindings)
        
        viewModel.objectWillChange.send()
    }
    
    override func prepareForReuse() {
        descriptionLabel.text = nil
        currencyLabel.text = nil
        super.prepareForReuse()
    }
}
