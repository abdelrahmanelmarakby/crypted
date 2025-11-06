import React from 'react';
import {
  Box,
  VStack,
  Flex,
  Icon,
  Text,
  Avatar,
  Divider,
  useColorModeValue,
} from '@chakra-ui/react';
import { NavLink, useLocation } from 'react-router-dom';
import {
  FiHome,
  FiUsers,
  FiMessageSquare,
  FiImage,
  FiAlertCircle,
  FiBarChart2,
  FiSettings,
  FiFileText,
  FiPhone,
  FiBell,
  FiUserCheck,
} from 'react-icons/fi';
import { useAuth } from '@/contexts/AuthContext';

interface NavItemProps {
  icon: any;
  label: string;
  to: string;
}

const NavItem: React.FC<NavItemProps> = ({ icon, label, to }) => {
  const location = useLocation();
  const isActive = location.pathname === to || location.pathname.startsWith(to + '/');

  const activeBg = useColorModeValue('brand.50', 'brand.900');
  const activeColor = useColorModeValue('brand.600', 'brand.200');
  const hoverBg = useColorModeValue('gray.100', 'gray.700');

  return (
    <NavLink to={to} style={{ width: '100%' }}>
      <Flex
        align="center"
        px="4"
        py="3"
        borderRadius="lg"
        cursor="pointer"
        bg={isActive ? activeBg : 'transparent'}
        color={isActive ? activeColor : 'inherit'}
        _hover={{
          bg: isActive ? activeBg : hoverBg,
        }}
        transition="all 0.2s"
      >
        <Icon as={icon} fontSize="20" mr="3" />
        <Text fontSize="md" fontWeight={isActive ? 'semibold' : 'medium'}>
          {label}
        </Text>
      </Flex>
    </NavLink>
  );
};

const Sidebar: React.FC = () => {
  const { adminUser } = useAuth();
  const bgColor = useColorModeValue('white', 'gray.800');
  const borderColor = useColorModeValue('gray.200', 'gray.700');

  return (
    <Box
      w="260px"
      h="100vh"
      bg={bgColor}
      borderRight="1px"
      borderColor={borderColor}
      position="fixed"
      left="0"
      top="0"
      overflowY="auto"
      css={{
        '&::-webkit-scrollbar': {
          width: '4px',
        },
        '&::-webkit-scrollbar-track': {
          width: '6px',
        },
        '&::-webkit-scrollbar-thumb': {
          background: '#CBD5E0',
          borderRadius: '24px',
        },
      }}
    >
      <Flex direction="column" h="full" py="4">
        {/* Logo */}
        <Flex align="center" px="6" mb="6">
          <Avatar
            size="sm"
            name="Crypted"
            bg="brand.500"
            color="white"
            mr="3"
            src="/logo.png"
          />
          <Box>
            <Text fontSize="lg" fontWeight="bold" color="brand.500">
              Crypted
            </Text>
            <Text fontSize="xs" color="gray.500">
              Admin Panel
            </Text>
          </Box>
        </Flex>

        <Divider mb="4" />

        {/* Navigation */}
        <VStack spacing="1" px="3" flex="1">
          <NavItem icon={FiHome} label="Dashboard" to="/" />
          <NavItem icon={FiUsers} label="Users" to="/users" />
          <NavItem icon={FiMessageSquare} label="Chats" to="/chats" />
          <NavItem icon={FiImage} label="Stories" to="/stories" />
          <NavItem icon={FiAlertCircle} label="Reports" to="/reports" />
          <NavItem icon={FiPhone} label="Calls" to="/calls" />
          <NavItem icon={FiBarChart2} label="Analytics" to="/analytics" />
          <NavItem icon={FiBell} label="Notifications" to="/notifications" />
          <NavItem icon={FiFileText} label="Logs" to="/logs" />
          <NavItem icon={FiUserCheck} label="Admins" to="/admin-management" />
          <NavItem icon={FiSettings} label="Settings" to="/settings" />
        </VStack>

        <Divider my="4" />

        {/* User Info */}
        <Flex px="6" align="center">
          <Avatar size="sm" name={adminUser?.displayName} mr="3" />
          <Box flex="1" overflow="hidden">
            <Text fontSize="sm" fontWeight="medium" noOfLines={1}>
              {adminUser?.displayName}
            </Text>
            <Text fontSize="xs" color="gray.500" noOfLines={1}>
              {adminUser?.role}
            </Text>
          </Box>
        </Flex>
      </Flex>
    </Box>
  );
};

export default Sidebar;
