import React from 'react';
import { Box, keyframes } from '@mui/material';
import { COLORS } from '../../utils/constants';

interface LoadingSpinnerProps {
  fullScreen?: boolean;
  size?: 'small' | 'medium' | 'large';
}

const pulse = keyframes`
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.5;
    transform: scale(0.8);
  }
`;

const spin = keyframes`
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
`;

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  fullScreen = false,
  size = 'medium'
}) => {
  const sizeMap = {
    small: 40,
    medium: 60,
    large: 80,
  };

  const spinnerSize = sizeMap[size];

  return (
    <Box
      sx={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: fullScreen ? '100vh' : '200px',
        backgroundColor: fullScreen ? COLORS.grey[100] : 'transparent',
      }}
    >
      <Box sx={{ position: 'relative', width: spinnerSize, height: spinnerSize }}>
        {/* Outer rotating ring */}
        <Box
          sx={{
            position: 'absolute',
            width: '100%',
            height: '100%',
            border: `3px solid ${COLORS.grey[200]}`,
            borderTop: `3px solid ${COLORS.primary}`,
            borderRadius: '50%',
            animation: `${spin} 1s linear infinite`,
          }}
        />

        {/* Inner pulsing circle */}
        <Box
          sx={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            width: '50%',
            height: '50%',
            backgroundColor: COLORS.primary,
            borderRadius: '50%',
            animation: `${pulse} 1.5s ease-in-out infinite`,
          }}
        />
      </Box>
    </Box>
  );
};

export default LoadingSpinner;
