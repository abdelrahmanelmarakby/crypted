Create a new Flutter widget following the project's design system and conventions.

Widget description: $ARGUMENTS

Steps:
1. Determine if the widget should be:
   - **Shared**: placed in `lib/app/widgets/` (used across modules)
   - **Module-specific**: placed in the relevant module's `widgets/` directory
   - **Core**: placed in `lib/app/core/widgets/` (fundamental UI components)

2. Analyze existing widgets in that directory to match the code style exactly

3. Create the widget with:
   - Use `StatelessWidget` unless state is needed (prefer stateless)
   - `const` constructor with named parameters
   - Use the theme system: `ColorsManager`, `StylesManager`, `FontSize`, `Paddings`
   - Support RTL layout (Arabic and English)
   - Use `final` for all instance variables
   - Include proper `Key?` parameter in constructor

4. If the widget needs reactive state from a GetX controller, use `Obx(() => ...)` or `GetBuilder`

5. Follow IBM Plex Sans Arabic font family from the project's font system
