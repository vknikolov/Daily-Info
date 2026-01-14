# Daily Info

A beautiful iOS widget that displays your daily essentials at a glance — date, weather, battery level, calendar events, and activity rings.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![WidgetKit](https://img.shields.io/badge/WidgetKit-✓-green)

## Features

- 📅 **Date Display** — Current day, weekday, and month
- 🌤️ **Weather** — Real-time temperature with weather icons (WeatherKit)
- 🔋 **Battery Level** — Current battery percentage with color indicators
- 📆 **Calendar** — Next upcoming event with time (EventKit)
- 💪 **Activity Rings** — Move, Exercise, and Stand progress (HealthKit)

## Widget Sizes

| Small | Medium | Large | Lock Screen |
|-------|--------|-------|-------------|
| Compact daily overview | Grid layout with all info | Detailed view with stats | Circular & rectangular |

## Deep Links

Tap on widget elements to open corresponding apps:
- **Weather** → Weather app
- **Calendar** → Calendar app  
- **Activity Rings** → Fitness app

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Apple Developer Account (for WeatherKit)

## Permissions

The app requests access to:
- 📍 Location (for weather)
- 📅 Calendar (for events)
- ❤️ Health (for activity rings)

## Installation

1. Clone the repository
2. Open `Daily Info.xcodeproj` in Xcode
3. Configure your development team
4. Enable required capabilities:
   - App Groups: `group.com.daily_info.widget`
   - HealthKit
   - WeatherKit
5. Build and run

## Project Structure

```
Daily Info/
├── Daily Info/              # Main app
│   ├── ContentView.swift    # Main UI with toggles
│   ├── SharedDataManager.swift  # Data management
│   └── Daily_InfoApp.swift  # App entry point
├── Daily Info Grid/         # Widget extension
│   ├── Daily_Info_Grid.swift    # Widget views
│   └── Daily_Info_GridBundle.swift
└── Daily Info.xcodeproj
```

## License

MIT License

## Author

Veselin Nikolov
