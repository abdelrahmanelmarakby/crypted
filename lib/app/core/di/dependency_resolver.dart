import 'dart:async';
import 'package:get/get.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';

/// ARCH-013: Dependency Resolver
/// Resolves circular dependencies using dependency inversion principle
/// and lazy initialization patterns
class DependencyResolver {
  static final DependencyResolver instance = DependencyResolver._();
  DependencyResolver._();

  final _logger = LoggerService.instance;
  final Map<Type, DependencyFactory> _factories = {};
  final Map<Type, dynamic> _singletons = {};
  final Set<Type> _currentlyResolving = {};

  /// Register a factory for lazy initialization
  void registerFactory<T>(T Function() factory, {bool singleton = true}) {
    _factories[T] = DependencyFactory<T>(
      factory: factory,
      isSingleton: singleton,
    );
    _logger.debug('Registered factory for $T', context: 'DependencyResolver');
  }

  /// Register a lazy singleton (created on first access)
  void registerLazySingleton<T>(T Function() factory) {
    registerFactory<T>(factory, singleton: true);
  }

  /// Register an existing instance
  void registerInstance<T>(T instance) {
    _singletons[T] = instance;
    _logger.debug('Registered instance for $T', context: 'DependencyResolver');
  }

  /// Resolve a dependency
  T resolve<T>() {
    // Check for singleton first
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // Check for circular dependency
    if (_currentlyResolving.contains(T)) {
      throw CircularDependencyException(
        'Circular dependency detected while resolving $T. '
        'Currently resolving: $_currentlyResolving',
      );
    }

    // Check for factory
    final factory = _factories[T];
    if (factory == null) {
      // Try GetX as fallback
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
      throw DependencyNotFoundException('No factory registered for $T');
    }

    _currentlyResolving.add(T);
    try {
      final instance = factory.create();

      if (factory.isSingleton) {
        _singletons[T] = instance;
      }

      return instance as T;
    } finally {
      _currentlyResolving.remove(T);
    }
  }

  /// Try to resolve, returns null if not found
  T? tryResolve<T>() {
    try {
      return resolve<T>();
    } catch (e) {
      return null;
    }
  }

  /// Check if a type is registered
  bool isRegistered<T>() {
    return _factories.containsKey(T) ||
        _singletons.containsKey(T) ||
        Get.isRegistered<T>();
  }

  /// Unregister a type
  void unregister<T>() {
    _factories.remove(T);
    _singletons.remove(T);
  }

  /// Reset all registrations
  void reset() {
    _factories.clear();
    _singletons.clear();
    _currentlyResolving.clear();
  }
}

/// Factory wrapper for deferred initialization
class DependencyFactory<T> {
  final T Function() factory;
  final bool isSingleton;

  DependencyFactory({
    required this.factory,
    required this.isSingleton,
  });

  T create() => factory();
}

/// Exception for circular dependencies
class CircularDependencyException implements Exception {
  final String message;
  CircularDependencyException(this.message);

  @override
  String toString() => 'CircularDependencyException: $message';
}

/// Exception for missing dependencies
class DependencyNotFoundException implements Exception {
  final String message;
  DependencyNotFoundException(this.message);

  @override
  String toString() => 'DependencyNotFoundException: $message';
}

/// Mixin for controllers that need to resolve dependencies
mixin DependencyResolveMixin {
  final _resolver = DependencyResolver.instance;

  /// Resolve a dependency
  T inject<T>() => _resolver.resolve<T>();

  /// Try to resolve a dependency
  T? tryInject<T>() => _resolver.tryResolve<T>();

  /// Check if a dependency is available
  bool hasInjection<T>() => _resolver.isRegistered<T>();
}

/// Interface marker for abstracting implementations
abstract class IService {}

/// Abstract repository interface for dependency inversion
abstract class IRepository {}

/// Interface for breaking circular dependencies between controllers
abstract class IControllerBridge {
  void notify(String event, [dynamic data]);
  Stream<dynamic> on(String event);
}

/// Implementation of controller bridge for decoupling
class ControllerBridge implements IControllerBridge {
  final Map<String, List<void Function(dynamic)>> _listeners = {};

  @override
  void notify(String event, [dynamic data]) {
    final handlers = _listeners[event];
    if (handlers != null) {
      for (final handler in handlers) {
        handler(data);
      }
    }
  }

  @override
  Stream<dynamic> on(String event) {
    // Create a stream controller for this event
    final controller = StreamController<dynamic>.broadcast();

    void handler(dynamic data) {
      if (!controller.isClosed) {
        controller.add(data);
      }
    }

    _listeners[event] ??= [];
    _listeners[event]!.add(handler);

    // Cleanup when stream is done
    controller.onCancel = () {
      _listeners[event]?.remove(handler);
    };

    return controller.stream;
  }

  void dispose() {
    _listeners.clear();
  }
}

/// Lazy proxy for deferring initialization
class LazyProxy<T> {
  final T Function() _factory;
  T? _instance;
  bool _initialized = false;

  LazyProxy(this._factory);

  T get value {
    if (!_initialized) {
      _instance = _factory();
      _initialized = true;
    }
    return _instance as T;
  }

  bool get isInitialized => _initialized;

  void reset() {
    _instance = null;
    _initialized = false;
  }
}

/// Provider pattern for interface-based dependency injection
class Provider<T> {
  final T Function() _factory;

  Provider(this._factory);

  T provide() => _factory();

  /// Create a provider that returns the same instance
  factory Provider.value(T value) {
    return Provider(() => value);
  }

  /// Create a lazy singleton provider
  factory Provider.lazy(T Function() factory) {
    T? instance;
    return Provider(() {
      instance ??= factory();
      return instance!;
    });
  }
}

/// Scope for managing dependency lifecycle
class DependencyScope {
  final String name;
  final Map<Type, dynamic> _scopedInstances = {};
  final DependencyResolver _resolver = DependencyResolver.instance;
  final _logger = LoggerService.instance;

  DependencyScope(this.name);

  /// Register a scoped instance
  void register<T>(T instance) {
    _scopedInstances[T] = instance;
    _logger.debug('Registered scoped instance for $T in scope $name',
        context: 'DependencyScope');
  }

  /// Resolve within scope
  T resolve<T>() {
    if (_scopedInstances.containsKey(T)) {
      return _scopedInstances[T] as T;
    }
    return _resolver.resolve<T>();
  }

  /// Dispose the scope and cleanup
  void dispose() {
    for (final instance in _scopedInstances.values) {
      if (instance is GetxController) {
        instance.onClose();
      }
    }
    _scopedInstances.clear();
    _logger.debug('Disposed scope $name', context: 'DependencyScope');
  }
}
