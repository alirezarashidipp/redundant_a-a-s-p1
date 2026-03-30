from typing import Literal
from langgraph.graph import StateGraph, START, END
from state_p import WorkflowState

# from llm_client import llm
# from state_p import ExtractorOutput, ...


async def phase0_extract(state: WorkflowState):
    raw_input = state.get("raw_input", "")
    
    # TODO: Replace with actual async LLM call
    # result = await llm.aquery(prompt, ExtractorOutput)
    
    who = "Frontend Developer"  # Mocked
    what = "Implement login page"  # Mocked
    why = None  # Mocked as missing
    
    missing_fields = []
    if not who: missing_fields.append("who")
    if not what: missing_fields.append("what")
    if not why: missing_fields.append("why")
    
    return {
        "who": who,
        "what": what,
        "why": why,
        "missing_fields": missing_fields
    }


def route_after_extract(state: WorkflowState) -> Literal["wait_for_missing_info", "phase1_validate"]:
    if state.get("missing_fields"):
        return "wait_for_missing_info"
    return "phase1_validate"


async def wait_for_missing_info(state: WorkflowState):
    # The graph will be paused BEFORE this node in main_p.py using interrupt_before
    # When resumed, 'raw_input' must be updated with the user's new answer.
    return {}


async def phase1_validate(state: WorkflowState):
    # TODO: Implement validation logic
    is_valid = True 
    
    if not is_valid:
        return {
            "is_aborted": True,
            "abort_reason": "Policy violation"
        }
    return {"is_aborted": False}


def route_after_validate(state: WorkflowState) -> Literal["phase2_tech_questions", END]:
    if state.get("is_aborted"):
        return END
    return "phase2_tech_questions"


async def phase2_tech_questions(state: WorkflowState):
    # TODO: Generate dynamic technical questions via LLM
    questions = ["What is the expected RPS?", "Which database are we using?"]
    
    return {
        "pending_questions": questions,
        "total_tech_questions": len(questions)
    }


def route_before_tech_answers(state: WorkflowState) -> Literal["wait_for_tech_answers", "phase3_story"]:
    if state.get("pending_questions"):
        return "wait_for_tech_answers"
    return "phase3_story"


async def wait_for_tech_answers(state: WorkflowState):
    feedback = state.get("feedback_raw", "")
    pending = list(state.get("pending_questions", []))
    
    if pending:
        pending.pop(0)
        
    return {
        "tech_notes": [feedback],  # FIXED: Native LangGraph Reducer handles the append
        "pending_questions": pending,
        "feedback_raw": None  # Clean up the state
    }


async def phase3_story(state: WorkflowState):
    # TODO: Final LLM synthesis
    final_story = f"As a {state.get('who')}, I want to {state.get('what')}..."
    
    return {
        "final_story": final_story,
        "is_complete": True
    }


def build_graph() -> StateGraph:
    builder = StateGraph(WorkflowState)
    
    builder.add_node("phase0_extract", phase0_extract)
    builder.add_node("wait_for_missing_info", wait_for_missing_info)
    builder.add_node("phase1_validate", phase1_validate)
    builder.add_node("phase2_tech_questions", phase2_tech_questions)
    builder.add_node("wait_for_tech_answers", wait_for_tech_answers)
    builder.add_node("phase3_story", phase3_story)
    
    builder.add_edge(START, "phase0_extract")
    
    builder.add_conditional_edges("phase0_extract", route_after_extract)
    builder.add_edge("wait_for_missing_info", "phase0_extract")
    
    builder.add_conditional_edges("phase1_validate", route_after_validate)
    
    builder.add_edge("phase2_tech_questions", "wait_for_tech_answers")
    
    builder.add_conditional_edges("wait_for_tech_answers", route_before_tech_answers)
    
    builder.add_edge("phase3_story", END)
    
    return builder

# Note: The compilation step (.compile(checkpointer=...)) MUST be done in main_p.py
