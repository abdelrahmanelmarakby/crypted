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
  Flex,
  Button,
  useToast,
  Spinner,
  Center,
  Text,
  Select,
  Input,
  InputGroup,
  InputLeftElement,
  Alert,
  AlertIcon,
  AlertTitle,
  AlertDescription,
  VStack,
} from '@chakra-ui/react';
import { FiRefreshCw, FiSearch, FiFileText } from 'react-icons/fi';
import { getAdminLogs } from '@/services/adminService';
import { AdminLog } from '@/types';
import { formatDate, getStatusColor } from '@/utils/helpers';
import { runDiagnostics } from '@/utils/diagnostics';

const Logs: React.FC = () => {
  const [logs, setLogs] = useState<AdminLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [resourceFilter, setResourceFilter] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [runningDiagnostics, setRunningDiagnostics] = useState(false);

  const toast = useToast();

  useEffect(() => {
    fetchLogs();
  }, [resourceFilter]);

  const fetchLogs = async () => {
    try {
      setLoading(true);
      setError(null);

      console.log('📋 Logs: Fetching admin logs...');

      const fetchedLogs =
        resourceFilter === 'all'
          ? await getAdminLogs(200)
          : await getAdminLogs(200, resourceFilter);

      console.log('📋 Logs: Fetched', fetchedLogs.length, 'log entries');

      setLogs(fetchedLogs);

      if (fetchedLogs.length === 0) {
        setError('No logs found. The admin_logs collection may be empty or you may not have permission to read it.');
      }
    } catch (error: any) {
      console.error('❌ Logs: Error fetching logs:', error);
      const errorMessage = error?.message || 'Failed to fetch activity logs';
      setError(errorMessage);
      toast({
        title: 'Error loading logs',
        description: errorMessage,
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  const handleRunDiagnostics = async () => {
    setRunningDiagnostics(true);
    try {
      console.log('🔍 Running Firebase diagnostics...');
      await runDiagnostics();
      toast({
        title: 'Diagnostics Complete',
        description: 'Check the browser console for detailed results',
        status: 'info',
        duration: 5000,
        isClosable: true,
      });
    } catch (error: any) {
      console.error('❌ Diagnostics error:', error);
      toast({
        title: 'Diagnostics Failed',
        description: error?.message || 'Could not run diagnostics',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setRunningDiagnostics(false);
    }
  };

  const getActionColor = (action: string): string => {
    if (action.toLowerCase().includes('delete')) return 'red';
    if (action.toLowerCase().includes('create')) return 'green';
    if (action.toLowerCase().includes('update')) return 'blue';
    if (action.toLowerCase().includes('suspend')) return 'orange';
    return 'gray';
  };

  const filteredLogs = logs.filter(
    (log) =>
      log.adminName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.action?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.resourceId?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <Center h="50vh">
        <Spinner size="xl" color="brand.500" thickness="4px" />
      </Center>
    );
  }

  return (
    <Box>
      {/* Error Alert */}
      {error && logs.length === 0 && (
        <Alert status="warning" mb="6" borderRadius="md">
          <AlertIcon />
          <Box flex="1">
            <AlertTitle>No Logs Found</AlertTitle>
            <AlertDescription display="block">
              {error}
              <Button
                size="sm"
                colorScheme="orange"
                variant="outline"
                ml="4"
                mt="2"
                onClick={handleRunDiagnostics}
                isLoading={runningDiagnostics}
              >
                Run Diagnostics
              </Button>
            </AlertDescription>
          </Box>
        </Alert>
      )}

      {/* Header */}
      <Flex justify="space-between" align="center" mb="6">
        <Box>
          <Heading size="lg" mb="2">
            Activity Logs
          </Heading>
          <Text color="gray.600">{logs.length} total log entries</Text>
        </Box>
        <Button leftIcon={<FiRefreshCw />} onClick={fetchLogs} colorScheme="brand">
          Refresh
        </Button>
      </Flex>

      {/* Filters */}
      <Card mb="6" p="4">
        <Flex gap="4" wrap="wrap">
          <InputGroup maxW="400px">
            <InputLeftElement>
              <FiSearch />
            </InputLeftElement>
            <Input
              placeholder="Search logs..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </InputGroup>

          <Select
            value={resourceFilter}
            onChange={(e) => setResourceFilter(e.target.value)}
            maxW="200px"
          >
            <option value="all">All Resources</option>
            <option value="user">Users</option>
            <option value="chat">Chats</option>
            <option value="story">Stories</option>
            <option value="report">Reports</option>
            <option value="settings">Settings</option>
          </Select>
        </Flex>
      </Card>

      {/* Logs Table */}
      <Card>
        <Box overflowX="auto">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>Timestamp</Th>
                <Th>Admin</Th>
                <Th>Action</Th>
                <Th>Resource</Th>
                <Th>Resource ID</Th>
                <Th>Details</Th>
              </Tr>
            </Thead>
            <Tbody>
              {filteredLogs.map((log) => (
                <Tr key={log.id}>
                  <Td>
                    <Text fontSize="sm">{formatDate(log.timestamp, 'MMM dd, HH:mm:ss')}</Text>
                  </Td>
                  <Td>
                    <Text fontWeight="medium">{log.adminName}</Text>
                    <Text fontSize="xs" color="gray.500">
                      {log.adminId.slice(0, 8)}...
                    </Text>
                  </Td>
                  <Td>
                    <Badge colorScheme={getActionColor(log.action)}>{log.action}</Badge>
                  </Td>
                  <Td>
                    <Badge colorScheme={getStatusColor(log.resource)}>{log.resource}</Badge>
                  </Td>
                  <Td>
                    {log.resourceId ? (
                      <Text fontSize="sm" fontFamily="mono">
                        {log.resourceId.slice(0, 12)}...
                      </Text>
                    ) : (
                      <Text fontSize="sm" color="gray.400">
                        N/A
                      </Text>
                    )}
                  </Td>
                  <Td>
                    {log.details ? (
                      <Text fontSize="sm" noOfLines={2} maxW="300px">
                        {JSON.stringify(log.details)}
                      </Text>
                    ) : (
                      <Text fontSize="sm" color="gray.400">
                        No details
                      </Text>
                    )}
                  </Td>
                </Tr>
              ))}
            </Tbody>
          </Table>
        </Box>
      </Card>

      {filteredLogs.length === 0 && (
        <Center h="30vh" mt="6">
          <VStack spacing={4} textAlign="center">
            <FiFileText size="48" color="gray" style={{ margin: '0 auto 16px' }} />
            <Text color="gray.500" fontSize="lg">
              No activity logs found
            </Text>
            <Text color="gray.400" fontSize="sm">
              Admin actions will be recorded here
            </Text>
            <Button
              size="sm"
              colorScheme="blue"
              onClick={handleRunDiagnostics}
              isLoading={runningDiagnostics}
              loadingText="Running diagnostics..."
            >
              Run Diagnostics
            </Button>
          </VStack>
        </Center>
      )}
    </Box>
  );
};

export default Logs;
