import { useEffect } from 'react';
import { useAppDispatch, useAppSelector } from '../store';
import { setUser, setLoading, logout } from '../store/slices/authSlice';
import authService from '../services/auth.service';

export const useAuth = () => {
  const dispatch = useAppDispatch();
  const { user, loading, isAuthenticated, error } = useAppSelector((state) => state.auth);

  useEffect(() => {
    dispatch(setLoading(true));

    const unsubscribe = authService.onAuthStateChange((adminUser) => {
      dispatch(setUser(adminUser));
    });

    return () => unsubscribe();
  }, [dispatch]);

  const login = async (email: string, password: string) => {
    try {
      dispatch(setLoading(true));
      const adminUser = await authService.login(email, password);
      dispatch(setUser(adminUser));
      return { success: true };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  };

  const logoutUser = async () => {
    try {
      await authService.logout();
      dispatch(logout());
      return { success: true };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  };

  const hasPermission = (permission: keyof NonNullable<typeof user>['permissions']) => {
    return authService.hasPermission(user, permission);
  };

  const isSuperAdmin = () => {
    return authService.isSuperAdmin(user);
  };

  return {
    user,
    loading,
    isAuthenticated,
    error,
    login,
    logout: logoutUser,
    hasPermission,
    isSuperAdmin,
  };
};
