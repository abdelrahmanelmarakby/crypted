import React, { useEffect, useState } from 'react';
import {
  Box,
  Heading,
  Card,
  CardHeader,
  CardBody,
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
  SimpleGrid,
  Stat,
  StatLabel,
  StatNumber,
  StatHelpText,
  Select,
} from '@chakra-ui/react';
import { FiRefreshCw, FiPhone, FiVideo } from 'react-icons/fi';
import { getCalls, getCallStats } from '@/services/callService';
import { Call } from '@/types';
import { formatDate, formatRelativeTime, getStatusColor } from '@/utils/helpers';

const Calls: React.FC = () => {
  const [calls, setCalls] = useState<Call[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const toast = useToast();

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [callsData, statsData] = await Promise.all([getCalls(200), getCallStats()]);

      setCalls(callsData);
      setStats(statsData);
    } catch (error) {
      toast({
        title: 'Error loading calls',
        description: 'Failed to fetch call data',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  const formatDuration = (seconds: number): string => {
    if (!seconds) return 'N/A';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const filteredCalls =
    statusFilter === 'all' ? calls : calls.filter((call) => call.status === statusFilter);

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
            Call Management
          </Heading>
          <Text color="gray.600">{calls.length} total calls</Text>
        </Box>
        <Button leftIcon={<FiRefreshCw />} onClick={fetchData} colorScheme="brand">
          Refresh
        </Button>
      </Flex>

      {/* Statistics Cards */}
      {stats && (
        <SimpleGrid columns={{ base: 1, md: 2, lg: 4 }} spacing="6" mb="6">
          <Card>
            <CardBody>
              <Stat>
                <StatLabel>Total Calls</StatLabel>
                <StatNumber>{stats.totalCalls}</StatNumber>
                <StatHelpText>{stats.callsToday} today</StatHelpText>
              </Stat>
            </CardBody>
          </Card>

          <Card>
            <CardBody>
              <Stat>
                <StatLabel>Audio Calls</StatLabel>
                <StatNumber>{stats.audioCallsCount}</StatNumber>
                <StatHelpText>
                  <FiPhone style={{ display: 'inline', marginRight: '4px' }} />
                  Voice calls
                </StatHelpText>
              </Stat>
            </CardBody>
          </Card>

          <Card>
            <CardBody>
              <Stat>
                <StatLabel>Video Calls</StatLabel>
                <StatNumber>{stats.videoCallsCount}</StatNumber>
                <StatHelpText>
                  <FiVideo style={{ display: 'inline', marginRight: '4px' }} />
                  Video calls
                </StatHelpText>
              </Stat>
            </CardBody>
          </Card>

          <Card>
            <CardBody>
              <Stat>
                <StatLabel>Success Rate</StatLabel>
                <StatNumber>{stats.successRate}%</StatNumber>
                <StatHelpText>{stats.completedCalls} completed</StatHelpText>
              </Stat>
            </CardBody>
          </Card>
        </SimpleGrid>
      )}

      {/* Average Duration */}
      {stats && (
        <Card mb="6">
          <CardHeader>
            <Heading size="md">Call Statistics</Heading>
          </CardHeader>
          <CardBody>
            <SimpleGrid columns={{ base: 2, md: 4 }} spacing="6">
              <Box>
                <Text fontSize="sm" color="gray.600" mb="1">
                  Average Duration
                </Text>
                <Text fontSize="2xl" fontWeight="bold">
                  {formatDuration(stats.averageDuration)}
                </Text>
              </Box>
              <Box>
                <Text fontSize="sm" color="gray.600" mb="1">
                  Completed
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="green.500">
                  {stats.completedCalls}
                </Text>
              </Box>
              <Box>
                <Text fontSize="sm" color="gray.600" mb="1">
                  Missed
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="red.500">
                  {stats.missedCalls}
                </Text>
              </Box>
              <Box>
                <Text fontSize="sm" color="gray.600" mb="1">
                  Success Rate
                </Text>
                <Text fontSize="2xl" fontWeight="bold" color="blue.500">
                  {stats.successRate}%
                </Text>
              </Box>
            </SimpleGrid>
          </CardBody>
        </Card>
      )}

      {/* Filter */}
      <Card mb="6" p="4">
        <Select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          maxW="200px"
        >
          <option value="all">All Status</option>
          <option value="completed">Completed</option>
          <option value="missed">Missed</option>
          <option value="rejected">Rejected</option>
          <option value="cancelled">Cancelled</option>
        </Select>
      </Card>

      {/* Calls Table */}
      <Card>
        <Box overflowX="auto">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>Type</Th>
                <Th>Participants</Th>
                <Th>Duration</Th>
                <Th>Start Time</Th>
                <Th>Status</Th>
              </Tr>
            </Thead>
            <Tbody>
              {filteredCalls.map((call) => (
                <Tr key={call.id}>
                  <Td>
                    <Badge colorScheme={call.type === 'video' ? 'purple' : 'blue'}>
                      {call.type === 'video' ? (
                        <>
                          <FiVideo style={{ display: 'inline', marginRight: '4px' }} />
                          Video
                        </>
                      ) : (
                        <>
                          <FiPhone style={{ display: 'inline', marginRight: '4px' }} />
                          Audio
                        </>
                      )}
                    </Badge>
                  </Td>
                  <Td>
                    <Text fontSize="sm" fontFamily="mono">
                      {call.participants.length} participants
                    </Text>
                  </Td>
                  <Td>
                    <Text fontSize="sm">{formatDuration(call.duration || 0)}</Text>
                  </Td>
                  <Td>
                    <Text fontSize="sm">{formatDate(call.startTime, 'MMM dd, HH:mm')}</Text>
                    <Text fontSize="xs" color="gray.500">
                      {formatRelativeTime(call.startTime)}
                    </Text>
                  </Td>
                  <Td>
                    <Badge colorScheme={getStatusColor(call.status)}>{call.status}</Badge>
                  </Td>
                </Tr>
              ))}
            </Tbody>
          </Table>
        </Box>
      </Card>

      {filteredCalls.length === 0 && (
        <Center h="30vh" mt="6">
          <Text color="gray.500">No calls found</Text>
        </Center>
      )}
    </Box>
  );
};

export default Calls;
