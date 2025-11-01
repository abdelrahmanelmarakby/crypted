import React, { useEffect } from 'react';
import { Box, Typography, Paper } from '@mui/material';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { useAppDispatch, useAppSelector } from '../store';

const Users: React.FC = () => {
  const dispatch = useAppDispatch();
  const { loading } = useAppSelector((state) => state.users);

  useEffect(() => {
    // TODO: Fetch users
    // dispatch(fetchUsers());
  }, [dispatch]);

  if (loading) {
    return <LoadingSpinner />;
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        User Management
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Manage and monitor user accounts
      </Typography>

      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          User List
        </Typography>
        <Typography variant="body2" color="text.secondary">
          User management features coming soon...
        </Typography>
        <Typography variant="caption" display="block" sx={{ mt: 2 }}>
          Features to be implemented:
          <ul>
            <li>Search and filter users</li>
            <li>View user details and activity</li>
            <li>Suspend or ban users</li>
            <li>Export user data</li>
            <li>User statistics and analytics</li>
          </ul>
        </Typography>
      </Paper>
    </Box>
  );
};

export default Users;
