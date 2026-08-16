# University Social Network

## Description

University Social Network is a Flutter mobile application designed to manage groups or spaces related to university classes, activities, and clubs.

The application allows students to discover groups, join communities, interact with members, and share content within their groups.

Group administrators can manage groups, members, membership requests, and administrator roles.

This project was developed as part of a university project based on the theme:

**"Manage groups or spaces related to a class, activity, or club."**

## Features

### Group Management

* Create a group
* Edit group information
* Delete a group
* Choose the group type:

    * Class
    * Activity
    * Club
* Add a group description and image
* Search for groups

### Member Management

* Request to join a group
* Accept or reject membership requests
* Add members directly as an administrator
* Remove members
* View group members
* Manage administrator and member roles
* Transfer administrator responsibilities
* Leave a group
* Prevent an administrator from leaving without transferring responsibility

### Group Interaction

* Create publications
* Add images to publications
* Like publications
* Add comments
* Reply to comments
* Edit and delete publications
* Edit and delete comments

## Technologies

* Flutter
* Dart
* SQLite
* sqflite
* Android Studio

## Database

The application uses SQLite for local data storage.

Main tables:

* `groupes` — stores group information
* `utilisateurs` — stores users
* `membres_groupes` — manages group members, roles, and membership status
* `publications` — stores publications
* `commentaires` — stores comments and replies

## Project Structure

```text
lib/
├── database/
│   └── database_helper.dart
│
├── models/
│   ├── groupe.dart
│   ├── publication.dart
│   ├── commentaire.dart
│   └── utilisateurs.dart
│
├── pages/
│   ├── home_page.dart
│   ├── groupe_page.dart
│   └── membres_page.dart
│
└── main.dart
```

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/mirandyrakotoniaina/university-social-network.git
```

### 2. Open the project

Open the project with Android Studio.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the application

Start an Android emulator or connect an Android device, then run:

```bash
flutter run
```

## Requirements

* Flutter SDK
* Dart SDK
* Android Studio
* Android device or emulator

## Author

**Mirandy Tianasoa Rakotoniaina**

M1 Student — Data Engineering

## Project Status

The project is functional and focuses on group and community management within a university social network.
