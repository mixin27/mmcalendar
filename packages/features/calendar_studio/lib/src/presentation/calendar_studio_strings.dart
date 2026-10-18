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

  // Layers.
  static const renameLayer = 'Rename layer';
  static const layerName = 'Layer name';
  static const rename = 'Rename';
  static const dragLayer = 'Drag to change the order';

  // Pages.
  static const pageActions = 'Page actions';
  static const thisPage = 'This page';
  static const duplicatePage = 'Duplicate page';
  static const moveEarlier = 'Move earlier';
  static const moveLater = 'Move later';
  static const deletePage = 'Delete page';
  static const pageDuplicated = 'Page duplicated';
  static String pageDeleted(String label) => 'Deleted $label';
  static const dragToReorder = 'Drag a page to move it';

  static String fitLabel(String fit) => switch (fit) {
    'fit' => 'Fit: whole image',
    'fill' => 'Fit: stretch',
    _ => 'Fit: crop to fill',
  };

  // Inspector, Add panel and settings.
  static const calendar = 'Calendar';
  static const weekStarts = 'Week starts';
  static const calendarLanguage = 'Language on the calendar';
  static const daysShow = 'Days show';
  static const myanmarDates = 'Myanmar dates';
  static const moonPhases = 'Moon phases';
  static const publicHolidays = 'Public holidays';
  static const astrologyDays = 'Astrology days';
  static const myEvents = 'My events';
  static const theme = 'Theme';
  static const customiseColours = 'Customise colours';
  static const fonts = 'Fonts';
  static const headings = 'Headings';
  static const body = 'Body';
  static const pageSize = 'Page size';
  static const templateOwnSize = 'This template’s own size';
  static const resizeEveryPage = 'Resize every page';
  static const resizeEveryPageHint = 'Off changes only the page you are on';
  static const printHeading = 'Print';
  static const bleed = 'Bleed';
  static const bleedHint = '3 mm extra edge for trimming';
  static const safeMargin = 'Safe margin';
  static const output = 'Output';
  static const timeZone = 'Time zone';
  static const close = 'Close';
  static const projectSettings = 'Project settings';
  static const apply = 'Apply';
  static const projectFile = 'Project file';
  static const saveProjectFile = 'Save project file';
  static const share = 'Share';
  static const saveAsTemplate = 'Save as template';
  static const back = 'Back';
  static const next = 'Next';
  static const createProject = 'Create project';
  static const a4Portrait = 'A4 portrait';
  static const a4Landscape = 'A4 landscape';
  static const a3Portrait = 'A3 portrait';
  static const square = 'Square';
  static const story916 = 'Story 9:16';
  static const oneMonth = 'One month';
  static const twelveMonths = 'Twelve months';
  static const sun = 'Sun';
  static const mon = 'Mon';
  static const photoFromYourGallery = 'Photo from your gallery';
  static const photoHint = 'Or take one with the camera';
  static const logo = 'Logo';
  static const yourBrandMark = 'Your brand mark';
  static const calendarGrid = 'Calendar grid';
  static const calendarGridHint = 'This page’s month, with Myanmar dates';
  static const eventList = 'Event list';
  static const eventListHint = 'Holidays and your events this month';
  static const holidayLegend = 'Holiday legend';
  static const legendHint = 'Explains the marks and colours';
  static const addToPage = 'Add to page';
  static const recentEmpty = 'Things you add show up here, ready to add again.';
  static const emoji = 'Emoji';
  static const emojiField = 'Type or paste any emoji';
  static const shapes = 'Shapes';
  static const decorations = 'Decorations';
  static const rectangle = 'Rectangle';
  static const rounded = 'Rounded';
  static const circle = 'Circle';
  static const oval = 'Oval';
  static const triangle = 'Triangle';
  static const diamond = 'Diamond';
  static const pentagon = 'Pentagon';
  static const hexagon = 'Hexagon';
  static const octagon = 'Octagon';
  static const star = 'Star';
  static const heart = 'Heart';
  static const arrow = 'Arrow';
  static const line = 'Line';
  static const weeks = 'Weeks';
  static const rows = 'Rows';
  static const look = 'Look';
  static const dayStyle = 'Day style';
  static const gridLines = 'Grid lines';
  static const rowHeight = 'Row height';
  static const numbers = 'Numbers';
  static const numberFont = 'Number font';
  static const numeralFamily = 'Numeral family';
  static const colours = 'Colours';
  static const title = 'Title';
  static const sampleRows = 'Sample rows when a month has no events';
  static const onePerLine = 'One per line';
  static const text = 'Text';
  static const font = 'Font';
  static const size = 'Size';
  static const shows = 'Shows';
  static const legendNote =
      'A mark only appears when the calendar shows it too.';
  static const always6 = 'Always 6';
  static const asNeeded = 'As needed';
  static const standard = 'Standard';
  static const plain = 'Plain';
  static const moon = 'Moon';
  static const none = 'None';
  static const light = 'Light';
  static const full = 'Full';
  static const boxed = 'Boxed';
  static const serif = 'Serif';
  static const sans = 'Sans';
  static const gridDataNote = 'Dates come from the app calendar';
  static const closeInspector = 'Close inspector';
  static const save = 'Save';
  static const replace = 'Replace';
  static const editImage = 'Edit image';
  static const removeBackground = 'Remove background';
  static const revertToOriginal = 'Revert to original';
  static const printQuality = 'Print quality at A4';
  static const opacity = 'Opacity';
  static const frame = 'Frame';
  static const cornerRadius = 'Corner radius';
  static const border = 'Border';
  static const borderColour = 'Border colour';
  static const crop = 'Crop';
  static const stretch = 'Stretch';
  static const typeOnThePage = 'Type on the page';
  static const suggestText = 'Suggest text';
  static const bindingNote =
      'Changes with each page’s month and the project language.';
  static const secondLine = 'Second line';
  static const subtitle = 'Subtitle';
  static const subtitleHint = 'An English line under a Myanmar title';
  static const textStyle = 'Text style';
  static const weight = 'Weight';
  static const italic = 'Italic';
  static const forLatinText = 'For Latin text';
  static const lineHeight = 'Line height';
  static const letterSpacing = 'Letter spacing';
  static const alignment = 'Alignment';
  static const textColour = 'Text colour';
  static const subtitleColour = 'Subtitle colour';
  static const subtitleSize = 'Subtitle size';
  static const shape = 'Shape';
  static const fill = 'Fill';
  static const filled = 'Filled';
  static const fillColour = 'Fill colour';
  static const outlineHeading = 'Outline';
  static const width = 'Width';
  static const outlineColour = 'Outline colour';
  static const motif = 'Motif';
  static const mainColour = 'Main colour';
  static const templateArtNote =
      'This artwork keeps the template’s own colours.';
  static const positionAndSize = 'Position and size';
  static const height = 'Height';
  static const rotation = 'Rotation';
  static const layer = 'Layer';
  static const lockLayer = 'Lock layer';
  static const visible = 'Visible';
  static const forward = 'Forward';
  static const applyLayoutAll = 'Use this size and place on every month';

  // Tabs, notes and phrases with values.
  static const content = 'Content';
  static const style = 'Style';
  static const layout = 'Layout';
  static const data = 'Data';
  static const image = 'Image';
  static const elements = 'Elements';
  static const images = 'Images';
  static const recent = 'Recent';
  static const format = 'Format';
  static const month = 'Month';
  static const startsFrom = 'Starts from';
  static const done = 'Done';
  static const previous = 'previous';
  static const nextMonth = 'next';
  static const imageRequired = 'Image required';
  static const a4PortraitHint = 'Wall or desk · 21 × 29.7 cm';
  static const a4LandscapeHint = 'Wide wall · 29.7 × 21 cm';
  static const a3PortraitHint = 'Large wall · 29.7 × 42 cm';
  static const eventsNote =
      'Events come from the calendar data. Turn My events on or off in the '
      'calendar grid’s Data tab.';
  static const pageSizeNote =
      'Elements keep their place as a share of the page, so they follow a '
      'new size. Check the pages after changing shape.';
  static const timeZoneNote =
      'A printed calendar shows whole days, which are the same in every time '
      'zone. Myanmar dates and moon days follow the Myanmar calendar.';
  static const projectFileNote =
      'A copy with its images, to move this calendar to another device or '
      'keep a backup.';
  static const months = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static String miniMonth(String which) => 'Mini month · $which';
  static String miniMonthHint(String month) => 'A small $month';
  static String customTheme(String name) => 'Custom: $name';
  static String step(int number, String name) => '$number $name';
  static String qualityGood(int dpi) => '✓ Good · $dpi dpi';
  static String qualityCheck(int dpi) => 'Check · $dpi dpi';
  static String outputDetail(String format, int dpi, int width, int height) =>
      '$format · $dpi dpi · $width × $height px';

  // Page settings.
  static const pageSettings = 'Page settings';
  static const pageColour = 'Page colour';
  static const background = 'Background';
  static const whileEditing = 'While editing';
  static const showSafeArea = 'Show safe area';
  static const showSafeAreaHint = 'Keep important content inside the guide';
  static const snapToGrid = 'Snap to grid';
  static const projectSettingsLink = 'Page size, theme and calendar';
  static String itemsDeleted(int count) => '$count items deleted';
}
