// This file is intentionally simple since ForUI's button styling system
// doesn't easily support custom text styling through button styles.
//
// For buttons with custom text sizes:
// Use FButton directly with FButtonStyle.ghost(), FButtonStyle.primary(), etc.
// and provide a custom Text widget as the child.
//
// Example:
// FButton(
//   style: FButtonStyle.ghost(),
//   onPress: onPressed,
//   child: Text('Button Text', style: theme.typography.sm),
// )
