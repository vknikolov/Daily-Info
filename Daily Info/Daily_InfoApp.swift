//
//  Daily_InfoApp.swift
//  Daily Info
//
//  Created by Veselin Nikolov on 14.01.26.
//

import SwiftUI
import WidgetKit

@main
struct Daily_InfoApp: App {
    
    init() {
        setupMonitoringServices()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL(perform: handleDeepLink)
        }
    }
}

// MARK: - Private Helpers
private extension Daily_InfoApp {
    
    func setupMonitoringServices() {
        let manager = SharedDataManager.shared
        manager.startBatteryMonitoring()
        manager.startCalendarMonitoring()
        manager.startWeatherUpdates()
    }
    
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "dailyinfo",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let target = components.queryItems?.first(where: { $0.name == "target" })?.value,
              let systemURL = systemURL(for: target)
        else { return }
        
        UIApplication.shared.open(systemURL)
    }
    
    func systemURL(for target: String) -> URL? {
        switch target {
        case "weather":
            return URL(string: "weather://")
        case "calendar":
            return URL(string: "calshow://")
        case "fitness":
            let fitnessURL = URL(string: "apple-fitness://")!
            return UIApplication.shared.canOpenURL(fitnessURL)
                ? fitnessURL
                : URL(string: "x-apple-health://")
        default:
            return nil
        }
    }
}
