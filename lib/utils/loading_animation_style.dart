/// Available loading animation styles
/// Each style represents a different visual animation type
enum LoadingAnimationStyle {
  /// A pulsating dot animation (default)
  pulsatingDot,

  /// A rotating circular progress indicator
  progressiveRing,

  /// A bouncing dots animation
  bouncingBall,

  /// A rotating square animation
  twoRotatingArc,

  /// A smooth wave animation
  waveDots,

  /// A simple spinning circle
  fourRotatingDots,

  /// A throbbing circle animation
  threeArchedCircle,

  /// A hexagonal dot animation
  hexagonDots,

  /// Beat animation similar to a heartbeat
  beat,

  /// Ink drop animation
  inkDrop,

  /// Staggered dots in a grid
  staggeredDotsWave,

  /// Falling dots animation
  fallingDot,
}

/// Extension to provide display names for loading animation styles
extension LoadingAnimationStyleExtension on LoadingAnimationStyle {
  /// Human-readable display name for the animation style
  String get displayName {
    switch (this) {
      case LoadingAnimationStyle.pulsatingDot:
        return 'Pulsating Dot';
      case LoadingAnimationStyle.progressiveRing:
        return 'Progressive Ring';
      case LoadingAnimationStyle.bouncingBall:
        return 'Bouncing Ball';
      case LoadingAnimationStyle.twoRotatingArc:
        return 'Two Rotating Arc';
      case LoadingAnimationStyle.waveDots:
        return 'Wave Dots';
      case LoadingAnimationStyle.fourRotatingDots:
        return 'Four Rotating Dots';
      case LoadingAnimationStyle.threeArchedCircle:
        return 'Three Arched Circle';
      case LoadingAnimationStyle.hexagonDots:
        return 'Hexagon Dots';
      case LoadingAnimationStyle.beat:
        return 'Beat';
      case LoadingAnimationStyle.inkDrop:
        return 'Ink Drop';
      case LoadingAnimationStyle.staggeredDotsWave:
        return 'Staggered Dots Wave';
      case LoadingAnimationStyle.fallingDot:
        return 'Falling Dot';
    }
  }

  /// Description of the animation style
  String get description {
    switch (this) {
      case LoadingAnimationStyle.pulsatingDot:
        return 'A simple pulsating dot - great for minimal interfaces';
      case LoadingAnimationStyle.progressiveRing:
        return 'A rotating ring showing progress - ideal for downloads';
      case LoadingAnimationStyle.bouncingBall:
        return 'Playful bouncing ball - perfect for casual apps';
      case LoadingAnimationStyle.twoRotatingArc:
        return 'Two rotating arcs - clean and professional';
      case LoadingAnimationStyle.waveDots:
        return 'Flowing wave of dots - smooth and elegant';
      case LoadingAnimationStyle.fourRotatingDots:
        return 'Four dots rotating in formation - balanced look';
      case LoadingAnimationStyle.threeArchedCircle:
        return 'Three arched circles - sophisticated animation';
      case LoadingAnimationStyle.hexagonDots:
        return 'Hexagonal dot pattern - modern geometric style';
      case LoadingAnimationStyle.beat:
        return 'Heartbeat-like pulsing - dynamic and lively';
      case LoadingAnimationStyle.inkDrop:
        return 'Ink drop effect - creative and artistic';
      case LoadingAnimationStyle.staggeredDotsWave:
        return 'Staggered dots in wave pattern - rhythmic motion';
      case LoadingAnimationStyle.fallingDot:
        return 'Falling dot animation - gravity-inspired effect';
    }
  }
}
