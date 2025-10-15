# Contributing to Myanmar Calendar App

Thank you for your interest in contributing to Myanmar Calendar! 🎉

We welcome contributions from everyone, whether you're fixing a bug, adding a feature, improving documentation, or suggesting enhancements.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

---

## 📜 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please be respectful and constructive in your interactions.

### Expected Behavior

- ✅ Be respectful and inclusive
- ✅ Welcome newcomers and help them learn
- ✅ Accept constructive criticism gracefully
- ✅ Focus on what's best for the community
- ✅ Show empathy towards other contributors

### Unacceptable Behavior

- ❌ Harassment or discriminatory language
- ❌ Trolling or insulting comments
- ❌ Personal or political attacks
- ❌ Publishing others' private information
- ❌ Any unprofessional conduct

---

## 🤝 How Can I Contribute?

### Reporting Bugs

Found a bug? Help us fix it!

1. **Check existing issues** - Someone may have already reported it
2. **Use the bug report template** - Provide as much detail as possible
3. **Include steps to reproduce** - Help us recreate the issue
4. **Add screenshots/videos** - Visual aids are very helpful

**Bug Report Template:**

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Tap on '...'
3. Scroll down to '...'
4. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
Add screenshots if applicable.

**Device Information:**
- Device: [e.g. Samsung Galaxy S21]
- OS: [e.g. Android 13]
- App Version: [e.g. 1.0.0]

**Additional context**
Any other relevant information.
```

### Suggesting Features

Have an idea? We'd love to hear it!

1. **Check existing feature requests** - It might already be planned
2. **Use the feature request template**
3. **Explain the use case** - Why is this feature needed?
4. **Provide examples** - Show how it would work

**Feature Request Template:**

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Other solutions you've thought about.

**Additional context**
Mockups, examples from other apps, etc.
```

### Improving Documentation

- Fix typos or unclear explanations
- Add examples or clarifications
- Translate documentation to other languages
- Create tutorials or guides

### Writing Code

Ready to code? Here's how:

1. **Pick an issue** - Check "good first issue" or "help wanted" labels
2. **Comment on the issue** - Let others know you're working on it
3. **Fork the repository**
4. **Create a branch** - Use a descriptive name
5. **Write your code** - Follow our coding standards
6. **Test thoroughly** - Write tests for new features
7. **Submit a pull request**

---

## 🛠️ Development Setup

### Prerequisites

- **Flutter SDK**: 3.0 or higher
- **Dart SDK**: 3.0 or higher
- **IDE**: VS Code or Android Studio with Flutter plugins
- **Git**: For version control

### Initial Setup

1. **Fork and Clone**

```bash
# Fork the repository on GitHub first

# Clone your fork
git clone https://github.com/YOUR_USERNAME/mmcalendar.git myanmar_calendar_app
cd myanmar_calendar_app

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/mmcalendar.git
```

2. **Install Dependencies**

```bash
# Get all packages
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Verify Setup**

```bash
# Check Flutter installation
flutter doctor -v

# Run tests
flutter test

# Run the app
flutter run
```

### Project Structure

```
myanmar_calendar_app/
├── packages/
│   ├── core/              # Shared utilities
│   ├── data/              # Database layer
│   └── features/          # Feature modules
│       ├── calendar/
│       ├── views/
│       ├── converter/
│       └── settings/
└── apps/
    └── myanmar_calendar/  # Main app
```

### Keeping Your Fork Updated

```bash
# Fetch upstream changes
git fetch upstream

# Merge upstream changes
git checkout main
git merge upstream/main

# Push to your fork
git push origin main
```

---

## 💻 Coding Standards

### Dart Style Guide

We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart).

**Key Points:**

- Use `dartfmt` for formatting
- Follow naming conventions:
  - `UpperCamelCase` for classes
  - `lowerCamelCase` for variables and functions
  - `lowercase_with_underscores` for file names
- Maximum line length: 80 characters
- Use trailing commas for better formatting

### Flutter Best Practices

```dart
// ✅ Good: Const constructors where possible
const MyWidget({super.key});

