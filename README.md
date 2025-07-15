
# AI Life Navigator
### A Smart Career Guide for B.Tech Students, Powered by Google Cloud & Gemini AI

Your personalized AI mentor that understands your academic background, skills, and aspirations — and recommends the best career paths, internships, and learning resources just for you.  
Built to empower engineering students with data-driven insights, real-time guidance, and a complete ecosystem for informed career planning.

---

## 📚 Table of Contents

1. [🧩 Problem Statement](#1-🧩-problem-statement)  
2. [🚀 Our Solution](#2-🚀-our-solution)  
3. [🌟 Key Features](#3-🌟-key-features)  
4. [🔮 Planned Features](#4-🔮-planned-features)  
5. [🛠️ Google Technologies Used](#5-🛠️-google-technologies-used)  
6. [🧠 Model Training with Vertex AI](#6-🧠-model-training-with-vertex-ai)  
7. [⚡ Quickstart / Usage Instructions](#7⚡-quickstart--usage-instructions)  
8. [📁 Project Folder Structure](#8-📁-project-folder-structure)  
9. [🌍 Impact](#9-🌍-impact)  
10. [📞 Contact](#10-📞-contact)

---

## 1. 🧩 Problem Statement

B.Tech students often struggle with finding personalized career guidance, relevant internships, and mentorship. Generic job platforms provide limited tailored support:

- Over 60% of engineering graduates land in jobs that don’t match their skills  
- More than 70% don’t have access to mentorship or informed career advice  
- Existing platforms offer limited personalized recommendations  

---

## 2. 🚀 Our Solution

**AI Life Navigator** is a smart, AI-powered platform that:

- Understands student profiles using parameters like branch, CGPA, skills, and interests  
- Engages users through an AI assistant for deeper career understanding  
- Recommends personalized career paths, internships, exams, and learning resources  
- Uses AI and ML to guide students with confidence and clarity  

---

## 3. 🌟 Key Features

- **Conversational AI Assistant:** Powered by Gemini, it asks insightful questions like “Why did you choose B.Tech?” or “Are you focused on internships or skill development?”  
- **Personalized Dashboard:** User inputs like CGPA, year, branch, skills, and goals  
- **Career Prediction Engine:** Suggests career paths with match scores (e.g., Software Developer — 91%)  
- **LinkedIn Analysis:** Reads your LinkedIn and provides feedback and suggestions  
- **YouTube Integration:** Recommends relevant courses based on interests and career fit  
- **Deep Dive Insights:** Explains the reasoning behind each recommendation clearly  

---

### 📸 Feature Flow Diagrams

**Feature Flow 1**  
![Feature Flow 1](./3bdb3c6d-dae0-4019-801a-a20a7ad64076.png)

**Feature Flow 2**  
![Feature Flow 2](./9feee908-19ce-4e8b-bae6-2519d6aacf39.png)

---

## 4. 🔮 Planned Features

- Mentor matchmaking based on career prediction  
- Resume builder tailored to predicted paths and skills  
- Recommendations for competitive exams like GATE, GRE, CAT  
- Skill match graphs and job market trends  
- Visual insights like salary comparisons and growth projections  

---

## 5. 🛠️ Google Technologies Used

### Google Cloud Platform (GCP)

- **Vertex AI (AutoML):** Trains and deploys the ML model for career prediction  
- **Cloud IAM & Service Accounts:** Manages secure access across components  

### Firebase

- **Firebase Authentication:** Handles user login/signup  
- **Cloud Firestore:** Stores user data, chats, and predictions  
- **Firebase Hosting:** Deploys the frontend and backend  

### Google APIs & SDKs

- **Gemini API:** Powers the conversational assistant  
- **YouTube Data API v3:** Recommends career-aligned tutorials  
- **googleapis_auth (Dart):** Handles secure API calls  
- **Vertex AI REST APIs:** Fetch predictions in real time  

### Development Tools

- **Flutter:** Cross-platform frontend (web & mobile)  
- **Google Project IDX:** Cloud-based IDE used for collaborative development  

---

## 6. 🧠 Model Training with Vertex AI

By leveraging **Vertex AI AutoML**, we trained a model that does more than apply static logic — it reasons, learns, and helps students make data-backed career choices.

- **Gemini API:** Powers open-ended career conversations  
- **Vertex AI:** Provides structured career predictions based on student profiles  
- **YouTube API:** Suggests resources based on predicted paths  

### 📊 Data Overview

- Dataset includes student profiles with inputs like skills, branch, CGPA, and goals  
- Target labels include career roles (e.g., Data Analyst, Software Engineer, UI/UX Designer)  

### 🔧 Training Process

- Uploaded CSV data to Google Cloud Storage  
- Trained using AutoML Tables in Vertex AI  
- Evaluated performance with precision and fit score metrics  
- Deployed the model for real-time predictions using REST API  

### 🧬 Future ML Enhancements

- Internship and course recommendation system  
- Resume keyword matching and optimization  
- Skill-gap analyzer for career path readiness  

---

## 7⚡ Quickstart / Usage Instructions

Follow these steps to get AI Life Navigator up and running locally or for demo purposes.

### 1. 🔧 Prerequisites

Make sure you have the following installed:

- Flutter SDK  
- Firebase CLI  
- Dart >= 3.x  
- Git  

✅ Optional: Create a Google Cloud and Firebase project if you're running your own backend.

---

### 2. 📥 Clone the Repository

```bash
git clone https://github.com/your-username/ai-life-navigator.git
cd ai-life-navigator
```

---

### 3. 🔌 Configure Firebase

- Go to Firebase Console  
- Create a project → Enable Authentication and Firestore  
- Download your `google-services.json` or `firebase_options.dart` (if using FlutterFire CLI)  
- Place it inside the `lib/` directory as needed  

---

### 4. 🧠 Configure Vertex AI (for ML Predictions)

If running your own ML model:

- Upload your CSV dataset to Google Cloud Storage  
- Train model using Vertex AI AutoML Tables  
- Deploy it and get your endpoint + access credentials  
- Replace dummy values in your backend API logic inside `backend/functions/`  

_For demo purposes, we’ve used mock endpoints you can stub or simulate._

---

### 5. ▶️ Run the App

```bash
flutter pub get
flutter run
```

---

### 6. 🌐 Deploy (Optional)

To deploy frontend & backend:

```bash
firebase deploy
```

---

### 7. 🧪 Try It Out

- Signup or Login via Firebase Auth  
- Fill out your profile (CGPA, branch, skills, goals)  
- Talk to the AI Assistant  
- Get career suggestions, LinkedIn insights, and YouTube course recommendations  

---

## 8. 📁 Project Folder Structure

```
ai-life-navigator/
├── lib/
│   ├── screens/            # All Flutter UI screens
│   ├── services/           # API, ML, LinkedIn handlers
│   └── models/             # Dart data models
├── backend/
│   └── functions/          # Firebase backend functions
├── public/                 # Hosting frontend files
├── firestore.rules         # Firestore security
├── firebase.json           # Project config
├── pubspec.yaml            # Flutter dependencies
└── README.md               # This file
```

---

## 9. 🌍 Impact

**AI Life Navigator** is built to transform how B.Tech students discover and pursue careers by:

- Providing personalized guidance that generic platforms often overlook — helping students discover opportunities that match their unique background and goals.  
- Simulating real mentorship through conversational AI — critical support for the 70% of students who currently lack access to informed career guidance.  
- Reducing career misalignment — helping tackle the issue where 60% of engineering graduates end up in jobs unrelated to their core strengths.  
- Empowering students with clarity and direction — through AI-driven predictions, skill gap analysis, and curated resources for confident decision-making.  

---

## 10. 📞 Contact

**Project Lead:** Mouli Sharma  
**Email:** mouliiisharma17@gmail.com
