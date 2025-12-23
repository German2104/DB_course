import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { apiRequest } from '../api'

interface Assignment {
  id: number
  title: string
  due_at: string
  max_score: number
}

export default function CourseDetail() {
  const { id } = useParams()
  const [assignments, setAssignments] = useState<Assignment[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    if (!id) return
    apiRequest<Assignment[]>(`/courses/${id}/assignments`)
      .then(setAssignments)
      .catch((err) => setError(String(err)))
  }, [id])

  return (
    <div>
      <h2>Курс #{id}</h2>
      {error && <p>{error}</p>}
      <table>
        <thead>
          <tr>
            <th>Задание</th>
            <th>Дедлайн</th>
            <th>Баллы</th>
          </tr>
        </thead>
        <tbody>
          {assignments.map((assignment) => (
            <tr key={assignment.id}>
              <td><Link to={`/assignments/${assignment.id}`}>{assignment.title}</Link></td>
              <td>{new Date(assignment.due_at).toLocaleString()}</td>
              <td>{assignment.max_score}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
