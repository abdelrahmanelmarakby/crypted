import React from 'react';
import { Box } from '@chakra-ui/react';
import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import Header from './Header';

const Layout: React.FC = () => {
  return (
    <Box minH="100vh">
      <Sidebar />
      <Box ml="260px">
        <Header />
        <Box mt="70px" p="6">
          <Outlet />
        </Box>
      </Box>
    </Box>
  );
};

export default Layout;
