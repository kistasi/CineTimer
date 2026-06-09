import SwiftUI
import SwiftData

struct AddFilmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum RuntimeMode: String, CaseIterable {
        case minutes = "Minutes"
        case hoursAndMinutes = "h / min"
    }

    private let filmToEdit: Film?

    @State private var title: String
    @State private var runtimeMode: RuntimeMode
    @State private var runtimeInput: String
    @State private var runtimeHours: Int
    @State private var runtimeMinutes: Int
    @State private var startTime: Date
    @State private var trailerBuffer: Int

    init(film: Film? = nil) {
        filmToEdit = film
        _title = State(initialValue: film?.title ?? "")
        _runtimeMode = State(initialValue: .minutes)
        _runtimeInput = State(initialValue: film.map { "\($0.runningTime)" } ?? "")
        _runtimeHours = State(initialValue: (film?.runningTime ?? 120) / 60)
        _runtimeMinutes = State(initialValue: (film?.runningTime ?? 120) % 60)
        _startTime = State(initialValue: film?.startTime ?? Date())
        _trailerBuffer = State(initialValue: film?.trailerBuffer ?? 15)
    }

    private var isEditing: Bool { filmToEdit != nil }

    private var runningTime: Int {
        switch runtimeMode {
        case .minutes:         return Int(runtimeInput) ?? 0
        case .hoursAndMinutes: return runtimeHours * 60 + runtimeMinutes
        }
    }

    private var runtimeFormatted: String {
        guard runningTime > 0 else { return "" }
        let h = runningTime / 60
        let m = runningTime % 60
        return h > 0 ? (m > 0 ? "\(h)h \(m)m" : "\(h)h") : "\(m)m"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Film") {
                    TextField("Title", text: $title)
                }

                Section {
                    Picker("", selection: $runtimeMode) {
                        ForEach(RuntimeMode.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())

                    switch runtimeMode {
                    case .minutes:
                        HStack {
                            TextField("118", text: $runtimeInput)
                                .keyboardType(.numberPad)
                            Text("minutes")
                                .foregroundStyle(.secondary)
                        }
                    case .hoursAndMinutes:
                        Stepper("Hours: \(runtimeHours)", value: $runtimeHours, in: 0...6)
                        Stepper("Minutes: \(runtimeMinutes)", value: $runtimeMinutes, in: 0...59, step: 5)
                    }
                } header: {
                    Text("Running Time")
                } footer: {
                    if !runtimeFormatted.isEmpty {
                        Text(runtimeFormatted)
                    }
                }

                Section {
                    Stepper("Trailers: \(trailerBuffer) min", value: $trailerBuffer, in: 0...60, step: 5)
                } header: {
                    Text("Trailers & Commercials")
                } footer: {
                    Text("Added before the film. Most cinemas run 10–20 min.")
                }

                Section {
                    DatePicker("Showtime", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Schedule")
                } footer: {
                    let filmAt = startTime.addingTimeInterval(Double(trailerBuffer) * 60)
                        .formatted(date: .omitted, time: .shortened)
                    Text("Film starts at \(filmAt)")
                }
            }
            .navigationTitle(isEditing ? "Edit Film" : "Add Film")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || runningTime == 0)
                }
            }
        }
    }

    private func save() {
        if let film = filmToEdit {
            film.title = title.trimmingCharacters(in: .whitespaces)
            film.runningTime = runningTime
            film.startTime = startTime
            film.trailerBuffer = trailerBuffer
        } else {
            modelContext.insert(Film(
                title: title.trimmingCharacters(in: .whitespaces),
                runningTime: runningTime,
                startTime: startTime,
                trailerBuffer: trailerBuffer
            ))
        }
        dismiss()
    }
}
