//
//  ContentView.swift
//  Workout
//
//  Created by Sophie Redd with use of Gihub Copilot on 8/27/26.
//

import SwiftUI
import Charts
import UniformTypeIdentifiers
import Combine

struct ContentView: View {
    @State private var selectedTab = AppTab.today
    @State private var showingWorkout = false
    @State private var showingNewTemplate = false
    @State private var editingTemplate: WorkoutTemplate?
    @State private var editingSession: WorkoutSession?
    @State private var templates = WorkoutTemplate.samples
    @State private var sessions: [WorkoutSession] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(templates: templates, sessions: sessions, startWorkout: { showingWorkout = true }, openTemplates: { selectedTab = .templates }, openHistory: { selectedTab = .progress }, editSession: { editingSession = $0 }, deleteSession: deleteSession)
                .tabItem { Label("Today", systemImage: "sun.max.fill") }.tag(AppTab.today)
            TemplatesView(templates: $templates, startWorkout: { showingWorkout = true }, addTemplate: { showingNewTemplate = true }, editTemplate: { editingTemplate = $0 }, deleteTemplate: deleteTemplate)
                .tabItem { Label("Templates", systemImage: "square.stack.3d.up.fill") }.tag(AppTab.templates)
            ProgressView(sessions: $sessions, editSession: { editingSession = $0 }, deleteSession: deleteSession, clearHistory: { sessions.removeAll() })
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }.tag(AppTab.progress)
        }
        .tint(Brand.coral)
        .foregroundStyle(Brand.ink)
        .sheet(isPresented: $showingWorkout) {
            WorkoutLogView(templates: templates, sessions: sessions, onFinish: { session, updatedTemplate in
                sessions.insert(session, at: 0)
                updateTemplate(updatedTemplate)
                updateMatchingExerciseWeights(from: session)
                showingWorkout = false
            })
        }
        .sheet(isPresented: $showingNewTemplate) {
            NewTemplateView { template in templates.append(template); showingNewTemplate = false }
        }
        .sheet(item: $editingTemplate) { template in
            EditTemplateView(template: template) { updated in updateTemplate(updated) }
        }
        .sheet(item: $editingSession) { session in
            EditSessionView(session: session) { updated in updateSession(updated) }
        }
    }

    private func updateTemplate(_ template: WorkoutTemplate) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        templates[index] = template
        editingTemplate = nil
    }

    private func updateMatchingExerciseWeights(from session: WorkoutSession) {
        for result in session.exercises {
            for index in templates.indices {
                let updatedExercises = templates[index].exercises.map { exercise in
                    exercise.key == result.key ? ExerciseDefinition(id: exercise.id, name: exercise.name, startingWeight: result.averageWeight) : exercise
                }
                templates[index].exercises = updatedExercises
            }
        }
    }

    private func deleteTemplate(_ template: WorkoutTemplate) {
        templates.removeAll { $0.id == template.id }
    }

    private func updateSession(_ session: WorkoutSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index] = session
        editingSession = nil
    }

    private func deleteSession(_ session: WorkoutSession) {
        sessions.removeAll { $0.id == session.id }
    }
}

private enum AppTab: Hashable { case today, templates, progress }

private enum Brand {
    static let coral = Color(red: 0.91, green: 0.29, blue: 0.22)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.14)
    static let muted = Color(red: 0.24, green: 0.27, blue: 0.29)
    static let mint = Color(red: 0.18, green: 0.62, blue: 0.49)
    static let canvas = Color(red: 0.97, green: 0.96, blue: 0.93)
}

private struct LogoMark: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Brand.ink)
            HStack(alignment: .bottom, spacing: size * 0.07) {
                Capsule(style: .continuous)
                    .fill(Brand.coral)
                    .frame(width: size * 0.13, height: size * 0.28)
                Capsule(style: .continuous)
                    .fill(Brand.coral)
                    .frame(width: size * 0.13, height: size * 0.44)
                Capsule(style: .continuous)
                    .fill(Brand.coral)
                    .frame(width: size * 0.13, height: size * 0.60)
            }
            .offset(y: size * 0.08)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("TrainLog logo")
    }
}

private struct BrandTitle: View {
    var body: some View {
        HStack(spacing: 8) {
            LogoMark(size: 25)
            Text("TrainLog")
                .font(.headline.weight(.bold))
                .foregroundStyle(Brand.ink)
        }
    }
}

