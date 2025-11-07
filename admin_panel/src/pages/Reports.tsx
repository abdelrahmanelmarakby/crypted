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
  IconButton,
  Menu,
  MenuButton,
  MenuList,
  MenuItem,
  Flex,
  Button,
  useToast,
  Spinner,
  Center,
  Text,
  HStack,
  Select,
  useDisclosure,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalCloseButton,
  ModalFooter,
  FormControl,
  FormLabel,
  Textarea,
  VStack,
} from '@chakra-ui/react';
import { FiMoreVertical, FiEye, FiCheck, FiX, FiRefreshCw } from 'react-icons/fi';
import { getReports, updateReportStatus } from '@/services/reportService';
import { useAuth } from '@/contexts/AuthContext';
import { Report } from '@/types';
import { formatDate, getStatusColor } from '@/utils/helpers';

const Reports: React.FC = () => {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending' | 'reviewed' | 'action_taken' | 'dismissed'>('all');
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);
  const [actionType, setActionType] = useState<'reviewed' | 'action_taken' | 'dismissed' | null>(null);
  const [notes, setNotes] = useState('');

  const { isOpen, onOpen, onClose } = useDisclosure();
  const { adminUser } = useAuth();
  const toast = useToast();

  useEffect(() => {
    fetchReports();
  }, [filter]);

  const fetchReports = async () => {
    try {
      setLoading(true);
      const fetchedReports =
        filter === 'all' ? await getReports(undefined, 100) : await getReports(filter, 100);
      setReports(fetchedReports);
    } catch (error) {
      toast({
        title: 'Error loading reports',
        description: 'Failed to fetch reports',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    } finally {
      setLoading(false);
    }
  };

  const handleReviewReport = (report: Report, action: 'reviewed' | 'action_taken' | 'dismissed') => {
    setSelectedReport(report);
    setActionType(action);
    setNotes('');
    onOpen();
  };

  const confirmAction = async () => {
    if (!selectedReport || !actionType || !adminUser) return;

    try {
      await updateReportStatus(
        selectedReport.id,
        actionType,
        adminUser.uid,
        actionType === 'action_taken' ? 'User warned/suspended' : undefined,
        notes
      );

      toast({
        title: 'Report updated',
        description: `Report has been marked as ${actionType.replace('_', ' ')}`,
        status: 'success',
        duration: 3000,
        isClosable: true,
      });

      fetchReports();
      onClose();
    } catch (error) {
      toast({
        title: 'Update failed',
        description: 'Failed to update report',
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

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
            Reports & Moderation
          </Heading>
          <Text color="gray.600">
            {reports.filter((r) => r.status === 'pending').length} pending reports
          </Text>
        </Box>
        <HStack>
          <Select
            value={filter}
            onChange={(e) => setFilter(e.target.value as any)}
            maxW="200px"
          >
            <option value="all">All Reports</option>
            <option value="pending">Pending</option>
            <option value="reviewed">Reviewed</option>
            <option value="action_taken">Action Taken</option>
            <option value="dismissed">Dismissed</option>
          </Select>
          <Button leftIcon={<FiRefreshCw />} onClick={fetchReports} colorScheme="brand">
            Refresh
          </Button>
        </HStack>
      </Flex>

      {/* Reports Table */}
      <Card>
        <Box overflowX="auto">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>Type</Th>
                <Th>Reporter</Th>
                <Th>Reported User</Th>
                <Th>Reason</Th>
                <Th>Date</Th>
                <Th>Priority</Th>
                <Th>Status</Th>
                <Th>Actions</Th>
              </Tr>
            </Thead>
            <Tbody>
              {reports.map((report) => (
                <Tr key={report.id}>
                  <Td>
                    <Badge>{report.contentType}</Badge>
                  </Td>
                  <Td>{report.reporterId}</Td>
                  <Td>{report.reportedUserId || 'N/A'}</Td>
                  <Td>
                    <Text noOfLines={1} maxW="200px">
                      {report.reason}
                    </Text>
                  </Td>
                  <Td>{formatDate(report.createdAt)}</Td>
                  <Td>
                    <Badge
                      colorScheme={
                        report.priority === 'high'
                          ? 'red'
                          : report.priority === 'medium'
                          ? 'orange'
                          : 'gray'
                      }
                    >
                      {report.priority}
                    </Badge>
                  </Td>
                  <Td>
                    <Badge colorScheme={getStatusColor(report.status || 'pending')}>
                      {(report.status || 'pending').replace('_', ' ')}
                    </Badge>
                  </Td>
                  <Td>
                    <Menu>
                      <MenuButton
                        as={IconButton}
                        icon={<FiMoreVertical />}
                        variant="ghost"
                        size="sm"
                      />
                      <MenuList>
                        <MenuItem icon={<FiEye />}>View Details</MenuItem>
                        <MenuItem
                          icon={<FiCheck />}
                          onClick={() => handleReviewReport(report, 'reviewed')}
                          isDisabled={report.status !== 'pending'}
                        >
                          Mark as Reviewed
                        </MenuItem>
                        <MenuItem
                          icon={<FiCheck />}
                          color="green.500"
                          onClick={() => handleReviewReport(report, 'action_taken')}
                          isDisabled={report.status !== 'pending'}
                        >
                          Take Action
                        </MenuItem>
                        <MenuItem
                          icon={<FiX />}
                          color="red.500"
                          onClick={() => handleReviewReport(report, 'dismissed')}
                          isDisabled={report.status !== 'pending'}
                        >
                          Dismiss Report
                        </MenuItem>
                      </MenuList>
                    </Menu>
                  </Td>
                </Tr>
              ))}
            </Tbody>
          </Table>
        </Box>
      </Card>

      {reports.length === 0 && (
        <Center h="30vh" mt="6">
          <Text color="gray.500">No reports found</Text>
        </Center>
      )}

      {/* Action Modal */}
      <Modal isOpen={isOpen} onClose={onClose}>
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>
            {actionType === 'reviewed' && 'Mark as Reviewed'}
            {actionType === 'action_taken' && 'Take Action'}
            {actionType === 'dismissed' && 'Dismiss Report'}
          </ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            <VStack spacing="4" align="stretch">
              <Text>
                Are you sure you want to {actionType?.replace('_', ' ')} this report?
              </Text>
              <FormControl>
                <FormLabel>Notes (optional)</FormLabel>
                <Textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Add any notes about this action..."
                  rows={4}
                />
              </FormControl>
            </VStack>
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" mr={3} onClick={onClose}>
              Cancel
            </Button>
            <Button colorScheme="brand" onClick={confirmAction}>
              Confirm
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </Box>
  );
};

export default Reports;
