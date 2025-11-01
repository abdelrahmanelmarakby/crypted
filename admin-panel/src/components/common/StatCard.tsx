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
    <Card
      sx={{
        height: '100%',
        transition: 'all 0.2s ease',
        backgroundColor: COLORS.white,
        '&:hover': {
          transform: 'translateY(-2px)',
          borderColor: COLORS.grey[300],
        },
      }}
    >
      <CardContent sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 3 }}>
          <Box>
            <Typography
              variant="body2"
              sx={{
                color: COLORS.grey[600],
                fontWeight: 500,
                textTransform: 'uppercase',
                fontSize: '0.75rem',
                letterSpacing: '0.5px',
                mb: 1
              }}
            >
              {title}
            </Typography>
            <Typography
              variant="h3"
              sx={{
                color: COLORS.text,
                fontWeight: 700,
                fontSize: '2rem',
                lineHeight: 1.2,
              }}
            >
              {prefix}{formatNumber(value)}{suffix}
            </Typography>
          </Box>
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 52,
              height: 52,
              borderRadius: 2,
              backgroundColor: color === COLORS.primary ? COLORS.green[50] : COLORS.grey[100],
              color: color,
              flexShrink: 0,
            }}
          >
            {React.cloneElement(icon as React.ReactElement, {
              sx: { fontSize: 28 }
            })}
          </Box>
        </Box>

        {growth !== undefined && (
          <Box
            sx={{
              display: 'inline-flex',
              alignItems: 'center',
              backgroundColor: isPositiveGrowth ? COLORS.green[50] : COLORS.grey[100],
              borderRadius: 1,
              px: 1.5,
              py: 0.5,
            }}
          >
            {isPositiveGrowth ? (
              <TrendingUp sx={{ fontSize: 16, color: COLORS.primary, mr: 0.5 }} />
            ) : (
              <TrendingDown sx={{ fontSize: 16, color: COLORS.grey[700], mr: 0.5 }} />
            )}
            <Typography
              variant="body2"
              sx={{
                color: isPositiveGrowth ? COLORS.primary : COLORS.grey[700],
                fontWeight: 700,
                fontSize: '0.875rem',
              }}
            >
              {isPositiveGrowth ? '+' : ''}{growth.toFixed(1)}%
            </Typography>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export default StatCard;
