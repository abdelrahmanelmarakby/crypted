import React from 'react';
import { Box, Stat, StatLabel, StatNumber, StatHelpText, Flex, Icon, useColorModeValue, Badge, StatArrow } from '@chakra-ui/react';
import { IconType } from 'react-icons';
import { useNavigate } from 'react-router-dom';

interface StatCardProps {
  label: string;
  value: string | number;
  helpText?: string;
  icon: IconType;
  iconColor?: string;
  trend?: 'up' | 'down';
  trendValue?: string;
  link?: string;
  changePercent?: number;
}

const StatCard: React.FC<StatCardProps> = ({
  label,
  value,
  helpText,
  icon,
  iconColor = 'brand.500',
  trend,
  trendValue,
  link,
  changePercent,
}) => {
  const bgColor = useColorModeValue('white', 'gray.800');
  const borderColor = useColorModeValue('gray.200', 'gray.700');
  const navigate = useNavigate();

  const handleClick = () => {
    if (link) {
      navigate(link);
    }
  };

  return (
    <Box
      bg={bgColor}
      p="6"
      borderRadius="xl"
      border="1px"
      borderColor={borderColor}
      onClick={handleClick}
      cursor={link ? 'pointer' : 'default'}
      boxShadow="md"
      _hover={{
        boxShadow: 'xl',
        transform: link ? 'translateY(-4px)' : 'translateY(-2px)',
        borderColor: iconColor,
      }}
      transition="all 0.3s ease"
      position="relative"
      overflow="hidden"
    >
      <Flex justify="space-between" align="start">
        <Stat>
          <StatLabel color="gray.600" fontSize="sm" fontWeight="semibold" mb="2">
            {label}
          </StatLabel>
          <StatNumber fontSize="4xl" fontWeight="extrabold" mb="2">
            {value}
          </StatNumber>
          {changePercent !== undefined && (
            <Flex align="center" gap="2" mb="2">
              <StatArrow type={changePercent >= 0 ? 'increase' : 'decrease'} />
              <Badge
                colorScheme={changePercent >= 0 ? 'green' : 'red'}
                fontSize="xs"
                px="2"
                py="1"
                borderRadius="md"
                fontWeight="bold"
              >
                {Math.abs(changePercent).toFixed(1)}%
              </Badge>
              <Box as="span" fontSize="xs" color="gray.500">
                vs last period
              </Box>
            </Flex>
          )}
          {helpText && (
            <StatHelpText mb="0" fontSize="sm" color="gray.500">
              {helpText}
            </StatHelpText>
          )}
          {trendValue && (
            <StatHelpText
              mb="0"
              fontSize="sm"
              color={trend === 'up' ? 'green.500' : 'red.500'}
              fontWeight="medium"
            >
              {trend === 'up' ? '↑' : '↓'} {trendValue}
            </StatHelpText>
          )}
        </Stat>
        <Box
          p="4"
          borderRadius="xl"
          bg={useColorModeValue(`${iconColor}.50`, `${iconColor}.900`)}
        >
          <Icon as={icon} boxSize="7" color={iconColor} />
        </Box>
      </Flex>
    </Box>
  );
};

export default StatCard;
