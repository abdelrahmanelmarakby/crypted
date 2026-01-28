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
  Avatar,
  AvatarGroup,
  useDisclosure,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalCloseButton,
  VStack,
  Input,
  InputGroup,
  InputLeftElement,
  SimpleGrid,
  Stat,
  StatLabel,
  StatNumber,
  StatHelpText,
  Icon,
  Tabs,
  TabList,
  Tab,
  Select,
  Tooltip,
  useColorModeValue,
  Divider,
  CardBody,
} from '@chakra-ui/react';
import {
  FiMoreVertical,
  FiEye,
  FiTrash2,
  FiRefreshCw,
  FiSearch,
  FiMessageSquare,
  FiUsers,
  FiImage,
  FiVideo,
  FiClock,
  FiActivity,
  FiArchive,
} from 'react-icons/fi';
import { getChatRooms, deleteChatRoom, getChatMessages } from '@/services/chatService';
import { ChatRoom, Message } from '@/types';
import { formatRelativeTime, truncateText } from '@/utils/helpers';

const Chats: React.FC = () => {
  const [chatRooms, setChatRooms] = useState<ChatRoom[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedRoom, setSelectedRoom] = useState<ChatRoom | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [typeFilter, setTypeFilter] = useState<'all' | 'private' | 'group'>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'archived'>('all');
  const [tabIndex, setTabIndex] = useState(0);

  const { isOpen, onOpen, onClose } = useDisclosure();
  const toast = useToast();
  const cardBg = useColorModeValue('white', 'gray.800');

  useEffect(() => {
    fetchChatRooms();
  }, []);

  const fetchChatRooms = async () => {
    try {
      setLoading(true);
      const rooms = await getChatRooms(100);
      setChatRooms(rooms);
    } catch (error) {
      toast({
        title: 'Error loading chat rooms',
        description: 'Failed to fetch chat rooms',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  const handleViewMessages = async (room: ChatRoom) => {
    try {
      setSelectedRoom(room);
      setLoadingMessages(true);
      onOpen();

      const roomMessages = await getChatMessages(room.id, 100);
      setMessages(roomMessages);
    } catch (error) {
      toast({
        title: 'Error loading messages',
        description: 'Failed to fetch messages',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoadingMessages(false);
    }
  };

  const handleDeleteRoom = async (room: ChatRoom) => {
    const memberCount = room.membersIds?.length || 0;
    if (!window.confirm(`Delete chat room with ${memberCount} members?`)) {
      return;
    }

    try {
      await deleteChatRoom(room.id);
      toast({
        title: 'Chat room deleted',
        description: 'The chat room has been deleted successfully',
        status: 'success',
        duration: 3000,
        isClosable: true,
      });
      fetchChatRooms();
    } catch (error) {
      toast({
        title: 'Delete failed',
        description: 'Failed to delete chat room',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

  const getRoomDisplayName = (room: ChatRoom): string => {
    if (room.name) return room.name;
    if (room.isGroupChat) return 'Group Chat';

    const members = room.members || [];
    if (members.length === 0) return 'Unknown';

    return members.map((m) => m?.full_name || 'Unknown').join(', ');
  };

  // Calculate statistics
  const statistics = useMemo(() => {
    const total = chatRooms.length;
    const groupChats = chatRooms.filter(r => r.isGroupChat).length;
    const privateChats = total - groupChats;
    const activeChats = chatRooms.filter(r => !r.isArchived).length;
    const archivedChats = chatRooms.filter(r => r.isArchived).length;

    // Calculate chats with activity in last 24h
    const now = new Date();
    const last24h = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const recentlyActive = chatRooms.filter(r => {
      if (!r.lastTime) return false;
      const lastTime = (r.lastTime as any).toDate ? (r.lastTime as any).toDate() : new Date(r.lastTime as any);
      return lastTime >= last24h;
    }).length;

    return {
      total,
      groupChats,
      privateChats,
      activeChats,
      archivedChats,
      recentlyActive,
    };
  }, [chatRooms]);

  // Filter rooms based on search, type, and status
  const filteredRooms = useMemo(() => {
    return chatRooms.filter((room) => {
      // Search filter
      const displayName = getRoomDisplayName(room).toLowerCase();
      const searchLower = searchTerm.toLowerCase();
      const matchesSearch = displayName.includes(searchLower) || room.id.includes(searchLower);

      // Type filter
      let matchesType = true;
      if (typeFilter === 'group') matchesType = room.isGroupChat === true;
      if (typeFilter === 'private') matchesType = room.isGroupChat !== true;

      // Status filter
      let matchesStatus = true;
      if (statusFilter === 'active') matchesStatus = !room.isArchived;
      if (statusFilter === 'archived') matchesStatus = room.isArchived === true;

      // Tab filter
      let matchesTab = true;
      if (tabIndex === 1) matchesTab = room.isGroupChat === true; // Group chats
      if (tabIndex === 2) matchesTab = room.isGroupChat !== true; // Private chats
      if (tabIndex === 3) matchesTab = room.isArchived === true; // Archived

      return matchesSearch && matchesType && matchesStatus && matchesTab;
    });
  }, [chatRooms, searchTerm, typeFilter, statusFilter, tabIndex]);

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
      <Flex justify="space-between" align="center" mb="8">
        <Box>
          <Heading size="xl" mb="2" fontWeight="extrabold">
            Chat Management
          </Heading>
          <HStack spacing="2">
            <Icon as={FiMessageSquare} color="purple.500" />
            <Text color="gray.600" fontSize="md">
              Manage and monitor all chat conversations
            </Text>
          </HStack>
        </Box>
        <Button
          leftIcon={<FiRefreshCw />}
          onClick={fetchChatRooms}
          colorScheme="brand"
          size="md"
          borderRadius="lg"
        >
          Refresh
        </Button>
      </Flex>

      {/* Statistics Cards */}
      <SimpleGrid columns={{ base: 1, md: 2, lg: 4 }} spacing="6" mb="8">
        <Card bg={cardBg} borderRadius="xl" boxShadow="md" _hover={{ boxShadow: 'lg' }} transition="all 0.3s">
          <CardBody>
            <Flex justify="space-between" align="start">
              <Stat>
                <StatLabel color="gray.600" fontSize="sm" fontWeight="semibold" mb="2">
                  Total Chats
                </StatLabel>
                <StatNumber fontSize="4xl" fontWeight="extrabold" mb="1">
                  {statistics.total}
                </StatNumber>
                <StatHelpText fontSize="sm" color="gray.500">
                  All conversations
                </StatHelpText>
              </Stat>
              <Box p="3" borderRadius="lg" bg="purple.50">
                <Icon as={FiMessageSquare} boxSize="6" color="purple.500" />
              </Box>
            </Flex>
          </CardBody>
        </Card>

        <Card bg={cardBg} borderRadius="xl" boxShadow="md" _hover={{ boxShadow: 'lg' }} transition="all 0.3s">
          <CardBody>
            <Flex justify="space-between" align="start">
              <Stat>
                <StatLabel color="gray.600" fontSize="sm" fontWeight="semibold" mb="2">
                  Group Chats
                </StatLabel>
                <StatNumber fontSize="4xl" fontWeight="extrabold" mb="1">
                  {statistics.groupChats}
                </StatNumber>
                <StatHelpText fontSize="sm" color="gray.500">
                  {statistics.privateChats} private chats
                </StatHelpText>
              </Stat>
              <Box p="3" borderRadius="lg" bg="blue.50">
                <Icon as={FiUsers} boxSize="6" color="blue.500" />
              </Box>
            </Flex>
          </CardBody>
        </Card>

        <Card bg={cardBg} borderRadius="xl" boxShadow="md" _hover={{ boxShadow: 'lg' }} transition="all 0.3s">
          <CardBody>
            <Flex justify="space-between" align="start">
              <Stat>
                <StatLabel color="gray.600" fontSize="sm" fontWeight="semibold" mb="2">
                  Active (24h)
                </StatLabel>
                <StatNumber fontSize="4xl" fontWeight="extrabold" mb="1">
                  {statistics.recentlyActive}
                </StatNumber>
                <StatHelpText fontSize="sm" color="gray.500">
                  Recently active
                </StatHelpText>
              </Stat>
              <Box p="3" borderRadius="lg" bg="green.50">
                <Icon as={FiActivity} boxSize="6" color="green.500" />
              </Box>
            </Flex>
          </CardBody>
        </Card>

        <Card bg={cardBg} borderRadius="xl" boxShadow="md" _hover={{ boxShadow: 'lg' }} transition="all 0.3s">
          <CardBody>
            <Flex justify="space-between" align="start">
              <Stat>
                <StatLabel color="gray.600" fontSize="sm" fontWeight="semibold" mb="2">
                  Archived
                </StatLabel>
                <StatNumber fontSize="4xl" fontWeight="extrabold" mb="1">
                  {statistics.archivedChats}
                </StatNumber>
                <StatHelpText fontSize="sm" color="gray.500">
                  {statistics.activeChats} active
                </StatHelpText>
              </Stat>
              <Box p="3" borderRadius="lg" bg="gray.100">
                <Icon as={FiArchive} boxSize="6" color="gray.500" />
              </Box>
            </Flex>
          </CardBody>
        </Card>
      </SimpleGrid>

      {/* Search and Filters */}
      <Card mb="6" p="4" bg={cardBg} borderRadius="xl" boxShadow="md">
        <Flex gap="4" wrap="wrap" align="center">
          <InputGroup maxW="400px" flex="1">
            <InputLeftElement>
              <FiSearch />
            </InputLeftElement>
            <Input
              placeholder="Search chat rooms..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              borderRadius="lg"
            />
          </InputGroup>

          <Select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value as any)}
            maxW="200px"
            borderRadius="lg"
          >
            <option value="all">All Types</option>
            <option value="private">Private Chats</option>
            <option value="group">Group Chats</option>
          </Select>

          <Select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as any)}
            maxW="200px"
            borderRadius="lg"
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="archived">Archived</option>
          </Select>

          <Badge colorScheme="purple" fontSize="md" px="3" py="2" borderRadius="lg">
            {filteredRooms.length} results
          </Badge>
        </Flex>
      </Card>

      {/* Tabs */}
      <Tabs
        index={tabIndex}
        onChange={setTabIndex}
        colorScheme="purple"
        variant="enclosed"
        mb="6"
      >
        <TabList>
          <Tab fontWeight="semibold">All Chats ({statistics.total})</Tab>
          <Tab fontWeight="semibold">Group ({statistics.groupChats})</Tab>
          <Tab fontWeight="semibold">Private ({statistics.privateChats})</Tab>
          <Tab fontWeight="semibold">Archived ({statistics.archivedChats})</Tab>
        </TabList>
      </Tabs>

      {/* Chat Rooms Table */}
      <Card bg={cardBg} borderRadius="xl" boxShadow="lg">
        <Box overflowX="auto">
          <Table variant="simple">
            <Thead bg={useColorModeValue('gray.50', 'gray.700')}>
              <Tr>
                <Th>Participants</Th>
                <Th>Type</Th>
                <Th>Messages</Th>
                <Th>Last Message</Th>
                <Th>Last Activity</Th>
                <Th>Status</Th>
                <Th>Actions</Th>
              </Tr>
            </Thead>
            <Tbody>
              {filteredRooms.map((room) => {
                const lastActivity = room.lastTime
                  ? formatRelativeTime(
                      (room.lastTime as any).toDate ? (room.lastTime as any).toDate() : (room.lastTime as any)
                    )
                  : 'Never';

                const isRecentlyActive =
                  room.lastTime &&
                  new Date(
                    (room.lastTime as any).toDate ? (room.lastTime as any).toDate() : (room.lastTime as any)
                  ).getTime() > Date.now() - 24 * 60 * 60 * 1000;

                return (
                  <Tr
                    key={room.id}
                    _hover={{ bg: useColorModeValue('gray.50', 'gray.700') }}
                    transition="all 0.2s"
                  >
                    <Td>
                      <HStack spacing="3">
                        <AvatarGroup size="sm" max={3}>
                          {room.members?.map((member) => (
                            <Avatar
                              key={member?.uid}
                              name={member?.full_name}
                              src={member?.image_url}
                            />
                          ))}
                        </AvatarGroup>
                        <Box>
                          <Text fontWeight="semibold" noOfLines={1} fontSize="sm">
                            {getRoomDisplayName(room)}
                          </Text>
                          <HStack spacing="2" mt="1">
                            <Badge size="xs" colorScheme="gray" fontSize="xs">
                              {room.membersIds?.length || 0} members
                            </Badge>
                            {isRecentlyActive && (
                              <Badge size="xs" colorScheme="green" fontSize="xs">
                                <HStack spacing="1">
                                  <Icon as={FiActivity} boxSize="2" />
                                  <Text>Active</Text>
                                </HStack>
                              </Badge>
                            )}
                          </HStack>
                        </Box>
                      </HStack>
                    </Td>
                    <Td>
                      <HStack>
                        <Badge
                          colorScheme={room.isGroupChat ? 'purple' : 'blue'}
                          fontSize="xs"
                          px="2"
                          py="1"
                          borderRadius="md"
                        >
                          <HStack spacing="1">
                            <Icon
                              as={room.isGroupChat ? FiUsers : FiMessageSquare}
                              boxSize="3"
                            />
                            <Text>{room.isGroupChat ? 'Group' : 'Private'}</Text>
                          </HStack>
                        </Badge>
                      </HStack>
                    </Td>
                    <Td>
                      <VStack align="start" spacing="0">
                        <Text fontSize="sm" fontWeight="bold" color="purple.500">
                          {room.messageCount || 0}
                        </Text>
                        <Text fontSize="xs" color="gray.500">
                          messages
                        </Text>
                      </VStack>
                    </Td>
                    <Td maxW="300px">
                      {room.lastMsg ? (
                        <Box>
                          <Text fontSize="sm" noOfLines={1} mb="1">
                            {truncateText(room.lastMsg || 'No message', 40)}
                          </Text>
                          <HStack spacing="2">
                            <Text fontSize="xs" color="gray.500" fontWeight="medium">
                              {room.lastSender || 'Unknown'}
                            </Text>
                            {room.lastMsgType && room.lastMsgType !== 'text' && (
                              <Badge size="xs" colorScheme="purple" fontSize="xs">
                                <HStack spacing="1">
                                  <Icon
                                    as={
                                      room.lastMsgType === 'image'
                                        ? FiImage
                                        : room.lastMsgType === 'video'
                                        ? FiVideo
                                        : FiMessageSquare
                                    }
                                    boxSize="2"
                                  />
                                  <Text>{room.lastMsgType}</Text>
                                </HStack>
                              </Badge>
                            )}
                          </HStack>
                        </Box>
                      ) : (
                        <Text fontSize="sm" color="gray.400" fontStyle="italic">
                          No messages yet
                        </Text>
                      )}
                    </Td>
                    <Td>
                      <Tooltip label={lastActivity} placement="top">
                        <HStack spacing="1">
                          <Icon as={FiClock} boxSize="3" color="gray.400" />
                          <Text fontSize="sm" color="gray.600">
                            {lastActivity}
                          </Text>
                        </HStack>
                      </Tooltip>
                    </Td>
                    <Td>
                      <Badge
                        colorScheme={room.isArchived ? 'gray' : 'green'}
                        fontSize="xs"
                        px="3"
                        py="1"
                        borderRadius="md"
                      >
                        {room.isArchived ? 'Archived' : 'Active'}
                      </Badge>
                    </Td>
                    <Td>
                      <HStack spacing="2">
                        <Tooltip label="View messages" placement="top">
                          <IconButton
                            icon={<FiEye />}
                            size="sm"
                            variant="ghost"
                            colorScheme="blue"
                            onClick={() => handleViewMessages(room)}
                            aria-label="View messages"
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
                            <MenuItem icon={<FiEye />} onClick={() => handleViewMessages(room)}>
                              View Messages
                            </MenuItem>
                            <Divider />
                            <MenuItem
                              icon={<FiTrash2 />}
                              color="red.500"
                              onClick={() => handleDeleteRoom(room)}
                            >
                              Delete Room
                            </MenuItem>
                          </MenuList>
                        </Menu>
                      </HStack>
                    </Td>
                  </Tr>
                );
              })}
            </Tbody>
          </Table>
        </Box>
      </Card>

      {filteredRooms.length === 0 && (
        <Center h="30vh" mt="6">
          <VStack>
            <FiMessageSquare size="48" color="gray" />
            <Text color="gray.500">No chat rooms found</Text>
          </VStack>
        </Center>
      )}

      {/* Messages Modal */}
      <Modal isOpen={isOpen} onClose={onClose} size="2xl" scrollBehavior="inside">
        <ModalOverlay backdropFilter="blur(4px)" />
        <ModalContent maxH="85vh" borderRadius="xl">
          <ModalHeader bg={useColorModeValue('gray.50', 'gray.700')} borderTopRadius="xl">
            <VStack align="start" spacing="2">
              <HStack spacing="3">
                {selectedRoom && (
                  <AvatarGroup size="sm" max={3}>
                    {selectedRoom.members?.map((member) => (
                      <Avatar
                        key={member?.uid}
                        name={member?.full_name}
                        src={member?.image_url}
                      />
                    ))}
                  </AvatarGroup>
                )}
                <Box>
                  <Text fontSize="lg" fontWeight="bold">
                    {selectedRoom && getRoomDisplayName(selectedRoom)}
                  </Text>
                  <HStack spacing="2" mt="1">
                    <Badge
                      colorScheme={selectedRoom?.isGroupChat ? 'purple' : 'blue'}
                      fontSize="xs"
                    >
                      {selectedRoom?.isGroupChat ? 'Group Chat' : 'Private Chat'}
                    </Badge>
                    <Badge colorScheme="gray" fontSize="xs">
                      {selectedRoom?.membersIds?.length || 0} members
                    </Badge>
                    <Badge colorScheme="purple" fontSize="xs">
                      {messages.length} messages
                    </Badge>
                  </HStack>
                </Box>
              </HStack>
            </VStack>
          </ModalHeader>
          <ModalCloseButton />
          <ModalBody py="6" bg={useColorModeValue('gray.50', 'gray.800')}>
            {loadingMessages ? (
              <Center h="300px">
                <VStack spacing="4">
                  <Spinner size="xl" color="brand.500" thickness="4px" />
                  <Text color="gray.500">Loading messages...</Text>
                </VStack>
              </Center>
            ) : messages.length > 0 ? (
              <VStack spacing="3" align="stretch">
                {messages.map((message, index) => {
                  const isFirstFromUser =
                    index === 0 || messages[index - 1].senderId !== message.senderId;

                  return (
                    <Box key={message.id}>
                      {isFirstFromUser && (
                        <HStack spacing="2" mb="2" ml="2">
                          <Avatar size="xs" name={message.senderName} />
                          <Text fontSize="xs" fontWeight="bold" color="gray.600">
                            {message.senderName || 'Unknown'}
                          </Text>
                        </HStack>
                      )}
                      <Card
                        p="4"
                        bg={useColorModeValue('white', 'gray.700')}
                        borderRadius="lg"
                        boxShadow="sm"
                        ml={isFirstFromUser ? 0 : 8}
                        _hover={{ boxShadow: 'md' }}
                        transition="all 0.2s"
                      >
                        <HStack align="start" spacing="3" justify="space-between">
                          <Box flex="1">
                            {message.text ? (
                              <Text fontSize="sm" whiteSpace="pre-wrap">
                                {message.text}
                              </Text>
                            ) : (
                              <HStack spacing="2">
                                <Icon
                                  as={
                                    message.type === 'image'
                                      ? FiImage
                                      : message.type === 'video'
                                      ? FiVideo
                                      : FiMessageSquare
                                  }
                                  color="purple.500"
                                />
                                <Text fontSize="sm" color="gray.500" fontStyle="italic">
                                  {message.type === 'image' && 'Image'}
                                  {message.type === 'video' && 'Video'}
                                  {message.type === 'audio' && 'Audio'}
                                  {message.type === 'file' && 'File'}
                                  {!['image', 'video', 'audio', 'file'].includes(
                                    message.type
                                  ) && 'Media'}
                                </Text>
                              </HStack>
                            )}
                            {message.type !== 'text' && (
                              <Badge size="sm" mt="2" colorScheme="purple" fontSize="xs">
                                <HStack spacing="1">
                                  <Icon
                                    as={
                                      message.type === 'image'
                                        ? FiImage
                                        : message.type === 'video'
                                        ? FiVideo
                                        : FiMessageSquare
                                    }
                                    boxSize="2"
                                  />
                                  <Text>{message.type}</Text>
                                </HStack>
                              </Badge>
                            )}
                          </Box>
                          <Tooltip
                            label={new Date((message.timestamp as any).toDate ? (message.timestamp as any).toDate() : message.timestamp).toLocaleString()}
                            placement="top"
                          >
                            <Text fontSize="xs" color="gray.500" whiteSpace="nowrap">
                              {formatRelativeTime(message.timestamp)}
                            </Text>
                          </Tooltip>
                        </HStack>
                      </Card>
                    </Box>
                  );
                })}
              </VStack>
            ) : (
              <Center h="300px">
                <VStack spacing="3">
                  <Icon as={FiMessageSquare} boxSize="12" color="gray.300" />
                  <Text color="gray.500" fontSize="lg">
                    No messages in this chat room
                  </Text>
                  <Text color="gray.400" fontSize="sm">
                    Messages will appear here when users start chatting
                  </Text>
                </VStack>
              </Center>
            )}
          </ModalBody>
        </ModalContent>
      </Modal>
    </Box>
  );
};

export default Chats;
