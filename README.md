# WilliDreams Open
A dream tracking app with social features

### Introduction
WilliDreams, originally released March 31, 2025 is a dream journal iOS and macOS app with the ability to share dreams with other users using SwiftUI, SwiftData and Firebase. WilliDream's final update (v1.4) has released on December 3, 2025 and the app is no longer recieving updates.

### Download
You can find WilliDreams here:
https://apps.apple.com/us/app/willidreams/id6553981777

### Features
- Journaling for your dreams
- Dreams rating system
- Friends list with sharing with other friends
- AI summarization of dreams using FirebaseAI and Apple's Foundation Models frameworks
- Sign in and Sign up with Firebase

### Instructions
Setting up WilliDreams is very simple. Here is what you will need:
- Xcode 26.0 or newer
- Google Account

Once you have your Google account ready, head over to https://firebase.google.com/

Create a Firebase project

Enable the features
- Authentication
- Firestore Database
- Storage

In Firestore Database, create a Standard edition database. Start in Production mode.

Once you have your Database created, add a collection with the Collection ID of "UserDreams", then create a Placeholder document.

Head to the Rules tab and type the following in:
```javascript
match /Users/{userId} {
  allow read, write, create, update: if request.auth != null;
}

match /UserDreams/{userID}/dreams/{dreamID} {
  allow create, update, delete: if request.auth != null;
}
```

After that, you are ready to open the Xcode project!
Modify your Bundle Identifier in Xcode. Copy your bundle identifier.

In your Firebase's Project's home menu, hit "Add app", then iOS.

Follow the instructions on the screen!

Download the Config File, and add it to your Xcode project!

Congrats! You now have a working copy of WilliDreams! 

### Conclusion
I am really excited to see what all of you do with WilliDreams' code! Please DM me on Instagram @willgallegos3607, or on X @WilliApple to show me what you do with WilliDreams, whether its just using the Firebase feature of the project, or expanding on the concept of WilliDreams, I am excited to see what you do!
