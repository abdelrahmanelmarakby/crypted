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
} from '@chakra-ui/react';
import {
  FiMoreVertical,
  FiEye,
  FiTrash2,
  FiRefreshCw,
  FiSearch,
  FiMessageSquare,
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

  const { isOpen, onOpen, onClose } = useDisclosure();
  const toast = useToast();

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

  const filteredRooms = chatRooms.filter((room) => {
    const displayName = getRoomDisplayName(room).toLowerCase();
    const searchLower = searchTerm.toLowerCase();
    return displayName.includes(searchLower) || room.id.includes(searchLower);
  });

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
            Chat Management
          </Heading>
          <Text color="gray.600">{chatRooms.length} total chat rooms</Text>
        </Box>
        <Button leftIcon={<FiRefreshCw />} onClick={fetchChatRooms} colorScheme="brand">
          Refresh
        </Button>
      </Flex>

      {/* Search */}
      <Card mb="6" p="4">
        <InputGroup maxW="400px">
          <InputLeftElement>
            <FiSearch />
          </InputLeftElement>
          <Input
            placeholder="Search chat rooms..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </InputGroup>
      </Card>

      {/* Chat Rooms Table */}
      <Card>
        <Box overflowX="auto">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>Participants</Th>
                <Th>Type</Th>
                <Th>Last Message</Th>
                <Th>Created</Th>
                <Th>Status</Th>
                <Th>Actions</Th>
              </Tr>
            </Thead>
            <Tbody>
              {filteredRooms.map((room) => (
                <Tr key={room.id}>
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
                        <Text fontWeight="medium" noOfLines={1}>
                          {getRoomDisplayName(room)}
                        </Text>
                        <Text fontSize="sm" color="gray.500">
                          {room.membersIds?.length || 0} members
                        </Text>
                      </Box>
                    </HStack>
                  </Td>
                  <Td>
                    <Badge colorScheme={room.isGroupChat ? 'purple' : 'blue'}>
                      {room.isGroupChat ? 'Group' : 'Private'}
                    </Badge>
                  </Td>
                  <Td>
                    {room.lastMsg ? (
                      <Box>
                        <Text fontSize="sm" noOfLines={1}>
                          {truncateText(room.lastMsg || 'No message', 30)}
                        </Text>
                        <Text fontSize="xs" color="gray.500">
                          {room.lastSender || 'Unknown'}
                        </Text>
                      </Box>
                    ) : (
                      <Text fontSize="sm" color="gray.500">
                        No messages
                      </Text>
                    )}
                  </Td>
                  <Td>
                    <Text fontSize="sm" color="gray.500">-</Text>
                  </Td>
                  <Td>
                    <Badge colorScheme={room.isArchived ? 'gray' : 'green'}>
                      {room.isArchived ? 'Archived' : 'Active'}
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
                        <MenuItem icon={<FiEye />} onClick={() => handleViewMessages(room)}>
                          View Messages
                        </MenuItem>
                        <MenuItem
                          icon={<FiTrash2 />}
                          color="red.500"
                          onClick={() => handleDeleteRoom(room)}
                        >
                          Delete Room
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

      {filteredRooms.length === 0 && (
        <Center h="30vh" mt="6">
          <VStack>
            <FiMessageSquare size="48" color="gray" />
            <Text color="gray.500">No chat rooms found</Text>
          </VStack>
        </Center>
      )}

      {/* Messages Modal */}
      <Modal isOpen={isOpen} onClose={onClose} size="xl" scrollBehavior="inside">
        <ModalOverlay />
        <ModalContent maxH="80vh">
          <ModalHeader>
            Messages - {selectedRoom && getRoomDisplayName(selectedRoom)}
          </ModalHeader>
          <ModalCloseButton />
          <ModalBody pb="6">
            {loadingMessages ? (
              <Center h="200px">
                <Spinner color="brand.500" />
              </Center>
            ) : messages.length > 0 ? (
              <VStack spacing="3" align="stretch">
                {messages.map((message) => (
                  <Card key={message.id} p="3" bg={message.senderId ? 'gray.50' : 'white'}>
                    <HStack align="start" spacing="3">
                      <Avatar size="sm" name={message.senderName} />
                      <Box flex="1">
                        <HStack justify="space-between" mb="1">
                          <Text fontWeight="medium" fontSize="sm">
                            {message.senderName || 'Unknown'}
                          </Text>
                          <Text fontSize="xs" color="gray.500">
                            {formatRelativeTime(message.timestamp)}
                          </Text>
                        </HStack>
                        <Text fontSize="sm">{message.text || '[Media]'}</Text>
                        {message.type !== 'text' && (
                          <Badge size="sm" mt="1" colorScheme="purple">
                            {message.type}
                          </Badge>
                        )}
                      </Box>
                    </HStack>
                  </Card>
                ))}
              </VStack>
            ) : (
              <Center h="200px">
                <Text color="gray.500">No messages in this chat room</Text>
              </Center>
            )}
          </ModalBody>
        </ModalContent>
      </Modal>
    </Box>
  );
};

export default Chats;
