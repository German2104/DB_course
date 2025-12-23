from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from passlib.context import CryptContext

from . import models

pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    return pwd_context.verify(password, hashed)


async def create_user(session: AsyncSession, email: str, full_name: str, role: str, password: str) -> models.User:
    user = models.User(email=email, full_name=full_name, role=role, password_hash=hash_password(password))
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


async def get_user_by_email(session: AsyncSession, email: str) -> models.User | None:
    result = await session.execute(select(models.User).where(models.User.email == email))
    return result.scalar_one_or_none()


async def list_courses(session: AsyncSession) -> list[models.Course]:
    result = await session.execute(select(models.Course))
    return result.scalars().all()


async def create_course(session: AsyncSession, payload: dict) -> models.Course:
    course = models.Course(**payload)
    session.add(course)
    await session.commit()
    await session.refresh(course)
    return course


async def list_assignments(session: AsyncSession, course_id: int) -> list[models.Assignment]:
    result = await session.execute(select(models.Assignment).where(models.Assignment.course_id == course_id))
    return result.scalars().all()


async def create_assignment(session: AsyncSession, payload: dict) -> models.Assignment:
    assignment = models.Assignment(**payload)
    session.add(assignment)
    await session.commit()
    await session.refresh(assignment)
    return assignment


async def create_submission(session: AsyncSession, payload: dict) -> models.Submission:
    submission = models.Submission(**payload)
    session.add(submission)
    await session.commit()
    await session.refresh(submission)
    return submission


async def create_grade(session: AsyncSession, payload: dict) -> models.Grade:
    grade = models.Grade(**payload)
    session.add(grade)
    await session.commit()
    await session.refresh(grade)
    return grade


async def list_notifications(session: AsyncSession, user_id: int) -> list[models.Notification]:
    result = await session.execute(select(models.Notification).where(models.Notification.user_id == user_id))
    return result.scalars().all()
