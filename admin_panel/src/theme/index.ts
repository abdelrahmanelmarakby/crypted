import { extendTheme, type ThemeConfig } from '@chakra-ui/react';

const config: ThemeConfig = {
  initialColorMode: 'light',
  useSystemColorMode: false,
};

const theme = extendTheme({
  config,
  colors: {
    brand: {
      50: '#e6f7ed',
      100: '#b3e6c9',
      200: '#80d5a5',
      300: '#4dc481',
      400: '#31a354', // Primary color from Crypted app
      500: '#2a8d48',
      600: '#23773c',
      700: '#1c6130',
      800: '#154b24',
      900: '#0e3518',
    },
    primary: '#31A354',
    secondary: '#2C3E50',
  },
  fonts: {
    heading: `'IBM Plex Sans Arabic', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`,
    body: `'IBM Plex Sans Arabic', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`,
  },
  components: {
    Button: {
      defaultProps: {
        colorScheme: 'brand',
      },
    },
    Link: {
      baseStyle: {
        _hover: {
          textDecoration: 'none',
        },
      },
    },
  },
  styles: {
    global: {
      body: {
        bg: 'gray.50',
        color: 'gray.800',
      },
    },
  },
});

export default theme;
