# Chart Generator Applications - User Guide

This guide covers two powerful chart visualization tools: **statusPieChart.html** (2D) and **statusPieChart3d.html** (3D). Both are standalone HTML applications that run entirely in your browser with no external dependencies.

---

## 📊 statusPieChart.html - 2D Pie Chart Generator

### Overview
Creates beautiful 2D pie charts with intelligent label placement, customizable styling, and professional callout lines for small slices.

### Key Features

#### 🎨 **Display Options**
- **Show Count**: Display absolute numbers on slices
- **Show Percentage**: Display percentage values on slices
- **Show Legend**: Toggle legend visibility with color-coded entries
- **Callout Threshold**: Slices below this percentage get external callout labels (0-25%, default: 10%)

#### 📁 **Data Management**
- **Import CSV**: Load chart data from CSV files
  - Format: Row 1 (Headers), Row 2 (Values), Row 3 (Colors), Row 4+ (Settings)
- **Export to CSV**: Save chart configuration with all settings preserved
- **Create Chart**: Interactive wizard to build charts from scratch
- **Modify Chart Numbers**: Update slice values without recreating chart

#### 🎨 **Customization**

**Colors**
- Custom color picker for each slice
- Reset to default color palette
- Colors persist in CSV export/import

**Typography**
- **12 Font Families**: Segoe UI, Arial, Helvetica, Times New Roman, Georgia, Courier New, Verdana, Tahoma, Trebuchet MS, Comic Sans MS, Impact, Palatino
- **Title Size**: 50-200% scaling
- **Content Size**: 50-200% scaling (labels, percentages, counts)

**Shadows**
- **Label Shadow Color**: Customizable shadow color for text
- **Shadow Intensity**: 0-300% control for callout boxes and legend shadows

#### 💾 **Export Options**
- **Copy as PNG**: Copy chart to clipboard as image
- **Download PNG**: Save chart as PNG file
- **Copy SVG Code**: Copy raw SVG markup to clipboard
- **Download SVG**: Save chart as scalable vector graphics

#### 🎯 **Smart Label Placement**
- **Large Slices**: Labels placed inside the slice
- **Small Slices**: Automatic callout lines with external labels
- Prevents label overlap with intelligent positioning
- Clean, professional appearance for presentations

### CSV Format (2D Chart)
```csv
Initiative Name,Total,Category1,Category2,...
Title,Total,Value1,Value2,...
Colors,,#color1,#color2,...
FontFamily
CalloutThreshold,value
TitleSize,value
ContentSize,value
ShadowIntensity,value
ShadowColor,value
```

---

## 🎭 statusPieChart3d.html - 3D Pie Chart Generator

### Overview
Advanced 3D pie chart with realistic depth, rotation controls, variable slice depths, explosion effects, and glass polish rendering.

### Key Features

#### 🎨 **Display Options**
- **Show Percentage**: Display percentage values on slices
- **Show Count**: Display absolute numbers on slices  
- **Show Legend**: Toggle legend with color-coded entries
- **Callout Threshold**: Small slices get external labels (0-25%, default: 10%)

#### 🎬 **3D Controls**

**Rotation**
- **X-Axis Rotation**: -90° to +90° (tilt forward/backward)
- **Y-Axis Rotation**: 0° to 360° (spin left/right)
- Real-time preview with smooth rendering

**Depth**
- **Global Depth**: 10-80px (applies to all slices)
- **Variable Depths**: Individual depth per slice (10-100px)
  - Toggle checkbox to enable per-slice depth control
  - Represents "heft of work" or complexity
  - Each slice can have unique thickness

**Depth Direction**
- **⬇ Down (extruded)**: Traditional pie depth extending downward
- **⬆ Up (raised)**: Bar-chart style with slices rising upward
- Automatically adjusts all geometry and shading

#### 💎 **Visual Effects**

**Glass Polish**
- 3D glass effect on visible face
- Radial gradients for depth perception
- Specular highlights simulating light reflection
- Adjustable polish intensity

**Shadow Intensity**
- 0-300% control for 3D depth shadows
- Affects side faces and edges
- Creates realistic depth perception

**Side Opacity**
- 0-100% transparency control (step: 5%)
- 100% = Solid, opaque sides (hides internal geometry)
- Lower values = Transparent/glass effect
- Allows artistic see-through effects

#### 💥 **Slice Explosion**
- **Explosion Distance**: 0-100px (pull slices outward)
- **Per-Slice Control**: Check/uncheck individual slices to explode
- Highlights specific data points
- Great for emphasizing important categories

#### 📁 **Data Management**
- **Import CSV**: Load complete chart state including 3D settings
- **Export to CSV**: Save all configurations (16 rows of settings)
- **Generate Chart**: Interactive creation wizard
- **Modify Chart Numbers**: Update values while preserving all styling

#### 🎨 **Customization**

**Colors**
- Individual color picker per slice
- Reset to default palette
- Color indicators update in all controls
- Full CSV persistence

**Typography**
- **12 Font Families**: Same as 2D version
- **Title Size**: 50-200% scaling
- **Content Size**: 50-200% scaling

#### 💾 **Export Options**
- **Copy PNG**: Copy current 3D view to clipboard
- **Download PNG**: Save exact rendered view as image
- **Download SVG**: Export as scalable vector (PNG embedded)
- All exports capture exact rotation, depth, colors, and effects

#### 🎯 **Advanced Rendering**
- **Z-sorting**: Proper depth ordering for overlapping slices
- **Side Face Rendering**: Curved walls with brightness variation
- **Radial Edges**: Clean straight edges from center to arc
- **Front/Back Faces**: Separated geometry with different shading
- **30-Step Curves**: Smooth circular arcs with no jagged edges

