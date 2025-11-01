import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { ChatRoom, Message } from '../../types/chat.types';

interface ChatState {
  rooms: ChatRoom[];
  selectedRoom: ChatRoom | null;
  messages: Message[];
  loading: boolean;
  error: string | null;
  totalRooms: number;
}

const initialState: ChatState = {
  rooms: [],
  selectedRoom: null,
  messages: [],
  loading: false,
  error: null,
  totalRooms: 0,
};

const chatSlice = createSlice({
  name: 'chats',
  initialState,
  reducers: {
    setChatRooms: (state, action: PayloadAction<ChatRoom[]>) => {
      state.rooms = action.payload;
      state.loading = false;
      state.error = null;
    },
    setSelectedRoom: (state, action: PayloadAction<ChatRoom | null>) => {
      state.selectedRoom = action.payload;
    },
    setMessages: (state, action: PayloadAction<Message[]>) => {
      state.messages = action.payload;
    },
    removeMessage: (state, action: PayloadAction<string>) => {
      state.messages = state.messages.filter((m) => m.id !== action.payload);
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload;
      state.loading = false;
    },
    setTotalRooms: (state, action: PayloadAction<number>) => {
      state.totalRooms = action.payload;
    },
  },
});

export const {
  setChatRooms,
  setSelectedRoom,
  setMessages,
  removeMessage,
  setLoading,
  setError,
  setTotalRooms,
} = chatSlice.actions;

export default chatSlice.reducer;
