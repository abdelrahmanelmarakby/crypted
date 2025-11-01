import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  Menu,
  MenuItem,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Grid,
  Tabs,
  Tab,
  Avatar,
} from '@mui/material';
import {
  MoreVert,
  CheckCircle,
  Block,
  Delete,
  Flag,
  Person,
  Message,
  PhotoLibrary,
} from '@mui/icons-material';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { COLORS } from '../utils/constants';
import reportService, { Report } from '../services/report.service';

const Reports: React.FC = () => {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(false);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    type: 'resolve' | 'dismiss' | 'delete' | null;
  }>({ open: false, type: null });
  const [actionNote, setActionNote] = useState('');
  const [tabValue, setTabValue] = useState(0);

  useEffect(() => {
    fetchReports();
  }, [tabValue]);

  const fetchReports = async () => {
    try {
      setLoading(true);
      const fetchedReports = tabValue === 0
        ? await reportService.getPendingReports()
        : await reportService.getReports();
      setReports(fetchedReports);
    } catch (error) {
      console.error('Error fetching reports:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, report: Report) => {
    setAnchorEl(event.currentTarget);
    setSelectedReport(report);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleActionClick = (type: 'resolve' | 'dismiss' | 'delete') => {
    setActionDialog({ open: true, type });
    handleMenuClose();
  };

  const handleActionConfirm = async () => {
    if (!selectedReport || !actionDialog.type) return;

    try {
      setLoading(true);
      switch (actionDialog.type) {
        case 'resolve':
          await reportService.updateReportStatus(selectedReport.id, 'resolved', actionNote);
          break;
        case 'dismiss':
          await reportService.updateReportStatus(selectedReport.id, 'dismissed', actionNote);
          break;
        case 'delete':
          await reportService.deleteReport(selectedReport.id);
          break;
      }
      await fetchReports();
    } catch (error) {
      console.error(`Error ${actionDialog.type}ing report:`, error);
    } finally {
      setLoading(false);
      setActionDialog({ open: false, type: null });
      setSelectedReport(null);
      setActionNote('');
    }
  };

  const getStatusChip = (status: string) => {
    switch (status) {
      case 'pending':
        return (
          <Chip
            label="Pending"
            size="small"
            icon={<Flag sx={{ fontSize: 16 }} />}
            sx={{
              backgroundColor: COLORS.grey[100],
              color: COLORS.grey[800],
              fontWeight: 600,
            }}
          />
        );
      case 'reviewed':
        return (
          <Chip
            label="Reviewed"
            size="small"
            sx={{
              backgroundColor: COLORS.green[50],
              color: COLORS.primary,
              fontWeight: 600,
            }}
          />
        );
      case 'resolved':
        return (
          <Chip
            label="Resolved"
            size="small"
            icon={<CheckCircle sx={{ fontSize: 16 }} />}
            sx={{
              backgroundColor: COLORS.green[50],
              color: COLORS.primary,
              fontWeight: 600,
            }}
          />
        );
      case 'dismissed':
        return (
          <Chip
            label="Dismissed"
            size="small"
            icon={<Block sx={{ fontSize: 16 }} />}
            sx={{
              backgroundColor: COLORS.grey[200],
              color: COLORS.grey[700],
              fontWeight: 600,
            }}
          />
        );
      default:
        return null;
    }
  };

  const getContentTypeIcon = (type: string) => {
    switch (type) {
      case 'user':
        return <Person sx={{ fontSize: 16 }} />;
      case 'message':
        return <Message sx={{ fontSize: 16 }} />;
      case 'story':
        return <PhotoLibrary sx={{ fontSize: 16 }} />;
      default:
        return <Flag sx={{ fontSize: 16 }} />;
    }
  };

  const pendingReports = reports.filter(r => r.status === 'pending');
  const resolvedReports = reports.filter(r => r.status === 'resolved');
  const dismissedReports = reports.filter(r => r.status === 'dismissed');

  if (loading && reports.length === 0) {
    return <LoadingSpinner />;
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography
          variant="h3"
          sx={{
            fontWeight: 700,
            color: COLORS.text,
            fontSize: '2.25rem',
            mb: 1,
          }}
        >
          Reports Management
        </Typography>
        <Typography variant="body1" sx={{ color: COLORS.grey[600] }}>
          Review and manage user reports and moderation requests
        </Typography>
      </Box>

      {/* Stats */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Total Reports
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.text }}>
              {reports.length}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Pending
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.grey[800] }}>
              {pendingReports.length}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Resolved
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.primary }}>
              {resolvedReports.length}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Dismissed
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.grey[600] }}>
              {dismissedReports.length}
            </Typography>
          </Paper>
        </Grid>
      </Grid>

      {/* Tabs */}
      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={tabValue}
          onChange={(e, newValue) => setTabValue(newValue)}
          sx={{
            borderBottom: `1px solid ${COLORS.grey[200]}`,
            '& .MuiTab-root': {
              textTransform: 'none',
              fontWeight: 600,
              fontSize: '0.95rem',
            },
          }}
        >
          <Tab label={`Pending (${pendingReports.length})`} />
          <Tab label={`All Reports (${reports.length})`} />
        </Tabs>
      </Paper>

      {/* Reports Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow sx={{ backgroundColor: COLORS.grey[50] }}>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Reporter</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Reported</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Type</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Reason</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Status</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }}>Date</TableCell>
              <TableCell sx={{ fontWeight: 600, color: COLORS.text }} align="right">
                Actions
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {reports.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 8 }}>
                  <Typography variant="body1" color="text.secondary">
                    No reports found
                  </Typography>
                </TableCell>
              </TableRow>
            ) : (
              reports.map((report) => (
                <TableRow
                  key={report.id}
                  sx={{
                    '&:hover': {
                      backgroundColor: COLORS.grey[50],
                    },
                  }}
                >
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                      <Avatar sx={{ width: 32, height: 32, bgcolor: COLORS.primary, fontSize: '0.9rem' }}>
                        {report.reporterName?.charAt(0).toUpperCase() || 'U'}
                      </Avatar>
                      <Typography variant="body2" sx={{ fontWeight: 600, color: COLORS.text }}>
                        {report.reporterName || 'Unknown'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ color: COLORS.grey[700] }}>
                      {report.reportedUserName || 'Unknown'}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      icon={getContentTypeIcon(report.contentType)}
                      label={report.contentType}
                      size="small"
                      sx={{
                        backgroundColor: COLORS.grey[100],
                        color: COLORS.grey[700],
                        textTransform: 'capitalize',
                        fontWeight: 500,
                      }}
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ color: COLORS.grey[700], maxWidth: 200 }}>
                      {report.reason}
                    </Typography>
                  </TableCell>
                  <TableCell>{getStatusChip(report.status)}</TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ color: COLORS.grey[700] }}>
                      {report.createdAt
                        ? new Date(report.createdAt.toDate()).toLocaleDateString()
                        : 'N/A'}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <IconButton
                      size="small"
                      onClick={(e) => handleMenuOpen(e, report)}
                      sx={{ color: COLORS.grey[600] }}
                    >
                      <MoreVert />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Action Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
        PaperProps={{
          elevation: 0,
          sx: {
            border: `1px solid ${COLORS.grey[200]}`,
            minWidth: 180,
          },
        }}
      >
        <MenuItem onClick={() => handleActionClick('resolve')}>
          <CheckCircle sx={{ mr: 1.5, fontSize: 20, color: COLORS.primary }} />
          Resolve Report
        </MenuItem>
        <MenuItem onClick={() => handleActionClick('dismiss')}>
          <Block sx={{ mr: 1.5, fontSize: 20, color: COLORS.grey[600] }} />
          Dismiss Report
        </MenuItem>
        <MenuItem onClick={() => handleActionClick('delete')} sx={{ color: COLORS.grey[900] }}>
          <Delete sx={{ mr: 1.5, fontSize: 20 }} />
          Delete Report
        </MenuItem>
      </Menu>

      {/* Action Dialog */}
      <Dialog
        open={actionDialog.open}
        onClose={() => setActionDialog({ open: false, type: null })}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          {actionDialog.type === 'resolve' && 'Resolve Report'}
          {actionDialog.type === 'dismiss' && 'Dismiss Report'}
          {actionDialog.type === 'delete' && 'Delete Report'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2 }}>
            <Typography variant="body2" sx={{ mb: 2, color: COLORS.grey[700] }}>
              Report: {selectedReport?.reason}
            </Typography>
            {actionDialog.type !== 'delete' && (
              <TextField
                fullWidth
                multiline
                rows={3}
                label="Action Note (Optional)"
                placeholder="Add a note about the action taken..."
                value={actionNote}
                onChange={(e) => setActionNote(e.target.value)}
                sx={{ mt: 1 }}
              />
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setActionDialog({ open: false, type: null })}>
            Cancel
          </Button>
          <Button onClick={handleActionConfirm} variant="contained">
            Confirm
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Reports;
