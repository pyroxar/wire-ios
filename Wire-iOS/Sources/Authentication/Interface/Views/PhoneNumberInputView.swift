//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import Foundation

/// An object that receives notification about the phone number input view.
protocol PhoneNumberInputViewDelegate: class {
    func phoneNumberInputView(_ inputView: PhoneNumberInputView, didPickPhoneNumber phoneNumber: String)
    func phoneNumberInputView(_ inputView: PhoneNumberInputView, didValidatePhoneNumber phoneNumber: String, withResult validationError: TextFieldValidator.ValidationError)
    func phoneNumberInputViewDidRequestCountryPicker(_ inputView: PhoneNumberInputView)
}

/**
 * A view providing an input field for phone numbers and a.
 */

class PhoneNumberInputView: UIView, UITextFieldDelegate, TextFieldValidationDelegate {

    /// The object receiving notifications about events from this view.
    weak var delegate: PhoneNumberInputViewDelegate?

    /// The currently selected country.
    private(set) var country = Country.default

    /// The validation error for the current input.
    private(set) var validationError: TextFieldValidator.ValidationError = .tooShort(kind: .phoneNumber)

    /// Whether to show the confirm button.
    var showConfirmButton: Bool = true {
        didSet {
            textField.showConfirmButton = showConfirmButton
        }
    }

    /// The value entered by the user.
    var input: String {
        return textField.input
    }

    // MARK: - Views

    private let countryPickerButton = IconButton()
    private let countryPickerIndicator = IconButton()

