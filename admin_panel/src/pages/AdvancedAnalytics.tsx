import React, { useEffect, useState } from 'react';
import {
  Box,
  Heading,
  SimpleGrid,
  Card,
  CardHeader,
  CardBody,
  Text,
  useToast,
  Spinner,
  Center,
  Tabs,
  TabList,
  TabPanels,
  Tab,
  TabPanel,
  Stat,
  StatLabel,
  StatNumber,
  StatHelpText,
  StatArrow,
  Badge,
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  Progress,
  HStack,
  VStack,
  Icon,
  Select,
  Button,
  Flex,
  Alert,
  AlertIcon,
  AlertTitle,
  AlertDescription,
} from '@chakra-ui/react';
import {
  FiMessageSquare,
  FiImage,
  FiPhone,
  FiDownload,
} from 'react-icons/fi';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import {
  getAdvancedDashboardStats,
  getRetentionData,
  getEventAnalytics,
  getTimeSeriesData,
  getUserSegments,
  getUserJourneys,
} from '@/services/advancedAnalyticsService';
import { AdvancedDashboardStats, RetentionData, EventAnalytics, TimeSeriesDataPoint } from '@/types';
import { formatNumber } from '@/utils/helpers';
import { CHART_COLORS } from '@/utils/constants';
import { runDiagnostics } from '@/utils/diagnostics';

