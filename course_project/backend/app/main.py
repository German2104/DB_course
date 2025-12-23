import csv
import io
import json
import os
import uuid
from datetime import datetime, timedelta
from typing import Annotated

from fastapi import Depends, FastAPI, File, HTTPException, UploadFile, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import jwt
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from . import crud, models, reports, schemas
from .db import get_session

SECRET_KEY = os.getenv('SECRET_KEY', 'supersecretkey')
ALGORITHM = 'HS256'
ACCESS_TOKEN_EXPIRE_MINUTES = 60

oauth2_scheme = OAuth2PasswordBearer(tokenUrl='/api/auth/login')

app = FastAPI(title='LMS-lite API', openapi_url='/api/openapi.json', docs_url='/api/docs')


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({'exp': expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    session: AsyncSession = Depends(get_session),
) -> models.User:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get('sub')
        if email is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Invalid token')
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Invalid token') from exc
    user = await crud.get_user_by_email(session, email)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='User not found')
    return user


def require_role(roles: set[str]):
    async def checker(user: models.User = Depends(get_current_user)):
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Forbidden')
        return user
    return checker


@app.post('/api/auth/login', response_model=schemas.Token)
async def login(form_data: Annotated[OAuth2PasswordRequestForm, Depends()], session: AsyncSession = Depends(get_session)):
    user = await crud.get_user_by_email(session, form_data.username)
    if not user or not crud.verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Incorrect credentials')
    token = create_access_token({'sub': user.email, 'role': user.role})
    return schemas.Token(access_token=token)


@app.post('/api/users', response_model=schemas.UserOut)
async def create_user(payload: schemas.UserCreate, session: AsyncSession = Depends(get_session)):
    user = await crud.create_user(session, payload.email, payload.full_name, payload.role, payload.password)
    return user


@app.get('/api/courses', response_model=list[schemas.CourseOut])
async def list_courses(session: AsyncSession = Depends(get_session)):
    return await crud.list_courses(session)


@app.post('/api/courses', response_model=schemas.CourseOut, dependencies=[Depends(require_role({'instructor', 'admin'}))])
async def create_course(payload: schemas.CourseCreate, session: AsyncSession = Depends(get_session)):
    return await crud.create_course(session, payload.model_dump())


@app.get('/api/courses/{course_id}/assignments', response_model=list[schemas.AssignmentOut])
async def list_assignments(course_id: int, session: AsyncSession = Depends(get_session)):
    return await crud.list_assignments(session, course_id)


@app.post('/api/assignments', response_model=schemas.AssignmentOut, dependencies=[Depends(require_role({'instructor', 'admin'}))])
async def create_assignment(payload: schemas.AssignmentCreate, session: AsyncSession = Depends(get_session)):
    return await crud.create_assignment(session, payload.model_dump())


@app.post('/api/submissions', response_model=schemas.SubmissionOut)
async def create_submission(payload: schemas.SubmissionCreate, session: AsyncSession = Depends(get_session), user: models.User = Depends(require_role({'student', 'admin'}))):
    return await crud.create_submission(session, payload.model_dump())


@app.post('/api/grades', response_model=schemas.GradeOut, dependencies=[Depends(require_role({'instructor', 'admin'}))])
async def create_grade(payload: schemas.GradeCreate, session: AsyncSession = Depends(get_session)):
    return await crud.create_grade(session, payload.model_dump())


@app.get('/api/notifications', response_model=list[schemas.NotificationOut])
async def list_notifications(user: models.User = Depends(get_current_user), session: AsyncSession = Depends(get_session)):
    return await crud.list_notifications(session, user.id)


@app.get('/api/reports/leaderboard/{course_id}')
async def report_leaderboard(course_id: int, session: AsyncSession = Depends(get_session)):
    return await reports.course_leaderboard(session, course_id)


@app.get('/api/reports/assignment/{assignment_id}')
async def report_assignment(assignment_id: int, session: AsyncSession = Depends(get_session)):
    return await reports.assignment_report(session, assignment_id)


@app.get('/api/reports/instructor/{instructor_id}')
async def report_instructor(instructor_id: int, session: AsyncSession = Depends(get_session)):
    return await reports.instructor_load(session, instructor_id)


@app.post('/api/batch-import', response_model=schemas.BatchImportResult)
async def batch_import(
    dry_run: bool = False,
    continue_on_error: bool = False,
    file: UploadFile | None = File(default=None),
    session: AsyncSession = Depends(get_session),
    user: models.User = Depends(require_role({'instructor', 'admin'})),
):
    request_id = str(uuid.uuid4())
    imported = 0
    errors = 0
    details: list[str] = []

    records: list[dict]
    if file:
        content = await file.read()
        if file.filename.endswith('.csv'):
            reader = csv.DictReader(io.StringIO(content.decode('utf-8')))
            records = list(reader)
        else:
            records = json.loads(content.decode('utf-8'))
    else:
        raise HTTPException(status_code=400, detail='File required')

    for idx, row in enumerate(records, start=1):
        try:
            payload = {
                'assignment_id': int(row['assignment_id']),
                'student_id': int(row['student_id']),
                'attempt_no': int(row.get('attempt_no', 1)),
                'submitted_at': datetime.fromisoformat(row.get('submitted_at', datetime.utcnow().isoformat())),
                'status': row.get('status', 'submitted'),
                'is_late': bool(row.get('is_late', False)),
                'content_text': row.get('content_text', 'Imported submission'),
            }
            if not dry_run:
                await crud.create_submission(session, payload)
            imported += 1
        except Exception as exc:
            errors += 1
            details.append(f'row {idx}: {exc}')
            await session.execute(
                text('''
                    INSERT INTO import_error_log (source, row_number, payload, error_message, request_id)
                    VALUES (:source, :row_number, :payload::jsonb, :error_message, :request_id)
                '''),
                {
                    'source': file.filename if file else 'unknown',
                    'row_number': idx,
                    'payload': json.dumps(row),
                    'error_message': str(exc),
                    'request_id': request_id,
                },
            )
            await session.commit()
            if not continue_on_error:
                break

    return schemas.BatchImportResult(imported=imported, errors=errors, request_id=request_id, details=details)
