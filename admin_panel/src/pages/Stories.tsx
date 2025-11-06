import React, { useEffect, useState } from 'react';
import {
  Box,
  Heading,
  Card,
  SimpleGrid,
  Image,
  Text,
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
  HStack,
  Avatar,
  Select,
  useDisclosure,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalCloseButton,
  ModalFooter,
} from '@chakra-ui/react';
import { FiMoreVertical, FiEye, FiTrash2, FiRefreshCw, FiPlay } from 'react-icons/fi';
import { getStories, deleteStory } from '@/services/storyService';
import { Story } from '@/types';
import { formatRelativeTime, getStatusColor } from '@/utils/helpers';

const Stories: React.FC = () => {
  const [stories, setStories] = useState<Story[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'active' | 'expired'>('all');
  const [selectedStory, setSelectedStory] = useState<Story | null>(null);
  const { isOpen, onOpen, onClose } = useDisclosure();

  const toast = useToast();

  useEffect(() => {
    fetchStories();
  }, [filter]);

  const fetchStories = async () => {
    try {
      setLoading(true);
      const fetchedStories =
        filter === 'all'
          ? await getStories(undefined, 100)
          : await getStories(filter as 'active' | 'expired', 100);
      setStories(fetchedStories);
    } catch (error) {
      toast({
        title: 'Error loading stories',
        description: 'Failed to fetch stories',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteStory = async (story: Story) => {
    setSelectedStory(story);
    onOpen();
  };

  const confirmDelete = async () => {
    if (!selectedStory) return;

    try {
      await deleteStory(selectedStory.id);
      toast({
        title: 'Story deleted',
        description: 'The story has been deleted successfully',
        status: 'success',
        duration: 3000,
        isClosable: true,
      });
      fetchStories();
      onClose();
    } catch (error) {
      toast({
        title: 'Delete failed',
        description: 'Failed to delete story',
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
          <Heading size="lg" mb="2">
            Stories Management
          </Heading>
          <Text color="gray.600">{stories.length} total stories</Text>
        </Box>
        <HStack>
          <Select
            value={filter}
            onChange={(e) => setFilter(e.target.value as any)}
            maxW="200px"
          >
            <option value="all">All Stories</option>
            <option value="active">Active</option>
            <option value="expired">Expired</option>
          </Select>
          <Button leftIcon={<FiRefreshCw />} onClick={fetchStories} colorScheme="brand">
            Refresh
          </Button>
        </HStack>
      </Flex>

      {/* Stories Grid */}
      <SimpleGrid columns={{ base: 1, sm: 2, md: 3, lg: 4, xl: 5 }} spacing="6">
        {stories.map((story) => (
          <Card key={story.id} position="relative" overflow="hidden">
            {/* Story Preview */}
            <Box position="relative" h="300px" bg="gray.100">
              {story.storyType === 'image' && story.storyFileUrl && (
                <Image
                  src={story.storyFileUrl}
                  alt="Story"
                  w="full"
                  h="full"
                  objectFit="cover"
                />
              )}
              {story.storyType === 'video' && story.storyFileUrl && (
                <Box position="relative" w="full" h="full" bg="black">
                  <video
                    src={story.storyFileUrl}
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                  <Center position="absolute" top="0" left="0" w="full" h="full">
                    <Box
                      bg="blackAlpha.600"
                      p="4"
                      borderRadius="full"
                      display="flex"
                      alignItems="center"
                      justifyContent="center"
                    >
                      <FiPlay size="32" color="white" />
                    </Box>
                  </Center>
                </Box>
              )}
              {story.storyType === 'text' && (
                <Center h="full" bg="brand.500" color="white" p="4">
                  <Text fontSize="lg" fontWeight="bold" textAlign="center">
                    {story.storyText}
                  </Text>
                </Center>
              )}

              {/* Actions Menu */}
              <Box position="absolute" top="2" right="2">
                <Menu>
                  <MenuButton
                    as={IconButton}
                    icon={<FiMoreVertical />}
                    variant="solid"
                    bg="blackAlpha.600"
                    color="white"
                    size="sm"
                    _hover={{ bg: 'blackAlpha.800' }}
                  />
                  <MenuList>
                    <MenuItem icon={<FiEye />}>View Details</MenuItem>
                    <MenuItem icon={<FiTrash2 />} color="red.500" onClick={() => handleDeleteStory(story)}>
                      Delete Story
                    </MenuItem>
                  </MenuList>
                </Menu>
              </Box>

              {/* Status Badge */}
              <Box position="absolute" top="2" left="2">
                <Badge colorScheme={getStatusColor(story.status)} fontSize="xs">
                  {story.status}
                </Badge>
              </Box>
            </Box>

            {/* Story Info */}
            <Box p="4">
              <HStack spacing="3" mb="2">
                <Avatar size="sm" name={story.user.full_name} src={story.user.image_url} />
                <Box flex="1" overflow="hidden">
                  <Text fontWeight="medium" fontSize="sm" noOfLines={1}>
                    {story.user.full_name}
                  </Text>
                  <Text fontSize="xs" color="gray.500">
                    {formatRelativeTime(story.createdAt)}
                  </Text>
                </Box>
              </HStack>
              <HStack justify="space-between" fontSize="sm">
                <Text color="gray.600">
                  <FiEye style={{ display: 'inline', marginRight: '4px' }} />
                  {story.viewedBy?.length || 0} views
                </Text>
                <Badge colorScheme="purple">{story.storyType}</Badge>
              </HStack>
            </Box>
          </Card>
        ))}
      </SimpleGrid>

      {stories.length === 0 && (
        <Center h="30vh">
          <Text color="gray.500">No stories found</Text>
        </Center>
      )}

      {/* Delete Confirmation Modal */}
      <Modal isOpen={isOpen} onClose={onClose}>
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>Delete Story</ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            <Text>
              Are you sure you want to delete this story? This action cannot be undone.
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
    </Box>
  );
};

export default Stories;
