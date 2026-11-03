import SwiftUI

private struct WorkspaceTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var detail: String
    var project: String
    var status: String
    var priority: String
    var dueDate: Date?

    static func load() -> [WorkspaceTask] {
        guard let data = UserDefaults.standard.data(forKey: "workspaceTasks"),
              let tasks = try? JSONDecoder().decode([WorkspaceTask].self, from: data) else {
            return [
                WorkspaceTask(title: "Connect GitHub account", detail: "Finish OAuth Client ID setup and authorize the app.", project: "iOS Starter", status: "To Do", priority: "High", dueDate: nil),
                WorkspaceTask(title: "Browse repository files", detail: "Add folder navigation and file previews.", project: "iOS Starter", status: "To Do", priority: "High", dueDate: nil),
                WorkspaceTask(title: "Build and test on iPhone", detail: "Run a device build, sign with ESign, and verify the installed app.", project: "iOS Starter", status: "In Progress", priority: "High", dueDate: nil)
            ]
        }
        return tasks
    }
}

struct TaskCenterView: View {
    @State private var tasks = WorkspaceTask.load()
    @State private var filter = "All"
    @State private var showingNewTask = false
    @State private var search = ""
    private let filters = ["All", "To Do", "In Progress", "Done"]

    private var visibleTasks: [WorkspaceTask] {
        tasks.filter { task in
            (filter == "All" || task.status == filter) &&
            (search.isEmpty || task.title.localizedCaseInsensitiveContains(search) ||
             task.project.localizedCaseInsensitiveContains(search) ||
             task.detail.localizedCaseInsensitiveContains(search))
        }
    }

    private var completedCount: Int { tasks.filter { $0.status == "Done" }.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Project Tasks").font(.largeTitle.bold())
                        Spacer()
                        Button { showingNewTask = true } label: {
                            Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.white)
                                .frame(width: 42, height: 42).background(.orange).clipShape(Circle())
                        }
                        .accessibilityLabel("Add task")
                    }
                    Text("\(completedCount) of \(tasks.count) tasks completed")
                        .font(.subheadline).foregroundStyle(.secondary)
                    ProgressView(value: tasks.isEmpty ? 0 : Double(completedCount) / Double(tasks.count))
                        .tint(.orange)
                }
                .padding(.horizontal, 18).padding(.top, 8)

                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search tasks or projects", text: $search)
                }
                .padding(12).background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 13)).padding(.horizontal, 18)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { item in
                            Button { filter = item } label: {
                                Text(item).font(.subheadline.weight(.semibold))
                                    .foregroundStyle(filter == item ? .white : .primary)
                                    .padding(.horizontal, 15).padding(.vertical, 9)
                                    .background(filter == item ? Color.orange : Color(uiColor: .secondarySystemBackground))
                                    .clipShape(Capsule())
                            }
                        }
                    }.padding(.horizontal, 18)
                }

                if visibleTasks.isEmpty {
                    ContentUnavailableView("No tasks found", systemImage: "checklist", description: Text("Add a task or change your search."))
                } else {
                    List {
                        ForEach(visibleTasks) { task in
                            taskRow(task)
                        }
                        .onDelete(perform: deleteTasks)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNewTask) {
                NewWorkspaceTaskView { task in tasks.insert(task, at: 0); save() }
            }
        }
    }

    private func taskRow(_ task: WorkspaceTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    update(task, status: task.status == "Done" ? "To Do" : "Done")
                } label: {
                    Image(systemName: task.status == "Done" ? "checkmark.circle.fill" : "circle")
                        .font(.title3).foregroundStyle(task.status == "Done" ? .green : .secondary)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title).font(.headline)
                        .strikethrough(task.status == "Done")
                    Text(task.project).font(.caption.weight(.semibold)).foregroundStyle(.orange)
                    if !task.detail.isEmpty {
                        Text(task.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 4)
                Text(task.priority).font(.caption2.weight(.bold))
                    .foregroundStyle(task.priority == "High" ? .red : .secondary)
            }
            HStack {
                Menu {
                    ForEach(["To Do", "In Progress", "Done"], id: \.self) { status in
                        Button(status) { update(task, status: status) }
                    }
                } label: {
                    Label(task.status, systemImage: "arrow.left.arrow.right")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
                Spacer()
                if let dueDate = task.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 5)
    }

    private func update(_ task: WorkspaceTask, status: String) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].status = status
        save()
    }

    private func deleteTasks(at offsets: IndexSet) {
        let ids = offsets.map { visibleTasks[$0].id }
        tasks.removeAll { ids.contains($0.id) }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "workspaceTasks")
        }
    }
}

private struct NewWorkspaceTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var detail = ""
    @State private var project = "iOS Starter"
    @State private var priority = "Medium"
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    let onSave: (WorkspaceTask) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task title", text: $title)
                    TextField("Details", text: $detail, axis: .vertical).lineLimit(2...4)
                    TextField("Project", text: $project)
                    Picker("Priority", selection: $priority) {
                        ForEach(["Low", "Medium", "High"], id: \.self) { Text($0) }
                    }
                }
                Section("Schedule") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate { DatePicker("Due", selection: $dueDate, displayedComponents: .date) }
                }
            }
            .navigationTitle("New Task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(WorkspaceTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                             detail: detail, project: project, status: "To Do",
                                             priority: priority, dueDate: hasDueDate ? dueDate : nil))
                        dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
