# MovieVerse

MovieVerse is a Flutter-based mobile application that allows users to discover, explore, and view detailed information about movies using data from the TMDb API. It supports Firebase-based user authentication and stores user data in Firestore. The app follows an MVVM architecture with a modular, clean folder structure and Provider-based state management.

## Setup and Run Locally

Follow the steps below to set up and run MovieVerse on your machine:

### 1. Clone the Repository

```bash
git clone https://github.com/mqasim41/movieverse.git
cd movieverse
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

- Replace `firebase_options.dart` with your actual Firebase configuration.
- Or run the following (requires FlutterFire CLI):

```bash
flutterfire configure
```

### 4. Insert TMDb API Key

- Open `tmdb_api_service.dart` or wherever the API call is configured.
- Replace the placeholder with your own TMDb API key.

### 5. Run the App

```bash
flutter run
```

## Features

- User login and registration using Firebase Auth
- Movie list view with trending and popular titles
- Detailed movie screen with title, overview, and poster
- Secure data storage using Firestore
- MVVM architecture with Provider state management
- Reusable widget components and modular codebase

## Screens

- **Login Screen** – authenticates existing users
- **Register Screen** – allows new users to sign up
- **Home Screen** – displays popular/trending movies
- **Movie Detail Screen** – shows selected movie’s full information
- **Profile Screen** – shows user info and logout option

## Tools and Technologies

- Flutter & Dart
- Firebase Authentication
- Cloud Firestore
- TMDb API
- Provider (State Management)
- Modular folder structure with MVVM principles

## Folder Structure

```
lib/
├── models/              # Data models (e.g., Movie, User)
├── screens/             # UI screens (Login, Register, Home, etc.)
├── services/            # API and business logic (Auth, TMDb)
├── viewmodels/          # ViewModels for screens
├── utils/               # Helper methods and constants
└── widgets/             # Reusable UI widgets
```

## Architecture

The app is built using the Model-View-ViewModel (MVVM) design pattern.

- **Models**: Define data structures used in the app
- **Views**: Represented by UI in the screens folder
- **ViewModels**: Connect UI with business logic and service calls
- **Services**: Handle authentication, movie API, and Firestore operations

## Testing

You can run tests using the following command:

```bash
flutter test
```

## License

This project is licensed under the MIT License.

## Authors

Farooq, Qasim, Affan, Hamza  
MovieVerse: Mobile Application Development Semester Project (2025)
