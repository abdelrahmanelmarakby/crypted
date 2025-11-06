import React, { useState } from 'react';
import {
  Box,
  Heading,
  Card,
  CardHeader,
  CardBody,
  VStack,
  FormControl,
  FormLabel,
  Input,
  Textarea,
  Select,
  Button,
  useToast,
  SimpleGrid,
  Radio,
  RadioGroup,
  HStack,
  Text,
  Divider,
  Badge,
} from '@chakra-ui/react';
import { FiSend, FiBell } from 'react-icons/fi';

const Notifications: React.FC = () => {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [targetType, setTargetType] = useState('all');
  const [platform, setPlatform] = useState('all');
  const [sending, setSending] = useState(false);

  const toast = useToast();

  const handleSendNotification = async () => {
    if (!title || !message) {
      toast({
        title: 'Validation Error',
        description: 'Please fill in all required fields',
        status: 'error',
        duration: 3000,
        isClosable: true,
      });
      return;
    }

    try {
      setSending(true);

      // Simulate API call - in production, this would call a Firebase Cloud Function
      await new Promise((resolve) => setTimeout(resolve, 2000));

      toast({
        title: 'Notification Sent',
        description: `Notification sent to ${targetType} users`,
        status: 'success',
        duration: 5000,
        isClosable: true,
      });

      // Reset form
      setTitle('');
      setMessage('');
      setTargetType('all');
      setPlatform('all');
    } catch (error) {
      toast({
        title: 'Send Failed',
        description: 'Failed to send notification',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setSending(false);
    }
  };

  return (
    <Box>
      <Heading size="lg" mb="2">
        Send Notifications
      </Heading>
      <Text color="gray.600" mb="6">
        Send push notifications to users
      </Text>

      <SimpleGrid columns={{ base: 1, lg: 2 }} spacing="6">
        {/* Send Notification Form */}
        <Card>
          <CardHeader>
            <Heading size="md">Compose Notification</Heading>
          </CardHeader>
          <CardBody>
            <VStack spacing="4" align="stretch">
              <FormControl isRequired>
                <FormLabel>Notification Title</FormLabel>
                <Input
                  placeholder="e.g., New Feature Available!"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                />
              </FormControl>

              <FormControl isRequired>
                <FormLabel>Message</FormLabel>
                <Textarea
                  placeholder="Enter your notification message..."
                  rows={5}
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                />
              </FormControl>

              <FormControl>
                <FormLabel>Target Audience</FormLabel>
                <Select value={targetType} onChange={(e) => setTargetType(e.target.value)}>
                  <option value="all">All Users</option>
                  <option value="active">Active Users Only</option>
                  <option value="inactive">Inactive Users</option>
                  <option value="new">New Users (Last 7 days)</option>
                </Select>
              </FormControl>

              <FormControl>
                <FormLabel>Platform</FormLabel>
                <RadioGroup value={platform} onChange={setPlatform}>
                  <HStack spacing="4">
                    <Radio value="all">All Platforms</Radio>
                    <Radio value="ios">iOS</Radio>
                    <Radio value="android">Android</Radio>
                  </HStack>
                </RadioGroup>
              </FormControl>

              <Divider />

              <Button
                leftIcon={<FiSend />}
                colorScheme="brand"
                size="lg"
                onClick={handleSendNotification}
                isLoading={sending}
                loadingText="Sending..."
              >
                Send Notification
              </Button>
            </VStack>
          </CardBody>
        </Card>

        {/* Preview & Info */}
        <VStack spacing="6" align="stretch">
          {/* Preview */}
          <Card>
            <CardHeader>
              <Heading size="md">Preview</Heading>
            </CardHeader>
            <CardBody>
              <Box
                p="4"
                borderRadius="lg"
                bg="gray.50"
                border="1px"
                borderColor="gray.200"
              >
                <HStack mb="2">
                  <FiBell color="brand" />
                  <Text fontWeight="bold" fontSize="md">
                    {title || 'Notification Title'}
                  </Text>
                </HStack>
                <Text fontSize="sm" color="gray.700">
                  {message || 'Your notification message will appear here...'}
                </Text>
              </Box>
            </CardBody>
          </Card>

          {/* Info Card */}
          <Card>
            <CardHeader>
              <Heading size="md">Notification Info</Heading>
            </CardHeader>
            <CardBody>
              <VStack spacing="3" align="stretch">
                <HStack justify="space-between">
                  <Text fontSize="sm" fontWeight="medium">
                    Target:
                  </Text>
                  <Badge colorScheme="blue">{targetType}</Badge>
                </HStack>
                <HStack justify="space-between">
                  <Text fontSize="sm" fontWeight="medium">
                    Platform:
                  </Text>
                  <Badge colorScheme="purple">{platform}</Badge>
                </HStack>
                <Divider />
                <Text fontSize="xs" color="gray.500">
                  Notifications will be sent via Firebase Cloud Messaging (FCM)
                </Text>
              </VStack>
            </CardBody>
          </Card>

          {/* Quick Templates */}
          <Card>
            <CardHeader>
              <Heading size="md">Quick Templates</Heading>
            </CardHeader>
            <CardBody>
              <VStack spacing="2" align="stretch">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    setTitle('New Feature Available');
                    setMessage('Check out our latest feature! Update your app now.');
                  }}
                >
                  New Feature
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    setTitle('Security Update');
                    setMessage('Important security update available. Please update your app.');
                  }}
                >
                  Security Update
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    setTitle('Maintenance Notice');
                    setMessage(
                      'Scheduled maintenance on [date]. App may be unavailable for 2 hours.'
                    );
                  }}
                >
                  Maintenance Notice
                </Button>
              </VStack>
            </CardBody>
          </Card>
        </VStack>
      </SimpleGrid>
    </Box>
  );
};

export default Notifications;
