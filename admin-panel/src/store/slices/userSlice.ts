import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { User } from '../../types/user.types';

interface UserState {
  list: User[];
  selectedUser: User | null;
  loading: boolean;
  error: string | null;
  totalCount: number;
  searchQuery: string;
  filters: {
    status?: string;
    dateFrom?: Date;
    dateTo?: Date;
  };
}

const initialState: UserState = {
  list: [],
  selectedUser: null,
  loading: false,
  error: null,
  totalCount: 0,
  searchQuery: '',
  filters: {},
};

const userSlice = createSlice({
  name: 'users',
  initialState,
  reducers: {
    setUsers: (state, action: PayloadAction<User[]>) => {
      state.list = action.payload;
      state.loading = false;
      state.error = null;
    },
    setSelectedUser: (state, action: PayloadAction<User | null>) => {
      state.selectedUser = action.payload;
    },
    updateUser: (state, action: PayloadAction<User>) => {
      const index = state.list.findIndex((u) => u.uid === action.payload.uid);
      if (index !== -1) {
        state.list[index] = action.payload;
      }
      if (state.selectedUser?.uid === action.payload.uid) {
        state.selectedUser = action.payload;
      }
    },
    removeUser: (state, action: PayloadAction<string>) => {
      state.list = state.list.filter((u) => u.uid !== action.payload);
      if (state.selectedUser?.uid === action.payload) {
        state.selectedUser = null;
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
    setSearchQuery: (state, action: PayloadAction<string>) => {
      state.searchQuery = action.payload;
    },
    setFilters: (state, action: PayloadAction<UserState['filters']>) => {
      state.filters = action.payload;
    },
  },
});

export const {
  setUsers,
  setSelectedUser,
  updateUser,
  removeUser,
  setLoading,
  setError,
  setTotalCount,
  setSearchQuery,
  setFilters,
} = userSlice.actions;

export default userSlice.reducer;
