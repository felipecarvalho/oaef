# Design System Standards & Visual Boundaries

> Canonical design system guide for `python-starter`. All user interface implementation must adhere strictly to these principles.

---

## 1. The Design Boundary Principle

To maintain visual cohesion, accessibility, and maintainability:
- **Direct Framework Primitives Are Forbidden in Views**: Do not use raw, un-themed framework primitives (e.g. raw unstyled buttons, raw un-tokenized colors) directly in feature screens.
- **Use Encapsulated Design System Components**: Feature screens must compose standardized components from the project's shared component library.
- **Strict Tokenization**: Never hardcode colors, padding values, or typography scales. Always use design tokens.

---

## 2. Design Token System

### Colors & Palette
- **Primary / Brand**: The principal action and emphasis color.
- **Surface & Background**: Neutral tokens for cards, sheets, and views.
- **Feedback & Semantics**: Success, Warning, Error, and Informational tokens.

### Typography Scale
- **Display**: Reserved for prominent marketing headings.
- **Title**: Section and modal headers.
- **Body**: Standard paragraph content (regular and medium weights).
- **Caption / Label**: Metadata, timestamps, and badges.

### Spacing & Layout
- 4px/8px incremental grid:
  - `none`: 0px
  - `xs`: 4px
  - `sm`: 8px
  - `md`: 16px
  - `lg`: 24px
  - `xl`: 32px
  - `xxl`: 48px

---

## 3. Accessibility & Responsiveness
- All interactive touch targets must meet WCAG 2.2 minimums (>= 44x44 points).
- Ensure color contrast ratios satisfy WCAG AA (>= 4.5:1 for normal text).
- Layouts must adapt to compact screens, tablets, and varied viewport widths using flexible/responsive containers.
