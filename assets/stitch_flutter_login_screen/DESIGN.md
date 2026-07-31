---
name: Cinematic Noir
colors:
  surface: '#141313'
  surface-dim: '#141313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2b2a2a'
  surface-container-highest: '#353434'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c4c7c7'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8e9192'
  outline-variant: '#444748'
  surface-tint: '#c8c6c5'
  primary: '#c8c6c5'
  on-primary: '#313030'
  primary-container: '#121212'
  on-primary-container: '#7e7d7d'
  inverse-primary: '#5f5e5e'
  secondary: '#c9c6c5'
  on-secondary: '#313030'
  secondary-container: '#484646'
  on-secondary-container: '#b7b4b4'
  tertiary: '#cac6c3'
  on-tertiary: '#32302f'
  tertiary-container: '#131211'
  on-tertiary-container: '#807d7b'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c8c6c5'
  on-primary-fixed: '#1c1b1b'
  on-primary-fixed-variant: '#474646'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c9c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#484646'
  tertiary-fixed: '#e6e1df'
  tertiary-fixed-dim: '#cac6c3'
  on-tertiary-fixed: '#1c1b1a'
  on-tertiary-fixed-variant: '#484645'
  background: '#141313'
  on-background: '#e5e2e1'
  surface-variant: '#353434'
typography:
  display-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 48px
    fontWeight: '800'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-lg-mobile:
    fontFamily: Be Vietnam Pro
    fontSize: 28px
    fontWeight: '700'
    lineHeight: '1.2'
  title-md:
    fontFamily: Be Vietnam Pro
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  body-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1'
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-padding: 24px
  gutter: 16px
  section-gap: 64px
  stack-sm: 4px
  stack-md: 12px
  stack-lg: 24px
---

## Brand & Style
The design system embodies a "Cinematic Noir" aesthetic, characterized by high-stakes atmosphere, deep immersion, and premium focus. It targets a modern audience that appreciates sophisticated storytelling, whether in entertainment, gaming, or high-end creative tools. 

The style is a hybrid of **Modern Minimalism** and **Glassmorphism**, set against a dark, dramatic backdrop. It evokes an emotional response of focus, luxury, and anticipation. Visual hierarchy is established through vibrant accent gradients that pierce through the charcoal darkness, simulating the "neon-on-asphalt" look of modern cinematography.

## Colors
The palette is rooted in a deep charcoal base to create a theater-like environment where content is the protagonist. 

- **Primary Background:** `#121212` provides the foundational depth.
- **Accent Gradient:** A dynamic transition from vibrant purple to amber. This gradient is used sparingly for high-intent actions and focal points.
- **Surfaces:** Use `#1E1E1E` for container backgrounds to create subtle separation from the base layer.
- **State Colors:** Success and Error states should be tinted with low-opacity versions of the accent colors or standard semantic colors adjusted to high-vibrancy levels to maintain the cinematic intensity.

## Typography
The system utilizes **Be Vietnam Pro** across all levels to maintain a contemporary, approachable, yet sleek feel. 

Headlines use heavy weights and tight letter-spacing to mimic movie titles and editorial layouts. Body text is optimized for readability against dark backgrounds, using slightly increased line heights to prevent "halo" effects on high-contrast displays. Labels and secondary metadata utilize uppercase styling with generous tracking to provide a technical, "HUD" (Heads-Up Display) aesthetic.

## Layout & Spacing
This design system uses a **Fluid Grid** model with a 12-column structure for desktop and a 4-column structure for mobile. 

The layout philosophy emphasizes generous negative space to direct the eye. Spacing is based on an 8px rhythmic scale. For cinematic landing pages and login screens, content is typically centered or grouped in large "islands" of information with wide margins (minimum 24px) to ensure the interface feels airy and premium.

## Elevation & Depth
Depth is achieved through **Tonal Layering** and **Glassmorphism** rather than traditional heavy shadows.

- **Level 0 (Base):** Deep charcoal (`#121212`).
- **Level 1 (Cards/Inputs):** A slightly lighter surface (`#1E1E1E`) with a subtle 1px border (`#2A2A2A`).
- **Level 2 (Modals/Overlays):** Semi-transparent surfaces using a backdrop blur (20px - 32px) and a light inner glow or "rim light" (0.5px white at 10% opacity) on the top edge to simulate physical lighting.
- **Floating Elements:** Use a soft, expansive shadow with a purple or amber tint (5% opacity) to suggest the accent colors are casting ambient light onto the surface below.

## Shapes
The shape language is consistently **Rounded** (0.5rem / 8px). This softens the "industrial" feel of the dark theme, making the UI feel more accessible and modern. 

- **Inputs & Small Buttons:** 8px radius.
- **Cards & Login Containers:** 16px radius (`rounded-lg`).
- **Feature Tags/Chips:** Full pill-shape (`rounded-full`) to differentiate from interactive buttons.

## Components

- **Primary Buttons:** Styled with a horizontal gradient from Purple to Amber. Text is white with a slight drop shadow for legibility. On hover, the gradient shifts in intensity or "glows" using a box-shadow that matches the gradient colors.
- **Input Fields:** Backgrounds are a dark grey (`#1E1E1E`) with a subtle border. On focus, the border transitions to the accent purple, and a 2px outer glow is applied.
- **Chips:** Translucent dark backgrounds with purple or amber text. Used for categories or status indicators.
- **Login Cards:** High-blur glassmorphism containers. They should feature a very thin 1px border that picks up the ambient light of the background.
- **Checkboxes & Radios:** Use the amber accent for the "checked" state to ensure high visibility against the dark background.
- **Loading States:** Use a shimmering "skeleton" effect that cycles through dark grey and a deep purple tint, mimicking a film reel or digital scanline.