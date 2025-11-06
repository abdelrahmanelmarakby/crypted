import React from 'react';
import {
  Box,
  Heading,
  Card,
  CardHeader,
  CardBody,
  Text,
  VStack,
  FormControl,
  FormLabel,
  Switch,
  Button,
  Divider,
  SimpleGrid,
  Input,
  Select,
  useToast,
} from '@chakra-ui/react';
import { FiSave } from 'react-icons/fi';

const Settings: React.FC = () => {
  const toast = useToast();

  const handleSaveSettings = () => {
    toast({
      title: 'Settings saved',
      description: 'Your changes have been saved successfully',
      status: 'success',
      duration: 3000,
      isClosable: true,
    });
  };

  return (
    <Box>
      <Heading size="lg" mb="2">
        Settings
      </Heading>
      <Text color="gray.600" mb="6">
        Manage application settings and configurations
      </Text>

      <SimpleGrid columns={{ base: 1, lg: 2 }} spacing="6">
        {/* App Settings */}
        <Card>
          <CardHeader>
            <Heading size="md">Application Settings</Heading>
          </CardHeader>
          <CardBody>
            <VStack spacing="4" align="stretch">
              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="maintenance-mode" mb="0">
                  Maintenance Mode
                </FormLabel>
                <Switch id="maintenance-mode" colorScheme="brand" />
              </FormControl>

              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="registration" mb="0">
                  Allow New Registrations
                </FormLabel>
                <Switch id="registration" colorScheme="brand" defaultChecked />
              </FormControl>

              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="stories" mb="0">
                  Enable Stories Feature
                </FormLabel>
                <Switch id="stories" colorScheme="brand" defaultChecked />
              </FormControl>

              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="calls" mb="0">
                  Enable Voice/Video Calls
                </FormLabel>
                <Switch id="calls" colorScheme="brand" defaultChecked />
              </FormControl>

              <Divider />

              <FormControl>
                <FormLabel>Minimum App Version</FormLabel>
                <Input placeholder="1.0.0" />
              </FormControl>

              <FormControl>
                <FormLabel>Maximum Story Duration (seconds)</FormLabel>
                <Input type="number" defaultValue="30" />
              </FormControl>

              <FormControl>
                <FormLabel>Maximum Message Length</FormLabel>
                <Input type="number" defaultValue="5000" />
              </FormControl>
            </VStack>
          </CardBody>
        </Card>

        {/* Security Settings */}
        <Card>
          <CardHeader>
            <Heading size="md">Security Settings</Heading>
          </CardHeader>
          <CardBody>
            <VStack spacing="4" align="stretch">
              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="2fa" mb="0">
                  Require 2FA for Admins
                </FormLabel>
                <Switch id="2fa" colorScheme="brand" />
              </FormControl>

              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="audit-logs" mb="0">
                  Enable Audit Logs
                </FormLabel>
                <Switch id="audit-logs" colorScheme="brand" defaultChecked />
              </FormControl>

              <Divider />

              <FormControl>
                <FormLabel>Session Timeout (minutes)</FormLabel>
                <Input type="number" defaultValue="30" />
              </FormControl>

              <FormControl>
                <FormLabel>Max Login Attempts</FormLabel>
                <Input type="number" defaultValue="5" />
              </FormControl>

              <FormControl>
                <FormLabel>Rate Limit (requests/minute)</FormLabel>
                <Input type="number" defaultValue="100" />
              </FormControl>
            </VStack>
          </CardBody>
        </Card>

        {/* Notification Settings */}
        <Card>
          <CardHeader>
            <Heading size="md">Notification Settings</Heading>
          </CardHeader>
          <CardBody>
            <VStack spacing="4" align="stretch">
              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="push-notifications" mb="0">
                  Push Notifications
                </FormLabel>
                <Switch id="push-notifications" colorScheme="brand" defaultChecked />
              </FormControl>

              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="email-notifications" mb="0">
                  Email Notifications
                </FormLabel>
                <Switch id="email-notifications" colorScheme="brand" defaultChecked />
              </FormControl>

              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="alert-new-reports" mb="0">
                  Alert on New Reports
                </FormLabel>
                <Switch id="alert-new-reports" colorScheme="brand" defaultChecked />
              </FormControl>

              <Divider />

              <FormControl>
                <FormLabel>Admin Email</FormLabel>
                <Input type="email" placeholder="admin@crypted.com" />
              </FormControl>
            </VStack>
          </CardBody>
        </Card>

        {/* Backup Settings */}
        <Card>
          <CardHeader>
            <Heading size="md">Backup & Data</Heading>
          </CardHeader>
          <CardBody>
            <VStack spacing="4" align="stretch">
              <FormControl display="flex" alignItems="center" justifyContent="space-between">
                <FormLabel htmlFor="auto-backup" mb="0">
                  Automatic Backups
                </FormLabel>
                <Switch id="auto-backup" colorScheme="brand" defaultChecked />
              </FormControl>

              <FormControl>
                <FormLabel>Backup Frequency</FormLabel>
                <Select defaultValue="daily">
                  <option value="hourly">Hourly</option>
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                </Select>
              </FormControl>

              <FormControl>
                <FormLabel>Data Retention (days)</FormLabel>
                <Input type="number" defaultValue="90" />
              </FormControl>

              <Divider />

              <Button colorScheme="blue" variant="outline">
                Backup Now
              </Button>

              <Button colorScheme="orange" variant="outline">
                Export All Data
              </Button>
            </VStack>
          </CardBody>
        </Card>
      </SimpleGrid>

      {/* Save Button */}
      <Box mt="6">
        <Button
          leftIcon={<FiSave />}
          colorScheme="brand"
          size="lg"
          onClick={handleSaveSettings}
        >
          Save All Settings
        </Button>
      </Box>
    </Box>
  );
};

export default Settings;