const AdvancedAnalytics: React.FC = () => {
  const [stats, setStats] = useState<AdvancedDashboardStats | null>(null);
  const [retentionData, setRetentionData] = useState<RetentionData[]>([]);
  const [eventAnalytics, setEventAnalytics] = useState<EventAnalytics[]>([]);
  const [timeSeriesData, setTimeSeriesData] = useState<TimeSeriesDataPoint[]>([]);
  const [userSegments, setUserSegments] = useState<any[]>([]);
  const [userJourneys, setUserJourneys] = useState<any>(null);
  const [selectedMetric, setSelectedMetric] = useState<'users' | 'messages' | 'stories' | 'calls'>('users');
  const [loading, setLoading] = useState(true);
  const [timeRange, setTimeRange] = useState<number>(30);
  const [runningDiagnostics, setRunningDiagnostics] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const toast = useToast();

  useEffect(() => {
    fetchAnalyticsData();
  }, [timeRange]);

  useEffect(() => {
    fetchTimeSeriesData(selectedMetric);
  }, [selectedMetric, timeRange]);

  const fetchAnalyticsData = async () => {
    try {
      setLoading(true);
      setError(null);

      console.log('📊 AdvancedAnalytics: Starting to fetch data...');

      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - timeRange);

      const [statsData, retentionDataRes, eventData, segments, journeys] = await Promise.all([
        getAdvancedDashboardStats(),
        getRetentionData(startDate, endDate),
        getEventAnalytics(startDate, endDate),
        getUserSegments(),
        getUserJourneys(),
      ]);

      console.log('📊 AdvancedAnalytics: Received stats:', statsData);
      console.log('📊 AdvancedAnalytics: DAU:', statsData.dau, 'MAU:', statsData.mau);
      console.log('📊 AdvancedAnalytics: User segments:', segments);
      console.log('📊 AdvancedAnalytics: User journeys:', journeys);

      setStats(statsData);
      setRetentionData(retentionDataRes);
      setEventAnalytics(eventData);
      setUserSegments(segments);
      setUserJourneys(journeys);

      // Check if we got zero data
      if (statsData.dau === 0 && statsData.mau === 0 && statsData.totalMessages === 0) {
        setError('No data found in Firebase collections. Collections may be empty or you may not have permission to read them.');
      }
    } catch (error: any) {
      console.error('❌ AdvancedAnalytics: Error fetching data:', error);
      const errorMessage = error?.message || 'Failed to fetch analytics data';
      setError(errorMessage);
      toast({
        title: 'Error loading analytics',
        description: errorMessage,
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  const fetchTimeSeriesData = async (metric: typeof selectedMetric) => {
    try {
      const data = await getTimeSeriesData(metric, timeRange);
      setTimeSeriesData(data);
    } catch (error) {
      console.error('Error fetching time series data:', error);
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

  if (loading) {
    return (
      <Center h="50vh">
        <Spinner size="xl" color="brand.500" thickness="4px" />
      </Center>
    );
  }

  if (!stats) {
    return (
      <Center h="50vh">
        <VStack spacing={4}>
          <Text fontSize="lg">No data available</Text>
          <Button
            colorScheme="blue"
            onClick={handleRunDiagnostics}
            isLoading={runningDiagnostics}
            loadingText="Running diagnostics..."
          >
            Run Diagnostics
          </Button>
          <Text fontSize="sm" color="gray.500">
            Check browser console for details
          </Text>
        </VStack>
      </Center>
    );
  }

  return (
    <Box>
      {/* Error Alert */}
      {error && (
        <Alert status="warning" mb="6" borderRadius="md">
          <AlertIcon />
          <Box flex="1">
            <AlertTitle>Data Issue Detected</AlertTitle>
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
            Advanced Analytics
          </Heading>
          <Text color="gray.600">Comprehensive insights into app performance and user behavior</Text>
        </Box>
        <HStack spacing="4">
          <Select value={timeRange} onChange={(e) => setTimeRange(Number(e.target.value))} w="150px">
            <option value={7}>Last 7 days</option>
            <option value={30}>Last 30 days</option>
            <option value={90}>Last 90 days</option>
            <option value={365}>Last year</option>
          </Select>
          <Button leftIcon={<FiDownload />} colorScheme="blue">
            Export
          </Button>
        </HStack>
      </Flex>

      <Tabs colorScheme="blue" variant="enclosed">
        <TabList>
          <Tab>Overview</Tab>
          <Tab>Engagement</Tab>
          <Tab>Retention</Tab>
          <Tab>Events</Tab>
          <Tab>User Behavior</Tab>
        </TabList>

        <TabPanels>
          {/* OVERVIEW TAB */}
          <TabPanel>
            {/* Key Metrics */}
            <SimpleGrid columns={{ base: 1, md: 2, lg: 4 }} spacing="6" mb="6">
              {/* DAU/MAU/WAU */}
              <Card>
                <CardBody>
                  <Stat>
                    <StatLabel>Daily Active Users</StatLabel>
                    <StatNumber>{formatNumber(stats.dau || 0)}</StatNumber>
                    <StatHelpText>
                      <StatArrow type="increase" />
                      {stats.wau && stats.dau ? ((stats.dau / stats.wau) * 100).toFixed(1) : 0}% of WAU
                    </StatHelpText>
                  </Stat>
                </CardBody>
              </Card>

              <Card>
                <CardBody>
                  <Stat>
                    <StatLabel>Weekly Active Users</StatLabel>
                    <StatNumber>{formatNumber(stats.wau || 0)}</StatNumber>
                    <StatHelpText>Last 7 days</StatHelpText>
                  </Stat>
                </CardBody>
              </Card>

              <Card>
                <CardBody>
                  <Stat>
                    <StatLabel>Monthly Active Users</StatLabel>
                    <StatNumber>{formatNumber(stats.mau || 0)}</StatNumber>
                    <StatHelpText>Last 30 days</StatHelpText>
                  </Stat>
                </CardBody>
              </Card>

              <Card>
                <CardBody>
                  <Stat>
                    <StatLabel>Stickiness (DAU/MAU)</StatLabel>
                    <StatNumber>{stats.stickiness?.toFixed(1)}%</StatNumber>
                    <StatHelpText>
                      {stats.stickiness && stats.stickiness > 20 ? (
                        <Badge colorScheme="green">Excellent</Badge>
                      ) : (
                        <Badge colorScheme="yellow">Good</Badge>
                      )}
                    </StatHelpText>
                  </Stat>
                </CardBody>
              </Card>
            </SimpleGrid>

            {/* Growth Metrics */}
            <SimpleGrid columns={{ base: 1, md: 3 }} spacing="6" mb="6">
              <Card>
                <CardBody>
                  <Stat>
                    <StatLabel>User Growth Rate</StatLabel>
                    <StatNumber>
                      {stats.user_growth_rate && stats.user_growth_rate > 0 ? (
                        <StatArrow type="increase" />
                      ) : (
                        <StatArrow type="decrease" />
                      )}
                      {Math.abs(stats.user_growth_rate || 0).toFixed(1)}%
                    </StatNumber>
                    <StatHelpText>Month over month</StatHelpText>
                  </Stat>
                </CardBody>
              </Card>

              <Card>
                <CardBody>
                  <Stat>
                    <StatLabel>New Users This Month</StatLabel>
                    <StatNumber>{formatNumber(stats.newUsersThisMonth)}</StatNumber>
                    <StatHelpText>{formatNumber(stats.newUsersToday)} today</StatHelpText>
                  </Stat>
                </CardBody>
              </Card>

              <Card>
                <CardBody>
                  <Stat>
                    <StatLabel>Avg Session Duration</StatLabel>
                    <StatNumber>
                      {Math.floor((stats.avg_session_duration || 0) / 60)}m{' '}
                      {Math.floor((stats.avg_session_duration || 0) % 60)}s
                    </StatNumber>
                    <StatHelpText>Per session</StatHelpText>
                  </Stat>
                </CardBody>
              </Card>
            </SimpleGrid>

            {/* Time Series Chart */}
            <Card mb="6">
              <CardHeader>
                <Flex justify="space-between" align="center">
                  <Heading size="md">Trend Analysis</Heading>
                  <Select
                    value={selectedMetric}
                    onChange={(e) => setSelectedMetric(e.target.value as typeof selectedMetric)}
                    w="200px"
                  >
                    <option value="users">New Users</option>
                    <option value="messages">Messages</option>
                    <option value="stories">Stories</option>
                    <option value="calls">Calls</option>
                  </Select>
                </Flex>
              </CardHeader>
              <CardBody>
                <ResponsiveContainer width="100%" height={300}>
                  <AreaChart data={timeSeriesData}>
                    <defs>
                      <linearGradient id="colorMetric" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor={CHART_COLORS[0]} stopOpacity={0.8} />
                        <stop offset="95%" stopColor={CHART_COLORS[0]} stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="label" fontSize={12} />
                    <YAxis fontSize={12} />
                    <Tooltip />
                    <Area
                      type="monotone"
                      dataKey="value"
                      stroke={CHART_COLORS[0]}
                      fillOpacity={1}
                      fill="url(#colorMetric)"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </CardBody>
            </Card>

            {/* Content Metrics */}
            <SimpleGrid columns={{ base: 1, md: 3 }} spacing="6" mb="6">
              <Card>
                <CardHeader>
                  <HStack>
                    <Icon as={FiMessageSquare} color="purple.500" />
                    <Heading size="sm">Messages</Heading>
                  </HStack>
                </CardHeader>
                <CardBody>
                  <VStack align="stretch" spacing="2">
                    <HStack justify="space-between">
                      <Text fontSize="sm" color="gray.600">
                        Total
                      </Text>
                      <Text fontWeight="bold">{formatNumber(stats.totalMessages)}</Text>
                    </HStack>
                    <HStack justify="space-between">
                      <Text fontSize="sm" color="gray.600">
                        Today
                      </Text>
                      <Text fontWeight="bold">{formatNumber(stats.messagesToday)}</Text>
                    </HStack>
                    <HStack justify="space-between">
                      <Text fontSize="sm" color="gray.600">
                        Avg per user
                      </Text>
                      <Text fontWeight="bold">{stats.avg_messages_per_user?.toFixed(1)}</Text>
                    </HStack>
                  </VStack>
                </CardBody>
              </Card>

              <Card>
                <CardHeader>
                  <HStack>
                    <Icon as={FiImage} color="orange.500" />
                    <Heading size="sm">Stories</Heading>
                  </HStack>
                </CardHeader>
                <CardBody>
                  <VStack align="stretch" spacing="2">
                    <HStack justify="space-between">
                      <Text fontSize="sm" color="gray.600">
                        Active
                      </Text>
                      <Text fontWeight="bold">{formatNumber(stats.activeStories)}</Text>
                    </HStack>
                    <HStack justify="space-between">
                      <Text fontSize="sm" color="gray.600">
                        Today
                      </Text>
                      <Text fontWeight="bold">{formatNumber(stats.storiesToday)}</Text>
                    </HStack>
                    <HStack justify="space-between">
                      <Text fontSize="sm" color="gray.600">
                        Avg per user
                      </Text>
                      <Text fontWeight="bold">{stats.avg_stories_per_user?.toFixed(1)}</Text>
                    </HStack>
                  </VStack>
                </CardBody>
              </Card>

              <Card>
                <CardHeader>
                  <HStack>
                    <Icon as={FiPhone} color="cyan.500" />
                    <Heading size="sm">Calls</Heading>
                  </HStack>
                </CardHeader>
                <CardBody>
                  <VStack align="stretch" spacing="2">
                    <HStack justify="space-between">
                      <Text fontSize="sm" color="gray.600">
                        Total
                      </Text>
                      <Text fontWeight="bold">{formatNumber(stats.totalCalls)}</Text>
                    </HStack>
                    <HStack justify="space-between">
                      <Text fontSize="sm" color="gray.600">
                        Today
                      </Text>
                      <Text fontWeight="bold">{formatNumber(stats.callsToday)}</Text>
                    </HStack>
                    <HStack justify="space-between">
                      <Text fontSize="sm" color="gray.600">
                        Avg duration
                      </Text>
                      <Text fontWeight="bold">{Math.floor(stats.averageCallDuration / 60)}m</Text>
                    </HStack>
                  </VStack>
                </CardBody>
              </Card>
            </SimpleGrid>
          </TabPanel>

          {/* ENGAGEMENT TAB */}
          <TabPanel>
            <SimpleGrid columns={{ base: 1, lg: 2 }} spacing="6">
              <Card>
                <CardHeader>
                  <Heading size="md">Engagement Breakdown</Heading>
                </CardHeader>
                <CardBody>
                  <VStack align="stretch" spacing="4">
                    <Box>
                      <HStack justify="space-between" mb="2">
                        <Text>Messages</Text>
                        <Text fontWeight="bold">{formatNumber(stats.totalMessages)}</Text>
                      </HStack>
                      <Progress
                        value={100}
                        colorScheme="purple"
                        size="sm"
                        borderRadius="full"
                      />
                    </Box>
                    <Box>
                      <HStack justify="space-between" mb="2">
                        <Text>Stories</Text>
                        <Text fontWeight="bold">{formatNumber(stats.totalStories)}</Text>
                      </HStack>
                      <Progress
                        value={(stats.totalStories / stats.totalMessages) * 100}
                        colorScheme="orange"
                        size="sm"
                        borderRadius="full"
                      />
                    </Box>
                    <Box>
                      <HStack justify="space-between" mb="2">
                        <Text>Calls</Text>
                        <Text fontWeight="bold">{formatNumber(stats.totalCalls)}</Text>
                      </HStack>
                      <Progress
                        value={(stats.totalCalls / stats.totalMessages) * 100}
                        colorScheme="cyan"
                        size="sm"
                        borderRadius="full"
                      />
                    </Box>
                  </VStack>
                </CardBody>
              </Card>

              <Card>
                <CardHeader>
                  <Heading size="md">Session Metrics</Heading>
                </CardHeader>
                <CardBody>
                  <VStack align="stretch" spacing="4">
                    <Stat>
                      <StatLabel>Avg Sessions per User</StatLabel>
                      <StatNumber>{stats.avg_sessions_per_user?.toFixed(1)}</StatNumber>
                      <StatHelpText>Last 30 days</StatHelpText>
                    </Stat>
                    <Stat>
                      <StatLabel>Avg Session Duration</StatLabel>
                      <StatNumber>
                        {Math.floor((stats.avg_session_duration || 0) / 60)} min
                      </StatNumber>
                      <StatHelpText>Time spent per session</StatHelpText>
                    </Stat>
                  </VStack>
                </CardBody>
              </Card>
            </SimpleGrid>
          </TabPanel>

          {/* RETENTION TAB */}
          <TabPanel>
            <Card>
              <CardHeader>
                <Heading size="md">Retention Analysis</Heading>
                <Text fontSize="sm" color="gray.600" mt="2">
                  Percentage of users who return after signup
                </Text>
              </CardHeader>
              <CardBody>
                <SimpleGrid columns={{ base: 1, md: 3 }} spacing="6" mb="6">
                  <Stat>
                    <StatLabel>Day 1 Retention</StatLabel>
                    <StatNumber>{stats.day1_retention?.toFixed(1)}%</StatNumber>
                    <StatHelpText>
                      {stats.day1_retention && stats.day1_retention > 40 ? (
                        <Badge colorScheme="green">Great</Badge>
                      ) : (
                        <Badge colorScheme="yellow">Fair</Badge>
                      )}
                    </StatHelpText>
                  </Stat>
                  <Stat>
                    <StatLabel>Day 7 Retention</StatLabel>
                    <StatNumber>{stats.day7_retention?.toFixed(1)}%</StatNumber>
                    <StatHelpText>
                      {stats.day7_retention && stats.day7_retention > 20 ? (
                        <Badge colorScheme="green">Great</Badge>
                      ) : (
                        <Badge colorScheme="yellow">Fair</Badge>
                      )}
                    </StatHelpText>
                  </Stat>
                  <Stat>
                    <StatLabel>Day 30 Retention</StatLabel>
                    <StatNumber>{stats.day30_retention?.toFixed(1)}%</StatNumber>
                    <StatHelpText>
                      {stats.day30_retention && stats.day30_retention > 10 ? (
                        <Badge colorScheme="green">Great</Badge>
                      ) : (
                        <Badge colorScheme="yellow">Fair</Badge>
                      )}
                    </StatHelpText>
                  </Stat>
                </SimpleGrid>

                {retentionData.length > 0 && (
                  <Box overflowX="auto">
                    <Table variant="simple">
                      <Thead>
                        <Tr>
                          <Th>Cohort Date</Th>
                          <Th isNumeric>Size</Th>
                          <Th isNumeric>Day 0</Th>
                          <Th isNumeric>Day 1</Th>
                          <Th isNumeric>Day 7</Th>
                          <Th isNumeric>Day 30</Th>
                        </Tr>
                      </Thead>
                      <Tbody>
                        {retentionData.slice(0, 10).map((cohort) => (
                          <Tr key={cohort.cohort_date}>
                            <Td>{cohort.cohort_date}</Td>
                            <Td isNumeric>{cohort.cohort_size}</Td>
                            <Td isNumeric>
                              <Badge colorScheme="green">100%</Badge>
                            </Td>
                            <Td isNumeric>{cohort.day_1?.toFixed(1)}%</Td>
                            <Td isNumeric>{cohort.day_7?.toFixed(1)}%</Td>
                            <Td isNumeric>{cohort.day_30?.toFixed(1)}%</Td>
                          </Tr>
                        ))}
                      </Tbody>
                    </Table>
                  </Box>
                )}
              </CardBody>
            </Card>
          </TabPanel>

          {/* EVENTS TAB */}
          <TabPanel>
            <Card>
              <CardHeader>
                <Heading size="md">Top Events</Heading>
                <Text fontSize="sm" color="gray.600" mt="2">
                  Most frequent user actions
                </Text>
              </CardHeader>
              <CardBody>
                {eventAnalytics.length > 0 ? (
                  <Table variant="simple">
                    <Thead>
                      <Tr>
                        <Th>Event Name</Th>
                        <Th isNumeric>Total Count</Th>
                        <Th isNumeric>Unique Users</Th>
                        <Th isNumeric>Avg per User</Th>
                      </Tr>
                    </Thead>
                    <Tbody>
                      {eventAnalytics.slice(0, 20).map((event) => (
                        <Tr key={event.event_name}>
                          <Td>
                            <Text fontWeight="medium">{event.event_name}</Text>
                          </Td>
                          <Td isNumeric>{formatNumber(event.total_count)}</Td>
                          <Td isNumeric>{formatNumber(event.unique_users)}</Td>
                          <Td isNumeric>{event.avg_per_user.toFixed(2)}</Td>
                        </Tr>
                      ))}
                    </Tbody>
                  </Table>
                ) : (
                  <Center py="10">
                    <Text color="gray.500">No event data available</Text>
                  </Center>
                )}
              </CardBody>
            </Card>
          </TabPanel>

          {/* USER BEHAVIOR TAB */}
          <TabPanel>
            <VStack spacing="6" align="stretch">
              {/* User Segments */}
              <Card>
                <CardHeader>
                  <Heading size="md">User Segments</Heading>
                  <Text fontSize="sm" color="gray.600" mt="2">
                    User distribution across different activity and engagement segments
                  </Text>
                </CardHeader>
                <CardBody>
                  {userSegments.length > 0 ? (
                    <SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} spacing="4">
                      {userSegments.map((segment, index) => (
                        <Card key={index} variant="outline" bg="gray.50">
                          <CardBody>
                            <VStack align="stretch" spacing="3">
                              <HStack justify="space-between">
                                <Text fontWeight="bold" fontSize="md">
                                  {segment.name}
                                </Text>
                                <Badge colorScheme={segment.color} fontSize="sm">
                                  {segment.percentage}%
                                </Badge>
                              </HStack>
                              <Text fontSize="2xl" fontWeight="extrabold" color={`${segment.color}.500`}>
                                {formatNumber(segment.count)}
                              </Text>
                              <Text fontSize="xs" color="gray.600">
                                {segment.description}
                              </Text>
                              <Progress
                                value={parseFloat(segment.percentage)}
                                colorScheme={segment.color}
                                size="sm"
                                borderRadius="full"
                              />
                            </VStack>
                          </CardBody>
                        </Card>
                      ))}
                    </SimpleGrid>
                  ) : (
                    <Center py="8">
                      <Text color="gray.500">Loading user segments...</Text>
                    </Center>
                  )}
                </CardBody>
              </Card>

              {/* User Journeys - Funnel */}
              <Card>
                <CardHeader>
                  <Heading size="md">User Journey Funnel</Heading>
                  <Text fontSize="sm" color="gray.600" mt="2">
                    Progression of users through key milestones
                  </Text>
                </CardHeader>
                <CardBody>
                  {userJourneys && userJourneys.funnel ? (
                    <VStack spacing="4" align="stretch">
                      {userJourneys.funnel.map((step: any, index: number) => (
                        <Box key={index}>
                          <Flex justify="space-between" align="center" mb="2">
                            <HStack>
                              <Badge colorScheme="purple" fontSize="sm">
                                Step {step.step}
                              </Badge>
                              <Text fontWeight="semibold">{step.name}</Text>
                            </HStack>
                            <HStack spacing="3">
                              <Text fontSize="lg" fontWeight="bold" color="purple.500">
                                {formatNumber(step.users)}
                              </Text>
                              <Badge colorScheme="green" fontSize="sm">
                                {step.percentage}%
                              </Badge>
                              {step.dropOff && (
                                <Badge colorScheme="red" fontSize="xs">
                                  {step.dropOff}% drop-off
                                </Badge>
                              )}
                            </HStack>
                          </Flex>
                          <Progress
                            value={parseFloat(step.percentage)}
                            colorScheme="purple"
                            size="lg"
                            borderRadius="full"
                          />
                          <Text fontSize="xs" color="gray.600" mt="1">
                            {step.description}
                          </Text>
                        </Box>
                      ))}
                    </VStack>
                  ) : (
                    <Center py="8">
                      <Text color="gray.500">Loading user journey funnel...</Text>
                    </Center>
                  )}
                </CardBody>
              </Card>

              {/* Common Paths */}
              <SimpleGrid columns={{ base: 1, md: 2 }} spacing="6">
                <Card>
                  <CardHeader>
                    <Heading size="md">Common User Paths</Heading>
                    <Text fontSize="sm" color="gray.600" mt="2">
                      Most frequent user journeys through the app
                    </Text>
                  </CardHeader>
                  <CardBody>
                    {userJourneys && userJourneys.commonPaths ? (
                      <VStack spacing="4" align="stretch">
                        {userJourneys.commonPaths.map((path: any, index: number) => (
                          <Box key={index} p="4" bg="gray.50" borderRadius="md">
                            <HStack justify="space-between" mb="2">
                              <Text fontSize="sm" fontWeight="semibold">
                                {path.path}
                              </Text>
                              <Badge colorScheme="blue">
                                {path.percentage}%
                              </Badge>
                            </HStack>
                            <HStack justify="space-between">
                              <Text fontSize="xs" color="gray.600">
                                {formatNumber(path.users)} users
                              </Text>
                              <Text fontSize="xs" color="gray.600">
                                Avg: {path.averageTime}
                              </Text>
                            </HStack>
                          </Box>
                        ))}
                      </VStack>
                    ) : (
                      <Center py="8">
                        <Text color="gray.500">Loading common paths...</Text>
                      </Center>
                    )}
                  </CardBody>
                </Card>

                {/* Engagement Milestones */}
                <Card>
                  <CardHeader>
                    <Heading size="md">Engagement Milestones</Heading>
                    <Text fontSize="sm" color="gray.600" mt="2">
                      User achievement of key engagement milestones
                    </Text>
                  </CardHeader>
                  <CardBody>
                    {userJourneys && userJourneys.milestones ? (
                      <VStack spacing="3" align="stretch">
                        {userJourneys.milestones.map((milestone: any, index: number) => (
                          <Flex
                            key={index}
                            justify="space-between"
                            align="center"
                            p="3"
                            bg="gray.50"
                            borderRadius="md"
                          >
                            <VStack align="start" spacing="0">
                              <Text fontSize="sm" fontWeight="semibold">
                                {milestone.milestone}
                              </Text>
                              <Text fontSize="xs" color="gray.600">
                                {milestone.avgTimeToComplete}
                              </Text>
                            </VStack>
                            <VStack align="end" spacing="0">
                              <Text fontSize="lg" fontWeight="bold" color="purple.500">
                                {formatNumber(milestone.users)}
                              </Text>
                              <Text fontSize="xs" color="gray.600">
                                users
                              </Text>
                            </VStack>
                          </Flex>
                        ))}
                      </VStack>
                    ) : (
                      <Center py="8">
                        <Text color="gray.500">Loading milestones...</Text>
                      </Center>
                    )}
                  </CardBody>
                </Card>
              </SimpleGrid>
            </VStack>
          </TabPanel>
        </TabPanels>
      </Tabs>
    </Box>
  );
};

export default AdvancedAnalytics;
