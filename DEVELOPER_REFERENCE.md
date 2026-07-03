# Nyero AVR System - Developer Reference

## Architecture Overview

### New Features Components

#### 1. Settings System

```javascript
// Load settings from localStorage
const settings = loadSettings();

// Save settings
saveSettings(settings);

// Toggle individual settings
toggleSetting(element);

// Apply graphics changes
applyGraphicsSettings(settings);
```

**Storage Key**: `nyero_settings`

**Default Settings Object**:

```javascript
{
  particles: true,      // Enable particle effects
  shadows: true,        // Enable shadows
  fog: true,           // Enable fog
  audio: true,         // Enable ambient audio
  labels: true,        // Show hotspot labels
  beacon: true,        // Show pointer beacon
  textSize: 1.0,       // Text scale factor
  volume: 50,          // Audio volume (0-100)
  minimap: false,      // Show minimap
  perfMonitor: false   // Show performance monitor
}
```

---

#### 2. Progress Tracking

```javascript
// Storage key for visited paintings
const VISITED_PAINTINGS = "nyero_visited";

// Initialize tracker
initProgressTracker();

// Update display
updateProgressDisplay();
```

**Data Format**: Array of painting IDs

```javascript
['painting-nyero1', 'painting-sun', ...]
```

**Automatic**: Click on paintings to add to visited list

---

#### 3. Search System

```javascript
// Initialize search
initSearch();

// Paintings database
const PAINTINGS_DATA = [{ id: "painting-id", name: "Name", tags: "keywords" }];
```

**Features**:

- Real-time filtering
- Auto-navigation on selection
- Tag-based search

---

#### 4. Minimap Implementation

```javascript
// Initialize minimap
initMinimap();

// Toggle visibility
toggleMinimap();

// Canvas ID: minimap-canvas
// Size: 140x140 pixels
// Updates every frame using requestAnimationFrame
```

**Minimap Features**:

- Player position (blue square)
- Viewing direction (white arrow)
- Painting locations (colored dots)
- Scene boundaries (grid)

---

#### 5. Guided Tour System

```javascript
// Start/stop tour
startGuidedTour();

// Advance to next step
advanceTour();

// Tour sequence array
const tourSequence = [
  {x, y, z, name, desc},
  ...
];
```

**Tour Data**: 12 waypoints with descriptions

---

#### 6. Performance Monitoring

```javascript
// Toggle monitor display
togglePerfMonitor();

// Monitor updates every frame
updatePerfMonitor();

// Tracked metrics:
// - FPS (frames per second)
// - Entity count
// - Response time (ping)
```

---

#### 7. Notifications System

```javascript
// Show toast notification
showToast(message, duration);

// Default duration: 3000ms
// Auto-removes after display
```

---

### CSS Classes Reference

| Class                 | Purpose                     |
| --------------------- | --------------------------- |
| `.settings-modal`     | Settings panel container    |
| `.settings-card`      | Settings card styling       |
| `.settings-toggle`    | Toggle switch component     |
| `.help-modal`         | Help panel container        |
| `.progress-container` | Progress bar container      |
| `.search-container`   | Search bar wrapper          |
| `.toast`              | Notification element        |
| `#minimap`            | Minimap container           |
| `#perf-monitor`       | Performance monitor display |

---

### Event Listeners

**Global Events**:

```javascript
// Keyboard shortcuts
document.addEventListener("keydown", (e) => {
  if (e.key === "h") openHelp();
  if (e.key === "o") openSettings();
});

// Settings changed
// Search performed
// Tour advanced
// Painting visited
```

---

### Local Storage Schema

```javascript
// User Settings
localStorage.getItem("nyero_settings");
// → JSON string of settings object

// Visited Paintings
localStorage.getItem("nyero_visited");
// → JSON array of painting IDs
```

---

### Functions Reference

#### Settings Management

```javascript
loadSettings(); // Load settings from storage
saveSettings(obj); // Save settings to storage
toggleSetting(elem); // Toggle a setting on/off
setVolume(value); // Set audio volume
setTextSize(value); // Set text scaling
applyGraphicsSettings(); // Apply graphics changes
closeSettings(); // Close settings modal
```

