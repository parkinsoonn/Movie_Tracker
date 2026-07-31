---
name: Cinematic Noir
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1b1b1c'
  surface-container: '#202020'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353535'
  on-surface: '#e5e2e1'
  on-surface-variant: '#d0c6ab'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#303030'
  outline: '#999077'
  outline-variant: '#4d4732'
  surface-tint: '#e9c400'
  primary: '#fff6df'
  on-primary: '#3a3000'
  primary-container: '#ffd700'
  on-primary-container: '#705e00'
  inverse-primary: '#705d00'
  secondary: '#c6c6c7'
  on-secondary: '#2f3131'
  secondary-container: '#454747'
  on-secondary-container: '#b4b5b5'
  tertiary: '#f8f6f5'
  on-tertiary: '#303030'
  tertiary-container: '#dcd9d9'
  on-tertiary-container: '#5f5f5f'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffe16d'
  primary-fixed-dim: '#e9c400'
  on-primary-fixed: '#221b00'
  on-primary-fixed-variant: '#544600'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#e4e2e1'
  tertiary-fixed-dim: '#c8c6c6'
  on-tertiary-fixed: '#1b1c1c'
  on-tertiary-fixed-variant: '#474747'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353535'
typography:
  display-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Be Vietnam Pro
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Be Vietnam Pro
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-padding: 24px
  gutter: 16px
  stack-sm: 12px
  stack-md: 24px
  stack-lg: 40px
---

## Brand & Style
The design system focuses on a "Private Screening" aesthetic—premium, immersive, and high-contrast. It is tailored for cinephiles who value a theater-like atmosphere while browsing and tracking films. 

The style merges **Minimalism** with **Glassmorphism**. By using a deep, monochromatic foundation, the interface recedes to let movie key art and typography take center stage. Interaction points are deliberate and luxurious, utilizing subtle glows and gold highlights to signify quality and achievement (like high ratings or completed watchlists). The emotional response should be one of sophisticated curation and focused immersion.

## Colors
The palette is strictly controlled to maintain a premium feel. 

- **Neutral (Base):** `#1E1E1E` serves as the canvas, providing a deep, non-distracting background that reduces eye strain in low-light environments.
- **Primary (Accent):** `#FFD700` (Gold) is used sparingly for high-value information: star ratings, "Pro" badges, and active states.
- **Secondary (Content):** Pure `#FFFFFF` and high-alpha whites are reserved for critical text and iconography to ensure maximum legibility.
- **Surface Tiers:** Use `#2A2A2A` for primary containers and `#323232` for elevated states (hover/active) to create subtle depth without breaking the dark aesthetic.

## Typography
The typography strategy balances bold, contemporary character with technical precision.

**Be Vietnam Pro** is used for headings to provide a friendly yet modern look. Use heavy weights (700+) for movie titles and section headers to create a strong visual hierarchy against the dark background.

**Inter** handles the bulk of metadata and descriptions, chosen for its exceptional readability at small sizes on mobile screens.

**JetBrains Mono** is utilized for technical metadata (run times, release years, aspect ratios) to evoke the "behind the scenes" feel of a film script or production slate.

## Layout & Spacing
The layout follows a **Fluid Grid** model with generous internal padding to maintain a "gallery" feel.

- **Desktop:** 12-column grid with 24px gutters. Content is centered with a max-width of 1440px.
- **Mobile:** Single column with 20px side margins.
- **Vertical Rhythm:** Use the 8px base unit. Stack elements with 24px (md) spacing for related content and 40px (lg) between major sections.

Movie posters should maintain a consistent aspect ratio (2:3). In list views, prioritize a horizontal scroll for "Similar Movies" to keep the vertical scan efficient.

## Elevation & Depth
In this dark UI, depth is achieved through **Tonal Layers** and **Backdrop Blurs** rather than heavy shadows.

- **Level 0 (Background):** `#1E1E1E` (The void).
- **Level 1 (Cards/Panels):** `#2A2A2A`.
- **Level 2 (Modals/Overlays):** `#323232` with a 20px backdrop blur to create a glassmorphic effect that lets the movie art bleed through.
- **Interaction:** Use a subtle "outer glow" for primary gold elements (ratings/buttons) using `rgba(255, 215, 0, 0.15)` with a 15px spread to simulate a neon or projector light effect.

## Shapes
The design system uses a **Rounded** (12px base) shape language to soften the high-contrast visuals and make the app feel approachable.

- **Cards & Images:** 12px (`rounded-md`).
- **Input Fields & Buttons:** 12px (`rounded-md`).
- **Chips & Tags:** Fully rounded (pill) to distinguish them from actionable buttons.
- **Selection States:** Use a 2px solid gold border for focused movie posters.

## Components

### Buttons
- **Primary:** Solid `#FFD700` with `#1E1E1E` text. Bold weight. High-contrast.
- **Secondary:** Transparent with a 1.5px `#FFFFFF` border (Ghost style).
- **Tertiary:** Text-only with gold icons for low-priority actions.

### Cards
Movie cards are the hero component. They feature a 2:3 aspect ratio poster with a subtle 1px inner stroke (`rgba(255,255,255,0.1)`) to define edges. Metadata (title/year) sits below the poster in white.

### Ratings
The 10-star or decimal rating is always displayed in Gold (`#FFD700`). Use a star icon (filled for the rating, outline for the remainder).

### Inputs
Search bars and text fields use the `#2A2A2A` surface color. On focus, the border transitions to Gold. Placeholder text should be a mid-gray (`#888888`).

### Lists
Lists of actors or crew should use circular avatars (50% radius) with names in `label-md` (JetBrains Mono) to differentiate people from film titles.