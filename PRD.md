# Local Quiz Host App (Flutter)

## Overview

A locally hosted real-time quiz application built with Flutter. The system allows an administrator to create and run quiz sessions while participants join instantly through their web browsers using a QR code over a local network (LAN / Wi‑Fi hotspot). No internet connection is required.

---

## Core Concept

The application acts as a **quiz host + local server**, enabling real-time quiz gameplay for classrooms, workshops, events, and offline environments.

The admin uses the Flutter app to create quizzes and control sessions. Participants join via a lightweight browser interface.

---

## Primary Workflow

### 1. Quiz Creation (Admin)

The administrator can:

* Create a new quiz
* Add questions manually, with 4 options and 1 correct answer
* Import and Export questions (CSV / JSON)
* Configure quiz settings:

  * Time duration (per question or total)
  * Scoring mode
  * Randomization options

---

### 2. Quiz Session Setup

When starting a session:

* The app generates a **local IP address + port**
* A **QR Code** is displayed
* Optional **Session / Room Code** provided
* A local server is launched within the app

Displayed information:

* QR Code
* Join URL
* Live participant counter

---

### 3. Participant Join Flow (Browser)

Participants:

* Scan QR Code
* Open web interface
* Enter Team name
* Join waiting lobby

---

### 4. Live Quiz Phase

Admin controls quiz start.

Participants:

* Receive questions in real time
* Submit answers
* View countdown timer

Scoring Logic:

* Correctness-based scoring
* Speed bonus
* Optional streak multiplier

---

### 5. Results & Export

Admin dashboard provides:

* Live leaderboard
* Performance analytics
* CSV export of session results

Exported data may include:

* Participant name
* Score
* Accuracy
* Response times
* Question breakdown

---

## Key Features

### Essential (MVP)

* Quiz creation (manual + import)
* Multiple choice questions
* Local server hosting
* QR-based joining
* Real-time answering
* Speed-based scoring
* Leaderboard
* CSV export

---

## Question Types (Initial Support)

* Multiple Choice (Single Correct)
* Multiple Choice (Multiple Correct)
* True / False

---

## Technical Architecture

### Flutter App Responsibilities

* Quiz management UI
* Local HTTP/WebSocket server
* Session state management
* Scoring engine
* Data persistence
* Result exporting

Possible Technologies:

* Local server: `shelf` / `dart:io`
* QR generation: `qr_flutter`
* Storage: Hive / Isar / SQLite
* State management: Riverpod / Bloc / Provider

---

### Participant Interface

Lightweight browser-based UI:

* Displays questions
* Submits answers
* Shows timer & feedback

Implementation Options:

* Flutter Web
* Minimal HTML / JS client

---

## Value Proposition

* Works fully offline
* No account / login required
* Instant joining via QR
* Ideal for classrooms & events
* Platform-independent participants (any browser)

---

## UI / Visual Theme

**Design Style:** Modern, minimal, high-contrast

**Color Palette:**

* Black (Primary Background)
* Gold (Accent / Highlights)
* White (Text / Contrast)

**Visual Feel:**

* Premium
* Clean & distraction-free
* Game-show inspired aesthetics

---

## Product Vision

A sleek, offline-first quiz hosting system that transforms any local network into an interactive real-time quiz environment.
