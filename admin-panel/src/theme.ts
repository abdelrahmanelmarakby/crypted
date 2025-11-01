import { createTheme } from '@mui/material/styles';
import { COLORS } from './utils/constants';

export const theme = createTheme({
  palette: {
    primary: {
      main: COLORS.primary,
      light: COLORS.green[400],
      dark: COLORS.green[700],
      contrastText: COLORS.white,
    },
    secondary: {
      main: COLORS.grey[800],
      contrastText: COLORS.white,
    },
    success: {
      main: COLORS.success,
    },
    warning: {
      main: COLORS.grey[600],
    },
    error: {
      main: COLORS.grey[900],
    },
    background: {
      default: COLORS.grey[50],
      paper: COLORS.white,
    },
    text: {
      primary: COLORS.text,
      secondary: COLORS.grey[600],
    },
  },
  typography: {
    fontFamily: '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif',
    h1: {
      fontSize: '2.75rem',
      fontWeight: 700,
      letterSpacing: '-0.02em',
      color: COLORS.text,
    },
    h2: {
      fontSize: '2.25rem',
      fontWeight: 700,
      letterSpacing: '-0.02em',
      color: COLORS.text,
    },
    h3: {
      fontSize: '1.875rem',
      fontWeight: 700,
      letterSpacing: '-0.01em',
      color: COLORS.text,
    },
    h4: {
      fontSize: '1.5rem',
      fontWeight: 700,
      letterSpacing: '-0.01em',
      color: COLORS.text,
    },
    h5: {
      fontSize: '1.25rem',
      fontWeight: 600,
      color: COLORS.text,
    },
    h6: {
      fontSize: '1.125rem',
      fontWeight: 600,
      color: COLORS.text,
    },
    button: {
      fontWeight: 600,
      textTransform: 'none',
      letterSpacing: '0.02em',
    },
    body1: {
      fontSize: '1rem',
      lineHeight: 1.6,
    },
    body2: {
      fontSize: '0.875rem',
      lineHeight: 1.5,
    },
  },
  shape: {
    borderRadius: 8,
  },
  shadows: [
    'none',
    'none',
    'none',
    'none',
    'none',
    'none',
    ...Array(19).fill('none'),
  ] as any,
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 600,
          borderRadius: 6,
          padding: '10px 20px',
          boxShadow: 'none',
          transition: 'all 0.2s ease',
          '&:hover': {
            boxShadow: 'none',
            transform: 'translateY(-1px)',
          },
        },
        contained: {
          '&:hover': {
            boxShadow: 'none',
          },
        },
        outlined: {
          borderWidth: '2px',
          '&:hover': {
            borderWidth: '2px',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: 'none',
          border: `1px solid ${COLORS.grey[200]}`,
          borderRadius: 8,
          transition: 'all 0.2s ease',
          '&:hover': {
            boxShadow: 'none',
            borderColor: COLORS.grey[300],
          },
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          boxShadow: 'none',
          border: `1px solid ${COLORS.grey[200]}`,
        },
        elevation0: {
          border: 'none',
        },
        elevation1: {
          boxShadow: 'none',
          border: `1px solid ${COLORS.grey[200]}`,
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          boxShadow: 'none',
          borderBottom: `1px solid ${COLORS.grey[200]}`,
          backgroundColor: COLORS.white,
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontWeight: 500,
          borderRadius: 6,
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        root: {
          borderBottom: `1px solid ${COLORS.grey[200]}`,
        },
      },
    },
    MuiDivider: {
      styleOverrides: {
        root: {
          borderColor: COLORS.grey[200],
        },
      },
    },
  },
});
