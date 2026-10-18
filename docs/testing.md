# Testing Strategy

## Philosophy
The testing strategy enforces test coverage across critical application tiers:
1. **Unit Tests**: Domain entities, parsers, evaluation schemas, state machines, and business rules.
2. **Integration Tests**: FastAPI endpoints, authentication, database transactions, role-based access control.
3. **Frontend Analysis & Unit Tests**: Riverpod state providers, route guards, models, and UI widgets.

## Running Tests

### Backend Unit & Integration Tests
```powershell
cd "c:\ai interviewer\backend"
.\.venv\Scripts\pytest -v tests/
```

### Static Analysis & Type Checking
```powershell
cd "c:\ai interviewer\backend"
# Optional ruff / flake8 / mypy
```

### Flutter Analysis & Tests
```powershell
cd "c:\ai interviewer\frontend"
flutter analyze
flutter test
```
