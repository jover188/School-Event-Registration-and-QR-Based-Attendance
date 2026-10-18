import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const fontFamily = 'Inter';

  // :root (Light Mode)
  static const background = Color(0xFFFAFAFA); // --background: #fafafa
  static const foreground = Color(0xFF09090B); // --foreground: #09090b
  static const card = Color(0xFFFFFFFF); // --card: #ffffff
  static const cardForeground = Color(0xFF09090B); // --card-foreground: #09090b
  static const popover = Color(0xFFFFFFFF); // --popover: #ffffff
  static const popoverForeground =
      Color(0xFF09090B); // --popover-foreground: #09090b
  static const primary = Color(0xFF18181B); // --primary: #18181b
  static const primaryForeground =
      Color(0xFFFAFAFA); // --primary-foreground: #fafafa
  static const buttonPrimary = Color(0xFF18181B); // --primary: #18181b
  static const buttonPrimaryForeground =
      Color(0xFFFAFAFA); // --primary-foreground: #fafafa
  static const secondary = Color(0xFFF4F4F5); // --secondary: #f4f4f5
  static const secondaryForeground =
      Color(0xFF18181B); // --secondary-foreground: #18181b
  static const muted = Color(0xFFF4F4F5); // --muted: #f4f4f5
  static const mutedForeground =
      Color(0xFF52525B); // --muted-foreground: #52525b
  static const accent = Color(0xFFF4F4F5); // --accent: #f4f4f5
  static const accentForeground =
      Color(0xFF18181B); // --accent-foreground: #18181b
  static const selection = Color(0xFFF4F4F5); // --accent / --secondary: #f4f4f5
  static const destructive = Color(0xFFEF4444); // --destructive: #ef4444
  static const destructiveForeground =
      Color(0xFF09090B); // --destructive-foreground: #09090b
  static const warning = Color(0xFFF59E0B); // --warning: #f59e0b
  static const warningForeground =
      Color(0xFF09090B); // --warning-foreground: #09090b
  static const success = Color(0xFF14B8A6); // --success: #14b8a6
  static const successForeground =
      Color(0xFF042F2E); // --success-foreground: #042f2e
  static const border = Color(0xFFE4E4E7); // --border: #e4e4e7
  static const input = Color(0xFFE4E4E7); // --input: #e4e4e7
  static const ring = Color(0xFF71717A); // --ring: #71717a

  // Sidebar (Light Mode)
  static const sidebar = Color(0xFFF4F4F5); // --sidebar: #f4f4f5
  static const sidebarForeground =
      Color(0xFF09090B); // --sidebar-foreground: #09090b
  static const sidebarPrimary = Color(0xFF18181B); // --sidebar-primary: #18181b
  static const sidebarPrimaryForeground =
      Color(0xFFFAFAFA); // --sidebar-primary-foreground: #fafafa
  static const sidebarAccent = Color(0xFFF4F4F5); // --sidebar-accent: #f4f4f5
  static const sidebarAccentForeground =
      Color(0xFF18181B); // --sidebar-accent-foreground: #18181b
  static const sidebarBorder = Color(0xFFE4E4E7); // --sidebar-border: #e4e4e7
  static const sidebarRing = Color(0xFF71717A); // --sidebar-ring: #71717a

  // Complementary & Semantic Status Surfaces (Light)
  static const brandPink = Color(0xFFEC4899);
  static const brandPinkForeground = Color(0xFF09090B);
  static const brandCyan = Color(0xFF14B8A6);
  static const brandCyanForeground = Color(0xFF042F2E);
  static const successBackground = Color(0xFFF0FDFA);
  static const warningBackground = Color(0xFFFFFBEB);
  static const dangerBackground = Color(0xFFFEF2F2);
  static const information = Color(0xFF18181B);
  static const informationBackground = Color(0xFFF4F4F5);
  static const waiting = Color(0xFFD97706);
  static const waitingBackground = Color(0xFFFFFBEB);
  static const excused = Color(0xFF0D9488);
  static const excusedBackground = Color(0xFFF0FDFA);

  // .dark (Dark Mode)
  static const darkBackground = Color(0xFF09090B); // --background: #09090b
  static const darkForeground = Color(0xFFFFFFFF); // --foreground: #ffffff
  static const darkCard = Color(0xFF121214); // --card: #121214
  static const darkCardForeground =
      Color(0xFFFFFFFF); // --card-foreground: #ffffff
  static const darkPopover = Color(0xFF18181B); // --popover: #18181b
  static const darkPopoverForeground =
      Color(0xFFFFFFFF); // --popover-foreground: #ffffff
  static const darkPrimary = Color(0xFFFFFFFF); // --primary: #ffffff
  static const darkPrimaryForeground =
      Color(0xFF27272A); // --primary-foreground: #27272a
  static const darkButtonPrimary = Color(0xFFFFFFFF); // --primary: #ffffff
  static const darkButtonPrimaryForeground =
      Color(0xFF27272A); // --primary-foreground: #27272a
  static const darkSecondary = Color(0xFF27272A); // --secondary: #27272a
  static const darkSecondaryForeground =
      Color(0xFFFAFAFA); // --secondary-foreground: #fafafa
  static const darkMuted = Color(0xFF27272A); // --muted: #27272a
  static const darkMutedForeground =
      Color(0xFFA1A1AA); // --muted-foreground: #a1a1aa
  static const darkAccent = Color(0xFF27272A); // --accent: #27272a
  static const darkAccentForeground =
      Color(0xFFFAFAFA); // --accent-foreground: #fafafa
  static const darkSelection =
      Color(0xFF27272A); // --accent / --secondary: #27272a
  static const darkDestructive = Color(0xFFEF4444); // --destructive: #ef4444
  static const darkDestructiveForeground =
      Color(0xFF09090B); // --destructive-foreground: #09090b
  static const darkWarning = Color(0xFFF59E0B); // --warning: #f59e0b
  static const darkWarningForeground =
      Color(0xFF09090B); // --warning-foreground: #09090b
  static const darkSuccess = Color(0xFF14B8A6); // --success: #14b8a6
  static const darkSuccessForeground =
      Color(0xFF042F2E); // --success-foreground: #042f2e
  static const darkBorder = Color(0xFF27272A); // --border: #27272a
  static const darkInput = Color(0xFF27272A); // --input: #27272a
  static const darkRing = Color(0xFFA1A1AA); // --ring: #a1a1aa

  // Sidebar (Dark Mode)
  static const darkSidebar = Color(0xFF0F0F12); // --sidebar: #0f0f12
  static const darkSidebarForeground =
      Color(0xFFFFFFFF); // --sidebar-foreground: #ffffff
  static const darkSidebarPrimary =
      Color(0xFFFFFFFF); // --sidebar-primary: #ffffff
  static const darkSidebarPrimaryForeground =
      Color(0xFF27272A); // --sidebar-primary-foreground: #27272a
  static const darkSidebarAccent =
      Color(0xFF27272A); // --sidebar-accent: #27272a
  static const darkSidebarAccentForeground =
      Color(0xFFFAFAFA); // --sidebar-accent-foreground: #fafafa
  static const darkSidebarBorder =
      Color(0xFF27272A); // --sidebar-border: #27272a
  static const darkSidebarRing = Color(0xFFA1A1AA); // --sidebar-ring: #a1a1aa

  // Semantic Status Surfaces (Dark)
  static const darkSuccessBackground = Color(0xFF042F2E);
  static const darkWarningBackground = Color(0xFF451A03);
  static const darkDangerBackground = Color(0xFF450A0A);
  static const darkInformation = Color(0xFFFAFAFA);
  static const darkInformationBackground = Color(0xFF27272A);
  static const darkWaiting = Color(0xFFF59E0B);
  static const darkWaitingBackground = Color(0xFF451A03);
  static const darkExcused = Color(0xFF14B8A6);
  static const darkExcusedBackground = Color(0xFF042F2E);
}