private struct ExerciseDefinition: Identifiable, Hashable {
    let id: UUID
    var name: String
    var startingWeight: Double

    init(id: UUID = UUID(), name: String, startingWeight: Double = 0) {
        self.id = id
        self.name = name
        self.startingWeight = startingWeight
    }

    var key: String { name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
}

private struct WorkoutTemplate: Identifiable, Hashable {
    let id: UUID; var name: String; var detail: String; var exercises: [ExerciseDefinition]; var color: Color
    init(id: UUID = UUID(), name: String, detail: String, exercises: [ExerciseDefinition], color: Color) { self.id = id; self.name = name; self.detail = detail; self.exercises = exercises; self.color = color }
    static let samples = [
        WorkoutTemplate(name: "Upper A", detail: "5 exercises  •  45 min", exercises: [ExerciseDefinition(name: "Bench Press", startingWeight: 72.5), ExerciseDefinition(name: "Barbell Row", startingWeight: 60), ExerciseDefinition(name: "Overhead Press", startingWeight: 35), ExerciseDefinition(name: "Lat Pulldown", startingWeight: 55), ExerciseDefinition(name: "Cable Curl", startingWeight: 20)], color: Brand.coral),
        WorkoutTemplate(name: "Lower A", detail: "4 exercises  •  40 min", exercises: [ExerciseDefinition(name: "Back Squat", startingWeight: 80), ExerciseDefinition(name: "Romanian Deadlift", startingWeight: 70), ExerciseDefinition(name: "Leg Press", startingWeight: 120), ExerciseDefinition(name: "Calf Raise", startingWeight: 50)], color: Brand.mint),
        WorkoutTemplate(name: "Full Body", detail: "6 exercises  •  55 min", exercises: [ExerciseDefinition(name: "Deadlift", startingWeight: 90), ExerciseDefinition(name: "Incline Press", startingWeight: 60), ExerciseDefinition(name: "Goblet Squat", startingWeight: 24), ExerciseDefinition(name: "Pull Up"), ExerciseDefinition(name: "Lateral Raise", startingWeight: 10), ExerciseDefinition(name: "Plank")], color: .orange)
    ]
}

private struct CompletedExercise: Identifiable {
    let id: UUID
    var name: String
    var key: String
    var averageWeight: Double
    var volume: Int
    var sets: [LoggedSet]
}

private struct WorkoutSession: Identifiable {
    let id: UUID; var date: Date; var template: String; var volume: Int; var duration: Int; var exercises: [CompletedExercise]
    init(id: UUID = UUID(), date: Date, template: String, volume: Int, duration: Int, exercises: [CompletedExercise] = []) { self.id = id; self.date = date; self.template = template; self.volume = volume; self.duration = duration; self.exercises = exercises }
    static let samples = [
        WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!, template: "Upper A", volume: 12480, duration: 46),
        WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -4, to: .now)!, template: "Lower A", volume: 15820, duration: 42),
        WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -7, to: .now)!, template: "Upper A", volume: 11800, duration: 49),
        WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -11, to: .now)!, template: "Full Body", volume: 14600, duration: 56)
    ]
}

private struct TodayView: View {
    let templates: [WorkoutTemplate]; let sessions: [WorkoutSession]; let startWorkout: () -> Void; let openTemplates: () -> Void; let openHistory: () -> Void; let editSession: (WorkoutSession) -> Void; let deleteSession: (WorkoutSession) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day()).font(.subheadline.weight(.medium)).foregroundStyle(Brand.muted)
                        Text("Ready when\nyou are.").font(.system(size: 40, weight: .bold, design: .rounded)).foregroundStyle(Brand.ink)
                    }
                    Button(action: startWorkout) {
                        HStack { VStack(alignment: .leading, spacing: 5) { Text("Start a workout").font(.title3.bold()); Text("Pick up where you left off").font(.subheadline).opacity(0.8) }; Spacer(); Image(systemName: "arrow.up.right").font(.title3.bold()) }
                            .foregroundStyle(.white).padding(22).background(Brand.coral, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                    HStack(spacing: 12) { StatTile(value: "4", label: "This month", icon: "flame.fill", color: Brand.coral); StatTile(value: "52.4k", label: "Total volume", icon: "scalemass.fill", color: Brand.mint) }
                    SectionHeader(title: "Your templates", action: "See all", onAction: openTemplates)
                    ForEach(templates.prefix(2)) { template in TemplateRow(template: template, action: startWorkout) }
                    SectionHeader(title: "Recent sessions", action: "See all", onAction: openHistory)
                    ForEach(sessions.prefix(3)) { session in SessionRow(session: session, edit: { editSession(session) }, delete: { deleteSession(session) }) }
                }.padding(20)
            }
            .background(Brand.canvas.ignoresSafeArea())
            .navigationTitle("TrainLog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { BrandTitle() } }
        }
    }
}

