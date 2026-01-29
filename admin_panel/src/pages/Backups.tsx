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
  Progress,
  CircularProgress,
  CircularProgressLabel,
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
  FiMessageSquare,
  FiVideo,
  FiMusic,
  FiPlay,
  FiPause,
  FiX,
  FiDownload,
  FiFolder,
} from 'react-icons/fi';
import { collection, getDocs, doc, deleteDoc, query, orderBy, onSnapshot } from 'firebase/firestore';
import { ref, listAll, getDownloadURL, getMetadata } from 'firebase/storage';
import { db, storage } from '@/config/firebase';
import { formatDate, formatRelativeTime } from '@/utils/helpers';

// New interface for backup_jobs collection
interface BackupJob {
  id: string; // Document ID (backupId or {userId}_active)
  userId: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed' | 'cancelled';
  progress: number; // 0.0 - 1.0
  current_type?: 'chats' | 'media' | 'contacts' | 'device_info';
  chats_count: number;
  media_count: number;
  contacts_count: number;
  files_count: number; // device info count
  error?: string;
  startedAt?: any;
  completedAt?: any;
  types?: string[]; // BackupTypes being backed up
  // Additional fields for storage info
  storageFiles?: StorageFile[];
}

interface StorageFile {
  name: string;
  folder: string;
  subFolder?: string;
  url: string;
  size: number;
  contentType: string;
  timeCreated: string;
}

// Helper functions
const getTotalItems = (backup: BackupJob): number => {
  return (
    (backup.chats_count || 0) +
    (backup.media_count || 0) +
    (backup.contacts_count || 0) +
    (backup.files_count || 0)
  );
};

const getStatusColor = (status: string) => {
  switch (status) {
    case 'completed':
      return 'green';
    case 'in_progress':
      return 'blue';
    case 'pending':
      return 'gray';
    case 'failed':
      return 'red';
    case 'cancelled':
      return 'orange';
    default:
      return 'gray';
  }
};

const getStatusIcon = (status: string) => {
  switch (status) {
    case 'completed':
      return FiCheckCircle;
    case 'in_progress':
      return FiPlay;
    case 'pending':
      return FiClock;
    case 'failed':
      return FiAlertCircle;
    case 'cancelled':
      return FiX;
    default:
      return FiClock;
  }
};

