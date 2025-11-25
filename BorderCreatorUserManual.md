# Border Creator User Manual

## Overview
**Border Creator** (Golden Frame Constructor) is a specialized design tool for creating intricate, high-quality border frames, wreaths, and decorative edges. It combines procedural pattern generation with a stamp-based floral designer, allowing you to create complex compositions for certificates, invitations, or digital art.

## Getting Started

### The Interface
The application is divided into two main areas:
1.  **Sidebar (Left)**: Contains all controls for materials, stamps, layers, and export settings.
2.  **Canvas (Right)**: The main workspace where you build your design.

### Basic Workflow
1.  **Choose a Shape**: Select Rectangle, Square, Circle, or Oval from the top bar.
2.  **Add Layers**: Build the frame structure using procedural lines and patterns.
3.  **Add Stamps**: Decorate with flowers, leaves, and ornaments.
4.  **Customize**: Adjust materials, colors, and shadows.
5.  **Export**: Save your design as an image or JSON project file.

---

## 1. Border Designer (Layers)
The core of the frame is built using **Layers**. Each layer draws a pattern at a specific distance (inset) from the edge.

### Managing Layers
*   **Add Layer**: Click the `+ Add Layer` button at the bottom of the Border Designer section.
*   **Delete Layer**: Click the red `x` next to a layer in the list.
*   **Reorder**: Layers are drawn in order. Currently, reordering is done by deleting and re-adding (or editing existing layers).

### Layer Properties
*   **Inset**: Distance from the canvas edge.
*   **Size**: Thickness of the line or size of the pattern elements.
*   **Spacing**: Gap between repeated elements (for patterns like dots or stars).
*   **Lines**: Create multi-line strips (e.g., 3 parallel lines).
*   **Sep (Separation)**: Distance between multiple lines.
*   **Corner Radius**: Rounds the corners of the layer path.

### Patterns
Choose from various styles:
*   **Line Styles**: Solid, Wavy, Curvy, Baroque, Stitch.
*   **Shape Repeaters**: Line Dash, Circles, Diamonds, Crosses, Stars, Hearts.
*   **Floral**: Roses, Daisies, Tulips, Leaves (these repeat along the path).

### Segment Control (Mini-Map)
The **Segment Map** (SVG display) allows you to control *where* the layer appears.
*   Click segments on the map to toggle them on/off.
*   **Presets**:
    *   **All**: Full border.
    *   **Corners**: Only draws in the corners.
    *   **Sides**: Only draws on the sides.
    *   **Top/Bottom**: Only draws on top and bottom edges.

### Global Edit Mode
*   **Apply to All Layers**: Check this box to apply changes (Inset, Size, Pattern, etc.) to **all** layers simultaneously. Useful for quickly resizing the entire frame.

---

## 2. Stamp Designer (Decorations)
Stamps are individual graphical elements like flowers, leaves, or corners that you place freely on the canvas.

### Placing Stamps
1.  Select a stamp from the list (e.g., "Pro Leaf", "Lily", "Classic Corner").
2.  Ensure **Place** mode is active (Yellow button).
3.  Click anywhere on the canvas to place the stamp.

### Stamp Properties
Before or after placing, you can adjust:
*   **Size**: Scale of the stamp.
*   **Rotation**: Angle in degrees.
*   **Flip H/V**: Mirror the stamp horizontally or vertically.

### Cluster Mode
Create wreaths or bouquets instantly.
1.  Toggle **Cluster Mode** on.
2.  Adjust **Count** (number of items) and **Radius**.
3.  Click on the canvas to place a circular arrangement of the selected stamp.

---

## 3. Selection & Editing
Switch to **Select & Edit** mode (Gray button) to manipulate existing stamps.

### Single Selection
*   **Click** a stamp to select it.
*   **Drag** to move it.
*   The sidebar controls will update to show the selected stamp's properties.

### Multi-Selection
*   **Shift + Click** to select multiple stamps.
*   **Drag** any selected stamp to move the entire group.
*   **Duplicate**: Click the "Duplicate" button to clone all selected stamps.

### Deleting
*   **Undo**: Click the Undo button in the top bar to remove the last action.
*   **Clear All**: Removes all global stamps.

---

## 4. Floral Designer (Customization)
For "Pro" stamps (like Procedural Leaf) and certain flowers, you can customize their internal colors and structure.

*   **Colors**:
    *   **Inner/Outer**: Gradient colors for petals.
    *   **Leaf/Vein**: Colors for foliage.
*   **Structure**:
    *   **Petals**: Number of petals for flowers.
    *   **Vein Thick**: Thickness of leaf veins.
    *   **Leaf Shape**: Choose between Simple, Oak, Maple, Fern, or Ivy.
*   **Shadows**: Toggle internal shadows for depth.

---

## 5. Materials & Global Settings
Define the overall look of the frame.

### Base Material
Choose a metallic or gem-like finish:
*   **Metals**: Gold, Silver, Rose Gold, Copper, Steel.
*   **Gems**: Emerald, Ruby, Sapphire, Amethyst, Pearl, Obsidian.
*   **Brightness**: Adjust the shine/lightness of the material.

### Global Shadows
Add depth to the entire composition.
*   **Shadow Blur**: Softness of the shadow.
*   **Shadow Color**: Tint of the shadow.
*   **Shadow Intensity**: Opacity of the shadow.

### Background
*   **Transparent**: Check this for exporting PNGs with transparency.
*   **Canvas Color**: Default is a dark slate for contrast.

---

## 6. Export & Import

### Saving Your Work
*   **Export JSON**: Saves the entire project state (layers, stamps, settings) to a `.json` file.
*   **Import JSON**: Load a previously saved project.
*   **Copy Data**: Copies the raw JSON to your clipboard.

### Exporting Images
*   **Quality**: Choose 1x (Screen), 2x (HD), or 4x (Print/4K).
*   **Save**: Downloads a `.png` file of your creation.
*   **Copy**: Copies the image to your clipboard (useful for pasting directly into other apps).

---

## 7. Quick Themes (Presets)
Use the **Quick Themes** tabs in the Border Designer to instantly load pre-made styles:
*   **Floral**: Romantic and nature-inspired borders.
*   **Classic**: Traditional frames, art deco, and baroque styles.
*   **Modern**: Clean lines, steel finishes, and geometric shapes.
*   **Shapes**: Specific setups for circular and oval frames.
