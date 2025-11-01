import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
} from '@mui/material';
import {
  Send,
  People,
  PersonOutline,
  Notifications as NotificationsIcon,
  CheckCircle,
} from '@mui/icons-material';
import { COLORS } from '../utils/constants';

const Notifications: React.FC = () => {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [audience, setAudience] = useState('all');
  const [sent, setSent] = useState(false);

  const handleSend = () => {
    // Send notification logic
    setSent(true);
    setTimeout(() => {
      setSent(false);
      setTitle('');
      setMessage('');
      setAudience('all');
    }, 3000);
  };

  const recentNotifications = [
    { title: 'System Update', message: 'New features available', audience: 'All Users', date: '2025-10-29' },
    { title: 'Maintenance Notice', message: 'Scheduled maintenance at 2 AM', audience: 'All Users', date: '2025-10-28' },
    { title: 'New Feature', message: 'Try our new story filters', audience: 'Active Users', date: '2025-10-27' },
  ];

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h3" sx={{ fontWeight: 700, color: COLORS.text, fontSize: '2.25rem', mb: 1 }}>
          Push Notifications
        </Typography>
        <Typography variant="body1" sx={{ color: COLORS.grey[600] }}>
          Send notifications to users across the platform
        </Typography>
      </Box>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, lg: 7 }}>
          <Paper sx={{ p: 4 }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
              Create New Notification
            </Typography>

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <TextField
                fullWidth
                label="Notification Title"
                placeholder="Enter a catchy title..."
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                variant="outlined"
              />

              <TextField
                fullWidth
                multiline
                rows={4}
                label="Message"
                placeholder="Enter your notification message..."
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                variant="outlined"
              />

              <FormControl fullWidth>
                <InputLabel>Target Audience</InputLabel>
                <Select
                  value={audience}
                  onChange={(e) => setAudience(e.target.value)}
                  label="Target Audience"
                >
                  <MenuItem value="all">All Users</MenuItem>
                  <MenuItem value="active">Active Users (Last 7 Days)</MenuItem>
                  <MenuItem value="inactive">Inactive Users</MenuItem>
                  <MenuItem value="premium">Premium Users</MenuItem>
                </Select>
              </FormControl>

              <Box sx={{ display: 'flex', gap: 2 }}>
                <Button
                  variant="contained"
                  startIcon={<Send />}
                  onClick={handleSend}
                  disabled={!title || !message || sent}
                  fullWidth
                  sx={{
                    backgroundColor: COLORS.primary,
                    '&:hover': {
                      backgroundColor: COLORS.green[700],
                    },
                  }}
                >
                  {sent ? 'Sent!' : 'Send Notification'}
                </Button>
                <Button
                  variant="outlined"
                  onClick={() => { setTitle(''); setMessage(''); setAudience('all'); }}
                  sx={{
                    borderColor: COLORS.grey[300],
                    color: COLORS.text,
                  }}
                >
                  Clear
                </Button>
              </Box>

              {sent && (
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 1,
                    p: 2,
                    backgroundColor: COLORS.green[50],
                    borderRadius: 2,
                  }}
                >
                  <CheckCircle sx={{ color: COLORS.primary }} />
                  <Typography variant="body2" sx={{ color: COLORS.primary, fontWeight: 600 }}>
                    Notification sent successfully!
                  </Typography>
                </Box>
              )}
            </Box>
          </Paper>

          <Grid container spacing={3} sx={{ mt: 0 }}>
            <Grid size={{ xs: 12, sm: 4 }}>
              <Paper sx={{ p: 3, textAlign: 'center' }}>
                <NotificationsIcon sx={{ fontSize: 40, color: COLORS.primary, mb: 1 }} />
                <Typography variant="h5" sx={{ fontWeight: 700, color: COLORS.text }}>
                  1,234
                </Typography>
                <Typography variant="body2" sx={{ color: COLORS.grey[600] }}>
                  Total Sent
                </Typography>
              </Paper>
            </Grid>
            <Grid size={{ xs: 12, sm: 4 }}>
              <Paper sx={{ p: 3, textAlign: 'center' }}>
                <People sx={{ fontSize: 40, color: COLORS.grey[700], mb: 1 }} />
                <Typography variant="h5" sx={{ fontWeight: 700, color: COLORS.text }}>
                  892
                </Typography>
                <Typography variant="body2" sx={{ color: COLORS.grey[600] }}>
                  Delivered
                </Typography>
              </Paper>
            </Grid>
            <Grid size={{ xs: 12, sm: 4 }}>
              <Paper sx={{ p: 3, textAlign: 'center' }}>
                <PersonOutline sx={{ fontSize: 40, color: COLORS.grey[600], mb: 1 }} />
                <Typography variant="h5" sx={{ fontWeight: 700, color: COLORS.text }}>
                  72%
                </Typography>
                <Typography variant="body2" sx={{ color: COLORS.grey[600] }}>
                  Open Rate
                </Typography>
              </Paper>
            </Grid>
          </Grid>
        </Grid>

        <Grid size={{ xs: 12, lg: 5 }}>
          <Paper sx={{ p: 4 }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
              Recent Notifications
            </Typography>
            <List>
              {recentNotifications.map((notif, index) => (
                <React.Fragment key={index}>
                  <ListItem alignItems="flex-start" sx={{ px: 0 }}>
                    <ListItemIcon sx={{ minWidth: 40, mt: 1 }}>
                      <NotificationsIcon sx={{ color: COLORS.grey[600] }} />
                    </ListItemIcon>
                    <ListItemText
                      primary={
                        <Typography variant="body1" sx={{ fontWeight: 600, color: COLORS.text, mb: 0.5 }}>
                          {notif.title}
                        </Typography>
                      }
                      secondary={
                        <>
                          <Typography variant="body2" sx={{ color: COLORS.grey[700], mb: 1 }}>
                            {notif.message}
                          </Typography>
                          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                            <Chip
                              label={notif.audience}
                              size="small"
                              sx={{
                                backgroundColor: COLORS.green[50],
                                color: COLORS.primary,
                                fontWeight: 500,
                                fontSize: '0.75rem',
                              }}
                            />
                            <Typography variant="caption" sx={{ color: COLORS.grey[600] }}>
                              {notif.date}
                            </Typography>
                          </Box>
                        </>
                      }
                    />
                  </ListItem>
                  {index < recentNotifications.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Notifications;