private struct TemplatesView: View {
    @Binding var templates: [WorkoutTemplate]; let startWorkout: () -> Void; let addTemplate: () -> Void; let editTemplate: (WorkoutTemplate) -> Void; let deleteTemplate: (WorkoutTemplate) -> Void
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 14) { Text("Build once.\nTrain consistently.").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(Brand.ink).padding(.bottom, 10); ForEach(templates) { template in TemplateCard(template: template, action: startWorkout, edit: { editTemplate(template) }, delete: { deleteTemplate(template) }) } }.padding(20) }
                .background(Brand.canvas.ignoresSafeArea()).navigationTitle("Templates")
                .toolbar {
                    ToolbarItem(placement: .principal) { BrandTitle() }
                    ToolbarItem(placement: .topBarTrailing) { Button(action: addTemplate) { Image(systemName: "plus") } }
                }
        }
    }
}

private struct ProgressView: View {
    @Binding var sessions: [WorkoutSession]; let editSession: (WorkoutSession) -> Void; let deleteSession: (WorkoutSession) -> Void; let clearHistory: () -> Void
    @State private var showingExporter = false
    @State private var showingClearConfirmation = false
    @State private var selectedExerciseKey = ""
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) { Text("Strength at a glance").font(.system(size: 32, weight: .bold, design: .rounded)); Text("Track a lift across every workout.").foregroundStyle(Brand.muted) }.padding(.top, 8)
                if exerciseOptions.isEmpty {
                    Text("Complete a workout to start tracking exercise progress.").foregroundStyle(Brand.muted).padding(.vertical, 20)
                } else {
                    Picker("Exercise", selection: $selectedExerciseKey) {
                        ForEach(exerciseOptions, id: \.key) { exercise in Text(exercise.name).tag(exercise.key) }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Text(selectedExercise?.name ?? "Exercise volume").font(.headline); Spacer(); Text("All workouts").font(.caption.weight(.semibold)).foregroundStyle(Brand.muted) }
                    Chart(exerciseHistory) { entry in BarMark(x: .value("Date", entry.date, unit: .day), y: .value("Volume", entry.volume)).foregroundStyle(Brand.mint.gradient).cornerRadius(5) }.frame(height: 210).chartYAxis { AxisMarks(position: .leading) }.chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 18))
                HStack(spacing: 12) { MetricCard(title: "Best lift", value: "80 kg", detail: "Bench press", color: Brand.mint); MetricCard(title: "Consistency", value: "86%", detail: "Last 4 weeks", color: .orange) }
                Text("Workout history").font(.title3.bold())
                VStack(spacing: 0) {
                    ForEach(sessions) { session in
                        SessionRow(session: session, edit: { editSession(session) }, delete: { deleteSession(session) })
                        if session.id != sessions.last?.id { Divider() }
                    }
                }
                .padding(.horizontal, 16)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
            }
            .background(Brand.canvas.ignoresSafeArea())
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .principal) { BrandTitle() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingExporter = true } label: { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Export progress as CSV")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingClearConfirmation = true } label: { Image(systemName: "trash") }
                        .accessibilityLabel("Clear workout history")
                }
            }
            .alert("Clear workout history?", isPresented: $showingClearConfirmation) {
                Button("Clear History", role: .destructive, action: clearHistory)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes all logged workouts from this session.")
            }
            .fileExporter(isPresented: $showingExporter, document: CSVDocument(sessions: sessions), contentType: .commaSeparatedText, defaultFilename: "TrainLog-progress") { _ in }
        }
    }

    private var exerciseOptions: [(name: String, key: String)] {
        Dictionary(grouping: sessions.flatMap { $0.exercises }, by: \.key).compactMap { key, values in
            guard let first = values.first else { return nil }
            return (first.name, key)
        }.sorted { $0.name < $1.name }
    }

    private var selectedExercise: (name: String, key: String)? {
        exerciseOptions.first(where: { $0.key == selectedExerciseKey }) ?? exerciseOptions.first
    }

    private var exerciseHistory: [ExerciseProgressEntry] {
        guard let key = selectedExercise?.key else { return [] }
        return sessions.flatMap { session in session.exercises.filter { $0.key == key }.map { ExerciseProgressEntry(date: session.date, volume: $0.volume) } }.sorted { $0.date < $1.date }
    }
}

