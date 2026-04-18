import { useState, useEffect } from 'react'
import { RefreshCw } from 'lucide-react'
import TaskPanel from '../components/TaskPanel'
import { getTasks } from '../services/api'

export default function Tasks() {
  const [tasks, setTasks] = useState([])
  const [loading, setLoading] = useState(true)

  const fetchTasks = async () => {
    setLoading(true)
    try {
      const data = await getTasks()
      setTasks(data)
    } catch (error) {
      console.error('Failed to fetch tasks:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchTasks()
  }, [])

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Onboarding Tasks</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Track and manage new employee onboarding tasks</p>
        </div>
        <button
          onClick={fetchTasks}
          disabled={loading}
          className="flex items-center gap-2 px-3 py-2 rounded-lg bg-gray-100 dark:bg-navy-800 hover:bg-gray-200 dark:hover:bg-navy-800/80 text-sm text-gray-600 dark:text-gray-300 transition-colors disabled:opacity-50"
        >
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          Refresh
        </button>
      </div>

      <div className="bg-white dark:bg-navy-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        {loading ? (
          <div className="p-4 space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="animate-pulse flex items-center gap-4 px-4 py-3">
                <div className="flex-1 space-y-2">
                  <div className="h-4 bg-gray-200 dark:bg-navy-800 rounded w-1/3" />
                  <div className="h-3 bg-gray-200 dark:bg-navy-800 rounded w-2/3" />
                </div>
                <div className="h-6 bg-gray-200 dark:bg-navy-800 rounded w-20" />
              </div>
            ))}
          </div>
        ) : (
          <TaskPanel tasks={tasks} onTaskUpdated={fetchTasks} />
        )}
      </div>
    </div>
  )
}
