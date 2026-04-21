<img width="368" height="673" alt="image" src="https://github.com/user-attachments/assets/6b635bef-c5b3-434b-89ed-c31f7cdbd04e" />

# BetAny

A social betting iOS app that lets you create and manage custom bets with friends using a virtual coin system.

## Features

- **User Authentication** — Sign up and log in securely via Firebase Auth
- **Create Bets** — Challenge any friend to a custom bet with a title, optional description, and coin amount
- **Bet Lifecycle** — Bets flow through statuses: `Pending → Accepted → Active → Completed`
- **Declare Winners** — Either player can declare who won; coins are transferred automatically
- **Friend System** — Search for users, send friend requests, accept/decline incoming requests, and remove friends
- **Daily Coin Claim** — Claim 1,000 free coins every 24 hours from the home screen
- **Coin Balance** — Win coins from bets; your balance is tracked in real time

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift |
| UI Framework | SwiftUI |
| Backend | Firebase (Auth + Firestore) |
| Local Storage | SwiftData |
| Package Manager | Swift Package Manager |

## Firebase SDK Dependencies

- `firebase-ios-sdk` v12.6.0
- `FirebaseAuth`
- `FirebaseFirestore`

## Project Structure

```
GamblingApp/
├── GamblingAppApp.swift      # App entry point, Firebase setup
├── ContentView.swift         # Root view (routes to login)
├── Bet.swift                 # Bet model + BetStatus enum
├── BetManager.swift          # Shared data manager (Firestore, coins, friends)
├── loginview.swift           # Login screen
├── SignUpView.swift           # Sign up screen
├── HomePageView.swift         # Main feed (pending & active bets)
├── CreateBetView.swift        # Create a new bet
├── BetDetailView.swift        # Bet detail + accept/decline/winner actions
├── FriendsView.swift          # Friends list
├── FriendRequestsView.swift   # Incoming friend requests
├── FriendSelectorView.swift   # Pick a friend when creating a bet
└── UserSearchView.swift       # Search for users to add as friends
```

## Getting Started

### Prerequisites

- Xcode 15+
- iOS 17+ deployment target
- A Firebase project with **Authentication** (Email/Password) and **Firestore** enabled

### Setup

1. Clone the repository.
2. Open `GamblingApp.xcodeproj` in Xcode.
3. Replace `GamblingApp/GoogleService-Info.plist` with your own Firebase project's `GoogleService-Info.plist`.
4. Build and run on a simulator or device (iOS 17+).

### Firestore Rules

A `firestore.rules` file is included at the project root. Deploy it to your Firebase project to set up the correct security rules.

```bash
firebase deploy --only firestore:rules
```

## How It Works

1. **Sign up / Log in** with an email and password.
2. **Search for friends** using the people icon on the home screen and send friend requests.
3. **Accept friend requests** from the sidebar menu under "Friend Requests".
4. **Create a bet** by tapping the "Create Bet" button, selecting a friend, entering a title and amount.
5. The recipient sees the bet as **Pending** and can accept or decline it.
6. Once accepted, the bet becomes **Active** — either player can then declare who won.
7. Coins are automatically transferred from the loser to the winner.
8. **Claim 1,000 free coins** daily from the coin claim button in the top-right corner.
