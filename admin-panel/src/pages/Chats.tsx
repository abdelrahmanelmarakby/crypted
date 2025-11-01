import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Avatar,
  TextField,
  InputAdornment,
  Chip,
  IconButton,
  Grid,
  Divider,
  Badge,
} from '@mui/material';
import {
  Search,
  MoreVert,
  Message,
  People,
  AccessTime,
} from '@mui/icons-material';
import { COLORS } from '../utils/constants';

// Mock data
const mockChats = [
  { id: '1', participants: ['Ahmed Hassan', 'Sara Ali'], lastMessage: 'See you tomorrow!', timestamp: '2 min ago', unread: 3, online: true },
  { id: '2', participants: ['Mohamed Saeed', 'Layla Khan'], lastMessage: 'Thanks for the help', timestamp: '15 min ago', unread: 0, online: true },
  { id: '3', participants: ['Omar Zaki', 'Fatima Noor'], lastMessage: 'Photo', timestamp: '1 hour ago', unread: 1, online: false },
  { id: '4', participants: ['Youssef Ali', 'Amira Hasan'], lastMessage: 'Got it!', timestamp: '3 hours ago', unread: 0, online: false },
  { id: '5', participants: ['Ali Khan', 'Nour Ahmed'], lastMessage: 'Where are you?', timestamp: '1 day ago', unread: 0, online: true },
];

const Chats: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedChat, setSelectedChat] = useState<string | null>(null);

  const filteredChats = mockChats.filter(chat =>
    chat.participants.some(p => p.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const totalChats = mockChats.length;
  const activeChats = mockChats.filter(c => c.online).length;
  const unreadCount = mockChats.reduce((acc, c) => acc + c.unread, 0);

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h3" sx={{ fontWeight: 700, color: COLORS.text, fontSize: '2.25rem', mb: 1 }}>
          Chat Management
        </Typography>
        <Typography variant="body1" sx={{ color: COLORS.grey[600] }}>
          Monitor and manage conversations across the platform
        </Typography>
      </Box>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>Total Chats</Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.text }}>{totalChats}</Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>Active Now</Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.primary }}>{activeChats}</Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>Unread Messages</Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.grey[800] }}>{unreadCount}</Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>Today's Messages</Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.text }}>1.2K</Typography>
          </Paper>
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, lg: 5 }}>
          <Paper sx={{ height: 600, display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ p: 3, borderBottom: `1px solid ${COLORS.grey[200]}` }}>
              <TextField
                fullWidth
                placeholder="Search conversations..."
                variant="outlined"
                size="small"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                sx={{ '& .MuiOutlinedInput-root': { backgroundColor: COLORS.grey[50] } }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Search sx={{ color: COLORS.grey[600] }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Box>

            <List sx={{ overflow: 'auto', flexGrow: 1 }}>
              {filteredChats.map((chat) => (
                <React.Fragment key={chat.id}>
                  <ListItem
                    button
                    selected={selectedChat === chat.id}
                    onClick={() => setSelectedChat(chat.id)}
                    sx={{
                      py: 2,
                      '&.Mui-selected': {
                        backgroundColor: COLORS.green[50],
                        '&:hover': {
                          backgroundColor: COLORS.green[100],
                        },
                      },
                      '&:hover': {
                        backgroundColor: COLORS.grey[50],
                      },
                    }}
                  >
                    <ListItemAvatar>
                      <Badge
                        overlap="circular"
                        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                        variant="dot"
                        sx={{
                          '& .MuiBadge-dot': {
                            backgroundColor: chat.online ? COLORS.primary : COLORS.grey[400],
                            width: 12,
                            height: 12,
                            borderRadius: '50%',
                            border: `2px solid ${COLORS.white}`,
                          },
                        }}
                      >
                        <Avatar sx={{ bgcolor: COLORS.primary, width: 48, height: 48 }}>
                          {chat.participants[0].charAt(0)}
                        </Avatar>
                      </Badge>
                    </ListItemAvatar>
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 0.5 }}>
                          <Typography variant="body1" sx={{ fontWeight: 600, color: COLORS.text }}>
                            {chat.participants.join(' & ')}
                          </Typography>
                          {chat.unread > 0 && (
                            <Chip
                              label={chat.unread}
                              size="small"
                              sx={{
                                backgroundColor: COLORS.primary,
                                color: COLORS.white,
                                height: 20,
                                fontSize: '0.75rem',
                                fontWeight: 600,
                              }}
                            />
                          )}
                        </Box>
                      }
                      secondary={
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Typography variant="body2" sx={{ color: COLORS.grey[700], fontSize: '0.875rem' }}>
                            {chat.lastMessage}
                          </Typography>
                          <Typography variant="caption" sx={{ color: COLORS.grey[600] }}>
                            {chat.timestamp}
                          </Typography>
                        </Box>
                      }
                    />
                  </ListItem>
                  <Divider variant="inset" component="li" />
                </React.Fragment>
              ))}
            </List>
          </Paper>
        </Grid>

        <Grid size={{ xs: 12, lg: 7 }}>
          <Paper sx={{ height: 600, display: 'flex', flexDirection: 'column' }}>
            {selectedChat ? (
              <>
                <Box sx={{ p: 3, borderBottom: `1px solid ${COLORS.grey[200]}`, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Avatar sx={{ bgcolor: COLORS.primary, width: 40, height: 40 }}>
                      {mockChats.find(c => c.id === selectedChat)?.participants[0].charAt(0)}
                    </Avatar>
                    <Box>
                      <Typography variant="body1" sx={{ fontWeight: 600 }}>
                        {mockChats.find(c => c.id === selectedChat)?.participants.join(' & ')}
                      </Typography>
                      <Typography variant="caption" sx={{ color: COLORS.grey[600] }}>
                        {mockChats.find(c => c.id === selectedChat)?.online ? 'Online' : 'Offline'}
                      </Typography>
                    </Box>
                  </Box>
                  <IconButton>
                    <MoreVert />
                  </IconButton>
                </Box>

                <Box
                  sx={{
                    flexGrow: 1,
                    p: 3,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    backgroundColor: COLORS.grey[50],
                  }}
                >
                  <Box sx={{ textAlign: 'center' }}>
                    <Message sx={{ fontSize: 64, color: COLORS.grey[400], mb: 2 }} />
                    <Typography variant="body1" sx={{ color: COLORS.grey[600] }}>
                      Message history would appear here
                    </Typography>
                  </Box>
                </Box>
              </>
            ) : (
              <Box
                sx={{
                  height: '100%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexDirection: 'column',
                  gap: 2,
                }}
              >
                <Message sx={{ fontSize: 80, color: COLORS.grey[300] }} />
                <Typography variant="h6" sx={{ color: COLORS.grey[600] }}>
                  Select a conversation to view
                </Typography>
              </Box>
            )}
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Chats;
