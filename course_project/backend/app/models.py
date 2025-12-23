from datetime import datetime, date
from sqlalchemy import Boolean, CheckConstraint, Date, ForeignKey, Integer, Numeric, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = 'users'

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    full_name: Mapped[str] = mapped_column(Text, nullable=False)
    role: Mapped[str] = mapped_column(Text, nullable=False)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)
    last_login_at: Mapped[datetime | None] = mapped_column(default=None)

    courses_created = relationship('Course', back_populates='creator')


class Course(Base):
    __tablename__ = 'courses'

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    created_by: Mapped[int] = mapped_column(ForeignKey('users.id', onupdate='CASCADE', ondelete='RESTRICT'))
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)

    creator = relationship('User', back_populates='courses_created')
    assignments = relationship('Assignment', back_populates='course')


class CourseInstructor(Base):
    __tablename__ = 'course_instructors'
    __table_args__ = (UniqueConstraint('course_id', 'instructor_id'),)

    id: Mapped[int] = mapped_column(primary_key=True)
    course_id: Mapped[int] = mapped_column(ForeignKey('courses.id', ondelete='CASCADE', onupdate='CASCADE'))
    instructor_id: Mapped[int] = mapped_column(ForeignKey('users.id', ondelete='RESTRICT', onupdate='CASCADE'))
    role_label: Mapped[str] = mapped_column(Text, nullable=False, default='lecturer')
    assigned_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)
    is_primary: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)


class CourseEnrollment(Base):
    __tablename__ = 'course_enrollments'
    __table_args__ = (UniqueConstraint('course_id', 'student_id'),)

    id: Mapped[int] = mapped_column(primary_key=True)
    course_id: Mapped[int] = mapped_column(ForeignKey('courses.id', ondelete='CASCADE', onupdate='CASCADE'))
    student_id: Mapped[int] = mapped_column(ForeignKey('users.id', ondelete='RESTRICT', onupdate='CASCADE'))
    status: Mapped[str] = mapped_column(Text, nullable=False)
    enrolled_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)
    final_grade: Mapped[float | None] = mapped_column(Numeric(5, 2))
    progress_pct: Mapped[float] = mapped_column(Numeric(5, 2), nullable=False, default=0)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)


class Assignment(Base):
    __tablename__ = 'assignments'

    id: Mapped[int] = mapped_column(primary_key=True)
    course_id: Mapped[int] = mapped_column(ForeignKey('courses.id', ondelete='CASCADE', onupdate='CASCADE'))
    title: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    max_score: Mapped[float] = mapped_column(Numeric(6, 2), nullable=False)
    due_at: Mapped[datetime] = mapped_column(nullable=False)
    allow_late: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    position: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)

    course = relationship('Course', back_populates='assignments')


class AssignmentCriteria(Base):
    __tablename__ = 'assignment_criteria'

    id: Mapped[int] = mapped_column(primary_key=True)
    assignment_id: Mapped[int] = mapped_column(ForeignKey('assignments.id', ondelete='CASCADE', onupdate='CASCADE'))
    title: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    max_points: Mapped[float] = mapped_column(Numeric(6, 2), nullable=False)
    weight: Mapped[float] = mapped_column(Numeric(6, 3), nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)


class Submission(Base):
    __tablename__ = 'submissions'
    __table_args__ = (UniqueConstraint('assignment_id', 'student_id', 'attempt_no'),)

    id: Mapped[int] = mapped_column(primary_key=True)
    assignment_id: Mapped[int] = mapped_column(ForeignKey('assignments.id', ondelete='CASCADE', onupdate='CASCADE'))
    student_id: Mapped[int] = mapped_column(ForeignKey('users.id', ondelete='RESTRICT', onupdate='CASCADE'))
    attempt_no: Mapped[int] = mapped_column(Integer, nullable=False)
    submitted_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)
    status: Mapped[str] = mapped_column(Text, nullable=False)
    is_late: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    content_text: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)


class SubmissionFile(Base):
    __tablename__ = 'submission_files'

    id: Mapped[int] = mapped_column(primary_key=True)
    submission_id: Mapped[int] = mapped_column(ForeignKey('submissions.id', ondelete='CASCADE', onupdate='CASCADE'))
    file_name: Mapped[str] = mapped_column(Text, nullable=False)
    file_path: Mapped[str] = mapped_column(Text, nullable=False)
    file_size: Mapped[int] = mapped_column(Integer, nullable=False)
    mime_type: Mapped[str] = mapped_column(Text, nullable=False)
    checksum: Mapped[str] = mapped_column(Text, nullable=False)
    uploaded_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)


class Grade(Base):
    __tablename__ = 'grades'
    __table_args__ = (CheckConstraint('score >= 0', name='grades_score_positive'),)

    id: Mapped[int] = mapped_column(primary_key=True)
    submission_id: Mapped[int] = mapped_column(ForeignKey('submissions.id', ondelete='CASCADE', onupdate='CASCADE'), unique=True)
    reviewer_id: Mapped[int] = mapped_column(ForeignKey('users.id', ondelete='RESTRICT', onupdate='CASCADE'))
    score: Mapped[float] = mapped_column(Numeric(6, 2), nullable=False)
    feedback: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(Text, nullable=False)
    graded_at: Mapped[datetime | None] = mapped_column(default=None)
    created_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)


class Notification(Base):
    __tablename__ = 'notifications'

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey('users.id', ondelete='CASCADE', onupdate='CASCADE'))
    type: Mapped[str] = mapped_column(Text, nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    meta: Mapped[dict] = mapped_column('metadata', JSONB, nullable=False, default=dict)
    is_read: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)
    sent_at: Mapped[datetime | None] = mapped_column(default=None)


class ImportErrorLog(Base):
    __tablename__ = 'import_error_log'

    id: Mapped[int] = mapped_column(primary_key=True)
    source: Mapped[str] = mapped_column(Text, nullable=False)
    row_number: Mapped[int] = mapped_column(Integer, nullable=False)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)
    error_message: Mapped[str] = mapped_column(Text, nullable=False)
    request_id: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(nullable=False, default=datetime.utcnow)