    private let inputStack = UIStackView()
    private let countryCodeInputView = IconButton()
    private let textField = AccessoryTextField(kind: .phoneNumber, leftInset: 8)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
        configureValidation()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
        configureValidation()
    }

    private func configureSubviews() {
        // countryPickerButton
        countryPickerButton.accessibilityIdentifier = "CountryPickerButton"
        countryPickerButton.titleLabel?.font = UIFont.normalLightFont
        countryPickerButton.contentHorizontalAlignment = UIApplication.isLeftToRightLayout ? .left : .right
        countryPickerButton.addTarget(self, action: #selector(handleCountryButtonTap), for: .touchUpInside)
        countryPickerButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addSubview(countryPickerButton)

        // countryCodeButton
        countryCodeInputView.setContentHuggingPriority(.required, for: .horizontal)
        countryCodeInputView.setBackgroundImageColor(.white, for: .normal)
        countryCodeInputView.setTitleColor(.black, for: .normal)
        countryCodeInputView.titleLabel?.font = UIFont.normalLightFont
        countryCodeInputView.isUserInteractionEnabled = false
        inputStack.addArrangedSubview(countryCodeInputView)

        // inputStack
        inputStack.axis = .horizontal
        inputStack.spacing = 0
        inputStack.distribution = .fill
        inputStack.alignment = .fill
        addSubview(inputStack)

        // textField
        textField.textInsets.left = 0
        textField.placeholder = "registration.enter_phone_number.placeholder".localized(uppercased: true)
        textField.accessibilityLabel = "registration.enter_phone_number.placeholder".localized
        textField.accessibilityIdentifier = "PhoneNumberField"
        textField.tintColor = UIColor.Team.activeButtonColor
        textField.confirmButton.addTarget(self, action: #selector(handleConfirmButtonTap), for: .touchUpInside)
        textField.delegate = self
        textField.textFieldValidationDelegate = self
        inputStack.addArrangedSubview(textField)

        selectCountry(.default)
    }

    private func configureConstraints() {
        inputStack.translatesAutoresizingMaskIntoConstraints = false
        countryPickerButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // countryPickerStack
            countryPickerButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            countryPickerButton.topAnchor.constraint(equalTo: topAnchor),
            countryPickerButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            countryPickerButton.heightAnchor.constraint(equalToConstant: 28),

            // inputStack
            inputStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputStack.topAnchor.constraint(equalTo: countryPickerButton.bottomAnchor, constant: 16),
            inputStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            inputStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            // dimentions
            textField.heightAnchor.constraint(equalToConstant: 56),
            countryCodeInputView.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func configureValidation() {
        textField.textFieldValidator.customValidator = { input in
            let phoneNumber = self.country.e164PrefixString + input
            let normalizedNumber = UnregisteredUser.normalizedPhoneNumber(phoneNumber)

            switch normalizedNumber {
            case .invalid(let errorCode):
                switch errorCode {
                case .objectValidationErrorCodeStringTooLong: return .tooLong(kind: .phoneNumber)
                case .objectValidationErrorCodeStringTooShort: return .tooShort(kind: .phoneNumber)
                default: return .invalidPhoneNumber
                }
            case .unknownError:
                return .invalidPhoneNumber
            case .valid:
                return .none
            }
        }
    }

    // MARK: - View Lifecycle

    override var tintColor: UIColor! {
        didSet {
            countryPickerButton.setTitleColor(tintColor, for: .normal)
            countryPickerButton.setTitleColor(tintColor, for: .normal)
        }
    }

    override var canBecomeFirstResponder: Bool {
        return textField.canBecomeFirstResponder
    }

    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override var canResignFirstResponder: Bool {
        return textField.canResignFirstResponder
    }

    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    /**
     * Selects the specified country as the beginning of the phone number.
     * - parameter country: The country of the phone number,
     */

    func selectCountry(_ country: Country) {
        self.country = country

        let title = country.displayName
        let color = UIColor.black
        let selectedColor = UIColor(white: 0, alpha: 0.4)

        let icon = NSTextAttachment.downArrow(color: color)
        let selectedIcon = NSTextAttachment.downArrow(color: selectedColor)

        let normalLabel = title.addingTrailingAttachment(icon) && color
        countryPickerButton.setAttributedTitle(normalLabel, for: .normal)

        let selectedLabel = title.addingTrailingAttachment(selectedIcon) && selectedColor
        countryPickerButton.setAttributedTitle(selectedLabel, for: .highlighted)

        countryPickerButton.accessibilityValue = country.displayName
        countryPickerButton.accessibilityLabel = "registration.phone_country".localized
        countryPickerButton.accessibilityHint = "registration.phone_country.hint".localized
        countryCodeInputView.setTitle(country.e164PrefixString, for: .normal)
        countryCodeInputView.accessibilityValue = country.e164PrefixString
    }

    // MARK: - Text Update

    /// Returns whether the text should be updated.
    func shouldChangeCharacters(in range: NSRange, replacementString: String) -> Bool {
        guard let replacementRange = Range(range, in: input) else {
            return false
        }

        let updatedString = input.replacingCharacters(in: replacementRange, with: replacementString)
        return updatePhoneNumber(updatedString)
    }

    /// Updates the phone number with a new value.
    @discardableResult func updatePhoneNumber(_ updatedString: String?) -> Bool {
        guard let updatedString = updatedString else { return false }

        // If the textField is empty and a replacementString with a +, it is likely to insert from autoFill.
        if textField.text?.count == 0 && updatedString.contains("+") {
            return shouldInsert(phoneNumber: updatedString)
        }

        let number = PhoneNumber(countryCode: country.e164.uintValue, numberWithoutCode: updatedString)

        switch number.validate() {
        case .containsInvalidCharacters, .tooLong:
            return false
        default:
            removeValidationError()
            return true
        }
    }

    // MARK: - Events

    @objc private func handleCountryButtonTap() {
        delegate?.phoneNumberInputViewDidRequestCountryPicker(self)
    }

    @objc private func handleConfirmButtonTap() {
        submitValue()
    }

    /// Do not paste if we need to set the text manually.
    override open func paste(_ sender: Any?) {
        var shouldPaste = true

        if let pastedString = UIPasteboard.general.string {
            shouldPaste = shouldInsert(phoneNumber: pastedString)
        }

        if shouldPaste {
            super.paste(sender)
        }
    }

    /// Only insert text if we have a valid phone number.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return shouldChangeCharacters(in: range, replacementString: string)
    }

    /**
     * Checks whether the inserted text contains a phone number. If it does, we overtake the paste / text change mechanism and
     * update the country and text field manually.
     * - parameter phoneNumber: The text that is being inserted.
     * - returns: Whether the text should be inserted by the text field or if we need to insert it manually.
     */

    private func shouldInsert(phoneNumber: String) -> Bool {
        guard let (country, phoneNumberWithoutCountryCode) = phoneNumber.shouldInsertAsPhoneNumber(presetCountry: country) else {
            return true
        }

        selectCountry(country)
        textField.updateText(phoneNumberWithoutCountryCode)
        removeValidationError()
        return false
    }

    // MARK: - Value Submission

    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError) {
        self.validationError = error
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textField.validateInput()
        submitValue()
        return true
    }

    func submitValue() {
        let phoneNumber = country.e164PrefixString + textField.input

        switch validationError {
        case .none:
            delegate?.phoneNumberInputView(self, didValidatePhoneNumber: phoneNumber, withResult: .none)
            delegate?.phoneNumberInputView(self, didPickPhoneNumber: phoneNumber)
        default:
            delegate?.phoneNumberInputView(self, didValidatePhoneNumber: phoneNumber, withResult: validationError)
        }
    }

    func removeValidationError() {
        validationError = .none
        let phoneNumber = country.e164PrefixString + textField.input
        delegate?.phoneNumberInputView(self, didValidatePhoneNumber: phoneNumber, withResult: .none)
    }

}
