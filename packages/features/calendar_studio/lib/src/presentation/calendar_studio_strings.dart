/// Studio's English UI strings for the tools added in the v3 redesign, kept
/// in one place so they can move to localisation later.
abstract final class StudioStrings {
  // Contextual bar.
  static const editText = 'Edit text';
  static const smallerText = 'Smaller text';
  static const largerText = 'Larger text';
  static const colour = 'Colour';
  static const accentColour = 'Accent colour';
  static const moreColours = 'More colours…';
  static const textAlignment = 'Text alignment';
  static const imageFit = 'Fit';
  static const outline = 'Outline only';
  static const daysShown = 'Days shown';
  static const gridStyle = 'Grid style';
  static const applyToAllMonths = 'Apply to all months';
  static const duplicate = 'Duplicate';
  static const delete = 'Delete';
  static const editItem = 'Edit item';
  static const moreActions = 'More actions';
  static const lock = 'Lock';
  static const unlock = 'Unlock';
  static const hide = 'Hide';
  static const show = 'Show';
  static const bringForward = 'Bring forward';
  static const sendBackward = 'Send backward';
  static const align = 'Align';
  static const alignLeft = 'Align left';
  static const alignCenter = 'Align centres';
  static const alignRight = 'Align right';
  static const alignTop = 'Align top';
  static const alignMiddle = 'Align middles';
  static const alignBottom = 'Align bottom';
  static const distributeHorizontally = 'Distribute horizontally';
  static const distributeVertically = 'Distribute vertically';
  static String selected(int count) => '$count selected';
  static String appliedToMonths(int count) =>
      count == 1 ? 'Applied to 1 more page' : 'Applied to $count more pages';
  static const alreadyMatches = 'Every month already matches';

  static String fitLabel(String fit) => switch (fit) {
    'fit' => 'Fit: whole image',
    'fill' => 'Fit: stretch',
    _ => 'Fit: crop to fill',
  };
}
