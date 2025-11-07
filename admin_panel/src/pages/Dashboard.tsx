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
} from '@chakra-ui/react';
import { FiUsers, FiMessageSquare, FiImage, FiAlertCircle, FiPhone, FiDatabase } from 'react-icons/fi';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import StatCard from '@/components/dashboard/StatCard';
import { getDashboardStats, getUserGrowthData, getMessageActivityData } from '@/services/analyticsService';
import { DashboardStats, UserGrowthData, MessageActivityData } from '@/types';
import { formatNumber } from '@/utils/helpers';
import { CHART_COLORS } from '@/utils/constants';

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [userGrowthData, setUserGrowthData] = useState<UserGrowthData[]>([]);
  const [messageActivityData, setMessageActivityData] = useState<MessageActivityData[]>([]);
  const [loading, setLoading] = useState(true);
  const toast = useToast();

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      const [statsData, growthData, activityData] = await Promise.all([
        getDashboardStats(),
        getUserGrowthData(30),
        getMessageActivityData(7),
      ]);

      setStats(statsData);
      setUserGrowthData(growthData);
      setMessageActivityData(activityData);
    } catch (error) {
      toast({
        title: 'Error loading dashboard',
        description: 'Failed to fetch dashboard data',
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

  if (!stats) {
    return (
      <Center h="50vh">
        <Text>No data available</Text>
      </Center>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box mb="6">
        <Heading size="lg" mb="2">
          Dashboard
        </Heading>
        <Text color="gray.600">Welcome back! Here's what's happening with your app today.</Text>
      </Box>

      {/* Stats Grid */}
      <SimpleGrid columns={{ base: 1, md: 2, lg: 3, xl: 4 }} spacing="6" mb="6">
        <StatCard
          label="Total Users"
          value={formatNumber(stats.totalUsers)}
          helpText={`${formatNumber(stats.activeUsers24h)} active today`}
          icon={FiUsers}
          iconColor="blue.500"
          link="/users"
        />
        <StatCard
          label="Active Users (24h)"
          value={formatNumber(stats.activeUsers24h)}
          helpText={`${formatNumber(stats.activeUsers7d)} in last 7 days`}
          icon={FiUsers}
          iconColor="green.500"
          link="/users"
        />
        <StatCard
          label="Messages Today"
          value={formatNumber(stats.messagesToday)}
          helpText={`${formatNumber(stats.totalMessages)} total`}
          icon={FiMessageSquare}
          iconColor="purple.500"
          link="/chats"
        />
        <StatCard
          label="Active Stories"
          value={formatNumber(stats.activeStories)}
          helpText="Live stories"
          icon={FiImage}
          iconColor="orange.500"
          link="/stories"
        />
        <StatCard
          label="Chat Rooms"
          value={formatNumber(stats.activeChatRooms)}
          helpText="Active conversations"
          icon={FiMessageSquare}
          iconColor="teal.500"
          link="/chats"
        />
        <StatCard
          label="Calls Today"
          value={formatNumber(stats.callsToday)}
          helpText={`${formatNumber(stats.totalCalls)} total`}
          icon={FiPhone}
          iconColor="cyan.500"
          link="/calls"
        />
        <StatCard
          label="Pending Reports"
          value={formatNumber(stats.pendingReports)}
          helpText="Requires review"
          icon={FiAlertCircle}
          iconColor="red.500"
          link="/reports"
        />
        <StatCard
          label="Storage Usage"
          value="N/A"
          helpText="Cloud storage"
          icon={FiDatabase}
          iconColor="gray.500"
          link="/settings"
        />
      </SimpleGrid>

      {/* Charts */}
      <SimpleGrid columns={{ base: 1, lg: 2 }} spacing="6" mb="6">
        {/* User Growth Chart */}
        <Card>
          <CardHeader>
            <Heading size="md">User Growth (Last 30 Days)</Heading>
          </CardHeader>
          <CardBody>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={userGrowthData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" fontSize={12} />
                <YAxis fontSize={12} />
                <Tooltip />
                <Line type="monotone" dataKey="users" stroke={CHART_COLORS[0]} strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>

        {/* Message Activity Chart */}
        <Card>
          <CardHeader>
            <Heading size="md">Message Activity (Last 7 Days)</Heading>
          </CardHeader>
          <CardBody>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={messageActivityData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" fontSize={12} />
                <YAxis fontSize={12} />
                <Tooltip />
                <Bar dataKey="messages" fill={CHART_COLORS[1]} />
              </BarChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>
      </SimpleGrid>
    </Box>
  );
};

export default Dashboard;
