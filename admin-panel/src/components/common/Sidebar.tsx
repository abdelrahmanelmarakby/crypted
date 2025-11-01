import React from 'react';
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Divider,
  Badge,
  Box,
} from '@mui/material';
import {
  Dashboard,
  People,
  Chat,
  PhotoLibrary,
  Flag,
  Phone,
  BarChart,
  Notifications,
  Settings,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppSelector } from '../../store';
import { COLORS } from '../../utils/constants';

interface SidebarProps {
  mobileOpen: boolean;
  onClose: () => void;
}

const drawerWidth = 240;

const menuItems = [
  { text: 'Dashboard', icon: <Dashboard />, path: '/' },
  { text: 'Users', icon: <People />, path: '/users' },
  { text: 'Chats', icon: <Chat />, path: '/chats' },
  { text: 'Stories', icon: <PhotoLibrary />, path: '/stories' },
  { text: 'Reports', icon: <Flag />, path: '/reports', badge: 'pendingReports' },
  { text: 'Calls', icon: <Phone />, path: '/calls' },
  { text: 'Analytics', icon: <BarChart />, path: '/analytics' },
  { text: 'Notifications', icon: <Notifications />, path: '/notifications' },
  { text: 'Settings', icon: <Settings />, path: '/settings' },
];

const Sidebar: React.FC<SidebarProps> = ({ mobileOpen, onClose }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { pendingCount } = useAppSelector((state) => state.reports);

  const getBadgeContent = (badgeKey?: string) => {
    if (badgeKey === 'pendingReports' && pendingCount > 0) {
      return pendingCount;
    }
    return undefined;
  };

  const drawer = (
    <Box sx={{ height: '100%', backgroundColor: COLORS.white }}>
      <Toolbar />
      <Divider />
      <List sx={{ px: 2, py: 2 }}>
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          const badgeContent = getBadgeContent(item.badge);

          return (
            <ListItem key={item.text} disablePadding sx={{ mb: 0.5 }}>
              <ListItemButton
                selected={isActive}
                onClick={() => {
                  navigate(item.path);
                  onClose();
                }}
                sx={{
                  borderRadius: 2,
                  py: 1.25,
                  px: 2,
                  transition: 'all 0.2s ease',
                  '&.Mui-selected': {
                    backgroundColor: COLORS.green[50],
                    color: COLORS.primary,
                    '&:hover': {
                      backgroundColor: COLORS.green[100],
                    },
                    '& .MuiListItemIcon-root': {
                      color: COLORS.primary,
                    },
                  },
                  '&:hover': {
                    backgroundColor: COLORS.grey[100],
                  },
                }}
              >
                <ListItemIcon
                  sx={{
                    minWidth: 40,
                    color: isActive ? COLORS.primary : COLORS.grey[600],
                    transition: 'color 0.2s ease',
                  }}
                >
                  {badgeContent ? (
                    <Badge
                      badgeContent={badgeContent}
                      sx={{
                        '& .MuiBadge-badge': {
                          backgroundColor: COLORS.grey[900],
                          color: COLORS.white,
                          fontWeight: 600,
                          fontSize: '0.7rem',
                        },
                      }}
                    >
                      {item.icon}
                    </Badge>
                  ) : (
                    item.icon
                  )}
                </ListItemIcon>
                <ListItemText
                  primary={item.text}
                  primaryTypographyProps={{
                    fontSize: '0.9rem',
                    fontWeight: isActive ? 600 : 500,
                    color: isActive ? COLORS.primary : COLORS.text,
                  }}
                />
              </ListItemButton>
            </ListItem>
          );
        })}
      </List>
    </Box>
  );

  return (
    <>
      {/* Mobile drawer */}
      <Drawer
        variant="temporary"
        open={mobileOpen}
        onClose={onClose}
        ModalProps={{
          keepMounted: true,
        }}
        sx={{
          display: { xs: 'block', sm: 'none' },
          '& .MuiDrawer-paper': {
            boxSizing: 'border-box',
            width: drawerWidth,
            border: 'none',
          },
        }}
      >
        {drawer}
      </Drawer>

      {/* Desktop drawer */}
      <Drawer
        variant="permanent"
        sx={{
          display: { xs: 'none', sm: 'block' },
          '& .MuiDrawer-paper': {
            boxSizing: 'border-box',
            width: drawerWidth,
            borderRight: `1px solid ${COLORS.grey[200]}`,
            borderLeft: 'none',
          },
        }}
        open
      >
        {drawer}
      </Drawer>
    </>
  );
};

export default Sidebar;
