//
//  Daily_Info_Grid.swift
//  Daily Info Grid
//
//  Created by Veselin Nikolov on 14.01.26.
//

import WidgetKit
import SwiftUI

// MARK: - Constants
private enum AppGroup {
    static let suiteName = "group.com.daily_info.widget"
}

private enum StorageKeys {
    static let showWeather = "showWeather"
    static let showBattery = "showBattery"
    static let showCalendar = "showCalendar"
    static let showActivityRings = "showActivityRings"
    static let lastBatteryLevel = "lastBatteryLevel"
    static let lastKnownTemperature = "lastKnownTemperature"
    static let lastKnownWeatherSymbol = "lastKnownWeatherSymbol"
    static let nextEventTitle = "nextEventTitle"
    static let nextEventTime = "nextEventTime"
    static let moveCalories = "moveCalories"
    static let moveGoal = "moveGoal"
    static let exerciseMinutes = "exerciseMinutes"
    static let exerciseGoal = "exerciseGoal"
    static let standHours = "standHours"
    static let standGoal = "standGoal"
}

private enum DeepLinks {
    static let weather = URL(string: "dailyinfo://open?target=weather")!
    static let calendar = URL(string: "dailyinfo://open?target=calendar")!
    static let fitness = URL(string: "dailyinfo://open?target=fitness")!
}

// MARK: - Entry
struct WidgetEntry: TimelineEntry {
    let date: Date
    let showWeather: Bool
    let showBattery: Bool
    let showCalendar: Bool
    let showActivityRings: Bool
    let temperature: String
    let weatherSymbol: String
    let batteryLevel: Float
    let nextEventTitle: String
    let nextEventTime: Date?
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double
    let moveCalories: Int
    let exerciseMinutes: Int
    let standHours: Int
    
    static var placeholder: WidgetEntry {
        WidgetEntry(
            date: Date(),
            showWeather: true, showBattery: true, showCalendar: true, showActivityRings: true,
            temperature: "22°", weatherSymbol: "sun.max.fill", batteryLevel: 0.75,
            nextEventTitle: "Next Event", nextEventTime: Date().addingTimeInterval(3600),
            moveProgress: 0.7, exerciseProgress: 0.5, standProgress: 0.8,
            moveCalories: 350, exerciseMinutes: 15, standHours: 8
        )
    }
}

// MARK: - Timeline Provider
struct WidgetProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: AppGroup.suiteName)
    
    func placeholder(in context: Context) -> WidgetEntry { .placeholder }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(createEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [createEntry()], policy: .after(nextUpdate)))
    }
    
    private func createEntry() -> WidgetEntry {
        func readBool(_ key: String) -> Bool {
            defaults?.object(forKey: key) == nil ? true : defaults!.bool(forKey: key)
        }
        
        let storedBattery = defaults?.float(forKey: StorageKeys.lastBatteryLevel) ?? 0
        let moveCalories = defaults?.double(forKey: StorageKeys.moveCalories) ?? 0
        let moveGoal = max(defaults?.double(forKey: StorageKeys.moveGoal) ?? 500, 1)
        let exerciseMinutes = defaults?.double(forKey: StorageKeys.exerciseMinutes) ?? 0
        let exerciseGoal = max(defaults?.double(forKey: StorageKeys.exerciseGoal) ?? 30, 1)
        let standHours = defaults?.double(forKey: StorageKeys.standHours) ?? 0
        let standGoal = max(defaults?.double(forKey: StorageKeys.standGoal) ?? 12, 1)
        
        return WidgetEntry(
            date: Date(),
            showWeather: readBool(StorageKeys.showWeather),
            showBattery: readBool(StorageKeys.showBattery),
            showCalendar: readBool(StorageKeys.showCalendar),
            showActivityRings: readBool(StorageKeys.showActivityRings),
            temperature: defaults?.string(forKey: StorageKeys.lastKnownTemperature) ?? "--°",
            weatherSymbol: defaults?.string(forKey: StorageKeys.lastKnownWeatherSymbol) ?? "sun.max.fill",
            batteryLevel: storedBattery > 0 ? storedBattery : 0.75,
            nextEventTitle: defaults?.string(forKey: StorageKeys.nextEventTitle) ?? "No events",
            nextEventTime: defaults?.object(forKey: StorageKeys.nextEventTime) as? Date,
            moveProgress: min(moveCalories / moveGoal, 1.5),
            exerciseProgress: min(exerciseMinutes / exerciseGoal, 1.5),
            standProgress: min(standHours / standGoal, 1.5),
            moveCalories: Int(moveCalories),
            exerciseMinutes: Int(exerciseMinutes),
            standHours: Int(standHours)
        )
    }
}

