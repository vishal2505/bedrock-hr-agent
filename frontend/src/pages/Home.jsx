import ChatWindow from '../components/ChatWindow'
import { useAgent } from '../hooks/useAgent'

export default function Home() {
  const { messages, isLoading, sessions, send, newSession } = useAgent()

  return (
    <ChatWindow
      messages={messages}
      isLoading={isLoading}
      sessions={sessions}
      onSend={send}
      onNewSession={newSession}
    />
  )
}