private struct ExerciseProgressEntry: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Int
}

private struct WorkoutLogView: View {
    @Environment(\.dismiss) private var dismiss
    let templates: [WorkoutTemplate]
    let sessions: [WorkoutSession]
    @State private var selectedTemplate: WorkoutTemplate
    @State private var selectedExerciseID: UUID
    @State private var exerciseSets: [UUID: [LoggedSet]]
    @State private var completedExerciseIDs: Set<UUID> = []
    let onFinish: (WorkoutSession, WorkoutTemplate) -> Void

    init(templates: [WorkoutTemplate], sessions: [WorkoutSession], onFinish: @escaping (WorkoutSession, WorkoutTemplate) -> Void) {
        self.templates = templates
        self.sessions = sessions
        self.onFinish = onFinish
        let template = templates.first ?? WorkoutTemplate(name: "Workout", detail: "0 exercises", exercises: [], color: Brand.coral)
        _selectedTemplate = State(initialValue: template)
        _selectedExerciseID = State(initialValue: template.exercises.first?.id ?? UUID())
        _exerciseSets = State(initialValue: Dictionary(uniqueKeysWithValues: template.exercises.map { ($0.id, [LoggedSet(weight: $0.startingWeight, reps: 8, rpe: 8)]) }))
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    RestTimerView()
                }
                Section {
                    Picker("Template", selection: $selectedTemplate) { ForEach(templates) { template in Text(template.name).tag(template) } }
                    Picker("Exercise", selection: $selectedExerciseID) { ForEach(selectedTemplate.exercises) { exercise in Text(exercise.name).tag(exercise.id) } }
                }
                Section {
                    HStack { VStack(alignment: .leading, spacing: 4) { Text(selectedExercise?.name ?? "Exercise").font(.headline); Text(lastPerformanceText).font(.caption).foregroundStyle(.white.opacity(0.72)) }; Spacer(); Image(systemName: completedExerciseIDs.contains(selectedExerciseID) ? "checkmark.circle.fill" : "arrow.clockwise").foregroundStyle(Brand.mint) }
                    HStack {
                        Text("Set").frame(width: 28, alignment: .leading)
                        Text("Weight").frame(maxWidth: .infinity)
                        Text("Reps").frame(width: 78)
                        Text("RPE").frame(width: 34)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    ForEach(Array(currentSets.enumerated()), id: \.element.id) { index, _ in
                        SetRow(set: Binding(get: { exerciseSets[selectedExerciseID]?[index] ?? LoggedSet(weight: 0, reps: 8, rpe: 8) }, set: { exerciseSets[selectedExerciseID]?[index] = $0 }))
                    }
                    Button {
                        var updatedSets = currentSets
                        updatedSets.append(LoggedSet(weight: currentSets.last?.weight ?? selectedExercise?.startingWeight ?? 0, reps: currentSets.last?.reps ?? 8, rpe: 8))
                        exerciseSets[selectedExerciseID] = updatedSets
                    } label: { Label("Add set", systemImage: "plus.circle.fill") }
                    Button(action: completeExercise) {
                        Label(completedExerciseIDs.contains(selectedExerciseID) ? "Exercise completed" : "Complete exercise", systemImage: completedExerciseIDs.contains(selectedExerciseID) ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(completedExerciseIDs.contains(selectedExerciseID))
                } header: { Text(exercisePositionText) }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Brand.ink)
            .foregroundStyle(.white)
            .navigationTitle("Log workout")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Finish") { finishWorkout() }.fontWeight(.bold) } }
            .preferredColorScheme(.dark)
            .onChange(of: selectedTemplate) { _, newTemplate in
                selectedExerciseID = newTemplate.exercises.first?.id ?? UUID()
                exerciseSets = Dictionary(uniqueKeysWithValues: newTemplate.exercises.map { ($0.id, [LoggedSet(weight: $0.startingWeight, reps: 8, rpe: 8)]) })
                completedExerciseIDs = []
            }
        }
    }

