import { Link, Route, Routes } from 'react-router-dom'
import Login from './pages/Login'
import Courses from './pages/Courses'
import CourseDetail from './pages/CourseDetail'
import AssignmentDetail from './pages/AssignmentDetail'
import InstructorReview from './pages/InstructorReview'
import Leaderboard from './pages/Leaderboard'

export default function App() {
  return (
    <div style={{ fontFamily: 'Arial, sans-serif', padding: '20px' }}>
      <header style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
        <Link to="/">Курсы</Link>
        <Link to="/leaderboard">Рейтинг</Link>
        <Link to="/instructor-review">Проверка</Link>
        <Link to="/login">Войти</Link>
      </header>
      <Routes>
        <Route path="/" element={<Courses />} />
        <Route path="/login" element={<Login />} />
        <Route path="/courses/:id" element={<CourseDetail />} />
        <Route path="/assignments/:id" element={<AssignmentDetail />} />
        <Route path="/instructor-review" element={<InstructorReview />} />
        <Route path="/leaderboard" element={<Leaderboard />} />
      </Routes>
    </div>
  )
}
