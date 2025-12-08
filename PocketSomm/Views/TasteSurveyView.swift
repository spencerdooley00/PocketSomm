//
//  TasteSurveyView.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//

import SwiftUI

struct TasteSurveyView: View {
    @EnvironmentObject var appState: AppState

    @State private var answers: TasteSurveyAnswers = .default
    @State private var stepIndex: Int = 0

    private let totalSteps = 5

    // Available options
    private let styleOptions: [(value: String, label: String)] = [
        ("light_fruity_red", "Light & fruity reds"),
        ("medium_red", "Medium-bodied reds"),
        ("bold_red", "Bold / structured reds"),
        ("crisp_white", "Crisp whites"),
        ("rich_white", "Richer whites"),
        ("sparkling", "Sparkling"),
        ("rosé", "Rosé"),
        ("dessert", "Dessert wines")
    ]

    private let tanninOptions: [String] = ["low", "medium", "high"]
    private let acidityOptions: [String] = ["low", "medium", "high"]
    private let oakOptions: [String] = ["low", "medium", "high"]
    private let adventureOptions: [String] = ["low", "medium", "high"]

    var body: some View {
        VStack {
            stepIndicator

            Spacer(minLength: 8)

            Group {
                switch stepIndex {
                case 0:
                    stylesCard
                case 1:
                    tanninCard
                case 2:
                    acidityCard
                case 3:
                    oakCard
                case 4:
                    adventureCard
                default:
                    stylesCard
                }
            }
            .animation(.easeInOut, value: stepIndex)

            Spacer(minLength: 16)

            footerButtons
        }
        .padding()
        .navigationTitle("Taste Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            answers = appState.lastSurveyAnswers
        }
    }

    // MARK: - Step indicator

    private var stepIndicator: some View {
        HStack {
            Text("Step \(stepIndex + 1) of \(totalSteps)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Cards

    private var stylesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Which styles do you usually enjoy?")
                .font(.title3.weight(.semibold))

            Text("Pick as many as you like. This helps anchor your overall profile.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(styleOptions, id: \.value) { option in
                    styleChip(option: option)
                }
            }

            if answers.favoriteStyles.isEmpty {
                Text("Select at least one style to continue.")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .card()
    }

    private func styleChip(option: (value: String, label: String)) -> some View {
        let isSelected = answers.favoriteStyles.contains(option.value)

        return Button {
            if isSelected {
                answers.favoriteStyles.removeAll { $0 == option.value }
            } else {
                answers.favoriteStyles.append(option.value)
            }
        } label: {
            HStack {
                Text(option.label)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            )
        }
        .foregroundColor(isSelected ? Color.accentColor : Color.primary)
    }

    private var tanninCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How much tannin do you prefer?")
                .font(.title3.weight(.semibold))

            Text("Tannin is that drying, grippy feeling in red wines.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            segmentedButtons(
                options: tanninOptions,
                selected: answers.tanninPref,
                labelFor: { optionLabel("tannin", $0) }
            ) { selected in
                answers.tanninPref = selected
            }
        }
        .card()
    }

    private var acidityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How much acidity do you like?")
                .font(.title3.weight(.semibold))

            Text("Higher acidity feels brighter, fresher, more mouth-watering.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            segmentedButtons(
                options: acidityOptions,
                selected: answers.acidityPref,
                labelFor: { optionLabel("acidity", $0) }
            ) { selected in
                answers.acidityPref = selected
            }
        }
        .card()
    }

    private var oakCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How much oak influence?")
                .font(.title3.weight(.semibold))

            Text("Things like vanilla, toast, baking spices often come from oak.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            segmentedButtons(
                options: oakOptions,
                selected: answers.oakPref,
                labelFor: { optionLabel("oak", $0) }
            ) { selected in
                answers.oakPref = selected
            }
        }
        .card()
    }

    private var adventureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How adventurous are you?")
                .font(.title3.weight(.semibold))

            Text("Are you happy staying in your comfort zone, or do you want more unusual bottles?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            segmentedButtons(
                options: adventureOptions,
                selected: answers.adventurePref,
                labelFor: { optionLabel("adventure", $0) }
            ) { selected in
                answers.adventurePref = selected
            }

            if appState.isSubmittingSurvey {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Saving your profile…")
                        .font(.subheadline)
                }
            } else if appState.surveySaved {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Preferences saved. Recommendations will use this profile.")
                }
                .font(.subheadline)
                .foregroundColor(.green)
            } else if let error = appState.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .card()
    }

    // MARK: - Segmented buttons helper

    private func segmentedButtons(
        options: [String],
        selected: String,
        labelFor: @escaping (String) -> String,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        HStack {
            ForEach(options, id: \.self) { option in
                let isSelected = (option == selected)
                Button {
                    onSelect(option)
                } label: {
                    Text(labelFor(option))
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                )
                .foregroundColor(isSelected ? Color.accentColor : Color.primary)
            }
        }
    }

    private func optionLabel(_ kind: String, _ raw: String) -> String {
        switch (kind, raw) {
        case (_, "low"): return "Low"
        case (_, "medium"): return "Medium"
        case (_, "high"): return "High"
        default: return raw.capitalized
        }
    }

    // MARK: - Footer

    private var footerButtons: some View {
        HStack {
            if stepIndex > 0 {
                Button("Back") {
                    stepIndex = max(0, stepIndex - 1)
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button(stepIndex == totalSteps - 1 ? "Save Preferences" : "Next") {
                if stepIndex < totalSteps - 1 {
                    if stepIndex == 0 && answers.favoriteStyles.isEmpty {
                        // force at least one style
                        return
                    }
                    stepIndex += 1
                } else {
                    Task {
                        await appState.submitSurvey(answers: answers)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(stepIndex == 0 && answers.favoriteStyles.isEmpty)
        }
    }
}

// MARK: - Card modifier

private extension View {
    func card() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(16)
    }
}
