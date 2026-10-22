"""Rubric Engine and Transparent Scoring Calculation Service."""
import re
from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional, Tuple


class CriterionKey(str, Enum):
    TECHNICAL_KNOWLEDGE = "technical_knowledge"
    RELEVANCE = "relevance"
    REASONING_PROBLEM_SOLVING = "reasoning_problem_solving"
    PRACTICAL_APPLICATION = "practical_application"
    BEHAVIORAL_COMPETENCIES = "behavioral_competencies"


RUBRIC_VERSION = "1.0.0"

# Standard descriptions and anchor guidelines for 0-4 scale
SCORING_ANCHORS: Dict[int, str] = {
    0: "No relevant evidence in the answer",
    1: "Limited relevant evidence",
    2: "Partial evidence",
    3: "Strong evidence",
    4: "Thorough, relevant evidence",
}

CRITERION_TITLES: Dict[CriterionKey, str] = {
    CriterionKey.TECHNICAL_KNOWLEDGE: "Technical Knowledge & Correctness",
    CriterionKey.RELEVANCE: "Relevance to Question",
    CriterionKey.REASONING_PROBLEM_SOLVING: "Reasoning & Problem-Solving",
    CriterionKey.PRACTICAL_APPLICATION: "Practical Application & Examples",
    CriterionKey.BEHAVIORAL_COMPETENCIES: "Behavioral Competencies",
}

CRITERION_DESCRIPTIONS: Dict[CriterionKey, str] = {
    CriterionKey.TECHNICAL_KNOWLEDGE: (
        "Accuracy, conceptual correctness, and depth of technical terminology, "
        "syntax, principles, and industry standards without factual misstatements."
    ),
    CriterionKey.RELEVANCE: (
        "Directly addresses all aspects of the interview prompt without evasiveness, "
        "irrelevant topic drift, or generic filler."
    ),
    CriterionKey.REASONING_PROBLEM_SOLVING: (
        "Demonstrates structured analytical thinking, trade-off evaluation, cause-and-effect "
        "understanding, and logical step-by-step problem resolution."
    ),
    CriterionKey.PRACTICAL_APPLICATION: (
        "Provides realistic implementations, concrete production examples, architectural context, "
        "or tangible real-world code/system patterns."
    ),
    CriterionKey.BEHAVIORAL_COMPETENCIES: (
        "Exhibits constructive collaboration, ownership, clear stakeholder communication, "
        "blameless incident resolution, and professional reflection."
    ),
}

# Base weights mapped per question category
CATEGORY_RUBRIC_CONFIGS: Dict[str, Dict[CriterionKey, float]] = {
    "technical": {
        CriterionKey.TECHNICAL_KNOWLEDGE: 0.35,
        CriterionKey.RELEVANCE: 0.25,
        CriterionKey.REASONING_PROBLEM_SOLVING: 0.20,
        CriterionKey.PRACTICAL_APPLICATION: 0.20,
    },
    "problem_solving": {
        CriterionKey.REASONING_PROBLEM_SOLVING: 0.35,
        CriterionKey.TECHNICAL_KNOWLEDGE: 0.25,
        CriterionKey.PRACTICAL_APPLICATION: 0.20,
        CriterionKey.RELEVANCE: 0.20,
    },
    "project_experience": {
        CriterionKey.PRACTICAL_APPLICATION: 0.35,
        CriterionKey.TECHNICAL_KNOWLEDGE: 0.25,
        CriterionKey.REASONING_PROBLEM_SOLVING: 0.20,
        CriterionKey.RELEVANCE: 0.20,
    },
    "behavioral": {
        CriterionKey.BEHAVIORAL_COMPETENCIES: 0.40,
        CriterionKey.RELEVANCE: 0.30,
        CriterionKey.REASONING_PROBLEM_SOLVING: 0.30,
    },
}

# Default fallback config if category is unknown or custom
DEFAULT_RUBRIC_CONFIG: Dict[CriterionKey, float] = {
    CriterionKey.TECHNICAL_KNOWLEDGE: 0.30,
    CriterionKey.RELEVANCE: 0.30,
    CriterionKey.REASONING_PROBLEM_SOLVING: 0.20,
    CriterionKey.PRACTICAL_APPLICATION: 0.20,
}

# Prompt injection and adversarial instruction patterns to sanitize/neutralize
PROMPT_INJECTION_PATTERNS = [
    r"(?i)\bignore\s+(?:all\s+)?(?:previous|prior|above|system)\s+(?:instructions|prompts|rules|commands)\b",
    r"(?i)\byou\s+(?:must|are\s+now|should)\s+(?:give|rate|score)\s+(?:me\s+)?(?:4|100%|full\s+marks|perfect)\b",
    r"(?i)\bdisregard\s+(?:the\s+)?rubric\b",
    r"(?i)\boverride\s+(?:the\s+)?evaluation\b",
    r"(?i)\bsystem\s+prompt\b",
    r"(?i)\bas\s+an\s+ai\s+evaluator,\s+give\b",
    r"(?i)\bprint\s+score\s*:\s*4\b",
    r"(?i)\bdo\s+not\s+evaluate\b",
]

