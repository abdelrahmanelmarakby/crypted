import React from 'react';
import { Box, Stat, StatLabel, StatNumber, StatHelpText, Flex, Icon, useColorModeValue } from '@chakra-ui/react';
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
      borderRadius="lg"
      border="1px"
      borderColor={borderColor}
      onClick={handleClick}
      cursor={link ? 'pointer' : 'default'}
      _hover={{
        boxShadow: link ? 'lg' : 'md',
        transform: link ? 'translateY(-4px)' : 'translateY(-2px)',
      }}
      transition="all 0.2s"
    >
      <Flex justify="space-between" align="start">
        <Stat>
          <StatLabel color="gray.600" fontSize="sm" fontWeight="medium" mb="2">
            {label}
          </StatLabel>
          <StatNumber fontSize="3xl" fontWeight="bold" mb="1">
            {value}
          </StatNumber>
          {helpText && (
            <StatHelpText mb="0" fontSize="sm">
              {helpText}
            </StatHelpText>
          )}
          {trendValue && (
            <StatHelpText
              mb="0"
              fontSize="sm"
              color={trend === 'up' ? 'green.500' : 'red.500'}
            >
              {trend === 'up' ? '↑' : '↓'} {trendValue}
            </StatHelpText>
          )}
        </Stat>
        <Box
          p="3"
          borderRadius="lg"
          bg={useColorModeValue(`${iconColor}.50`, `${iconColor}.900`)}
        >
          <Icon as={icon} boxSize="6" color={iconColor} />
        </Box>
      </Flex>
    </Box>
  );
};

export default StatCard;
