Create a new GetX feature module following the project's established architecture pattern.

Module name: $ARGUMENTS

Steps:
1. Create the module directory structure at `lib/app/modules/<module_name>/`:
   - `bindings/<module_name>_binding.dart`
   - `controllers/<module_name>_controller.dart`
   - `views/<module_name>_view.dart`
   - `widgets/` (empty directory for future module-specific widgets)

2. **Binding**: Register the controller with `Get.lazyPut` following the pattern in existing bindings

3. **Controller**: Create extending `GetxController` with:
   - Reactive state variables using `.obs`
   - `onInit()` / `onClose()` lifecycle methods
   - Standard error handling with `log()` from `dart:developer`

4. **View**: Create extending `GetView<ControllerName>` with:
   - Scaffold with AppBar
   - `Obx(() => ...)` for reactive UI
   - Use `ColorsManager`, `StylesManager`, `Paddings` from the theme system
   - Support RTL layout (Arabic + English)

5. **Route**: Add the route to `lib/app/routes/app_pages.dart` and `app_routes.dart`

6. Follow all conventions from CLAUDE.md (const constructors, final variables, Arabic comments where appropriate)
