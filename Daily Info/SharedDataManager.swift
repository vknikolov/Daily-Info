//
//  SharedDataManager.swift
//  Daily Info
//
//  Created by Veselin Nikolov on 14.01.26.
//

import Foundation
import UIKit
import WidgetKit
import EventKit
import WeatherKit
import CoreLocation
import HealthKit

// MARK: - Constants
private enum AppGroup {
    static let suiteName = "group.com.daily_info.widget"
}

private enum StorageKeys {
    // Toggles
    static let showWeather = "showWeather"
    static let showBattery = "showBattery"
    static let showCalendar = "showCalendar"
    static let showActivityRings = "showActivityRings"
    // Battery
    static let lastBatteryLevel = "lastBatteryLevel"
    // Weather
    static let lastKnownTemperature = "lastKnownTemperature"
    static let lastKnownWeatherSymbol = "lastKnownWeatherSymbol"
    // Calendar
    static let nextEventTitle = "nextEventTitle"
    static let nextEventTime = "nextEventTime"
    // Activity Rings
    static let moveCalories = "moveCalories"
    static let moveGoal = "moveGoal"
    static let exerciseMinutes = "exerciseMinutes"
    static let exerciseGoal = "exerciseGoal"
    static let standHours = "standHours"
    static let standGoal = "standGoal"
}

// MARK: - Shared Data Manager
@MainActor
final class SharedDataManager: NSObject, CLLocationManagerDelegate {
    static let shared = SharedDataManager()
    
    // MARK: - Dependencies
    private let defaults: UserDefaults?
    private let eventStore = EKEventStore()
    private let locationManager = CLLocationManager()
    private let weatherService = WeatherService.shared
    private let healthStore = HKHealthStore()
    
    // MARK: - Initialization
    private override init() {
        defaults = UserDefaults(suiteName: AppGroup.suiteName)
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - Toggle Properties
    var showWeather: Bool {
        get { boolValue(for: StorageKeys.showWeather, defaultValue: true) }
        set { setBool(newValue, for: StorageKeys.showWeather) }
    }
    
    var showBattery: Bool {
        get { boolValue(for: StorageKeys.showBattery, defaultValue: true) }
        set { setBool(newValue, for: StorageKeys.showBattery) }
    }
    
    var showCalendar: Bool {
        get { boolValue(for: StorageKeys.showCalendar, defaultValue: true) }
        set { setBool(newValue, for: StorageKeys.showCalendar) }
    }
    
    var showActivityRings: Bool {
        get { boolValue(for: StorageKeys.showActivityRings, defaultValue: true) }
        set { setBool(newValue, for: StorageKeys.showActivityRings) }
    }
    
    // MARK: - Data Properties
    var lastBatteryLevel: Float {
        get { defaults?.float(forKey: StorageKeys.lastBatteryLevel) ?? 0.75 }
        set { setFloat(newValue, for: StorageKeys.lastBatteryLevel) }
    }
    
    var lastKnownTemperature: String {
        get { defaults?.string(forKey: StorageKeys.lastKnownTemperature) ?? "—" }
        set { setString(newValue, for: StorageKeys.lastKnownTemperature) }
    }
    
    var lastKnownWeatherSymbol: String {
        get { defaults?.string(forKey: StorageKeys.lastKnownWeatherSymbol) ?? "cloud.fill" }
        set { setString(newValue, for: StorageKeys.lastKnownWeatherSymbol) }
    }
    
    var nextEventTitle: String {
        get { defaults?.string(forKey: StorageKeys.nextEventTitle) ?? "No events" }
        set { setString(newValue, for: StorageKeys.nextEventTitle) }
    }
    
    var nextEventTime: Date? {
        get { defaults?.object(forKey: StorageKeys.nextEventTime) as? Date }
        set { setDate(newValue, for: StorageKeys.nextEventTime) }
    }
    
    // MARK: - Activity Ring Properties
    var moveCalories: Double {
        get { defaults?.double(forKey: StorageKeys.moveCalories) ?? 0 }
        set { setDouble(newValue, for: StorageKeys.moveCalories) }
    }
    
    var moveGoal: Double {
        get { max(defaults?.double(forKey: StorageKeys.moveGoal) ?? 500, 1) }
        set { setDouble(newValue, for: StorageKeys.moveGoal) }
    }
    
    var exerciseMinutes: Double {
        get { defaults?.double(forKey: StorageKeys.exerciseMinutes) ?? 0 }
        set { setDouble(newValue, for: StorageKeys.exerciseMinutes) }
    }
    
    var exerciseGoal: Double {
        get { max(defaults?.double(forKey: StorageKeys.exerciseGoal) ?? 30, 1) }
        set { setDouble(newValue, for: StorageKeys.exerciseGoal) }
    }
    
    var standHours: Double {
        get { defaults?.double(forKey: StorageKeys.standHours) ?? 0 }
        set { setDouble(newValue, for: StorageKeys.standHours) }
    }
    
    var standGoal: Double {
        get { max(defaults?.double(forKey: StorageKeys.standGoal) ?? 12, 1) }
        set { setDouble(newValue, for: StorageKeys.standGoal) }
    }
    
    // MARK: - UserDefaults Helpers
    private func boolValue(for key: String, defaultValue: Bool) -> Bool {
        defaults?.object(forKey: key) == nil ? defaultValue : defaults!.bool(forKey: key)
    }
    
    private func setBool(_ value: Bool, for key: String) {
        defaults?.set(value, forKey: key)
        saveAndReload()
    }
    
    private func setFloat(_ value: Float, for key: String) {
        defaults?.set(value, forKey: key)
        defaults?.synchronize()
    }
    
    private func setString(_ value: String, for key: String) {
        defaults?.set(value, forKey: key)
        defaults?.synchronize()
    }
    
    private func setDouble(_ value: Double, for key: String) {
        defaults?.set(value, forKey: key)
        defaults?.synchronize()
    }
    
    private func setDate(_ value: Date?, for key: String) {
        defaults?.set(value, forKey: key)
        defaults?.synchronize()
    }
    
    private func saveAndReload() {
        defaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Battery Monitoring
extension SharedDataManager {
    func startBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateBatteryLevel()
        }
        
        [UIDevice.batteryLevelDidChangeNotification, UIDevice.batteryStateDidChangeNotification].forEach { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateBatteryLevel()
                }
            }
        }
    }
    
    func updateBatteryLevel() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        
        if level >= 0 {
            lastBatteryLevel = level
            saveAndReload()
        } else if UIDevice.current.batteryState == .unknown {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.updateBatteryLevel()
            }
        }
    }
}

