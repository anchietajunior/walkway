# Mock rules

A **Mock** is an image of the intended UI attached to a Task. Mock tools lack the application's configuration, so Walkway reproduces a Mock as closely as the application's front-end rules allow, never pixel for pixel.

**Front-end rules** are what the implemented application already does: its components, design tokens (colors, spacing, typography, radii), layout grid, icons, copy style, and the loading, empty and error states of its screens. Read them in the code and in the screens already built, the **reference screens**.

## Balance

- **The Mock decides** the structure and layout, the content and copy, the visual hierarchy, which elements exist and which states appear.
- **The front-end rules decide** the exact values (colors, spacing, sizes, fonts), the component for each element and its behavior, responsiveness and accessibility.
- A Mock element with no matching component or token takes the closest existing one. Build a new one only when nothing close exists, following the patterns of its neighbors.
- Every deviation from the Mock names the front-end rule that caused it.

## Per Step

- **Research:** save each Mock under `<Task folder>/mocks/` with an ASCII kebab-case name, such as `checkout-empty-state.png`, and look at it. In the Roadmap, write one AC per screen or state the Mock shows ("<screen> matches `mocks/<file>` in structure, content and hierarchy, built with the front-end rules"), name the reference screens, and add one Decision per deviation you already expect, with its rule.
- **Development:** build from the Mock and the reference screens, reusing their components and tokens. List every deviation still in the code, with its rule, under `## Mock deviations` in each `development-<n>.md`, carrying forward the ones from earlier cycles.
- **Simplifier:** the UI still matches the Mock after every simplification.
- **Code Review:** check each Mock AC, and report as Required a value copied from the Mock where a token or component already exists.
- **Validation:** screenshot each screen and state in the running application and compare it side by side with the Mock and the reference screens. A difference is a Finding unless a Decision or a listed Mock deviation explains it. Save the screenshots with your evidence.
