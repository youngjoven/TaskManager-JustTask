//
//  CalendarView.swift
//  GmailTaskManager
//
//  Created by Claude Code
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var gmailService: GmailService
    let selectedLabel: GmailLabel

    @State private var currentDate = Date()
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 헤더
                    headerView

                    // 이메일 요약 섹션
                    emailSummaryView
                        .padding(.bottom, 20)

                    // 캘린더
                    calendarGridView

                    // 선택된 날짜의 과업 리스트
                    if let selected = selectedDate {
                        taskListView(for: selected)
                    } else {
                        emptyStateView
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // 라벨 변경 시마다 이메일 새로 가져오기
            Task {
                await gmailService.fetchEmailsByLabel(labelId: selectedLabel.id)
            }
        }
        .id(selectedLabel.id) // 라벨이 변경되면 뷰를 완전히 새로 생성
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }

                Spacer()

                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)

            Text("라벨: \(selectedLabel.name)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Email Summary View
    private var emailSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📧 최신 업무 요약")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            if gmailService.tasks.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    Text("이메일을 불러오는 중...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 10) {
                    ForEach(latestTasks.prefix(3)) { task in
                        EmailSummaryCard(task: task)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .padding(.horizontal, 12)
        )
    }

    private var latestTasks: [EmailTask] {
        gmailService.tasks.sorted { $0.date > $1.date }
    }

    // MARK: - Calendar Grid View
    private var calendarGridView: some View {
        VStack(spacing: 8) {
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast),
                            isToday: calendar.isDateInToday(date),
                            taskCount: taskCount(for: date),
                            onTap: {
                                selectedDate = date
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Task List View
    private func taskListView(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateString(date))
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            LazyVStack(spacing: 12) {
                ForEach(tasksForDate(date)) { task in
                    TaskCard(task: task)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color.gray.opacity(0.1))
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("날짜를 선택해주세요")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Helper Properties
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentDate)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        let days: [Date?] = (0..<42).map { index in
            let date = calendar.date(byAdding: .day, value: index, to: monthFirstWeek.start)
            if let date = date, calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
                return date
            }
            return nil
        }

        return days
    }

    private func taskCount(for date: Date) -> Int {
        tasksForDate(date).count
    }

    private func tasksForDate(_ date: Date) -> [EmailTask] {
        gmailService.tasks.filter { task in
            calendar.isDate(task.date, inSameDayAs: date)
        }
    }

    // MARK: - Actions
    private func previousMonth() {
        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
    }

    private func nextMonth() {
        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let taskCount: Int
    let onTap: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 16))
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : (isToday ? .blue : .white))

                if taskCount > 0 {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.2) : Color.clear))
            )
        }
    }
}

// MARK: - Email Summary Card
struct EmailSummaryCard: View {
    let task: EmailTask

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: task.date, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(task.sender)
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // AI 요약 - 전체 표시
            if let aiSummary = task.aiSummary {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Text("AI 업무 요약")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                    }

                    Text(aiSummary)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 4)
            } else {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white.opacity(0.5))
                    Text("AI 요약 생성 중...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(task.aiSummary != nil ? Color.yellow.opacity(0.4) : Color.clear, lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Task Card
struct TaskCard: View {
    let task: EmailTask

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            Text(task.sender)
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(task.body)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
        )
    }
}

#Preview {
    CalendarView(
        gmailService: GmailService(),
        selectedLabel: GmailLabel(id: "1", name: "업무")
    )
}