// MARK: - Weather (WeatherKit)
extension SharedDataManager {
    func startWeatherUpdates() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in await fetchWeather(for: location) }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus) {
                locationManager.requestLocation()
            }
        }
    }
    
    private func fetchWeather(for location: CLLocation) async {
        do {
            let weather = try await weatherService.weather(for: location)
            let temp = weather.currentWeather.temperature
            lastKnownTemperature = "\(Int(round(temp.value)))\(temp.unit == .celsius ? "°" : "°F")"
            lastKnownWeatherSymbol = weather.currentWeather.symbolName
            saveAndReload()
        } catch {}
    }
}

// MARK: - Calendar
extension SharedDataManager {
    func startCalendarMonitoring() {
        updateNextEvent()
        
        [Notification.Name.EKEventStoreChanged, UIApplication.didBecomeActiveNotification].forEach { name in
            NotificationCenter.default.addObserver(forName: name, object: name == .EKEventStoreChanged ? eventStore : nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.updateNextEvent() }
            }
        }
    }
    
    func updateNextEvent() {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status.rawValue == 3 || status.rawValue == 1 else {
            nextEventTitle = "Enable calendar access"
            nextEventTime = nil
            saveAndReload()
            return
        }
        
        eventStore.refreshSourcesIfNecessary()
        
        let now = Date()
        guard let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return }
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: eventStore.calendars(for: .event))
        let events = eventStore.events(matching: predicate)
        
        if let timedEvent = events.filter({ !$0.isAllDay }).sorted(by: { $0.startDate < $1.startDate }).first {
            nextEventTitle = timedEvent.title ?? "Untitled"
            nextEventTime = timedEvent.startDate
        } else if let allDayEvent = events.filter({ $0.isAllDay }).sorted(by: { $0.startDate < $1.startDate }).first {
            nextEventTitle = allDayEvent.title ?? "Untitled"
            nextEventTime = allDayEvent.startDate
        } else {
            nextEventTitle = "No events"
            nextEventTime = nil
        }
        
        saveAndReload()
    }
    
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            if granted { updateNextEvent() }
            return granted
        } catch { return false }
    }
}

// MARK: - HealthKit / Activity Rings
extension SharedDataManager {
    var isHealthKitAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    
    func requestHealthKitAccess() async -> Bool {
        guard isHealthKitAvailable,
              let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let exerciseTime = HKObjectType.quantityType(forIdentifier: .appleExerciseTime),
              let standTime = HKObjectType.quantityType(forIdentifier: .appleStandTime) else { return false }
        
        let typesToRead: Set<HKObjectType> = [HKObjectType.activitySummaryType(), activeEnergy, exerciseTime, standTime]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            updateActivityRings()
            return true
        } catch { return false }
    }
    
    func updateActivityRings() {
        guard isHealthKitAvailable else { return }
        
        var components = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
        components.calendar = Calendar.current
        
        let query = HKActivitySummaryQuery(predicate: HKQuery.predicateForActivitySummary(with: components)) { [weak self] _, summaries, error in
            Task { @MainActor [weak self] in
                guard let self, error == nil, let summary = summaries?.first else { return }
                self.moveCalories = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
                self.moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
                self.exerciseMinutes = summary.appleExerciseTime.doubleValue(for: .minute())
                self.exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
                self.standHours = summary.appleStandHours.doubleValue(for: .count())
                self.standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())
                self.saveAndReload()
            }
        }
        healthStore.execute(query)
    }
    
    func startActivityMonitoring() {
        updateActivityRings()
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateActivityRings() }
        }
    }
}

// MARK: - Refresh All
extension SharedDataManager {
    func refreshAllData() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBatteryLevel()
        updateNextEvent()
        startWeatherUpdates()
        updateActivityRings()
    }
}