#### Progress

```javascript
initProgressTracker(); // Initialize progress system
updateProgressDisplay(); // Update progress UI
```

#### Search

```javascript
initSearch(); // Initialize search functionality
// Search input id: search-input
// Results container id: search-results
```

#### Minimap

```javascript
initMinimap(); // Initialize minimap
toggleMinimap(); // Toggle minimap display
// Canvas id: minimap-canvas
```

#### Tour

```javascript
startGuidedTour(); // Start/stop guided tour
advanceTour(); // Move to next tour step
```

#### Performance

```javascript
updatePerfMonitor(); // Update performance display
togglePerfMonitor(); // Toggle monitor visibility
```

#### UI

```javascript
showToast(msg, dur); // Show notification
toggleFullscreen(); // Toggle fullscreen mode
closeHelp(); // Close help modal
```

---

### Integration Points

#### With A-Frame

- Settings applied to `a-scene` attributes
- Minimap reads camera position from `a-entity[camera]`
- Tour navigation uses `navigateTo()` function
- Paintings tracked by element ID

#### With Authentication

- Settings tied to user session
- Progress tied to user account
- Favorites could extend user profile

#### With Navigation

- Search results use `navigateTo(x, y, z)`
- Tour uses navigation system
- Quick buttons integrated

---

### Extending Features

#### Add New Settings

1. Add property to `DEFAULT_SETTINGS`
2. Create UI toggle/input in settings panel
3. Add handler in `toggleSetting()`
4. Add logic to `applyGraphicsSettings()`

#### Add New Paintings

1. Add to `PAINTINGS_DATA` array
2. Update `tourSequence` array
3. Paintings automatically in search
4. Minimap shows new location

#### Add New Tour Steps

1. Add waypoint to `tourSequence`
2. Include `{x, y, z, name, desc}`
3. Tour automatically includes new step

---

### Performance Considerations

**Minimap Rendering**:

- Uses canvas 2D context
- Updates every frame (requestAnimationFrame)
- Consider disabling on mobile if FPS drops

**Search Index**:

- Pre-computed in `PAINTINGS_DATA`
- Linear search (11 items - negligible)
- Could be optimized with trie/fuzzy search

**Settings Impact**:

- Particle effects: ~5-10% FPS impact
- Shadows: ~10-15% FPS impact
- Fog: ~2-5% FPS impact

---

### Browser Compatibility

**Required APIs**:

- localStorage (for settings)
- Fullscreen API (for fullscreen toggle)
- Canvas 2D (for minimap)
- requestAnimationFrame (for smooth updates)

**Tested On**:

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers

---

### Security Notes

- All data stored client-side only
- No sensitive data in localStorage
- Settings are user-preferences only
- No authentication bypasses in features

---

### Debugging Tips

**Check Settings**:

```javascript
console.log(loadSettings());
```

**Check Progress**:

```javascript
console.log(JSON.parse(localStorage.getItem("nyero_visited")));
```

**Check Minimap Canvas**:

```javascript
const canvas = document.getElementById("minimap-canvas");
console.log(canvas.getContext("2d"));
```

**Monitor Performance**:

```javascript
// Enable perf monitor
togglePerfMonitor();
```

---

### Future Enhancements

**Potential Improvements**:

- [ ] IndexedDB for larger datasets
- [ ] Service Worker for offline support
- [ ] Progressive Web App (PWA) support
- [ ] Cloud sync for cross-device
- [ ] Analytics tracking
- [ ] A/B testing framework
- [ ] User feedback system
- [ ] Screenshot/export functionality

---

## Code Quality

**Standards Applied**:

- Descriptive function names
- Clear variable naming
- Inline comments for complex logic
- Organized code sections
- Consistent formatting
- Error handling with try-catch
- User feedback (toast notifications)

---

## Maintenance

**Regular Tasks**:

- Monitor browser compatibility
- Update A-Frame library when needed
- Test on various device sizes
- Gather user feedback
- Optimize performance as needed
- Keep documentation updated

---

Generated for Nyero AVR System v1.0