// ✅ Good: Extract widgets for reusability
Widget _buildHeader() {
  return Container(...);
}

// ✅ Good: Use meaningful names
final completeDate = MyanmarCalendar.getCompleteDate(date);

// ❌ Bad: Magic numbers
Container(width: 100); // What does 100 represent?

// ✅ Good: Named constants
Container(width: AppDimensions.cardWidth);
```

### Architecture Guidelines

**Follow Clean Architecture:**

```
Presentation Layer (UI, BLoC)
    ↓
Domain Layer (Use Cases, Entities)
    ↓
Data Layer (Repositories, Data Sources)
```

**BLoC Pattern:**

```dart
// Events - User actions
abstract class CalendarEvent extends Equatable {}

class LoadCalendarMonth extends CalendarEvent {
  final DateTime month;
  LoadCalendarMonth(this.month);

  @override
  List<Object?> get props => [month];
}

// States - UI states
abstract class CalendarState extends Equatable {}

class CalendarLoaded extends CalendarState {
  final CalendarMonth data;
  CalendarLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

// BLoC - Business logic
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetCalendarMonth getCalendarMonth;

  CalendarBloc({required this.getCalendarMonth})
      : super(CalendarInitial()) {
    on<LoadCalendarMonth>(_onLoadMonth);
  }

  Future<void> _onLoadMonth(
    LoadCalendarMonth event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());
    // Business logic here
  }
}
```

### Code Documentation

```dart
/// Converts Western date to Myanmar date.
///
/// Takes a [DateTime] object and returns a [MyanmarDate] with
/// complete calendar information including astrological data.
///
/// Example:
/// ```dart
/// final date = DateTime(2024, 1, 1);
/// final myanmarDate = converter.toMyanmar(date);
/// print(myanmarDate.year); // 1385
/// ```
///
/// Throws [ArgumentError] if the date is before supported range.
MyanmarDate toMyanmar(DateTime date) {
  // Implementation
}
```

---

## 📝 Commit Guidelines

### Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements

**Examples:**

```bash
feat(calendar): add swipe navigation between days

Added gesture detection to allow users to swipe left/right
to navigate between days in the day details view.

Closes #123

---

fix(converter): correct date calculation for watat years

Fixed incorrect date conversion for big watat years.
The algorithm now properly handles the extra day.

Fixes #456

---

docs(readme): update installation instructions

Added prerequisites section and clarified build steps
for both Android and iOS platforms.

---

test(calendar): add unit tests for month navigation

Added comprehensive test coverage for calendar month
navigation including edge cases and error handling.
```

### Best Practices

- ✅ Write clear, concise commit messages
- ✅ Use present tense ("add feature" not "added feature")
- ✅ Keep subject line under 72 characters
- ✅ Reference issues and PRs in the footer
- ✅ Make atomic commits (one logical change per commit)

---

## 🔀 Pull Request Process

### Before Submitting

- ✅ Code follows style guidelines
- ✅ All tests pass
- ✅ New code has tests
- ✅ Documentation is updated
- ✅ Commits follow guidelines
- ✅ Branch is up-to-date with main

### Submitting a Pull Request

1. **Create a Branch**

```bash
# Feature branch
git checkout -b feat/add-swipe-navigation

# Bug fix branch
git checkout -b fix/date-conversion-bug

# Documentation branch
git checkout -b docs/update-readme
```

2. **Make Your Changes**

```bash
# Make changes
# Test thoroughly
# Commit with meaningful messages

git add .
git commit -m "feat(calendar): add swipe navigation"
```

3. **Push to Your Fork**

```bash
git push origin feat/add-swipe-navigation
```

4. **Open a Pull Request**

- Go to the original repository on GitHub
- Click "New Pull Request"
- Select your fork and branch
- Fill out the PR template
- Link related issues

**Pull Request Template:**

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Fixes #123
Closes #456

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Screenshots/Videos
[If applicable]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added and passing
- [ ] Dependent changes merged
```

