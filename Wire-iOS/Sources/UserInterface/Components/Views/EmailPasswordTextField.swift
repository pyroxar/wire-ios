//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit

protocol EmailPasswordTextFieldDelegate: class {
    func textFieldDidUpdateText(_ textField: EmailPasswordTextField)
    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String))
}

class EmailPasswordTextField: UIView {

    let emailField = AccessoryTextField(kind: .email)
    let passwordField = AccessoryTextField(kind: .password(isNew: false))
    let contentStack = UIStackView()
    let separatorContainer: ContentInsetView

    weak var delegate: EmailPasswordTextFieldDelegate?

    private var emailValidationError: TextFieldValidator.ValidationError = .none
    private var passwordValidationError: TextFieldValidator.ValidationError = .none

    // MARK: - Initialization

    override init(frame: CGRect) {
        let separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        separatorContainer = ContentInsetView(UIView(), inset: separatorInset)
        super.init(frame: frame)

        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        let separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        separatorContainer = ContentInsetView(UIView(), inset: separatorInset)
        super.init(coder: aDecoder)

        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        addSubview(contentStack)

        emailField.delegate = self
        emailField.textFieldValidationDelegate = self
        emailField.placeholder = "email.placeholder".localized(uppercased: true)
        emailField.showConfirmButton = false
        emailField.addTarget(self, action: #selector(textInputDidChange), for: .editingChanged)

        contentStack.addArrangedSubview(emailField)

        separatorContainer.view.backgroundColor = .white
        separatorContainer.view.backgroundColor = UIColor.from(scheme: .separator)
        contentStack.addArrangedSubview(separatorContainer)

        passwordField.delegate = self
        passwordField.textFieldValidationDelegate = self
        passwordField.placeholder = "password.placeholder".localized(uppercased: true)
        passwordField.bindConfirmationButton(to: emailField)
        passwordField.addTarget(self, action: #selector(textInputDidChange), for: .editingChanged)
        passwordField.confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)

        contentStack.addArrangedSubview(passwordField)
    }

    private func configureConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.fitInSuperview()
        separatorContainer.heightAnchor.constraint(equalToConstant: CGFloat.hairline).isActive = true
    }

    // MARK: - Responder

    override var isFirstResponder: Bool {
        return emailField.isFirstResponder || passwordField.isFirstResponder
    }

    override var canBecomeFirstResponder: Bool {
        return emailField.canBecomeFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        return emailField.becomeFirstResponder()
    }

    override var canResignFirstResponder: Bool {
        return emailField.canResignFirstResponder || passwordField.canResignFirstResponder
    }

    override func resignFirstResponder() -> Bool {
        if emailField.isFirstResponder {
            return emailField.resignFirstResponder()
        } else if passwordField.isFirstResponder {
            return passwordField.resignFirstResponder()
        } else {
            return false
        }
    }

    // MARK: - Submission

    @objc private func confirmButtonTapped() {
        delegate?.textField(self, didConfirmCredentials: (emailField.input, passwordField.input))
    }

    @objc private func textInputDidChange(sender: UITextField) {
        if sender == emailField {
            emailField.validateInput()
        } else if sender == passwordField {
            passwordField.validateInput()
        }

        delegate?.textFieldDidUpdateText(self)
    }

}

extension EmailPasswordTextField: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            emailField.validateInput()
            passwordField.validateInput()
            confirmButtonTapped()
        }

        return true
    }

}

extension EmailPasswordTextField: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError) {
        print(error)
        // self.validationError = error
    }
}

