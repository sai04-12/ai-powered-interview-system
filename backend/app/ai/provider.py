"""AI Evaluation Provider Abstraction Layer and Deterministic Engine."""
import abc
import re
import time
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field

from app.core.config import settings
from app.services.rubric_service import (
    CRITERION_DESCRIPTIONS,
    CRITERION_TITLES,
    CriterionEvaluationResult,
    CriterionKey,
    RUBRIC_VERSION,
    SCORING_ANCHORS,
    STANDARD_LIMITATIONS_DISCLAIMER,
    RubricService,
)


class EvaluationRequest(BaseModel):
    """Payload to request answer evaluation."""
    question_text: str
    category: str
    skill: str
    difficulty: str
    answer_text: str
    job_title: Optional[str] = None
    job_description: Optional[str] = None


class CriterionScoreSchema(BaseModel):
    """Structured criterion score for serialization and validation."""
    key: str
    name: str
    score: int = Field(..., ge=0, le=4)
    max_score: int = Field(default=4)
    base_weight: float
    normalized_weight: float
    explanation: str
    evidence_quote: Optional[str] = None
    is_applicable: bool = True


class EvaluationResponse(BaseModel):
    """Structured evaluation output conforming to Pydantic schema."""
    status: str  # "completed", "failed", "requires_review"
    rubric_version: str = RUBRIC_VERSION
    criteria_scores: List[CriterionScoreSchema]
    evidence_excerpts: List[str]
    strengths: List[str]
    improvement_areas: List[str]
    overall_score: Optional[float] = None  # 0.0 - 100.0
    normalized_score: Optional[float] = None  # 0.0 - 4.0
    evaluator_type: str
    provider_metadata: Dict[str, Any]
    evaluation_limitations: str = STANDARD_LIMITATIONS_DISCLAIMER
    feedback_summary: Optional[str] = None


class BaseEvaluationProvider(abc.ABC):
    """Abstract base class for all AI answer evaluation providers."""

    @abc.abstractmethod
    def evaluate(self, request: EvaluationRequest) -> EvaluationResponse:
        """Evaluate candidate answer and return structured EvaluationResponse."""
        pass


