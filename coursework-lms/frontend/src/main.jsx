import React, { useState } from 'react';
import { createRoot } from 'react-dom/client';
import { apiRequest } from './api/client';

function App() {
  const [token, setToken] = useState('');
  const [role, setRole] = useState('');
  const [courses, setCourses] = useState([]);
  const [message, setMessage] = useState('');

  async function login(email, password) {
    try {
      const data = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      setToken(data.access_token);
      setRole(email.includes('teacher') ? 'teacher' : email.includes('admin') ? 'admin' : 'student');
      setMessage('Успешный вход');
    } catch (error) {
      setMessage(error.message);
    }
  }

  async function loadCourses() {
    try {
      const data = await apiRequest('/courses', {
        headers: { Authorization: `Bearer ${token}` },
      });
      setCourses(data);
    } catch (error) {
      setMessage(error.message);
    }
  }

  return (
    <main style={{ fontFamily: 'Arial, sans-serif', maxWidth: 800, margin: '24px auto' }}>
      <h1>LMS</h1>
      <section>
        <h2>Login</h2>
        <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
          <button onClick={() => login('student1@lms.local', 'student123')}>Login as Student</button>
          <button onClick={() => login('teacher1@lms.local', 'teacher123')}>Login as Teacher</button>
          <button onClick={() => login('admin@lms.local', 'admin123')}>Login as Admin</button>
        </div>
        <p>{message}</p>
      </section>

      <section>
        <h2>Курсы</h2>
        <button disabled={!token} onClick={loadCourses}>Загрузить курсы</button>
        <ul>
          {courses.map((course) => (
            <li key={course.id}>{course.title} (teacher_id: {course.teacher_id})</li>
          ))}
        </ul>
      </section>

      <section>
        <h2>Роль</h2>
        <p>{role || 'Не определена'}</p>
      </section>

      <section>
        <h2>Задания и оценки</h2>
        <p>Демо-интерфейс: для полного сценария используйте Swagger backend.</p>
      </section>
    </main>
  );
}

createRoot(document.getElementById('root')).render(<App />);
