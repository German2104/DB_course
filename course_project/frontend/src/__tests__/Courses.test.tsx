import { render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, it, vi } from 'vitest'
import Courses from '../pages/Courses'

const mockFetch = (data: unknown) =>
  vi.fn().mockResolvedValue({
    ok: true,
    json: async () => data
  })

describe('Courses', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', mockFetch([]))
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('renders course list heading', async () => {
    render(<Courses />)

    await waitFor(() => {
      expect(screen.getByText('Курсы')).toBeInTheDocument()
    })
  })
})
