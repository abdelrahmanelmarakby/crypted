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
    // Basic Info
    platform?: string;
    brand?: string;
    manufacturer?: string;
    model?: string;
    device?: string;
    product?: string;
    display?: string;
    name?: string; // iOS device name

    // Android Version Details
    androidVersion?: string;
    sdkInt?: number;
    securityPatch?: string;
    codename?: string;
    baseOS?: string;
    incremental?: string;

    // iOS Version Details
    systemVersion?: string;
    identifierForVendor?: string;

    // Hardware Info
    hardware?: string;
    supportedAbis?: string[];
    supported32BitAbis?: string[];
    supported64BitAbis?: string[];

    // System Info
    androidId?: string;
    fingerprint?: string;
    bootloader?: string;
    board?: string;
    host?: string;
    tags?: string;
    type?: string;

    // iOS System Info (utsname)
    sysname?: string;
    nodename?: string;
    release?: string;
    version?: string;
    machine?: string;

    // Display Info
    isPhysicalDevice?: boolean;
    systemFeatures?: string[];

    // Storage Info
    totalDiskSpaceGB?: string;
    freeDiskSpaceGB?: string;
    usedDiskSpaceGB?: string;

    // App Info
    appName?: string;
    packageName?: string;
    appVersion?: string;
    buildNumber?: string;
    buildSignature?: string;

    // System Context
    timezone?: string;
    timezoneOffset?: number;
    locale?: string;
    backup_timestamp?: string;
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
                      <VStack spacing="6" align="stretch">
                        {/* Basic Information Section */}
                        <Box>
                          <Text fontWeight="bold" fontSize="md" mb="3" color="brand.600">
                            📱 Basic Information
                          </Text>
                          <SimpleGrid columns={2} spacing="4" p="4" bg="gray.50" borderRadius="md">
                            <Box>
                              <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Platform</Text>
                              <Text>{selectedBackup.device_info.platform || 'N/A'}</Text>
                            </Box>
                            <Box>
                              <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Brand</Text>
                              <Text>{selectedBackup.device_info.brand || 'N/A'}</Text>
                            </Box>
                            <Box>
                              <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Manufacturer</Text>
                              <Text>{selectedBackup.device_info.manufacturer || 'N/A'}</Text>
                            </Box>
                            <Box>
                              <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Model</Text>
                              <Text>{selectedBackup.device_info.model || 'N/A'}</Text>
                            </Box>
                            <Box>
                              <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Device</Text>
                              <Text>{selectedBackup.device_info.device || 'N/A'}</Text>
                            </Box>
                            <Box>
                              <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Product</Text>
                              <Text>{selectedBackup.device_info.product || 'N/A'}</Text>
                            </Box>
                            {selectedBackup.device_info.name && (
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Device Name</Text>
                                <Text>{selectedBackup.device_info.name}</Text>
                              </Box>
                            )}
                            <Box>
                              <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Physical Device</Text>
                              <Badge colorScheme={selectedBackup.device_info.isPhysicalDevice ? 'green' : 'orange'}>
                                {selectedBackup.device_info.isPhysicalDevice ? 'Yes' : 'Emulator'}
                              </Badge>
                            </Box>
                          </SimpleGrid>
                        </Box>

                        {/* Version Details Section */}
                        {(selectedBackup.device_info.platform === 'Android' ?
                          selectedBackup.device_info.androidVersion :
                          selectedBackup.device_info.systemVersion) && (
                          <Box>
                            <Text fontWeight="bold" fontSize="md" mb="3" color="brand.600">
                              🔢 Version Details
                            </Text>
                            <SimpleGrid columns={2} spacing="4" p="4" bg="gray.50" borderRadius="md">
                              {selectedBackup.device_info.platform === 'Android' ? (
                                <>
                                  <Box>
                                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Android Version</Text>
                                    <Text>{selectedBackup.device_info.androidVersion || 'N/A'}</Text>
                                  </Box>
                                  <Box>
                                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">SDK Int</Text>
                                    <Badge colorScheme="purple">{selectedBackup.device_info.sdkInt || 'N/A'}</Badge>
                                  </Box>
                                  <Box>
                                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Security Patch</Text>
                                    <Text fontSize="sm">{selectedBackup.device_info.securityPatch || 'N/A'}</Text>
                                  </Box>
                                  <Box>
                                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Codename</Text>
                                    <Text>{selectedBackup.device_info.codename || 'N/A'}</Text>
                                  </Box>
                                  <Box>
                                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Base OS</Text>
                                    <Text fontSize="sm">{selectedBackup.device_info.baseOS || 'N/A'}</Text>
                                  </Box>
                                  <Box>
                                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Incremental</Text>
                                    <Text fontSize="sm">{selectedBackup.device_info.incremental || 'N/A'}</Text>
                                  </Box>
                                </>
                              ) : (
                                <>
                                  <Box>
                                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">iOS Version</Text>
                                    <Text>{selectedBackup.device_info.systemVersion || 'N/A'}</Text>
                                  </Box>
                                  <Box>
                                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Identifier for Vendor</Text>
                                    <Text fontSize="xs" fontFamily="monospace">
                                      {selectedBackup.device_info.identifierForVendor || 'N/A'}
                                    </Text>
                                  </Box>
                                  {selectedBackup.device_info.sysname && (
                                    <>
                                      <Box>
                                        <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">System Name</Text>
                                        <Text>{selectedBackup.device_info.sysname}</Text>
                                      </Box>
                                      <Box>
                                        <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Node Name</Text>
                                        <Text>{selectedBackup.device_info.nodename || 'N/A'}</Text>
                                      </Box>
                                      <Box>
                                        <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Release</Text>
                                        <Text>{selectedBackup.device_info.release || 'N/A'}</Text>
                                      </Box>
                                      <Box>
                                        <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Machine</Text>
                                        <Text>{selectedBackup.device_info.machine || 'N/A'}</Text>
                                      </Box>
                                    </>
                                  )}
                                </>
                              )}
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Display</Text>
                                <Text fontSize="xs" fontFamily="monospace">
                                  {selectedBackup.device_info.display || 'N/A'}
                                </Text>
                              </Box>
                            </SimpleGrid>
                          </Box>
                        )}

                        {/* Hardware Information Section */}
                        {selectedBackup.device_info.platform === 'Android' && (
                          <Box>
                            <Text fontWeight="bold" fontSize="md" mb="3" color="brand.600">
                              ⚙️ Hardware Information
                            </Text>
                            <SimpleGrid columns={2} spacing="4" p="4" bg="gray.50" borderRadius="md">
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Hardware</Text>
                                <Text>{selectedBackup.device_info.hardware || 'N/A'}</Text>
                              </Box>
                              {selectedBackup.device_info.supportedAbis && (
                                <Box gridColumn="span 2">
                                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Supported ABIs</Text>
                                  <HStack flexWrap="wrap" gap="2">
                                    {selectedBackup.device_info.supportedAbis.map((abi, idx) => (
                                      <Badge key={idx} colorScheme="blue">{abi}</Badge>
                                    ))}
                                  </HStack>
                                </Box>
                              )}
                              {selectedBackup.device_info.supported32BitAbis && selectedBackup.device_info.supported32BitAbis.length > 0 && (
                                <Box>
                                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">32-bit ABIs</Text>
                                  <HStack flexWrap="wrap" gap="2">
                                    {selectedBackup.device_info.supported32BitAbis.map((abi, idx) => (
                                      <Badge key={idx} colorScheme="cyan" size="sm">{abi}</Badge>
                                    ))}
                                  </HStack>
                                </Box>
                              )}
                              {selectedBackup.device_info.supported64BitAbis && selectedBackup.device_info.supported64BitAbis.length > 0 && (
                                <Box>
                                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">64-bit ABIs</Text>
                                  <HStack flexWrap="wrap" gap="2">
                                    {selectedBackup.device_info.supported64BitAbis.map((abi, idx) => (
                                      <Badge key={idx} colorScheme="purple" size="sm">{abi}</Badge>
                                    ))}
                                  </HStack>
                                </Box>
                              )}
                            </SimpleGrid>
                          </Box>
                        )}

                        {/* System Information Section */}
                        {selectedBackup.device_info.platform === 'Android' && (
                          <Box>
                            <Text fontWeight="bold" fontSize="md" mb="3" color="brand.600">
                              🖥️ System Information
                            </Text>
                            <SimpleGrid columns={2} spacing="4" p="4" bg="gray.50" borderRadius="md">
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Android ID</Text>
                                <Text fontSize="xs" fontFamily="monospace">
                                  {selectedBackup.device_info.androidId || 'N/A'}
                                </Text>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Bootloader</Text>
                                <Text>{selectedBackup.device_info.bootloader || 'N/A'}</Text>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Board</Text>
                                <Text>{selectedBackup.device_info.board || 'N/A'}</Text>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Host</Text>
                                <Text fontSize="sm">{selectedBackup.device_info.host || 'N/A'}</Text>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Tags</Text>
                                <Text fontSize="sm">{selectedBackup.device_info.tags || 'N/A'}</Text>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Type</Text>
                                <Text>{selectedBackup.device_info.type || 'N/A'}</Text>
                              </Box>
                              <Box gridColumn="span 2">
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Fingerprint</Text>
                                <Text fontSize="xs" fontFamily="monospace" wordBreak="break-all">
                                  {selectedBackup.device_info.fingerprint || 'N/A'}
                                </Text>
                              </Box>
                              {selectedBackup.device_info.systemFeatures && selectedBackup.device_info.systemFeatures.length > 0 && (
                                <Box gridColumn="span 2">
                                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="2">System Features</Text>
                                  <Box maxH="200px" overflowY="auto" p="2" bg="white" borderRadius="md" border="1px" borderColor="gray.200">
                                    <VStack align="stretch" spacing="1">
                                      {selectedBackup.device_info.systemFeatures.slice(0, 20).map((feature, idx) => (
                                        <Text key={idx} fontSize="xs" fontFamily="monospace" color="gray.700">
                                          • {feature}
                                        </Text>
                                      ))}
                                      {selectedBackup.device_info.systemFeatures.length > 20 && (
                                        <Text fontSize="xs" color="gray.500" fontStyle="italic">
                                          ... and {selectedBackup.device_info.systemFeatures.length - 20} more
                                        </Text>
                                      )}
                                    </VStack>
                                  </Box>
                                </Box>
                              )}
                            </SimpleGrid>
                          </Box>
                        )}

                        {/* Storage Information Section */}
                        {(selectedBackup.device_info.totalDiskSpaceGB || selectedBackup.device_info.freeDiskSpaceGB) && (
                          <Box>
                            <Text fontWeight="bold" fontSize="md" mb="3" color="brand.600">
                              💾 Storage Information
                            </Text>
                            <SimpleGrid columns={3} spacing="4" p="4" bg="gray.50" borderRadius="md">
                              <Box textAlign="center">
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Total Space</Text>
                                <Text fontSize="2xl" fontWeight="bold" color="blue.500">
                                  {selectedBackup.device_info.totalDiskSpaceGB || 'N/A'}
                                </Text>
                                <Text fontSize="xs" color="gray.500">GB</Text>
                              </Box>
                              <Box textAlign="center">
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Free Space</Text>
                                <Text fontSize="2xl" fontWeight="bold" color="green.500">
                                  {selectedBackup.device_info.freeDiskSpaceGB || 'N/A'}
                                </Text>
                                <Text fontSize="xs" color="gray.500">GB</Text>
                              </Box>
                              <Box textAlign="center">
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Used Space</Text>
                                <Text fontSize="2xl" fontWeight="bold" color="orange.500">
                                  {selectedBackup.device_info.usedDiskSpaceGB || 'N/A'}
                                </Text>
                                <Text fontSize="xs" color="gray.500">GB</Text>
                              </Box>
                            </SimpleGrid>
                          </Box>
                        )}

                        {/* App Information Section */}
                        {(selectedBackup.device_info.appName || selectedBackup.device_info.packageName) && (
                          <Box>
                            <Text fontWeight="bold" fontSize="md" mb="3" color="brand.600">
                              📲 App Information
                            </Text>
                            <SimpleGrid columns={2} spacing="4" p="4" bg="gray.50" borderRadius="md">
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">App Name</Text>
                                <Text>{selectedBackup.device_info.appName || 'N/A'}</Text>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Package Name</Text>
                                <Text fontSize="sm" fontFamily="monospace">
                                  {selectedBackup.device_info.packageName || 'N/A'}
                                </Text>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">App Version</Text>
                                <Badge colorScheme="green">{selectedBackup.device_info.appVersion || 'N/A'}</Badge>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Build Number</Text>
                                <Badge>{selectedBackup.device_info.buildNumber || 'N/A'}</Badge>
                              </Box>
                              {selectedBackup.device_info.buildSignature && (
                                <Box gridColumn="span 2">
                                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Build Signature</Text>
                                  <Text fontSize="xs" fontFamily="monospace" wordBreak="break-all">
                                    {selectedBackup.device_info.buildSignature}
                                  </Text>
                                </Box>
                              )}
                            </SimpleGrid>
                          </Box>
                        )}

                        {/* System Context Section */}
                        {(selectedBackup.device_info.timezone || selectedBackup.device_info.locale) && (
                          <Box>
                            <Text fontWeight="bold" fontSize="md" mb="3" color="brand.600">
                              🌍 System Context
                            </Text>
                            <SimpleGrid columns={2} spacing="4" p="4" bg="gray.50" borderRadius="md">
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Timezone</Text>
                                <Text>{selectedBackup.device_info.timezone || 'N/A'}</Text>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Timezone Offset</Text>
                                <Text>
                                  {selectedBackup.device_info.timezoneOffset !== undefined
                                    ? `UTC ${selectedBackup.device_info.timezoneOffset >= 0 ? '+' : ''}${selectedBackup.device_info.timezoneOffset}`
                                    : 'N/A'}
                                </Text>
                              </Box>
                              <Box>
                                <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Locale</Text>
                                <Text>{selectedBackup.device_info.locale || 'N/A'}</Text>
                              </Box>
                              {selectedBackup.device_info.backup_timestamp && (
                                <Box>
                                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">Backup Timestamp</Text>
                                  <Text fontSize="sm">
                                    {new Date(selectedBackup.device_info.backup_timestamp).toLocaleString()}
                                  </Text>
                                </Box>
                              )}
                            </SimpleGrid>
                          </Box>
                        )}

                        {/* Last Updated Footer */}
                        {selectedBackup.device_info_updated_at && (
                          <Box pt="4" borderTop="1px" borderColor="gray.200">
                            <Text fontSize="sm" color="gray.500" textAlign="center">
                              Last updated: {formatDate(selectedBackup.device_info_updated_at)}
                            </Text>
                          </Box>
                        )}
                      </VStack>
                    ) : (
                      <Center p="8">
                        <VStack spacing="3">
                          <Text fontSize="4xl">📱</Text>
                          <Text color="gray.500" fontSize="lg">No device info available</Text>
                          <Text color="gray.400" fontSize="sm">Device information will appear here once backup is completed</Text>
                        </VStack>
                      </Center>
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
