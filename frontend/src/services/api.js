import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// --- Chat ---
export async function sendMessage(message, sessionId, onChunk, onDone) {
  const response = await fetch(`${API_BASE_URL}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, session_id: sessionId }),
  })

  if (!response.ok) {
    throw new Error(`Chat request failed: ${response.statusText}`)
  }

  const reader = response.body.getReader()
  const decoder = new TextDecoder()
  let newSessionId = sessionId

  while (true) {
    const { done, value } = await reader.read()
    if (done) break

    const text = decoder.decode(value, { stream: true })
    const lines = text.split('\n')

    for (const line of lines) {
      if (!line.startsWith('data: ')) continue

      try {
        const data = JSON.parse(line.slice(6))

        if (data.type === 'session') {
          newSessionId = data.session_id
        } else if (data.type === 'chunk') {
          onChunk(data.content)
        } else if (data.type === 'done') {
          onDone(data.sources || [], newSessionId)
        }
      } catch {
        // Skip malformed JSON lines
      }
    }
  }

  return newSessionId
}

export async function getChatHistory(sessionId) {
  const response = await api.get(`/api/chat/${sessionId}`)
  return response.data
}

// --- Tasks ---
export async function getTasks() {
  const response = await api.get('/api/tasks')
  return response.data
}

export async function createTask(task) {
  const response = await api.post('/api/tasks', task)
  return response.data
}

export async function updateTask(taskId, updates) {
  const response = await api.patch(`/api/tasks/${taskId}`, updates)
  return response.data
}

export default api
