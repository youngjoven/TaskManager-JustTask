//
//  LoginView.swift
//  GmailTaskManager
//
//  Created by Claude Code
//

import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @ObservedObject var gmailService: GmailService
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            // 다크모드 배경
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // 앱 아이콘/로고 영역
                VStack(spacing: 16) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Just Task")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Gmail 라벨로 과업을 관리하세요")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Google 로그인 버튼
                GoogleSignInButton(gmailService: gmailService)

                Text("Gmail 계정으로 로그인")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()
                    .frame(height: 80)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Google Sign-In 버튼
struct GoogleSignInButton: UIViewControllerRepresentable {
    @ObservedObject var gmailService: GmailService

    func makeUIViewController(context: Context) -> GoogleSignInViewController {
        return GoogleSignInViewController(gmailService: gmailService)
    }

    func updateUIViewController(_ uiViewController: GoogleSignInViewController, context: Context) {
    }
}

class GoogleSignInViewController: UIViewController {
    var gmailService: GmailService

    init(gmailService: GmailService) {
        self.gmailService = gmailService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let button = UIButton(type: .custom) // .system 대신 .custom 사용
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        // HStack 시뮬레이션
        let icon = UIImageView(image: UIImage(systemName: "g.circle.fill"))
        icon.tintColor = .black
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Google로 로그인"
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [icon, label])
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false // 터치를 버튼으로 전달
        stackView.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: button.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -24)
        ])

        // 컨테이너 뷰
        let containerView = UIView()
        containerView.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        self.view = containerView
    }

    @objc func signInTapped() {
        NSLog("🔵🔵🔵 BUTTON TAPPED - START 🔵🔵🔵")
        print("🔵 Button tapped in UIViewController")

        let clientID = AppConfig.googleClientID
        NSLog("Client ID: %@", clientID)

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let scopes = AppConfig.gmailScopes

        NSLog("🔵 Starting sign in...")
        print("🔵 Starting sign in with presenting: \(self)")

        GIDSignIn.sharedInstance.signIn(
            withPresenting: self,
            hint: nil,
            additionalScopes: scopes
        ) { [weak self] result, error in
            NSLog("🔥🔥🔥 CALLBACK CALLED 🔥🔥🔥")

            guard let self = self else {
                NSLog("❌ self is nil")
                return
            }

            // 에러 체크
            if let error = error {
                NSLog("❌ Sign in error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "로그인 실패", message: "에러: \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(alert, animated: true)
                }
                return
            }

            // result 체크
            guard let result = result else {
                NSLog("❌ No result")
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "로그인 실패", message: "결과 없음 (result is nil)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(alert, animated: true)
                }
                return
            }

            // 성공!
            NSLog("✅✅✅ SIGN IN SUCCESSFUL! ✅✅✅")
            let accessToken = result.user.accessToken.tokenString
            NSLog("✅ Access token first 20 chars: %@", String(accessToken.prefix(20)))

            // 바로 인증 처리 (Alert 없이)
            Task { @MainActor in
                NSLog("🔵 Calling setAuthenticated...")
                self.gmailService.setAuthenticated(accessToken: accessToken)

                NSLog("🔵 Fetching labels...")
                await self.gmailService.fetchLabels()

                NSLog("🔵 Labels count: \(self.gmailService.labels.count)")
            }
        }
    }
}

#Preview {
    LoginView(gmailService: GmailService())
}
