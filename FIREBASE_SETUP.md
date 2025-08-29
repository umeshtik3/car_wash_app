d# Firebase Setup Guide for Car Wash App

## Prerequisites
- Flutter SDK installed
- Android Studio or VS Code
- Firebase account

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `car-wash-app` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

## Step 2: Enable Authentication

1. In Firebase Console, go to "Authentication" in the left sidebar
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" provider
5. Click "Save"

## Step 3: Enable Firestore Database

1. In Firebase Console, go to "Firestore Database" in the left sidebar
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to your users)
5. Click "Done"

## Step 4: Add Android App

1. In Firebase Console, click the gear icon next to "Project Overview"
2. Select "Project settings"
3. Scroll down to "Your apps" section
4. Click the Android icon to add Android app
5. Enter Android package name: `com.example.car_wash_app`
6. Enter app nickname: `Car Wash App`
7. Click "Register app"
8. Download the `google-services.json` file
9. Replace the placeholder file in `android/app/google-services.json` with the downloaded file

## Step 5: Install Dependencies

Run the following command in your project root:
```bash
flutter pub get
```

## Step 6: Test Firebase Connection

1. Run the app: `flutter run`
2. Check console for any Firebase initialization errors
3. If successful, you should see "Firebase initialized successfully" in the console

## Step 7: Security Rules (Optional for Development)

In Firestore Database > Rules, you can use these basic rules for development:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /users/{userId}/cars/{carId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    match /services/{serviceId} {
      allow read: if true;
    }
  }
}
```

## Troubleshooting

### Common Issues:

1. **"Google Services plugin not found"**
   - Make sure you've added the Google Services plugin in `android/build.gradle.kts`
   - Run `flutter clean` and `flutter pub get`

2. **"Firebase not initialized"**
   - Check that `google-services.json` is in the correct location
   - Verify the package name matches in both files

3. **"Permission denied" errors**
   - Check Firestore security rules
   - Ensure authentication is properly set up

4. **Build errors**
   - Run `flutter clean`
   - Delete `build/` folder
   - Run `flutter pub get` again

## Next Steps

After successful Firebase setup:
1. Test authentication flow (signup/login)
2. Test Firestore operations (save/retrieve data)
3. Implement the remaining backend tasks from your task list
4. Add proper error handling and loading states

## Support

If you encounter issues:
1. Check Firebase Console for error logs
2. Verify all configuration files are correct
3. Check Flutter and Firebase plugin versions compatibility
4. Refer to [Firebase Flutter documentation](https://firebase.flutter.dev/)
