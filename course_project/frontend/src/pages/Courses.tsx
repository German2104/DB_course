import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { apiRequest } from '../api'

interface Course {
  id: number
  title: string
  code: string
  description: string
}

export default function Courses() {
  const [courses, setCourses] = useState<Course[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    apiRequest<Course[]>('/courses')
      .then(setCourses)
      .catch((err) => setError(String(err)))
  }, [])

  return (
    <div>
      <h2>Курсы</h2>
      {error && <p>{error}</p>}
      <ul>
        {courses.map((course) => (
          <li key={course.id}>
            <Link to={`/courses/${course.id}`}>{course.title}</Link> ({course.code})
          </li>
        ))}
      </ul>
    </div>
  )
}
