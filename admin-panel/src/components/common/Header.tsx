import React from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  IconButton,
  Avatar,
  Menu,
  MenuItem,
  Box,
  Tooltip,
  Divider,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Logout,
  Settings,
  Person,
} from '@mui/icons-material';
import { useAuth } from '../../hooks/useAuth';
import { useNavigate } from 'react-router-dom';
import { APP_NAME, COLORS } from '../../utils/constants';

interface HeaderProps {
  onMenuClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <AppBar
      position="fixed"
      elevation={0}
      sx={{
        zIndex: (theme) => theme.zIndex.drawer + 1,
        backgroundColor: COLORS.white,
        borderBottom: `1px solid ${COLORS.grey[200]}`,
      }}
    >
      <Toolbar sx={{ minHeight: 64 }}>
        <IconButton
          edge="start"
          onClick={onMenuClick}
          sx={{
            mr: 2,
            display: { sm: 'none' },
            color: COLORS.text,
          }}
        >
          <MenuIcon />
        </IconButton>

        <Typography
          variant="h6"
          component="div"
          sx={{
            flexGrow: 1,
            fontWeight: 700,
            color: COLORS.text,
            fontSize: '1.25rem',
          }}
        >
          {APP_NAME}
        </Typography>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Box sx={{ textAlign: 'right', mr: 1, display: { xs: 'none', md: 'block' } }}>
            <Typography
              variant="body2"
              sx={{ fontWeight: 600, color: COLORS.text, lineHeight: 1.2 }}
            >
              {user?.displayName || 'Admin'}
            </Typography>
            <Typography
              variant="caption"
              sx={{ color: COLORS.grey[600], fontSize: '0.75rem' }}
            >
              {user?.role?.replace('_', ' ')}
            </Typography>
          </Box>
          <Tooltip title={user?.displayName || 'Admin'}>
            <IconButton onClick={handleMenuOpen} sx={{ p: 0 }}>
              <Avatar
                sx={{
                  bgcolor: COLORS.primary,
                  width: 40,
                  height: 40,
                  fontWeight: 600,
                }}
              >
                {user?.displayName?.charAt(0).toUpperCase() || 'A'}
              </Avatar>
            </IconButton>
          </Tooltip>

          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={handleMenuClose}
            transformOrigin={{ horizontal: 'right', vertical: 'top' }}
            anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
            PaperProps={{
              elevation: 0,
              sx: {
                mt: 1.5,
                minWidth: 220,
                border: `1px solid ${COLORS.grey[200]}`,
                '& .MuiMenuItem-root': {
                  px: 2,
                  py: 1.5,
                  borderRadius: 1,
                  mx: 1,
                  '&:hover': {
                    backgroundColor: COLORS.grey[100],
                  },
                },
              },
            }}
          >
            <Box sx={{ px: 2, py: 1.5 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 0.5 }}>
                <Person sx={{ mr: 1, fontSize: 20, color: COLORS.grey[600] }} />
                <Typography variant="body2" sx={{ fontWeight: 600, color: COLORS.text }}>
                  {user?.displayName || 'Admin'}
                </Typography>
              </Box>
              <Typography
                variant="caption"
                sx={{ color: COLORS.grey[600], pl: 4, display: 'block' }}
              >
                {user?.email}
              </Typography>
              <Typography
                variant="caption"
                sx={{
                  color: COLORS.primary,
                  pl: 4,
                  display: 'block',
                  fontWeight: 600,
                  textTransform: 'uppercase',
                  fontSize: '0.7rem',
                  mt: 0.5,
                }}
              >
                {user?.role?.replace('_', ' ')}
              </Typography>
            </Box>
            <Divider sx={{ my: 1 }} />
            <MenuItem
              onClick={() => {
                navigate('/settings');
                handleMenuClose();
              }}
            >
              <Settings sx={{ mr: 1.5, fontSize: 20, color: COLORS.grey[600] }} />
              <Typography variant="body2" sx={{ fontWeight: 500 }}>
                Settings
              </Typography>
            </MenuItem>
            <MenuItem onClick={handleLogout}>
              <Logout sx={{ mr: 1.5, fontSize: 20, color: COLORS.grey[700] }} />
              <Typography variant="body2" sx={{ fontWeight: 500 }}>
                Logout
              </Typography>
            </MenuItem>
          </Menu>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Header;
