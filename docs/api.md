# API Documentation

## Overview
All REST APIs are versioned under `/api/v1`.
Interactive OpenAPI documentation is automatically served by FastAPI at:
- **Swagger UI**: `http://127.0.0.1:8000/docs`
- **ReDoc**: `http://127.0.0.1:8000/redoc`

## Planned Endpoints Summary

### System & Health
- `GET /health` - Root health check
- `GET /api/v1/health` - API v1 operational health check (status, timestamp, environment)

### Authentication (`/api/v1/auth`)
- `POST /register` - Register new user (Candidate / Recruiter)
- `POST /login` - Authenticate user & return JWT tokens
- `POST /refresh` - Refresh access token
- `POST /logout` - Invalidate session
- `GET /me` - Retrieve current user profile

### Candidates & Resumes (`/api/v1/resumes`)
- `POST /upload` - Upload resume (PDF / DOCX)
- `GET /{id}` - Get parsed resume details
- `POST /{id}/match` - Match candidate profile with job opening

### Jobs (`/api/v1/jobs`)
- `POST /` - Create new job posting (Recruiter)
- `GET /` - List accessible job postings
- `GET /{id}` - Get job details with required skills

### Interviews (`/api/v1/interviews`)
- `POST /` - Initialize interview session
- `GET /{id}` - Get interview state & progress
- `GET /{id}/questions/current` - Get active question
- `POST /{id}/answers` - Submit answer to current question
- `POST /{id}/complete` - Finish interview session & trigger evaluation

### Reports (`/api/v1/reports`)
- `GET /{interview_id}` - Get evaluation report summary
- `GET /{interview_id}/pdf` - Download full PDF interview evaluation report