const formatBytes = (bytes: number): string => {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

const Backups: React.FC = () => {
  const [backups, setBackups] = useState<BackupJob[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedBackup, setSelectedBackup] = useState<BackupJob | null>(null);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'completed' | 'in_progress' | 'pending' | 'failed' | 'cancelled'>('all');
  const [loadingFiles, setLoadingFiles] = useState(false);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const cancelRef = React.useRef<HTMLButtonElement>(null);

  const toast = useToast();
  const cardBg = useColorModeValue('white', 'gray.800');

  // Calculate statistics
  const statistics = useMemo(() => {
    const safeBackups = Array.isArray(backups) ? backups : [];

    const totalBackups = safeBackups.length;
    const totalChats = safeBackups.reduce((sum, b) => sum + (b.chats_count || 0), 0);
    const totalMedia = safeBackups.reduce((sum, b) => sum + (b.media_count || 0), 0);
    const totalContacts = safeBackups.reduce((sum, b) => sum + (b.contacts_count || 0), 0);

    const completedBackups = safeBackups.filter((b) => b.status === 'completed').length;
    const inProgressBackups = safeBackups.filter((b) => b.status === 'in_progress').length;
    const failedBackups = safeBackups.filter((b) => b.status === 'failed').length;
    const pendingBackups = safeBackups.filter((b) => b.status === 'pending').length;

    // Get unique users
    const uniqueUsers = new Set(safeBackups.map(b => b.userId)).size;

    return {
      totalBackups,
      totalChats,
      totalMedia,
      totalContacts,
      completedBackups,
      inProgressBackups,
      failedBackups,
      pendingBackups,
      uniqueUsers,
      avgItemsPerBackup: totalBackups > 0
        ? Math.round((totalChats + totalMedia + totalContacts) / totalBackups)
        : 0,
    };
  }, [backups]);

  // Filter backups
  const filteredBackups = useMemo(() => {
    const safeBackups = Array.isArray(backups) ? backups : [];

    return safeBackups.filter((backup) => {
      // Search filter
      const matchesSearch =
        searchTerm === '' ||
        backup.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        backup.userId?.toLowerCase().includes(searchTerm.toLowerCase());

      // Status filter
      const matchesStatus = statusFilter === 'all' || backup.status === statusFilter;

      return matchesSearch && matchesStatus;
    });
  }, [backups, searchTerm, statusFilter]);

  useEffect(() => {
    fetchBackups();
  }, []);

  const fetchBackups = async () => {
    try {
      setLoading(true);
      // Read from backup_jobs collection
      const backupsRef = collection(db, 'backup_jobs');
      const q = query(backupsRef, orderBy('startedAt', 'desc'));
      const snapshot = await getDocs(q);

      const fetchedBackups = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })) as BackupJob[];

      setBackups(fetchedBackups);
    } catch (error) {
      console.error('Error fetching backups:', error);
      toast({
        title: 'Error fetching backups',
        description: 'Could not load backup data. Check console for details.',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
      setBackups([]);
    } finally {
      setLoading(false);
    }
  };

  // Fetch storage files for a backup
  const fetchStorageFiles = async (backup: BackupJob): Promise<StorageFile[]> => {
    const files: StorageFile[] = [];

    try {
      // Storage path: backups/{userId}/{backupId}/
      const basePath = `backups/${backup.userId}/${backup.id}`;
      const baseRef = ref(storage, basePath);

      // List all folders
      const folders = ['chats', 'contacts', 'device_info', 'media'];

      for (const folder of folders) {
        try {
          const folderRef = ref(storage, `${basePath}/${folder}`);
          const folderResult = await listAll(folderRef);

          // Get files directly in folder
          for (const item of folderResult.items) {
            try {
              const url = await getDownloadURL(item);
              const metadata = await getMetadata(item);
              files.push({
                name: item.name,
                folder: folder,
                url: url,
                size: metadata.size,
                contentType: metadata.contentType || 'unknown',
                timeCreated: metadata.timeCreated,
              });
            } catch (e) {
              console.warn(`Could not get file info for ${item.fullPath}:`, e);
            }
          }

          // Check subfolders (for media: images, videos, audio, files)
          for (const subFolderRef of folderResult.prefixes) {
            try {
              const subFolderResult = await listAll(subFolderRef);
              for (const item of subFolderResult.items) {
                try {
                  const url = await getDownloadURL(item);
                  const metadata = await getMetadata(item);
                  files.push({
                    name: item.name,
                    folder: folder,
                    subFolder: subFolderRef.name,
                    url: url,
                    size: metadata.size,
                    contentType: metadata.contentType || 'unknown',
                    timeCreated: metadata.timeCreated,
                  });
                } catch (e) {
                  console.warn(`Could not get file info for ${item.fullPath}:`, e);
                }
              }
            } catch (e) {
              console.warn(`Could not list subfolder ${subFolderRef.fullPath}:`, e);
            }
          }
        } catch (e) {
          // Folder might not exist
          console.debug(`Folder ${folder} not found for backup ${backup.id}`);
        }
      }
    } catch (error) {
      console.error('Error fetching storage files:', error);
    }

    return files;
  };

  const handleViewBackup = async (backup: BackupJob) => {
    setSelectedBackup(backup);
    setLoadingFiles(true);
    onOpen();

    // Fetch storage files in background
    const files = await fetchStorageFiles(backup);
    setSelectedBackup({ ...backup, storageFiles: files });
    setLoadingFiles(false);
  };

  const handleDeleteBackup = async () => {
    if (!selectedBackup) return;

    try {
      const backupRef = doc(db, 'backup_jobs', selectedBackup.id);
      await deleteDoc(backupRef);

      toast({
        title: 'Backup deleted',
        description: 'The backup record has been deleted. Note: Storage files may need manual cleanup.',
        status: 'success',
        duration: 3000,
        isClosable: true,
      });

      setIsDeleteOpen(false);
      onClose();
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
        <VStack spacing="4">
          <Spinner size="xl" color="brand.500" thickness="4px" />
          <Text color="gray.500">Loading backups...</Text>
        </VStack>
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
              Backup Jobs
            </Heading>
          </HStack>
          <Text color="gray.600" fontSize="md">
            Monitor and manage user backup jobs from the mobile app
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
                  Total Backups
                </StatLabel>
                <Icon
                  as={FiDatabase}
                  boxSize="10"
                  color="purple.500"
                  bg="purple.50"
                  p="2"
                  borderRadius="lg"
                />
              </Flex>
              <StatNumber fontSize="4xl" fontWeight="extrabold" color="purple.500">
                {statistics.totalBackups}
              </StatNumber>
              <StatHelpText fontSize="sm">{statistics.uniqueUsers} unique users</StatHelpText>
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
                  Total Chats
                </StatLabel>
                <Icon
                  as={FiMessageSquare}
                  boxSize="10"
                  color="blue.500"
                  bg="blue.50"
                  p="2"
                  borderRadius="lg"
                />
              </Flex>
              <StatNumber fontSize="4xl" fontWeight="extrabold" color="blue.500">
                {statistics.totalChats.toLocaleString()}
              </StatNumber>
              <StatHelpText fontSize="sm">Chat rooms backed up</StatHelpText>
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
                  Total Media
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
                {statistics.totalMedia.toLocaleString()}
              </StatNumber>
              <StatHelpText fontSize="sm">Images, videos, audio</StatHelpText>
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
                  color="orange.500"
                  bg="orange.50"
                  p="2"
                  borderRadius="lg"
                />
              </Flex>
              <StatNumber fontSize="4xl" fontWeight="extrabold" color="orange.500">
                {statistics.totalContacts.toLocaleString()}
              </StatNumber>
              <StatHelpText fontSize="sm">Contacts backed up</StatHelpText>
            </Stat>
          </CardBody>
        </Card>
      </SimpleGrid>

      {/* Status Statistics Row */}
      <SimpleGrid columns={{ base: 2, md: 4, lg: 5 }} spacing="4" mb="6">
        <Card bg={cardBg} shadow="sm">
          <CardBody py="4">
            <Flex align="center" justify="space-between">
              <VStack align="start" spacing="0">
                <Text fontSize="xs" color="gray.600" fontWeight="medium">
                  Completed
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="green.500">
                  {statistics.completedBackups}
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
                  In Progress
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="blue.500">
                  {statistics.inProgressBackups}
                </Text>
              </VStack>
              <Icon as={FiPlay} boxSize="6" color="blue.500" />
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
                  Failed
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="red.500">
                  {statistics.failedBackups}
                </Text>
              </VStack>
              <Icon as={FiAlertCircle} boxSize="6" color="red.500" />
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
                  {statistics.avgItemsPerBackup.toLocaleString()}
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
                placeholder="Search by backup ID or user ID..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                size="md"
              />
            </InputGroup>

            <Select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
              maxW="200px"
              size="md"
            >
              <option value="all">All Status</option>
              <option value="completed">Completed</option>
              <option value="in_progress">In Progress</option>
              <option value="pending">Pending</option>
              <option value="failed">Failed</option>
              <option value="cancelled">Cancelled</option>
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
                  <Th>Backup ID</Th>
                  <Th>User</Th>
                  <Th>Status</Th>
                  <Th>Progress</Th>
                  <Th>Items Backed Up</Th>
                  <Th>Started</Th>
                  <Th>Completed</Th>
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
                        <Text fontWeight="semibold" fontSize="sm" noOfLines={1} maxW="200px">
                          {backup.id}
                        </Text>
                        {backup.current_type && backup.status === 'in_progress' && (
                          <Badge colorScheme="blue" fontSize="xs">
                            {backup.current_type}
                          </Badge>
                        )}
                      </VStack>
                    </Td>
                    <Td>
                      <Text fontSize="sm" fontWeight="medium" noOfLines={1} maxW="150px">
                        {backup.userId || 'Unknown'}
                      </Text>
                    </Td>
                    <Td>
                      <Badge
                        colorScheme={getStatusColor(backup.status)}
                        fontSize="sm"
                        px="3"
                        py="1"
                        borderRadius="full"
                        textTransform="capitalize"
                      >
                        <HStack spacing="1">
                          <Icon as={getStatusIcon(backup.status)} boxSize="3" />
                          <Text>{backup.status?.replace('_', ' ')}</Text>
                        </HStack>
                      </Badge>
                    </Td>
                    <Td>
                      {backup.status === 'in_progress' ? (
                        <HStack spacing="2">
                          <CircularProgress
                            value={(backup.progress || 0) * 100}
                            size="40px"
                            color="blue.500"
                            trackColor="gray.200"
                          >
                            <CircularProgressLabel fontSize="xs">
                              {Math.round((backup.progress || 0) * 100)}%
                            </CircularProgressLabel>
                          </CircularProgress>
                        </HStack>
                      ) : backup.status === 'completed' ? (
                        <Badge colorScheme="green" fontSize="sm">100%</Badge>
                      ) : (
                        <Text fontSize="sm" color="gray.400">-</Text>
                      )}
                    </Td>
                    <Td>
                      <VStack align="start" spacing="2">
                        <Text fontSize="lg" fontWeight="bold" color="purple.500">
                          {getTotalItems(backup).toLocaleString()}
                        </Text>
                        <HStack spacing="3" fontSize="xs" color="gray.600" flexWrap="wrap">
                          <Tooltip label="Chats" hasArrow>
                            <HStack spacing="1">
                              <Icon as={FiMessageSquare} color="blue.500" />
                              <Text>{backup.chats_count || 0}</Text>
                            </HStack>
                          </Tooltip>
                          <Tooltip label="Media" hasArrow>
                            <HStack spacing="1">
                              <Icon as={FiImage} color="green.500" />
                              <Text>{backup.media_count || 0}</Text>
                            </HStack>
                          </Tooltip>
                          <Tooltip label="Contacts" hasArrow>
                            <HStack spacing="1">
                              <Icon as={FiUsers} color="orange.500" />
                              <Text>{backup.contacts_count || 0}</Text>
                            </HStack>
                          </Tooltip>
                        </HStack>
                      </VStack>
                    </Td>
                    <Td>
                      {backup.startedAt ? (
                        <VStack align="start" spacing="0">
                          <Text fontSize="sm" fontWeight="medium">
                            {formatDate(backup.startedAt, 'MMM dd, HH:mm')}
                          </Text>
                          <Text fontSize="xs" color="gray.500">
                            {formatRelativeTime(backup.startedAt)}
                          </Text>
                        </VStack>
                      ) : (
                        <Text fontSize="sm" color="gray.400">-</Text>
                      )}
                    </Td>
                    <Td>
                      {backup.completedAt ? (
                        <VStack align="start" spacing="0">
                          <Text fontSize="sm" fontWeight="medium">
                            {formatDate(backup.completedAt, 'MMM dd, HH:mm')}
                          </Text>
                          <Text fontSize="xs" color="gray.500">
                            {formatRelativeTime(backup.completedAt)}
                          </Text>
                        </VStack>
                      ) : (
                        <Text fontSize="sm" color="gray.400">-</Text>
                      )}
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
                  {backups.length === 0 ? 'No backup jobs found' : 'No results found'}
                </Text>
                <Text fontSize="sm" color="gray.400" textAlign="center" maxW="md">
                  {backups.length === 0
                    ? "User backup jobs will appear here when they initiate backups from the mobile app"
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
                    <Text fontSize="xl" fontWeight="bold" noOfLines={1}>
                      Backup Details
                    </Text>
                    <Text fontSize="sm" color="gray.600" fontWeight="normal" noOfLines={1}>
                      {selectedBackup?.id}
                    </Text>
                  </VStack>
                </HStack>
                <ModalCloseButton position="relative" top="0" right="0" />
              </HStack>
              <HStack spacing="2" flexWrap="wrap">
                {selectedBackup && (
                  <>
                    <Badge
                      colorScheme={getStatusColor(selectedBackup.status)}
                      fontSize="sm"
                      px="3"
                      py="1"
                      borderRadius="full"
                    >
                      {selectedBackup.status}
                    </Badge>
                    <Badge colorScheme="purple" fontSize="sm" px="3" py="1" borderRadius="full">
                      {getTotalItems(selectedBackup).toLocaleString()} items
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
                  <Tab>
                    <HStack>
                      <Icon as={FiFolder} />
                      <Text>Storage Files</Text>
                      {loadingFiles && <Spinner size="xs" />}
                    </HStack>
                  </Tab>
                  {selectedBackup.error && <Tab color="red.500">Error</Tab>}
                </TabList>

                <TabPanels>
                  {/* Overview Tab */}
                  <TabPanel>
                    <VStack spacing="6" align="stretch">
                      {/* Basic Info */}
                      <SimpleGrid columns={{ base: 1, md: 2 }} spacing="6">
                        <Card bg="white" shadow="sm">
                          <CardBody>
                            <VStack align="start" spacing="2">
                              <HStack>
                                <Icon as={FiUsers} color="purple.500" boxSize="5" />
                                <Text fontWeight="bold" fontSize="md" color="gray.700">
                                  User ID
                                </Text>
                              </HStack>
                              <Text fontSize="md" fontFamily="monospace" wordBreak="break-all">
                                {selectedBackup.userId || 'Unknown'}
                              </Text>
                            </VStack>
                          </CardBody>
                        </Card>

                        <Card bg="white" shadow="sm">
                          <CardBody>
                            <VStack align="start" spacing="2">
                              <HStack>
                                <Icon
                                  as={getStatusIcon(selectedBackup.status)}
                                  color={`${getStatusColor(selectedBackup.status)}.500`}
                                  boxSize="5"
                                />
                                <Text fontWeight="bold" fontSize="md" color="gray.700">
                                  Status
                                </Text>
                              </HStack>
                              <Badge
                                colorScheme={getStatusColor(selectedBackup.status)}
                                fontSize="md"
                                px="4"
                                py="1"
                                borderRadius="full"
                                textTransform="capitalize"
                              >
                                {selectedBackup.status}
                              </Badge>
                              {selectedBackup.status === 'in_progress' && (
                                <Progress
                                  value={(selectedBackup.progress || 0) * 100}
                                  colorScheme="blue"
                                  size="sm"
                                  borderRadius="full"
                                  w="100%"
                                />
                              )}
                            </VStack>
                          </CardBody>
                        </Card>
                      </SimpleGrid>

                      {/* Timestamps */}
                      <SimpleGrid columns={{ base: 1, md: 2 }} spacing="6">
                        <Card bg="white" shadow="sm">
                          <CardBody>
                            <VStack align="start" spacing="2">
                              <HStack>
                                <Icon as={FiClock} color="blue.500" boxSize="5" />
                                <Text fontWeight="bold" fontSize="md" color="gray.700">
                                  Started At
                                </Text>
                              </HStack>
                              <Text fontSize="lg" fontWeight="semibold">
                                {selectedBackup.startedAt
                                  ? formatDate(selectedBackup.startedAt)
                                  : 'Not started'}
                              </Text>
                              {selectedBackup.startedAt && (
                                <Text fontSize="sm" color="gray.600">
                                  {formatRelativeTime(selectedBackup.startedAt)}
                                </Text>
                              )}
                            </VStack>
                          </CardBody>
                        </Card>

                        <Card bg="white" shadow="sm">
                          <CardBody>
                            <VStack align="start" spacing="2">
                              <HStack>
                                <Icon as={FiCheckCircle} color="green.500" boxSize="5" />
                                <Text fontWeight="bold" fontSize="md" color="gray.700">
                                  Completed At
                                </Text>
                              </HStack>
                              <Text fontSize="lg" fontWeight="semibold">
                                {selectedBackup.completedAt
                                  ? formatDate(selectedBackup.completedAt)
                                  : 'Not completed'}
                              </Text>
                              {selectedBackup.completedAt && (
                                <Text fontSize="sm" color="gray.600">
                                  {formatRelativeTime(selectedBackup.completedAt)}
                                </Text>
                              )}
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
                              <Icon as={FiMessageSquare} boxSize="10" color="blue.500" />
                              <Text fontSize="3xl" fontWeight="bold" color="blue.500">
                                {selectedBackup.chats_count || 0}
                              </Text>
                              <Text fontSize="sm" color="gray.600">
                                Chats
                              </Text>
                            </VStack>
                            <VStack>
                              <Icon as={FiImage} boxSize="10" color="green.500" />
                              <Text fontSize="3xl" fontWeight="bold" color="green.500">
                                {selectedBackup.media_count || 0}
                              </Text>
                              <Text fontSize="sm" color="gray.600">
                                Media Files
                              </Text>
                            </VStack>
                            <VStack>
                              <Icon as={FiUsers} boxSize="10" color="orange.500" />
                              <Text fontSize="3xl" fontWeight="bold" color="orange.500">
                                {selectedBackup.contacts_count || 0}
                              </Text>
                              <Text fontSize="sm" color="gray.600">
                                Contacts
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

                      {/* Backup Types */}
                      {selectedBackup.types && selectedBackup.types.length > 0 && (
                        <Card bg="white" shadow="sm">
                          <CardBody>
                            <Text fontWeight="bold" fontSize="md" color="gray.700" mb="4">
                              Backup Types Included
                            </Text>
                            <HStack spacing="2" flexWrap="wrap">
                              {selectedBackup.types.map((type, idx) => (
                                <Badge
                                  key={idx}
                                  colorScheme="purple"
                                  fontSize="sm"
                                  px="3"
                                  py="1"
                                  borderRadius="full"
                                >
                                  {type}
                                </Badge>
                              ))}
                            </HStack>
                          </CardBody>
                        </Card>
                      )}
                    </VStack>
                  </TabPanel>

                  {/* Storage Files Tab */}
                  <TabPanel>
                    <VStack align="stretch" spacing="4">
                      <HStack justify="space-between">
                        <HStack spacing="3">
                          <Icon as={FiFolder} boxSize="5" color="purple.500" />
                          <Text fontWeight="bold" fontSize="lg">
                            Storage Files
                          </Text>
                        </HStack>
                        <Text fontSize="sm" color="gray.500">
                          Path: backups/{selectedBackup.userId}/{selectedBackup.id}/
                        </Text>
                      </HStack>

                      {loadingFiles ? (
                        <Center p="8">
                          <VStack spacing="3">
                            <Spinner size="lg" color="purple.500" />
                            <Text color="gray.500">Loading storage files...</Text>
                          </VStack>
                        </Center>
                      ) : selectedBackup.storageFiles && selectedBackup.storageFiles.length > 0 ? (
                        <Box maxH="500px" overflowY="auto" borderWidth="1px" borderRadius="md">
                          <Table size="sm" variant="simple">
                            <Thead position="sticky" top="0" bg="white" zIndex="1">
                              <Tr>
                                <Th>File Name</Th>
                                <Th>Folder</Th>
                                <Th>Type</Th>
                                <Th>Size</Th>
                                <Th>Created</Th>
                                <Th>Actions</Th>
                              </Tr>
                            </Thead>
                            <Tbody>
                              {selectedBackup.storageFiles.map((file, index) => (
                                <Tr key={index}>
                                  <Td>
                                    <Text fontSize="sm" fontWeight="medium" noOfLines={1} maxW="200px">
                                      {file.name}
                                    </Text>
                                  </Td>
                                  <Td>
                                    <VStack align="start" spacing="0">
                                      <Badge colorScheme="purple" fontSize="xs">
                                        {file.folder}
                                      </Badge>
                                      {file.subFolder && (
                                        <Badge colorScheme="gray" fontSize="xs" mt="1">
                                          {file.subFolder}
                                        </Badge>
                                      )}
                                    </VStack>
                                  </Td>
                                  <Td>
                                    <Badge
                                      colorScheme={
                                        file.contentType?.includes('image') ? 'green' :
                                        file.contentType?.includes('video') ? 'purple' :
                                        file.contentType?.includes('audio') ? 'orange' :
                                        file.contentType?.includes('json') ? 'blue' : 'gray'
                                      }
                                      fontSize="xs"
                                    >
                                      {file.contentType?.split('/')[1] || 'unknown'}
                                    </Badge>
                                  </Td>
                                  <Td>
                                    <Text fontSize="sm">{formatBytes(file.size)}</Text>
                                  </Td>
                                  <Td>
                                    <Text fontSize="xs" color="gray.600">
                                      {new Date(file.timeCreated).toLocaleString()}
                                    </Text>
                                  </Td>
                                  <Td>
                                    <HStack spacing="2">
                                      <Tooltip label="View File" hasArrow>
                                        <IconButton
                                          icon={<FiEye />}
                                          variant="ghost"
                                          size="xs"
                                          colorScheme="purple"
                                          onClick={() => window.open(file.url, '_blank')}
                                          aria-label="View file"
                                        />
                                      </Tooltip>
                                      <Tooltip label="Download" hasArrow>
                                        <IconButton
                                          icon={<FiDownload />}
                                          variant="ghost"
                                          size="xs"
                                          colorScheme="green"
                                          onClick={() => {
                                            const link = document.createElement('a');
                                            link.href = file.url;
                                            link.download = file.name;
                                            link.target = '_blank';
                                            link.click();
                                          }}
                                          aria-label="Download file"
                                        />
                                      </Tooltip>
                                    </HStack>
                                  </Td>
                                </Tr>
                              ))}
                            </Tbody>
                          </Table>
                        </Box>
                      ) : (
                        <Center p="12" borderWidth="1px" borderRadius="md" borderStyle="dashed" bg="gray.50">
                          <VStack spacing="3">
                            <Icon as={FiFolder} boxSize="16" color="gray.300" />
                            <Text color="gray.500" fontSize="lg" fontWeight="medium">
                              No storage files found
                            </Text>
                            <Text color="gray.400" fontSize="sm" textAlign="center" maxW="sm">
                              Storage files will appear here once the backup uploads them to Firebase Storage
                            </Text>
                          </VStack>
                        </Center>
                      )}

                      {/* Storage Summary */}
                      {selectedBackup.storageFiles && selectedBackup.storageFiles.length > 0 && (
                        <Card bg="white" shadow="sm">
                          <CardBody>
                            <SimpleGrid columns={{ base: 2, md: 4 }} spacing="4">
                              <VStack>
                                <Text fontSize="sm" color="gray.600">Total Files</Text>
                                <Text fontSize="2xl" fontWeight="bold" color="purple.500">
                                  {selectedBackup.storageFiles.length}
                                </Text>
                              </VStack>
                              <VStack>
                                <Text fontSize="sm" color="gray.600">Total Size</Text>
                                <Text fontSize="2xl" fontWeight="bold" color="blue.500">
                                  {formatBytes(selectedBackup.storageFiles.reduce((sum, f) => sum + f.size, 0))}
                                </Text>
                              </VStack>
                              <VStack>
                                <Text fontSize="sm" color="gray.600">Images</Text>
                                <Text fontSize="2xl" fontWeight="bold" color="green.500">
                                  {selectedBackup.storageFiles.filter(f => f.contentType?.includes('image')).length}
                                </Text>
                              </VStack>
                              <VStack>
                                <Text fontSize="sm" color="gray.600">Videos</Text>
                                <Text fontSize="2xl" fontWeight="bold" color="orange.500">
                                  {selectedBackup.storageFiles.filter(f => f.contentType?.includes('video')).length}
                                </Text>
                              </VStack>
                            </SimpleGrid>
                          </CardBody>
                        </Card>
                      )}
                    </VStack>
                  </TabPanel>

                  {/* Error Tab */}
                  {selectedBackup.error && (
                    <TabPanel>
                      <Card bg="red.50" borderWidth="1px" borderColor="red.200">
                        <CardBody>
                          <VStack align="start" spacing="3">
                            <HStack>
                              <Icon as={FiAlertCircle} boxSize="6" color="red.500" />
                              <Text fontWeight="bold" fontSize="lg" color="red.700">
                                Backup Error
                              </Text>
                            </HStack>
                            <Box
                              p="4"
                              bg="white"
                              borderRadius="md"
                              borderWidth="1px"
                              borderColor="red.200"
                              w="100%"
                            >
                              <Text
                                fontFamily="monospace"
                                fontSize="sm"
                                color="red.700"
                                whiteSpace="pre-wrap"
                                wordBreak="break-word"
                              >
                                {selectedBackup.error}
                              </Text>
                            </Box>
                          </VStack>
                        </CardBody>
                      </Card>
                    </TabPanel>
                  )}
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
              <VStack align="start" spacing="3">
                <Text>
                  Are you sure you want to delete this backup record? This will remove the Firestore document.
                </Text>
                <Text fontSize="sm" color="orange.600" fontWeight="medium">
                  Note: Storage files will not be automatically deleted. You may need to manually clean up files in Firebase Storage.
                </Text>
              </VStack>
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
