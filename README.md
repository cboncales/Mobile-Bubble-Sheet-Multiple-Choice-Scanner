# SmartCheckr - OMR-Based Test Checking Application

A mobile application for automated OMR (Optical Mark Recognition) based test checking using Flutter, Python/OpenCV, and Supabase.

## Features

- **Create Tests**: Set up tests with custom answer keys
- **OMR Processing**: Automatically detect and grade answer sheets using OpenCV
- **Camera Integration**: Capture answer sheets directly from the app
- **Real-time Results**: Instant scoring and detailed analysis
- **Cloud Storage**: Store tests and images in Supabase
- **Modern UI**: Beautiful and intuitive user interface

## Architecture

- **Frontend**: Flutter mobile app
- **Backend**: Python Flask API with OpenCV for OMR processing
- **Database**: Supabase (PostgreSQL)
- **Storage**: Supabase Storage for answer sheet images

## Prerequisites

- Flutter SDK (3.8.1 or later)
- Python 3.8+
- Supabase account
- Android Studio/VS Code
- Git

## Setup Instructions

### 1. Supabase Setup

1. Create a new project on [Supabase](https://supabase.com)
2. Go to Settings > API to get your project URL and anon key
3. Create the `Tests` table:

```sql
CREATE TABLE "Tests" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    total_items INTEGER NOT NULL,
    answer_key JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE "Tests" ENABLE ROW LEVEL SECURITY;

-- Create policy for users to manage their own tests
CREATE POLICY "Users can manage their own tests" ON "Tests"
    FOR ALL USING (auth.uid() = user_id);
```

4. Create a storage bucket for answer sheets:
   - Go to Storage in Supabase dashboard
   - Create a new bucket named `answer_sheets`
   - Make it public if needed

### 2. Flutter App Setup

1. Clone the repository:

```bash
git clone <repository-url>
cd AnswerSheetScanner/smartcheckr
```

2. Install dependencies:

```bash
flutter pub get
```

3. Update Supabase configuration in `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

4. Configure Android permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### 3. Python API Setup

1. Navigate to the project root:

```bash
cd AnswerSheetScanner
```

2. Create a virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install Python dependencies:

```bash
pip install -r requirements.txt
```

4. Make sure the `grader` folder contains the `four_point.py` file

5. Start the API server:

```bash
python omr_api.py
```

The API will start on `http://localhost:5000`

### 4. Running the Application

1. Start the Python API (if not already running):

```bash
python omr_api.py
```

2. Update the API URL in Flutter app (`lib/services/omr_service.dart`):

```dart
static const String baseUrl = 'http://YOUR_IP:5000';  // Use your actual IP for device testing
```

3. Run the Flutter app:

```bash
cd smartcheckr
flutter run
```

## API Endpoints

- `GET /` - API information
- `GET /health` - Health check
- `POST /process_omr` - Process OMR image
  - Form data: `image` (file), `num_questions` (integer)
  - Returns: `{success: true, answers: [...], total_questions: n}`

## Usage

1. **Authentication**: Set up authentication in Supabase (optional, currently uses anonymous access)
2. **Create Test**: Add a new test with title, number of questions, and answer key
3. **Scan Answer Sheet**: Select a test, enter student details, capture/select answer sheet image
4. **View Results**: See instant results with detailed analysis

## Project Structure

```
AnswerSheetScanner/
├── smartcheckr/          # Flutter mobile app
│   ├── lib/
│   │   ├── bloc/         # State management
│   │   ├── models/       # Data models
│   │   ├── screens/      # UI screens
│   │   ├── services/     # API services
│   │   └── main.dart     # App entry point
│   └── pubspec.yaml      # Flutter dependencies
├── grader/               # Original OMR processing code
│   ├── grader.py
│   ├── four_point.py
│   └── omr.png
├── doc_scanner/          # Document scanning utilities
├── omr_api.py           # Python Flask API
├── requirements.txt     # Python dependencies
└── README.md
```

## Technologies Used

- **Flutter**: Cross-platform mobile development
- **Python**: Backend API and OMR processing
- **OpenCV**: Computer vision for OMR detection
- **Flask**: Web framework for API
- **Supabase**: Backend-as-a-Service (Database + Storage)
- **BLoC**: State management pattern

## Troubleshooting

### Common Issues

1. **API Connection Issues**:

   - Make sure the Python API is running
   - Update the API URL in Flutter app
   - Check firewall settings

2. **Camera Permissions**:

   - Add camera permissions in AndroidManifest.xml
   - Request permissions at runtime

3. **Supabase Connection**:

   - Verify URL and API keys
   - Check network connectivity
   - Ensure Row Level Security policies are set up

4. **OMR Processing Issues**:
   - Ensure answer sheet is well-lit and flat
   - Check that bubbles are properly filled
   - Verify the four_point.py module is accessible

## Future Enhancements

- [ ] User authentication and profiles
- [ ] Batch processing of multiple answer sheets
- [ ] Export results to PDF/CSV
- [ ] Custom answer sheet templates
- [ ] Analytics and reporting dashboard
- [ ] Offline mode support
- [ ] Teacher/admin dashboard

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or issues, please:

1. Check the troubleshooting section
2. Search existing issues
3. Create a new issue with detailed information

---

**Note**: This is a development project. For production use, implement proper security measures, error handling, and testing.
