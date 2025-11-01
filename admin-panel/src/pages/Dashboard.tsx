import React from 'react';
import { Box, Grid, Typography, Paper, Chip, Divider } from '@mui/material';
import {
  People,
  Chat,
  PhotoLibrary,
  Phone,
  Flag,
  TrendingUp,
  CheckCircle,
  ArrowForward,
} from '@mui/icons-material';
import StatCard from '../components/common/StatCard';
import { useAuth } from '../hooks/useAuth';
import { COLORS } from '../utils/constants';

const Dashboard: React.FC = () => {
  const { user } = useAuth();

  // Mock data for demonstration
  const mockStats = {
    totalUsers: 1250,
    activeUsers24h: 450,
    totalMessages: 25600,
    activeStories: 87,
    totalCalls: 1420,
    pendingReports: 12,
    userGrowth: 15.3,
    activeGrowth: 8.2,
    messagesGrowth: 23.5,
    storiesGrowth: -4.1,
  };

  return (
    <Box>
      {/* Header Section */}
      <Box sx={{ mb: 5 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
          <Typography
            variant="h3"
            sx={{
              fontWeight: 700,
              color: COLORS.text,
              fontSize: '2.25rem',
            }}
          >
            Dashboard
          </Typography>
          <Chip
            icon={<CheckCircle sx={{ fontSize: 16 }} />}
            label="System Online"
            sx={{
              backgroundColor: COLORS.green[50],
              color: COLORS.primary,
              border: 'none',
              fontWeight: 600,
              fontSize: '0.8rem',
            }}
            size="small"
          />
        </Box>
        <Typography
          variant="body1"
          sx={{
            color: COLORS.grey[600],
            fontSize: '1rem',
          }}
        >
          Welcome back, <Box component="span" sx={{ fontWeight: 600, color: COLORS.text }}>{user?.displayName || 'Admin'}</Box>! Here's your overview for today.
        </Typography>
      </Box>

      {/* Stats Grid */}
      <Grid container spacing={3} sx={{ mb: 5 }}>
        <Grid size={{ xs: 12, sm: 6, lg: 4 }}>
          <StatCard
            title="Total Users"
            value={mockStats.totalUsers}
            icon={<People />}
            growth={mockStats.userGrowth}
            color={COLORS.primary}
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, lg: 4 }}>
          <StatCard
            title="Active Users (24h)"
            value={mockStats.activeUsers24h}
            icon={<TrendingUp />}
            color={COLORS.primary}
            growth={mockStats.activeGrowth}
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, lg: 4 }}>
          <StatCard
            title="Total Messages"
            value={mockStats.totalMessages}
            icon={<Chat />}
            color={COLORS.grey[700]}
            growth={mockStats.messagesGrowth}
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, lg: 4 }}>
          <StatCard
            title="Active Stories"
            value={mockStats.activeStories}
            icon={<PhotoLibrary />}
            color={COLORS.grey[700]}
            growth={mockStats.storiesGrowth}
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, lg: 4 }}>
          <StatCard
            title="Total Calls"
            value={mockStats.totalCalls}
            icon={<Phone />}
            color={COLORS.grey[700]}
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, lg: 4 }}>
          <StatCard
            title="Pending Reports"
            value={mockStats.pendingReports}
            icon={<Flag />}
            color={COLORS.grey[900]}
          />
        </Grid>
      </Grid>

      <Divider sx={{ mb: 5 }} />

      {/* Quick Actions Section */}
      <Box>
        <Typography
          variant="h5"
          sx={{
            fontWeight: 700,
            color: COLORS.text,
            mb: 3,
            fontSize: '1.5rem',
          }}
        >
          Quick Actions
        </Typography>
        <Grid container spacing={3}>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Paper
              sx={{
                p: 3,
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                backgroundColor: COLORS.white,
                '&:hover': {
                  transform: 'translateY(-2px)',
                  borderColor: COLORS.primary,
                  '& .action-icon': {
                    backgroundColor: COLORS.primary,
                    color: COLORS.white,
                  },
                  '& .arrow-icon': {
                    transform: 'translateX(4px)',
                  },
                },
              }}
            >
              <Box
                className="action-icon"
                sx={{
                  width: 56,
                  height: 56,
                  borderRadius: 2,
                  backgroundColor: COLORS.green[50],
                  color: COLORS.primary,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mb: 2,
                  transition: 'all 0.2s ease',
                }}
              >
                <People sx={{ fontSize: 28 }} />
              </Box>
              <Typography
                variant="h6"
                sx={{
                  fontWeight: 600,
                  color: COLORS.text,
                  mb: 1,
                  fontSize: '1.125rem',
                }}
              >
                Manage Users
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  color: COLORS.grey[600],
                  mb: 2,
                  fontSize: '0.875rem',
                }}
              >
                View and moderate users
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', color: COLORS.primary }}>
                <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.875rem' }}>
                  Open
                </Typography>
                <ArrowForward
                  className="arrow-icon"
                  sx={{ fontSize: 16, ml: 0.5, transition: 'transform 0.2s ease' }}
                />
              </Box>
            </Paper>
          </Grid>

          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Paper
              sx={{
                p: 3,
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                backgroundColor: COLORS.white,
                '&:hover': {
                  transform: 'translateY(-2px)',
                  borderColor: COLORS.grey[900],
                  '& .action-icon': {
                    backgroundColor: COLORS.grey[900],
                    color: COLORS.white,
                  },
                  '& .arrow-icon': {
                    transform: 'translateX(4px)',
                  },
                },
              }}
            >
              <Box
                className="action-icon"
                sx={{
                  width: 56,
                  height: 56,
                  borderRadius: 2,
                  backgroundColor: COLORS.grey[100],
                  color: COLORS.grey[900],
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mb: 2,
                  transition: 'all 0.2s ease',
                }}
              >
                <Flag sx={{ fontSize: 28 }} />
              </Box>
              <Typography
                variant="h6"
                sx={{
                  fontWeight: 600,
                  color: COLORS.text,
                  mb: 1,
                  fontSize: '1.125rem',
                }}
              >
                Review Reports
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  color: COLORS.grey[600],
                  mb: 2,
                  fontSize: '0.875rem',
                }}
              >
                {mockStats.pendingReports} pending reports
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', color: COLORS.grey[900] }}>
                <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.875rem' }}>
                  Open
                </Typography>
                <ArrowForward
                  className="arrow-icon"
                  sx={{ fontSize: 16, ml: 0.5, transition: 'transform 0.2s ease' }}
                />
              </Box>
            </Paper>
          </Grid>

          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Paper
              sx={{
                p: 3,
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                backgroundColor: COLORS.white,
                '&:hover': {
                  transform: 'translateY(-2px)',
                  borderColor: COLORS.grey[700],
                  '& .action-icon': {
                    backgroundColor: COLORS.grey[700],
                    color: COLORS.white,
                  },
                  '& .arrow-icon': {
                    transform: 'translateX(4px)',
                  },
                },
              }}
            >
              <Box
                className="action-icon"
                sx={{
                  width: 56,
                  height: 56,
                  borderRadius: 2,
                  backgroundColor: COLORS.grey[100],
                  color: COLORS.grey[700],
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mb: 2,
                  transition: 'all 0.2s ease',
                }}
              >
                <PhotoLibrary sx={{ fontSize: 28 }} />
              </Box>
              <Typography
                variant="h6"
                sx={{
                  fontWeight: 600,
                  color: COLORS.text,
                  mb: 1,
                  fontSize: '1.125rem',
                }}
              >
                Moderate Stories
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  color: COLORS.grey[600],
                  mb: 2,
                  fontSize: '0.875rem',
                }}
              >
                {mockStats.activeStories} active stories
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', color: COLORS.grey[700] }}>
                <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.875rem' }}>
                  Open
                </Typography>
                <ArrowForward
                  className="arrow-icon"
                  sx={{ fontSize: 16, ml: 0.5, transition: 'transform 0.2s ease' }}
                />
              </Box>
            </Paper>
          </Grid>

          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Paper
              sx={{
                p: 3,
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                backgroundColor: COLORS.white,
                '&:hover': {
                  transform: 'translateY(-2px)',
                  borderColor: COLORS.primary,
                  '& .action-icon': {
                    backgroundColor: COLORS.primary,
                    color: COLORS.white,
                  },
                  '& .arrow-icon': {
                    transform: 'translateX(4px)',
                  },
                },
              }}
            >
              <Box
                className="action-icon"
                sx={{
                  width: 56,
                  height: 56,
                  borderRadius: 2,
                  backgroundColor: COLORS.green[50],
                  color: COLORS.primary,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  mb: 2,
                  transition: 'all 0.2s ease',
                }}
              >
                <TrendingUp sx={{ fontSize: 28 }} />
              </Box>
              <Typography
                variant="h6"
                sx={{
                  fontWeight: 600,
                  color: COLORS.text,
                  mb: 1,
                  fontSize: '1.125rem',
                }}
              >
                View Analytics
              </Typography>
              <Typography
                variant="body2"
                sx={{
                  color: COLORS.grey[600],
                  mb: 2,
                  fontSize: '0.875rem',
                }}
              >
                Detailed insights
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', color: COLORS.primary }}>
                <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.875rem' }}>
                  Open
                </Typography>
                <ArrowForward
                  className="arrow-icon"
                  sx={{ fontSize: 16, ml: 0.5, transition: 'transform 0.2s ease' }}
                />
              </Box>
            </Paper>
          </Grid>
        </Grid>
      </Box>
    </Box>
  );
};

export default Dashboard;
