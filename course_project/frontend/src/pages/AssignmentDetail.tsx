import { FormEvent, useState } from 'react'
import { useParams } from 'react-router-dom'
import { apiRequest } from '../api'

export default function AssignmentDetail() {
  const { id } = useParams()
  const [studentId, setStudentId] = useState('')
  const [content, setContent] = useState('')
  const [message, setMessage] = useState('')

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault()
    try {
      await apiRequest('/submissions', {
        method: 'POST',
        body: JSON.stringify({
          assignment_id: Number(id),
          student_id: Number(studentId),
          attempt_no: 1,
          submitted_at: new Date().toISOString(),
          status: 'submitted',
          is_late: false,
          content_text: content
        })
      })
      setMessage('Решение отправлено')
    } catch (error) {
      setMessage(`Ошибка: ${String(error)}`)
    }
  }

  return (
    <div>
      <h2>Задание #{id}</h2>
      <p>Здесь отображаются критерии и дедлайн задания.</p>
      <form onSubmit={onSubmit} style={{ display: 'grid', gap: '12px', maxWidth: '420px' }}>
        <input placeholder="ID студента" value={studentId} onChange={(e) => setStudentId(e.target.value)} />
        <textarea placeholder="Текст решения" value={content} onChange={(e) => setContent(e.target.value)} />
        <button type="submit">Загрузить решение</button>
      </form>
      {message && <p>{message}</p>}
    </div>
  )
}