### Review Process

1. **Automated Checks**
   - CI/CD tests must pass
   - Code coverage checks
   - Linting validation

2. **Code Review**
   - At least one maintainer approval required
   - Address all review comments
   - Make requested changes

3. **Merging**
   - Squash and merge for feature branches
   - Maintainers will merge approved PRs

---

## 🧪 Testing Guidelines

### Test Structure

```dart
void main() {
  group('CalendarBloc', () {
    late CalendarBloc bloc;
    late MockGetCalendarMonth mockUseCase;

    setUp(() {
      mockUseCase = MockGetCalendarMonth();
      bloc = CalendarBloc(getCalendarMonth: mockUseCase);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is CalendarInitial', () {
      expect(bloc.state, equals(CalendarInitial()));
    });

    blocTest<CalendarBloc, CalendarState>(
      'emits [CalendarLoading, CalendarLoaded] when successful',
      build: () => bloc,
      act: (bloc) => bloc.add(LoadCalendarMonth(DateTime(2024, 1, 1))),
      expect: () => [
        CalendarLoading(),
        isA<CalendarLoaded>(),
      ],
    );
  });
}
```

### Test Coverage

- Aim for **80%+ coverage**
- Must cover:
  - All use cases
  - All BLoC logic
  - Critical UI flows
  - Edge cases and errors

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/calendar/bloc/calendar_bloc_test.dart

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📚 Documentation

### Code Documentation

- Add doc comments to all public APIs
- Explain complex algorithms
- Provide usage examples
- Document parameters and return values

### README Updates

Update README.md when:
- Adding new features
- Changing setup process
- Updating dependencies
- Modifying architecture

### User Documentation

- Update user guides for new features
- Add screenshots for UI changes
- Create tutorials for complex features
- Translate to multiple languages

---

## 🏷️ Issue Labels

We use labels to organize issues:

- `bug` - Something isn't working
- `feature` - New feature request
- `documentation` - Documentation improvements
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `enhancement` - Improvement to existing feature
- `question` - Further information requested
- `wontfix` - Will not be addressed
- `duplicate` - Already reported

---

## 🎯 Priority Levels

- **P0**: Critical - Drop everything
- **P1**: High - Next release
- **P2**: Medium - Upcoming releases
- **P3**: Low - Backlog

---

## 🌍 Internationalization

### Adding Translations

1. Add entries to translation files
2. Use TranslationService
3. Test with different languages
4. Update language support documentation

```dart
// Add calendar translation
TranslationService.addTranslation("welcome", Language.english, "welcome");
TranslationService.addTranslation("welcome", Language.myanmar, "ကြိုဆိုပါတယ်");

// Use in code
Text(TranslationService.translate('welcome'));
```

In-app langauge translation

```json
// insert to packages/localizations/lib/l10n/app_en.arb
{
  "welcome": "Welcome",
  "@welcome": {
    "description": "Welcome label"
  }
}
// insert to packages/localizations/lib/l10n/app_my.arb
{
  "welcome": "ကြိုဆိုပါတယ်",
  "@welcome": {
    "description": "Welcome label"
  }
}
```

---

## 🎨 Design Contributions

### UI/UX Improvements

- Follow Material Design 3 guidelines
- Maintain consistency with existing design
- Consider accessibility
- Provide mockups or prototypes
- Test on multiple devices

### Assets

- Use vector graphics (SVG) when possible
- Optimize images for size
- Provide assets in required sizes
- Include attribution for third-party assets

---

## ❓ Questions?

- 📧 Email: kyawzayartun.contact@gmail.com
- 💬 GitHub Discussions
- 🐛 GitHub Issues
- 📱 Community Chat (if applicable)

---

## 🙏 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Acknowledged in the app (About section)

---

**Thank you for contributing to Myanmar Calendar! 🎉**

Every contribution, no matter how small, helps make this app better for everyone in the Myanmar community.

---

© 2024 Kyaw Zayar Tun. All rights reserved.
