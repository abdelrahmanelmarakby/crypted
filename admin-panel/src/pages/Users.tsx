import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Avatar,
  Chip,
  IconButton,
  TextField,
  InputAdornment,
  Menu,
  MenuItem,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  DialogContentText,
  Grid,
} from '@mui/material';
import {
  Search,
  MoreVert,
  Block,
  CheckCircle,
  Delete,
  Visibility,
  FileDownload,
  PersonOff,
} from '@mui/icons-material';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { useAppDispatch, useAppSelector } from '../store';
import { COLORS } from '../utils/constants';
import userService from '../services/user.service';
import { User } from '../types/user.types';

const Users: React.FC = () => {
  const dispatch = useAppDispatch();
  const { loading } = useAppSelector((state) => state.users);
  const [users, setUsers] = useState<User[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    type: 'suspend' | 'ban' | 'delete' | null;
  }>({ open: false, type: null });
  const [localLoading, setLocalLoading] = useState(false);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLocalLoading(true);
      const { users: fetchedUsers } = await userService.getUsers(50);
      setUsers(fetchedUsers);
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLocalLoading(false);
    }
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, user: User) => {
    setAnchorEl(event.currentTarget);
    setSelectedUser(user);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleActionClick = (type: 'suspend' | 'ban' | 'delete') => {
    setActionDialog({ open: true, type });
    handleMenuClose();
  };

  const handleActionConfirm = async () => {
    if (!selectedUser || !actionDialog.type) return;

    try {
      setLocalLoading(true);
      switch (actionDialog.type) {
        case 'suspend':
          await userService.suspendUser(selectedUser.uid, 7);
          break;
        case 'ban':
          await userService.banUser(selectedUser.uid, 'Banned by admin');
          break;
        case 'delete':
          await userService.deleteUser(selectedUser.uid);
          break;
      }
      await fetchUsers();
    } catch (error) {
      console.error(`Error ${actionDialog.type}ing user:`, error);
    } finally {
      setLocalLoading(false);
      setActionDialog({ open: false, type: null });
      setSelectedUser(null);
    }
  };

  const getStatusChip = (status?: string) => {
    switch (status) {
      case 'active':
        return (
          <Chip
            label="Active"
            size="small"
            icon={<CheckCircle sx={{ fontSize: 16 }} />}
            sx={{
              backgroundColor: COLORS.green[50],
              color: COLORS.primary,
              fontWeight: 600,
              border: 'none',
            }}
          />
        );
      case 'suspended':
        return (
          <Chip
            label="Suspended"
            size="small"
            icon={<Block sx={{ fontSize: 16 }} />}
            sx={{
              backgroundColor: COLORS.grey[100],
              color: COLORS.grey[700],
              fontWeight: 600,
              border: 'none',
            }}
          />
        );
      case 'banned':
        return (
          <Chip
            label="Banned"
            size="small"
            icon={<PersonOff sx={{ fontSize: 16 }} />}
            sx={{
              backgroundColor: COLORS.grey[900],
              color: COLORS.white,
              fontWeight: 600,
              border: 'none',
            }}
          />
        );
      default:
        return (
          <Chip
            label="Unknown"
            size="small"
            sx={{
              backgroundColor: COLORS.grey[100],
              color: COLORS.grey[600],
              fontWeight: 600,
              border: 'none',
            }}
          />
        );
    }
  };

  const filteredUsers = users.filter((user) =>
    user.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading || localLoading) {
    return <LoadingSpinner />;
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography
          variant="h3"
          sx={{
            fontWeight: 700,
            color: COLORS.text,
            fontSize: '2.25rem',
            mb: 1,
          }}
        >
          User Management
        </Typography>
        <Typography variant="body1" sx={{ color: COLORS.grey[600] }}>
          Manage and monitor user accounts across the platform
        </Typography>
      </Box>

      {/* Stats Row */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Total Users
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.text }}>
              {users.length}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Active
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.primary }}>
              {users.filter((u) => u.status === 'active').length}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Suspended
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.grey[700] }}>
              {users.filter((u) => u.status === 'suspended').length}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Banned
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.grey[900] }}>
              {users.filter((u) => u.status === 'banned').length}
            </Typography>
          </Paper>
        </Grid>
      </Grid>

      {/* Search and Actions */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 2 }}>
          <TextField
            placeholder="Search users by name or email..."
            variant="outlined"
            size="small"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            sx={{
              minWidth: 300,
              '& .MuiOutlinedInput-root': {
                backgroundColor: COLORS.grey[50],
              },
            }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search sx={{ color: COLORS.grey[600] }} />
                </InputAdornment>
              ),
            }}
          />
          <Button
            variant="outlined"
            startIcon={<FileDownload />}
            sx={{
              borderColor: COLORS.grey[300],
              color: COLORS.text,
              '&:hover': {
                borderColor: COLORS.grey[400],
                backgroundColor: COLORS.grey[50],
              },
            }}
          >
            Export
          </Button>
        </Box>
      </Paper>

      {/* Users Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow sx={{ backgroundColor: COLORS.grey[50] }}>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>User</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Email</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Status</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Joined</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }} align="right">
                Actions
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredUsers.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} align="center" sx={{ py: 8 }}>
                  <Typography variant="body1" color="text.secondary">
                    No users found
                  </Typography>
                </TableCell>
              </TableRow>
            ) : (
              filteredUsers.map((user) => (
                <TableRow
                  key={user.uid}
                  sx={{
                    '&:hover': {
                      backgroundColor: COLORS.grey[50],
                    },
                  }}
                >
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Avatar
                        src={user.avatar_url}
                        sx={{
                          bgcolor: COLORS.primary,
                          width: 40,
                          height: 40,
                        }}
                      >
                        {user.full_name?.charAt(0).toUpperCase()}
                      </Avatar>
                      <Typography variant="body2" sx={{ fontWeight: 600, color: COLORS.text }}>
                        {user.full_name || 'Unknown User'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ color: COLORS.grey[700] }}>
                      {user.email || 'N/A'}
                    </Typography>
                  </TableCell>
                  <TableCell>{getStatusChip(user.status)}</TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ color: COLORS.grey[700] }}>
                      {user.createdAt
                        ? new Date(user.createdAt.toDate()).toLocaleDateString()
                        : 'N/A'}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <IconButton
                      size="small"
                      onClick={(e) => handleMenuOpen(e, user)}
                      sx={{ color: COLORS.grey[600] }}
                    >
                      <MoreVert />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Action Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
        PaperProps={{
          elevation: 0,
          sx: {
            border: `1px solid ${COLORS.grey[200]}`,
            minWidth: 180,
          },
        }}
      >
        <MenuItem onClick={() => console.log('View user')}>
          <Visibility sx={{ mr: 1.5, fontSize: 20 }} />
          View Details
        </MenuItem>
        <MenuItem onClick={() => handleActionClick('suspend')}>
          <Block sx={{ mr: 1.5, fontSize: 20 }} />
          Suspend User
        </MenuItem>
        <MenuItem onClick={() => handleActionClick('ban')}>
          <PersonOff sx={{ mr: 1.5, fontSize: 20 }} />
          Ban User
        </MenuItem>
        <MenuItem onClick={() => handleActionClick('delete')} sx={{ color: COLORS.grey[900] }}>
          <Delete sx={{ mr: 1.5, fontSize: 20 }} />
          Delete User
        </MenuItem>
      </Menu>

      {/* Action Confirmation Dialog */}
      <Dialog open={actionDialog.open} onClose={() => setActionDialog({ open: false, type: null })}>
        <DialogTitle>Confirm Action</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to {actionDialog.type} user "{selectedUser?.full_name}"?
            This action may affect their access to the platform.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setActionDialog({ open: false, type: null })}>
            Cancel
          </Button>
          <Button onClick={handleActionConfirm} variant="contained" color="primary">
            Confirm
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Users;
