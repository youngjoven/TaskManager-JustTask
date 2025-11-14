//
//  GmailService.swift
//  GmailTaskManager
//
//  Created by Claude Code
//

import Foundation
import Combine
import GoogleSignIn

class GmailService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var labels: [GmailLabel] = []
    @Published var tasks: [EmailTask] = []
    @Published var errorMessage: String?

    private let clientID = AppConfig.googleClientID
    private var accessToken: String?
    private let geminiService = GeminiService()

    // Google Sign-In으로 로그인
    @MainActor
    func signIn() async {
        print("📱 Sign in started...")

        // rootViewController 찾기 개선
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("❌ No window scene found")
            return
        }

        print("✅ Window scene found")

        guard let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
            print("❌ No window found")
            return
        }

        print("✅ Window found")

        guard var rootViewController = window.rootViewController else {
            print("❌ No root view controller found")
            return
        }

        // presentedViewController가 있으면 그것을 사용
        while let presented = rootViewController.presentedViewController {
            rootViewController = presented
        }

        print("✅ Root view controller found: \(type(of: rootViewController))")

        let config = GIDConfiguration(clientID: clientID)
        print("✅ Configuration created")

        GIDSignIn.sharedInstance.configuration = config
        print("✅ Configuration set")

        // Gmail API 스코프 추가
        let scopes = AppConfig.gmailScopes
        print("✅ Scopes: \(scopes)")

        do {
            print("🔐 Starting Google Sign-In...")
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: scopes
            )

            print("✅ Sign-In successful!")

            // 액세스 토큰 저장
            self.accessToken = result.user.accessToken.tokenString
            print("✅ Access token saved")

            self.isAuthenticated = true
            print("✅ User authenticated")

        } catch {
            print("❌ Sign in error: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func setAuthenticated(accessToken: String) {
        print("🔵 setAuthenticated called")
        print("🔵 Access token length: \(accessToken.count)")
        self.accessToken = accessToken
        print("🔵 Setting isAuthenticated to true...")
        self.isAuthenticated = true
        print("✅ User authenticated in service, isAuthenticated: \(self.isAuthenticated)")
    }

    func signOut() {
        isAuthenticated = false
        labels = []
        tasks = []
    }

    // Gmail 라벨 목록 가져오기
    func fetchLabels() async {
        guard let token = accessToken else {
            print("No access token available")
            return
        }

        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/labels")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let labelsArray = json["labels"] as? [[String: Any]] {

                let fetchedLabels = labelsArray.compactMap { labelDict -> GmailLabel? in
                    guard let id = labelDict["id"] as? String,
                          let name = labelDict["name"] as? String else {
                        return nil
                    }

                    // 시스템 라벨 제외 (사용자가 만든 라벨만)
                    let systemLabels = [
                        "INBOX", "SENT", "DRAFT", "SPAM", "TRASH", "UNREAD", "STARRED", "IMPORTANT",
                        "CATEGORY_PERSONAL", "CATEGORY_SOCIAL", "CATEGORY_PROMOTIONS", "CATEGORY_UPDATES", "CATEGORY_FORUMS",
                        "YELLOW_STAR", "BLUE_STAR", "RED_STAR", "ORANGE_STAR", "GREEN_STAR", "PURPLE_STAR",
                        "CHAT", "NOTES"
                    ]
                    if systemLabels.contains(id) {
                        return nil
                    }

                    return GmailLabel(id: id, name: name)
                }

                print("Fetched \(fetchedLabels.count) labels, now fetching latest email dates...")

                // 각 라벨의 최신 이메일 날짜를 병렬로 가져오기
                let labelsWithDates = await withTaskGroup(of: GmailLabel?.self) { group in
                    for label in fetchedLabels {
                        group.addTask {
                            await self.fetchLatestEmailDate(for: label, token: token)
                        }
                    }

                    var results: [GmailLabel] = []
                    for await labelWithDate in group {
                        if let label = labelWithDate {
                            results.append(label)
                        }
                    }
                    return results
                }

                // 최신 이메일 날짜 기준으로 내림차순 정렬 (최신이 먼저)
                let sortedLabels = labelsWithDates.sorted { label1, label2 in
                    guard let date1 = label1.latestEmailDate else { return false }
                    guard let date2 = label2.latestEmailDate else { return true }
                    return date1 > date2
                }

                await MainActor.run {
                    self.labels = sortedLabels
                }

                print("Fetched and sorted \(sortedLabels.count) labels by latest email date")
            }
        } catch {
            print("Error fetching labels: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "라벨 가져오기 실패: \(error.localizedDescription)"
            }
        }
    }

    // 특정 라벨의 최신 이메일 날짜 가져오기
    private func fetchLatestEmailDate(for label: GmailLabel, token: String) async -> GmailLabel? {
        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages?labelIds=\(label.id)&maxResults=1")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let messages = json["messages"] as? [[String: Any]],
                  let firstMessage = messages.first,
                  let messageId = firstMessage["id"] as? String else {
                // 이메일이 없는 라벨은 nil 날짜로 반환
                return GmailLabel(id: label.id, name: label.name, latestEmailDate: nil)
            }

            // 메시지 상세 정보에서 날짜 가져오기
            let messageUrl = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(messageId)?format=metadata&metadataHeaders=Date")!
            var messageRequest = URLRequest(url: messageUrl)
            messageRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (messageData, _) = try await URLSession.shared.data(for: messageRequest)

            guard let messageJson = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
                  let payload = messageJson["payload"] as? [String: Any],
                  let headers = payload["headers"] as? [[String: Any]] else {
                return GmailLabel(id: label.id, name: label.name, latestEmailDate: nil)
            }

            // Date 헤더 찾기
            for header in headers {
                if let headerName = header["name"] as? String,
                   headerName.lowercased() == "date",
                   let dateString = header["value"] as? String,
                   let date = parseEmailDate(dateString) {
                    return GmailLabel(id: label.id, name: label.name, latestEmailDate: date)
                }
            }

            return GmailLabel(id: label.id, name: label.name, latestEmailDate: nil)

        } catch {
            print("Error fetching latest email for label \(label.name): \(error.localizedDescription)")
            return GmailLabel(id: label.id, name: label.name, latestEmailDate: nil)
        }
    }

    // 특정 라벨의 이메일 가져오기
    func fetchEmailsByLabel(labelId: String) async {
        guard let token = accessToken else {
            print("No access token available")
            return
        }

        // 먼저 기존 tasks 초기화 (캐시 문제 방지)
        await MainActor.run {
            self.tasks = []
            print("🗑️ Cleared previous tasks")
        }

        // 1단계: 메시지 ID 목록 가져오기 (최대 20개, 최신순)
        let listUrl = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages?labelIds=\(labelId)&maxResults=20")!
        var listRequest = URLRequest(url: listUrl)
        listRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (listData, _) = try await URLSession.shared.data(for: listRequest)

            guard let json = try? JSONSerialization.jsonObject(with: listData) as? [String: Any],
                  let messages = json["messages"] as? [[String: Any]] else {
                print("No messages found")
                await MainActor.run {
                    self.tasks = []
                }
                return
            }

            print("Found \(messages.count) messages")

            // 2단계: 각 메시지의 상세 정보 가져오기
            var fetchedTasks: [EmailTask] = []

            for message in messages {
                guard let messageId = message["id"] as? String else { continue }

                if let task = await fetchMessageDetail(messageId: messageId, token: token, labelId: labelId) {
                    fetchedTasks.append(task)
                }
            }

            // 최신순 정렬
            fetchedTasks.sort { $0.date > $1.date }

            await MainActor.run {
                self.tasks = fetchedTasks
            }

            print("Fetched \(fetchedTasks.count) tasks")

            // 3단계: 최신 3개 이메일에 대해 AI 요약 생성
            await generateAISummaries(for: fetchedTasks)

        } catch {
            print("Error fetching emails: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "이메일 가져오기 실패: \(error.localizedDescription)"
            }
        }
    }

    // 메시지 상세 정보 가져오기
    private func fetchMessageDetail(messageId: String, token: String, labelId: String) async -> EmailTask? {
        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(messageId)?format=full")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let payload = json["payload"] as? [String: Any],
                  let headers = payload["headers"] as? [[String: Any]] else {
                return nil
            }

            // 헤더에서 정보 추출
            var subject = "제목 없음"
            var from = "발신자 없음"
            var dateString = ""

            for header in headers {
                if let name = header["name"] as? String,
                   let value = header["value"] as? String {
                    switch name.lowercased() {
                    case "subject":
                        subject = value
                    case "from":
                        from = value
                    case "date":
                        dateString = value
                    default:
                        break
                    }
                }
            }

            // 날짜 파싱
            let date = parseEmailDate(dateString) ?? Date()

            // 본문 추출
            let body = extractBody(from: payload) ?? "본문 없음"

            // 라벨 이름 가져오기
            let labelName = labels.first(where: { $0.id == labelId })?.name ?? "라벨"

            return EmailTask(
                id: messageId,
                title: subject,
                body: body,
                sender: from,
                date: date,
                labelName: labelName
            )

        } catch {
            print("Error fetching message \(messageId): \(error.localizedDescription)")
            return nil
        }
    }

    // 이메일 본문 추출 (재귀적으로 parts 탐색)
    private func extractBody(from payload: [String: Any]) -> String? {
        // 먼저 body 확인
        if let body = payload["body"] as? [String: Any],
           let data = body["data"] as? String {
            return decodeBase64Url(data)
        }

        // parts가 있으면 재귀적으로 탐색
        if let parts = payload["parts"] as? [[String: Any]] {
            for part in parts {
                if let mimeType = part["mimeType"] as? String {
                    // text/plain 우선 선택
                    if mimeType == "text/plain",
                       let body = part["body"] as? [String: Any],
                       let data = body["data"] as? String {
                        return decodeBase64Url(data)
                    }
                }
            }

            // text/plain이 없으면 text/html 선택
            for part in parts {
                if let mimeType = part["mimeType"] as? String {
                    if mimeType == "text/html",
                       let body = part["body"] as? [String: Any],
                       let data = body["data"] as? String {
                        return stripHTML(decodeBase64Url(data) ?? "")
                    }
                }
            }

            // 재귀적으로 nested parts 탐색
            for part in parts {
                if let extractedBody = extractBody(from: part) {
                    return extractedBody
                }
            }
        }

        return nil
    }

    // Base64 URL 디코딩
    private func decodeBase64Url(_ encoded: String) -> String? {
        var base64 = encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // 패딩 추가
        let paddingLength = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: paddingLength)

        guard let data = Data(base64Encoded: base64) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    // HTML 태그 제거
    private func stripHTML(_ html: String) -> String {
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // 이메일 날짜 파싱
    private func parseEmailDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"

        return formatter.date(from: dateString)
    }

    // AI 요약 생성 (최신 3개 이메일) - 병렬 처리
    private func generateAISummaries(for tasks: [EmailTask]) async {
        let tasksToSummarize = Array(tasks.prefix(3))

        print("🤖 Generating AI summaries for \(tasksToSummarize.count) emails in parallel...")

        // 병렬 처리를 위한 TaskGroup 사용
        await withTaskGroup(of: (String, String)?.self) { group in
            for (index, task) in tasksToSummarize.enumerated() {
                group.addTask {
                    do {
                        print("🤖 Summarizing email \(index + 1): \(task.title)")

                        // 첫 번째는 전체, 나머지는 개요만
                        let isFullSummary = (index == 0)
                        let summary = try await self.geminiService.summarizeTask(
                            title: task.title,
                            body: task.body,
                            sender: task.sender,
                            fullSummary: isFullSummary
                        )

                        print("✅ Summary completed for email \(index + 1)")
                        return (task.id, summary)

                    } catch {
                        print("❌ Failed to generate summary for \(task.title): \(error.localizedDescription)")
                        return nil
                    }
                }
            }

            // 모든 요약이 완료되면 업데이트
            for await result in group {
                if let (taskId, summary) = result {
                    await MainActor.run {
                        if let taskIndex = self.tasks.firstIndex(where: { $0.id == taskId }) {
                            var updatedTask = self.tasks[taskIndex]
                            updatedTask.aiSummary = summary
                            self.tasks[taskIndex] = updatedTask
                        }
                    }
                }
            }
        }

        print("✅ All AI summaries generated (parallel)")
    }
}
