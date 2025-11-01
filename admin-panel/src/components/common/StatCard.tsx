import React from 'react';
import { Card, CardContent, Typography, Box } from '@mui/material';
import { TrendingUp, TrendingDown } from '@mui/icons-material';
import { formatNumber } from '../../utils/helpers';
import { COLORS } from '../../utils/constants';

interface StatCardProps {
  title: string;
  value: number;
  icon: React.ReactNode;
  color?: string;
  growth?: number;
  prefix?: string;
  suffix?: string;
}

const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  icon,
  color = COLORS.primary,
  growth,
  prefix = '',
  suffix = '',
}) => {
  const isPositiveGrowth = growth !== undefined && growth >= 0;

  return (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 48,
              height: 48,
              borderRadius: 2,
              backgroundColor: `${color}20`,
              color: color,
              mr: 2,
            }}
          >
            {icon}
          </Box>
          <Typography variant="body2" color="text.secondary">
            {title}
          </Typography>
        </Box>

        <Typography variant="h4" fontWeight="600" gutterBottom>
          {prefix}{formatNumber(value)}{suffix}
        </Typography>

        {growth !== undefined && (
          <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
            {isPositiveGrowth ? (
              <TrendingUp sx={{ fontSize: 20, color: COLORS.success, mr: 0.5 }} />
            ) : (
              <TrendingDown sx={{ fontSize: 20, color: COLORS.danger, mr: 0.5 }} />
            )}
            <Typography
              variant="body2"
              sx={{
                color: isPositiveGrowth ? COLORS.success : COLORS.danger,
                fontWeight: 500,
              }}
            >
              {Math.abs(growth).toFixed(1)}%
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ ml: 0.5 }}>
              vs last period
            </Typography>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export default StatCard;
