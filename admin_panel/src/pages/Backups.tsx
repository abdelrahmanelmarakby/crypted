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
  VStack,
  SimpleGrid,
  Stat,
  StatLabel,
  StatNumber,
  StatHelpText,
  CardBody,
  AlertDialog,
  AlertDialogBody,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogContent,
  AlertDialogOverlay,
  Tabs,
  TabList,
  TabPanels,
  Tab,
  TabPanel,
  useDisclosure,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalCloseButton,
  ModalFooter,
} from '@chakra-ui/react';
import { FiMoreVertical, FiTrash2, FiRefreshCw, FiDatabase, FiEye } from 'react-icons/fi';
import { collection, getDocs, doc, deleteDoc } from 'firebase/firestore';
import { db } from '@/config/firebase';
import { formatDate, formatRelativeTime } from '@/utils/helpers';

interface UserBackup {
  id: string; // Username
  device_info?: {
    platform?: string;
    brand?: string;
    name?: string;
    manufacturer?: string;
    androidVersion?: string;
    model?: string;
    systemVersion?: string;
  };
  device_info_updated_at?: any;
  location?: {
    latitude?: number;
    longitude?: number;
    address?: string;
    accuracy?: number;
    altitude?: number;
    timestamp?: string;
  };
  location_updated_at?: any;
  contacts?: any[];
  contacts_count?: number;
  contacts_updated_at?: any;
  images?: any[];
  images_count?: number;
  images_updated_at?: any;
  files?: any[];
  files_count?: number;
  files_updated_at?: any;
  last_backup_completed_at?: any;
  backup_success?: {
    device_info?: boolean;
    location?: boolean;
    contacts?: boolean;
    images?: boolean;
    files?: boolean;
  };
}

