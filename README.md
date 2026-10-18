# AI-Powered Intelligent Interview System

A production-grade, secure, and adaptive recruitment and interview platform built with Flutter and FastAPI.

## Key Features
- **Role-Based Access Control**: Separate workflows and permissions for Candidates, Recruiters, and Administrators.
- **Resume Parsing & Job Matching**: Safe document text extraction and transparent skill gap analysis.
- **Adaptive AI Interview Engine**: Stateful session lifecycle, dynamic role-tailored questions, and structured rubric evaluations.
- **Session & Identity Integrity**: Consent-based camera verification and objective session observations without unverified claims.
- **PDF Performance Reports**: Detailed downloadable candidate assessment dossiers.
- **Modern Responsive Frontend**: Flutter Web & Desktop client utilizing Riverpod, GoRouter, and Dio.

## Directory Structure
```
ai-interviewer/
  frontend/          # Flutter Web & Desktop application
    lib/
      app/           # App configuration and entry point
      core/          # Theme, network client, storage, constants
      models/        # Domain data models
      services/      # API communication services
      providers/     # Riverpod state management providers
      router/        # GoRouter navigation & auth guards
      shared/        # Reusable UI widgets and layout components
      features/      # Domain feature modules
    test/            # Flutter widget and unit tests
  backend/           # FastAPI backend
    app/
      main.py        # FastAPI entry point
      api/           # Versioned API routes (/api/v1)
      core/          # Config, security, database engine
      models/        # SQLAlchemy ORM models
      schemas/       # Pydantic request/response schemas
      repositories/  # Data access abstractions
      services/      # Business logic services
      ai/            # AI provider abstraction & prompts
      integrations/  # Third-party adapters (storage, speech, PDF)
      workers/       # Asynchronous background tasks
      utils/         # Utility functions
    migrations/      # Alembic migration scripts
    tests/           # Pytest test suite
    requirements.txt # Python dependencies
    .env.example     # Environment template
  docs/              # Architectural, API, setup, and testing documentation
```

## Quick Start
Refer to [Setup Guide](file:///c:/ai%20interviewer/docs/setup.md) for step-by-step instructions.
