"""Adaptive Interview Session Engine and Question Generation Service."""
import re
from typing import Any, Dict, List, Optional, Tuple
from app.models.interview import (
    InterviewAnswer,
    InterviewQuestion,
    InterviewSession,
    QuestionCategory,
    QuestionDifficulty,
    QuestionSource,
    SessionStatus,
)
from app.models.resume import JobDescription, Resume
from app.services.resume_service import ResumeService


class InterviewStateError(Exception):
    """Exception raised when an invalid interview state transition is requested."""
    pass


class InterviewService:
    """Service governing question generation, session lifecycle, and adaptive progression."""

    # -------------------------------------------------------------------------
    # Curated Question Bank by Skill and Category
    # -------------------------------------------------------------------------
    QUESTION_BANK: Dict[str, Dict[str, Dict[str, List[str]]]] = {
        "python": {
            QuestionCategory.TECHNICAL.value: {
                QuestionDifficulty.EASY.value: [
                    "What are the key differences between lists and tuples in Python, and when would you choose one over the other?",
                    "How does Python's memory management and garbage collection mechanism work at a high level?",
                    "Explain the concept of decorators in Python and provide an example of where they are useful.",
                ],
                QuestionDifficulty.MEDIUM.value: [
                    "How does the Global Interpreter Lock (GIL) impact multithreading in CPython, and what concurrency alternatives exist for CPU-bound tasks?",
                    "What is the difference between deep copy and shallow copy in Python, and how does Python handle mutable default arguments?",
                    "How do generators and the 'yield' statement optimize memory utilization compared to returning lists in Python?",
                ],
                QuestionDifficulty.HARD.value: [
                    "How would you design a custom metaclass in Python to enforce architectural contracts across subclass implementations at import time?",
                    "Explain the internal implementation of Python dictionaries from version 3.6+ and how hash collisions are resolved.",
                ],
            },
            QuestionCategory.PROBLEM_SOLVING.value: {
                QuestionDifficulty.MEDIUM.value: [
                    "Given a scenario where a Python web API experiences gradual memory leaks in production, what profiling tools and methodology would you employ to identify the root cause?",
                    "How would you refactor a synchronous batch-processing pipeline in Python to handle 100,000 I/O-bound web requests concurrently without overwhelming downstream services?",
                ],
                QuestionDifficulty.HARD.value: [
                    "Design an in-memory caching system in Python with LRU eviction and thread-safe operations without using third-party libraries.",
                ],
            },
        },
        "fastapi": {
            QuestionCategory.TECHNICAL.value: {
                QuestionDifficulty.EASY.value: [
                    "How does FastAPI utilize Pydantic schemas for request validation, serialization, and automatic OpenAPI schema generation?",
                    "What is dependency injection in FastAPI, and how do you use the 'Depends' provider?",
                ],
                QuestionDifficulty.MEDIUM.value: [
                    "Explain the difference between 'async def' and plain 'def' route handlers in FastAPI, and how threadpool offloading behaves in each case.",
                    "How would you implement custom middleware in FastAPI for correlation ID tracing across distributed requests?",
                ],
                QuestionDifficulty.HARD.value: [
                    "How would you architect a secure background task execution and WebSocket streaming pipeline using FastAPI and an asynchronous event broker?",
                ],
            },
        },
        "flutter": {
            QuestionCategory.TECHNICAL.value: {
                QuestionDifficulty.EASY.value: [
                    "Explain the fundamental difference between StatelessWidget and StatefulWidget in Flutter.",
                    "What is the Widget tree versus the Element and RenderObject trees in Flutter's rendering pipeline?",
                ],
                QuestionDifficulty.MEDIUM.value: [
                    "Compare Riverpod and Bloc for state management in large-scale Flutter applications. What are the key trade-offs?",
                    "How does Flutter ensure 60fps/120fps performance, and what common anti-patterns cause jank during layout and build passes?",
                ],
                QuestionDifficulty.HARD.value: [
                    "How would you implement custom platform channels to stream real-time hardware telemetry between native iOS/Android code and Flutter?",
                ],
            },
            QuestionCategory.PROBLEM_SOLVING.value: {
                QuestionDifficulty.MEDIUM.value: [
                    "How would you optimize a Flutter application displaying an infinite scroll list containing dynamic, high-resolution media to prevent memory warnings?",
                ],
            },
        },
        "dart": {
            QuestionCategory.TECHNICAL.value: {
                QuestionDifficulty.EASY.value: [
                    "How does Dart's sound null safety system prevent runtime null reference exceptions?",
                    "Explain how asynchronous programming works in Dart using Futures, Streams, and the event loop.",
                ],
                QuestionDifficulty.MEDIUM.value: [
                    "What are Dart Isolates, and how do they differ from threads in traditional shared-memory languages?",
                ],
            },
        },
        "postgresql": {
            QuestionCategory.TECHNICAL.value: {
                QuestionDifficulty.EASY.value: [
                    "What is the difference between clustered and non-clustered indexes in relational databases like PostgreSQL?",
                    "Explain ACID properties and why they are vital in financial or transactional database operations.",
                ],
                QuestionDifficulty.MEDIUM.value: [
                    "How does PostgreSQL's Multi-Version Concurrency Control (MVCC) operate, and why is VACUUM necessary?",
                    "Explain how you would interpret the output of 'EXPLAIN ANALYZE' to optimize a slow JOIN query spanning millions of rows.",
                ],
                QuestionDifficulty.HARD.value: [
                    "How would you design a zero-downtime database migration strategy for altering a high-write table with over 50 million rows?",
                ],
            },
        },
        "docker": {
            QuestionCategory.TECHNICAL.value: {
                QuestionDifficulty.EASY.value: [
                    "What is the difference between a Docker image and a Docker container?",
                    "Why are multi-stage Docker builds recommended when packaging production applications?",
                ],
                QuestionDifficulty.MEDIUM.value: [
                    "How do Docker networks and volume mounts operate under the hood in Linux container runtimes?",
                ],
            },
        },
        "git": {
            QuestionCategory.TECHNICAL.value: {
                QuestionDifficulty.EASY.value: [
                    "Explain the difference between 'git merge' and 'git rebase' and when you would prefer one over the other.",
                ],
                QuestionDifficulty.MEDIUM.value: [
                    "How does Git resolve merge conflicts under the 3-way merge algorithm, and what is git cherry-pick?",
                ],
            },
        },
    }

    # General domain questions for behavioral, problem-solving, and general engineering
    GENERAL_QUESTIONS: Dict[str, Dict[str, List[str]]] = {
        QuestionCategory.BEHAVIORAL.value: {
            QuestionDifficulty.EASY.value: [
                "Describe a situation where you had to quickly learn a new technology or framework to deliver a project on schedule. How did you structure your learning?",
                "Tell me about a time you received constructive feedback on a code review that changed your perspective. How did you respond?",
            ],
            QuestionDifficulty.MEDIUM.value: [
                "Can you describe a time when you and a teammate or tech lead strongly disagreed on an architectural decision? How was the conflict resolved?",
                "Describe a scenario where a critical deadline was at risk due to scope changes. How did you communicate with stakeholders and prioritize tasks?",
            ],
            QuestionDifficulty.HARD.value: [
                "Tell me about a high-severity production incident you were involved in. How did you manage incident response, triage, root-cause analysis, and post-mortem communication?",
            ],
        },
        QuestionCategory.PROJECT_EXPERIENCE.value: {
            QuestionDifficulty.EASY.value: [
                "Can you walk me through the architecture of a recent application you contributed to, explaining the separation of responsibilities?",
                "What testing strategies (unit, integration, end-to-end) did you adopt on your most recent project to maintain high code confidence?",
            ],
            QuestionDifficulty.MEDIUM.value: [
                "Describe a complex technical challenge you solved in a previous project. What constraints did you face, and what alternatives did you reject?",
                "How do you ensure data integrity and security when integrating third-party APIs or external services into your applications?",
            ],
            QuestionDifficulty.HARD.value: [
                "Describe a system you designed or scaled that experienced significant growth in traffic or data volume. What architectural bottlenecks emerged, and how did you resolve them?",
            ],
        },
        QuestionCategory.PROBLEM_SOLVING.value: {
            QuestionDifficulty.EASY.value: [
                "Suppose an API endpoint suddenly starts returning 500 Internal Server Errors in production. What step-by-step diagnostic workflow would you follow?",
                "How do you approach breaking down a vague feature request from product management into precise technical requirements and milestones?",
            ],
            QuestionDifficulty.MEDIUM.value: [
                "Imagine your application's database CPU reaches 95% utilization during peak hours. How would you determine whether the issue is query inefficiency, connection pool exhaustion, or indexing gaps?",
            ],
            QuestionDifficulty.HARD.value: [
                "Design a distributed rate-limiting service capable of handling 50,000 requests per second across geographically distributed application servers.",
            ],
        },
        QuestionCategory.TECHNICAL.value: {
            QuestionDifficulty.EASY.value: [
                "What are the core principles of RESTful API design, and what do status codes 200, 201, 400, 401, 403, and 404 signify?",
                "Explain the difference between synchronous and asynchronous code execution and when concurrency is advantageous.",
            ],
            QuestionDifficulty.MEDIUM.value: [
                "How do microservices communicate reliably in distributed architectures, and what mechanisms prevent cascading failures across services?",
                "Explain the trade-offs between SQL (relational) and NoSQL (document/key-value) databases for scalable web architectures.",
            ],
            QuestionDifficulty.HARD.value: [
                "Explain the CAP theorem and discuss how distributed consensus algorithms like Raft or Paxos maintain consistency during network partitions.",
            ],
        },
    }

    # -------------------------------------------------------------------------
    # Question Generation Methods
    # -------------------------------------------------------------------------
    @classmethod
    def generate_initial_questions(
        cls,
        job: JobDescription,
        resume: Optional[Resume] = None,
        total_questions: int = 5,
        mode: str = "mixed",
    ) -> List[Dict[str, Any]]:
        """
        Generate a balanced, deterministic set of questions tailored to the job's required skills
        and candidate profile. Avoids duplicate questions within the session.
        """
        total_questions = max(1, min(15, total_questions))
        required_skills = [s.strip() for s in (job.required_skills or []) if s.strip()]
        preferred_skills = [s.strip() for s in (job.preferred_skills or []) if s.strip()]
        all_skills = required_skills + preferred_skills

        # Resume context if available
        resume_skills: List[str] = []
        if resume and resume.structured_data:
            resume_skills = resume.structured_data.get("skills", [])

        questions: List[Dict[str, Any]] = []
        used_texts: set = set()

        # Build balanced sequence of categories and difficulties
        # E.g. for 5 questions:
        # Q0: Technical (Easy / Fundamentals)
        # Q1: Technical / Core Skill (Medium)
        # Q2: Problem Solving (Medium)
        # Q3: Technical / Architecture (Medium or Hard)
        # Q4: Behavioral or Project Experience (Medium)
        plan = cls._build_question_plan(total_questions, mode)

        for order, plan_item in enumerate(plan):
            category = plan_item["category"]
            target_difficulty = plan_item["difficulty"]

            # Select skill to assess
            skill = "General Engineering"
            if category in [QuestionCategory.TECHNICAL.value, QuestionCategory.PROBLEM_SOLVING.value]:
                if all_skills:
                    skill_idx = order % len(all_skills)
                    skill = all_skills[skill_idx]
                elif resume_skills:
                    skill_idx = order % len(resume_skills)
                    skill = resume_skills[skill_idx]

            # Find matching question from bank or template
            q_text, reason = cls._select_or_template_question(
                skill=skill,
                category=category,
                difficulty=target_difficulty,
                job_title=job.title,
                used_texts=used_texts,
                is_resume_aligned=(skill in resume_skills) if resume_skills else False,
            )

            used_texts.add(q_text)
            questions.append({
                "question_text": q_text,
                "category": category,
                "skill": skill,
                "difficulty": target_difficulty,
                "question_order": order,
                "question_source": QuestionSource.PREDEFINED.value,
                "selection_reason": reason,
            })

        return questions

    @classmethod
    def _build_question_plan(cls, count: int, mode: str) -> List[Dict[str, str]]:
        """Construct the category and target difficulty blueprint for the session."""
        plan: List[Dict[str, str]] = []

        if mode == "technical":
            for i in range(count):
                diff = QuestionDifficulty.EASY.value if i == 0 else (
                    QuestionDifficulty.HARD.value if i == count - 1 and count >= 4 else QuestionDifficulty.MEDIUM.value
                )
                cat = QuestionCategory.PROBLEM_SOLVING.value if i % 3 == 2 else QuestionCategory.TECHNICAL.value
                plan.append({"category": cat, "difficulty": diff})
        elif mode == "behavioral":
            for i in range(count):
                diff = QuestionDifficulty.EASY.value if i == 0 else QuestionDifficulty.MEDIUM.value
                cat = QuestionCategory.PROJECT_EXPERIENCE.value if i % 2 == 1 else QuestionCategory.BEHAVIORAL.value
                plan.append({"category": cat, "difficulty": diff})
        else:
            # Default "mixed" balanced blueprint
            for i in range(count):
                if i == 0:
                    plan.append({"category": QuestionCategory.TECHNICAL.value, "difficulty": QuestionDifficulty.EASY.value})
                elif i == 1:
                    plan.append({"category": QuestionCategory.TECHNICAL.value, "difficulty": QuestionDifficulty.MEDIUM.value})
                elif i == 2:
                    plan.append({"category": QuestionCategory.PROBLEM_SOLVING.value, "difficulty": QuestionDifficulty.MEDIUM.value})
                elif i == count - 1 and count >= 4:
                    plan.append({"category": QuestionCategory.BEHAVIORAL.value, "difficulty": QuestionDifficulty.MEDIUM.value})
                elif i % 2 == 1:
                    plan.append({"category": QuestionCategory.PROJECT_EXPERIENCE.value, "difficulty": QuestionDifficulty.MEDIUM.value})
                else:
                    plan.append({"category": QuestionCategory.TECHNICAL.value, "difficulty": QuestionDifficulty.HARD.value})

        return plan[:count]

    @classmethod
    def _select_or_template_question(
        cls,
        skill: str,
        category: str,
        difficulty: str,
        job_title: str,
        used_texts: set,
        is_resume_aligned: bool = False,
    ) -> Tuple[str, str]:
        """Retrieve question from taxonomy or generate clean parameterized template question."""
        norm_skill = skill.strip().lower()

        # 1. Check skill-specific bank
        if norm_skill in cls.QUESTION_BANK:
            cat_dict = cls.QUESTION_BANK[norm_skill].get(category, {})
            diff_list = cat_dict.get(difficulty) or cat_dict.get(QuestionDifficulty.MEDIUM.value, [])
            for q in diff_list:
                if q not in used_texts:
                    reason = f"Selected from curated bank assessing required skill '{skill}' at '{difficulty}' difficulty."
                    if is_resume_aligned:
                        reason += " Aligns with candidate documented resume competency."
                    return q, reason

        # 2. Check general category bank
        if category in cls.GENERAL_QUESTIONS:
            diff_list = cls.GENERAL_QUESTIONS[category].get(difficulty, [])
            for q in diff_list:
                if q not in used_texts:
                    return q, f"Selected from general {category} question bank at '{difficulty}' difficulty."

        # 3. Dynamic clean domain template fallback
        clean_skill = re.sub(r"[^\w\s\+\#\.\-]", "", skill).strip()
        clean_title = re.sub(r"[^\w\s\+\#\.\-]", "", job_title).strip()[:80] or "Engineering"
        templates = [
            f"In your experience with {clean_skill}, how do you ensure high reliability, modularity, and maintainability in production applications?",
            f"What are the most challenging technical pitfalls or bottlenecks you have encountered when working with {clean_skill}, and how did you resolve them?",
            f"Can you explain how you design and test automated suites for services utilizing {clean_skill} for the {clean_title} role?",
            f"How do you evaluate performance and memory consumption when developing critical features in {clean_skill}?",
        ]
        for t in templates:
            if t not in used_texts:
                return t, f"Generated structured competency template for '{clean_skill}' for the {clean_title} role."

        fallback = f"Describe an end-to-end feature you engineered using {clean_skill}, detailing key architectural trade-offs."
        return fallback, f"Assessing practical experience with '{clean_skill}'."

    # -------------------------------------------------------------------------
    # Adaptive Difficulty Engine
    # -------------------------------------------------------------------------
    @classmethod
    def adapt_next_question(
        cls,
        session: InterviewSession,
        last_answer: InterviewAnswer,
        current_question: InterviewQuestion,
        next_question: InterviewQuestion,
    ) -> Optional[str]:
        """
        Adaptively calibrate the next question's difficulty and selection based on submitted answer metadata.
        Does not evaluate correctness (Phase 7). Operates transparently and deterministically.
        """
        raw_text = (last_answer.answer_text or "").strip()
        char_count = len(raw_text)
        word_count = len(raw_text.split())

        adaptation_note: Optional[str] = None

        # Rule 1: Very brief or sparse answer (< 30 characters or < 6 words)
        if char_count < 30 or word_count < 6:
            # Step down difficulty if hard or medium, or offer targeted clarifying question
            if next_question.difficulty == QuestionDifficulty.HARD.value:
                next_question.difficulty = QuestionDifficulty.MEDIUM.value
            elif next_question.difficulty == QuestionDifficulty.MEDIUM.value:
                next_question.difficulty = QuestionDifficulty.EASY.value

            adaptation_note = (
                f"Previous answer was brief ({char_count} chars). Target difficulty for Question {next_question.question_order + 1} "
                f"calibrated to '{next_question.difficulty}' to reinforce foundational competencies."
            )
            next_question.selection_reason = (
                f"Adaptive calibration: calibrated to '{next_question.difficulty}' due to brief response on previous question."
            )

        # Rule 2: Substantial, detailed technical answer (>= 150 characters and >= 20 words)
        elif char_count >= 150 and word_count >= 20:
            if next_question.difficulty == QuestionDifficulty.EASY.value:
                next_question.difficulty = QuestionDifficulty.MEDIUM.value
            elif next_question.difficulty == QuestionDifficulty.MEDIUM.value:
                next_question.difficulty = QuestionDifficulty.HARD.value

            adaptation_note = (
                f"Previous answer was thorough ({word_count} words). Progression difficulty for Question {next_question.question_order + 1} "
                f"stepped up to '{next_question.difficulty}' to explore deeper technical depth."
            )
            next_question.selection_reason = (
                f"Adaptive progression: advanced to '{next_question.difficulty}' following comprehensive response on previous question."
            )

        # Rule 3: Moderate answer length (30 - 149 characters)
        else:
            adaptation_note = (
                f"Standard response provided. Maintaining planned difficulty '{next_question.difficulty}' for Question {next_question.question_order + 1}."
            )

        return adaptation_note

    # -------------------------------------------------------------------------
    # State Machine Validation
    # -------------------------------------------------------------------------
    @staticmethod
    def validate_session_start(session: InterviewSession) -> None:
        """Validate state transition to in_progress."""
        if session.status == SessionStatus.IN_PROGRESS.value:
            raise InterviewStateError("Interview session is already in progress.")
        if session.status == SessionStatus.COMPLETED.value:
            raise InterviewStateError("Cannot start a session that has already been completed.")
        if session.status == SessionStatus.ABANDONED.value:
            raise InterviewStateError("Cannot start an abandoned interview session.")
        if session.status != SessionStatus.DRAFT.value:
            raise InterviewStateError(f"Invalid session status '{session.status}' for starting.")

    @staticmethod
    def validate_answer_submission(
        session: InterviewSession,
        current_question: Optional[InterviewQuestion],
    ) -> None:
        """Validate session state when candidate submits an answer."""
        if session.status != SessionStatus.IN_PROGRESS.value:
            raise InterviewStateError(
                f"Cannot submit answers: session is currently '{session.status}' (must be 'in_progress')."
            )
        if not current_question:
            raise InterviewStateError("No active question found for the current session index.")

    @staticmethod
    def validate_next_transition(
        session: InterviewSession,
        has_answered_current: bool,
    ) -> None:
        """Validate advancement to the next question."""
        if session.status != SessionStatus.IN_PROGRESS.value:
            raise InterviewStateError(
                f"Cannot advance: session is currently '{session.status}' (must be 'in_progress')."
            )
        if not has_answered_current:
            raise InterviewStateError(
                "Please submit an answer for the current question before advancing to the next question."
            )

    @staticmethod
    def validate_abandonment(session: InterviewSession) -> None:
        """Validate session abandonment."""
        if session.status == SessionStatus.COMPLETED.value:
            raise InterviewStateError("Cannot abandon a session that has already been completed.")
        if session.status == SessionStatus.ABANDONED.value:
            raise InterviewStateError("Session is already abandoned.")
