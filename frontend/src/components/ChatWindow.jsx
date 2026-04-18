import { useState, useRef, useEffect } from 'react'
import { Send, Plus, MessageSquare, Bot } from 'lucide-react'
import MessageBubble from './MessageBubble'

export default function ChatWindow({ messages, isLoading, sessions, onSend, onNewSession }) {
  const [input, setInput] = useState('')
  const messagesEndRef = useRef(null)
  const inputRef = useRef(null)

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSend = () => {
    if (!input.trim() || isLoading) return
    onSend(input)
    setInput('')
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  return (
    <div className="flex h-[calc(100vh-4rem)]">
      {/* Sidebar */}
      <div className="hidden md:flex flex-col w-64 border-r border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-navy-950">
        <div className="p-3">
          <button
            onClick={onNewSession}
            className="w-full flex items-center gap-2 px-3 py-2 rounded-lg bg-electric-500 hover:bg-electric-600 text-white text-sm font-medium transition-colors"
          >
            <Plus size={16} />
            New Chat
          </button>
        </div>
        <div className="flex-1 overflow-y-auto px-2">
          {sessions.map((session) => (
            <div
              key={session.id}
              className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-navy-800 cursor-pointer transition-colors mb-0.5"
            >
              <MessageSquare size={14} />
              <span className="truncate">{session.preview || 'New conversation'}</span>
            </div>
          ))}
          {sessions.length === 0 && (
            <p className="text-xs text-gray-400 dark:text-gray-600 text-center mt-8">No conversations yet</p>
          )}
        </div>
      </div>

      {/* Main chat area */}
      <div className="flex-1 flex flex-col">
        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-4 py-6">
          {messages.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-center">
              <div className="w-16 h-16 rounded-2xl bg-electric-500/10 flex items-center justify-center mb-4">
                <Bot size={32} className="text-electric-500" />
              </div>
              <h2 className="text-xl font-semibold text-gray-800 dark:text-white mb-2">HR Onboarding Assistant</h2>
              <p className="text-gray-500 dark:text-gray-400 max-w-md text-sm">
                Ask me about company policies, request a welcome email for new hires, or create onboarding tasks. I'm here to help!
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-6 max-w-lg">
                {[
                  'What is the leave policy?',
                  'How do I set up VPN access?',
                  'Send a welcome email to a new hire',
                  'Create an onboarding task',
                ].map((suggestion) => (
                  <button
                    key={suggestion}
                    onClick={() => { setInput(suggestion); inputRef.current?.focus() }}
                    className="text-left text-sm px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-electric-500 dark:hover:border-electric-500 hover:bg-electric-500/5 text-gray-600 dark:text-gray-400 transition-all"
                  >
                    {suggestion}
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <div className="max-w-3xl mx-auto space-y-4">
              {messages.map((msg) => (
                <MessageBubble key={msg.id} message={msg} />
              ))}
              {isLoading && messages[messages.length - 1]?.content === '' && (
                <div className="flex gap-3">
                  <div className="w-8 h-8 rounded-full bg-navy-800 border border-gray-700 flex items-center justify-center">
                    <Bot size={16} />
                  </div>
                  <div className="bg-gray-100 dark:bg-navy-800 rounded-2xl rounded-bl-md px-4 py-3">
                    <div className="flex gap-1">
                      <span className="typing-dot w-2 h-2 bg-gray-400 rounded-full" />
                      <span className="typing-dot w-2 h-2 bg-gray-400 rounded-full" />
                      <span className="typing-dot w-2 h-2 bg-gray-400 rounded-full" />
                    </div>
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>
          )}
        </div>

        {/* Input */}
        <div className="border-t border-gray-200 dark:border-gray-800 px-4 py-3">
          <div className="max-w-3xl mx-auto flex gap-2">
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Ask about company policies, onboarding tasks..."
              disabled={isLoading}
              className="flex-1 bg-gray-100 dark:bg-navy-800 border border-gray-200 dark:border-gray-700 rounded-xl px-4 py-2.5 text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-electric-500 focus:border-transparent disabled:opacity-50 transition-all"
            />
            <button
              onClick={handleSend}
              disabled={!input.trim() || isLoading}
              className="bg-electric-500 hover:bg-electric-600 disabled:bg-gray-300 dark:disabled:bg-gray-700 text-white rounded-xl px-4 py-2.5 transition-colors disabled:cursor-not-allowed"
            >
              <Send size={18} />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
