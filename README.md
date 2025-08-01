# SwasthaSetu 🇮🇳 - AI-Powered Rural Healthcare

**SwasthaSetu** is a revolutionary mobile application designed to bridge the healthcare gap in rural India. It leverages the power of Artificial Intelligence to provide fast, affordable, and accessible diagnostics for critical diseases like Pneumonia, Tuberculosis (TB), and Malaria, directly into the hands of community health workers.

## The Problem
Every year in India, millions of lives are tragically lost to treatable diseases. The core issue, especially in rural areas, is the lack of timely diagnosis due to the unavailability of specialist doctors and radiologists. This delay in detection is a critical bottleneck that costs lives.

## Our Solution: A Complete Diagnostic Ecosystem
**SwasthaSetu** (meaning "Health Bridge" in Hindi) is a fully functional Android application built with Flutter that tackles this problem head-on. It's more than just an app; it's a complete ecosystem designed to assist, diagnose, and empower.

## ✨ Key Features

*   **🤖 AI-Powered Disease Detection:**
    *   Users can upload a Chest X-Ray or a Blood Smear image.
    *   Our live, deployed AI models (trained on verified government datasets) analyze the image in real-time.
    *   Provides an instant preliminary diagnosis for Pneumonia, TB, and Malaria with a confidence score.

*   **📄 Professional PDF Reporting:**
    *   Generates a comprehensive, multi-page medical report after each diagnosis.
    *   Features a **technical section for doctors** and a **patient-friendly summary in 4 native Indian languages** (Hindi, Telugu, Tamil, Bengali) plus English.
    *   Reports are saved directly to the device for easy sharing and record-keeping.

*   **💬 Multilingual AI Chatbot (Dr. SwasthaSetu):**
    *   Powered by **Sarvam AI**, India's own Large Language Model, ensuring culturally relevant responses.
    *   Allows patients and health workers to ask medical questions in their native language.
    *   Provides information on diseases, care, prevention, and government health schemes like DOTS and Ayushman Bharat.

*   **🗓️ Agentic AI 6-Month Health Plan:**
    *   For diagnosed patients, the app leverages Agentic AI to generate a **customized 6-month healthcare and recovery plan**.
    *   Provides interactive guidance and follow-up prompts to ensure treatment adherence.

*   **📞 Integrated Telemedicine:**
    *   A critical lifeline for escalating care.
    *   If a patient's condition is serious, health workers can use the app to initiate a **direct video call with a qualified doctor**, bridging the distance barrier instantly.

## 📸 Application Screenshots

(Replace the `#` with links to your screenshots)

| Home Screen                               | Disease Detection                      | AI Analysis Result                      |
| ----------------------------------------- | -------------------------------------- | --------------------------------------- |
|                          |                 |                     |
| **Chatbot Interface**                     | **PDF Report Generation**              | **Telemedicine**                        |
|                              |                        |                        |

## 💻 Technology Stack

### Frontend (Mobile Application)
*   **Framework:** Flutter 3.x.x
*   **Language:** Dart
*   **Key Packages:**
    *   `http`: For making API calls to the backend.
    *   `image_picker`: For selecting images from the gallery or camera.
    *   `pdf`, `printing`: For generating, viewing, and saving professional medical reports.
    *   `flutter_spinkit`: For elegant loading animations.
    *   `path_provider`: For managing file paths to save reports.

### Backend (AI & API Server)
*   **Framework:** FastAPI
*   **Language:** Python 3.9+
*   **AI/ML Libraries:**
    *   `PyTorch`: For running the deep learning models (EfficientNet/ResNet).
    *   `Pillow`: For image preprocessing.
    *   `ONNX Runtime`: For optimized model inference.
*   **LLM Provider:** Sarvam AI (`sarvam-m` model) for Chatbot and Agentic AI features.

### ☁️ Cloud & Deployment
*   **Platform:** Render
*   **Deployment:** The FastAPI backend is deployed as a web service on Render, providing a live API endpoint for the Flutter app.

## 🏗️ System Architecture

The system operates in a simple, robust client-server architecture:

1.  **Flutter App (Client):** Captures user input (images, patient data, chat queries).
2.  **API Request:** Sends a secure HTTPS request to our deployed backend on Render.
3.  **FastAPI Backend (Server on Render):**
    *   Receives the request.
    *   For image analysis, it preprocesses the image and feeds it to the PyTorch models.
    *   For chat queries, it forwards the request to the Sarvam AI API.
4.  **JSON Response:** The backend returns a structured JSON response containing the diagnosis, confidence scores, or chatbot text.
5.  **Flutter App (Client):** Parses the JSON and displays the information to the user in a clean, intuitive UI, or generates a PDF report.

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites
*   Flutter SDK (version 3.x.x or higher)
*   A code editor like VS Code or Android Studio
*   An Android device or emulator

### Installation
1.  **Clone the repo:**
    ```sh
    git clone https://github.com/your-username/swasthasetu.git
    cd swasthasetu
    ```
2.  **Install Flutter packages:**
    ```sh
    flutter pub get
    ```
3.  **Configure API Keys:**
    *   Open `lib/screens/chatbot_screen.dart`.
    *   Replace the placeholder on line ~25 with your Sarvam AI API key:
        ```dart
        static const String _sarvamApiKey = 'YOUR_SARVAM_AI_API_KEY_HERE';
        ```
    *   Open `lib/services/ml_service.dart`.
    *   Ensure the `_baseUrl` points to your deployed Render API.
        ```dart
        static const String _baseUrl = 'https://swasthasetu-medical-ai.onrender.com';
        ```

4.  **Run the app:**
    ```sh
    flutter run
    ```

## 🌟 Our Vision
Our mission is to democratize healthcare by making advanced diagnostics accessible and affordable for everyone, everywhere. SwasthaSetu is our first step towards building a healthier, more equitable India.

We believe in technology that serves humanity. **Join us, not just for winning, but for creating a real, life-saving change in healthcare.**

---
**Team: OptiBeamTech**

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
