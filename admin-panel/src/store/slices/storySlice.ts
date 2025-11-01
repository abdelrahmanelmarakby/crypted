import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Story } from '../../types/story.types';

interface StoryState {
  list: Story[];
  selectedStory: Story | null;
  loading: boolean;
  error: string | null;
  totalCount: number;
  filters: {
    status?: string;
    type?: string;
    userId?: string;
  };
}

const initialState: StoryState = {
  list: [],
  selectedStory: null,
  loading: false,
  error: null,
  totalCount: 0,
  filters: {},
};

const storySlice = createSlice({
  name: 'stories',
  initialState,
  reducers: {
    setStories: (state, action: PayloadAction<Story[]>) => {
      state.list = action.payload;
      state.loading = false;
      state.error = null;
    },
    setSelectedStory: (state, action: PayloadAction<Story | null>) => {
      state.selectedStory = action.payload;
    },
    removeStory: (state, action: PayloadAction<string>) => {
      state.list = state.list.filter((s) => s.id !== action.payload);
      if (state.selectedStory?.id === action.payload) {
        state.selectedStory = null;
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
    setFilters: (state, action: PayloadAction<StoryState['filters']>) => {
      state.filters = action.payload;
    },
  },
});

export const {
  setStories,
  setSelectedStory,
  removeStory,
  setLoading,
  setError,
  setTotalCount,
  setFilters,
} = storySlice.actions;

export default storySlice.reducer;
