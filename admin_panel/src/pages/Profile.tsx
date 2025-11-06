import React from 'react';
import {
  Box,
  Heading,
  Card,
  CardHeader,
  CardBody,
  VStack,
  HStack,
  Avatar,
  Text,
  Badge,
  Button,
  Divider,
  SimpleGrid,
  FormControl,
  FormLabel,
  Input,
  useToast,
} from '@chakra-ui/react';
import { FiSave, FiKey } from 'react-icons/fi';
import { useAuth } from '@/contexts/AuthContext';
import { formatDate } from '@/utils/helpers';

const Profile: React.FC = () => {
  const { adminUser } = useAuth();
  const toast = useToast();

  const handleSaveProfile = () => {
    toast({
      title: 'Profile Updated',
      description: 'Your profile has been updated successfully',
      status: 'success',
      duration: 3000,
      isClosable: true,
    });
  };

  const handleChangePassword = () => {
    toast({
      title: 'Password Change',
      description: 'Please use Firebase Authentication to change your password',
      status: 'info',
      duration: 5000,
      isClosable: true,
    });
  };

  const getRoleColor = (role: string): string => {
    switch (role) {
      case 'super_admin':
        return 'red';
      case 'admin':
        return 'orange';
      case 'moderator':
        return 'blue';
      case 'analyst':
        return 'green';
      default:
        return 'gray';
    }
  };

  return (
    <Box>
      <Heading size="lg" mb="6">
        My Profile
      </Heading>

      <SimpleGrid columns={{ base: 1, lg: 3 }} spacing="6">
        {/* Profile Card */}
        <Card>
          <CardBody>
            <VStack spacing="4">
              <Avatar size="2xl" name={adminUser?.displayName} />
              <Box textAlign="center">
                <Heading size="md" mb="1">
                  {adminUser?.displayName}
                </Heading>
                <Text color="gray.600" fontSize="sm" mb="2">
                  {adminUser?.email}
                </Text>
                <Badge colorScheme={getRoleColor(adminUser?.role || '')} fontSize="md" px="3" py="1">
                  {adminUser?.role}
                </Badge>
              </Box>

              <Divider />

              <VStack spacing="2" w="full" align="start">
                <HStack justify="space-between" w="full">
                  <Text fontSize="sm" fontWeight="medium">
                    User ID:
                  </Text>
                  <Text fontSize="sm" color="gray.600" fontFamily="mono">
                    {adminUser?.uid.slice(0, 8)}...
                  </Text>
                </HStack>

                <HStack justify="space-between" w="full">
                  <Text fontSize="sm" fontWeight="medium">
                    Member Since:
                  </Text>
                  <Text fontSize="sm" color="gray.600">
                    {formatDate(adminUser?.createdAt)}
                  </Text>
                </HStack>

                <HStack justify="space-between" w="full">
                  <Text fontSize="sm" fontWeight="medium">
                    Last Login:
                  </Text>
                  <Text fontSize="sm" color="gray.600">
                    {adminUser?.lastLogin ? formatDate(adminUser.lastLogin) : 'Never'}
                  </Text>
                </HStack>
              </VStack>

              <Divider />

              <Button
                leftIcon={<FiKey />}
                w="full"
                variant="outline"
                onClick={handleChangePassword}
              >
                Change Password
              </Button>
            </VStack>
          </CardBody>
        </Card>

        {/* Edit Profile */}
        <Card gridColumn={{ lg: 'span 2' }}>
          <CardHeader>
            <Heading size="md">Edit Profile</Heading>
          </CardHeader>
          <CardBody>
            <VStack spacing="4" align="stretch">
              <FormControl>
                <FormLabel>Display Name</FormLabel>
                <Input defaultValue={adminUser?.displayName} />
              </FormControl>

              <FormControl>
                <FormLabel>Email</FormLabel>
                <Input type="email" defaultValue={adminUser?.email} isDisabled />
                <Text fontSize="xs" color="gray.500" mt="1">
                  Email cannot be changed from this panel
                </Text>
              </FormControl>

              <FormControl>
                <FormLabel>Role</FormLabel>
                <Input value={adminUser?.role} isDisabled />
                <Text fontSize="xs" color="gray.500" mt="1">
                  Contact super admin to change your role
                </Text>
              </FormControl>

              <Divider />

              <Button leftIcon={<FiSave />} colorScheme="brand" onClick={handleSaveProfile}>
                Save Changes
              </Button>
            </VStack>
          </CardBody>
        </Card>

        {/* Permissions */}
        <Card gridColumn={{ base: 1, lg: 'span 3' }}>
          <CardHeader>
            <Heading size="md">Permissions & Access</Heading>
          </CardHeader>
          <CardBody>
            <SimpleGrid columns={{ base: 1, md: 2, lg: 4 }} spacing="4">
              {adminUser?.permissions.includes('all') ? (
                <Box p="3" bg="green.50" borderRadius="md">
                  <Text fontWeight="bold" color="green.800">
                    Full Access
                  </Text>
                  <Text fontSize="sm" color="green.700">
                    You have access to all features
                  </Text>
                </Box>
              ) : (
                adminUser?.permissions.map((permission) => (
                  <Box key={permission} p="3" bg="blue.50" borderRadius="md">
                    <Text fontWeight="bold" color="blue.800" fontSize="sm">
                      {permission.replace(/_/g, ' ')}
                    </Text>
                  </Box>
                ))
              )}
            </SimpleGrid>
          </CardBody>
        </Card>
      </SimpleGrid>
    </Box>
  );
};

export default Profile;
