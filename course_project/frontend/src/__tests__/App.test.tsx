import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import App from '../App'

test('renders navigation links', () => {
  render(
    <MemoryRouter>
      <App />
    </MemoryRouter>
  )

  expect(screen.getByText('Курсы')).toBeInTheDocument()
  expect(screen.getByText('Рейтинг')).toBeInTheDocument()
  expect(screen.getByText('Проверка')).toBeInTheDocument()
  expect(screen.getByText('Войти')).toBeInTheDocument()
})
