import React from 'react';
import {
  Box,
  Heading,
  Text,
  SimpleGrid,
  Card,
  CardHeader,
  CardBody,
} from '@chakra-ui/react';
import {
  AreaChart,
  Area,
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { CHART_COLORS } from '@/utils/constants';

const Analytics: React.FC = () => {
  // Sample data - would be fetched from Firebase in production
  const userEngagementData = [
    { date: '2024-01-01', dau: 1200, wau: 5400, mau: 18000 },
    { date: '2024-01-02', dau: 1350, wau: 5600, mau: 18200 },
    { date: '2024-01-03', dau: 1400, wau: 5800, mau: 18500 },
    { date: '2024-01-04', dau: 1250, wau: 5700, mau: 18400 },
    { date: '2024-01-05', dau: 1500, wau: 6000, mau: 19000 },
  ];

  const contentAnalyticsData = [
    { date: '2024-01-01', messages: 5000, stories: 800, calls: 300 },
    { date: '2024-01-02', messages: 5500, stories: 850, calls: 320 },
    { date: '2024-01-03', messages: 6000, stories: 900, calls: 350 },
    { date: '2024-01-04', messages: 5800, stories: 880, calls: 340 },
    { date: '2024-01-05', messages: 6200, stories: 950, calls: 380 },
  ];

  const retentionData = [
    { day: 'Day 1', retention: 100 },
    { day: 'Day 7', retention: 45 },
    { day: 'Day 14', retention: 32 },
    { day: 'Day 30', retention: 25 },
    { day: 'Day 60', retention: 18 },
    { day: 'Day 90', retention: 15 },
  ];

  return (
    <Box>
      <Heading size="lg" mb="2">
        Analytics Dashboard
      </Heading>
      <Text color="gray.600" mb="6">
        Comprehensive analytics and insights
      </Text>

      <SimpleGrid columns={{ base: 1, lg: 2 }} spacing="6" mb="6">
        {/* User Engagement */}
        <Card>
          <CardHeader>
            <Heading size="md">User Engagement</Heading>
            <Text fontSize="sm" color="gray.600">
              Daily, Weekly, and Monthly Active Users
            </Text>
          </CardHeader>
          <CardBody>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={userEngagementData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" fontSize={12} />
                <YAxis fontSize={12} />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="dau" stroke={CHART_COLORS[0]} name="DAU" />
                <Line type="monotone" dataKey="wau" stroke={CHART_COLORS[1]} name="WAU" />
                <Line type="monotone" dataKey="mau" stroke={CHART_COLORS[2]} name="MAU" />
              </LineChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>

        {/* Content Analytics */}
        <Card>
          <CardHeader>
            <Heading size="md">Content Activity</Heading>
            <Text fontSize="sm" color="gray.600">
              Messages, Stories, and Calls
            </Text>
          </CardHeader>
          <CardBody>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={contentAnalyticsData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" fontSize={12} />
                <YAxis fontSize={12} />
                <Tooltip />
                <Legend />
                <Bar dataKey="messages" fill={CHART_COLORS[0]} name="Messages" />
                <Bar dataKey="stories" fill={CHART_COLORS[1]} name="Stories" />
                <Bar dataKey="calls" fill={CHART_COLORS[2]} name="Calls" />
              </BarChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>
      </SimpleGrid>

      {/* User Retention */}
      <Card>
        <CardHeader>
          <Heading size="md">User Retention</Heading>
          <Text fontSize="sm" color="gray.600">
            Percentage of users returning after signup
          </Text>
        </CardHeader>
        <CardBody>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={retentionData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="day" fontSize={12} />
              <YAxis fontSize={12} />
              <Tooltip />
              <Area
                type="monotone"
                dataKey="retention"
                stroke={CHART_COLORS[0]}
                fill={CHART_COLORS[0]}
                fillOpacity={0.3}
                name="Retention %"
              />
            </AreaChart>
          </ResponsiveContainer>
        </CardBody>
      </Card>
    </Box>
  );
};

export default Analytics;