    private var lastPerformanceText: String {
        guard let exercise = selectedTemplate.exercises.first(where: { $0.id == selectedExerciseID }) else { return "Add an exercise to this template" }
        guard let previous = sessions.flatMap({ $0.exercises }).last(where: { $0.key == exercise.key }) else { return "Starting weight: \(String(format: "%.1f", exercise.startingWeight)) kg" }
        return "Last average: \(String(format: "%.1f", previous.averageWeight)) kg"
    }

    private func finishWorkout() {
        guard !selectedTemplate.exercises.isEmpty else { return }
        let completed = selectedTemplate.exercises.compactMap { exercise -> CompletedExercise? in
            guard let sets = exerciseSets[exercise.id], !sets.isEmpty else { return nil }
            let totalReps = sets.reduce(0) { $0 + $1.reps }
            let averageWeight = totalReps == 0 ? 0 : sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) } / Double(totalReps)
            let volume = sets.reduce(0) { $0 + Int($1.weight * Double($1.reps)) }
            return CompletedExercise(id: UUID(), name: exercise.name, key: exercise.key, averageWeight: averageWeight, volume: volume, sets: sets)
        }
        let updatedExercises = selectedTemplate.exercises.map { definition in
            guard let result = completed.first(where: { $0.key == definition.key }) else { return definition }
            return ExerciseDefinition(id: definition.id, name: definition.name, startingWeight: result.averageWeight)
        }
        let updatedTemplate = WorkoutTemplate(id: selectedTemplate.id, name: selectedTemplate.name, detail: selectedTemplate.detail, exercises: updatedExercises, color: selectedTemplate.color)
        onFinish(WorkoutSession(date: .now, template: selectedTemplate.name, volume: completed.reduce(0) { $0 + $1.volume }, duration: 45, exercises: completed), updatedTemplate)
    }

    private func completeExercise() {
        guard let currentIndex = selectedTemplate.exercises.firstIndex(where: { $0.id == selectedExerciseID }) else { return }
        completedExerciseIDs.insert(selectedExerciseID)
        let nextExercise = selectedTemplate.exercises[(currentIndex + 1)...].first(where: { !completedExerciseIDs.contains($0.id) })
            ?? selectedTemplate.exercises[..<currentIndex].first(where: { !completedExerciseIDs.contains($0.id) })
        if let nextExercise {
            selectedExerciseID = nextExercise.id
        }
    }

    private var selectedExercise: ExerciseDefinition? { selectedTemplate.exercises.first(where: { $0.id == selectedExerciseID }) }
    private var exercisePositionText: String {
        guard let index = selectedTemplate.exercises.firstIndex(where: { $0.id == selectedExerciseID }) else { return "Exercise" }
        return "Exercise \(index + 1) of \(selectedTemplate.exercises.count)"
    }

    private var currentSets: [LoggedSet] {
        get { exerciseSets[selectedExerciseID] ?? [] }
        set { exerciseSets[selectedExerciseID] = newValue }
    }
}

private struct RestTimerView: View {
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var remainingSeconds = 90
    @State private var isRunning = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Brand.coral.opacity(0.18), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(remainingSeconds) / 120)
                    .stroke(Brand.coral, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "timer")
                    .foregroundStyle(Brand.coral)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest timer")
                    .font(.headline)
                Text(timeString)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Menu {
                ForEach([60, 90, 120, 180], id: \.self) { seconds in
                    Button("\(seconds / 60) min") {
                        remainingSeconds = seconds
                        isRunning = false
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .accessibilityLabel("Rest timer duration")

            Button {
                isRunning.toggle()
            } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Brand.coral, in: Circle())
            }
            .disabled(remainingSeconds == 0)
            .accessibilityLabel(isRunning ? "Pause rest timer" : "Start rest timer")
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                isRunning = false
            }
        }
        .contextMenu {
            Button("Reset to 90 seconds", systemImage: "arrow.counterclockwise") {
                remainingSeconds = 90
                isRunning = false
            }
        }
    }

    private var timeString: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }
}

private struct LoggedSet: Identifiable { let id = UUID(); var weight: Double; var reps: Int; var rpe: Int }

