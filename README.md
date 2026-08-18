# University Social Network

## Description

University Social Network is a Flutter mobile application designed to manage groups or spaces related to university classes, activities, and clubs.

The application allows students to discover groups, join communities, interact with members, and share content within their groups.

Group administrators can manage groups, members, membership roles, publications, and interactions within their communities.

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
  * Association
  * Project
* Add a group description and image
* Search for groups
* Filter groups by type

### Member Management

* Join a group
* View group members
* Manage administrator and member roles
* Add members
* Remove members
* Leave a group
* Manage group administrator responsibilities

### Group Interaction

* Create publications
* Add multiple images to publications
* Like publications
* Add comments
* Reply to comments
* Like comments
* Edit and delete publications
* Edit and delete comments
* Display publication and comment counters

## Technologies

* Flutter
* Dart
* Android Studio
* Supabase
* Supabase Database
* Supabase Storage
* SQLite / sqflite for local application data

## Database

The application uses **Supabase** as the main backend database.

Supabase is used to store and synchronize groups, members, publications, comments, and likes.

### Main tables

* `groupes` — stores group information
* `utilisateurs` — stores local application users
* `membres_groupes` — manages group members and roles
* `publications` — stores publications
* `publication_images` — stores publication image URLs
* `commentaires` — stores comments and replies
* `likes_publications` — stores publication likes
* `likes_commentaires` — stores comment likes
* `profiles` — stores user profiles used for Supabase references

### Image Storage

Publication images are stored in **Supabase Storage**.

Storage bucket:

```text
publication-images
```

Images are uploaded to the `publications/` folder and their public URLs are stored in the `publication_images` table.

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

### 4. Configure Supabase

The application connects to the project's Supabase backend using:

* Supabase API URL
* Supabase Publishable Key

These values are required to initialize Supabase in the Flutter application.

The project uses the same Supabase project for the different application modules.

**Do not use or expose the Supabase Secret Key in the Flutter application or in the Git repository.**

### 5. Run the application

Start an Android emulator or connect an Android device, then run:

```bash
flutter run
```

## Requirements

* Flutter SDK
* Dart SDK
* Android Studio
* Android device or emulator
* Supabase project

## Backend

The backend is shared between the different modules of the application.

The group management module and the news feed module can use the same Supabase project and database.

## Author

**Mirandy Tianasoa Rakotoniaina**

M1 Student — Data Engineering

## Project Status

The project is functional and focuses on group and community management within a university social network.

The main group, publication, comment, like, and image storage features are currently connected to Supabase.
