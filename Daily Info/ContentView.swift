//
//  ContentView.swift
//  Daily Info
//
//  Created by Veselin Nikolov on 14.01.26.
//

import SwiftUI
import WidgetKit
import EventKit

// MARK: - Content View
struct ContentView: View {
    @State private var showWeather: Bool
    @State private var showBattery: Bool
    @State private var showCalendar: Bool
    @State private var showActivityRings: Bool
    @State private var calendarAccessGranted = false
    @State private var healthKitAccessGranted = false
    @State private var showingCalendarAlert = false
    @State private var isRefreshing = false
    @State private var appearAnimation = false
    
    private let dataManager = SharedDataManager.shared
    
    init() {
        let manager = SharedDataManager.shared
        _showWeather = State(initialValue: manager.showWeather)
        _showBattery = State(initialValue: manager.showBattery)
        _showCalendar = State(initialValue: manager.showCalendar)
        _showActivityRings = State(initialValue: manager.showActivityRings)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroHeader
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : -20)
                    
                    widgetPreviewCard
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    
                    componentsSection
                        .opacity(appearAnimation ? 1 : 0)
                    
                    actionsSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                }
                .padding(.vertical)
            }
            .background(backgroundGradient)
            .navigationTitle("Daily Info")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: onAppear)
            .alert("Calendar Access", isPresented: $showingCalendarAlert) {
                Button("Open Settings") { openSettings() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable calendar access in Settings to show upcoming events.")
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Hero Header
    private var heroHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(spacing: 4) {
                Text("Your Widget")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Customize your home screen experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal)
    }
    
    // MARK: - Widget Preview Card
    private var widgetPreviewCard: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            HStack(spacing: 0) {
                dateSection
                
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                infoSection
            }
            .padding(20)
            .background(previewCardBackground)
        }
        .padding(.horizontal)
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date(), format: .dateTime.weekday(.wide))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(Date(), format: .dateTime.day())
                .font(.system(size: 44, weight: .bold, design: .rounded))
            
            Text(Date(), format: .dateTime.month(.wide))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showWeather {
                previewRow(icon: "sun.max.fill", text: "22°", color: nil, multicolor: true)
            }
            if showBattery {
                previewRow(icon: "battery.75percent", text: "75%", color: .green)
            }
            if showCalendar {
                previewRow(icon: "calendar", text: "Next Event", color: .red)
            }
            if showActivityRings {
                activityRingsPreview
            }
            if !showWeather && !showBattery && !showCalendar && !showActivityRings {
                previewRow(icon: "square.dashed", text: "No items", color: .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
        .animation(.spring(response: 0.4), value: showWeather)
        .animation(.spring(response: 0.4), value: showBattery)
        .animation(.spring(response: 0.4), value: showCalendar)
        .animation(.spring(response: 0.4), value: showActivityRings)
    }
    
    private func previewRow(icon: String, text: String, color: Color?, multicolor: Bool = false) -> some View {
        HStack(spacing: 8) {
            if multicolor {
                Image(systemName: icon).symbolRenderingMode(.multicolor)
            } else {
                Image(systemName: icon).foregroundStyle(color ?? .primary)
            }
            Text(text).fontWeight(.medium)
        }
        .font(.subheadline)
        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
    }
    
    private var activityRingsPreview: some View {
        HStack(spacing: 8) {
            ZStack {
                ringPair(size: 24, progress: 0.7, color: .red)
                ringPair(size: 17, progress: 0.6, color: .green)
                ringPair(size: 10, progress: 0.8, color: .cyan)
            }
            .frame(width: 28, height: 28)
            Text("Activity").font(.caption)
        }
        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
    }
    
    private func ringPair(size: CGFloat, progress: CGFloat, color: Color) -> some View {
        ZStack {
            Circle().stroke(color.opacity(0.3), lineWidth: 3).frame(width: size, height: size)
            Circle().trim(from: 0, to: progress).stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: size, height: size).rotationEffect(.degrees(-90))
        }
    }
    
    private var previewCardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.2), lineWidth: 1))
    }
    
    // MARK: - Components Section
    private var componentsSection: some View {
        VStack(spacing: 12) {
            Text("Components")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            toggleCard(icon: "sun.max.fill", title: "Weather", subtitle: "Current temperature", color: .orange, isOn: $showWeather, delay: 0.1)
            toggleCard(icon: "battery.100percent.bolt", title: "Battery", subtitle: "Battery percentage", color: .green, isOn: $showBattery, delay: 0.2)
            toggleCard(icon: "calendar.badge.clock", title: "Calendar", subtitle: "Upcoming events", color: .red, isOn: $showCalendar, delay: 0.3)
            toggleCard(icon: "figure.run.circle.fill", title: "Activity Rings", subtitle: "Move, Exercise, Stand", color: .pink, isOn: $showActivityRings, delay: 0.4)
        }
        .padding(.horizontal)
    }
    
    private func toggleCard(icon: String, title: String, subtitle: String, color: Color, isOn: Binding<Bool>, delay: Double) -> some View {
        AnimatedToggleCard(icon: icon, title: title, subtitle: subtitle, color: color, isOn: isOn, delay: delay)
            .onChange(of: isOn.wrappedValue) { _, newValue in
                withAnimation(.spring(response: 0.3)) {
                    switch title {
                    case "Weather": dataManager.showWeather = newValue
                    case "Battery": dataManager.showBattery = newValue
                    case "Calendar": dataManager.showCalendar = newValue
                    case "Activity Rings": dataManager.showActivityRings = newValue
                    default: break
                    }
                }
            }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Text("Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            ActionButton(icon: "calendar.badge.checkmark", title: "Calendar Access",
                        subtitle: calendarAccessGranted ? "Access granted" : "Tap to enable",
                        color: .blue, showCheckmark: calendarAccessGranted, action: requestCalendarAccess)
            
            ActionButton(icon: "heart.circle.fill", title: "Health Access",
                        subtitle: healthKitAccessGranted ? "Access granted" : "Tap to enable Activity Rings",
                        color: .pink, showCheckmark: healthKitAccessGranted, action: requestHealthKitAccess)
            
            ActionButton(icon: "arrow.triangle.2.circlepath", title: "Refresh Widget",
                        subtitle: "Update widget now", color: .purple, isLoading: isRefreshing, action: refreshWidget)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    private func onAppear() {
        checkCalendarAccess()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            appearAnimation = true
        }
    }
    
    private func checkCalendarAccess() {
        withAnimation(.spring(response: 0.3)) {
            calendarAccessGranted = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        }
    }
    
    private func requestCalendarAccess() {
        Task {
            let granted = await dataManager.requestCalendarAccess()
            await MainActor.run {
                withAnimation(.spring(response: 0.3)) { calendarAccessGranted = granted }
                if !granted { showingCalendarAlert = true }
            }
        }
    }
    
    private func requestHealthKitAccess() {
        Task {
            let granted = await dataManager.requestHealthKitAccess()
            await MainActor.run {
                withAnimation(.spring(response: 0.3)) { healthKitAccessGranted = granted }
            }
        }
    }
    
    private func refreshWidget() {
        withAnimation(.spring(response: 0.3)) { isRefreshing = true }
        dataManager.refreshAllData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3)) { isRefreshing = false }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Animated Toggle Card
struct AnimatedToggleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool
    var delay: Double = 0
    
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(color.gradient).frame(width: 44, height: 44)
                Image(systemName: icon).font(.title3).foregroundStyle(.white).symbolEffect(.bounce, value: isOn)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(color)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.background).shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5))
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) { appeared = true }
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var showCheckmark = false
    var isLoading = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(color.gradient).frame(width: 44, height: 44)
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: icon).font(.title3).foregroundStyle(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body).fontWeight(.medium).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if showCheckmark {
                    Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(.green).symbolEffect(.bounce, value: showCheckmark)
                } else {
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(.background).shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
