# UniFind

UniFind is a Flutter and Firebase-based campus lost-and-found platform designed to help students and school staff report missing items, publish found-item notices, communicate safely, and coordinate recovery within a single school community. The app combines community posting, moderation, verification, chat, and notifications so that the process of recovering lost property is faster, more transparent, and easier to manage.


### Project Background

Lost items inside a school environment are usually handled through fragmented channels such as word of mouth, bulletin boards, classroom announcements, and informal social media posts. These methods are slow, hard to verify, and often fail to connect the rightful owner with the person who found the item.

UniFind was built as a digital response to that problem. Instead of relying on scattered communication, the platform gives students and administrators one place to:

- post lost and found reports
- identify users inside the campus community
- notify affected users in real time
- moderate suspicious or inappropriate content
- keep conversations related to item recovery inside the app

### Problem Statement

The traditional lost-and-found process in a college setting has four common weaknesses:

1. Reports are not centralized.
2. Claimants and finders are difficult to verify.
3. Updates are not delivered quickly to the right people.
4. School staff have limited tools for moderation and account approval.

UniFind addresses those gaps by combining identity-aware registration, role-based access, post management, messaging, and notification flows in one mobile-first system.

### Project Goal

The main goal of UniFind is to create a secure and organized campus lost-and-found application that improves the visibility of lost-item reports while reducing impersonation, misinformation, and response delays.

### Target Users

- Students who want to report lost items or return found ones
- School staff or designated moderators who verify users and review reports
- Campus community members who need a safer and more structured recovery process

## Solution Summary

UniFind uses a role-based workflow:

- Regular users create an account, submit profile details, and upload school ID images for review.
- Admins verify pending accounts before enabling full participation.
- Verified users can create lost-item, found-item, and announcement posts.
- Other users can comment, react, report, and contact each other through chat.
- The system stores in-app notifications and also surfaces selected events as local push-style alerts on device.

This creates a lightweight moderation loop that keeps participation tied to identifiable campus members instead of anonymous accounts.

## Core Features

### 1. Account Registration and Verification

New users provide their name, course, username, password, and school ID images. Account verification is reviewed by an admin before full access is granted. This reduces fake accounts and helps build trust between claimants and finders.

### 2. Role-Based Access

UniFind separates regular-user and administrator experiences. Users focus on posting, searching, chatting, and receiving updates. Admins can monitor reports, review users, and approve pending accounts.

### 3. Lost-and-Found Feed

The feed acts as the central information hub of the system. Users can create posts for:

- lost items
- found items
- announcements

This helps the community quickly discover relevant reports without depending on scattered external channels.

### 4. Search and Profile Viewing

The app includes search and profile navigation to help users find people, inspect posts, and track account identity before engaging in conversations.

### 5. Comments, Reactions, and Reporting

Posts and comments can be interacted with directly. Users can:

- comment on posts
- like posts or comments
- report posts, comments, or users

These actions support both engagement and moderation.

### 6. In-App Messaging

UniFind includes user-to-user messaging backed by Firestore conversation subcollections. This allows a finder and claimant to discuss handoff details privately without moving to another platform.

### 7. Notifications

The app stores notifications under each user document and can also show local notifications for selected events such as:

- new posts
- account verification
- direct message-related events

This keeps users updated even when they are not actively browsing the feed.

### 8. Password Recovery

The project includes an email-based reset-code workflow for password recovery, giving users a way back into their account without manual admin intervention.

## System Workflow

### User Flow

1. The user signs up and submits personal details with school ID images.
2. The account remains pending until verification.
3. Once approved, the user can browse the feed, create posts, interact with content, and send messages.
4. Notifications help the user return to important activity such as chats or moderation updates.

### Admin Flow

1. The admin reviews pending accounts.
2. The admin verifies legitimate users.
3. The admin monitors reports and flagged content.
4. The admin uses the same ecosystem to keep the platform organized and safe.

## Technology Stack

### Frontend

