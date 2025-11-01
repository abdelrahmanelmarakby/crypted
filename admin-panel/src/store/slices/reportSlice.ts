import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Report } from '../../types/report.types';

interface ReportState {
  list: Report[];
  selectedReport: Report | null;
  loading: boolean;
  error: string | null;
  totalCount: number;
  pendingCount: number;
  filters: {
    status?: string;
    type?: string;
    priority?: string;
  };
}

const initialState: ReportState = {
  list: [],
  selectedReport: null,
  loading: false,
  error: null,
  totalCount: 0,
  pendingCount: 0,
  filters: {},
};

const reportSlice = createSlice({
  name: 'reports',
  initialState,
  reducers: {
    setReports: (state, action: PayloadAction<Report[]>) => {
      state.list = action.payload;
      state.pendingCount = action.payload.filter((r) => r.status === 'pending').length;
      state.loading = false;
      state.error = null;
    },
    setSelectedReport: (state, action: PayloadAction<Report | null>) => {
      state.selectedReport = action.payload;
    },
    updateReport: (state, action: PayloadAction<Report>) => {
      const index = state.list.findIndex((r) => r.id === action.payload.id);
      if (index !== -1) {
        state.list[index] = action.payload;
      }
      if (state.selectedReport?.id === action.payload.id) {
        state.selectedReport = action.payload;
      }
      state.pendingCount = state.list.filter((r) => r.status === 'pending').length;
    },
    removeReport: (state, action: PayloadAction<string>) => {
      state.list = state.list.filter((r) => r.id !== action.payload);
      if (state.selectedReport?.id === action.payload) {
        state.selectedReport = null;
      }
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload;
      state.loading = false;
    },
    setTotalCount: (state, action: PayloadAction<number>) => {
      state.totalCount = action.payload;
    },
    setPendingCount: (state, action: PayloadAction<number>) => {
      state.pendingCount = action.payload;
    },
    setFilters: (state, action: PayloadAction<ReportState['filters']>) => {
      state.filters = action.payload;
    },
  },
});

export const {
  setReports,
  setSelectedReport,
  updateReport,
  removeReport,
  setLoading,
  setError,
  setTotalCount,
  setPendingCount,
  setFilters,
} = reportSlice.actions;

export default reportSlice.reducer;