STANDARD_LIMITATIONS_DISCLAIMER = (
    "AI rubric evaluation is an automated assessment of evidence strictly present within the "
    "submitted candidate text response against predefined rubrics. It represents rubric judgments, "
    "not an objective or holistic measurement of a candidate's personal capability, future job performance, "
    "or unstated skills. Self-reported experience in answers is treated as claims rather than independently "
    "verified facts. Personality, emotional state, and demographic inference are strictly excluded."
)


@dataclass
class CriterionEvaluationResult:
    key: str
    name: str
    score: int  # 0 to 4
    max_score: int  # 4
    base_weight: float
    normalized_weight: float
    explanation: str
    evidence_quote: Optional[str]
    is_applicable: bool = True

    def to_dict(self) -> dict:
        return {
            "key": self.key,
            "name": self.name,
            "score": self.score,
            "max_score": self.max_score,
            "base_weight": round(self.base_weight, 4),
            "normalized_weight": round(self.normalized_weight, 4),
            "explanation": self.explanation,
            "evidence_quote": self.evidence_quote,
            "is_applicable": self.is_applicable,
        }


class RubricService:
    """Service for managing question rubrics, weight normalization, and scoring calculations."""

    @staticmethod
    def get_rubric_for_category(category: str) -> Dict[CriterionKey, float]:
        """Return base weights for the specified question category."""
        return CATEGORY_RUBRIC_CONFIGS.get(category.lower(), DEFAULT_RUBRIC_CONFIG)

    @staticmethod
    def normalize_weights(applicable_weights: Dict[CriterionKey, float]) -> Dict[CriterionKey, float]:
        """
        Normalize applicable weights to sum exactly to 1.0.
        Formula: W_i = w_i / sum(w_j for j in applicable)
        """
        total = sum(applicable_weights.values())
        if total <= 0:
            count = len(applicable_weights)
            return {k: 1.0 / count for k in applicable_weights} if count > 0 else {}
        return {k: round(w / total, 6) for k, w in applicable_weights.items()}

    @staticmethod
    def validate_score(score: int) -> int:
        """Enforce score bounds [0, 4]."""
        if not isinstance(score, int) or score < 0 or score > 4:
            raise ValueError(f"Score must be an integer between 0 and 4, got: {score}")
        return score

    @staticmethod
    def detect_prompt_injection(text: str) -> Tuple[bool, List[str]]:
        """
        Detect attempts to override evaluator rules, prompt injection, or adversarial instructions.
        Returns (is_detected, list_of_matched_patterns).
        """
        matches = []
        for pat in PROMPT_INJECTION_PATTERNS:
            if re.search(pat, text):
                matches.append(pat)
        return len(matches) > 0, matches

    @staticmethod
    def sanitize_untrusted_answer(answer_text: str) -> str:
        """
        Neutralize prompt injection attempts without altering genuine domain content.
        Candidate input is always treated as untrusted text, never as instructions.
        """
        sanitized = answer_text
        for pat in PROMPT_INJECTION_PATTERNS:
            sanitized = re.sub(pat, "[FILTERED_INSTRUCTION_OVERRIDE_ATTEMPT]", sanitized)
        return sanitized

    @staticmethod
    def assess_answer_evidence_state(answer_text: str) -> str:
        """
        Categorize response substance:
        - 'absent': blank or whitespace only
        - 'insufficient': non-responsive, 'idk', gibberish, or trivial text (< 12 chars)
        - 'adversarial': primary text is prompt injection
        - 'evaluable': non-trivial text ready for rubric assessment
        """
        stripped = answer_text.strip()
        if not stripped:
            return "absent"

        is_injection, _ = RubricService.detect_prompt_injection(stripped)
        # If the entire answer is basically prompt injection
        if is_injection and len(stripped.split()) < 20:
            return "adversarial"

        lower = stripped.lower()
        insufficient_phrases = [
            "i don't know", "i dont know", "idk", "no idea", "pass", "skip",
            "not sure", "na", "n/a", "none", "dunno", "asdf", "test", "qwerty",
        ]
        if any(p in lower for p in insufficient_phrases) and len(stripped.split()) <= 6:
            return "insufficient"
        if len(stripped) < 12:
            return "insufficient"

        # Check for keyboard smashing (repeating characters or non-words)
        if len(set(lower.replace(" ", ""))) <= 3 and len(stripped) > 6:
            return "insufficient"

        return "evaluable"

    @staticmethod
    def calculate_overall_scores(
        criteria_results: List[CriterionEvaluationResult],
    ) -> Tuple[Optional[float], Optional[float]]:
        """
        Calculate overall score on 0-100 scale and 0-4 rubric scale.
        Only valid, applicable criteria with non-negative scores are counted.
        Formula:
          Overall (0-100) = sum((score_i / 4.0) * normalized_weight_i) * 100
          Rubric (0-4) = sum(score_i * normalized_weight_i)
        """
        applicable = [c for c in criteria_results if c.is_applicable]
        if not applicable:
            return None, None

        total_weight = sum(c.normalized_weight for c in applicable)
        if total_weight <= 0:
            return None, None

        weighted_rubric_sum = sum(c.score * c.normalized_weight for c in applicable)
        rubric_score = round(weighted_rubric_sum / total_weight, 2)
        overall_score = round((rubric_score / 4.0) * 100.0, 1)

        return overall_score, rubric_score