### CSV Format (3D Chart)
```csv
Initiative Name,Total,Category1,Category2,...
Title,Total,Value1,Value2,...
Colors,,#color1,#color2,...
FontFamily
RotationX,value
RotationY,value
Depth,value
ExplosionDistance,value
TitleSize,value
ContentSize,value
CalloutThreshold,value
ExplodedSlices,index1,index2,...
UseVariableDepths,0or1
VariableDepths,,depth1,depth2,...
DepthDirection,0or1
SideOpacity,value
```

**Row Explanations:**
- **Row 1**: Category headers
- **Row 2**: Data values
- **Row 3**: Slice colors
- **Row 4**: Font family name
- **Row 5**: X-Axis rotation angle
- **Row 6**: Y-Axis rotation angle
- **Row 7**: Global depth (used when variable depths OFF)
- **Row 8**: Explosion distance
- **Row 9**: Title font size percentage
- **Row 10**: Content font size percentage
- **Row 11**: Callout threshold percentage
- **Row 12**: Comma-separated indices of exploded slices
- **Row 13**: Variable depths flag (0=OFF, 1=ON)
- **Row 14**: Per-slice depth values (used when Row 13=1)
- **Row 15**: Depth direction (0=Down, 1=Up)
- **Row 16**: Side opacity percentage (0-100)

---

## 🚀 Getting Started

### For Both Applications

1. **Open HTML File**: Double-click to open in any modern browser
2. **Import Data**: Click "Import CSV" or use "Create Chart" wizard
3. **Customize**: Adjust colors, fonts, sizes, and effects
4. **Export**: Download as PNG/SVG or export configuration to CSV

### Creating a Chart from Scratch

1. Click **"Create Chart"** or **"Generate Chart"**
2. Enter chart title
3. Enter number of categories
4. For each category:
   - Enter name
   - Enter value
5. Chart appears immediately
6. Customize as needed

### Modifying Existing Charts

1. Load chart (import CSV or create new)
2. Click **"Modify Chart Numbers"**
3. Update values for any category
4. Chart regenerates with new data

---

## 📋 Best Practices

### Label Readability (Both Apps)
- Set **Callout Threshold** to 10-15% for clean presentation
- Small slices automatically get callout labels
- Adjust **Content Size** if labels overlap

### 3D Chart Optimization
- Use **X-Axis: 20-40°** for good depth perception
- Set **Y-Axis** to emphasize specific slices
- **Side Opacity 100%** for solid, professional look
- **Side Opacity 60-85%** for artistic glass effect

### Variable Depths (3D Only)
- Enable **"Variable Depths"** to show data complexity
- Assign larger depths to more important/complex items
- Export to CSV to save custom depth configurations

### Explosion Effects (3D Only)
- Explode 1-3 slices maximum for clarity
- Use explosion to highlight key data points
- Adjust **Explosion Distance** based on chart size

### Export Quality
- **PNG**: Best for presentations, documents, emails
- **SVG**: Best for print, scaling, further editing
- CSV exports preserve **all settings** for later editing

---

## 💡 Pro Tips

### 2D Charts
- Use shadow color strategically (white shadow on dark backgrounds)
- Higher shadow intensity (200-300%) creates dramatic effects
- Reset colors anytime with "Reset Colors" button

### 3D Charts
- **Depth Direction Up** works great for bar-chart-style comparisons
- Combine explosion + variable depths for maximum emphasis
- Save multiple CSV files for different "views" of same data
- Use low side opacity (30-50%) for unique artistic renders

### Both Applications
- Font size sliders update in real-time
- All controls have visual feedback
- No data loss - everything exports to CSV
- Works offline - no internet required

---

## 🔧 Technical Notes

### Browser Compatibility
- Modern Chrome, Firefox, Safari, Edge
- HTML5 Canvas 2D API
- No external libraries required
- Pure vanilla JavaScript

### Performance
- Handles dozens of slices smoothly
- Real-time rendering with debouncing
- Efficient canvas operations
- Z-sorting for proper 3D depth

### File Formats
- **CSV**: Text-based, human-readable, Excel-compatible
- **PNG**: Raster image, universal compatibility
- **SVG**: Vector format, infinitely scalable

---

## 📞 Troubleshooting

**Chart not appearing?**
- Ensure browser allows canvas rendering
- Check that CSV format matches specification
- Verify all values are numeric

**Labels overlapping?**
- Increase callout threshold
- Adjust content size
- Reduce number of small slices

**3D chart looks flat?**
- Increase depth value
- Adjust X-axis rotation (20-40° recommended)
- Enable side opacity to see depth

**Export not working?**
- Check browser clipboard permissions (for copy functions)
- Ensure popup blocker allows downloads
- Try different browser if issues persist

---

## 🎓 Use Cases

### 2D Charts Best For:
- Status reports
- Budget breakdowns
- Survey results
- Simple data visualization
- Print materials
- Quick presentations

### 3D Charts Best For:
- Executive presentations
- Complex data with multiple dimensions
- Emphasis on specific categories
- Visual impact and engagement
- Showing work complexity (variable depths)
- Interactive data exploration

---

## 📄 License & Credits

Standalone HTML applications with no external dependencies. Use freely for personal and commercial projects.

**Features:**
- ✅ No installation required
- ✅ No internet connection needed
- ✅ No data sent to servers
- ✅ Complete privacy
- ✅ Full customization
- ✅ Professional output

---

*Last Updated: November 2025*
*Version: 2D (v9), 3D (v10)*
