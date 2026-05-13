part of 'teacher_profile_screen.dart';

BoxDecoration _tileBoxDecoration({
  required Color tileColor,
  required Color shadowColor,
  Color? borderColor,
}) {
  return BoxDecoration(
    color: tileColor,
    borderRadius: const BorderRadius.all(Radius.circular(22)),
    border: borderColor != null ? Border.all(color: borderColor) : null,
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class _ProfileHeaderCard extends StatelessWidget {
  final String fullName;
  final String teacherCode;
  final String? imageUrl;
  final String firstLetter;
  final Color avatarBackground;
  final Color titleColor;
  final Color mutedColor;
  final Color cardColor;
  final Color shadowColor;
  final Color borderColor;
  final Color accentColor;

  const _ProfileHeaderCard({
    required this.fullName,
    required this.teacherCode,
    required this.imageUrl,
    required this.firstLetter,
    required this.avatarBackground,
    required this.titleColor,
    required this.mutedColor,
    required this.cardColor,
    required this.shadowColor,
    required this.borderColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _tileBoxDecoration(
        tileColor: cardColor,
        shadowColor: shadowColor,
        borderColor: borderColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: avatarBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 39,
              backgroundColor: avatarBackground,
              backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? NetworkImage(imageUrl!)
                  : null,
              child: (imageUrl == null || imageUrl!.isEmpty)
                  ? Text(
                      firstLetter,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.teacherAccount,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 15,
                            color: accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            teacherCode,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10, start: 2),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: color,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tileColor;
  final Color shadowColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxBackground;
  final Color borderColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.tileColor,
    required this.shadowColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxBackground,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _tileBoxDecoration(
        tileColor: tileColor,
        shadowColor: shadowColor,
        borderColor: borderColor,
      ),
      child: ListTile(
        minTileHeight: 68,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: _IconBox(
          icon: icon,
          iconColor: titleColor,
          backgroundColor: iconBoxBackground,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: mutedColor,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final bool isDarkMode;
  final Color tileColor;
  final Color shadowColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxBackground;
  final Color borderColor;
  final ValueChanged<bool> onChanged;

  const _ThemeTile({
    required this.isDarkMode,
    required this.tileColor,
    required this.shadowColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxBackground,
    required this.borderColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _tileBoxDecoration(
        tileColor: tileColor,
        shadowColor: shadowColor,
        borderColor: borderColor,
      ),
      child: ListTile(
        minTileHeight: 74,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: _IconBox(
          icon: Icons.dark_mode_outlined,
          iconColor: titleColor,
          backgroundColor: iconBoxBackground,
        ),
        title: Text(
          l10n.darkMode,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            isDarkMode ? l10n.darkActive : l10n.lightActive,
            style: TextStyle(
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: _FixedThemeSwitch(
          value: isDarkMode,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final Color tileColor;
  final Color shadowColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxBackground;
  final Color borderColor;

  const _LanguageTile({
    required this.tileColor,
    required this.shadowColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxBackground,
    required this.borderColor,
  });

  String _languageDisplayName(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context);
    switch (code) {
      case 'ar':
        return l10n.arabic;
      case 'en':
      default:
        return l10n.english;
    }
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final appState = EduLearnApp.of(context);
    final currentCode = appState.locale.languageCode;

    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final currentLocaleCode = EduLearnApp.of(sheetContext).locale.languageCode;
        final options = [
          ('en', l10n.english),
          ('ar', l10n.arabic),
        ];

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chooseLanguage,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.selectLanguage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((option) {
                  final code = option.$1;
                  final label = option.$2;
                  final selected = currentLocaleCode == code;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.24)
                            : theme.dividerColor.withValues(alpha: 0.55),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      trailing: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: mutedColor,
                            ),
                      onTap: () => Navigator.of(sheetContext).pop(code),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedCode == null || selectedCode == currentCode) return;
    await appState.changeLanguage(selectedCode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = EduLearnApp.of(context);
    final currentLanguage = _languageDisplayName(
      context,
      appState.locale.languageCode,
    );

    return Container(
      decoration: _tileBoxDecoration(
        tileColor: tileColor,
        shadowColor: shadowColor,
        borderColor: borderColor,
      ),
      child: ListTile(
        minTileHeight: 74,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: _IconBox(
          icon: Icons.language_rounded,
          iconColor: titleColor,
          backgroundColor: iconBoxBackground,
        ),
        title: Text(
          l10n.language,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            l10n.appLanguage,
            style: TextStyle(
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLanguage,
              style: TextStyle(
                color: mutedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: mutedColor,
            ),
          ],
        ),
        onTap: () => _showLanguagePicker(context),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final Color logoutBoxColor;
  final VoidCallback onTap;
  final Color titleColor;
  final Color subtitleColor;
  final Color borderColor;

  const _LogoutTile({
    required this.logoutBoxColor,
    required this.onTap,
    required this.titleColor,
    required this.subtitleColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: logoutBoxColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        minTileHeight: 74,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: Colors.redAccent,
          ),
        ),
        title: Text(
          l10n.logout,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            l10n.logoutSubtitle,
            style: TextStyle(
              color: subtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: titleColor.withValues(alpha: 0.78),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _IconBox({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 21,
      ),
    );
  }
}

class _FixedThemeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FixedThemeSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 32,
      child: FittedBox(
        fit: BoxFit.fill,
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _LogoutHintTitle extends StatelessWidget {
  const _LogoutHintTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Text(
      l10n.beforeContinue,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ) ?? const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}

class _LogoutHint extends StatelessWidget {
  final String text;

  const _LogoutHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}