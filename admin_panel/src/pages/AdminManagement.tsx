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
  Badge,
  IconButton,
  Menu,
  MenuButton,
  MenuList,
  MenuItem,
  Flex,
  Button,
  useToast,
  Spinner,
  Center,
  Text,
  HStack,
  Avatar,
  useDisclosure,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalCloseButton,
  ModalFooter,
  FormControl,
  FormLabel,
  Input,
  Select,
  VStack,
} from '@chakra-ui/react';
import { FiMoreVertical, FiTrash2, FiRefreshCw, FiUserPlus } from 'react-icons/fi';
import { getAdminUsers, deleteAdminUser } from '@/services/adminService';
import { useAuth } from '@/contexts/AuthContext';
import { AdminUser } from '@/types';
import { formatDate } from '@/utils/helpers';

const AdminManagement: React.FC = () => {
  const [admins, setAdmins] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedAdmin, setSelectedAdmin] = useState<AdminUser | null>(null);
  const [newAdminEmail, setNewAdminEmail] = useState('');
  const [newAdminName, setNewAdminName] = useState('');
  const [newAdminRole, setNewAdminRole] = useState('moderator');

  const { isOpen, onOpen, onClose } = useDisclosure();
  const {
    isOpen: isAddOpen,
    onOpen: onAddOpen,
    onClose: onAddClose,
  } = useDisclosure();

  const { adminUser } = useAuth();
  const toast = useToast();

  useEffect(() => {
    fetchAdmins();
  }, []);

  const fetchAdmins = async () => {
    try {
      setLoading(true);
      const adminList = await getAdminUsers();
      setAdmins(adminList);
    } catch (error) {
      toast({
        title: 'Error loading admins',
        description: 'Failed to fetch admin users',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteAdmin = async (admin: AdminUser) => {
    setSelectedAdmin(admin);
    onOpen();
  };

  const confirmDelete = async () => {
    if (!selectedAdmin) return;

    if (selectedAdmin.uid === adminUser?.uid) {
      toast({
        title: 'Cannot delete',
        description: 'You cannot delete your own account',
        status: 'error',
        duration: 3000,
        isClosable: true,
      });
      return;
    }

    try {
      await deleteAdminUser(selectedAdmin.uid);
      toast({
        title: 'Admin deleted',
        description: `${selectedAdmin.displayName} has been removed`,
        status: 'success',
        duration: 3000,
        isClosable: true,
      });
      fetchAdmins();
      onClose();
    } catch (error) {
      toast({
        title: 'Delete failed',
        description: 'Failed to delete admin user',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

  const handleAddAdmin = async () => {
    if (!newAdminEmail || !newAdminName) {
      toast({
        title: 'Validation Error',
        description: 'Please fill in all fields',
        status: 'error',
        duration: 3000,
        isClosable: true,
      });
      return;
    }

    try {
      toast({
        title: 'Manual Setup Required',
        description:
          'Please create the admin user in Firebase Authentication first, then add them to the admin_users collection in Firestore',
        status: 'info',
        duration: 8000,
        isClosable: true,
      });

      onAddClose();
      setNewAdminEmail('');
      setNewAdminName('');
      setNewAdminRole('moderator');
    } catch (error) {
      toast({
        title: 'Creation failed',
        description: 'Failed to create admin user',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

  const getRoleColor = (role: string): string => {
    switch (role) {
      case 'super_admin':
        return 'red';
      case 'admin':
        return 'orange';
      case 'moderator':
        return 'blue';
      case 'analyst':
        return 'green';
      default:
        return 'gray';
    }
  };

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
            Admin User Management
          </Heading>
          <Text color="gray.600">{admins.length} admin users</Text>
        </Box>
        <HStack>
          <Button leftIcon={<FiUserPlus />} onClick={onAddOpen} colorScheme="brand">
            Add Admin
          </Button>
          <Button leftIcon={<FiRefreshCw />} onClick={fetchAdmins} variant="outline">
            Refresh
          </Button>
        </HStack>
      </Flex>

      {/* Admins Table */}
      <Card>
        <Box overflowX="auto">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>Admin</Th>
                <Th>Email</Th>
                <Th>Role</Th>
                <Th>Created</Th>
                <Th>Last Login</Th>
                <Th>Actions</Th>
              </Tr>
            </Thead>
            <Tbody>
              {admins.map((admin) => (
                <Tr key={admin.uid}>
                  <Td>
                    <HStack spacing="3">
                      <Avatar size="sm" name={admin.displayName} />
                      <Box>
                        <Text fontWeight="medium">{admin.displayName}</Text>
                        {admin.uid === adminUser?.uid && (
                          <Badge colorScheme="green" size="sm">
                            You
                          </Badge>
                        )}
                      </Box>
                    </HStack>
                  </Td>
                  <Td>{admin.email}</Td>
                  <Td>
                    <Badge colorScheme={getRoleColor(admin.role)}>{admin.role}</Badge>
                  </Td>
                  <Td>{formatDate(admin.createdAt)}</Td>
                  <Td>
                    {admin.lastLogin ? formatDate(admin.lastLogin) : (
                      <Text color="gray.400">Never</Text>
                    )}
                  </Td>
                  <Td>
                    <Menu>
                      <MenuButton
                        as={IconButton}
                        icon={<FiMoreVertical />}
                        variant="ghost"
                        size="sm"
                        isDisabled={admin.uid === adminUser?.uid}
                      />
                      <MenuList>
                        <MenuItem
                          icon={<FiTrash2 />}
                          color="red.500"
                          onClick={() => handleDeleteAdmin(admin)}
                        >
                          Delete Admin
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

      {/* Delete Confirmation Modal */}
      <Modal isOpen={isOpen} onClose={onClose}>
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>Delete Admin User</ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            <Text>
              Are you sure you want to delete <strong>{selectedAdmin?.displayName}</strong>? This
              action cannot be undone.
            </Text>
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" mr={3} onClick={onClose}>
              Cancel
            </Button>
            <Button colorScheme="red" onClick={confirmDelete}>
              Delete
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>

      {/* Add Admin Modal */}
      <Modal isOpen={isAddOpen} onClose={onAddClose}>
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>Add New Admin</ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            <VStack spacing="4">
              <FormControl isRequired>
                <FormLabel>Email</FormLabel>
                <Input
                  type="email"
                  placeholder="admin@crypted.com"
                  value={newAdminEmail}
                  onChange={(e) => setNewAdminEmail(e.target.value)}
                />
              </FormControl>

              <FormControl isRequired>
                <FormLabel>Display Name</FormLabel>
                <Input
                  placeholder="John Doe"
                  value={newAdminName}
                  onChange={(e) => setNewAdminName(e.target.value)}
                />
              </FormControl>

              <FormControl isRequired>
                <FormLabel>Role</FormLabel>
                <Select value={newAdminRole} onChange={(e) => setNewAdminRole(e.target.value)}>
                  <option value="moderator">Moderator</option>
                  <option value="analyst">Analyst</option>
                  <option value="admin">Admin</option>
                  <option value="super_admin">Super Admin</option>
                </Select>
              </FormControl>

              <Box w="full" p="3" bg="blue.50" borderRadius="md">
                <Text fontSize="sm" color="blue.800">
                  <strong>Note:</strong> You must first create this user in Firebase Authentication,
                  then manually add them to the admin_users collection in Firestore.
                </Text>
              </Box>
            </VStack>
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" mr={3} onClick={onAddClose}>
              Cancel
            </Button>
            <Button colorScheme="brand" onClick={handleAddAdmin}>
              View Instructions
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </Box>
  );
};

export default AdminManagement;
