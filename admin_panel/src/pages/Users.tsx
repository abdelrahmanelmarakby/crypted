import React, { useEffect, useState } from 'react';
import {
  Box,
  Heading,
  Card,
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  Avatar,
  Badge,
  IconButton,
  Menu,
  MenuButton,
  MenuList,
  MenuItem,
  Input,
  InputGroup,
  InputLeftElement,
  Flex,
  Button,
  useToast,
  Spinner,
  Center,
  Text,
  HStack,
  useDisclosure,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalCloseButton,
  ModalFooter,
  Select,
} from '@chakra-ui/react';
import { FiSearch, FiMoreVertical, FiEye, FiUserX, FiTrash2, FiRefreshCw, FiDownload } from 'react-icons/fi';
import { useNavigate } from 'react-router-dom';
import { getUsers, updateUserStatus, deleteUser } from '@/services/userService';
import { User } from '@/types';
import { formatDate, formatRelativeTime, getStatusColor, debounce } from '@/utils/helpers';
import { exportToCSV, prepareUserDataForExport } from '@/utils/exportUtils';

const Users: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [actionType, setActionType] = useState<'suspend' | 'delete' | null>(null);

  const { isOpen, onOpen, onClose } = useDisclosure();
  const navigate = useNavigate();
  const toast = useToast();

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const { users: fetchedUsers } = await getUsers(100);
      setUsers(fetchedUsers);
    } catch (error) {
      toast({
        title: 'Error loading users',
        description: 'Failed to fetch users',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = debounce((value: string) => {
    setSearchTerm(value);
    // Implement search logic
  }, 300);

  const handleSuspendUser = async (user: User) => {
    setSelectedUser(user);
    setActionType('suspend');
    onOpen();
  };

  const handleDeleteUser = async (user: User) => {
    setSelectedUser(user);
    setActionType('delete');
    onOpen();
  };

  const handleExport = () => {
    const exportData = prepareUserDataForExport(users);
    exportToCSV(exportData, 'users');
    toast({
      title: 'Export successful',
      description: 'User data has been exported',
      status: 'success',
      duration: 3000,
      isClosable: true,
    });
  };

  const confirmAction = async () => {
    if (!selectedUser) return;

    try {
      if (actionType === 'suspend') {
        await updateUserStatus(selectedUser.uid, 'suspended');
        toast({
          title: 'User suspended',
          description: `${selectedUser.full_name} has been suspended`,
          status: 'success',
          duration: 3000,
          isClosable: true,
        });
      } else if (actionType === 'delete') {
        await deleteUser(selectedUser.uid);
        toast({
          title: 'User deleted',
          description: `${selectedUser.full_name} has been deleted`,
          status: 'success',
          duration: 3000,
          isClosable: true,
        });
      }

      fetchUsers();
      onClose();
    } catch (error) {
      toast({
        title: 'Action failed',
        description: 'Failed to perform action',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

  const filteredUsers = users.filter(
    (user) =>
      user.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <Center h="50vh">
        <Spinner size="xl" color="brand.500" thickness="4px" />
      </Center>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Flex justify="space-between" align="center" mb="6">
        <Box>
          <Heading size="lg" mb="2">
            User Management
          </Heading>
          <Text color="gray.600">{users.length} total users</Text>
        </Box>
        <HStack>
          <Button leftIcon={<FiDownload />} onClick={handleExport} variant="outline">
            Export
          </Button>
          <Button leftIcon={<FiRefreshCw />} onClick={fetchUsers} colorScheme="brand">
            Refresh
          </Button>
        </HStack>
      </Flex>

      {/* Search and Filters */}
      <Card mb="6" p="4">
        <Flex gap="4">
          <InputGroup maxW="400px">
            <InputLeftElement>
              <FiSearch />
            </InputLeftElement>
            <Input
              placeholder="Search by name or email..."
              onChange={(e) => handleSearch(e.target.value)}
            />
          </InputGroup>
          <Select placeholder="All Status" maxW="200px">
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
            <option value="deleted">Deleted</option>
          </Select>
        </Flex>
      </Card>

      {/* Users Table */}
      <Card>
        <Box overflowX="auto">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>User</Th>
                <Th>Email</Th>
                <Th>Phone</Th>
                <Th>Joined</Th>
                <Th>Last Seen</Th>
                <Th>Status</Th>
                <Th>Actions</Th>
              </Tr>
            </Thead>
            <Tbody>
              {filteredUsers.map((user) => (
                <Tr key={user.uid}>
                  <Td>
                    <HStack spacing="3">
                      <Avatar size="sm" name={user.full_name} src={user.image_url} />
                      <Text fontWeight="medium">{user.full_name}</Text>
                    </HStack>
                  </Td>
                  <Td>{user.email}</Td>
                  <Td>{user.phoneNumber || 'N/A'}</Td>
                  <Td>{user.createdAt ? formatDate(user.createdAt) : 'N/A'}</Td>
                  <Td>
                    {user.isOnline ? (
                      <Badge colorScheme="green">Online</Badge>
                    ) : (
                      formatRelativeTime(user.lastSeen)
                    )}
                  </Td>
                  <Td>
                    <Badge colorScheme={getStatusColor(user.status || 'active')}>
                      {user.status || 'active'}
                    </Badge>
                  </Td>
                  <Td>
                    <Menu>
                      <MenuButton
                        as={IconButton}
                        icon={<FiMoreVertical />}
                        variant="ghost"
                        size="sm"
                      />
                      <MenuList>
                        <MenuItem
                          icon={<FiEye />}
                          onClick={() => navigate(`/users/${user.uid}`)}
                        >
                          View Details
                        </MenuItem>
                        <MenuItem
                          icon={<FiUserX />}
                          onClick={() => handleSuspendUser(user)}
                          isDisabled={user.status === 'suspended'}
                        >
                          Suspend User
                        </MenuItem>
                        <MenuItem
                          icon={<FiTrash2 />}
                          color="red.500"
                          onClick={() => handleDeleteUser(user)}
                        >
                          Delete User
                        </MenuItem>
                      </MenuList>
                    </Menu>
                  </Td>
                </Tr>
              ))}
            </Tbody>
          </Table>
        </Box>
      </Card>

      {/* Confirmation Modal */}
      <Modal isOpen={isOpen} onClose={onClose}>
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>
            {actionType === 'suspend' ? 'Suspend User' : 'Delete User'}
          </ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            <Text>
              Are you sure you want to {actionType} <strong>{selectedUser?.full_name}</strong>?
              This action cannot be undone.
            </Text>
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" mr={3} onClick={onClose}>
              Cancel
            </Button>
            <Button colorScheme="red" onClick={confirmAction}>
              {actionType === 'suspend' ? 'Suspend' : 'Delete'}
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </Box>
  );
};

export default Users;