class DeterministicEvaluationProvider(BaseEvaluationProvider):
    """
    Deterministic, transparent evaluation engine.
    Produces consistent, rubric-grounded evaluations using semantic taxonomy matching,
    structural reasoning analysis, and authentic evidence excerpting.
    Never hallucinates quotes and completely ignores prompt injections.
    """

    def evaluate(self, request: EvaluationRequest) -> EvaluationResponse:
        start_time = time.time()
        raw_text = request.answer_text
        category = request.category.lower()
        skill = request.skill.lower()

        # 1. Assess Evidence State (absent, insufficient, adversarial, evaluable)
        evidence_state = RubricService.assess_answer_evidence_state(raw_text)

        # Handle absent answer
        if evidence_state == "absent":
            return self._build_absent_response(request, start_time)

        # Handle adversarial attempt (prompt injection as sole content)
        if evidence_state == "adversarial":
            return self._build_adversarial_response(request, start_time)

        # Handle insufficient evidence (e.g. "I don't know", gibberish)
        if evidence_state == "insufficient":
            return self._build_insufficient_response(request, start_time)

        # 2. Sanitize candidate answer from any embedded override attempts
        sanitized_text = RubricService.sanitize_untrusted_answer(raw_text)

        # 3. Retrieve and normalize rubric weights
        base_rubric = RubricService.get_rubric_for_category(category)
        norm_weights = RubricService.normalize_weights(base_rubric)

        # 4. Evaluate each criterion deterministically
        criteria_results: List[CriterionEvaluationResult] = []
        evidence_excerpts: List[str] = []

        # Extract sentences from candidate's answer for genuine quotes
        candidate_sentences = [
            s.strip() for s in re.split(r"[.!?\n]+", sanitized_text)
            if len(s.strip()) > 8 and "[FILTERED_INSTRUCTION_OVERRIDE_ATTEMPT]" not in s
        ]

        # Evaluate Technical Knowledge
        if CriterionKey.TECHNICAL_KNOWLEDGE in base_rubric:
            tech_result = self._score_technical_knowledge(
                skill=skill,
                answer_text=sanitized_text,
                sentences=candidate_sentences,
                base_w=base_rubric[CriterionKey.TECHNICAL_KNOWLEDGE],
                norm_w=norm_weights[CriterionKey.TECHNICAL_KNOWLEDGE],
            )
            criteria_results.append(tech_result)
            if tech_result.evidence_quote:
                evidence_excerpts.append(tech_result.evidence_quote)

        # Evaluate Relevance
        if CriterionKey.RELEVANCE in base_rubric:
            rel_result = self._score_relevance(
                question_text=request.question_text,
                skill=skill,
                answer_text=sanitized_text,
                sentences=candidate_sentences,
                base_w=base_rubric[CriterionKey.RELEVANCE],
                norm_w=norm_weights[CriterionKey.RELEVANCE],
            )
            criteria_results.append(rel_result)
            if rel_result.evidence_quote and rel_result.evidence_quote not in evidence_excerpts:
                evidence_excerpts.append(rel_result.evidence_quote)

        # Evaluate Reasoning & Problem Solving
        if CriterionKey.REASONING_PROBLEM_SOLVING in base_rubric:
            reasoning_result = self._score_reasoning(
                answer_text=sanitized_text,
                sentences=candidate_sentences,
                base_w=base_rubric[CriterionKey.REASONING_PROBLEM_SOLVING],
                norm_w=norm_weights[CriterionKey.REASONING_PROBLEM_SOLVING],
            )
            criteria_results.append(reasoning_result)
            if reasoning_result.evidence_quote and reasoning_result.evidence_quote not in evidence_excerpts:
                evidence_excerpts.append(reasoning_result.evidence_quote)

        # Evaluate Practical Application
        if CriterionKey.PRACTICAL_APPLICATION in base_rubric:
            practical_result = self._score_practical_application(
                answer_text=sanitized_text,
                sentences=candidate_sentences,
                base_w=base_rubric[CriterionKey.PRACTICAL_APPLICATION],
                norm_w=norm_weights[CriterionKey.PRACTICAL_APPLICATION],
            )
            criteria_results.append(practical_result)
            if practical_result.evidence_quote and practical_result.evidence_quote not in evidence_excerpts:
                evidence_excerpts.append(practical_result.evidence_quote)

        # Evaluate Behavioral Competencies
        if CriterionKey.BEHAVIORAL_COMPETENCIES in base_rubric:
            behavioral_result = self._score_behavioral(
                answer_text=sanitized_text,
                sentences=candidate_sentences,
                base_w=base_rubric[CriterionKey.BEHAVIORAL_COMPETENCIES],
                norm_w=norm_weights[CriterionKey.BEHAVIORAL_COMPETENCIES],
            )
            criteria_results.append(behavioral_result)
            if behavioral_result.evidence_quote and behavioral_result.evidence_quote not in evidence_excerpts:
                evidence_excerpts.append(behavioral_result.evidence_quote)

        # 5. Calculate Overall Scores
        overall_score, rubric_score = RubricService.calculate_overall_scores(criteria_results)

        # 6. Extract Strengths and Actionable Improvement Suggestions
        strengths = self._generate_strengths(criteria_results, skill)
        improvements = self._generate_improvements(criteria_results, skill)

        # 7. Build Constructive Feedback Summary
        summary = (
            f"The candidate's response demonstrated a rubric evaluation score of {rubric_score}/4.0 "
            f"({overall_score}%). Primary strength: {strengths[0] if strengths else 'Coherent response'}. "
            f"Key opportunity for growth: {improvements[0] if improvements else 'Expand technical depth'}."
        )

        duration_ms = int((time.time() - start_time) * 1000)

        return EvaluationResponse(
            status="completed",
            rubric_version=RUBRIC_VERSION,
            criteria_scores=[CriterionScoreSchema(**c.to_dict()) for c in criteria_results],
            evidence_excerpts=evidence_excerpts[:3],
            strengths=strengths,
            improvement_areas=improvements,
            overall_score=overall_score,
            normalized_score=rubric_score,
            evaluator_type="deterministic",
            provider_metadata={
                "provider": "deterministic_engine",
                "version": RUBRIC_VERSION,
                "execution_time_ms": duration_ms,
                "evidence_state": "evaluable",
            },
            evaluation_limitations=STANDARD_LIMITATIONS_DISCLAIMER,
            feedback_summary=summary,
        )

    def _score_technical_knowledge(
        self,
        skill: str,
        answer_text: str,
        sentences: List[str],
        base_w: float,
        norm_w: float,
    ) -> CriterionEvaluationResult:
        lower = answer_text.lower()
        score = 1
        explanation = "Limited technical specifics identified in candidate response."
        quote = sentences[0] if sentences else None

        # Technical domain markers
        tech_indicators = [
            "function", "class", "method", "variable", "database", "query", "index",
            "api", "endpoint", "async", "await", "coroutine", "thread", "concurrency",
            "transaction", "schema", "orm", "cache", "redis", "postgres", "sql",
            "widget", "state", "stream", "component", "interface", "protocol",
            "memory", "latency", "throughput", "algorithm", "data structure", "docker",
        ]
        matched_indicators = [t for t in tech_indicators if t in lower]
        has_skill_mention = skill in lower

        if has_skill_mention and len(matched_indicators) >= 4:
            score = 4
            explanation = (
                f"Thorough relevant evidence: Directly articulates {skill} concepts with specific "
                f"technical vocabulary ({', '.join(matched_indicators[:3])})."
            )
        elif len(matched_indicators) >= 2 or has_skill_mention:
            score = 3
            explanation = (
                f"Strong evidence: Accurately references technical principles and domain terminology "
                f"relevant to {skill}."
            )
        elif len(matched_indicators) == 1:
            score = 2
            explanation = "Partial evidence: Mentions relevant technical terminology but lacks deeper conceptual precision."
        else:
            score = 1
            explanation = "Limited evidence: Superficial or minimal technical detail provided."

        # Pick quote that contains matching indicator
        for s in sentences:
            if any(t in s.lower() for t in matched_indicators) or skill in s.lower():
                quote = s
                break

        return CriterionEvaluationResult(
            key=CriterionKey.TECHNICAL_KNOWLEDGE.value,
            name=CRITERION_TITLES[CriterionKey.TECHNICAL_KNOWLEDGE],
            score=score,
            max_score=4,
            base_weight=base_w,
            normalized_weight=norm_w,
            explanation=explanation,
            evidence_quote=quote,
            is_applicable=True,
        )

    def _score_relevance(
        self,
        question_text: str,
        skill: str,
        answer_text: str,
        sentences: List[str],
        base_w: float,
        norm_w: float,
    ) -> CriterionEvaluationResult:
        lower = answer_text.lower()
        score = 2
        explanation = "Partial evidence: Response touches upon general topic but wanders from core question prompt."
        quote = sentences[0] if sentences else None

        # Check question key terms
        q_words = [
            w.lower() for w in re.findall(r"\b[a-zA-Z]{4,}\b", question_text)
            if w.lower() not in {"what", "when", "where", "which", "explain", "describe", "discuss", "would"}
        ]
        matched_q_words = [w for w in q_words if w in lower]

        if len(matched_q_words) >= 3 or (len(matched_q_words) >= 1 and skill in lower):
            score = 4
            explanation = "Thorough evidence: Answer directly and comprehensively addresses core questions in the prompt."
        elif len(matched_q_words) >= 1:
            score = 3
            explanation = "Strong evidence: Response directly aligns with the primary objectives of the question."
        elif len(sentences) >= 2:
            score = 2
            explanation = "Partial evidence: Addressed contextual background without targeting the specific question constraints."
        else:
            score = 1
            explanation = "Limited evidence: Highly tangential response with weak topical relevance."

        for s in sentences:
            if any(w in s.lower() for w in matched_q_words):
                quote = s
                break

        return CriterionEvaluationResult(
            key=CriterionKey.RELEVANCE.value,
            name=CRITERION_TITLES[CriterionKey.RELEVANCE],
            score=score,
            max_score=4,
            base_weight=base_w,
            normalized_weight=norm_w,
            explanation=explanation,
            evidence_quote=quote,
            is_applicable=True,
        )

    def _score_reasoning(
        self,
        answer_text: str,
        sentences: List[str],
        base_w: float,
        norm_w: float,
    ) -> CriterionEvaluationResult:
        lower = answer_text.lower()
        score = 2
        quote = sentences[0] if sentences else None

        reasoning_markers = [
            "because", "therefore", "however", "in order to", "as a result", "trade-off",
            "advantage", "disadvantage", "alternatively", "firstly", "secondly", "leads to",
            "ensures", "prevents", "mitigates", "enables", "compare", "contrast",
        ]
        matched_markers = [m for m in reasoning_markers if m in lower]

        if len(matched_markers) >= 3:
            score = 4
            explanation = (
                f"Thorough evidence: Employs structured logical reasoning and trade-off analysis "
                f"using causal connectives ({', '.join(matched_markers[:2])})."
            )
        elif len(matched_markers) >= 1:
            score = 3
            explanation = "Strong evidence: Provides coherent cause-and-effect reasoning connecting problem and solution."
        elif len(sentences) >= 3:
            score = 2
            explanation = "Partial evidence: Step-by-step description is present but lacks explicit trade-off justification."
        else:
            score = 1
            explanation = "Limited evidence: Conclusions are asserted without supporting rationale or reasoning."

        for s in sentences:
            if any(m in s.lower() for m in matched_markers):
                quote = s
                break

        return CriterionEvaluationResult(
            key=CriterionKey.REASONING_PROBLEM_SOLVING.value,
            name=CRITERION_TITLES[CriterionKey.REASONING_PROBLEM_SOLVING],
            score=score,
            max_score=4,
            base_weight=base_w,
            normalized_weight=norm_w,
            explanation=explanation,
            evidence_quote=quote,
            is_applicable=True,
        )

    def _score_practical_application(
        self,
        answer_text: str,
        sentences: List[str],
        base_w: float,
        norm_w: float,
    ) -> CriterionEvaluationResult:
        lower = answer_text.lower()
        score = 1
        quote = sentences[0] if sentences else None

        practical_markers = [
            "for example", "in my project", "production", "implemented", "we used",
            "i configured", "created a", "deployed", "tested with", "handled by",
            "architecture", "pipeline", "service", "database table", "dockerfile",
        ]
        matched_markers = [m for m in practical_markers if m in lower]

        if len(matched_markers) >= 2 or any(char in answer_text for char in ["def ", "class ", "=>", "SELECT ", "import "]):
            score = 4
            explanation = "Thorough evidence: Detailed realistic implementation patterns, code snippets, or production examples cited."
        elif len(matched_markers) >= 1:
            score = 3
            explanation = "Strong evidence: Mentions concrete application scenarios or production tooling."
        elif len(sentences) >= 2:
            score = 2
            explanation = "Partial evidence: Conceptual understanding present but lacks concrete practical scenarios."
        else:
            score = 1
            explanation = "Limited evidence: Purely theoretical answer with no practical examples or real-world application."

        for s in sentences:
            if any(m in s.lower() for m in practical_markers):
                quote = s
                break

        return CriterionEvaluationResult(
            key=CriterionKey.PRACTICAL_APPLICATION.value,
            name=CRITERION_TITLES[CriterionKey.PRACTICAL_APPLICATION],
            score=score,
            max_score=4,
            base_weight=base_w,
            normalized_weight=norm_w,
            explanation=explanation,
            evidence_quote=quote,
            is_applicable=True,
        )

    def _score_behavioral(
        self,
        answer_text: str,
        sentences: List[str],
        base_w: float,
        norm_w: float,
    ) -> CriterionEvaluationResult:
        lower = answer_text.lower()
        score = 2
        quote = sentences[0] if sentences else None

        behavioral_markers = [
            "collaborat", "communicat", "team", "stakeholder", "feedback",
            "resolved", "ownership", "responsibility", "learned", "agile",
            "post-mortem", "retrospective", "shared", "mentored", "aligned",
        ]
        matched_markers = [m for m in behavioral_markers if m in lower]

        if len(matched_markers) >= 3:
            score = 4
            explanation = "Thorough evidence: Highlights collaborative ownership, clear communication, and reflective learning."
        elif len(matched_markers) >= 1:
            score = 3
            explanation = "Strong evidence: Demonstrates constructive team participation and situational ownership."
        elif len(sentences) >= 2:
            score = 2
            explanation = "Partial evidence: Describes situational outcome but minimizes personal contribution or learning."
        else:
            score = 1
            explanation = "Limited evidence: Minimal context or collaborative awareness demonstrated."

        for s in sentences:
            if any(m in s.lower() for m in matched_markers):
                quote = s
                break

        return CriterionEvaluationResult(
            key=CriterionKey.BEHAVIORAL_COMPETENCIES.value,
            name=CRITERION_TITLES[CriterionKey.BEHAVIORAL_COMPETENCIES],
            score=score,
            max_score=4,
            base_weight=base_w,
            normalized_weight=norm_w,
            explanation=explanation,
            evidence_quote=quote,
            is_applicable=True,
        )

    def _generate_strengths(self, criteria: List[CriterionEvaluationResult], skill: str) -> List[str]:
        strengths = []
        for c in sorted(criteria, key=lambda x: x.score, reverse=True):
            if c.score >= 3:
                if c.key == CriterionKey.TECHNICAL_KNOWLEDGE.value:
                    strengths.append(f"Clear grasp of {skill} core terminology and architectural principles.")
                elif c.key == CriterionKey.RELEVANCE.value:
                    strengths.append("Direct, focused answers that address the core prompt requirements.")
                elif c.key == CriterionKey.REASONING_PROBLEM_SOLVING.value:
                    strengths.append("Structured cause-and-effect thinking with explicit trade-off awareness.")
                elif c.key == CriterionKey.PRACTICAL_APPLICATION.value:
                    strengths.append("Concrete production context and realistic implementation examples.")
                elif c.key == CriterionKey.BEHAVIORAL_COMPETENCIES.value:
                    strengths.append("Strong collaborative perspective, stakeholder empathy, and shared ownership.")
        if not strengths:
            strengths.append("Submitted structured text responding to the interview question.")
        return strengths[:3]

    def _generate_improvements(self, criteria: List[CriterionEvaluationResult], skill: str) -> List[str]:
        improvements = []
        for c in sorted(criteria, key=lambda x: x.score):
            if c.score <= 2:
                if c.key == CriterionKey.TECHNICAL_KNOWLEDGE.value:
                    improvements.append(f"Reinforce deeper technical mechanisms and syntax for {skill}.")
                elif c.key == CriterionKey.RELEVANCE.value:
                    improvements.append("Target specific constraints in the question more directly without tangential topics.")
                elif c.key == CriterionKey.REASONING_PROBLEM_SOLVING.value:
                    improvements.append("Explain 'why' certain solutions are chosen, analyzing alternative approaches and edge cases.")
                elif c.key == CriterionKey.PRACTICAL_APPLICATION.value:
                    improvements.append("Include code excerpts, schema definitions, or concrete deployment patterns.")
                elif c.key == CriterionKey.BEHAVIORAL_COMPETENCIES.value:
                    improvements.append("Articulate personal impact, retrospective lessons, and stakeholder alignment strategies.")
        if not improvements:
            improvements.append("Continue maintaining strong technical depth and exploring nuanced architectural trade-offs.")
        return improvements[:3]

    def _build_absent_response(self, request: EvaluationRequest, start_time: float) -> EvaluationResponse:
        base_rubric = RubricService.get_rubric_for_category(request.category)
        norm_weights = RubricService.normalize_weights(base_rubric)
        criteria = [
            CriterionScoreSchema(
                key=k.value,
                name=CRITERION_TITLES[k],
                score=0,
                max_score=4,
                base_weight=w,
                normalized_weight=norm_weights[k],
                explanation="No relevant evidence: Answer was absent or whitespace-only.",
                evidence_quote=None,
                is_applicable=True,
            )
            for k, w in base_rubric.items()
        ]
        duration_ms = int((time.time() - start_time) * 1000)
        return EvaluationResponse(
            status="completed",
            rubric_version=RUBRIC_VERSION,
            criteria_scores=criteria,
            evidence_excerpts=[],
            strengths=[],
            improvement_areas=["Submit a response addressing the technical prompt."],
            overall_score=0.0,
            normalized_score=0.0,
            evaluator_type="deterministic",
            provider_metadata={
                "provider": "deterministic_engine",
                "version": RUBRIC_VERSION,
                "execution_time_ms": duration_ms,
                "evidence_state": "absent",
            },
            evaluation_limitations=STANDARD_LIMITATIONS_DISCLAIMER,
            feedback_summary="No answer text was submitted by candidate for this question.",
        )

    def _build_adversarial_response(self, request: EvaluationRequest, start_time: float) -> EvaluationResponse:
        base_rubric = RubricService.get_rubric_for_category(request.category)
        norm_weights = RubricService.normalize_weights(base_rubric)
        criteria = [
            CriterionScoreSchema(
                key=k.value,
                name=CRITERION_TITLES[k],
                score=0,
                max_score=4,
                base_weight=w,
                normalized_weight=norm_weights[k],
                explanation="No valid domain evidence: Candidate answer contained evaluator override instructions.",
                evidence_quote=None,
                is_applicable=True,
            )
            for k, w in base_rubric.items()
        ]
        duration_ms = int((time.time() - start_time) * 1000)
        return EvaluationResponse(
            status="requires_review",
            rubric_version=RUBRIC_VERSION,
            criteria_scores=criteria,
            evidence_excerpts=[],
            strengths=[],
            improvement_areas=["Submit substantive technical answers rather than system override instructions."],
            overall_score=None,
            normalized_score=None,
            evaluator_type="deterministic",
            provider_metadata={
                "provider": "deterministic_engine",
                "version": RUBRIC_VERSION,
                "execution_time_ms": duration_ms,
                "evidence_state": "adversarial",
                "flagged_adversarial_input": True,
            },
            evaluation_limitations=STANDARD_LIMITATIONS_DISCLAIMER,
            feedback_summary=(
                "Evaluation suspended: Submitted text contained evaluator override commands and lacked substantive "
                "technical evidence. Requires human review."
            ),
        )

    def _build_insufficient_response(self, request: EvaluationRequest, start_time: float) -> EvaluationResponse:
        base_rubric = RubricService.get_rubric_for_category(request.category)
        norm_weights = RubricService.normalize_weights(base_rubric)
        criteria = [
            CriterionScoreSchema(
                key=k.value,
                name=CRITERION_TITLES[k],
                score=0,
                max_score=4,
                base_weight=w,
                normalized_weight=norm_weights[k],
                explanation=f"Insufficient evidence: '{request.answer_text.strip()}' does not provide assessable evidence.",
                evidence_quote=request.answer_text.strip(),
                is_applicable=True,
            )
            for k, w in base_rubric.items()
        ]
        duration_ms = int((time.time() - start_time) * 1000)
        return EvaluationResponse(
            status="requires_review",
            rubric_version=RUBRIC_VERSION,
            criteria_scores=criteria,
            evidence_excerpts=[request.answer_text.strip()],
            strengths=[],
            improvement_areas=[f"Provide a detailed, substantive explanation of {request.skill}."],
            overall_score=None,
            normalized_score=None,
            evaluator_type="deterministic",
            provider_metadata={
                "provider": "deterministic_engine",
                "version": RUBRIC_VERSION,
                "execution_time_ms": duration_ms,
                "evidence_state": "insufficient",
            },
            evaluation_limitations=STANDARD_LIMITATIONS_DISCLAIMER,
            feedback_summary="Insufficient evidence to produce a defensible technical evaluation. Flagged for review.",
        )


