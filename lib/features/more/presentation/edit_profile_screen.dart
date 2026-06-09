import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/profile_avatar_section.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/username_form_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _bioCtrl;

  String? _originalUsername;

  UsernameState _usernameState = UsernameState.idle;
  List<String> _usernameSuggestions = [];
  Timer? _usernameDebounce;

  bool _isRefreshing = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  File? _pickedAvatarFile;
  String? _uploadedAvatarUrl;
  String? _saveError;

  // Captured before refreshUser() runs so we can detect an avatar change
  // when the listener fires (at that point `previous` is the loading state).
  String? _avatarUrlAtRefreshStart;

  static const int _bioMaxLength = 100;
  static const Duration _debounceDuration = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).user;
    _originalUsername = user?.username;
    _avatarUrlAtRefreshStart = user?.avatarUrl;
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _bioCtrl = TextEditingController(text: user?.aboutMe ?? '');
    _bioCtrl.addListener(() => setState(() {}));

    // Fetch fresh user info from the API when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isRefreshing = true);
      ref.read(userProvider.notifier).refreshUser();
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _usernameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Username debounce ─────────────────────────────────────────────────────

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty || trimmed == _originalUsername) {
      setState(() {
        _usernameState = UsernameState.idle;
        _usernameSuggestions = [];
      });
      return;
    }

    setState(() {
      _usernameState = UsernameState.checking;
      _usernameSuggestions = [];
    });

    _usernameDebounce = Timer(_debounceDuration, () => _checkUsername(trimmed));
  }

  Future<void> _checkUsername(String username) async {
    if (!mounted) return;
    setState(() => _usernameState = UsernameState.checking);

    final result = await ref
        .read(userProvider.notifier)
        .updateUsername(username);

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _usernameState = UsernameState.error;
        _usernameSuggestions = [];
      });
      return;
    }

    if (result.isAvailable) {
      _originalUsername = result.updatedUsername;
      setState(() {
        _usernameState = UsernameState.available;
        _usernameSuggestions = [];
      });
    } else {
      setState(() {
        _usernameState = UsernameState.conflict;
        _usernameSuggestions = result.suggestions;
      });
    }
  }

  void _applySuggestion(String suggestion) {
    _usernameDebounce?.cancel();
    _usernameCtrl.text = suggestion;
    _usernameCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _checkUsername(suggestion);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    // If a username check is pending, wait for it first.
    if (_usernameState == UsernameState.checking) return;

    // Block save if username has a conflict.
    if (_usernameState == UsernameState.conflict) return;

    // If the username debounce hasn't fired yet, run it synchronously.
    final pendingUsername = _usernameCtrl.text.trim();
    if (_usernameDebounce?.isActive == true &&
        pendingUsername != _originalUsername &&
        pendingUsername.isNotEmpty) {
      _usernameDebounce!.cancel();
      await _checkUsername(pendingUsername);
      if (!mounted) return;
      if (_usernameState == UsernameState.conflict ||
          _usernameState == UsernameState.error) {
        return;
      }
    }

    setState(() {
      _saveError = null;
      _isSaving = true;
    });

    // Use the newly uploaded URL if available, otherwise preserve the existing
    // one so the backend doesn't wipe the avatar on a plain profile save.
    final existingAvatarUrl = ref.read(userProvider).user?.avatarUrl;
    final avatarUrlToSend = _uploadedAvatarUrl ?? existingAvatarUrl;

    final error = await ref
        .read(userProvider.notifier)
        .saveProfile(
          firstName:
              _firstNameCtrl.text.trim().isEmpty
                  ? null
                  : _firstNameCtrl.text.trim(),
          lastName:
              _lastNameCtrl.text.trim().isEmpty
                  ? null
                  : _lastNameCtrl.text.trim(),
          aboutMe: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
          avatarUrl: avatarUrlToSend,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      setState(() => _saveError = error);
      return;
    }

    // Refresh user data in the background so me_screen immediately shows the
    // latest avatar and profile fields from the server (the POST /users/info
    // response may omit avatar_url, which would otherwise wipe it from state).
    unawaited(ref.read(userProvider.notifier).refreshUser());

    Navigator.of(context).pop();
  }

  // ── Avatar picker + upload ────────────────────────────────────────────────

  static const int _maxAvatarBytes = 1024 * 1024; // 1 MB — matches server limit

  /// Returns a new [File] whose pixels are physically rotated to match the
  /// EXIF orientation and whose EXIF orientation tag is stripped/set to 1.
  ///
  /// This ensures the file stored on S3 always has correct upright pixels,
  /// regardless of which iOS version or image renderer fetches it later.
  Future<File> _normalizeOrientation(String sourcePath) async {
    final tmpDir = await getTemporaryDirectory();
    final destPath =
        '${tmpDir.path}/avatar_normalized_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      destPath,
      quality: 90,
      autoCorrectionAngle: true,
    );
    return result != null ? File(result.path) : File(sourcePath);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? xFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (xFile == null || !mounted) return;

    // Physically bake the EXIF orientation into the pixel data before upload.
    // Without this, some iOS versions store the image with pixels in sensor
    // orientation (e.g. landscape) and only an EXIF tag to indicate rotation.
    // CachedNetworkImage and other renderers handle that tag inconsistently,
    // causing the avatar to appear rotated on a subset of devices.
    final file = await _normalizeOrientation(xFile.path);

    // Guard against files that are still over the server limit even after
    // picker compression. Skips the network call entirely.
    final fileSize = await file.length();
    if (fileSize > _maxAvatarBytes) {
      _showAvatarUploadError(null);
      return;
    }

    setState(() {
      _pickedAvatarFile = file;
      _isUploadingAvatar = true;
      _saveError = null;
    });

    final result = await ref.read(userProvider.notifier).uploadAvatar(file);

    if (!mounted) return;

    if (result.error != null) {
      // Upload failed — revert the local preview and show a friendly dialog.
      setState(() {
        _isUploadingAvatar = false;
        _pickedAvatarFile = null;
      });
      _showAvatarUploadError(result.error!);
    } else {
      // Upload succeeded — evict the stale image from both the disk cache and
      // Flutter's in-memory image cache. Both must be cleared because presigned
      // S3 URLs share the same stable cache key, and the imageCache can serve
      // stale decoded pixels even after the disk entry is removed.
      final oldUrl = ref.read(userProvider).user?.avatarUrl ?? '';
      if (oldUrl.isNotEmpty) {
        _evictAvatarFromAllCaches(oldUrl);
      }

      setState(() {
        _isUploadingAvatar = false;
        _uploadedAvatarUrl = result.url;
      });
    }
  }

  /// Removes [url] from every layer of image caching so the widget always
  /// re-fetches the latest image from the server.
  ///
  /// Two separate stores must be cleared:
  /// • `flutter_cache_manager`'s disk + memory store (via [CachedNetworkImage.evictFromCache])
  /// • Flutter's decoded-pixel in-memory cache (via [ImageProvider.evict])
  ///   — this is the layer that causes stale images even after disk eviction.
  void _evictAvatarFromAllCaches(String url) {
    if (url.isEmpty) return;
    final stableKey =
        Uri.tryParse(url)?.replace(query: '', fragment: '').toString() ?? url;
    // Disk + flutter_cache_manager memory store
    unawaited(CachedNetworkImage.evictFromCache(url, cacheKey: stableKey));
    // Flutter's imageCache (decoded pixel store)
    unawaited(
      CachedNetworkImageProvider(url, cacheKey: stableKey).evict(),
    );
  }

  void _showAvatarUploadError(String? rawError) {
    // null → client-side size rejection; non-null → server error string
    final bool isTooBig =
        rawError == null ||
        rawError.contains('413') ||
        rawError.toLowerCase().contains('too large');
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Photo not uploaded'),
            content: Text(
              isTooBig
                  ? 'Image is too large. Please choose a photo under 1 MB and try again.'
                  : 'Could not upload your photo. Please try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showAvatarSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from library'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAndUploadAvatar(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAndUploadAvatar(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _showDeleteAccountDialog() {
    context.push(AppRoutes.deleteAccount);
  }

  bool get _canSave =>
      !_isRefreshing &&
      !_isSaving &&
      !_isUploadingAvatar &&
      _usernameState != UsernameState.checking &&
      _usernameState != UsernameState.conflict;

  @override
  Widget build(BuildContext context) {
    // Update text fields once the fresh API data arrives.
    ref.listen<UserState>(userProvider, (previous, next) {
      if (!_isRefreshing) return;
      if (next.isLoading) return;
      if (!mounted) return;
      final user = next.user;
      if (user != null) {
        // If the avatar URL changed, purge the old decoded image from both
        // flutter_cache_manager's disk store and Flutter's in-memory image
        // cache. Without this, the imageCache serves stale pixels even though
        // the disk cache was already evicted at upload time.
        final oldUrl = _avatarUrlAtRefreshStart ?? '';
        final newUrl = user.avatarUrl ?? '';
        if (oldUrl.isNotEmpty && oldUrl != newUrl) {
          _evictAvatarFromAllCaches(oldUrl);
        }

        _originalUsername = user.username;
        _usernameCtrl.text = user.username ?? '';
        _firstNameCtrl.text = user.firstName ?? '';
        _lastNameCtrl.text = user.lastName ?? '';
        _bioCtrl.text = user.aboutMe ?? '';
      }
      setState(() => _isRefreshing = false);
    });

    final user = ref.watch(userProvider).user;
    final avatarUrl = user?.avatarUrl ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? AppColors.grey800 : AppColors.grey300,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? AppColors.grey600 : AppColors.grey900,
        width: 1.5,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            AppAssets.arrowLeft,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit profile',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom:
            (_isRefreshing || _isSaving || _isUploadingAvatar)
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.grey600 : AppColors.grey300,
                    ),
                  ),
                )
                : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _canSave ? _onSave : null,
              style: TextButton.styleFrom(
                backgroundColor: _canSave ? Colors.black : AppColors.grey300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar ────────────────────────────────────────────────
              ProfileAvatarSection(
                avatarUrl: avatarUrl,
                isUploadingAvatar: _isUploadingAvatar,
                pickedAvatarFile: _pickedAvatarFile,
                onEditTap: _showAvatarSourceSheet,
              ),

              const SizedBox(height: 32),

              // ── Save error banner ─────────────────────────────────────
              if (_saveError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _saveError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Username ──────────────────────────────────────────────
              UsernameFormField(
                controller: _usernameCtrl,
                usernameState: _usernameState,
                usernameSuggestions: _usernameSuggestions,
                onChanged: _onUsernameChanged,
                onSuggestionTap: _applySuggestion,
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // ── First / Last Name row ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'First Name',
                        hintStyle: TextStyle(color: AppColors.grey500),
                        filled: true,
                        fillColor:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceWhite,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lastNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Last Name',
                        hintStyle: TextStyle(color: AppColors.grey500),
                        filled: true,
                        fillColor:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceWhite,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Bio ───────────────────────────────────────────────────
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: _bioMaxLength,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) {
                  return Text(
                    '$currentLength/${maxLength ?? _bioMaxLength}',
                    style: TextStyle(fontSize: 12, color: AppColors.grey600),
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Bio\nShare a little about yourself',
                  hintStyle: TextStyle(color: AppColors.grey500, height: 1.6),
                  filled: true,
                  fillColor:
                      isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceWhite,
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Delete account ────────────────────────────────────────
              InkWell(
                onTap: _showDeleteAccountDialog,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        AppAssets.trash,
                        size: 22,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Delete account',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Icon(
                        AppAssets.caretRight,
                        size: 20,
                        color: AppColors.grey600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
