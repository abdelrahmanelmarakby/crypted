/**
 * Export data to CSV format
 */
export const exportToCSV = (data: any[], filename: string) => {
  if (data.length === 0) {
    alert('No data to export');
    return;
  }

  // Get headers from first object
  const headers = Object.keys(data[0]);

  // Create CSV content
  let csvContent = headers.join(',') + '\n';

  // Add data rows
  data.forEach((row) => {
    const values = headers.map((header) => {
      const value = row[header];

      // Handle different data types
      if (value === null || value === undefined) {
        return '';
      }

      // Convert objects/arrays to JSON strings
      if (typeof value === 'object') {
        return `"${JSON.stringify(value).replace(/"/g, '""')}"`;
      }

      // Escape quotes and wrap in quotes if contains comma
      const stringValue = String(value);
      if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
        return `"${stringValue.replace(/"/g, '""')}"`;
      }

      return stringValue;
    });

    csvContent += values.join(',') + '\n';
  });

  // Create download link
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);

  link.setAttribute('href', url);
  link.setAttribute('download', `${filename}_${new Date().toISOString().split('T')[0]}.csv`);
  link.style.visibility = 'hidden';

  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

/**
 * Export data to JSON format
 */
export const exportToJSON = (data: any[], filename: string) => {
  if (data.length === 0) {
    alert('No data to export');
    return;
  }

  const jsonContent = JSON.stringify(data, null, 2);

  const blob = new Blob([jsonContent], { type: 'application/json' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);

  link.setAttribute('href', url);
  link.setAttribute('download', `${filename}_${new Date().toISOString().split('T')[0]}.json`);
  link.style.visibility = 'hidden';

  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

/**
 * Prepare user data for export
 */
export const prepareUserDataForExport = (users: any[]) => {
  return users.map((user) => ({
    uid: user.uid,
    full_name: user.full_name,
    email: user.email,
    phoneNumber: user.phoneNumber || '',
    status: user.status || 'active',
    createdAt: user.createdAt?.toDate?.()?.toISOString() || '',
    lastSeen: user.lastSeen?.toDate?.()?.toISOString() || '',
    isOnline: user.isOnline || false,
    followersCount: user.followers?.length || 0,
    followingCount: user.following?.length || 0,
  }));
};

/**
 * Prepare chat data for export
 */
export const prepareChatDataForExport = (chatRooms: any[]) => {
  return chatRooms.map((room) => ({
    id: room.id,
    type: room.type,
    participantsCount: room.participants?.length || 0,
    participants: room.participants?.join(', ') || '',
    createdAt: room.createdAt?.toDate?.()?.toISOString() || '',
    lastMessageTime: room.lastMessageTime?.toDate?.()?.toISOString() || '',
    isActive: room.isActive || false,
  }));
};

/**
 * Prepare story data for export
 */
export const prepareStoryDataForExport = (stories: any[]) => {
  return stories.map((story) => ({
    id: story.id,
    uid: story.uid,
    userName: story.user?.full_name || '',
    storyType: story.storyType,
    status: story.status,
    viewCount: story.viewedBy?.length || 0,
    createdAt: story.createdAt?.toDate?.()?.toISOString() || '',
    expiresAt: story.expiresAt?.toDate?.()?.toISOString() || '',
  }));
};

/**
 * Prepare report data for export
 */
export const prepareReportDataForExport = (reports: any[]) => {
  return reports.map((report) => ({
    id: report.id,
    reporterId: report.reporterId,
    reportedUserId: report.reportedUserId || '',
    contentType: report.contentType,
    reason: report.reason,
    status: report.status,
    priority: report.priority,
    createdAt: report.createdAt?.toDate?.()?.toISOString() || '',
    reviewedAt: report.reviewedAt?.toDate?.()?.toISOString() || '',
    reviewedBy: report.reviewedBy || '',
  }));
};

/**
 * Prepare call data for export
 */
export const prepareCallDataForExport = (calls: any[]) => {
  return calls.map((call) => ({
    id: call.id,
    type: call.type,
    participantsCount: call.participants?.length || 0,
    duration: call.duration || 0,
    status: call.status,
    startTime: call.startTime?.toDate?.()?.toISOString() || '',
    endTime: call.endTime?.toDate?.()?.toISOString() || '',
  }));
};

/**
 * Prepare admin log data for export
 */
export const prepareLogDataForExport = (logs: any[]) => {
  return logs.map((log) => ({
    id: log.id,
    adminId: log.adminId,
    adminName: log.adminName,
    action: log.action,
    resource: log.resource,
    resourceId: log.resourceId || '',
    timestamp: log.timestamp?.toDate?.()?.toISOString() || '',
    details: JSON.stringify(log.details || {}),
  }));
};