class MockEvaluationProvider(BaseEvaluationProvider):
    """Mock provider allowing tests to simulate timeouts, outages, and malformed outputs."""

    def __init__(
        self,
        simulate_timeout: bool = False,
        simulate_failure: bool = False,
        simulate_malformed: bool = False,
    ):
        self.simulate_timeout = simulate_timeout
        self.simulate_failure = simulate_failure
        self.simulate_malformed = simulate_malformed

    def evaluate(self, request: EvaluationRequest) -> EvaluationResponse:
        if self.simulate_timeout:
            raise TimeoutError("Simulated upstream AI provider request timed out after 15s")

        if self.simulate_failure:
            raise RuntimeError("Simulated upstream AI provider service unavailable (HTTP 503)")

        if self.simulate_malformed:
            # Return invalid schema or missing required field
            return EvaluationResponse(
                status="failed",
                rubric_version=RUBRIC_VERSION,
                criteria_scores=[],
                evidence_excerpts=[],
                strengths=[],
                improvement_areas=[],
                overall_score=None,
                normalized_score=None,
                evaluator_type="mock",
                provider_metadata={"simulated_malformed": True},
                evaluation_limitations=STANDARD_LIMITATIONS_DISCLAIMER,
                feedback_summary="Evaluation failed due to malformed model response.",
            )

        # Normal deterministic fallback simulation
        det_provider = DeterministicEvaluationProvider()
        resp = det_provider.evaluate(request)
        resp.evaluator_type = "mock"
        resp.provider_metadata["provider"] = "mock_provider"
        return resp


def get_evaluation_provider(provider_type: Optional[str] = None) -> BaseEvaluationProvider:
    """Factory creating configured AI evaluation provider based on environment settings."""
    chosen = (provider_type or getattr(settings, "AI_EVALUATION_PROVIDER", "deterministic")).lower()
    if chosen == "mock":
        return MockEvaluationProvider()
    return DeterministicEvaluationProvider()