- Flutter
- Dart

### Backend and Platform Services

- Firebase Core
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Cloud Functions for Firebase

### Supporting Packages

- `shared_preferences` for lightweight local session storage
- `image_picker` for image upload flows
- `flutter_local_notifications` for device-side notification display
- `http` for external email API requests
- `crypto` for password hashing in the current implementation

## Architecture Snapshot

The project currently follows a practical UI-first Flutter structure:

```text
lib/
  app.dart
  main.dart
  core/
    theme/
      app_colors.dart
  admin/
  screens/
  services/
  settings/
  user/
  widgets/
```

### Folder Responsibilities

- `lib/main.dart`: app bootstrap and Firebase initialization
- `lib/app.dart`: root `MaterialApp` configuration
- `lib/core/`: shared app-level primitives such as theme tokens
- `lib/models/`: shared typed data models
- `lib/repositories/`: Firestore-facing data access layer
- `lib/admin/`: administrator-facing screens and moderation flows
- `lib/user/`: regular-user pages such as feed, chat, profile, and notifications
- `lib/screens/`: shared screens like auth, loading, comments, and search
- `lib/services/`: non-UI logic such as chat, notifications, and email handling
- `lib/widgets/`: reusable view components
- `functions/`: Firebase Cloud Functions workspace

## Data and Platform Design

Based on the current codebase, the app relies heavily on Firestore collections such as:

- `users`
- `posts`
- `users/{username}/notifications`
- `users/{username}/conversations`

This design keeps user-centered activity grouped around each account while allowing the global feed to remain queryable through shared collections.

## Strengths of the Current Solution

- Centralizes lost-and-found communication in one platform
- Reduces anonymous or fake participation through admin verification
- Supports direct coordination through chat
- Improves response speed through notifications
- Combines social interaction and moderation in the same workflow
- Uses a cross-platform mobile stack that is practical for student projects and school pilots

## Current Limitations

The project is functional, but the current codebase still shows areas that can be improved for production quality:

- many UI screens still talk directly to Firestore instead of going through repositories or models
- some legacy analyzer warnings remain across async UI flows
- parts of the code still contain encoding issues in user-facing text
- chat and notification logic can still be broken into smaller feature-focused modules

## Recommended Next Steps

### Product Improvements

- add stronger item-claim verification flows
- support richer search and filtering by category, date, and location
- add audit history for moderation decisions
- add analytics for recovery success rate and average response time
- improve accessibility and text consistency across the interface

## Setup Notes

### Prerequisites

- Flutter SDK
- Firebase project configuration
- Android Studio or VS Code with Flutter tooling
- Node.js for the `functions/` workspace

### Local Development

1. Install Flutter dependencies with `flutter pub get`.
2. Install Cloud Functions dependencies with `npm install` inside `functions/`.
3. Configure Firebase for the target platforms.
4. Provide email configuration when testing password reset:
   Run with `flutter run --dart-define=SENDGRID_API_KEY=your_key --dart-define=SENDGRID_SENDER_EMAIL=your_sender@example.com`
5. Run the app with `flutter run`.

### Configuration and Secrets

Do not store production secrets directly in tracked source files. Local environment files, Firebase debug logs, function runtime config files, and local dependency folders are now ignored through `.gitignore`, but any existing tracked secrets should still be rotated and moved to safer configuration storage.

## Academic or Presentation Use

As a case study, UniFind demonstrates how a campus problem can be translated into a focused digital workflow using Flutter and Firebase. It is a good example of:

- applying role-based system design to a real school context
- combining social interaction with moderation controls
- using cloud-backed mobile features such as storage, chat, and notifications
- building a practical prototype around trust, verification, and community coordination

## Conclusion

UniFind is more than a generic posting app. It is a structured campus service concept that blends identity, moderation, messaging, and alerts into a single lost-and-found workflow. As a student or institutional case study, it shows strong practical value, a clear problem-solution fit, and a solid foundation for further refinement into a more production-ready platform.
