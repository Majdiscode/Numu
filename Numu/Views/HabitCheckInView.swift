//
//  HabitCheckInView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct HabitCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habit: Habit

    @State private var notes: String = ""
    @State private var satisfaction: Int = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Identity Reinforcement
                    identitySection

                    // MARK: - Satisfaction Rating
                    satisfactionSection

                    // MARK: - Notes
                    notesSection

                    // MARK: - Streak Info
                    streakSection
                }
                .padding()
            }
            .navigationTitle("Complete Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        completeHabit()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Identity Section
    private var identitySection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.color).opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: habit.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: habit.color))
            }

            VStack(spacing: 8) {
                Text("I am a \(habit.identity)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("I am a person who \(habit.actionName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("Every action you take is a vote for the person you want to become")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .italic()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Satisfaction Section
    private var satisfactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How do you feel?", systemImage: "face.smiling")
                .font(.headline)

            Text("Law 4: Make it Satisfying")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            satisfaction = rating
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(satisfaction >= rating ? Color(hex: habit.color) : Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)

                            Text(emojiForRating(rating))
                                .font(.title2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes (Optional)", systemImage: "note.text")
                .font(.headline)

            TextField("How did it go? Any insights?", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Streak Section
    private var streakSection: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(habit.currentStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Text("Current Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("\(habit.longestStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Text("Best Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Helper Methods
    private func emojiForRating(_ rating: Int) -> String {
        switch rating {
        case 1: return "😞"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😄"
        default: return "😐"
        }
    }

    private func completeHabit() {
        let log = HabitLog(
            notes: notes.isEmpty ? nil : notes,
            satisfaction: satisfaction
        )
        log.habit = habit

        modelContext.insert(log)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving habit log: \(error)")
        }
    }
}