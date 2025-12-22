import { useState } from 'react'
import { apiRequest } from '../api'

interface Row {
  student_id: number
  student_name: string
  total_score: number
  max_score: number
  progress_pct: number
}

export default function Leaderboard() {
  const [courseId, setCourseId] = useState('1')
  const [rows, setRows] = useState<Row[]>([])
  const [error, setError] = useState('')

  const load = async () => {
    try {
      const data = await apiRequest<Row[]>(`/reports/leaderboard/${courseId}`)
      setRows(data)
      setError('')
    } catch (err) {
      setError(String(err))
    }
  }

  return (
    <div>
      <h2>Рейтинг</h2>
      <div style={{ display: 'flex', gap: '12px', marginBottom: '12px' }}>
        <input value={courseId} onChange={(e) => setCourseId(e.target.value)} />
        <button onClick={load}>Показать</button>
      </div>
      {error && <p>{error}</p>}
      <table>
        <thead>
          <tr>
            <th>Студент</th>
            <th>Баллы</th>
            <th>Прогресс</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.student_id}>
              <td>{row.student_name}</td>
              <td>{row.total_score} / {row.max_score}</td>
              <td>{row.progress_pct}%</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
