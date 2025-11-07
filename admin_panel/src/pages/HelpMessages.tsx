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
  Select,
  useDisclosure,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalCloseButton,
  ModalFooter,
  VStack,
  HStack,
  Textarea,
  FormControl,
  FormLabel,
} from '@chakra-ui/react';
import { FiMoreVertical, FiEye, FiCheck, FiRefreshCw, FiMail, FiSend } from 'react-icons/fi';
import { collection, getDocs, query, where, limit, doc, updateDoc, Timestamp } from 'firebase/firestore';
import { db } from '@/config/firebase';
import { formatDate, formatRelativeTime } from '@/utils/helpers';
import { useAuth } from '@/contexts/AuthContext';

interface HelpMessage {
  id: string;
  fullName: string;
  email: string;
  message: string;
  requestType: 'support' | 'inquiry' | 'bugReport' | 'featureRequest' | 'recommendation' | 'complaint' | 'other';
  status: 'pending' | 'in_progress' | 'resolved' | 'closed';
  createdAt: any;
  updatedAt?: any;
  response?: string;
  adminId?: string;
  userId: string;
  attachmentUrls?: string[];
  priority: 'low' | 'medium' | 'high' | 'urgent';
}

const HelpMessages: React.FC = () => {
  const [messages, setMessages] = useState<HelpMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending' | 'in_progress' | 'resolved' | 'closed'>('all');
  const [selectedMessage, setSelectedMessage] = useState<HelpMessage | null>(null);
  const [replyText, setReplyText] = useState('');
  const [sendingReply, setSendingReply] = useState(false);

  const { isOpen, onOpen, onClose } = useDisclosure();
  const {
    isOpen: isReplyOpen,
    onOpen: onReplyOpen,
    onClose: onReplyClose,
  } = useDisclosure();
  const toast = useToast();
  const { adminUser } = useAuth();

  useEffect(() => {
    fetchHelpMessages();
  }, [filter]);

  const fetchHelpMessages = async () => {
    try {
      setLoading(true);
      const helpMessagesRef = collection(db, 'help_messages');

      let q;
      if (filter === 'all') {
        q = query(helpMessagesRef, limit(100));
      } else {
        q = query(helpMessagesRef, where('status', '==', filter), limit(100));
      }

      const snapshot = await getDocs(q);
      const fetchedMessages = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })) as HelpMessage[];

      setMessages(fetchedMessages);
    } catch (error) {
      console.error('Error fetching help messages:', error);
      toast({
        title: 'Error loading help messages',
        description: 'Failed to fetch help messages',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  const handleViewMessage = (message: HelpMessage) => {
    setSelectedMessage(message);
    onOpen();
  };

  const handleOpenReply = (message: HelpMessage) => {
    setSelectedMessage(message);
    setReplyText(message.response || '');
    onReplyOpen();
  };

  const handleSendReply = async () => {
    if (!selectedMessage || !replyText.trim()) {
      toast({
        title: 'Reply required',
        description: 'Please enter a reply message',
        status: 'warning',
        duration: 3000,
        isClosable: true,
      });
      return;
    }

    try {
      setSendingReply(true);
      const messageRef = doc(db, 'help_messages', selectedMessage.id);
      await updateDoc(messageRef, {
        response: replyText,
        adminId: adminUser?.uid || 'admin',
        status: 'resolved',
        updatedAt: Timestamp.now(),
      });

      toast({
        title: 'Reply sent successfully',
        description: 'The user will be notified via email',
        status: 'success',
        duration: 3000,
        isClosable: true,
      });

      setReplyText('');
      onReplyClose();
      fetchHelpMessages();
    } catch (error) {
      console.error('Error sending reply:', error);
      toast({
        title: 'Failed to send reply',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setSendingReply(false);
    }
  };

  const handleUpdateStatus = async (messageId: string, newStatus: string) => {
    try {
      const messageRef = doc(db, 'help_messages', messageId);
      await updateDoc(messageRef, {
        status: newStatus,
        updatedAt: Timestamp.now(),
      });

      toast({
        title: 'Status updated',
        status: 'success',
        duration: 3000,
        isClosable: true,
      });

      fetchHelpMessages();
    } catch (error) {
      console.error('Error updating status:', error);
      toast({
        title: 'Failed to update status',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

  const getRequestTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      support: 'Support',
      inquiry: 'General Inquiry',
      bugReport: 'Bug Report',
      featureRequest: 'Feature Request',
      recommendation: 'Recommendation',
      complaint: 'Complaint',
      other: 'Other',
    };
    return labels[type] || type;
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent':
        return 'red';
      case 'high':
        return 'orange';
      case 'medium':
        return 'yellow';
      case 'low':
        return 'gray';
      default:
        return 'gray';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'in_progress':
        return 'blue';
      case 'resolved':
        return 'green';
      case 'closed':
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
            Help Messages
          </Heading>
          <Text color="gray.600">
            {messages.filter((m) => m.status === 'pending').length} pending messages
          </Text>
        </Box>
        <HStack>
          <Select
            value={filter}
            onChange={(e) => setFilter(e.target.value as any)}
            maxW="200px"
          >
            <option value="all">All Messages</option>
            <option value="pending">Pending</option>
            <option value="in_progress">In Progress</option>
            <option value="resolved">Resolved</option>
            <option value="closed">Closed</option>
          </Select>
          <Button leftIcon={<FiRefreshCw />} onClick={fetchHelpMessages} colorScheme="brand">
            Refresh
          </Button>
        </HStack>
      </Flex>

      {/* Messages Table */}
      <Card>
        <Box overflowX="auto">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>User</Th>
                <Th>Type</Th>
                <Th>Priority</Th>
                <Th>Date</Th>
                <Th>Status</Th>
                <Th>Actions</Th>
              </Tr>
            </Thead>
            <Tbody>
              {messages.map((message) => (
                <Tr key={message.id}>
                  <Td>
                    <VStack align="start" spacing="0">
                      <Text fontWeight="medium" fontSize="sm">
                        {message.fullName}
                      </Text>
                      <Text fontSize="xs" color="gray.500">
                        {message.email}
                      </Text>
                    </VStack>
                  </Td>
                  <Td>
                    <Text fontSize="sm">{getRequestTypeLabel(message.requestType)}</Text>
                  </Td>
                  <Td>
                    <Badge colorScheme={getPriorityColor(message.priority)}>
                      {message.priority}
                    </Badge>
                  </Td>
                  <Td>
                    <VStack align="start" spacing="0">
                      <Text fontSize="sm">{formatDate(message.createdAt, 'MMM dd, HH:mm')}</Text>
                      <Text fontSize="xs" color="gray.500">
                        {formatRelativeTime(message.createdAt)}
                      </Text>
                    </VStack>
                  </Td>
                  <Td>
                    <Badge colorScheme={getStatusColor(message.status)}>
                      {message.status.replace('_', ' ')}
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
                        <MenuItem icon={<FiEye />} onClick={() => handleViewMessage(message)}>
                          View Details
                        </MenuItem>
                        <MenuItem icon={<FiMail />} onClick={() => handleOpenReply(message)}>
                          {message.response ? 'View/Edit Reply' : 'Send Reply'}
                        </MenuItem>
                        <MenuItem
                          icon={<FiCheck />}
                          onClick={() => handleUpdateStatus(message.id, 'in_progress')}
                          isDisabled={message.status === 'in_progress'}
                        >
                          Mark In Progress
                        </MenuItem>
                        <MenuItem
                          icon={<FiCheck />}
                          onClick={() => handleUpdateStatus(message.id, 'resolved')}
                          isDisabled={message.status === 'resolved'}
                        >
                          Mark as Resolved
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

      {messages.length === 0 && (
        <Center h="30vh" mt="6">
          <Text color="gray.500">No help messages found</Text>
        </Center>
      )}

      {/* View Message Modal */}
      <Modal isOpen={isOpen} onClose={onClose} size="xl">
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>Help Message Details</ModalHeader>
          <ModalCloseButton />
          <ModalBody pb="6">
            {selectedMessage && (
              <VStack spacing="4" align="stretch">
                <Box>
                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                    From
                  </Text>
                  <Text>{selectedMessage.fullName}</Text>
                  <Text fontSize="sm" color="gray.500">
                    {selectedMessage.email}
                  </Text>
                </Box>
                <Box>
                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                    Request Type
                  </Text>
                  <Badge colorScheme="blue">{getRequestTypeLabel(selectedMessage.requestType)}</Badge>
                </Box>
                <Box>
                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                    Message
                  </Text>
                  <Text whiteSpace="pre-wrap">{selectedMessage.message}</Text>
                </Box>
                {selectedMessage.attachmentUrls && selectedMessage.attachmentUrls.length > 0 && (
                  <Box>
                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                      Attachments
                    </Text>
                    {selectedMessage.attachmentUrls.map((url, index) => (
                      <Button
                        key={index}
                        as="a"
                        href={url}
                        target="_blank"
                        size="sm"
                        variant="outline"
                        mr="2"
                        mb="2"
                      >
                        Attachment {index + 1}
                      </Button>
                    ))}
                  </Box>
                )}
                <HStack>
                  <Box flex="1">
                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                      Priority
                    </Text>
                    <Badge colorScheme={getPriorityColor(selectedMessage.priority)}>
                      {selectedMessage.priority}
                    </Badge>
                  </Box>
                  <Box flex="1">
                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                      Status
                    </Text>
                    <Badge colorScheme={getStatusColor(selectedMessage.status)}>
                      {selectedMessage.status.replace('_', ' ')}
                    </Badge>
                  </Box>
                </HStack>
                {selectedMessage.response && (
                  <Box bg="green.50" p="4" borderRadius="md">
                    <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="2">
                      Admin Response
                    </Text>
                    <Text whiteSpace="pre-wrap">{selectedMessage.response}</Text>
                  </Box>
                )}
                <Box>
                  <Text fontWeight="bold" fontSize="sm" color="gray.600" mb="1">
                    Submitted
                  </Text>
                  <Text fontSize="sm">
                    {formatDate(selectedMessage.createdAt)} ({formatRelativeTime(selectedMessage.createdAt)})
                  </Text>
                </Box>
              </VStack>
            )}
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" mr={3} onClick={onClose}>
              Close
            </Button>
            <Button
              colorScheme="brand"
              leftIcon={<FiMail />}
              onClick={() => {
                onClose();
                handleOpenReply(selectedMessage!);
              }}
            >
              Send Reply
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>

      {/* Reply Modal */}
      <Modal isOpen={isReplyOpen} onClose={onReplyClose} size="xl">
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>
            {selectedMessage?.response ? 'Edit Reply' : 'Send Reply'}
          </ModalHeader>
          <ModalCloseButton />
          <ModalBody pb="6">
            {selectedMessage && (
              <VStack spacing="4" align="stretch">
                <Box bg="gray.50" p="4" borderRadius="md">
                  <Text fontWeight="bold" fontSize="sm" mb="2">
                    Original Message from {selectedMessage.fullName}
                  </Text>
                  <Text fontSize="sm" color="gray.600">
                    {selectedMessage.message}
                  </Text>
                </Box>
                <FormControl>
                  <FormLabel>Your Reply</FormLabel>
                  <Textarea
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    placeholder="Type your reply here..."
                    rows={8}
                  />
                </FormControl>
                <Text fontSize="sm" color="gray.500">
                  This reply will be sent to {selectedMessage.email} and saved in the database.
                </Text>
              </VStack>
            )}
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" mr={3} onClick={onReplyClose}>
              Cancel
            </Button>
            <Button
              colorScheme="brand"
              leftIcon={<FiSend />}
              onClick={handleSendReply}
              isLoading={sendingReply}
              loadingText="Sending..."
            >
              Send Reply
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </Box>
  );
};

export default HelpMessages;