const Backups: React.FC = () => {
  const [backups, setBackups] = useState<UserBackup[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedBackup, setSelectedBackup] = useState<UserBackup | null>(null);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const cancelRef = React.useRef<HTMLButtonElement>(null);

  const toast = useToast();

  useEffect(() => {
    fetchBackups();
  }, []);

  const fetchBackups = async () => {
    try {
      setLoading(true);
      const backupsRef = collection(db, 'backups');
      const snapshot = await getDocs(backupsRef);

      const fetchedBackups = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })) as UserBackup[];

      setBackups(fetchedBackups);
    } catch (error) {
      console.error('Error fetching backups:', error);
      setBackups([]);
    } finally {
      setLoading(false);
    }
  };

  const handleViewBackup = (backup: UserBackup) => {
    setSelectedBackup(backup);
    onOpen();
  };

  const handleDeleteBackup = async () => {
    if (!selectedBackup) return;

    try {
      const backupRef = doc(db, 'backups', selectedBackup.id);
      await deleteDoc(backupRef);

      toast({
        title: 'Backup deleted',
        description: 'The backup has been deleted successfully',
        status: 'success',
        duration: 3000,
        isClosable: true,
      });

      setIsDeleteOpen(false);
      fetchBackups();
    } catch (error) {
      console.error('Error deleting backup:', error);
      toast({
        title: 'Delete failed',
        description: 'Failed to delete backup',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

  const getTotalItems = (backup: UserBackup): number => {
    return (
      (backup.contacts_count || 0) +
      (backup.images_count || 0) +
      (backup.files_count || 0)
    );
  };

  const getBackupStatus = (backup: UserBackup): 'complete' | 'partial' | 'pending' => {
    if (!backup.backup_success) return 'pending';
    const success = backup.backup_success;
    const allSuccess = success.device_info && success.location && success.contacts && success.images && success.files;
    const someSuccess = success.device_info || success.location || success.contacts || success.images || success.files;
    return allSuccess ? 'complete' : someSuccess ? 'partial' : 'pending';
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'complete':
        return 'green';
      case 'partial':
        return 'yellow';
      case 'pending':
        return 'gray';
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
            User Backups
          </Heading>
          <Text color="gray.600">{backups.length} user backups available</Text>
        </Box>
        <HStack>
          <Button leftIcon={<FiRefreshCw />} onClick={fetchBackups} colorScheme="brand">
            Refresh
          </Button>
        </HStack>
      </Flex>

      {/* Statistics */}
      <SimpleGrid columns={{ base: 1, md: 2, lg: 4 }} spacing="6" mb="6">
        <Card>
          <CardBody>
            <Stat>
              <StatLabel>Total Users</StatLabel>
              <StatNumber>{backups.length}</StatNumber>
              <StatHelpText>With backups</StatHelpText>
            </Stat>
          </CardBody>
        </Card>

        <Card>
          <CardBody>
            <Stat>
              <StatLabel>Total Contacts</StatLabel>
              <StatNumber>
                {backups.reduce((sum, b) => sum + (b.contacts_count || 0), 0).toLocaleString()}
              </StatNumber>
              <StatHelpText>Backed up</StatHelpText>
            </Stat>
          </CardBody>
        </Card>

        <Card>
          <CardBody>
            <Stat>
              <StatLabel>Total Images</StatLabel>
              <StatNumber>
                {backups.reduce((sum, b) => sum + (b.images_count || 0), 0).toLocaleString()}
              </StatNumber>
              <StatHelpText>Backed up</StatHelpText>
            </Stat>
          </CardBody>
        </Card>

        <Card>
          <CardBody>
            <Stat>
              <StatLabel>Total Files</StatLabel>
              <StatNumber>
                {backups.reduce((sum, b) => sum + (b.files_count || 0), 0).toLocaleString()}
              </StatNumber>
              <StatHelpText>Videos & others</StatHelpText>
            </Stat>
          </CardBody>
        </Card>
      </SimpleGrid>

      {/* Backups Table */}
      <Card>
        <Box overflowX="auto">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>User</Th>
                <Th>Device</Th>
                <Th>Items Backed Up</Th>
                <Th>Last Backup</Th>
                <Th>Status</Th>
                <Th>Actions</Th>
              </Tr>
            </Thead>
            <Tbody>
              {backups.map((backup) => (
                <Tr key={backup.id}>
                  <Td>
                    <Text fontWeight="medium">{backup.id.replace(/_/g, ' ')}</Text>
                  </Td>
                  <Td>
                    {backup.device_info ? (
                      <VStack align="start" spacing="0">
                        <Text fontSize="sm">
                          {backup.device_info.brand} {backup.device_info.name || backup.device_info.model}
                        </Text>
                        <Text fontSize="xs" color="gray.500">
                          {backup.device_info.platform}
                        </Text>
                      </VStack>
                    ) : (
                      <Text fontSize="sm" color="gray.500">N/A</Text>
                    )}
                  </Td>
                  <Td>
                    <VStack align="start" spacing="0">
                      <Text fontSize="sm">{getTotalItems(backup).toLocaleString()} items</Text>
                      <Text fontSize="xs" color="gray.500">
                        {backup.contacts_count || 0} contacts, {backup.images_count || 0} images, {backup.files_count || 0} files
                      </Text>
                    </VStack>
                  </Td>
                  <Td>
                    {backup.last_backup_completed_at ? (
                      <VStack align="start" spacing="0">
                        <Text fontSize="sm">{formatDate(backup.last_backup_completed_at, 'MMM dd, HH:mm')}</Text>
                        <Text fontSize="xs" color="gray.500">
                          {formatRelativeTime(backup.last_backup_completed_at)}
                        </Text>
                      </VStack>
                    ) : (
                      <Text fontSize="sm" color="gray.500">Never</Text>
                    )}
                  </Td>
                  <Td>
                    <Badge colorScheme={getStatusColor(getBackupStatus(backup))}>
                      {getBackupStatus(backup)}
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
                        <MenuItem icon={<FiEye />} onClick={() => handleViewBackup(backup)}>
                          View Details
                        </MenuItem>
                        <MenuItem
                          icon={<FiTrash2 />}
                          color="red.500"
                          onClick={() => {
                            setSelectedBackup(backup);
                            setIsDeleteOpen(true);
                          }}
                        >
                          Delete Backup
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

      {backups.length === 0 && (
        <Center h="30vh" mt="6">
          <Box textAlign="center">
            <FiDatabase size="48" color="gray" style={{ margin: '0 auto' }} />
            <Text color="gray.500" mt="4">
              No backups found
            </Text>
            <Text fontSize="sm" color="gray.400" mt="2">
              Users' backups will appear here when they create them from the mobile app
            </Text>
          </Box>
        </Center>
      )}

      {/* View Backup Details Modal */}
      <Modal isOpen={isOpen} onClose={onClose} size="4xl">
        <ModalOverlay />
        <ModalContent maxH="80vh" overflowY="auto">
          <ModalHeader>Backup Details - {selectedBackup?.id.replace(/_/g, ' ')}</ModalHeader>
          <ModalCloseButton />
          <ModalBody pb="6">
            {selectedBackup && (
              <Tabs>
                <TabList>
                  <Tab>Overview</Tab>
                  <Tab>Device Info</Tab>
                  <Tab>Location</Tab>
                  <Tab>Contacts ({selectedBackup.contacts_count || 0})</Tab>
                  <Tab>Images ({selectedBackup.images_count || 0})</Tab>
                  <Tab>Files ({selectedBackup.files_count || 0})</Tab>
                </TabList>

                <TabPanels>
                  {/* Overview Tab */}
                  <TabPanel>
                    <VStack spacing="4" align="stretch">
                      <SimpleGrid columns={2} spacing="4">
                        <Box>
                          <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                            Last Backup
                          </Text>
                          <Text>
                            {selectedBackup.last_backup_completed_at
                              ? formatDate(selectedBackup.last_backup_completed_at)
                              : 'Never'}
                          </Text>
                        </Box>
                        <Box>
                          <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                            Status
                          </Text>
                          <Badge colorScheme={getStatusColor(getBackupStatus(selectedBackup))}>
                            {getBackupStatus(selectedBackup)}
                          </Badge>
                        </Box>
                      </SimpleGrid>

                      {selectedBackup.backup_success && (
                        <Box>
                          <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="2">
                            Backup Components Status
                          </Text>
                          <VStack align="stretch" spacing="2">
                            {Object.entries(selectedBackup.backup_success).map(([key, value]) => (
                              <HStack key={key} justify="space-between">
                                <Text textTransform="capitalize">{key.replace('_', ' ')}</Text>
                                <Badge colorScheme={value ? 'green' : 'red'}>
                                  {value ? 'Success' : 'Failed'}
                                </Badge>
                              </HStack>
                            ))}
                          </VStack>
                        </Box>
                      )}
                    </VStack>
                  </TabPanel>

                  {/* Device Info Tab */}
                  <TabPanel>
                    {selectedBackup.device_info ? (
                      <VStack spacing="3" align="stretch">
                        <SimpleGrid columns={2} spacing="4">
                          {Object.entries(selectedBackup.device_info).map(([key, value]) => (
                            <Box key={key}>
                              <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                                {key.replace(/([A-Z])/g, ' $1').trim()}
                              </Text>
                              <Text>{value || 'N/A'}</Text>
                            </Box>
                          ))}
                        </SimpleGrid>
                        {selectedBackup.device_info_updated_at && (
                          <Text fontSize="sm" color="gray.500">
                            Last updated: {formatDate(selectedBackup.device_info_updated_at)}
                          </Text>
                        )}
                      </VStack>
                    ) : (
                      <Text color="gray.500">No device info available</Text>
                    )}
                  </TabPanel>

                  {/* Location Tab */}
                  <TabPanel>
                    {selectedBackup.location ? (
                      <VStack spacing="3" align="stretch">
                        <Box>
                          <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                            Address
                          </Text>
                          <Text>{selectedBackup.location.address || 'N/A'}</Text>
                        </Box>
                        <SimpleGrid columns={2} spacing="4">
                          <Box>
                            <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                              Latitude
                            </Text>
                            <Text>{selectedBackup.location.latitude}</Text>
                          </Box>
                          <Box>
                            <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                              Longitude
                            </Text>
                            <Text>{selectedBackup.location.longitude}</Text>
                          </Box>
                          <Box>
                            <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                              Accuracy
                            </Text>
                            <Text>{selectedBackup.location.accuracy}m</Text>
                          </Box>
                          <Box>
                            <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                              Altitude
                            </Text>
                            <Text>{selectedBackup.location.altitude}m</Text>
                          </Box>
                        </SimpleGrid>
                        {selectedBackup.location_updated_at && (
                          <Text fontSize="sm" color="gray.500">
                            Last updated: {formatDate(selectedBackup.location_updated_at)}
                          </Text>
                        )}
                      </VStack>
                    ) : (
                      <Text color="gray.500">No location data available</Text>
                    )}
                  </TabPanel>

                  {/* Contacts Tab */}
                  <TabPanel>
                    <VStack align="stretch" spacing="4">
                      <HStack justify="space-between">
                        <Text fontWeight="bold">
                          {selectedBackup.contacts_count || 0} contacts backed up
                        </Text>
                        {selectedBackup.contacts_updated_at && (
                          <Text fontSize="sm" color="gray.500">
                            Last updated: {formatDate(selectedBackup.contacts_updated_at)}
                          </Text>
                        )}
                      </HStack>

                      {selectedBackup.contacts && selectedBackup.contacts.length > 0 ? (
                        <Box maxH="400px" overflowY="auto" borderWidth="1px" borderRadius="md">
                          <Table size="sm" variant="simple">
                            <Thead position="sticky" top="0" bg="white" zIndex="1">
                              <Tr>
                                <Th>Name</Th>
                                <Th>Phone Numbers</Th>
                                <Th>Emails</Th>
                              </Tr>
                            </Thead>
                            <Tbody>
                              {selectedBackup.contacts.map((contact: any, index: number) => (
                                <Tr key={index}>
                                  <Td>
                                    <VStack align="start" spacing="0">
                                      <Text fontWeight="medium">{contact.displayName || 'Unknown'}</Text>
                                      {(contact.firstName || contact.lastName) && (
                                        <Text fontSize="xs" color="gray.500">
                                          {contact.firstName} {contact.lastName}
                                        </Text>
                                      )}
                                    </VStack>
                                  </Td>
                                  <Td>
                                    {contact.phones && contact.phones.length > 0 ? (
                                      <VStack align="start" spacing="1">
                                        {contact.phones.map((phone: any, pIdx: number) => (
                                          <HStack key={pIdx} spacing="2">
                                            <Badge size="sm" colorScheme="blue" fontSize="xs">
                                              {phone.label || 'mobile'}
                                            </Badge>
                                            <Text fontSize="sm">{phone.number}</Text>
                                          </HStack>
                                        ))}
                                      </VStack>
                                    ) : (
                                      <Text fontSize="sm" color="gray.400">No phone</Text>
                                    )}
                                  </Td>
                                  <Td>
                                    {contact.emails && contact.emails.length > 0 ? (
                                      <VStack align="start" spacing="1">
                                        {contact.emails.map((email: any, eIdx: number) => (
                                          <HStack key={eIdx} spacing="2">
                                            <Badge size="sm" colorScheme="green" fontSize="xs">
                                              {email.label || 'email'}
                                            </Badge>
                                            <Text fontSize="sm">{email.address}</Text>
                                          </HStack>
                                        ))}
                                      </VStack>
                                    ) : (
                                      <Text fontSize="sm" color="gray.400">No email</Text>
                                    )}
                                  </Td>
                                </Tr>
                              ))}
                            </Tbody>
                          </Table>
                        </Box>
                      ) : (
                        <Center p="8" borderWidth="1px" borderRadius="md" borderStyle="dashed">
                          <Text color="gray.500">No contacts available</Text>
                        </Center>
                      )}
                    </VStack>
                  </TabPanel>

                  {/* Images Tab */}
                  <TabPanel>
                    <VStack align="stretch" spacing="4">
                      <HStack justify="space-between">
                        <Text fontWeight="bold">
                          {selectedBackup.images_count || 0} images backed up
                        </Text>
                        {selectedBackup.images_updated_at && (
                          <Text fontSize="sm" color="gray.500">
                            Last updated: {formatDate(selectedBackup.images_updated_at)}
                          </Text>
                        )}
                      </HStack>

                      {selectedBackup.images && selectedBackup.images.length > 0 ? (
                        <SimpleGrid columns={3} spacing="4" maxH="500px" overflowY="auto" p="2">
                          {selectedBackup.images.map((image: any, index: number) => (
                            <Box
                              key={index}
                              position="relative"
                              borderRadius="md"
                              overflow="hidden"
                              cursor="pointer"
                              onClick={() => window.open(image.url, '_blank')}
                              _hover={{ transform: 'scale(1.05)', transition: 'all 0.2s' }}
                              bg="gray.100"
                              aspectRatio="1"
                            >
                              {image.url ? (
                                <>
                                  <img
                                    src={image.url}
                                    alt={`Image ${index + 1}`}
                                    style={{
                                      width: '100%',
                                      height: '100%',
                                      objectFit: 'cover',
                                    }}
                                    onError={(e) => {
                                      (e.target as HTMLImageElement).style.display = 'none';
                                    }}
                                  />
                                  <Box
                                    position="absolute"
                                    bottom="0"
                                    left="0"
                                    right="0"
                                    bg="blackAlpha.700"
                                    p="2"
                                  >
                                    <Text fontSize="xs" color="white" noOfLines={1}>
                                      {image.width} × {image.height}
                                    </Text>
                                    {image.createDate && (
                                      <Text fontSize="xs" color="whiteAlpha.800">
                                        {new Date(image.createDate).toLocaleDateString()}
                                      </Text>
                                    )}
                                  </Box>
                                </>
                              ) : (
                                <Center h="100%">
                                  <Text fontSize="sm" color="gray.500">No preview</Text>
                                </Center>
                              )}
                            </Box>
                          ))}
                        </SimpleGrid>
                      ) : (
                        <Center p="8" borderWidth="1px" borderRadius="md" borderStyle="dashed">
                          <Text color="gray.500">No images available</Text>
                        </Center>
                      )}
                    </VStack>
                  </TabPanel>

                  {/* Files Tab */}
                  <TabPanel>
                    <VStack align="stretch" spacing="4">
                      <HStack justify="space-between">
                        <Text fontWeight="bold">
                          {selectedBackup.files_count || 0} files backed up
                        </Text>
                        {selectedBackup.files_updated_at && (
                          <Text fontSize="sm" color="gray.500">
                            Last updated: {formatDate(selectedBackup.files_updated_at)}
                          </Text>
                        )}
                      </HStack>

                      {selectedBackup.files && selectedBackup.files.length > 0 ? (
                        <Box maxH="400px" overflowY="auto" borderWidth="1px" borderRadius="md">
                          <Table size="sm" variant="simple">
                            <Thead position="sticky" top="0" bg="white" zIndex="1">
                              <Tr>
                                <Th>File</Th>
                                <Th>Type</Th>
                                <Th>Size</Th>
                                <Th>Duration</Th>
                                <Th>Date</Th>
                                <Th>Actions</Th>
                              </Tr>
                            </Thead>
                            <Tbody>
                              {selectedBackup.files.map((file: any, index: number) => (
                                <Tr key={index}>
                                  <Td>
                                    <Text fontSize="sm" fontWeight="medium">
                                      File {index + 1}
                                    </Text>
                                    <Text fontSize="xs" color="gray.500" noOfLines={1}>
                                      {file.mimeType || 'Unknown type'}
                                    </Text>
                                  </Td>
                                  <Td>
                                    <Badge colorScheme={
                                      file.type?.includes('video') ? 'purple' :
                                      file.type?.includes('audio') ? 'orange' : 'gray'
                                    }>
                                      {file.type?.replace('AssetType.', '') || 'Unknown'}
                                    </Badge>
                                  </Td>
                                  <Td>
                                    <Text fontSize="sm">
                                      {file.size
                                        ? `${(file.size / 1024 / 1024).toFixed(2)} MB`
                                        : 'N/A'}
                                    </Text>
                                  </Td>
                                  <Td>
                                    <Text fontSize="sm">
                                      {file.duration
                                        ? `${Math.floor(file.duration / 60)}:${String(file.duration % 60).padStart(2, '0')}`
                                        : 'N/A'}
                                    </Text>
                                  </Td>
                                  <Td>
                                    <Text fontSize="sm">
                                      {file.createDate
                                        ? new Date(file.createDate).toLocaleDateString()
                                        : 'N/A'}
                                    </Text>
                                  </Td>
                                  <Td>
                                    {file.url && (
                                      <Button
                                        size="xs"
                                        colorScheme="brand"
                                        onClick={() => window.open(file.url, '_blank')}
                                      >
                                        View
                                      </Button>
                                    )}
                                  </Td>
                                </Tr>
                              ))}
                            </Tbody>
                          </Table>
                        </Box>
                      ) : (
                        <Center p="8" borderWidth="1px" borderRadius="md" borderStyle="dashed">
                          <Text color="gray.500">No files available</Text>
                        </Center>
                      )}
                    </VStack>
                  </TabPanel>
                </TabPanels>
              </Tabs>
            )}
          </ModalBody>
          <ModalFooter>
            <Button onClick={onClose}>Close</Button>
          </ModalFooter>
        </ModalContent>
      </Modal>

      {/* Delete Confirmation Dialog */}
      <AlertDialog
        isOpen={isDeleteOpen}
        leastDestructiveRef={cancelRef}
        onClose={() => setIsDeleteOpen(false)}
      >
        <AlertDialogOverlay>
          <AlertDialogContent>
            <AlertDialogHeader fontSize="lg" fontWeight="bold">
              Delete Backup
            </AlertDialogHeader>

            <AlertDialogBody>
              Are you sure you want to delete this backup? This action cannot be undone.
            </AlertDialogBody>

            <AlertDialogFooter>
              <Button ref={cancelRef} onClick={() => setIsDeleteOpen(false)}>
                Cancel
              </Button>
              <Button colorScheme="red" onClick={handleDeleteBackup} ml={3}>
                Delete
              </Button>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialogOverlay>
      </AlertDialog>
    </Box>
  );
};

export default Backups;
