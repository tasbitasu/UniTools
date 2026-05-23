# UniTools

**An all-in-one calculator suite built with Flutter**

UniTools bundles four everyday calculation tools into a single polished app — a land measurement converter, a BMI calculator, a basic calculator, and a scientific calculator — each with persistent history powered by a local SQLite database.

---

## Features at a Glance

| # | Tool | What it does |
|---|------|--------------|
| 1 | **Land Measurement Converter** | Enter length × width in any linear unit and get instant area output in sq m, sq ft, Shotok, Katha, Bigha, and Acre |
| 2 | **BMI Calculator** | Calculate Body Mass Index from weight (kg / lbs) and height (ft+in, cm, or m) with health-status label |
| 3 | **Basic Calculator** | Standard arithmetic (+, −, ×, ÷) with chained operations and expression display |
| 4 | **Scientific Calculator** | Full scientific functions — sin/cos/tan (+ inverses), log/ln, √, x², xⁿ, π, e, n!, with DEG/RAD toggle |

All four tools save every calculation to a swipe-up **History Sheet** (SQLite, persists across app restarts). History can be filtered by tool type and cleared individually or all at once.

---

## Project Structure

```
lib/
├── main.dart                        # App entry, MaterialApp, HomeMenuScreen
├── db/
│   └── db_helper.dart               # SQLite singleton (sqflite): insert / fetchAll / delete
├── screens/
│   ├── land_converter_screen.dart   # Tool 1 — Land Measurement Converter
│   ├── bmi_calculator_screen.dart   # Tool 2 — BMI Calculator
│   ├── basic_calculator_screen.dart # Tool 3 — Basic Calculator
│   └── scientific_calculator_screen.dart  # Tool 4 — Scientific Calculator
└── widgets/
    └── history_sheet.dart           # Shared bottom-sheet history widget
assets/
└── logo.png                         # App logo (used in launcher icons & home screen)
```
---

## Architecture

```
HomeMenuScreen  (main.dart)
│
├──► LandConverterScreen
│         uses DBHelper (type: 'land')
│         uses HistorySheet
│
├──► BmiCalculatorScreen
│         uses DBHelper (type: 'bmi')
│         uses HistorySheet
│
├──► BasicCalculatorScreen
│         uses DBHelper (type: 'basic')
│         uses HistorySheet
│
└──► ScientificCalculatorScreen
          uses DBHelper (type: 'scientific')
          uses HistorySheet
```

**Navigation** is simple `Navigator.push` — no named routes or state-management library. Each screen is fully self-contained.

**Persistence** (`db/db_helper.dart`) is a singleton `DBHelper` wrapping a single `history` table:

```
history
  id          INTEGER PRIMARY KEY AUTOINCREMENT
  type        TEXT    ('basic' | 'scientific' | 'bmi' | 'land')
  expression  TEXT
  result      TEXT
  timestamp   TEXT    (ISO 8601)
```

The `HistorySheet` widget is reused across all four screens; it receives a `type` string to filter entries for the current tool.

---

## Screens in Detail

### 1. Land Measurement Converter (`land_converter_screen.dart`)

- Input: length and width, each with an independent unit dropdown (Meter, Foot, Inch, Yard, Centimeter, Millimeter).
- Converts internally to square meters then derives all output units.
- Output: sq m · sq ft · Shotok · Katha · Bigha · Acre
- Validates that both fields are non-empty positive numbers before calculating.
- Fade animation on results reveal; haptic feedback on button press.
- Color theme: blue gradient (`#1976D2` → `#26C6DA`).

### 2. BMI Calculator (`bmi_calculator_screen.dart`)

- Weight units: Kilogram (kg), Pound (lbs).
- Height modes: Foot + Inch (two separate fields), Centimeter, Meter.
- Displays numeric BMI and a color-coded health status (Underweight / Normal / Overweight / Obese).
- Scale animation on result reveal.
- Color theme: green/teal gradient (`#43A047` → `#4DB6AC`).

### 3. Basic Calculator (`basic_calculator_screen.dart`)

- Operations: +, −, ×, ÷ with chained-operation support (operator applied immediately when a second operator is pressed).
- Running expression shown above the main display.
- Backspace, clear (AC), and ± (sign toggle).
- Saves `expression → result` to history on `=`.
- Color theme: orange/amber gradient (`#F57C00` → `#FFCA28`).

### 4. Scientific Calculator (`scientific_calculator_screen.dart`)

- Functions: sin, cos, tan, sin⁻¹, cos⁻¹, tan⁻¹ (toggle via INV button), log, ln, √, x², xⁿ, n!, 1/x.
- Constants: π, e.
- DEG / RAD toggle for trig functions.
- Uses Dart's `dart:math` — no external expression parser.
- Color theme: purple/pink gradient (`#7B1FA2` → `#EC407A`).

---

## Dependencies

```yaml
# Runtime
flutter_sdk
cupertino_icons: ^1.0.8      # iOS-style icons
math_expressions: ^2.6.0     # Expression parsing (referenced in pubspec; scientific calc uses dart:math directly)
sqflite: ^2.3.3              # SQLite for calculation history
path: ^1.9.0                 # Database file path helpers

# Dev
flutter_lints: ^4.0.0
flutter_launcher_icons: ^0.14.1   # Generates launcher icons from assets/logo.png
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.5.0`
- Dart SDK included with Flutter
- Android Studio / Xcode for device targets

### Run

```bash
#Create flutter dependencies
flutter create .

#Install dependencies
flutter pub get

#Generate Launcher Icons (for custom icon)
flutter pub run flutter_launcher_icons
```
This reads `assets/logo.png` and generates all required sizes for Android (`mipmap-*`) and iOS (`AppIcon.appiconset`).

---
#Run on a connected device or emulator
flutter run


## Platform Support

| Platform | Status |
|----------|--------|
| Android  | ✅ Supported (min SDK 21) |
| iOS      | ✅ Supported |
| Linux    | ✅ Desktop Supported |
| Web / Windows / macOS | ✅ Desktop Supported |

The app is locked to portrait orientation (`DeviceOrientation.portraitUp`) on all platforms.

---

## Version
`1.0`