private struct SetRow: View {
    @Binding var set: LoggedSet
    var body: some View {
        HStack(spacing: 8) {
            Text("Set")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 28, alignment: .leading)
            WeightControl(weight: $set.weight)
                .frame(maxWidth: .infinity)
            RepsControl(reps: $set.reps)
                .frame(width: 78)
            Menu {
                ForEach(1...10, id: \.self) { value in
                    Button("RPE \(value)") { set.rpe = value }
                }
            } label: {
                Text("R\(set.rpe)")
                    .font(.caption.bold())
                    .foregroundStyle(Brand.coral)
                    .frame(width: 34)
            }
        }
    }
}

private struct WeightControl: View {
    @Binding var weight: Double

    var body: some View {
        HStack(spacing: 5) {
            Button { weight = max(0, weight - 2.5) } label: { Image(systemName: "minus") }
            Text("\(weight, specifier: "%.1f")")
                .font(.caption.monospacedDigit().weight(.semibold))
                .frame(minWidth: 42)
            Button { weight = min(300, weight + 2.5) } label: { Image(systemName: "plus") }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Brand.mint)
        .controlSize(.small)
    }
}

private struct RepsControl: View {
    @Binding var reps: Int

    var body: some View {
        HStack(spacing: 4) {
            Button { reps = max(1, reps - 1) } label: { Image(systemName: "minus") }
            Text("\(reps)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .frame(width: 18)
            Button { reps = min(50, reps + 1) } label: { Image(systemName: "plus") }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Brand.mint)
        .controlSize(.small)
    }
}

private struct ExerciseEditorRow: View {
    @Binding var exercise: ExerciseDefinition

    var body: some View {
        HStack(spacing: 10) {
            TextField("Exercise name", text: $exercise.name)
            TextField("kg", value: $exercise.startingWeight, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text("kg")
                .font(.caption)
                .foregroundStyle(Brand.muted)
        }
    }
}

private struct NewTemplateView: View {
    @Environment(\.dismiss) private var dismiss; @State private var name = ""; @State private var exercises = [ExerciseDefinition(name: "", startingWeight: 0)]; let onSave: (WorkoutTemplate) -> Void
    var body: some View { NavigationStack { Form { Section("Template details") { TextField("Name", text: $name); ForEach($exercises) { $exercise in ExerciseEditorRow(exercise: $exercise) }; Button { exercises.append(ExerciseDefinition(name: "", startingWeight: 0)) } label: { Label("Add exercise", systemImage: "plus.circle.fill") }; Text("Starting weights become your default and update to the average completed weight.").font(.caption).foregroundStyle(Brand.muted) } }.navigationTitle("New template").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Create") { let valid = exercises.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }; onSave(WorkoutTemplate(name: name.isEmpty ? "New workout" : name, detail: "\(valid.count) exercises", exercises: valid, color: Brand.coral)) } } } } }
}

private struct EditTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    let template: WorkoutTemplate
    @State private var name: String
    @State private var exercises: [ExerciseDefinition]
    let onSave: (WorkoutTemplate) -> Void

    init(template: WorkoutTemplate, onSave: @escaping (WorkoutTemplate) -> Void) {
        self.template = template
        self.onSave = onSave
        _name = State(initialValue: template.name)
        _exercises = State(initialValue: template.exercises)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template details") {
                    TextField("Name", text: $name)
                    ForEach($exercises) { $exercise in ExerciseEditorRow(exercise: $exercise) }
                    Button { exercises.append(ExerciseDefinition(name: "", startingWeight: 0)) } label: { Label("Add exercise", systemImage: "plus.circle.fill") }
                }
            }
            .navigationTitle("Edit template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let definitions = exercises.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        onSave(WorkoutTemplate(id: template.id, name: name.isEmpty ? "New workout" : name, detail: "\(definitions.count) exercises", exercises: definitions, color: template.color))
                    }
                }
            }
        }
    }
}

private struct EditSessionView: View {
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession
    @State private var date: Date
    @State private var template: String
    @State private var volume: Int
    @State private var duration: Int
    let onSave: (WorkoutSession) -> Void

    init(session: WorkoutSession, onSave: @escaping (WorkoutSession) -> Void) {
        self.session = session
        self.onSave = onSave
        _date = State(initialValue: session.date)
        _template = State(initialValue: session.template)
        _volume = State(initialValue: session.volume)
        _duration = State(initialValue: session.duration)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout details") {
                    TextField("Template", text: $template)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Stepper("Volume: \(volume) kg", value: $volume, in: 0...100000, step: 10)
                    Stepper("Duration: \(duration) min", value: $duration, in: 1...300)
                }
            }
            .navigationTitle("Edit workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(WorkoutSession(id: session.id, date: date, template: template.isEmpty ? "Workout" : template, volume: volume, duration: duration)) }
                }
            }
        }
    }
}

private struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text: String

    init(sessions: [WorkoutSession]) {
        let formatter = ISO8601DateFormatter()
        let rows = sessions.flatMap { session in
            session.exercises.isEmpty
                ? ["\(formatter.string(from: session.date)),\(Self.escape(session.template)),,\(session.volume),\(session.duration),"]
                : session.exercises.map { exercise in "\(formatter.string(from: session.date)),\(Self.escape(session.template)),\(Self.escape(exercise.name)),\(exercise.volume),\(session.duration),\(exercise.averageWeight)" }
        }
        text = (["date,template,exercise,volume_kg,duration_minutes,average_weight_kg"] + rows).joined(separator: "\n") + "\n"
    }

    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }

    private static func escape(_ value: String) -> String {
        value.contains(",") || value.contains("\"") ? "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" : value
    }
}

private struct SectionHeader: View { let title: String; let action: String; let onAction: () -> Void; var body: some View { HStack { Text(title).font(.title3.bold()); Spacer(); Button(action, action: onAction).font(.caption.bold()).foregroundStyle(Brand.coral) } } }
private struct StatTile: View { let value: String; let label: String; let icon: String; let color: Color; var body: some View { VStack(alignment: .leading, spacing: 10) { Image(systemName: icon).foregroundStyle(color); Text(value).font(.title2.bold()); Text(label).font(.caption).foregroundStyle(Brand.muted) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 16)) } }
private struct MetricCard: View { let title: String; let value: String; let detail: String; let color: Color; var body: some View { VStack(alignment: .leading, spacing: 8) { Circle().fill(color).frame(width: 10, height: 10); Text(title).font(.caption).foregroundStyle(Brand.muted); Text(value).font(.title2.bold()); Text(detail).font(.caption2).foregroundStyle(Brand.muted) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 16)) } }
private struct TemplateRow: View { let template: WorkoutTemplate; let action: () -> Void; var body: some View { Button(action: action) { HStack { RoundedRectangle(cornerRadius: 5).fill(template.color).frame(width: 5, height: 42); VStack(alignment: .leading) { Text(template.name).font(.headline); Text(template.detail).font(.caption).foregroundStyle(Brand.muted) }; Spacer(); Image(systemName: "play.fill").foregroundStyle(template.color) }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 14)) }.buttonStyle(.plain) } }
private struct TemplateCard: View { let template: WorkoutTemplate; let action: () -> Void; let edit: () -> Void; let delete: () -> Void; var body: some View { VStack(alignment: .leading, spacing: 16) { HStack { Text(template.name).font(.title3.bold()); Spacer(); Menu { Button("Edit template", systemImage: "pencil", action: edit); Button("Delete template", systemImage: "trash", role: .destructive, action: delete) } label: { Image(systemName: "ellipsis") }.accessibilityLabel("Template actions") }.foregroundStyle(Brand.ink); Text(template.exercises.map(\.name).joined(separator: "  •  ")).font(.caption).foregroundStyle(Brand.muted); Button(action: action) { Label("Start workout", systemImage: "play.fill").font(.subheadline.bold()).frame(maxWidth: .infinity).padding(12).background(template.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10)).foregroundStyle(template.color) }.buttonStyle(.plain) }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 18)) } }
private struct SessionRow: View { let session: WorkoutSession; let edit: () -> Void; let delete: () -> Void; var body: some View { HStack { VStack(alignment: .leading) { Text(session.template).font(.headline); Text(session.date, format: .dateTime.month(.abbreviated).day()).font(.caption).foregroundStyle(Brand.muted) }; Spacer(); VStack(alignment: .trailing) { Text("\(session.volume) kg").font(.subheadline.bold()); Text("\(session.duration) min").font(.caption).foregroundStyle(Brand.muted) }; Menu { Button("Edit workout", systemImage: "pencil", action: edit); Button("Delete workout", systemImage: "trash", role: .destructive, action: delete) } label: { Image(systemName: "ellipsis.circle").foregroundStyle(Brand.muted) }.accessibilityLabel("Workout actions") }.padding(.vertical, 4) } }

#Preview {
    ContentView()
}
