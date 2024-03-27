//
//  BrowserLocalVC.swift
//  HashCamera
//
//  Created by WG-MacHome on 12/6/23.
//

import UIKit
import SnapKit
import RxSwift
import RxRelay
import Combine
import SwiftUI

class BrowserLocalVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate , UICollectionViewDelegateFlowLayout{
    
    
    let browserModel = FileBrowserModel(storageType: .localDrive)
    var disposeBag = DisposeBag()
    var cancellable = Set<AnyCancellable>()
    
    let containerStackView: UIStackView = UIStackView()
    let collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    ///NavigationBar > 사진 복수 선택 기능 on/off 버튼
    let selectionModeBtn: UIBarButtonItem = UIBarButtonItem(title: "선택", style: .plain, target: nil, action: nil)
    ///사진 복수 선택 기능 on 상태 여부
    let isSelecting = BehaviorRelay(value: false)
    let toolbar = BrowserToolBar()
    let toolbarBtmColorView = UIView()

    
    lazy var itemSize: CGSize =  {
        let itemLength = UIScreen.main.bounds.width / 3
        return CGSize(width: itemLength, height: itemLength)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initNavi()
        initView()
        initData()
    }
    
    
    ///네비게이션바를 초기 설정한다.
    func initNavi() {
        
        let backBtn = UIBarButtonItem.init(image: UIImage(systemName: "chevron.left")?.withTintColor(.black, renderingMode: .alwaysOriginal),
                                           style: .plain,
                                           target: nil,
                                           action: nil)
        self.navigationItem.title = "Local Folder"
        self.navigationItem.leftBarButtonItem = backBtn
        self.navigationItem.rightBarButtonItem = selectionModeBtn
        self.navigationController?.navigationBar.isHidden = false
        
        
        backBtn.rx.tap.bind { [weak self] _ in
            self?.movePrevVC(animated: true)
        }.disposed(by: disposeBag)
        
        isSelecting.bind {[weak self] isOn in
            self?.setSelectionMode(isOn) //사진 복수 선택 기능 on/off에 따라 UI 및 기능 변경
        }.disposed(by: disposeBag)
        
        selectionModeBtn.rx.tap.debug().bind(onNext: { [weak self] in
            guard let self else { return }
            let oldValue = isSelecting.value
            isSelecting.accept(!oldValue) //사진 복수 선택 기능 FLAG on/off 반전
        }).disposed(by: disposeBag)
        
       
    }
    
    ///뷰들을 초기설정한다.
    func initView() {
        
        view.backgroundColor = .white
        
        //콜렉션뷰
        if let collectionLayout = collectionView.collectionViewLayout as?  UICollectionViewFlowLayout {
            collectionLayout.scrollDirection = .vertical
            collectionLayout.minimumLineSpacing = .zero
            collectionLayout.minimumInteritemSpacing = .zero
        }
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UINib(nibName: "\(BrowserItemCell.self)",
                                      bundle: nil),
                                forCellWithReuseIdentifier: "\(BrowserItemCell.self)")
        
    
        //공유,삭제 툴바
        toolbar.leftItem.rx.tap.bind { [weak self] in
            guard let self else { return }
            if let selectedIndices:[Int] = collectionView.indexPathsForSelectedItems?.map({ $0.item }) {
                shareFiles(selectedIndices)
            }
            
        }.disposed(by: disposeBag)
        
        toolbar.rightItem.rx.tap.bind { [weak self] in
            guard let self else { return }
            if let selectedIndices:[Int] = collectionView.indexPathsForSelectedItems?.map({ $0.item }) {
                deleteFiles(selectedIndices)
            }
            
        }.disposed(by: disposeBag)
        
        
        //컨테이너
        containerStackView.axis = .vertical
        containerStackView.addArrangedSubview(collectionView)
        containerStackView.addArrangedSubview(toolbar)
        
        toolbar.isHidden = true
        
        view.addSubview(containerStackView)
        containerStackView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        toolbarBtmColorView.backgroundColor = .systemGray6

    }
    
    ///사진 목록을  초기 fetch 한다.
    func initData() {
        
        browserModel.thumbnailSize = CGSize(width: itemSize.width, height: itemSize.height)
        
        browserModel.fileList.sink { [weak self] _ in
            self?.collectionView.reloadData()
        }.store(in: &cancellable)
                
        browserModel.initFileList()
    }
    
    ///사진 선택 모드를 설정한다.
    func setSelectionMode(_ isSelecting: Bool) {
        
        selectionModeBtn.title = isSelecting ? "취소" : "선택" //사진 복수 선택 기능 on/off에 따라서 버튼 텍스트 변경
        collectionView.allowsMultipleSelection = isSelecting //콜렉션뷰 멀티셀렉션
        toolbar.isHidden = !isSelecting
        if let selectedIndices = collectionView.indexPathsForSelectedItems {
            selectedIndices.forEach { indexPath in
                collectionView.deselectItem(at: indexPath, animated: false) //선택 초기화
            }
        }
        
    }
    
    
    //MARK: - collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return browserModel.fileList.value.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        hcLog("index:\(indexPath.item)")
        guard let cell =  collectionView
            .dequeueReusableCell(withReuseIdentifier: "\(BrowserItemCell.self)", for: indexPath)
                as? BrowserItemCell else { return UICollectionViewCell()}
        
        browserModel.startFetchingThumb(index: indexPath.item) { image in
            
            DispatchQueue.main.async {
                //셀 indexPath가 바뀌었는지 확인
                if collectionView.indexPath(for: cell) == indexPath {
                    cell.imageView.image = image
                    //                    hcLog("index:\(indexPath.item) imageSize: \(image?.size ?? CGSize.zero)")
                } else {
                    hcLog("Cell 위치 변함")
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        browserModel.stopFetchingThumb(index: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
            if isSelecting.value {
                
                return true
            } else {
                //해당 사진을 Viewer로 띄운다.
                //뷰어 화면 이동
                let imageModel = browserModel.fileList.value[indexPath.item]
                imageModel.bestImage { [weak self] image in
                    guard let self else { return }
                    guard let image else { return }
                    let vc = UIHostingController(rootView: ImageViewer(image: Image(uiImage: image)))
                    present(vc, animated: true)
                }
                
                return false
            }
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSelecting.value {
            ///해당 사진이 선택된다.
            let selectedIndices: [Int] = collectionView.indexPathsForSelectedItems?.map({$0.item}) ?? []
            toolbar.middleLabel.text = "\(selectedIndices.count)" + " 개 선택됨"
            
        } else {
           
        }
    }
    

    func shareFiles(_ indices: [Int]) {
        guard let sharingData = browserModel.sharingFiles(indices)
        else { hcLog("공유할 URL 없음"); return }
        
        let activityViewController = UIActivityViewController(activityItems : sharingData, applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = .some({ [weak self] _, completed, _, error in
            if let error {
                hcLog("\(error) : \(error.localizedDescription)")
            }
            
            if completed {
                self?.isSelecting.accept(false)
            }
            
        })
//        activityViewController.popoverPresentationController?.sourceView = self
        
        //activityViewController.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook,UIActivity.ActivityType.postToTwitter,UIActivity.ActivityType.mail]
        present(activityViewController, animated: true)
    }
    
    func deleteFiles(_ indices: [Int]) {
        
        HCAlert.commonYesNo(baseVC: self, title: "선택된 파일을 삭제하시겠습니까?") {
            let result = self.browserModel.deleteFiles(indices)
            if result.success {
                hcLog("파일 삭제 성공")
            } else {
                hcLog("파일 삭제 실패(일부 또는 전체)")
            }
        }
    
    }
    
  
    
}
