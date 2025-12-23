import { FormEvent, useState } from 'react'
import { apiRequest, setToken } from '../api'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [message, setMessage] = useState('')

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault()
    try {
      const body = new URLSearchParams({ username: email, password })
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body
      })
      if (!response.ok) {
        throw new Error(await response.text())
      }
      const data = await response.json()
      setToken(data.access_token)
      setMessage('Успешный вход')
    } catch (error) {
      setMessage(`Ошибка: ${String(error)}`)
    }
  }

  return (
    <div>
      <h2>Вход</h2>
      <form onSubmit={onSubmit} style={{ display: 'grid', gap: '12px', maxWidth: '320px' }}>
        <input placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input type="password" placeholder="Пароль" value={password} onChange={(e) => setPassword(e.target.value)} />
        <button type="submit">Войти</button>
      </form>
      {message && <p>{message}</p>}
    </div>
  )
}
