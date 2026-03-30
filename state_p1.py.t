import operator
from typing import TypedDict, List, Optional, Annotated
from pydantic import BaseModel, Field

# ---------------------------------------------------------
# Pydantic Models (Unchanged - Valid for LLM Structured Output)
# ---------------------------------------------------------
class ExtractorOutput(BaseModel):
    who: Optional[str] = Field(None)
    what: Optional[str] = Field(None)
    why: Optional[str] = Field(None)
    ac_evidence: Optional[str] = Field(None)

class ValidatorOutput(BaseModel):
    is_valid: bool
    normalized_value: Optional[str] = Field(None)
    rejection_reason: Optional[str] = Field(None)

class TechQuestionsOutput(BaseModel):
    questions: List[str]

class FinalStoryOutput (BaseModel):
    story: str = Field(description="The fully synthesized Jira Agile Story")

# ---------------------------------------------------------
# LangGraph State (Refactored for Production)
# ---------------------------------------------------------
class WorkflowState(TypedDict):
    raw_input: str
    who: Optional[str]
    what: Optional[str]
    why: Optional[str]
    ac_evidence: Optional[str]
    
    missing_fields: List[str]
    phase1_retries: int
    last_rejection_reason: Optional[str]
    is_aborted: bool
    abort_reason: Optional[str]
    
    pending_questions: List[str]
    total_tech_questions: int
    
    tech_notes: Annotated[List[str], operator.add]
    
    final_story: Optional[str]
    feedback_retries: int
    is_complete: bool
    feedback_raw: Optional[str]
