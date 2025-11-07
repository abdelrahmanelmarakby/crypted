import React, { useEffect, useState } from 'react';
import {
  Box,
  Heading,
  Card,
  CardHeader,
  CardBody,
  Grid,
  GridItem,
  Avatar,
  Text,
  Badge,
  Button,
  HStack,
  VStack,
  Divider,
  useToast,
  Spinner,
  Center,
  Stat,
  StatLabel,
  StatNumber,
  SimpleGrid,
  IconButton,
} from '@chakra-ui/react';
import { FiArrowLeft, FiUserX, FiTrash2, FiMail, FiPhone, FiCalendar } from 'react-icons/fi';
import { useNavigate, useParams } from 'react-router-dom';
import { getUserById, getUserStats } from '@/services/userService';
import { User } from '@/types';
import { formatDate, formatRelativeTime, getStatusColor } from '@/utils/helpers';

const UserDetail: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  const [user, setUser] = useState<User | null>(null);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const toast = useToast();

  useEffect(() => {
    if (userId) {
      fetchUserDetails(userId);
    }
  }, [userId]);

  const fetchUserDetails = async (uid: string) => {
    try {
      setLoading(true);
      const [userData, userStats] = await Promise.all([getUserById(uid), getUserStats(uid)]);

      setUser(userData);
      setStats(userStats);
    } catch (error) {
      toast({
        title: 'Error loading user',
        description: 'Failed to fetch user details',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Center h="50vh">
        <Spinner size="xl" color="brand.500" thickness="4px" />
      </Center>
    );
  }

  if (!user) {
    return (
      <Center h="50vh">
        <Text>User not found</Text>
      </Center>
    );
  }

  return (
    <Box>
      {/* Header */}
      <HStack mb="6" spacing="4">
        <IconButton
          icon={<FiArrowLeft />}
          aria-label="Back"
          onClick={() => navigate('/users')}
          variant="ghost"
        />
        <Heading size="lg">User Details</Heading>
      </HStack>

      <Grid templateColumns={{ base: '1fr', lg: '300px 1fr' }} gap="6">
        {/* Profile Card */}
        <GridItem>
          <Card>
            <CardBody>
              <VStack spacing="4" align="center">
                <Avatar size="2xl" name={user.full_name} src={user.image_url} />
                <Box textAlign="center">
                  <Heading size="md" mb="1">
                    {user.full_name}
                  </Heading>
                  <Text color="gray.600" fontSize="sm">
                    @{user.uid.slice(0, 8)}
                  </Text>
                </Box>
                <Badge colorScheme={getStatusColor(user.status || 'active')} fontSize="md" px="3" py="1">
                  {user.status || 'active'}
                </Badge>

                <Divider />

                <VStack spacing="3" align="stretch" w="full">
                  <HStack>
                    <FiMail />
                    <Text fontSize="sm">{user.email}</Text>
                  </HStack>
                  {user.phoneNumber && (
                    <HStack>
                      <FiPhone />
                      <Text fontSize="sm">{user.phoneNumber}</Text>
                    </HStack>
                  )}
                  {user.createdAt && (
                    <HStack>
                      <FiCalendar />
                      <Text fontSize="sm">Joined {formatDate(user.createdAt)}</Text>
                    </HStack>
                  )}
                </VStack>

                <Divider />

                <VStack spacing="2" w="full">
                  <Button
                    leftIcon={<FiUserX />}
                    colorScheme="orange"
                    w="full"
                    size="sm"
                    isDisabled={user.status === 'suspended'}
                  >
                    Suspend User
                  </Button>
                  <Button
                    leftIcon={<FiTrash2 />}
                    colorScheme="red"
                    variant="outline"
                    w="full"
                    size="sm"
                  >
                    Delete User
                  </Button>
                </VStack>
              </VStack>
            </CardBody>
          </Card>
        </GridItem>

        {/* Details */}
        <GridItem>
          <VStack spacing="6" align="stretch">
            {/* Statistics */}
            <Card>
              <CardHeader>
                <Heading size="md">Statistics</Heading>
              </CardHeader>
              <CardBody>
                <SimpleGrid columns={{ base: 2, md: 4 }} spacing="6">
                  <Stat>
                    <StatLabel>Stories Posted</StatLabel>
                    <StatNumber>{stats?.storiesCount || 0}</StatNumber>
                  </Stat>
                  <Stat>
                    <StatLabel>Chat Rooms</StatLabel>
                    <StatNumber>{stats?.chatRoomsCount || 0}</StatNumber>
                  </Stat>
                  <Stat>
                    <StatLabel>Followers</StatLabel>
                    <StatNumber>{user.followers?.length || 0}</StatNumber>
                  </Stat>
                  <Stat>
                    <StatLabel>Following</StatLabel>
                    <StatNumber>{user.following?.length || 0}</StatNumber>
                  </Stat>
                </SimpleGrid>
              </CardBody>
            </Card>

            {/* Bio */}
            {user.bio && (
              <Card>
                <CardHeader>
                  <Heading size="md">Bio</Heading>
                </CardHeader>
                <CardBody>
                  <Text>{user.bio}</Text>
                </CardBody>
              </Card>
            )}

            {/* Device Info */}
            {user.deviceInfo && (
              <Card>
                <CardHeader>
                  <Heading size="md">Device Information</Heading>
                </CardHeader>
                <CardBody>
                  <SimpleGrid columns={2} spacing="4">
                    <Box>
                      <Text fontWeight="bold" fontSize="sm" color="gray.600">
                        Platform
                      </Text>
                      <Text>{user.deviceInfo.platform || 'N/A'}</Text>
                    </Box>
                    <Box>
                      <Text fontWeight="bold" fontSize="sm" color="gray.600">
                        OS Version
                      </Text>
                      <Text>{user.deviceInfo.osVersion || 'N/A'}</Text>
                    </Box>
                    <Box>
                      <Text fontWeight="bold" fontSize="sm" color="gray.600">
                        App Version
                      </Text>
                      <Text>{user.deviceInfo.appVersion || 'N/A'}</Text>
                    </Box>
                    <Box>
                      <Text fontWeight="bold" fontSize="sm" color="gray.600">
                        Device Model
                      </Text>
                      <Text>{user.deviceInfo.deviceModel || 'N/A'}</Text>
                    </Box>
                  </SimpleGrid>
                </CardBody>
              </Card>
            )}

            {/* Activity */}
            <Card>
              <CardHeader>
                <Heading size="md">Activity</Heading>
              </CardHeader>
              <CardBody>
                <VStack spacing="3" align="stretch">
                  <HStack justify="space-between">
                    <Text fontWeight="bold" fontSize="sm" color="gray.600">
                      Last Seen
                    </Text>
                    <Text>
                      {user.isOnline ? (
                        <Badge colorScheme="green">Online Now</Badge>
                      ) : (
                        formatRelativeTime(user.lastSeen)
                      )}
                    </Text>
                  </HStack>
                  {user.createdAt && (
                    <HStack justify="space-between">
                      <Text fontWeight="bold" fontSize="sm" color="gray.600">
                        Account Created
                      </Text>
                      <Text>{formatDate(user.createdAt)}</Text>
                    </HStack>
                  )}
                </VStack>
              </CardBody>
            </Card>
          </VStack>
        </GridItem>
      </Grid>
    </Box>
  );
};

export default UserDetail;