@immutable
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  const AppDesignTokens({
    this.primary = AppPalette.primary,
    this.primaryForeground = AppPalette.primaryForeground,
    this.buttonPrimary = AppPalette.buttonPrimary,
    this.buttonPrimaryForeground = AppPalette.buttonPrimaryForeground,
    this.brandPink = AppPalette.brandPink,
    this.brandPinkForeground = AppPalette.brandPinkForeground,
    this.brandCyan = AppPalette.brandCyan,
    this.brandCyanForeground = AppPalette.brandCyanForeground,
    this.background = AppPalette.background,
    this.foreground = AppPalette.foreground,
    this.card = AppPalette.card,
    this.cardForeground = AppPalette.cardForeground,
    this.popover = AppPalette.popover,
    this.popoverForeground = AppPalette.popoverForeground,
    this.muted = AppPalette.muted,
    this.mutedForeground = AppPalette.mutedForeground,
    this.secondary = AppPalette.secondary,
    this.secondaryForeground = AppPalette.secondaryForeground,
    this.accent = AppPalette.accent,
    this.accentForeground = AppPalette.accentForeground,
    this.selection = AppPalette.selection,
    this.border = AppPalette.border,
    this.input = AppPalette.input,
    this.ring = AppPalette.ring,
    this.destructive = AppPalette.destructive,
    this.destructiveForeground = AppPalette.destructiveForeground,
    this.success = AppPalette.success,
    this.successForeground = AppPalette.successForeground,
    this.successBackground = AppPalette.successBackground,
    this.warning = AppPalette.warning,
    this.warningForeground = AppPalette.warningForeground,
    this.warningBackground = AppPalette.warningBackground,
    this.dangerBackground = AppPalette.dangerBackground,
    this.information = AppPalette.information,
    this.informationBackground = AppPalette.informationBackground,
    this.waiting = AppPalette.waiting,
    this.waitingBackground = AppPalette.waitingBackground,
    this.excused = AppPalette.excused,
    this.excusedBackground = AppPalette.excusedBackground,
    this.sidebar = AppPalette.sidebar,
    this.sidebarForeground = AppPalette.sidebarForeground,
    this.sidebarPrimary = AppPalette.sidebarPrimary,
    this.sidebarPrimaryForeground = AppPalette.sidebarPrimaryForeground,
    this.sidebarAccent = AppPalette.sidebarAccent,
    this.sidebarAccentForeground = AppPalette.sidebarAccentForeground,
    this.sidebarBorder = AppPalette.sidebarBorder,
    this.sidebarRing = AppPalette.sidebarRing,
  });

  static const light = AppDesignTokens();

  static const dark = AppDesignTokens(
    primary: AppPalette.darkPrimary,
    primaryForeground: AppPalette.darkPrimaryForeground,
    buttonPrimary: AppPalette.darkButtonPrimary,
    buttonPrimaryForeground: AppPalette.darkButtonPrimaryForeground,
    brandPink: AppPalette.brandPink,
    brandPinkForeground: AppPalette.darkForeground,
    brandCyan: AppPalette.brandCyan,
    brandCyanForeground: AppPalette.darkSuccessForeground,
    background: AppPalette.darkBackground,
    foreground: AppPalette.darkForeground,
    card: AppPalette.darkCard,
    cardForeground: AppPalette.darkCardForeground,
    popover: AppPalette.darkPopover,
    popoverForeground: AppPalette.darkPopoverForeground,
    muted: AppPalette.darkMuted,
    mutedForeground: AppPalette.darkMutedForeground,
    secondary: AppPalette.darkSecondary,
    secondaryForeground: AppPalette.darkSecondaryForeground,
    accent: AppPalette.darkAccent,
    accentForeground: AppPalette.darkAccentForeground,
    selection: AppPalette.darkSelection,
    border: AppPalette.darkBorder,
    input: AppPalette.darkInput,
    ring: AppPalette.darkRing,
    destructive: AppPalette.darkDestructive,
    destructiveForeground: AppPalette.darkDestructiveForeground,
    success: AppPalette.darkSuccess,
    successForeground: AppPalette.darkSuccessForeground,
    successBackground: AppPalette.darkSuccessBackground,
    warning: AppPalette.darkWarning,
    warningForeground: AppPalette.darkWarningForeground,
    warningBackground: AppPalette.darkWarningBackground,
    dangerBackground: AppPalette.darkDangerBackground,
    information: AppPalette.darkInformation,
    informationBackground: AppPalette.darkInformationBackground,
    waiting: AppPalette.darkWaiting,
    waitingBackground: AppPalette.darkWaitingBackground,
    excused: AppPalette.darkExcused,
    excusedBackground: AppPalette.darkExcusedBackground,
    sidebar: AppPalette.darkSidebar,
    sidebarForeground: AppPalette.darkSidebarForeground,
    sidebarPrimary: AppPalette.darkSidebarPrimary,
    sidebarPrimaryForeground: AppPalette.darkSidebarPrimaryForeground,
    sidebarAccent: AppPalette.darkSidebarAccent,
    sidebarAccentForeground: AppPalette.darkSidebarAccentForeground,
    sidebarBorder: AppPalette.darkSidebarBorder,
    sidebarRing: AppPalette.darkSidebarRing,
  );

  final Color primary;
  final Color primaryForeground;
  final Color buttonPrimary;
  final Color buttonPrimaryForeground;
  final Color brandPink;
  final Color brandPinkForeground;
  final Color brandCyan;
  final Color brandCyanForeground;
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color muted;
  final Color mutedForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color accent;
  final Color accentForeground;
  final Color selection;
  final Color border;
  final Color input;
  final Color ring;
  final Color destructive;
  final Color destructiveForeground;
  final Color success;
  final Color successForeground;
  final Color successBackground;
  final Color warning;
  final Color warningForeground;
  final Color warningBackground;
  final Color dangerBackground;
  final Color information;
  final Color informationBackground;
  final Color waiting;
  final Color waitingBackground;
  final Color excused;
  final Color excusedBackground;
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;

  double get xs => 4;
  double get sm => 8;
  double get gap => 12;
  double get md => 16;
  double get lg => 24;
  double get xl => 32;
  double get xxl => 48;
  double get radiusControl => 8; // --radius: 0.5rem (8px)
  double get radiusCard => 8; // --radius: 0.5rem (8px)
  double get radiusOverlay => 12;
  double get radiusPill => 999;
  double get minimumTarget => 48;
  double get compactBreakpoint => 600;
  double get expandedBreakpoint => 1024;
  double get railWidth => 88;
  double get sidebarWidth => 256;
  double get contentMaxWidth => 1280;
  Color get authPage => const Color(0xFFE6E6E4);
  Color get authSurface => const Color(0xFFF6F6F4);
  Color get authDark => const Color(0xFF0A0A0A);
  Color get authDarkSelection => const Color(0x240A0A0A);
  Color get authLight => const Color(0xFFFFFFFF);
  double get authSurfaceMaxWidth => 420;
  double get authSurfaceMinHeight => 780;
  double get authSurfaceRadius => 36;
  double get authHeaderAspectRatio => 270 / 420;
  double get authLogoSize => 64;
  double get authFieldHeight => 54;
  double get authFieldRadius => 16;
  double get authButtonHeight => 58;
  TextStyle get authTitle => pageTitle.copyWith(
        fontSize: 34,
        height: 1.5,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.68,
      );
  TextStyle get authBrand => pageTitle.copyWith(
        fontSize: 20,
        height: 24 / 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      );
  TextStyle get authInputText => body.copyWith(fontSize: 15, height: 1.5);
  TextStyle get authButtonLabel => body.copyWith(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
      );
  Duration get interactionDuration => const Duration(milliseconds: 100);
  Duration get overlayDuration => const Duration(milliseconds: 180);

  TextStyle get pageTitle => TextStyle(
        fontFamily: AppPalette.fontFamily,
        fontSize: 26,
        height: 32 / 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: foreground,
      );
  TextStyle get compactPageTitle =>
      pageTitle.copyWith(fontSize: 22, height: 28 / 22);
  TextStyle get sectionTitle => TextStyle(
        fontFamily: AppPalette.fontFamily,
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: foreground,
      );
  TextStyle get cardTitle => TextStyle(
        fontFamily: AppPalette.fontFamily,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: foreground,
      );
  TextStyle get body => TextStyle(
        fontFamily: AppPalette.fontFamily,
        fontSize: 14,
        height: 20 / 14,
        color: foreground,
      );
  TextStyle get supporting => TextStyle(
        fontFamily: AppPalette.fontFamily,
        fontSize: 13,
        height: 18 / 13,
        color: mutedForeground,
      );
  TextStyle get badge => TextStyle(
        fontFamily: AppPalette.fontFamily,
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: foreground,
      );

  Color statusColor(String status) => switch (status.trim().toLowerCase()) {
        'published' ||
        'registered' ||
        'present' ||
        'active' ||
        'approved' =>
          success,
        'ongoing' || 'walk_in' || 'walk-in' => information,
        'completed' => primary,
        'late' || 'pending_approval' || 'pending' => warning,
        'waiting_list' || 'waiting' => waiting,
        'excused' => excused,
        'cancelled' ||
        'absent' ||
        'rejected' ||
        'revoked' ||
        'inactive' ||
        'suspended' =>
          destructive,
        _ => mutedForeground,
      };

  Color statusBackgroundColor(String status) =>
      switch (status.trim().toLowerCase()) {
        'published' ||
        'registered' ||
        'present' ||
        'active' ||
        'approved' =>
          successBackground,
        'ongoing' || 'walk_in' || 'walk-in' => informationBackground,
        'completed' => selection,
        'late' || 'pending_approval' || 'pending' => warningBackground,
        'waiting_list' || 'waiting' => waitingBackground,
        'excused' => excusedBackground,
        'cancelled' ||
        'absent' ||
        'rejected' ||
        'revoked' ||
        'inactive' ||
        'suspended' =>
          dangerBackground,
        _ => muted,
      };

  @override
  AppDesignTokens copyWith({
    Color? primary,
    Color? primaryForeground,
    Color? buttonPrimary,
    Color? buttonPrimaryForeground,
    Color? brandPink,
    Color? brandPinkForeground,
    Color? brandCyan,
    Color? brandCyanForeground,
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? muted,
    Color? mutedForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? accent,
    Color? accentForeground,
    Color? selection,
    Color? border,
    Color? input,
    Color? ring,
    Color? destructive,
    Color? destructiveForeground,
    Color? success,
    Color? successForeground,
    Color? successBackground,
    Color? warning,
    Color? warningForeground,
    Color? warningBackground,
    Color? dangerBackground,
    Color? information,
    Color? informationBackground,
    Color? waiting,
    Color? waitingBackground,
    Color? excused,
    Color? excusedBackground,
    Color? sidebar,
    Color? sidebarForeground,
    Color? sidebarPrimary,
    Color? sidebarPrimaryForeground,
    Color? sidebarAccent,
    Color? sidebarAccentForeground,
    Color? sidebarBorder,
    Color? sidebarRing,
  }) =>
      AppDesignTokens(
        primary: primary ?? this.primary,
        primaryForeground: primaryForeground ?? this.primaryForeground,
        buttonPrimary: buttonPrimary ?? this.buttonPrimary,
        buttonPrimaryForeground:
            buttonPrimaryForeground ?? this.buttonPrimaryForeground,
        brandPink: brandPink ?? this.brandPink,
        brandPinkForeground: brandPinkForeground ?? this.brandPinkForeground,
        brandCyan: brandCyan ?? this.brandCyan,
        brandCyanForeground: brandCyanForeground ?? this.brandCyanForeground,
        background: background ?? this.background,
        foreground: foreground ?? this.foreground,
        card: card ?? this.card,
        cardForeground: cardForeground ?? this.cardForeground,
        popover: popover ?? this.popover,
        popoverForeground: popoverForeground ?? this.popoverForeground,
        muted: muted ?? this.muted,
        mutedForeground: mutedForeground ?? this.mutedForeground,
        secondary: secondary ?? this.secondary,
        secondaryForeground: secondaryForeground ?? this.secondaryForeground,
        accent: accent ?? this.accent,
        accentForeground: accentForeground ?? this.accentForeground,
        selection: selection ?? this.selection,
        border: border ?? this.border,
        input: input ?? this.input,
        ring: ring ?? this.ring,
        destructive: destructive ?? this.destructive,
        destructiveForeground:
            destructiveForeground ?? this.destructiveForeground,
        success: success ?? this.success,
        successForeground: successForeground ?? this.successForeground,
        successBackground: successBackground ?? this.successBackground,
        warning: warning ?? this.warning,
        warningForeground: warningForeground ?? this.warningForeground,
        warningBackground: warningBackground ?? this.warningBackground,
        dangerBackground: dangerBackground ?? this.dangerBackground,
        information: information ?? this.information,
        informationBackground:
            informationBackground ?? this.informationBackground,
        waiting: waiting ?? this.waiting,
        waitingBackground: waitingBackground ?? this.waitingBackground,
        excused: excused ?? this.excused,
        excusedBackground: excusedBackground ?? this.excusedBackground,
        sidebar: sidebar ?? this.sidebar,
        sidebarForeground: sidebarForeground ?? this.sidebarForeground,
        sidebarPrimary: sidebarPrimary ?? this.sidebarPrimary,
        sidebarPrimaryForeground:
            sidebarPrimaryForeground ?? this.sidebarPrimaryForeground,
        sidebarAccent: sidebarAccent ?? this.sidebarAccent,
        sidebarAccentForeground:
            sidebarAccentForeground ?? this.sidebarAccentForeground,
        sidebarBorder: sidebarBorder ?? this.sidebarBorder,
        sidebarRing: sidebarRing ?? this.sidebarRing,
      );

  @override
  AppDesignTokens lerp(covariant AppDesignTokens? other, double t) {
    if (other == null) return this;
    return AppDesignTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t)!,
      buttonPrimary: Color.lerp(buttonPrimary, other.buttonPrimary, t)!,
      buttonPrimaryForeground: Color.lerp(
          buttonPrimaryForeground, other.buttonPrimaryForeground, t)!,
      brandPink: Color.lerp(brandPink, other.brandPink, t)!,
      brandPinkForeground:
          Color.lerp(brandPinkForeground, other.brandPinkForeground, t)!,
      brandCyan: Color.lerp(brandCyan, other.brandCyan, t)!,
      brandCyanForeground:
          Color.lerp(brandCyanForeground, other.brandCyanForeground, t)!,
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      popoverForeground:
          Color.lerp(popoverForeground, other.popoverForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground:
          Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground:
          Color.lerp(accentForeground, other.accentForeground, t)!,
      selection: Color.lerp(selection, other.selection, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground:
          Color.lerp(destructiveForeground, other.destructiveForeground, t)!,
      success: Color.lerp(success, other.success, t)!,
      successForeground:
          Color.lerp(successForeground, other.successForeground, t)!,
      successBackground:
          Color.lerp(successBackground, other.successBackground, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningForeground:
          Color.lerp(warningForeground, other.warningForeground, t)!,
      warningBackground:
          Color.lerp(warningBackground, other.warningBackground, t)!,
      dangerBackground:
          Color.lerp(dangerBackground, other.dangerBackground, t)!,
      information: Color.lerp(information, other.information, t)!,
      informationBackground:
          Color.lerp(informationBackground, other.informationBackground, t)!,
      waiting: Color.lerp(waiting, other.waiting, t)!,
      waitingBackground:
          Color.lerp(waitingBackground, other.waitingBackground, t)!,
      excused: Color.lerp(excused, other.excused, t)!,
      excusedBackground:
          Color.lerp(excusedBackground, other.excusedBackground, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarForeground:
          Color.lerp(sidebarForeground, other.sidebarForeground, t)!,
      sidebarPrimary: Color.lerp(sidebarPrimary, other.sidebarPrimary, t)!,
      sidebarPrimaryForeground: Color.lerp(
          sidebarPrimaryForeground, other.sidebarPrimaryForeground, t)!,
      sidebarAccent: Color.lerp(sidebarAccent, other.sidebarAccent, t)!,
      sidebarAccentForeground: Color.lerp(
          sidebarAccentForeground, other.sidebarAccentForeground, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      sidebarRing: Color.lerp(sidebarRing, other.sidebarRing, t)!,
    );
  }
}

extension AppDesignContext on BuildContext {
  AppDesignTokens get design =>
      Theme.of(this).extension<AppDesignTokens>() ?? AppDesignTokens.light;
}
