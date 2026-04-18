import { useState } from 'react'
import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom'
import { MessageSquare, ClipboardList, Sun, Moon } from 'lucide-react'
import Home from './pages/Home'
import Tasks from './pages/Tasks'

export default function App() {
  const [darkMode, setDarkMode] = useState(true)

  const toggleDarkMode = () => {
    setDarkMode(!darkMode)
    document.documentElement.classList.toggle('dark')
  }

  return (
    <div className={darkMode ? 'dark' : ''}>
      <BrowserRouter>
        <div className="min-h-screen bg-white dark:bg-navy-950 text-gray-900 dark:text-white transition-colors">
          {/* Top Nav */}
          <nav className="h-16 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between px-4 bg-white dark:bg-navy-900">
            <div className="flex items-center gap-6">
              <h1 className="text-lg font-bold text-electric-500">HR Agent</h1>
              <div className="flex gap-1">
                <NavLink
                  to="/"
                  className={({ isActive }) =>
                    `flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                      isActive
                        ? 'bg-electric-500/10 text-electric-500'
                        : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'
                    }`
                  }
                >
                  <MessageSquare size={16} />
                  Chat
                </NavLink>
                <NavLink
                  to="/tasks"
                  className={({ isActive }) =>
                    `flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                      isActive
                        ? 'bg-electric-500/10 text-electric-500'
                        : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'
                    }`
                  }
                >
                  <ClipboardList size={16} />
                  Tasks
                </NavLink>
              </div>
            </div>
            <button
              onClick={toggleDarkMode}
              className="p-2 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-navy-800 transition-colors"
            >
              {darkMode ? <Sun size={18} /> : <Moon size={18} />}
            </button>
          </nav>

          {/* Routes */}
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/tasks" element={<Tasks />} />
          </Routes>
        </div>
      </BrowserRouter>
    </div>
  )
}
