import { useState, useCallback, useRef } from 'react'
import { sendMessage } from '../services/api'

export function useAgent() {
  const [messages, setMessages] = useState([])
  const [isLoading, setIsLoading] = useState(false)
  const [sessionId, setSessionId] = useState(null)
  const [sessions, setSessions] = useState([])
  const abortRef = useRef(false)

  const send = useCallback(async (text) => {
    if (!text.trim() || isLoading) return

    const userMessage = {
      id: Date.now(),
      role: 'user',
      content: text,
      timestamp: new Date().toISOString(),
    }

    setMessages(prev => [...prev, userMessage])
    setIsLoading(true)

    const assistantMessage = {
      id: Date.now() + 1,
      role: 'assistant',
      content: '',
      timestamp: new Date().toISOString(),
      sources: [],
    }

    setMessages(prev => [...prev, assistantMessage])

    try {
      const newSessionId = await sendMessage(
        text,
        sessionId,
        // onChunk
        (chunk) => {
          setMessages(prev => {
            const updated = [...prev]
            const last = updated[updated.length - 1]
            updated[updated.length - 1] = { ...last, content: last.content + chunk }
            return updated
          })
        },
        // onDone
        (sources, sid) => {
          setMessages(prev => {
            const updated = [...prev]
            const last = updated[updated.length - 1]
            updated[updated.length - 1] = { ...last, sources }
            return updated
          })
          setSessionId(sid)

          // Track session in sidebar
          setSessions(prev => {
            const exists = prev.find(s => s.id === sid)
            if (!exists) {
              return [{ id: sid, preview: text.slice(0, 40), timestamp: new Date().toISOString() }, ...prev]
            }
            return prev
          })
        }
      )
    } catch (error) {
      setMessages(prev => {
        const updated = [...prev]
        updated[updated.length - 1] = {
          ...updated[updated.length - 1],
          content: 'Sorry, something went wrong. Please try again.',
        }
        return updated
      })
    } finally {
      setIsLoading(false)
    }
  }, [isLoading, sessionId])

  const newSession = useCallback(() => {
    setMessages([])
    setSessionId(null)
  }, [])

  return { messages, isLoading, sessionId, sessions, send, newSession }
}
