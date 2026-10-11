import UIKit

enum KeyboardWarmUp {
    private static var done = false

    static func run() {
        guard !done else { return }
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first
        guard let window else { return }
        done = true
        let field = UITextField(frame: .zero)
        field.autocorrectionType = .no
        window.addSubview(field)
        field.becomeFirstResponder()
        field.resignFirstResponder()
        field.removeFromSuperview()
    }
}
