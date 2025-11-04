# SchemePlus

SchemePlus is a full-stack prototype that recommends Indian government schemes based on a user's profile and preferences, providing bilingual content (English and Tamil), offline access, notifications, and quick apply links.

## 🚀 Quick Start

**New here?** See [QUICK_START.md](./QUICK_START.md) for a 5-minute setup guide.  
**Just fixed?** See [FIXES_APPLIED.md](./FIXES_APPLIED.md) for details on recent critical fixes.

## Project Structure

- `backend/` — Node.js + Express API serving schemes (currently **local-only mode** with 30 curated schemes)
- `frontend/` — Flutter application with Material 3 UI, Provider state management, and Hive offline storage

## Backend Setup

> **Note:** Backend is currently configured for **local-only mode**. OGD API integration is disabled. All data comes from `backend/data/sample_schemes.json`.

1. Install dependencies:
   ```bash
   cd backend
   npm install
   ```

2. Start the development server:
   ```bash
   npm run dev
   ```

   **Expected output:**
   ```
   ⚠️  Using local sample_schemes.json only
   🚀 SchemePlus backend listening on http://localhost:4000
   ```

3. The server exposes the following endpoints under `http://localhost:4000/api`:
   - `GET /schemes` — returns 30 curated local schemes
   - `GET /schemes/category/:category` — filter by category
   - `GET /schemes/state/:state` — filter by state
   - `POST /schemes/recommendations` — personalized recommendations based on profile
   - `GET /notifications` — simulated notifications
   - `POST /notifications/simulate` — create a mock notification
   - `POST /notifications/mark-read/:id` — mark notification as read

4. Stop the dev server with <kbd>Ctrl</kbd>+<kbd>C</kbd> when finished.

### Re-enabling OGD API (Optional)

If you have a valid [data.gov.in](https://data.gov.in/apis) API key:

1. Create `.env` file in `backend/` directory:
   ```bash
   OGD_API_KEY=your_actual_api_key_here
   PORT=4000
   CACHE_TTL_SECONDS=3600
   ```

2. Modify `backend/src/services/ogdClient.js`:
   - Remove the `return [];` line in `fetchSchemesFromOGD()`
   - Uncomment the original API fetch logic

3. Update `backend/src/config.js`:
   - Change warning message back to original

**Current Status:** App works perfectly with local data. OGD integration is optional for production.

## Frontend Setup

> **Prerequisites:** Flutter SDK 3.3+ with Dart 3.3+, Android/iOS tooling, and Chrome (for web runs).

1. Install dependencies:
   ```bash
   cd frontend
   flutter pub get
   ```

2. Generate localization delegates (optional — handled at runtime but recommended for tooling):
   ```bash
   flutter gen-l10n
   ```

3. Ensure Hive is initialized on first run; no manual steps required beyond granting storage permissions on physical devices.

4. Run the app (select platform of choice):
   ```bash
   flutter run -d chrome
   ```

   The app reads from the backend at `http://10.0.2.2:4000/api` by default (Android emulator). Override with `--dart-define=API_BASE_URL=https://your-host/api` when needed.

### Frontend Features

- ✅ **Material Design 3 UI** matched to Figma designs (home dashboard, browse, bookmarks)
- ✅ **Zero Overflow Errors** — all UI components properly constrained and responsive
- ✅ **Instant Data Loading** — schemes preload on app start for immediate display
- ✅ **Provider State Management** — profile, schemes, bookmarks, notifications, connectivity, language
- ✅ **Hive Offline Cache** — schemes and bookmarks persist locally
- ✅ **Bilingual Support** — English/Tamil with runtime switching
- ✅ **Smart Search & Filters** — search, category, and state filtering
- ✅ **Bottom Navigation** — custom styled nav bar matching Figma colors exactly
- ✅ **Responsive Design** — works on various screen sizes without overflow

### Recent Fixes (Latest)

1. **Backend:** Disabled OGD API to prevent 403 errors — all data now local
2. **UI Overflow:** Fixed category pills, state chips, cards, and grids
3. **Data Loading:** Added automatic preload in `SchemesProvider`
4. **Bottom Nav:** Styled to match Figma design (blue active, gray inactive)
5. **Responsive:** All components now have proper width constraints

See [FIXES_APPLIED.md](./FIXES_APPLIED.md) for complete details.

## Tooling & Quality

- **Backend Linting:** ESLint configured — run `npm run lint` in `backend/`
- **Frontend Analysis:** Dart analyzer — run `flutter analyze` in `frontend/`
- **VS Code Task:** `backend:dev` available via `Terminal > Run Task…`
- **Code Quality:** All lint checks passing, no compilation errors

## Testing Checklist

Before delivery:

1. ✅ Backend serves 30 schemes from local JSON
2. ✅ No 403 API errors in console
3. ✅ Frontend home screen loads data immediately
4. ✅ No UI overflow errors in any screen
5. ✅ Bottom nav matches Figma colors
6. ✅ Browse category/state filters work
7. ✅ All text properly wraps/truncates
8. ✅ Responsive on different screen sizes

See [QUICK_START.md](./QUICK_START.md) for detailed testing steps.

## Development Status

| Component | Status | Notes |
|-----------|--------|-------|
| Backend API | ✅ Complete | Local-only mode, 30 schemes |
| Frontend UI | ✅ Complete | Matches Figma, no overflow |
| Data Loading | ✅ Complete | Preload on startup |
| Bottom Nav | ✅ Complete | Custom styled |
| Responsive | ✅ Complete | All screens tested |
| Bilingual | ✅ Complete | English/Tamil working |
| Offline Mode | ✅ Complete | Hive cache functional |

## Known Limitations

- OGD API integration disabled (can be re-enabled with valid API key)
- Dataset limited to 30 curated schemes (expandable via `sample_schemes.json`)
- Push notifications are simulated (not real FCM integration)

## Next Steps

- [ ] Test on physical Android device
- [ ] Test on iOS device/simulator
- [ ] Add more schemes to `sample_schemes.json` if needed
- [ ] Re-enable OGD API with valid credentials (optional)
- [ ] Deploy backend to production server
- [ ] Build and release APK/IPA for distribution
