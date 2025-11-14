//
//  LabelSelectionView.swift
//  GmailTaskManager
//
//  Created by Claude Code
//

import SwiftUI

struct LabelSelectionView: View {
    @ObservedObject var gmailService: GmailService
    @State private var selectedLabel: GmailLabel?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // 헤더
                    VStack(spacing: 8) {
                        Text("라벨 선택")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("과업을 확인할 Gmail 라벨을 선택하세요")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)

                    // 라벨 리스트
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(gmailService.labels) { label in
                                LabelRow(
                                    label: label,
                                    isSelected: selectedLabel?.id == label.id,
                                    onTap: {
                                        selectedLabel = label
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 선택 완료 버튼
                    if selectedLabel != nil {
                        NavigationLink(destination: CalendarView(gmailService: gmailService, selectedLabel: selectedLabel!)) {
                            Text("과업 보기")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
        .onAppear {
            Task {
                await gmailService.fetchLabels()
            }
        }
    }
}

struct LabelRow: View {
    let label: GmailLabel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(isSelected ? .blue : .gray)

                Text(label.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    LabelSelectionView(gmailService: GmailService())
}
