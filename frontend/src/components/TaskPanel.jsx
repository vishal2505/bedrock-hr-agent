import { useState } from 'react'
import { ClipboardList, X } from 'lucide-react'
import StatusBadge from './StatusBadge'
import { updateTask } from '../services/api'

export default function TaskPanel({ tasks, onTaskUpdated }) {
  const [editingTask, setEditingTask] = useState(null)
  const [updating, setUpdating] = useState(false)

  const handleStatusChange = async (taskId, newStatus) => {
    setUpdating(true)
    try {
      await updateTask(taskId, { status: newStatus })
      onTaskUpdated()
      setEditingTask(null)
    } catch (error) {
      console.error('Failed to update task:', error)
    } finally {
      setUpdating(false)
    }
  }

  if (tasks.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-center">
        <div className="w-20 h-20 rounded-2xl bg-electric-500/10 flex items-center justify-center mb-4">
          <ClipboardList size={40} className="text-electric-500" />
        </div>
        <h3 className="text-lg font-semibold text-gray-800 dark:text-white mb-2">No tasks yet</h3>
        <p className="text-gray-500 dark:text-gray-400 text-sm max-w-sm">
          Onboarding tasks will appear here when created through the chat or manually added.
        </p>
      </div>
    )
  }

  return (
    <>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-800">
              <th className="text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider px-4 py-3">Title</th>
              <th className="text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider px-4 py-3">Assigned To</th>
              <th className="text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider px-4 py-3">Due Date</th>
              <th className="text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider px-4 py-3">Status</th>
            </tr>
          </thead>
          <tbody>
            {tasks.map((task) => (
              <tr
                key={task.task_id}
                onClick={() => setEditingTask(task)}
                className="border-b border-gray-100 dark:border-gray-800/50 hover:bg-gray-50 dark:hover:bg-navy-800/50 cursor-pointer transition-colors"
              >
                <td className="px-4 py-3">
                  <div>
                    <p className="text-sm font-medium text-gray-900 dark:text-white">{task.title}</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 truncate max-w-xs">{task.description}</p>
                  </div>
                </td>
                <td className="px-4 py-3 text-sm text-gray-600 dark:text-gray-300">{task.assigned_to}</td>
                <td className="px-4 py-3 text-sm text-gray-600 dark:text-gray-300">{task.due_date || '—'}</td>
                <td className="px-4 py-3"><StatusBadge status={task.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Edit Modal */}
      {editingTask && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-navy-900 rounded-xl shadow-xl max-w-md w-full p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Update Task</h3>
              <button onClick={() => setEditingTask(null)} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
                <X size={20} />
              </button>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-1 font-medium">{editingTask.title}</p>
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">{editingTask.description}</p>
            <div className="flex flex-col gap-2">
              <p className="text-xs text-gray-500 dark:text-gray-400 uppercase font-medium">Change status:</p>
              {['pending', 'in-progress', 'completed'].map((status) => (
                <button
                  key={status}
                  onClick={() => handleStatusChange(editingTask.task_id, status)}
                  disabled={updating || editingTask.status === status}
                  className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors ${
                    editingTask.status === status
                      ? 'bg-electric-500/10 text-electric-500 font-medium'
                      : 'hover:bg-gray-100 dark:hover:bg-navy-800 text-gray-700 dark:text-gray-300'
                  } disabled:opacity-50`}
                >
                  <StatusBadge status={status} />
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </>
  )
}
