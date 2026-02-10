from __future__ import annotations

from fastapi import Depends, FastAPI, HTTPException, status

from app.api.deps import get_current_user, require_role
from app.repositories.in_memory import repository
from app.schemas.models import (
    CourseOut,
    GradeCreate,
    GradeOut,
    LoginRequest,
    SubmissionCreate,
    SubmissionOut,
    TokenResponse,
)
from app.services.auth import login


def create_app() -> FastAPI:
    app = FastAPI(title="LMS Backend")

    @app.post("/auth/login", response_model=TokenResponse)
    def login_endpoint(body: LoginRequest):
        token = login(body.email, body.password)
        return TokenResponse(access_token=token)

    @app.get("/courses", response_model=list[CourseOut])
    def list_courses(_: dict = Depends(get_current_user)):
        return repository.list_courses()

    @app.post("/assignments/{assignment_id}/submissions", response_model=SubmissionOut, status_code=status.HTTP_201_CREATED)
    def submit_assignment(
        assignment_id: int,
        body: SubmissionCreate,
        user: dict = Depends(require_role("student")),
    ):
        if assignment_id not in repository.assignments:
            raise HTTPException(status_code=404, detail="Assignment not found")
        return repository.create_submission(assignment_id, user["sub"], body.content)

    @app.post("/submissions/{submission_id}/grade", response_model=GradeOut)
    def grade_submission(
        submission_id: int,
        body: GradeCreate,
        user: dict = Depends(require_role("teacher", "admin")),
    ):
        submission = repository.get_submission(submission_id)
        if not submission:
            raise HTTPException(status_code=404, detail="Submission not found")
        return repository.create_or_update_grade(submission_id, user["sub"], body.score, body.feedback)

    @app.get("/grades", response_model=list[GradeOut])
    def list_grades(_: dict = Depends(require_role("admin", "teacher"))):
        return repository.list_grades()

    return app


app = create_app()
