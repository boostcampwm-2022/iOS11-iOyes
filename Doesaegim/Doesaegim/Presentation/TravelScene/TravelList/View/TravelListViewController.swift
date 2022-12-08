//
//  TravelPlanViewController.swift
//  Doesaegim
//
//  Created by Jaehoon So on 2022/11/11.
//

import UIKit


import SnapKit

final class TravelListViewController: UIViewController {

    private typealias DataSource
    = UICollectionViewDiffableDataSource<String, TravelInfoViewModel>
    private typealias SnapShot
    = NSDiffableDataSourceSnapshot<String, TravelInfoViewModel>
    private typealias CellRegistration
    = UICollectionView.CellRegistration<TravelListCell, TravelInfoViewModel>
    
    // MARK: - Properties
    
    private let placeholdLabel: UILabel = {
        let label = UILabel()
        label.text = "새로운 여행을 떠나볼까요?"
        label.textColor = .grey2
        
        return label
    }()
    
    private lazy var planCollectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        configuration.trailingSwipeActionsConfigurationProvider = makeSwipeActions
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.layer.cornerRadius = 12
        return collectionView
        
    }()
    
    private var travelDataSource: DataSource?
    
    private var viewModel: TravelListViewModelProtocol? = TravelListViewModel()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        planCollectionView.delegate = self
        viewModel?.delegate = self
        
        configureSubviews()
        configureConstraints()
        configureNavigationBar()
        configureCollectionViewDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.fetchTravelInfo()
    }
    
    // MARK: - Configure
    
    func configureSubviews() {
        view.addSubview(planCollectionView)
        view.addSubview(placeholdLabel)
    }
    
    func configureConstraints() {
        
        placeholdLabel.snp.makeConstraints {
            $0.centerX.equalTo(view.snp.centerX)
            $0.centerY.equalTo(view.snp.centerY)
        }
        
        planCollectionView.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.equalTo(view.snp.leading).offset(16)
            $0.trailing.equalTo(view.snp.trailing).offset(-16)
        }
        
    }
    
    func configureNavigationBar() {
        
        navigationController?.navigationBar.tintColor = .primaryOrange
        navigationItem.title = "여행 목록"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didAddTravelButtonTap)
        )
    }
    
    // MARK: - Configure CollectionView
    
    private func configureCollectionViewDataSource() {
        let travelCell = CellRegistration { cell, indexPath, identifier in

            cell.configureContent(with: identifier)
            
            if let viewModel = self.viewModel,
               viewModel.travelInfos.count >= 10,
               indexPath.row == viewModel.travelInfos.count - 1 {
                DispatchQueue.main.async {
                    viewModel.fetchTravelInfo()
                }
            }
            
        }
        
        travelDataSource = DataSource(
            collectionView: planCollectionView,
            cellProvider: { collectionView, indexPath, item in
                return collectionView.dequeueConfiguredReusableCell(
                    using: travelCell,
                    for: indexPath,
                    item: item)
            })
    }
    
    // MARK: - Actions
    
    @objc func didAddTravelButtonTap() {
        // 여행 추가 뷰컨트롤러 이동
        navigationController?.pushViewController(TravelAddViewController(), animated: true)
    }
}

// MARK: - TravelListControllerDelegate

extension TravelListViewController: TravelListViewModelDelegate {
    func travelListSnapshotShouldChange() {
        
        guard let viewModel = viewModel else {
            return
        }
        
        print("Travel List - Snapshot 재적용")
        
        let travelInfos = viewModel.travelInfos
        var snapshot = SnapShot()
        
        snapshot.appendSections(["main section"])
        snapshot.appendItems(travelInfos)
        travelDataSource?.apply(snapshot, animatingDifferences: true)

        
    }
    
    func travelPlaceholderShouldChange() {
        
        guard let viewModel = viewModel else {
            return
        }
        
        let travelInfos = viewModel.travelInfos
        if travelInfos.isEmpty {
            placeholdLabel.isHidden = false
        } else {
            placeholdLabel.isHidden = true
        }
    }
    
    func travelListDeleteDataDidFail() {
        let alert = UIAlertController(
            title: "삭제 실패",
            message: "여행정보를 삭제하기를 실패하였습니다",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "확인", style: .default)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func travelListFetchDidFail() {
        let alert = UIAlertController(
            title: "로드 실패",
            message: "여행정보 불러오기를 실패하였습니다",
            preferredStyle: .alert
        )
        let alertAction = UIAlertAction(title: "확인", style: .default)
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDelegate

extension TravelListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let travelViewModel = travelDataSource?.itemIdentifier(for: indexPath)
        else {
            return
        }
        let result = PersistentManager.shared.fetch(request: Travel.fetchRequest())
        switch result {
        case .success(let response):
            guard let travel = response.first(where: { $0.id == travelViewModel.uuid }) else {
                return
            }
            let planListViewModel = PlanListViewModel(
                travel: travel,
                repository: PlanLocalRepository()
            )
            let planListViewController = PlanListViewController(viewModel: planListViewModel)
            planListViewModel.delegate = planListViewController
            show(planListViewController, sender: nil)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}

extension TravelListViewController {
    
    private func deleteTravel(with travelInfo: TravelInfoViewModel) {
        let uuid = travelInfo.uuid
        viewModel?.deleteTravel(with: uuid)
    }
    
    private func makeSwipeActions(for indexPath: IndexPath?) -> UISwipeActionsConfiguration? {
        guard let indexPath = indexPath,
              let id = travelDataSource?.itemIdentifier(for: indexPath) else { return nil }
        
        let deleteActionTitle = NSLocalizedString("삭제", comment: "여행 목록 삭제")
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: deleteActionTitle
        ) { [weak self] _, _, completion in
            self?.deleteTravel(with: id)
            // 원래는 스냅샷 업데이트 메서드를 호출해주지만 뷰모델에서 Travel배열의 변화를 감지하면 자동으로 호출하므로 불필요
            completion(false)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    

}
