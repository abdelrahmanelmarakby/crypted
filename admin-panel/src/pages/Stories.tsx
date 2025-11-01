import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardMedia,
  CardContent,
  CardActions,
  IconButton,
  Avatar,
  Chip,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  DialogContentText,
  Tabs,
  Tab,
} from '@mui/material';
import {
  Delete,
  Visibility,
  AccessTime,
  Image as ImageIcon,
  Videocam,
  TextFields,
} from '@mui/icons-material';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { COLORS } from '../utils/constants';
import storyService, { Story } from '../services/story.service';

const Stories: React.FC = () => {
  const [stories, setStories] = useState<Story[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedStory, setSelectedStory] = useState<Story | null>(null);
  const [deleteDialog, setDeleteDialog] = useState(false);
  const [tabValue, setTabValue] = useState(0);

  useEffect(() => {
    fetchStories();
  }, [tabValue]);

  const fetchStories = async () => {
    try {
      setLoading(true);
      const fetchedStories = tabValue === 0
        ? await storyService.getActiveStories()
        : await storyService.getStories();
      setStories(fetchedStories);
    } catch (error) {
      console.error('Error fetching stories:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteClick = (story: Story) => {
    setSelectedStory(story);
    setDeleteDialog(true);
  };

  const handleDeleteConfirm = async () => {
    if (!selectedStory) return;

    try {
      setLoading(true);
      await storyService.deleteStory(selectedStory.id);
      await fetchStories();
    } catch (error) {
      console.error('Error deleting story:', error);
    } finally {
      setLoading(false);
      setDeleteDialog(false);
      setSelectedStory(null);
    }
  };

  const getStoryTypeIcon = (type: string) => {
    switch (type) {
      case 'image':
        return <ImageIcon sx={{ fontSize: 16 }} />;
      case 'video':
        return <Videocam sx={{ fontSize: 16 }} />;
      case 'text':
        return <TextFields sx={{ fontSize: 16 }} />;
      default:
        return <ImageIcon sx={{ fontSize: 16 }} />;
    }
  };

  const getTimeRemaining = (expiresAt: any) => {
    if (!expiresAt) return 'Expired';
    const now = new Date();
    const expiry = expiresAt.toDate();
    const diff = expiry.getTime() - now.getTime();

    if (diff <= 0) return 'Expired';

    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

    return `${hours}h ${minutes}m`;
  };

  const activeStories = stories.filter(s => {
    const now = new Date();
    const expiry = s.expiresAt?.toDate();
    return expiry && expiry.getTime() > now.getTime();
  });

  const expiredStories = stories.filter(s => {
    const now = new Date();
    const expiry = s.expiresAt?.toDate();
    return !expiry || expiry.getTime() <= now.getTime();
  });

  const displayStories = tabValue === 0 ? activeStories : stories;

  if (loading && stories.length === 0) {
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
          Stories Moderation
        </Typography>
        <Typography variant="body1" sx={{ color: COLORS.grey[600] }}>
          Monitor and manage user stories across the platform
        </Typography>
      </Box>

      {/* Stats */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Total Stories
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.text }}>
              {stories.length}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Active Stories
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.primary }}>
              {activeStories.length}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Total Views
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.text }}>
              {stories.reduce((acc, s) => acc + (s.viewCount || 0), 0)}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="body2" sx={{ color: COLORS.grey[600], mb: 1 }}>
              Expired
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 700, color: COLORS.grey[600] }}>
              {expiredStories.length}
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
            '& .Mui-selected': {
              color: COLORS.primary,
            },
          }}
        >
          <Tab label={`Active (${activeStories.length})`} />
          <Tab label={`All Stories (${stories.length})`} />
        </Tabs>
      </Paper>

      {/* Stories Grid */}
      {displayStories.length === 0 ? (
        <Paper sx={{ p: 8, textAlign: 'center' }}>
          <Typography variant="body1" color="text.secondary">
            No stories found
          </Typography>
        </Paper>
      ) : (
        <Grid container spacing={3}>
          {displayStories.map((story) => (
            <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }} key={story.id}>
              <Card
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'all 0.2s ease',
                  '&:hover': {
                    transform: 'translateY(-2px)',
                    borderColor: COLORS.grey[300],
                  },
                }}
              >
                {story.type === 'image' && story.mediaUrl ? (
                  <CardMedia
                    component="img"
                    height="280"
                    image={story.mediaUrl}
                    alt="Story"
                    sx={{ objectFit: 'cover', backgroundColor: COLORS.grey[100] }}
                  />
                ) : story.type === 'video' && story.mediaUrl ? (
                  <Box
                    sx={{
                      height: 280,
                      backgroundColor: COLORS.grey[900],
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      position: 'relative',
                    }}
                  >
                    <Videocam sx={{ fontSize: 64, color: COLORS.white }} />
                  </Box>
                ) : (
                  <Box
                    sx={{
                      height: 280,
                      backgroundColor: story.backgroundColor || COLORS.primary,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      p: 3,
                    }}
                  >
                    <Typography
                      variant="h6"
                      sx={{
                        color: COLORS.white,
                        textAlign: 'center',
                        fontWeight: 600,
                      }}
                    >
                      {story.textContent || 'Text Story'}
                    </Typography>
                  </Box>
                )}
                <CardContent sx={{ flexGrow: 1 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2 }}>
                    <Avatar
                      src={story.userAvatar}
                      sx={{ width: 32, height: 32, bgcolor: COLORS.primary }}
                    >
                      {story.userName?.charAt(0).toUpperCase()}
                    </Avatar>
                    <Typography variant="body2" sx={{ fontWeight: 600, color: COLORS.text }}>
                      {story.userName || 'Unknown User'}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', gap: 1, mb: 1.5, flexWrap: 'wrap' }}>
                    <Chip
                      icon={getStoryTypeIcon(story.type)}
                      label={story.type}
                      size="small"
                      sx={{
                        backgroundColor: COLORS.grey[100],
                        color: COLORS.grey[700],
                        textTransform: 'capitalize',
                        fontWeight: 500,
                      }}
                    />
                    <Chip
                      icon={<Visibility sx={{ fontSize: 16 }} />}
                      label={`${story.viewCount || 0} views`}
                      size="small"
                      sx={{
                        backgroundColor: COLORS.green[50],
                        color: COLORS.primary,
                        fontWeight: 500,
                      }}
                    />
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    <AccessTime sx={{ fontSize: 16, color: COLORS.grey[600] }} />
                    <Typography variant="caption" sx={{ color: COLORS.grey[600] }}>
                      {getTimeRemaining(story.expiresAt)}
                    </Typography>
                  </Box>
                </CardContent>
                <CardActions sx={{ p: 2, pt: 0 }}>
                  <Button
                    size="small"
                    onClick={() => handleDeleteClick(story)}
                    startIcon={<Delete />}
                    sx={{
                      color: COLORS.grey[700],
                      '&:hover': {
                        backgroundColor: COLORS.grey[100],
                      },
                    }}
                  >
                    Delete
                  </Button>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialog} onClose={() => setDeleteDialog(false)}>
        <DialogTitle>Delete Story</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete this story from "{selectedStory?.userName}"?
            This action cannot be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialog(false)}>Cancel</Button>
          <Button onClick={handleDeleteConfirm} variant="contained" color="primary">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Stories;
