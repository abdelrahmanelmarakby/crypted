import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline, Box, Toolbar } from '@mui/material';
import { theme } from './theme';
import ProtectedRoute from './components/auth/ProtectedRoute';
import Header from './components/common/Header';
import Sidebar from './components/common/Sidebar';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import { useAuth } from './hooks/useAuth';

// Placeholder pages (to be implemented)
const Chats = () => <div>Chats Page - Coming Soon</div>;
const Stories = () => <div>Stories Page - Coming Soon</div>;
const Reports = () => <div>Reports Page - Coming Soon</div>;
const Calls = () => <div>Calls Page - Coming Soon</div>;
const Analytics = () => <div>Analytics Page - Coming Soon</div>;
const Notifications = () => <div>Notifications Page - Coming Soon</div>;
const Settings = () => <div>Settings Page - Coming Soon</div>;

const drawerWidth = 240;

const App: React.FC = () => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const { isAuthenticated } = useAuth();

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <BrowserRouter>
        <Routes>
          <Route
            path="/login"
            element={
              isAuthenticated ? <Navigate to="/" replace /> : <Login />
            }
          />
          <Route
            path="/*"
            element={
              <ProtectedRoute>
                <Box sx={{ display: 'flex' }}>
                  <Header onMenuClick={handleDrawerToggle} />
                  <Sidebar
                    mobileOpen={mobileOpen}
                    onClose={handleDrawerToggle}
                  />
                  <Box
                    component="main"
                    sx={{
                      flexGrow: 1,
                      p: 3,
                      width: { sm: `calc(100% - ${drawerWidth}px)` },
                    }}
                  >
                    <Toolbar />
                    <Routes>
                      <Route path="/" element={<Dashboard />} />
                      <Route path="/users" element={<Users />} />
                      <Route path="/chats" element={<Chats />} />
                      <Route path="/stories" element={<Stories />} />
                      <Route path="/reports" element={<Reports />} />
                      <Route path="/calls" element={<Calls />} />
                      <Route path="/analytics" element={<Analytics />} />
                      <Route path="/notifications" element={<Notifications />} />
                      <Route path="/settings" element={<Settings />} />
                    </Routes>
                  </Box>
                </Box>
              </ProtectedRoute>
            }
          />
        </Routes>
      </BrowserRouter>
    </ThemeProvider>
  );
};

export default App;
