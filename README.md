# Habesha Expense Tracker

A Flutter-based mobile application for automatically tracking expenses from CBE (Commercial Bank of Ethiopia) SMS transaction notifications. This app works entirely offline, parsing SMS messages to extract transaction details and providing comprehensive expense tracking and analytics.

## Features

- 📱 **Automatic SMS Parsing**: Automatically detects and parses CBE transaction SMS messages
- 💰 **Transaction Tracking**: Tracks all debit and credit transactions with detailed information
- 📊 **Analytics Dashboard**: Visual charts and statistics for spending patterns
- 🔒 **PIN Protection**: Secure your financial data with a 6-digit PIN lock
- 🌙 **Dark Mode**: Support for light, dark, and system theme modes
- 📈 **Category Management**: Organize transactions by custom categories
- 🔍 **Transaction History**: View and search through all past transactions
- 📅 **Date Range Filtering**: Filter transactions by custom date ranges
- 💾 **Offline First**: All data stored locally using SQLite - no internet required

## Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod
- **Database**: SQLite (via sqflite)
- **Charts**: fl_chart
- **SMS Handling**: telephony_fix
- **Permissions**: permission_handler

## Project Structure

```
lib/
├── core/
│   ├── constants/      # Database constants and message types
│   ├── services/        # Core services (SMS, permissions, PIN)
│   └── sms/            # SMS parsing logic
├── data/
│   ├── dao/           # Data Access Objects
│   ├── db/            # Database setup
│   ├── models/        # Data models
│   └── repositories/  # Repository pattern implementation
└── presentation/
    ├── providers/     # Riverpod providers
    ├── screens/       # UI screens
    └── widgets/       # Reusable widgets
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Android device/emulator or iOS simulator

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Alpha-Mintamir/Habesha-Expense-Tracker.git
cd Habesha-Expense-Tracker
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Android Setup

The app requires SMS permissions to function. On first launch, the app will request necessary permissions.

**Note**: For Android 6.0+, SMS permissions must be granted manually through device settings.

## Usage

1. **First Launch**: Grant SMS permissions when prompted
2. **Initial Sync**: Choose a time period to scan past SMS messages (1 month, 3 months, etc.)
3. **Automatic Tracking**: The app will automatically detect and parse new CBE transaction SMS messages
4. **View Transactions**: Navigate to the Transactions tab to see all recorded transactions
5. **Analytics**: Check the Analytics tab for spending insights and charts
6. **Settings**: Configure PIN lock, theme, and other preferences

## Permissions

- **SMS Read Permission**: Required to read CBE transaction SMS messages
- **SMS Receive Permission**: Required to automatically detect new transactions

## Security

- All transaction data is stored locally on your device
- Optional PIN lock protection for app access
- No data is transmitted to external servers
- Works completely offline

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Disclaimer

This app is not affiliated with or endorsed by Commercial Bank of Ethiopia (CBE). It is an independent tool for personal expense tracking.

## Author

Alpha Mintamir

---

Made with ❤️ using Flutter
