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
  Button,
  Alert,
  AlertIcon,
  AlertTitle,
  AlertDescription,
  VStack,
  Flex,
  Select,
  HStack,
  Badge,
  Icon,
  useColorModeValue,
} from '@chakra-ui/react';
import { FiUsers, FiMessageSquare, FiImage, FiAlertCircle, FiPhone, FiRefreshCw, FiTrendingUp, FiClock } from 'react-icons/fi';
import {
  BarChart,
  Bar,
  AreaChart,
  Area,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import StatCard from '@/components/dashboard/StatCard';
import { getDashboardStats, getUserGrowthData, getMessageActivityData } from '@/services/analyticsService';
import { DashboardStats, UserGrowthData, MessageActivityData } from '@/types';
import { formatNumber } from '@/utils/helpers';
import { runDiagnostics } from '@/utils/diagnostics';

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [userGrowthData, setUserGrowthData] = useState<UserGrowthData[]>([]);
  const [messageActivityData, setMessageActivityData] = useState<MessageActivityData[]>([]);
  const [loading, setLoading] = useState(true);
  const [runningDiagnostics, setRunningDiagnostics] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [timePeriod, setTimePeriod] = useState<number>(30);
  const [refreshing, setRefreshing] = useState(false);
  const toast = useToast();
  const cardBg = useColorModeValue('white', 'gray.800');

  useEffect(() => {
    fetchDashboardData();
  }, [timePeriod]);

  const fetchDashboardData = async (isRefresh = false) => {
    try {
      if (isRefresh) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }
      setError(null);

      console.log('📊 Dashboard: Starting to fetch data...');

      const [statsData, growthData, activityData] = await Promise.all([
        getDashboardStats(),
        getUserGrowthData(timePeriod),
        getMessageActivityData(Math.min(timePeriod, 30)),
      ]);

      console.log('📊 Dashboard: Received stats:', statsData);
      console.log('📊 Dashboard: Total users:', statsData.totalUsers);

      setStats(statsData);
      setUserGrowthData(growthData);
      setMessageActivityData(activityData);

      // Check if we got zero data
      if (statsData.totalUsers === 0 && statsData.totalMessages === 0 && statsData.totalCalls === 0) {
        setError('No data found in Firebase collections. Collections may be empty or you may not have permission to read them.');
      }

      if (isRefresh) {
        toast({
          title: 'Dashboard refreshed',
          status: 'success',
          duration: 2000,
          isClosable: true,
        });
      }
    } catch (error: any) {
      console.error('❌ Dashboard: Error fetching data:', error);
      const errorMessage = error?.message || 'Failed to fetch dashboard data';
      setError(errorMessage);
      toast({
        title: 'Error loading dashboard',
        description: errorMessage,
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRefresh = () => {
    fetchDashboardData(true);
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
      <Flex justify="space-between" align="center" mb="8">
        <Box>
          <Heading size="xl" mb="2" fontWeight="extrabold">
            Dashboard
          </Heading>
          <HStack spacing="2">
            <Icon as={FiTrendingUp} color="green.500" />
            <Text color="gray.600" fontSize="md">
              Welcome back! Here's what's happening with your app
            </Text>
          </HStack>
        </Box>
        <HStack spacing="3">
          <Select
            value={timePeriod}
            onChange={(e) => setTimePeriod(Number(e.target.value))}
            w="170px"
            size="md"
            borderRadius="lg"
          >
            <option value={7}>Last 7 days</option>
            <option value={30}>Last 30 days</option>
            <option value={90}>Last 90 days</option>
          </Select>
          <Button
            leftIcon={<FiRefreshCw />}
            onClick={handleRefresh}
            colorScheme="brand"
            isLoading={refreshing}
            loadingText="Refreshing"
            size="md"
            borderRadius="lg"
          >
            Refresh
          </Button>
        </HStack>
      </Flex>

      {/* Quick Stats Summary */}
      <Card mb="8" bg={cardBg} borderRadius="xl" boxShadow="lg" p="6">
        <HStack spacing="8" justify="space-around" flexWrap="wrap">
          <VStack spacing="1">
            <Text fontSize="sm" color="gray.500" fontWeight="medium">
              Total Users
            </Text>
            <Text fontSize="3xl" fontWeight="bold" color="blue.500">
              {formatNumber(stats.totalUsers)}
            </Text>
            <Badge colorScheme="blue" fontSize="xs" px="2" py="1">
              {formatNumber(stats.newUsersToday)} new today
            </Badge>
          </VStack>
          <VStack spacing="1">
            <Text fontSize="sm" color="gray.500" fontWeight="medium">
              Active Now
            </Text>
            <Text fontSize="3xl" fontWeight="bold" color="green.500">
              {formatNumber(stats.activeUsers24h)}
            </Text>
            <Badge colorScheme="green" fontSize="xs" px="2" py="1">
              {((stats.activeUsers24h / stats.totalUsers) * 100).toFixed(1)}% of total
            </Badge>
          </VStack>
          <VStack spacing="1">
            <Text fontSize="sm" color="gray.500" fontWeight="medium">
              Messages Today
            </Text>
            <Text fontSize="3xl" fontWeight="bold" color="purple.500">
              {formatNumber(stats.messagesToday)}
            </Text>
            <Badge colorScheme="purple" fontSize="xs" px="2" py="1">
              {formatNumber(stats.activeChatRooms)} active chats
            </Badge>
          </VStack>
          <VStack spacing="1">
            <Text fontSize="sm" color="gray.500" fontWeight="medium">
              Calls Today
            </Text>
            <Text fontSize="3xl" fontWeight="bold" color="cyan.500">
              {formatNumber(stats.callsToday)}
            </Text>
            <Badge colorScheme="cyan" fontSize="xs" px="2" py="1">
              {Math.floor(stats.averageCallDuration / 60)}m avg
            </Badge>
          </VStack>
        </HStack>
      </Card>

      {/* Stats Grid */}
      <SimpleGrid columns={{ base: 1, md: 2, lg: 3, xl: 4 }} spacing="6" mb="8">
        <StatCard
          label="Total Users"
          value={formatNumber(stats.totalUsers)}
          helpText={`${formatNumber(stats.newUsersThisWeek)} new this week`}
          icon={FiUsers}
          iconColor="blue.500"
          link="/users"
          changePercent={stats.newUsersThisMonth > 0 ? ((stats.newUsersThisWeek / stats.newUsersThisMonth) * 100) : 0}
        />
        <StatCard
          label="Active Users (24h)"
          value={formatNumber(stats.activeUsers24h)}
          helpText={`${formatNumber(stats.activeUsers7d)} in last 7 days`}
          icon={FiUsers}
          iconColor="green.500"
          link="/users"
          changePercent={stats.activeUsers7d > 0 ? ((stats.activeUsers24h / (stats.activeUsers7d / 7)) * 100 - 100) : 0}
        />
        <StatCard
          label="Messages Today"
          value={formatNumber(stats.messagesToday)}
          helpText={`${formatNumber(stats.messagesThisWeek)} this week`}
          icon={FiMessageSquare}
          iconColor="purple.500"
          link="/chats"
          changePercent={stats.messagesThisWeek > 0 ? ((stats.messagesToday / (stats.messagesThisWeek / 7)) * 100 - 100) : 0}
        />
        <StatCard
          label="Active Stories"
          value={formatNumber(stats.activeStories)}
          helpText={`${formatNumber(stats.storiesToday)} posted today`}
          icon={FiImage}
          iconColor="orange.500"
          link="/stories"
        />
        <StatCard
          label="Chat Rooms"
          value={formatNumber(stats.activeChatRooms)}
          helpText={`${stats.groupChats} group chats`}
          icon={FiMessageSquare}
          iconColor="teal.500"
          link="/chats"
        />
        <StatCard
          label="Calls Today"
          value={formatNumber(stats.callsToday)}
          helpText={`${formatNumber(stats.callsThisWeek)} this week`}
          icon={FiPhone}
          iconColor="cyan.500"
          link="/calls"
          changePercent={stats.callsThisWeek > 0 ? ((stats.callsToday / (stats.callsThisWeek / 7)) * 100 - 100) : 0}
        />
        <StatCard
          label="Pending Reports"
          value={formatNumber(stats.pendingReports)}
          helpText={`${formatNumber(stats.reportsToday)} new today`}
          icon={FiAlertCircle}
          iconColor="red.500"
          link="/reports"
        />
        <StatCard
          label="Avg Call Duration"
          value={`${Math.floor(stats.averageCallDuration / 60)}m`}
          helpText={`${formatNumber(stats.totalCalls)} total calls`}
          icon={FiClock}
          iconColor="pink.500"
          link="/calls"
        />
      </SimpleGrid>

      {/* Charts */}
      <SimpleGrid columns={{ base: 1, lg: 2 }} spacing="6" mb="8">
        {/* User Growth Chart */}
        <Card bg={cardBg} borderRadius="xl" boxShadow="lg">
          <CardHeader pb="4">
            <Flex justify="space-between" align="center">
              <Box>
                <Heading size="md" mb="1">User Growth</Heading>
                <Text fontSize="sm" color="gray.500">
                  New users over time
                </Text>
              </Box>
              <Badge colorScheme="blue" fontSize="sm" px="3" py="1">
                {timePeriod} days
              </Badge>
            </Flex>
          </CardHeader>
          <CardBody pt="0">
            <ResponsiveContainer width="100%" height={320}>
              <AreaChart data={userGrowthData}>
                <defs>
                  <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#3B82F6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                <XAxis
                  dataKey="date"
                  fontSize={11}
                  tickFormatter={(value) => {
                    const date = new Date(value);
                    return `${date.getMonth() + 1}/${date.getDate()}`;
                  }}
                />
                <YAxis fontSize={11} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #E5E7EB',
                    borderRadius: '8px',
                    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="users"
                  stroke="#3B82F6"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#colorUsers)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>

        {/* Message Activity Chart */}
        <Card bg={cardBg} borderRadius="xl" boxShadow="lg">
          <CardHeader pb="4">
            <Flex justify="space-between" align="center">
              <Box>
                <Heading size="md" mb="1">Message Activity</Heading>
                <Text fontSize="sm" color="gray.500">
                  Daily message volume
                </Text>
              </Box>
              <Badge colorScheme="purple" fontSize="sm" px="3" py="1">
                {Math.min(timePeriod, 30)} days
              </Badge>
            </Flex>
          </CardHeader>
          <CardBody pt="0">
            <ResponsiveContainer width="100%" height={320}>
              <BarChart data={messageActivityData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                <XAxis
                  dataKey="date"
                  fontSize={11}
                  tickFormatter={(value) => {
                    const date = new Date(value);
                    return `${date.getMonth() + 1}/${date.getDate()}`;
                  }}
                />
                <YAxis fontSize={11} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #E5E7EB',
                    borderRadius: '8px',
                    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                  }}
                />
                <Bar dataKey="messages" fill="#9333EA" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>
      </SimpleGrid>

      {/* Additional Charts */}
      <SimpleGrid columns={{ base: 1, lg: 3 }} spacing="6" mb="8">
        {/* Activity Distribution */}
        <Card bg={cardBg} borderRadius="xl" boxShadow="lg">
          <CardHeader>
            <Heading size="md" mb="1">Activity Distribution</Heading>
            <Text fontSize="sm" color="gray.500">
              By feature type
            </Text>
          </CardHeader>
          <CardBody>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={[
                    { name: 'Messages', value: stats.totalMessages, color: '#9333EA' },
                    { name: 'Stories', value: stats.totalStories, color: '#F97316' },
                    { name: 'Calls', value: stats.totalCalls, color: '#06B6D4' },
                  ]}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={90}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {[
                    { name: 'Messages', value: stats.totalMessages, color: '#9333EA' },
                    { name: 'Stories', value: stats.totalStories, color: '#F97316' },
                    { name: 'Calls', value: stats.totalCalls, color: '#06B6D4' },
                  ].map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #E5E7EB',
                    borderRadius: '8px',
                    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                  }}
                />
                <Legend
                  verticalAlign="bottom"
                  height={36}
                  iconType="circle"
                  formatter={(value, entry: any) => (
                    <span style={{ fontSize: '12px', color: '#6B7280' }}>
                      {value}: {formatNumber(entry.payload.value)}
                    </span>
                  )}
                />
              </PieChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>

        {/* User Engagement Stats */}
        <Card bg={cardBg} borderRadius="xl" boxShadow="lg">
          <CardHeader>
            <Heading size="md" mb="1">User Engagement</Heading>
            <Text fontSize="sm" color="gray.500">
              Activity levels
            </Text>
          </CardHeader>
          <CardBody>
            <VStack spacing="4" align="stretch">
              <Box>
                <Flex justify="space-between" mb="2">
                  <Text fontSize="sm" fontWeight="medium">
                    Active (24h)
                  </Text>
                  <Text fontSize="sm" fontWeight="bold" color="green.500">
                    {formatNumber(stats.activeUsers24h)}
                  </Text>
                </Flex>
                <Box
                  w="full"
                  h="8px"
                  bg="gray.200"
                  borderRadius="full"
                  overflow="hidden"
                >
                  <Box
                    w={`${(stats.activeUsers24h / stats.totalUsers) * 100}%`}
                    h="full"
                    bg="green.500"
                  />
                </Box>
              </Box>
              <Box>
                <Flex justify="space-between" mb="2">
                  <Text fontSize="sm" fontWeight="medium">
                    Active (7d)
                  </Text>
                  <Text fontSize="sm" fontWeight="bold" color="blue.500">
                    {formatNumber(stats.activeUsers7d)}
                  </Text>
                </Flex>
                <Box
                  w="full"
                  h="8px"
                  bg="gray.200"
                  borderRadius="full"
                  overflow="hidden"
                >
                  <Box
                    w={`${(stats.activeUsers7d / stats.totalUsers) * 100}%`}
                    h="full"
                    bg="blue.500"
                  />
                </Box>
              </Box>
              <Box>
                <Flex justify="space-between" mb="2">
                  <Text fontSize="sm" fontWeight="medium">
                    Active (30d)
                  </Text>
                  <Text fontSize="sm" fontWeight="bold" color="purple.500">
                    {formatNumber(stats.activeUsers30d)}
                  </Text>
                </Flex>
                <Box
                  w="full"
                  h="8px"
                  bg="gray.200"
                  borderRadius="full"
                  overflow="hidden"
                >
                  <Box
                    w={`${(stats.activeUsers30d / stats.totalUsers) * 100}%`}
                    h="full"
                    bg="purple.500"
                  />
                </Box>
              </Box>
              <Box pt="2">
                <Text fontSize="xs" color="gray.500" textAlign="center">
                  Engagement rate:{' '}
                  <Text as="span" fontWeight="bold" color="gray.700">
                    {((stats.activeUsers24h / stats.totalUsers) * 100).toFixed(1)}%
                  </Text>
                </Text>
              </Box>
            </VStack>
          </CardBody>
        </Card>

        {/* Growth Metrics */}
        <Card bg={cardBg} borderRadius="xl" boxShadow="lg">
          <CardHeader>
            <Heading size="md" mb="1">Growth Metrics</Heading>
            <Text fontSize="sm" color="gray.500">
              New signups
            </Text>
          </CardHeader>
          <CardBody>
            <VStack spacing="4" align="stretch">
              <Box textAlign="center" p="4" bg="blue.50" borderRadius="lg">
                <Text fontSize="xs" color="gray.600" mb="1" fontWeight="medium">
                  TODAY
                </Text>
                <Text fontSize="3xl" fontWeight="bold" color="blue.600">
                  {formatNumber(stats.newUsersToday)}
                </Text>
                <Text fontSize="xs" color="gray.600" mt="1">
                  new users
                </Text>
              </Box>
              <Box textAlign="center" p="4" bg="green.50" borderRadius="lg">
                <Text fontSize="xs" color="gray.600" mb="1" fontWeight="medium">
                  THIS WEEK
                </Text>
                <Text fontSize="3xl" fontWeight="bold" color="green.600">
                  {formatNumber(stats.newUsersThisWeek)}
                </Text>
                <Text fontSize="xs" color="gray.600" mt="1">
                  new users
                </Text>
              </Box>
              <Box textAlign="center" p="4" bg="purple.50" borderRadius="lg">
                <Text fontSize="xs" color="gray.600" mb="1" fontWeight="medium">
                  THIS MONTH
                </Text>
                <Text fontSize="3xl" fontWeight="bold" color="purple.600">
                  {formatNumber(stats.newUsersThisMonth)}
                </Text>
                <Text fontSize="xs" color="gray.600" mt="1">
                  new users
                </Text>
              </Box>
            </VStack>
          </CardBody>
        </Card>
      </SimpleGrid>
    </Box>
  );
};

export default Dashboard;
