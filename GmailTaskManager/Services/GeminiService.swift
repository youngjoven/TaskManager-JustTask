//
//  GeminiService.swift
//  GmailTaskManager
//
//  Created by Claude Code
//

import Foundation

class GeminiService {
    // Gemini API Key (Config.swift에서 가져옴)
    private let apiKey = AppConfig.geminiAPIKey

    // Gemini 2.0 Flash 모델 사용 (빠르고 효율적)
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    /// 이메일 내용을 분석하여 해야 할 업무를 요약
    func summarizeTask(title: String, body: String, sender: String, fullSummary: Bool = true) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.apiKeyNotSet
        }

        let prompt: String

        if fullSummary {
            // 첫 번째 이메일 - 전체 요약
            prompt = """
            다음 이메일의 내용을 분석하여 아래 템플릿 형식으로 업무를 요약해주세요.

            === 이메일 정보 ===
            제목: \(title)
            발신자: \(sender)
            내용: \(body)

            === 요약 템플릿 ===
            [개요]
            1. 주제: (이메일의 핵심 주제)
            2. 일시: (언급된 날짜/시간, 없으면 생략)
            3. 장소: (언급된 장소, 없으면 생략)
            4. 관련 인원: (언급된 사람들, 없으면 생략)

            [내용]
            (이메일의 핵심 내용을 계층 구조로 정리)
            1. 주제1
                (1) 세부 내용
                (2) 세부 내용
            2. 주제2
                (1) 세부 내용

            [향후 과업]
            (해야 할 일이나 요청사항을 명확하게 나열)

            주의사항:
            - 인사말이나 불필요한 부가 설명은 제외
            - 간결하고 명확하게 핵심만 작성
            - 정보가 없는 항목은 생략
            - 마크다운 형식으로 작성
            """
        } else {
            // 두 번째, 세 번째 이메일 - [개요]만
            prompt = """
            다음 이메일의 내용을 분석하여 [개요] 부분만 간단히 요약해주세요.

            === 이메일 정보 ===
            제목: \(title)
            발신자: \(sender)
            내용: \(body)

            === 요약 형식 ===
            [개요]
            1. 주제: (이메일의 핵심 주제)
            2. 일시: (언급된 날짜/시간, 없으면 생략)
            3. 장소: (언급된 장소, 없으면 생략)
            4. 관련 인원: (언급된 사람들, 있으면 간단히)

            주의사항:
            - [개요]만 작성
            - 인사말 제외, 핵심만 간결하게
            - 정보가 없는 항목은 생략
            """
        }

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 1000
            ]
        ]

        guard let url = URL(string: baseURL) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            print("Gemini API Error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
            throw GeminiError.apiError(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let candidates = json?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.failedToParse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors
enum GeminiError: LocalizedError {
    case apiKeyNotSet
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case failedToParse

    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet:
            return "Gemini API 키가 설정되지 않았습니다. GeminiService.swift 파일에서 API 키를 설정해주세요."
        case .invalidURL:
            return "잘못된 URL입니다."
        case .invalidResponse:
            return "잘못된 응답입니다."
        case .apiError(let statusCode):
            return "API 오류: \(statusCode)"
        case .failedToParse:
            return "응답 파싱에 실패했습니다."
        }
    }
}
