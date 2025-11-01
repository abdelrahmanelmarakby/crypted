import React, { useState } from 'react';
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
  Chip,
  Avatar,
  Grid,
  TextField,
  InputAdornment,
} from '@mui/material';
import {
  Search,
  Phone,
  Videocam,
  AccessTime,
  CheckCircle,
  Cancel,
} from '@mui/icons-material';
import { COLORS } from '../utils/constants';

// Mock data
const mockCalls = [
  { id: '1', caller: 'Ahmed Hassan', callee: 'Sara Ali', type: 'video', duration: '12:34', status: 'completed', timestamp: new Date('2025-10-29') },
  { id: '2', caller: 'Mohamed Saeed', callee: 'Layla Khan', type: 'voice', duration: '5:21', status: 'completed', timestamp: new Date('2025-10-29') },
  { id: '3', caller: 'Omar Zaki', callee: 'Fatima Noor', type: 'video', duration: '0:12', status: 'missed', timestamp: new Date('2025-10-28') },
  { id: '4', caller: 'Youssef Ali', callee: 'Amira Hasan', type: 'voice', duration: '8:45', status: 'completed', timestamp: new Date('2025-10-28') },
];

const Calls: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredCalls = mockCalls.filter(call =>
    call.caller.toLowerCase().includes(searchTerm.toLowerCase()) ||
    call.callee.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const totalCalls = mockCalls.length;
  const videoCalls = mockCalls.filter(c => c.type === 'video').length;
  const voiceCalls = mockCalls.filter(c => c.type === 'voice').length;
  const totalDuration = mockCalls.reduce((acc, call) => {
    const [min, sec] = call.duration.split(':').map(Number);
    return acc + min * 60 + sec;
  }, 0);

  const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h3" sx={{ fontWeight: 700, color: COLORS.text, fontSize: '2.25rem', mb: 1 }}>
          Calls Management
        </Typography>
        <Typography variant="body1" sx={{ color: COLORS.grey[600] }}>
          Monitor and analyze call history across the platform
        </Typography>
      </Box>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>Total Calls</Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.text }}>{totalCalls}</Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>Video Calls</Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.primary }}>{videoCalls}</Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>Voice Calls</Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.grey[700] }}>{voiceCalls}</Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>Total Duration</Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.text }}>{formatDuration(totalDuration)}</Typography>
          </Paper>
        </Grid>
      </Grid>

      <Paper sx={{ p: 3, mb: 3 }}>
        <TextField
          placeholder="Search calls by user..."
          variant="outlined"
          size="small"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          sx={{ minWidth: 300, '& .MuiOutlinedInput-root': { backgroundColor: COLORS.grey[50] } }}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search sx={{ color: COLORS.grey[600] }} />
              </InputAdornment>
            ),
          }}
        />
      </Paper>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow sx={{ backgroundColor: COLORS.grey[50] }}>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Caller</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Callee</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Type</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Duration</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Status</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Date</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredCalls.map((call) => (
              <TableRow key={call.id} sx={{ '&:hover': { backgroundColor: COLORS.grey[50] } }}>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <Avatar sx={{ width: 32, height: 32, bgcolor: COLORS.primary, fontSize: '0.9rem' }}>
                      {call.caller.charAt(0)}
                    </Avatar>
                    <Typography variant="body2" sx={{ fontWeight: 600, color: COLORS.text }}>
                      {call.caller}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" sx={{ color: COLORS.grey[700] }}>{call.callee}</Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    icon={call.type === 'video' ? <Videocam sx={{ fontSize: 16 }} /> : <Phone sx={{ fontSize: 16 }} />}
                    label={call.type}
                    size="small"
                    sx={{
                      backgroundColor: call.type === 'video' ? COLORS.green[50] : COLORS.grey[100],
                      color: call.type === 'video' ? COLORS.primary : COLORS.grey[700],
                      textTransform: 'capitalize',
                      fontWeight: 500,
                    }}
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    <AccessTime sx={{ fontSize: 16, color: COLORS.grey[600] }} />
                    <Typography variant="body2" sx={{ color: COLORS.grey[700] }}>{call.duration}</Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  {call.status === 'completed' ? (
                    <Chip
                      icon={<CheckCircle sx={{ fontSize: 16 }} />}
                      label="Completed"
                      size="small"
                      sx={{ backgroundColor: COLORS.green[50], color: COLORS.primary, fontWeight: 600 }}
                    />
                  ) : (
                    <Chip
                      icon={<Cancel sx={{ fontSize: 16 }} />}
                      label="Missed"
                      size="small"
                      sx={{ backgroundColor: COLORS.grey[100], color: COLORS.grey[700], fontWeight: 600 }}
                    />
                  )}
                </TableCell>
                <TableCell>
                  <Typography variant="body2" sx={{ color: COLORS.grey[700] }}>
                    {call.timestamp.toLocaleDateString()}
                  </Typography>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default Calls;
