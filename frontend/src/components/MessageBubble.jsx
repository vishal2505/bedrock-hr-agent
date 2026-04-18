import { useState } from 'react'
import { Bot, ChevronDown, ChevronUp, FileText, User } from 'lucide-react'

export default function MessageBubble({ message }) {
  const [showSources, setShowSources] = useState(false)
  const isUser = message.role === 'user'

  return (
    <div className={`flex gap-3 ${isUser ? 'flex-row-reverse' : ''}`}>
      {/* Avatar */}
      <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${
        isUser
          ? 'bg-electric-500'
          : 'bg-navy-800 dark:bg-navy-800 border border-gray-700'
      }`}>
        {isUser ? <User size={16} /> : <Bot size={16} />}
      </div>

      {/* Bubble */}
      <div className={`max-w-[75%] ${isUser ? 'items-end' : 'items-start'}`}>
        <div className={`rounded-2xl px-4 py-2.5 ${
          isUser
            ? 'bg-electric-500 text-white rounded-br-md'
            : 'bg-gray-100 dark:bg-navy-800 text-gray-900 dark:text-gray-100 rounded-bl-md'
        }`}>
          <p className="whitespace-pre-wrap text-sm leading-relaxed">{message.content}</p>
        </div>

        {/* Sources */}
        {!isUser && message.sources && message.sources.length > 0 && (
          <div className="mt-1.5">
            <button
              onClick={() => setShowSources(!showSources)}
              className="flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400 hover:text-electric-400 transition-colors"
            >
              <FileText size={12} />
              {message.sources.length} source{message.sources.length > 1 ? 's' : ''}
              {showSources ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
            </button>
            {showSources && (
              <div className="mt-1 p-2 bg-gray-50 dark:bg-navy-950 rounded-lg border border-gray-200 dark:border-gray-700">
                {message.sources.map((source, i) => (
                  <div key={i} className="flex items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400 py-0.5">
                    <FileText size={10} />
                    <span className="truncate">{source.split('/').pop()}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
