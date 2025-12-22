import { FormEvent, useState } from 'react'
import { apiRequest } from '../api'

export default function InstructorReview() {
  const [submissionId, setSubmissionId] = useState('')
  const [reviewerId, setReviewerId] = useState('')
  const [score, setScore] = useState('')
  const [feedback, setFeedback] = useState('')
  const [message, setMessage] = useState('')

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault()
    try {
      await apiRequest('/grades', {
        method: 'POST',
        body: JSON.stringify({
          submission_id: Number(submissionId),
          reviewer_id: Number(reviewerId),
          score: Number(score),
          feedback,
          status: 'graded',
          graded_at: new Date().toISOString()
        })
      })
      setMessage('Оценка сохранена')
    } catch (error) {
      setMessage(`Ошибка: ${String(error)}`)
    }
  }

  return (
    <div>
      <h2>Проверка заданий</h2>
      <form onSubmit={onSubmit} style={{ display: 'grid', gap: '12px', maxWidth: '420px' }}>
        <input placeholder="ID сдачи" value={submissionId} onChange={(e) => setSubmissionId(e.target.value)} />
        <input placeholder="ID преподавателя" value={reviewerId} onChange={(e) => setReviewerId(e.target.value)} />
        <input placeholder="Баллы" value={score} onChange={(e) => setScore(e.target.value)} />
        <textarea placeholder="Комментарий" value={feedback} onChange={(e) => setFeedback(e.target.value)} />
        <button type="submit">Сохранить</button>
      </form>
      {message && <p>{message}</p>}
    </div>
  )
}
