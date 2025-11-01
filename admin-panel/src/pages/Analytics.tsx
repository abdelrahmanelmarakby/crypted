import React from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
} from '@mui/material';
import {
  TrendingUp,
  People,
  Chat,
  PhotoLibrary,
} from '@mui/icons-material';
import { COLORS } from '../utils/constants';

const Analytics: React.FC = () => {
  // Mock data
  const metrics = [
    { title: 'Daily Active Users', value: '1,245', change: '+12.5%', positive: true, icon: <People /> },
    { title: 'Messages Sent Today', value: '8,432', change: '+8.3%', positive: true, icon: <Chat /> },
    { title: 'Stories Posted', value: '234', change: '-2.1%', positive: false, icon: <PhotoLibrary /> },
    { title: 'Engagement Rate', value: '68%', change: '+5.2%', positive: true, icon: <TrendingUp /> },
  ];

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h3" sx={{ fontWeight: 700, color: COLORS.text, fontSize: '2.25rem', mb: 1 }}>
          Analytics Dashboard
        </Typography>
        <Typography variant="body1" sx={{ color: COLORS.grey[600] }}>
          View detailed insights and platform analytics
        </Typography>
      </Box>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        {metrics.map((metric, index) => (
          <Grid size={{ xs: 12, sm: 6, lg: 3 }} key={index}>
            <Paper sx={{ p: 3 }}>
              <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 2 }}>
                <Box>
                  <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1, textTransform: 'uppercase', fontSize: '0.75rem', letterSpacing: '0.5px' }}>
                    {metric.title}
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.text }}>
                    {metric.value}
                  </Typography>
                </Box>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2,
                    backgroundColor: COLORS.green[50],
                    color: COLORS.primary,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  {metric.icon}
                </Box>
              </Box>
              <Box
                sx={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  backgroundColor: metric.positive ? COLORS.green[50] : COLORS.grey[100],
                  borderRadius: 1,
                  px: 1.5,
                  py: 0.5,
                }}
              >
                <TrendingUp sx={{ fontSize: 14, color: metric.positive ? COLORS.primary : COLORS.grey[700], mr: 0.5, transform: metric.positive ? 'none' : 'rotate(180deg)' }} />
                <Typography
                  variant="body2"
                  sx={{
                    color: metric.positive ? COLORS.primary : COLORS.grey[700],
                    fontWeight: 700,
                    fontSize: '0.8rem',
                  }}
                >
                  {metric.change}
                </Typography>
              </Box>
            </Paper>
          </Grid>
        ))}
      </Grid>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, lg: 8 }}>
          <Paper sx={{ p: 4, height: 400 }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
              User Activity Trend
            </Typography>
            <Box
              sx={{
                height: 320,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: COLORS.grey[50],
                borderRadius: 2,
              }}
            >
              <Typography variant="body2" sx={{ color: COLORS.grey[600] }}>
                Chart visualization would go here
              </Typography>
            </Box>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, lg: 4 }}>
          <Paper sx={{ p: 4, height: 400 }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
              Top Content Types
            </Typography>
            <Box
              sx={{
                height: 320,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: COLORS.grey[50],
                borderRadius: 2,
              }}
            >
              <Typography variant="body2" sx={{ color: COLORS.grey[600] }}>
                Pie chart would go here
              </Typography>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Analytics;
