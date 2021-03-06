//
/* Copyright(C) 2016-2018 Teambrella, Inc.
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
 * along with this program.  If not, see http://www.gnu.org/licenses/
 */

import UIKit

private let identifier = "Suggestions cell"

protocol SuggestionsVCDelegate: class {
    func suggestions(vc: SuggestionsVC, textChanged: String)
    func suggestionsVCWillClose(vc: SuggestionsVC)
}

class SuggestionsVC: UIViewController, Routable {
    enum Constant {
        static let cornerRadius: CGFloat = 4
    }
    
    static let storyboardName = "Info"
    
    @IBOutlet var topContainerView: UIView!
    @IBOutlet var textField: TextField!
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var effectView: UIVisualEffectView!
    
    var lastClickDate: Date = Date()
    
    weak var delegate: SuggestionsVCDelegate?
    
    var dataSource: SuggestionsFetcher! {
        didSet {
            let text = textField.text ?? ""
            
            dataSource.updateSuggestions(for: text, completion: { [weak self] in
                self?.tableView.reloadData()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        textField.autocapitalizationType = .words
        
        confirmButton.setTitle("General.choose".localized, for: .normal)
        
        topContainerView.layer.cornerRadius = Constant.cornerRadius
        topContainerView.clipsToBounds = true
        
        effectView.effect = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.tableFooterView = UIView()
        
        let parameters = UICubicTimingParameters(animationCurve: .easeIn)
        let animator = UIViewPropertyAnimator(duration: 0.5, timingParameters: parameters)
        animator.addAnimations {
            self.effectView.effect = UIBlurEffect(style: .dark)
        }
        animator.startAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }
    
    @IBAction func tapConfirmButton(_ sender: Any) {
        close()
    }
    
    @objc
    private func textChanged(sender: TextField) {
        delegate?.suggestions(vc: self, textChanged: sender.text ?? "")
        
        lastClickDate = Date()
        Timer.scheduledTimer(withTimeInterval: 0.51, repeats: false) { timer in
            guard Date().timeIntervalSince(self.lastClickDate) > 0.5 else { return }
            guard let text = self.textField.text else { return }
            
            self.updateSuggestions(text: text)
        }
    }
    
    private func updateSuggestions(text: String) {
        dataSource.updateSuggestions(for: text) { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    private func close() {
        delegate?.suggestionsVCWillClose(vc: self)
        dismiss(animated: true, completion: nil)
    }
    
}

extension SuggestionsVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        return cell
    }
    
}

extension SuggestionsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.text = dataSource.items[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        textField.text = nil
        let text = dataSource.items[indexPath.row]
        textField.insertText(text)
        tableView.deselectRow(at: indexPath, animated: true)
        if text.hasSuffix(" ") == false {
            close()
        }
    }
}

class SuggestionsFetcher {
    var items: [String] = []
    
    func updateSuggestions(for text: String, completion: @escaping () -> Void) {
        
    }
}

class CitiesFetcher: SuggestionsFetcher {
    override func updateSuggestions(for text: String, completion: @escaping  () -> Void) {
        service.dao.getCities(string: text).observe { result in
            switch result {
            case let .value(items):
                self.items = items
            case let .error(error):
                log(error)
            }
            completion()
        }
    }
    
}

class CarsFetcher: SuggestionsFetcher {
    override func updateSuggestions(for text: String, completion: @escaping  () -> Void) {
        service.dao.getCars(string: text).observe { result in
            switch result {
            case let .value(items):
                self.items = items
            case let .error(error):
                log(error)
            }
            completion()
        }
    }
}
