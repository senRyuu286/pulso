<h1 align="center">
  Pulso
</h1>

<p align="center">
  <em>A living, breathing feed of community moments.</em>
</p>

<p align="center">
  <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://supabase.com/"><img src="https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white" alt="Supabase"></a>
  <a href="https://riverpod.dev/"><img src="https://img.shields.io/badge/Riverpod-000000?style=flat-square&logo=riverpod&logoColor=white" alt="Riverpod"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-In_Development-yellow?style=flat-square" alt="Status">
</p>

---

**Pulso** is a mobile community social application built with **Flutter** and powered by **Supabase**. The name "Pulso" is the Filipino word for "pulse," reflecting the app's mission to provide a real-time, synchronized feed of community activity.

## Why Pulso?

In the modern digital landscape, social products rely on four critical foundations: cloud authentication, secure storage, real-time data synchronization, and robust access control. Pulso implements all four using a modern tech stack to create a seamless, reactive user experience.

## Features

- **User Authentication** — Secure email/password registration and login via Supabase Auth with persistent sessions.
- **Dynamic Profiles** — Personalized user profiles with editable bios and avatar uploads to Supabase Storage.
- **Interactive Post Feed** — Share community moments with images and captions, displayed in a reverse-chronological infinite scroll.
- **Real-Time Reactions** — Like and unlike posts with counts that update instantly across all devices via Supabase Realtime.
- **Community Conversations** — Real-time comment threads allowing users to engage with posts and manage their own contributions.
- **Social Graph** — A follow/unfollow system to build relationships and track community engagement.

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter |
| **Language** | Dart |
| **State Management** | Riverpod  |
| **Backend** | Supabase  |
| **Navigation** | GoRouter |
| **Testing** | flutter_test + Mockito |

## Setup & Environment

To protect sensitive credentials, this project uses environment variables for Supabase configuration.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/senRyuu286/pulso.git
   cd pulso
   ```

2. **Configure environment variables:**
   Copy the example environment file and fill in your Supabase credentials:
   ```bash
   cp .env.example .env
   ```
   Ensure your `.env` file contains the following keys (found in your Supabase Project Settings > API):
   * `SUPABASE_URL`: Your Supabase project URL.
   * `SUPABASE_PUBLISHABLE_KEY`: Your Supabase anonymous (anon) public key.

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   You can run the app using the `.env` file or by passing variables directly via `--dart-define`:
   ```bash
   flutter run --dart-define-from-file=.env
   ```

## App Screenshots
*TBI (To Be Inserted)*

## Course Context
Developed for the **Mobile Applications Development** course (Semester 2 Group Project) over a 14-day sprint.

## N.A.P.S. (Nearly All Programmers Sleeping)
A dedicated team of developers working through the night to bring the Pulso community experience to life, one late-night commit at a time.
- [Justin Ramas (senRyuu286)](https://github.com/senRyuu286)
- [John Anthony Romeo (lemonJAR)](https://github.com/lemonJAR)
- [Joel Franco Navales (JoelNavales)](https://github.com/JoelNavales)

---

<p align="center">
  Built with purpose — <em>Pulso Community Social.</em>
</p>