# 🎬 RateIt — Movie Review App

A Flutter mobile application for browsing, rating, and reviewing movies using the TMDB API.

## ✨ Features

- 🎥 Browse trending, popular, now playing, and top-rated movies
- 🔍 Search movies by title
- ⭐ Rate and write reviews for movies
- 🎞️ Add movies to personal watchlist
- 👤 User registration and login (local SQLite database)

## 🛠️ Tech Stack

| Technology | Usage |
|---|---|
| Flutter | UI Framework |
| Dart | Programming Language |
| SQLite (sqflite) | Local Database |
| TMDB API | Movie Data |
| shared_preferences | Session Storage |
| crypto | Password Hashing (SHA-256) |

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.9.0`
- A TMDB API Key (free) — [Get one here](https://www.themoviedb.org/settings/api)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/rateit.git
   cd rateit
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up your API Key**

   This app uses `--dart-define` to inject the TMDB API key securely (no hardcoding).

   Run the app with your API key:
   ```bash
   flutter run --dart-define=TMDB_API_KEY=your_tmdb_api_key_here
   ```

   Or for a release build:
   ```bash
   flutter build apk --dart-define=TMDB_API_KEY=your_tmdb_api_key_here
   ```

   > ⚠️ **Never hardcode your API key in source code or commit it to Git.**

### Android Studio / VS Code

Add a run configuration with the `--dart-define` flag:

**Android Studio:** Edit Run Configuration → Additional run args:
```
--dart-define=TMDB_API_KEY=your_key_here
```

**VS Code** — add to `.vscode/launch.json`:
```json
{
  "configurations": [
    {
      "name": "Flutter (dev)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=TMDB_API_KEY=your_key_here"]
    }
  ]
}
```

## 📁 Project Structure

```
lib/
├── config/
│   └── app_config.dart       # API key & config (via dart-define)
├── api/
│   └── movie_api.dart        # TMDB API calls
├── database/
│   └── db_helper.dart        # SQLite database helper
├── pages/
│   ├── splash.dart
│   ├── login.dart
│   ├── register.dart
│   ├── main_page.dart
│   ├── home.dart
│   ├── movie_page.dart
│   ├── movie_detail.dart
│   ├── search_page.dart
│   ├── watchlist_page.dart
│   └── review_page.dart
└── main.dart
```

## 🔐 Security Notes

- Passwords are hashed with **SHA-256** before storage
- API Key is injected via `--dart-define` — never committed to source
- `.env` and `android/local.properties` are excluded from Git

## 📄 License

This project was created as an academic miniproject.
