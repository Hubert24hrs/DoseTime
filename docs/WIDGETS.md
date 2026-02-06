# Widget Documentation

## ThreeDButton

A custom button widget that provides a 3D effect with shadow and elevation.

### Usage

```dart
ThreeDButton(
  color: Colors.teal,
  onPressed: () {
    // Action
  },
  child: Text('Click Me'),
)
```

### Properties

- `child`: The widget to display inside the button.
- `onPressed`: Callback when the button is tapped.
- `color`: The background color of the button (default: teal).
- `height`: Height of the button (default: 50).
- `width`: Width of the button (default: infinity).
- `isFloating`: Whether the button should animate continuously (default: false).

### Interactions

- **Press**: Scales down slightly and reduces shadow to simulate depression. Triggers `HapticFeedback.mediumImpact()`.
- **Release**: Returns to original state.

## DoseCard

A specialized card for displaying medication dosage information on the Home Screen.

### Usage

Used internally in `HomeScreen`.

### Interactions

- **Tap Icon**: Opens medication details dialog.
- **Swipe**: Not swipeable itself, but contains action buttons.
- **Actions**:
  - **Take**: Marks dose as taken. `HapticFeedback.lightImpact()`.
  - **Skip**: Opens skip options.
