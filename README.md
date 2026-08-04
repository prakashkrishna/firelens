# 🔥 FireLens — Modern Desktop GUI Client for Google Cloud Firestore

**FireLens** is a fast, modern, and open-source cross-platform Desktop GUI client for **Google Cloud Firestore**. Built with Flutter, FireLens provides database administrators, developers, and DevOps engineers with an intuitive desktop environment to explore, query, edit, and manage Firestore collections and documents effortlessly.

<p align="center">
  <img src="https://github.com/user-attachments/assets/3fe5d2ce-8f9b-4e23-b7b8-7e55b8924825" alt="FireLens Document Tree View & Visual Query Builder" width="100%" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/4bf7e403-cbce-4d60-9af2-bfb30b7b37e2" alt="FireLens Raw JSON Code Editor in Edit Mode" width="100%" />
</p>

---

## 🏗️ Architecture & Core Packages Used

FireLens connects directly to Google Cloud APIs via authenticated HTTP clients, bypassing emulator-only limits of standard Flutter desktop SDKs:

- **🔐 Authentication (`googleapis_auth`)**:
  - Uses `googleapis_auth` to create authenticated HTTP clients from **Service Account Key JSON** files (`clientViaServiceAccount`) and local **GCP Application Default Credentials (ADC)**.
- **🗂️ Project & Database Discovery (`googleapis`)**:
  - Leverages `googleapis` (Resource Manager API) to list accessible GCP projects and queries the Firestore Admin REST API for database instances (including `(default)` and named databases).
- **📡 Firestore CRUD & Queries (`http` + Firestore REST API v1)**:
  - **List Collections**: Invokes `documents:listCollectionIds` API endpoint.
  - **Execute Queries**: Dispatches `StructuredQuery` payloads via `documents.runQuery` for compound `WHERE` filters, `ORDER BY` sorting, and pagination limits.
  - **Add & Edit Documents**: Uses `documents.createDocument` and `documents.patch` with field masks.
  - **Delete Documents & Fields**: Uses `documents.delete` and `documents.patch` transform operations.
- **⚡ State Management (`flutter_riverpod`)**:
  - Manages reactive state across Auth mode, GCP Projects, Databases, Collections, Document selection, and Queries.
- **🖥️ Native Desktop Windowing (`window_manager` & `file_picker`)**:
  - `window_manager`: Native Windows frameless titlebar, minimum dimensions, and window controls.
  - `file_picker`: Native OS file picker dialogs for loading `.json` service account key files.

---

## ✨ Key Features

### 🔐 Flexible Authentication
- **Application Default Credentials (ADC)**: Automatically connects using your local `gcloud auth application-default login` credentials.
- **Service Account Key (.json)**: Easily load service account JSON key files to manage projects with specific IAM permissions.

### 🗂️ Project & Database Explorer
- **Multi-Project Support**: Seamlessly switch between GCP projects.
- **Multi-Database Management**: Full support for `(default)` and named Firestore databases within your GCP projects.
- **Collection Tree**: Top-to-bottom organized explorer for browsing collections and sub-collections.

### ⚡ Visual Query Builder & Query Snippets
- **Visual Filter Builder**: Build complex compound `WHERE` filter clauses (`==`, `!=`, `>`, `>=`, `<`, `<=`, `array-contains`, `in`, `not-in`) joined automatically with `AND`.
- **Sorting & Pagination**: Configure `ORDER BY` sorting (Ascending / Descending) and custom page size limits.
- **Interactive Query Guide**: Built-in snippet library with `+ Append` (merge with existing filters) and `Replace` query controls.

### 📝 Dual-Mode Document Editor
- **Interactive Tree View**:
  - Visual badges for native Firestore data types (`String`, `Integer`, `Double`, `Boolean`, `Timestamp`, `GeoPoint`, `Bytes`, `Reference`, `Map`, `Array`, `Null`).
  - Interactive **`true` / `false`** selector for Boolean fields.
  - Date & Time picker for ISO 8601 UTC and local timezone timestamps.
- **Raw JSON Code Editor**:
  - Syntax-highlighted JSON editor with pre-save syntax validation.
  - **Copy JSON** & **Paste JSON** clipboard utilities.
- **Read-Only Safety Guard**: Interactive **`🔒 Read-Only`** / **`⚡ Edit Mode`** badge to protect production databases against accidental edits.

---

## 💾 Download Prebuilt Executable

Download the prebuilt standalone Windows desktop app directly without needing Flutter installed:

👉 **[Download Latest Windows Release (FireLens-Windows-x64.zip)](https://github.com/prakashkrishna/firelens/releases/latest)**

1. Download and extract the `.zip` file.
2. Double-click `firelens.exe` to launch FireLens!

---

## 🛠️ Building & Running Locally

> [!NOTE]
> **Platform Testing Note**: While FireLens is architected for cross-platform support across desktop environments, it has currently been primary-tested and verified on **Windows**. Contributions and testing for macOS and Linux are welcome!

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0 or higher)

#### Platform-Specific Prerequisites:
- **🪟 Windows**: **Visual Studio Build Tools** with the **"Desktop development with C++"** workload installed *(Full Visual Studio IDE is **NOT** required; lightweight Build Tools is sufficient)*.
- **🍎 macOS**: Xcode command-line tools installed (`xcode-select --install`) & CocoaPods.
- **🐧 Linux**: C++ toolchain and GTK headers:
  ```bash
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
  ```

### Development Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/prakashkrishna/firelens.git
   cd firelens
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run in Debug Mode**:
   ```bash
   # Windows
   flutter run -d windows

   # macOS
   flutter run -d macos

   # Linux
   flutter run -d linux
   ```

4. **Build Production Release Binary**:
   ```bash
   # Windows (Outputs to build/windows/x64/runner/Release/)
   flutter build windows --release

   # macOS (Outputs to build/macos/Build/Products/Release/)
   flutter build macos --release

   # Linux (Outputs to build/linux/x64/release/bundle/)
   flutter build linux --release
   ```

---

## 🧪 Testing

Run static analysis and automated unit tests:

```bash
# Static analysis
flutter analyze

# Unit tests
flutter test
```

---

## 📄 License

This project is licensed under the **Non-Commercial License** — see the [LICENSE](LICENSE) file for details. Free for personal, educational, and internal developer use; commercial resale or paid distribution is strictly prohibited.
