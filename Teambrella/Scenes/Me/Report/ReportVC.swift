//
//  ReportVC.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 24.06.17.

/* Copyright(C) 2017  Teambrella, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License(version 3) as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see<http://www.gnu.org/licenses/>.
 */

import UIKit

protocol ReportDelegate: class {
    func report(controller: ReportVC, didSendReport data: Any)
}

class ReportVC: UIViewController, Routable {
    static let storyboardName: String = "Me"
    
    @IBOutlet var collectionView: UICollectionView!
    var reportContext: ReportContext!
    var dataSource: ReportDataSource!
    var isModal: Bool = false
    
    weak var delegate: ReportDelegate?
    
    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.date = Date()
        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(datePickerChangedValue), for: .valueChanged)
        return datePicker
    }()
    
    lazy var photoPicker: ImagePickerController = {
        let imagePicker = ImagePickerController(parent: self, delegate: self)
        return imagePicker
    }()
    
    var photoController: PhotoPreviewVC = PhotoPreviewVC(collectionViewLayout: UICollectionViewFlowLayout())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isModal {
            
        } else {
            setupTransparentNavigationBar()
            defaultGradientOnTop()
            automaticallyAdjustsScrollViewInsets = false
            title = "Report a Claim"
        }
        addKeyboardObservers()
        
        dataSource = ReportDataSource(context: reportContext)
        ReportCellBuilder.registerCells(in: collectionView)
        
    }
    
    func addKeyboardObservers() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapView))
        view.addGestureRecognizer(tap)
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(adjustForKeyboard),
                           name: Notification.Name.UIKeyboardWillHide,
                           object: nil)
        center.addObserver(self, selector: #selector(adjustForKeyboard),
                           name: Notification.Name.UIKeyboardWillChangeFrame,
                           object: nil)
    }
    
    func adjustForKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let value = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = value.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == Notification.Name.UIKeyboardWillHide {
            collectionView.contentInset = UIEdgeInsets.zero
        } else {
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        collectionView.scrollIndicatorInsets = collectionView.contentInset
        if let responder = collectionView.currentFirstResponder() as? UIView {
            for cell in collectionView.visibleCells where responder.isDescendant(of: cell) {
                if let indexPath = collectionView.indexPath(for: cell) {
                    collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }
    
    func tapView(sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func tapAddPhoto(sender: UIButton) {
        photoPicker.show()
    }
    
    func datePickerChangedValue(sender: UIDatePicker) {
        var idx = 0
        for i in 0 ..< dataSource.items.count where dataSource.items[i] is DateReportCellModel {
            idx = i
            break
        }
        
        let indexPath = IndexPath(row: idx, section: 0)
        if var dateReportCellModel = dataSource[indexPath] as? DateReportCellModel {
            dateReportCellModel.date = sender.date
            dataSource.items[idx] = dateReportCellModel
            if let cell = collectionView.cellForItem(at: indexPath) as? ReportTextFieldCell {
                cell.textField.text = DateProcessor().stringIntervalOrDate(from: dateReportCellModel.date)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showSubmitButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showSubmitButton()
    }
    
    private func showSubmitButton() {
        navigationItem.setRightBarButton(UIBarButtonItem(title: "Submit",
                                                         style: .done,
                                                         target: self,
                                                         action: #selector(tapSubmit(_:))),
                                         animated: false)
    }
    
    func tapSubmit(_ sender: UIButton) {
        print("tap Submit")
        validateAndSendData()
    }
    
    func validateAndSendData() {
        var date: Date?
        var expenses: Double?
        var message: String?
        let images = photoController.photos
        var address: String?
        
        for model in dataSource.items {
            if let model = model as? DateReportCellModel {
                date = model.date
            } else if let model = model as? ExpensesReportCellModel {
                expenses = model.expenses
            } else if let model = model as? DescriptionReportCellModel {
                message = model.text
            } else if let model = model as? WalletReportCellModel {
                address = model.text
            }
        }
        guard let teamID = service.session.currentTeam?.teamID else { fatalError("No current team") }
        
        if let date = date, let expenses = expenses, let message = message, let address = address {
            let model = NewClaimModel(teamID: teamID,
                                      incidentDate: date,
                                      expenses: expenses,
                                      message: message,
                                      images: images,
                                      address: address)
            dataSource.sendClaim(model: model) { [weak self] result in
                guard let me = self else { return }
                
                me.delegate?.report(controller: me, didSendReport: result)
            }
        }
    }
    
    func textFieldDidChange(textField: UITextField) {
        let indexPath = IndexPath(row: textField.tag, section: 0)
        if var model = dataSource[indexPath] as? WalletReportCellModel {
            model.text = textField.text ?? ""
            dataSource.items[indexPath.row] = model
        } else if var model = dataSource[indexPath] as? ExpensesReportCellModel,
            let text = textField.text,
            let expenses = Double(text) {
            model.expenses = expenses
            dataSource.items[indexPath.row] = model
        }
    }
    
    func addPhotoController(to view: UIView) {
        photoController.loadViewIfNeeded()
        if let superview = photoController.view.superview, superview == view {
            return
        }
        photoController.view.removeFromSuperview()
        photoController.removeFromParentViewController()
        photoController.didMove(toParentViewController: nil)
        photoController.willMove(toParentViewController: self)
        view.addSubview(photoController.view)
        photoController.view.frame = view.bounds
        photoController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addChildViewController(photoController)
        photoController.didMove(toParentViewController: self)
    }
    
}

// MARK: UICollectionViewDataSource
extension ReportVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = dataSource[indexPath].cellReusableIdentifier
        print(identifier + " at: \(indexPath)")
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier,
                                                  for: indexPath)
    }
    
}

// MARK: UICollectionViewDelegate
extension ReportVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        ReportCellBuilder.populate(cell: cell, with: dataSource[indexPath], reportVC: self, indexPath: indexPath)
        if let cell = cell as? ReportPhotoGalleryCell {
            addPhotoController(to: cell.container)
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
}

// MARK: UICollectionViewDelegateFlowLayout
extension ReportVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - 16 * 2,
                      height: CGFloat(dataSource[indexPath].preferredHeight))
    }
}

extension ReportVC: ImagePickerControllerDelegate {
    func imagePicker(controller: ImagePickerController, didSendPhoto photo: String) {
        photoController.addPhotos([photo])
    }
    
    func imagePicker(controller: ImagePickerController, didSelectPhoto photp: UIImage) {
        
    }
    
    func imagePicker(controller: ImagePickerController, willClosePickerByCancel cancel: Bool) {
        
    }
}

extension ReportVC: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let indexPath = IndexPath(row: textView.tag, section: 0)
        if var model = dataSource[indexPath] as? DescriptionReportCellModel {
            model.text = textView.text
            dataSource.items[indexPath.row] = model
        }
    }
}
