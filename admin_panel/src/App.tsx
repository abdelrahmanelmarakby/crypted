import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { AuthProvider } from '@/contexts/AuthContext';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Layout from '@/components/layout/Layout';
import theme from '@/theme';

// Pages
import Login from '@/pages/Login';
import Dashboard from '@/pages/Dashboard';
import Users from '@/pages/Users';
import UserDetail from '@/pages/UserDetail';
import Chats from '@/pages/Chats';
import Stories from '@/pages/Stories';
import Reports from '@/pages/Reports';
import Analytics from '@/pages/Analytics';
import AdvancedAnalytics from '@/pages/AdvancedAnalytics';
import Settings from '@/pages/Settings';
import Logs from '@/pages/Logs';
import Calls from '@/pages/Calls';
import Notifications from '@/pages/Notifications';
import AdminManagement from '@/pages/AdminManagement';
import Profile from '@/pages/Profile';
import HelpMessages from '@/pages/HelpMessages';
import Backups from '@/pages/Backups';

function App() {
  return (
    <ChakraProvider theme={theme}>
      <AuthProvider>
        <Router>
          <Routes>
            {/* Public Routes */}
            <Route path="/login" element={<Login />} />

            {/* Protected Routes */}
            <Route
              path="/"
              element={
                <ProtectedRoute>
                  <Layout />
                </ProtectedRoute>
              }
            >
              <Route index element={<Dashboard />} />
              <Route path="users" element={<Users />} />
              <Route path="users/:userId" element={<UserDetail />} />
              <Route path="chats" element={<Chats />} />
              <Route path="stories" element={<Stories />} />
              <Route path="reports" element={<Reports />} />
              <Route path="calls" element={<Calls />} />
              <Route path="help-messages" element={<HelpMessages />} />
              <Route path="backups" element={<Backups />} />
              <Route path="analytics" element={<AdvancedAnalytics />} />
              <Route path="analytics-old" element={<Analytics />} />
              <Route path="notifications" element={<Notifications />} />
              <Route path="settings" element={<Settings />} />
              <Route path="logs" element={<Logs />} />
              <Route path="admin-management" element={<AdminManagement />} />
              <Route path="profile" element={<Profile />} />
            </Route>

            {/* Catch all */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </Router>
      </AuthProvider>
    </ChakraProvider>
  );
}

export default App;