// MARK: - Date Formatters
private enum Formatters {
    static let weekday: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f
    }()
    static let day: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
    static let month: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM"; return f
    }()
    static let time: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
}

// MARK: - Widget Entry View
struct WidgetEntryView: View {
    let entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall: smallWidget
        case .systemMedium: mediumWidget
        case .systemLarge, .systemExtraLarge: largeWidget
        case .accessoryCircular: accessoryCircularWidget
        case .accessoryRectangular: accessoryRectangularWidget
        case .accessoryInline: accessoryInlineWidget
        @unknown default: mediumWidget
        }
    }
    
    // MARK: - Small Widget
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 0) {
            dateHeader(daySize: 34, weekdaySize: 10, monthSize: 10)
            Spacer(minLength: 4)
            smallInfoItems
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
    }
    
    private func dateHeader(daySize: CGFloat, weekdaySize: CGFloat, monthSize: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(Formatters.day.string(from: entry.date))
                .font(.system(size: daySize, weight: .bold, design: .rounded))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(Formatters.weekday.string(from: entry.date).prefix(3).uppercased())
                    .font(.system(size: weekdaySize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red)
                Text(Formatters.month.string(from: entry.date).prefix(3))
                    .font(.system(size: monthSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var smallInfoItems: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.showWeather {
                Link(destination: DeepLinks.weather) {
                    infoRow(icon: entry.weatherSymbol, text: entry.temperature, color: nil, multicolor: true, fontSize: 12)
                }
            }
            if entry.showBattery {
                infoRow(icon: batteryIcon, text: "\(batteryPercent)%", color: batteryColor, fontSize: 12)
            }
            if entry.showActivityRings {
                Link(destination: DeepLinks.fitness) {
                    HStack(spacing: 4) {
                        ActivityRingsView(move: entry.moveProgress, exercise: entry.exerciseProgress, stand: entry.standProgress, size: 18, lineWidth: 2.5)
                        Text("\(entry.moveCalories) kcal").font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    }
                }
            }
            if entry.showCalendar && entry.nextEventTitle != "No events" {
                Link(destination: DeepLinks.calendar) {
                    HStack(spacing: 3) {
                        Circle().fill(.red).frame(width: 6, height: 6)
                        Text(entry.nextEventTitle).font(.system(size: 11, weight: .medium)).lineLimit(1)
                    }
                }
            }
        }
        .foregroundStyle(.primary)
    }
    
    private func infoRow(icon: String, text: String, color: Color?, multicolor: Bool = false, fontSize: CGFloat) -> some View {
        HStack(spacing: 4) {
            if multicolor {
                Image(systemName: icon).symbolRenderingMode(.multicolor).font(.system(size: fontSize))
            } else {
                Image(systemName: icon).foregroundStyle(color ?? .primary).font(.system(size: fontSize))
            }
            Text(text).font(.system(size: fontSize, weight: .semibold, design: .rounded))
        }
    }
    
    // MARK: - Medium Widget
    private var mediumWidget: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: -2) {
                Text(Formatters.weekday.string(from: entry.date).uppercased())
                    .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(.red)
                Text(Formatters.day.string(from: entry.date))
                    .font(.system(size: 48, weight: .light, design: .rounded))
                Text(Formatters.month.string(from: entry.date))
                    .font(.system(size: 14, weight: .regular, design: .rounded)).foregroundStyle(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            mediumGrid
        }
        .padding(12)
    }
    
    private var mediumGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            if entry.showWeather {
                Link(destination: DeepLinks.weather) { cardCell(icon: entry.weatherSymbol, value: entry.temperature, label: "Weather", color: .orange, multicolor: true) }
            }
            if entry.showBattery {
                cardCell(icon: batteryIcon, value: "\(batteryPercent)%", label: "Battery", color: batteryColor)
            }
            if entry.showActivityRings {
                Link(destination: DeepLinks.fitness) { activityCell(ringSize: 28, lineWidth: 3, fontSize: 14, labelSize: 9) }
            }
            if entry.showCalendar {
                Link(destination: DeepLinks.calendar) { calendarCell(iconSize: 16, titleSize: 11, timeSize: 9) }
            }
        }
    }
    
    private func cardCell(icon: String, value: String, label: String, color: Color, multicolor: Bool = false) -> some View {
        VStack(spacing: 4) {
            Group {
                if multicolor { Image(systemName: icon).symbolRenderingMode(.multicolor) }
                else { Image(systemName: icon).foregroundStyle(color) }
            }.font(.system(size: 20))
            Text(value).font(.system(size: 14, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.ultraThinMaterial))
    }
    
    private func activityCell(ringSize: CGFloat, lineWidth: CGFloat, fontSize: CGFloat, labelSize: CGFloat) -> some View {
        VStack(spacing: 4) {
            ActivityRingsView(move: entry.moveProgress, exercise: entry.exerciseProgress, stand: entry.standProgress, size: ringSize, lineWidth: lineWidth)
            Text("\(entry.moveCalories)").font(.system(size: fontSize, weight: .bold, design: .rounded)).foregroundStyle(.red)
            Text("kcal").font(.system(size: labelSize, weight: .medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.ultraThinMaterial))
    }
    
    private func calendarCell(iconSize: CGFloat, titleSize: CGFloat, timeSize: CGFloat) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "calendar").font(.system(size: iconSize)).foregroundStyle(.red)
            Text(entry.nextEventTitle).font(.system(size: titleSize, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
            if let time = entry.nextEventTime {
                Text(Formatters.time.string(from: time)).font(.system(size: timeSize)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.ultraThinMaterial))
    }
    
    // MARK: - Large Widget
    private var largeWidget: some View {
        VStack(spacing: 10) {
            largeHeader
            Rectangle().fill(.quaternary).frame(height: 0.5)
            largeGrid
            if !entry.showWeather && !entry.showBattery && !entry.showCalendar && !entry.showActivityRings {
                emptyState.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }
    
    private var largeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(Formatters.weekday.string(from: entry.date).uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(.red)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Formatters.day.string(from: entry.date)).font(.system(size: 56, weight: .light, design: .rounded))
                    Text(Formatters.month.string(from: entry.date)).font(.system(size: 20, weight: .regular, design: .rounded)).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
    
    private var largeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if entry.showWeather {
                Link(destination: DeepLinks.weather) { largeCard(icon: entry.weatherSymbol, color: .orange, title: entry.temperature, subtitle: "Weather", multicolor: true) }
            }
            if entry.showBattery {
                largeCard(icon: batteryIcon, color: batteryColor, title: "\(batteryPercent)%", subtitle: "Battery")
            }
            if entry.showActivityRings {
                Link(destination: DeepLinks.fitness) { largeActivityCard }
            }
            if entry.showCalendar {
                Link(destination: DeepLinks.calendar) { largeCalendarCard }
            }
        }
    }
    
    private func largeCard(icon: String, color: Color, title: String, subtitle: String, multicolor: Bool = false) -> some View {
        VStack(spacing: 6) {
            Group {
                if multicolor { Image(systemName: icon).symbolRenderingMode(.multicolor) }
                else { Image(systemName: icon).foregroundStyle(color) }
            }.font(.system(size: 32))
            Text(title).font(.system(size: 24, weight: .bold, design: .rounded))
            Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial))
    }
    
    private var largeActivityCard: some View {
        VStack(spacing: 8) {
            ActivityRingsView(move: entry.moveProgress, exercise: entry.exerciseProgress, stand: entry.standProgress, size: 56, lineWidth: 6)
            HStack(spacing: 12) {
                statLabel(value: "\(entry.moveCalories)", unit: "kcal", color: .red)
                statLabel(value: "\(entry.exerciseMinutes)", unit: "min", color: .green)
                statLabel(value: "\(entry.standHours)", unit: "hrs", color: .cyan)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial))
    }
    
    private func statLabel(value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(unit).font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }
    
    private var largeCalendarCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar").font(.system(size: 32)).foregroundStyle(.red)
            Text(entry.nextEventTitle).font(.system(size: 16, weight: .semibold, design: .rounded)).lineLimit(2).multilineTextAlignment(.center)
            if let time = entry.nextEventTime {
                Text(Formatters.time.string(from: time)).font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial))
    }
    
    // MARK: - Accessory Widgets
    private var accessoryCircularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Text(Formatters.day.string(from: entry.date)).font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(entry.date.formatted(.dateTime.month(.abbreviated)).uppercased()).font(.system(size: 10, weight: .medium))
            }
        }
    }
    
    private var accessoryRectangularWidget: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(Formatters.day.string(from: entry.date)).font(.system(size: 24, weight: .semibold, design: .rounded))
                Text(Formatters.weekday.string(from: entry.date)).font(.system(size: 12, weight: .medium)).textCase(.uppercase)
            }
            HStack(spacing: 10) {
                if entry.showWeather {
                    HStack(spacing: 2) { Image(systemName: entry.weatherSymbol).font(.system(size: 11)); Text(entry.temperature).font(.system(size: 12, weight: .medium)) }
                }
                if entry.showBattery {
                    HStack(spacing: 2) { Image(systemName: batteryIcon).font(.system(size: 11)); Text("\(batteryPercent)%").font(.system(size: 12, weight: .medium)) }
                }
            }.foregroundStyle(.secondary)
        }
    }
    
    private var accessoryInlineWidget: some View {
        HStack(spacing: 6) {
            Text(entry.date.formatted(.dateTime.weekday(.abbreviated).day()))
            if entry.showWeather { Text("•"); Text(entry.temperature) }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.2x2").font(.system(size: 24)).foregroundStyle(.tertiary)
            Text("Configure in app").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Helpers
    private var batteryPercent: Int { Int(entry.batteryLevel * 100) }
    
    private var batteryIcon: String {
        switch entry.batteryLevel {
        case 0..<0.1: return "battery.0percent"
        case 0.1..<0.25: return "battery.25percent"
        case 0.25..<0.5: return "battery.50percent"
        case 0.5..<0.75: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
    
    private var batteryColor: Color {
        switch entry.batteryLevel {
        case 0..<0.2: return .red
        case 0.2..<0.5: return .orange
        default: return .green
        }
    }
}

// MARK: - Activity Rings View
struct ActivityRingsView: View {
    let move: Double, exercise: Double, stand: Double
    var size: CGFloat = 50, lineWidth: CGFloat = 6
    
    var body: some View {
        ZStack {
            ring(progress: move, color: .red, gradient: [.red, .pink], diameter: size)
            ring(progress: exercise, color: .green, diameter: size - lineWidth * 2 - 4)
            ring(progress: stand, color: .cyan, diameter: size - lineWidth * 4 - 8)
        }
        .frame(width: size, height: size)
    }
    
    private func ring(progress: Double, color: Color, gradient: [Color]? = nil, diameter: CGFloat) -> some View {
        ZStack {
            Circle().stroke(color.opacity(0.3), lineWidth: lineWidth).frame(width: diameter, height: diameter)
            Circle().trim(from: 0, to: min(progress, 1.0))
                .stroke(gradient != nil ? AnyShapeStyle(LinearGradient(colors: gradient!, startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(color),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: diameter, height: diameter)
        }
    }
}

// MARK: - Widget Configuration
struct Daily_Info_Grid: Widget {
    let kind = "Daily_Info_Grid"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Info")
        .description("Your day at a glance — date, weather, battery, and calendar.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) { Daily_Info_Grid() } timeline: { WidgetEntry.placeholder }
#Preview("Medium", as: .systemMedium) { Daily_Info_Grid() } timeline: { WidgetEntry.placeholder }
#Preview("Large", as: .systemLarge) { Daily_Info_Grid() } timeline: { WidgetEntry.placeholder }
#Preview("Lock Screen", as: .accessoryCircular) { Daily_Info_Grid() } timeline: { WidgetEntry.placeholder }
