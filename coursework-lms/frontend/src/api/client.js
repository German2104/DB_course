const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8000';

export async function apiRequest(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });

  if (!response.ok) {
    const errorPayload = await response.json().catch(() => ({ detail: 'Unknown API error' }));
    throw new Error(errorPayload.detail || 'Request failed');
  }

  return response.json();
}
