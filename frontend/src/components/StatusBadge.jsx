const statusConfig = {
  pending: {
    bg: 'bg-yellow-500/20',
    text: 'text-yellow-400',
    dot: 'bg-yellow-400',
    label: 'Pending',
  },
  'in-progress': {
    bg: 'bg-blue-500/20',
    text: 'text-blue-400',
    dot: 'bg-blue-400',
    label: 'In Progress',
  },
  completed: {
    bg: 'bg-green-500/20',
    text: 'text-green-400',
    dot: 'bg-green-400',
    label: 'Completed',
  },
}

export default function StatusBadge({ status }) {
  const config = statusConfig[status] || statusConfig.pending

  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${config.bg} ${config.text}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${config.dot}`} />
      {config.label}
    </span>
  )
}
