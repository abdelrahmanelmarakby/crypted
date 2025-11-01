import React, { useEffect } from 'react';
import { Box, Grid, Typography } from '@mui/material';
import {
  People,
  Chat,
  PhotoLibrary,
  Phone,
  Flag,
  TrendingUp,
} from '@mui/icons-material';
import StatCard from '../components/common/StatCard';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { useAppDispatch, useAppSelector } from '../store';

const Dashboard: React.FC = () => {
  const dispatch = useAppDispatch();
  const { loading } = useAppSelector((state) => state.dashboard);

  useEffect(() => {
    // TODO: Fetch dashboard stats
    // dispatch(fetchDashboardStats());
  }, [dispatch]);

  if (loading) {
    return <LoadingSpinner />;
  }

  // Mock data for demonstration
  const mockStats = {
    totalUsers: 1250,
    activeUsers24h: 450,
    totalMessages: 25600,
    activeStories: 87,
    totalCalls: 1420,
    pendingReports: 12,
    userGrowth: 15.3,
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Welcome to Crypted Admin Panel
      </Typography>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <StatCard
            title="Total Users"
            value={mockStats.totalUsers}
            icon={<People />}
            growth={mockStats.userGrowth}
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <StatCard
            title="Active Users (24h)"
            value={mockStats.activeUsers24h}
            icon={<TrendingUp />}
            color="#27AE60"
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <StatCard
            title="Total Messages"
            value={mockStats.totalMessages}
            icon={<Chat />}
            color="#3498DB"
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <StatCard
            title="Active Stories"
            value={mockStats.activeStories}
            icon={<PhotoLibrary />}
            color="#9B59B6"
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <StatCard
            title="Total Calls"
            value={mockStats.totalCalls}
            icon={<Phone />}
            color="#1ABC9C"
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <StatCard
            title="Pending Reports"
            value={mockStats.pendingReports}
            icon={<Flag />}
            color="#E74C3C"
          />
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
