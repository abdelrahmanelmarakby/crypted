import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  Grid,
  Divider,
  Switch,
  FormControlLabel,
  Avatar,
  IconButton,
} from '@mui/material';
import {
  Save,
  Edit,
  Lock,
  Notifications,
  Security,
  Palette,
} from '@mui/icons-material';
import { useAuth } from '../hooks/useAuth';
import { COLORS } from '../utils/constants';

const Settings: React.FC = () => {
  const { user } = useAuth();
  const [displayName, setDisplayName] = useState(user?.displayName || '');
  const [email, setEmail] = useState(user?.email || '');
  const [notifications, setNotifications] = useState(true);
  const [twoFactor, setTwoFactor] = useState(false);
  const [saved, setSaved] = useState(false);

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h3" sx={{ fontWeight: 700, color: COLORS.text, fontSize: '2.25rem', mb: 1 }}>
          Settings
        </Typography>
        <Typography variant="body1" sx={{ color: COLORS.grey[600] }}>
          Manage your account settings and preferences
        </Typography>
      </Box>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, lg: 8 }}>
          {/* Profile Settings */}
          <Paper sx={{ p: 4, mb: 3 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
              <Edit sx={{ color: COLORS.primary }} />
              <Typography variant="h6" sx={{ fontWeight: 600 }}>
                Profile Information
              </Typography>
            </Box>

            <Box sx={{ display: 'flex', alignItems: 'center', gap: 3, mb: 4 }}>
              <Avatar
                sx={{
                  width: 80,
                  height: 80,
                  bgcolor: COLORS.primary,
                  fontSize: '2rem',
                  fontWeight: 600,
                }}
              >
                {user?.displayName?.charAt(0).toUpperCase() || 'A'}
              </Avatar>
              <Box>
                <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5 }}>
                  {user?.displayName || 'Admin'}
                </Typography>
                <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
                  {user?.role?.replace('_', ' ').toUpperCase()}
                </Typography>
                <Button size="small" variant="outlined" sx={{ textTransform: 'none' }}>
                  Change Avatar
                </Button>
              </Box>
            </Box>

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <TextField
                fullWidth
                label="Display Name"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                variant="outlined"
              />
              <TextField
                fullWidth
                label="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                variant="outlined"
                type="email"
              />
              <Button
                variant="contained"
                startIcon={<Save />}
                onClick={handleSave}
                sx={{
                  alignSelf: 'flex-start',
                  backgroundColor: COLORS.primary,
                  '&:hover': { backgroundColor: COLORS.green[700] },
                }}
              >
                {saved ? 'Saved!' : 'Save Changes'}
              </Button>
            </Box>
          </Paper>

          {/* Security Settings */}
          <Paper sx={{ p: 4, mb: 3 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
              <Security sx={{ color: COLORS.primary }} />
              <Typography variant="h6" sx={{ fontWeight: 600 }}>
                Security
              </Typography>
            </Box>

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <Box>
                <Typography variant="body1" sx={{ fontWeight: 600, mb: 1 }}>
                  Change Password
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <TextField
                    fullWidth
                    label="Current Password"
                    type="password"
                    variant="outlined"
                  />
                  <TextField
                    fullWidth
                    label="New Password"
                    type="password"
                    variant="outlined"
                  />
                  <TextField
                    fullWidth
                    label="Confirm New Password"
                    type="password"
                    variant="outlined"
                  />
                  <Button
                    variant="outlined"
                    startIcon={<Lock />}
                    sx={{
                      alignSelf: 'flex-start',
                      borderColor: COLORS.grey[300],
                      color: COLORS.text,
                    }}
                  >
                    Update Password
                  </Button>
                </Box>
              </Box>

              <Divider />

              <FormControlLabel
                control={
                  <Switch
                    checked={twoFactor}
                    onChange={(e) => setTwoFactor(e.target.checked)}
                    sx={{
                      '& .MuiSwitch-switchBase.Mui-checked': {
                        color: COLORS.primary,
                      },
                      '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                        backgroundColor: COLORS.primary,
                      },
                    }}
                  />
                }
                label={
                  <Box>
                    <Typography variant="body1" sx={{ fontWeight: 600 }}>
                      Two-Factor Authentication
                    </Typography>
                    <Typography variant="caption" sx={{ color: COLORS.grey[600] }}>
                      Add an extra layer of security to your account
                    </Typography>
                  </Box>
                }
              />
            </Box>
          </Paper>

          {/* Notification Settings */}
          <Paper sx={{ p: 4 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
              <Notifications sx={{ color: COLORS.primary }} />
              <Typography variant="h6" sx={{ fontWeight: 600 }}>
                Notification Preferences
              </Typography>
            </Box>

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={notifications}
                    onChange={(e) => setNotifications(e.target.checked)}
                    sx={{
                      '& .MuiSwitch-switchBase.Mui-checked': {
                        color: COLORS.primary,
                      },
                      '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                        backgroundColor: COLORS.primary,
                      },
                    }}
                  />
                }
                label="Email Notifications"
              />
              <FormControlLabel
                control={<Switch />}
                label="New User Alerts"
              />
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Report Notifications"
              />
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="System Updates"
              />
            </Box>
          </Paper>
        </Grid>

        <Grid size={{ xs: 12, lg: 4 }}>
          <Paper sx={{ p: 4, mb: 3 }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
              Account Information
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <Box>
                <Typography variant="caption" sx={{ color: COLORS.grey[600], textTransform: 'uppercase' }}>
                  Role
                </Typography>
                <Typography variant="body1" sx={{ fontWeight: 600 }}>
                  {user?.role?.replace('_', ' ').toUpperCase()}
                </Typography>
              </Box>
              <Divider />
              <Box>
                <Typography variant="caption" sx={{ color: COLORS.grey[600], textTransform: 'uppercase' }}>
                  Email
                </Typography>
                <Typography variant="body1" sx={{ fontWeight: 500 }}>
                  {user?.email}
                </Typography>
              </Box>
              <Divider />
              <Box>
                <Typography variant="caption" sx={{ color: COLORS.grey[600], textTransform: 'uppercase' }}>
                  Last Login
                </Typography>
                <Typography variant="body1" sx={{ fontWeight: 500 }}>
                  {user?.lastLogin
                    ? new Date(user.lastLogin.toDate()).toLocaleString()
                    : 'N/A'}
                </Typography>
              </Box>
            </Box>
          </Paper>

          <Paper sx={{ p: 4 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
              <Palette sx={{ color: COLORS.primary }} />
              <Typography variant="h6" sx={{ fontWeight: 600 }}>
                Appearance
              </Typography>
            </Box>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 2 }}>
              Customize the admin panel appearance
            </Typography>
            <Box sx={{ display: 'flex', gap: 2 }}>
              <Box
                sx={{
                  width: 40,
                  height: 40,
                  borderRadius: 1,
                  backgroundColor: COLORS.white,
                  border: `2px solid ${COLORS.primary}`,
                  cursor: 'pointer',
                }}
              />
              <Box
                sx={{
                  width: 40,
                  height: 40,
                  borderRadius: 1,
                  backgroundColor: COLORS.grey[900],
                  border: `2px solid ${COLORS.grey[300]}`,
                  cursor: 'pointer',
                }}
              />
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Settings;
