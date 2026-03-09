# SchemePlus Flutter Frontend

This Flutter app consumes the SchemePlus backend APIs and provides:
- scheme discovery and filtering
- profile-based recommendations
- multilingual UX (English/Tamil)
- local caching with Hive

## Run

```bash
flutter pub get
flutter run
```

Optional backend override:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

The app normalizes the base URL and targets `/api/v1` endpoints.

## Main App Entry Points

- `lib/main.dart`
- `lib/app.dart`
- `lib/data/services/api_service.dart`
- `lib/providers/schemes_provider.dart`

## Notes

- Local cache is stored in Hive boxes initialized at startup.
- Bottom navigation currently uses 3 primary tabs: Home, Browse, Settings.
