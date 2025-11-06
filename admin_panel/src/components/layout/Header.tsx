import React, { useState } from 'react';
import {
  Box,
  Flex,
  Input,
  InputGroup,
  InputLeftElement,
  IconButton,
  Avatar,
  Menu,
  MenuButton,
  MenuList,
  MenuItem,
  MenuDivider,
  Badge,
  Text,
  useColorModeValue,
  useToast,
} from '@chakra-ui/react';
import { FiSearch, FiBell, FiLogOut, FiUser, FiSettings } from 'react-icons/fi';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import GlobalSearch from '@/components/common/GlobalSearch';

const Header: React.FC = () => {
  const { adminUser, logout } = useAuth();
  const navigate = useNavigate();
  const toast = useToast();
  const [isSearchOpen, setIsSearchOpen] = useState(false);

  const bgColor = useColorModeValue('white', 'gray.800');
  const borderColor = useColorModeValue('gray.200', 'gray.700');

  const handleLogout = async () => {
    try {
      await logout();
      navigate('/login');
      toast({
        title: 'Logged out successfully',
        status: 'success',
        duration: 3000,
        isClosable: true,
      });
    } catch (error) {
      toast({
        title: 'Error logging out',
        description: 'Please try again',
        status: 'error',
        duration: 3000,
        isClosable: true,
      });
    }
  };

  return (
    <Box
      h="70px"
      bg={bgColor}
      borderBottom="1px"
      borderColor={borderColor}
      px="6"
      position="fixed"
      top="0"
      left="260px"
      right="0"
      zIndex="10"
    >
      <Flex h="full" align="center" justify="space-between">
        {/* Search Bar */}
        <InputGroup maxW="500px">
          <InputLeftElement pointerEvents="none">
            <FiSearch color="gray" />
          </InputLeftElement>
          <Input
            placeholder="Search users, chats, or reports..."
            bg={useColorModeValue('gray.50', 'gray.700')}
            border="none"
            onClick={() => setIsSearchOpen(true)}
            readOnly
            cursor="pointer"
            _focus={{
              bg: useColorModeValue('white', 'gray.600'),
              boxShadow: 'sm',
            }}
          />
        </InputGroup>

        <GlobalSearch isOpen={isSearchOpen} onClose={() => setIsSearchOpen(false)} />

        {/* Right Section */}
        <Flex align="center" gap="3">
          {/* Notifications */}
          <Menu>
            <MenuButton
              as={IconButton}
              icon={<FiBell />}
              variant="ghost"
              position="relative"
            >
              <Badge
                position="absolute"
                top="1"
                right="1"
                colorScheme="red"
                borderRadius="full"
                boxSize="8px"
              />
            </MenuButton>
            <MenuList>
              <Box px="4" py="2">
                <Text fontWeight="bold" fontSize="sm">
                  Notifications
                </Text>
              </Box>
              <MenuDivider />
              <MenuItem>
                <Text fontSize="sm">New report submitted</Text>
              </MenuItem>
              <MenuItem>
                <Text fontSize="sm">User account suspended</Text>
              </MenuItem>
              <MenuItem>
                <Text fontSize="sm" color="gray.500" textAlign="center">
                  View all notifications
                </Text>
              </MenuItem>
            </MenuList>
          </Menu>

          {/* User Menu */}
          <Menu>
            <MenuButton>
              <Flex align="center" gap="2" cursor="pointer">
                <Avatar size="sm" name={adminUser?.displayName} />
              </Flex>
            </MenuButton>
            <MenuList>
              <Box px="4" py="2">
                <Text fontWeight="bold">{adminUser?.displayName}</Text>
                <Text fontSize="sm" color="gray.500">
                  {adminUser?.email}
                </Text>
              </Box>
              <MenuDivider />
              <MenuItem icon={<FiUser />} onClick={() => navigate('/profile')}>
                Profile
              </MenuItem>
              <MenuItem icon={<FiSettings />} onClick={() => navigate('/settings')}>
                Settings
              </MenuItem>
              <MenuDivider />
              <MenuItem icon={<FiLogOut />} onClick={handleLogout} color="red.500">
                Logout
              </MenuItem>
            </MenuList>
          </Menu>
        </Flex>
      </Flex>
    </Box>
  );
};

export default Header;
