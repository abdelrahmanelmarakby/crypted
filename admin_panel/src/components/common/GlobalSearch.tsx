import React, { useState } from 'react';
import {
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalCloseButton,
  Input,
  VStack,
  HStack,
  Text,
  Box,
  Badge,
  Spinner,
  Center,
  useColorModeValue,
} from '@chakra-ui/react';
import { FiUser } from 'react-icons/fi';
import { useNavigate } from 'react-router-dom';
import { searchUsers } from '@/services/userService';
import { debounce } from '@/utils/helpers';

interface GlobalSearchProps {
  isOpen: boolean;
  onClose: () => void;
}

const GlobalSearch: React.FC<GlobalSearchProps> = ({ isOpen, onClose }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [results, setResults] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const bgColor = useColorModeValue('white', 'gray.800');
  const hoverBg = useColorModeValue('gray.50', 'gray.700');

  const handleSearch = debounce(async (term: string) => {
    if (!term || term.length < 2) {
      setResults([]);
      return;
    }

    setLoading(true);
    try {
      // Search users
      const users = await searchUsers(term);

      const searchResults = users.map((user) => ({
        type: 'user',
        id: user.uid,
        title: user.full_name,
        subtitle: user.email,
        icon: FiUser,
        path: `/users/${user.uid}`,
      }));

      setResults(searchResults);
    } catch (error) {
      console.error('Search error:', error);
    } finally {
      setLoading(false);
    }
  }, 300);

  const handleResultClick = (path: string) => {
    navigate(path);
    onClose();
    setSearchTerm('');
    setResults([]);
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'user':
        return 'blue';
      case 'chat':
        return 'purple';
      case 'story':
        return 'orange';
      default:
        return 'gray';
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} size="xl">
      <ModalOverlay />
      <ModalContent>
        <ModalHeader>Search</ModalHeader>
        <ModalCloseButton />
        <ModalBody pb="6">
          <VStack spacing="4" align="stretch">
            <Input
              placeholder="Search users, chats, stories..."
              size="lg"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                handleSearch(e.target.value);
              }}
              autoFocus
            />

            {loading && (
              <Center py="8">
                <Spinner color="brand.500" />
              </Center>
            )}

            {!loading && results.length === 0 && searchTerm.length >= 2 && (
              <Center py="8">
                <Text color="gray.500">No results found</Text>
              </Center>
            )}

            {!loading && results.length > 0 && (
              <VStack spacing="2" align="stretch" maxH="400px" overflowY="auto">
                {results.map((result) => (
                  <Box
                    key={result.id}
                    p="3"
                    borderRadius="md"
                    cursor="pointer"
                    bg={bgColor}
                    _hover={{ bg: hoverBg }}
                    onClick={() => handleResultClick(result.path)}
                  >
                    <HStack spacing="3">
                      <Box
                        p="2"
                        borderRadius="md"
                        bg={`${getTypeColor(result.type)}.50`}
                        color={`${getTypeColor(result.type)}.500`}
                      >
                        <result.icon />
                      </Box>
                      <Box flex="1">
                        <Text fontWeight="medium" mb="1">
                          {result.title}
                        </Text>
                        <Text fontSize="sm" color="gray.500">
                          {result.subtitle}
                        </Text>
                      </Box>
                      <Badge colorScheme={getTypeColor(result.type)}>{result.type}</Badge>
                    </HStack>
                  </Box>
                ))}
              </VStack>
            )}
          </VStack>
        </ModalBody>
      </ModalContent>
    </Modal>
  );
};

export default GlobalSearch;
