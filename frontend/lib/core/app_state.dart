import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/messaging_models.dart';
import '../models/ai_replay_models.dart';
import '../models/nutrition_models.dart';
import '../models/operator_models.dart';
import '../models/team_model.dart';
import '../models/user_profile.dart';
import '../models/watch_models.dart';
import '../models/weight_models.dart';
import '../services/api_service.dart';
import '../services/privacy_shield_service.dart';
import '../services/watch_companion_service.dart';
import '../services/session_storage.dart';
import '../theme/app_theme.dart';

class AppState extends ChangeNotifier {
  AppState()
      : api = ApiService(baseUrl: _resolveBaseUrl()),
        storage = SessionStorage();

  final ApiService api;
  final SessionStorage storage;
  final WatchCompanionService watchCompanion = WatchCompanionService();

  String? token;
  UserProfile? user;
  TeamModel? activeTeam;
  List<AnnouncementModel> announcements = [];
  TeamTextAlertReadinessModel? textAlertReadiness;
  List<MessageThreadSummaryModel> threads = [];
  List<ParentLinkModel> parentLinks = [];
  List<SafetyAlertModel> safetyAlerts = [];
  List<WeightLogModel> weightHistory = [];
  WeightPlanModel? athleteWeightPlan;
  List<TeamWeightSnapshotModel> teamWeightDashboard = [];
  List<WeightAlertModel> weightAlerts = [];
  List<LinkedAthleteModel> linkedAthletes = [];
  LinkedAthleteModel? selectedLinkedAthlete;
  MessageThreadDetailModel? activeThread;
  List<OperatorProduct> operatorProducts = seedOperatorProducts();
  List<OperatorSubscriptionPlan> operatorSubscriptionPlans =
      seedOperatorSubscriptionPlans();
  List<OperatorVendor> operatorVendors = seedOperatorVendors();
  List<AiReplayReviewModel> replayReviews = seedAiReplayReviews();
  List<NutritionAthleteProfileModel> nutritionProfiles =
      seedNutritionAthleteProfiles();
  String? selectedReplayReviewId;
  final Map<String, WatchCompanionProfile> watchProfiles = seedWatchProfiles();
  Map<String, int> storeCart = {};
  bool isBusy = false;
  bool isReady = false;
  bool onboardingComplete = false;
  bool screenCaptureActive = false;
  String? privacyNotice;
  final PrivacyShieldService privacyShield = PrivacyShieldService();

  Future<void> _initializePrivacyShield() async {
    await privacyShield.startMonitoring(
      onScreenCaptureChanged: (active) {
        screenCaptureActive = active;
        if (active) {
          privacyNotice =
              'Screen recording detected. Sensitive conversation details are obscured when possible.';
        }
        notifyListeners();
      },
      onScreenshotDetected: () {
        privacyNotice =
            'Screenshot detected. Safety-sensitive messages may be reviewed by adults.';
        notifyListeners();
      },
    );
  }

  Future<void> bootstrap() async {
    await _initializePrivacyShield();
    token = await storage.readToken();
    onboardingComplete = await storage.readOnboardingComplete();
    if (token != null) {
      try {
        user = await api.me(token!);
        final teams = await api.myTeams(token!);
        activeTeam = teams.isNotEmpty ? teams.first : null;
        if (user != null && activeTeam != null) {
          await refreshMessagingData();
          await refreshWeightData();
        }
      } catch (_) {
        await storage.clear();
        token = null;
        user = null;
        activeTeam = null;
        announcements = [];
        textAlertReadiness = null;
        threads = [];
        parentLinks = [];
        safetyAlerts = [];
        weightHistory = [];
        athleteWeightPlan = null;
        teamWeightDashboard = [];
        weightAlerts = [];
        linkedAthletes = [];
        selectedLinkedAthlete = null;
        activeThread = null;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    isReady = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    isBusy = true;
    notifyListeners();
    try {
      token = await api.login(email: email, password: password);
      await storage.saveToken(token!);
      user = await api.me(token!);
      final teams = await api.myTeams(token!);
      activeTeam = teams.isNotEmpty ? teams.first : null;
      if (user != null && activeTeam != null) {
        await refreshMessagingData();
        await refreshWeightData();
      }
      onboardingComplete = await storage.readOnboardingComplete();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    isBusy = true;
    notifyListeners();
    try {
      await api.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      await login(email, password);
    } finally {
      if (isBusy) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<void> createTeam(Map<String, dynamic> payload) async {
    if (token == null) return;
    isBusy = true;
    notifyListeners();
    try {
      activeTeam = await api.createTeam(token: token!, payload: payload);
      user = await api.me(token!);
      await refreshMessagingData();
      await refreshWeightData();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> joinTeam(String joinCode) async {
    if (token == null) return;
    isBusy = true;
    notifyListeners();
    activeTeam =
        await api.joinTeam(token: token!, joinCode: joinCode.toUpperCase());
    user = await api.me(token!);
    await refreshMessagingData();
    await refreshWeightData();
    isBusy = false;
    notifyListeners();
  }

  Future<void> refreshTeamMembers() async {
    if (token == null || activeTeam == null) return;
    activeTeam =
        await api.fetchTeamMembers(token: token!, teamId: activeTeam!.id);
    if (canSendTeamTextAlerts) {
      textAlertReadiness = await api.teamTextAlertReadiness(
          token: token!, teamId: activeTeam!.id);
    } else {
      textAlertReadiness = null;
    }
    notifyListeners();
  }

  Future<void> approveMember(int memberId) async {
    if (token == null || activeTeam == null) return;
    isBusy = true;
    notifyListeners();
    try {
      activeTeam = await api.updateMemberStatus(
        token: token!,
        teamId: activeTeam!.id,
        memberId: memberId,
        status: 'approved',
      );
      if (canSendTeamTextAlerts) {
        textAlertReadiness = await api.teamTextAlertReadiness(
            token: token!, teamId: activeTeam!.id);
      }
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> removeMember(int memberId) async {
    if (token == null || activeTeam == null) return;
    isBusy = true;
    notifyListeners();
    try {
      activeTeam = await api.removeMember(
        token: token!,
        teamId: activeTeam!.id,
        memberId: memberId,
      );
      if (canSendTeamTextAlerts) {
        textAlertReadiness = await api.teamTextAlertReadiness(
            token: token!, teamId: activeTeam!.id);
      }
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> updateBranding(Map<String, dynamic> payload) async {
    if (token == null || activeTeam == null) return;
    isBusy = true;
    notifyListeners();
    activeTeam = await api.updateBranding(
      token: token!,
      teamId: activeTeam!.id,
      payload: payload,
    );
    isBusy = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    if (token == null) return;
    isBusy = true;
    notifyListeners();
    try {
      user = await api.updateProfile(
        token: token!,
        fullName: fullName,
        phone: phone,
      );
      if (canSendTeamTextAlerts && activeTeam != null) {
        textAlertReadiness = await api.teamTextAlertReadiness(
            token: token!, teamId: activeTeam!.id);
      }
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (token == null) return;
    isBusy = true;
    notifyListeners();
    await api.changePassword(
      token: token!,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    isBusy = false;
    notifyListeners();
  }

  Future<void> rotateJoinCode() async {
    if (token == null || activeTeam == null) return;
    isBusy = true;
    notifyListeners();
    final newCode =
        await api.rotateJoinCode(token: token!, teamId: activeTeam!.id);
    activeTeam = TeamModel(
      id: activeTeam!.id,
      name: activeTeam!.name,
      slug: activeTeam!.slug,
      joinCode: newCode,
      schoolName: activeTeam!.schoolName,
      schoolAbbreviation: activeTeam!.schoolAbbreviation,
      mascotName: activeTeam!.mascotName,
      primaryColor: activeTeam!.primaryColor,
      secondaryColor: activeTeam!.secondaryColor,
      accentColor: activeTeam!.accentColor,
      surfaceColor: activeTeam!.surfaceColor,
      logoUrl: activeTeam!.logoUrl,
      tagline: activeTeam!.tagline,
      members: activeTeam!.members,
    );
    isBusy = false;
    notifyListeners();
  }

  Future<void> uploadLogo(File file) async {
    if (token == null || activeTeam == null) return;
    isBusy = true;
    notifyListeners();
    activeTeam =
        await api.uploadLogo(token: token!, teamId: activeTeam!.id, file: file);
    isBusy = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await storage.clear();
    token = null;
    user = null;
    activeTeam = null;
    announcements = [];
    textAlertReadiness = null;
    threads = [];
    parentLinks = [];
    safetyAlerts = [];
    weightHistory = [];
    athleteWeightPlan = null;
    teamWeightDashboard = [];
    weightAlerts = [];
    linkedAthletes = [];
    selectedLinkedAthlete = null;
    activeThread = null;
    operatorProducts = seedOperatorProducts();
    operatorSubscriptionPlans = seedOperatorSubscriptionPlans();
    operatorVendors = seedOperatorVendors();
    replayReviews = seedAiReplayReviews();
    nutritionProfiles = seedNutritionAthleteProfiles();
    selectedReplayReviewId = null;
    storeCart = {};
    onboardingComplete = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    await storage.saveOnboardingComplete();
    notifyListeners();
  }

  void addOperatorProduct(OperatorProduct product) {
    operatorProducts = [...operatorProducts, product];
    notifyListeners();
  }

  void updateOperatorProduct(OperatorProduct product) {
    operatorProducts = [
      for (final item in operatorProducts)
        if (item.id == product.id) product else item,
    ];
    notifyListeners();
  }

  void addOperatorSubscriptionPlan(OperatorSubscriptionPlan plan) {
    operatorSubscriptionPlans = [...operatorSubscriptionPlans, plan];
    notifyListeners();
  }

  void updateOperatorSubscriptionPlan(OperatorSubscriptionPlan plan) {
    operatorSubscriptionPlans = [
      for (final item in operatorSubscriptionPlans)
        if (item.id == plan.id) plan else item,
    ];
    notifyListeners();
  }

  void addOperatorVendor(OperatorVendor vendor) {
    operatorVendors = [...operatorVendors, vendor];
    notifyListeners();
  }

  void updateOperatorVendor(OperatorVendor vendor) {
    operatorVendors = [
      for (final item in operatorVendors)
        if (item.id == vendor.id) vendor else item,
    ];
    notifyListeners();
  }

  AiReplayReviewModel? get selectedReplayReview {
    if (replayReviews.isEmpty) return null;
    if (selectedReplayReviewId == null) return replayReviews.first;
    for (final review in replayReviews) {
      if (review.id == selectedReplayReviewId) return review;
    }
    return replayReviews.first;
  }

  WatchCompanionProfile get activeWatchProfile {
    if (isAthlete) return watchProfiles['athlete']!;
    if (isParent) return watchProfiles['parent']!;
    return watchProfiles['coach']!;
  }

  Future<bool> requestWatchHealthPermissions() {
    return watchCompanion.requestHealthPermissions();
  }

  Future<Map<String, dynamic>> fetchWatchHealthSnapshot() {
    return watchCompanion.fetchHealthSnapshot();
  }

  Future<bool> syncWatchCompanionSnapshot() {
    final nextEvent =
        announcements.isNotEmpty ? announcements.first.title : null;
    final nextWeighIn =
        athleteWeightPlan?.targetDate.toIso8601String().split('T').first;
    return watchCompanion.syncWatchSnapshot(
      unreadMessages: threads.length,
      alerts: weightAlerts.length,
      nextEvent: nextEvent,
      nextWeighIn: nextWeighIn,
    );
  }

  void selectReplayReview(String reviewId) {
    if (selectedReplayReviewId == reviewId) return;
    selectedReplayReviewId = reviewId;
    notifyListeners();
  }

  void saveReplayReview(AiReplayReviewModel review) {
    final existingIndex =
        replayReviews.indexWhere((item) => item.id == review.id);
    if (existingIndex == -1) {
      replayReviews = [review, ...replayReviews];
    } else {
      replayReviews = [
        for (final item in replayReviews)
          if (item.id == review.id) review else item,
      ];
    }
    selectedReplayReviewId = review.id;
    notifyListeners();
  }

  void updateNutritionProfileDecision({
    required String athlete,
    required String decision,
    String? focus,
  }) {
    nutritionProfiles = [
      for (final profile in nutritionProfiles)
        if (profile.athlete == athlete)
          profile.copyWith(
            decision: decision,
            focus: focus ?? _nutritionDecisionFocus(decision, profile),
          )
        else
          profile,
    ];
    notifyListeners();
  }

  void saveNutritionProfile(NutritionAthleteProfileModel profile) {
    final existingIndex = nutritionProfiles.indexWhere(
      (item) => item.athlete.toLowerCase() == profile.athlete.toLowerCase(),
    );
    if (existingIndex == -1) {
      nutritionProfiles = [profile, ...nutritionProfiles];
    } else {
      nutritionProfiles = [
        for (final item in nutritionProfiles)
          if (item.athlete.toLowerCase() == profile.athlete.toLowerCase())
            profile
          else
            item,
      ];
    }
    notifyListeners();
  }

  String _nutritionDecisionFocus(
    String decision,
    NutritionAthleteProfileModel profile,
  ) {
    return switch (decision) {
      'Approved' =>
        'Plan approved. Keep ${profile.hydration.toLowerCase()} hydration and family follow-through stable this week.',
      'Blocked' =>
        'Cut blocked. Recheck body fat, hydration, and weigh-in timing before the plan continues.',
      _ =>
        'Coach review held. Tighten hydration, recovery, and family clarity before advancing the plan.',
    };
  }

  void addProductToCart(String productId, {int quantity = 1}) {
    if (quantity <= 0) return;
    storeCart = {
      ...storeCart,
      productId: (storeCart[productId] ?? 0) + quantity,
    };
    notifyListeners();
  }

  void updateCartQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProductFromCart(productId);
      return;
    }
    storeCart = {
      ...storeCart,
      productId: quantity,
    };
    notifyListeners();
  }

  void removeProductFromCart(String productId) {
    if (!storeCart.containsKey(productId)) return;
    final next = Map<String, int>.from(storeCart);
    next.remove(productId);
    storeCart = next;
    notifyListeners();
  }

  void clearCart() {
    if (storeCart.isEmpty) return;
    storeCart = {};
    notifyListeners();
  }

  Future<void> refreshMessagingData() async {
    if (token == null || user == null || activeTeam == null) return;
    announcements =
        await api.teamAnnouncements(token: token!, teamId: activeTeam!.id);
    if (canSendTeamTextAlerts) {
      textAlertReadiness = await api.teamTextAlertReadiness(
          token: token!, teamId: activeTeam!.id);
    } else {
      textAlertReadiness = null;
    }
    threads = await api.userThreads(token: token!, userId: user!.id);
    if (canManageMembers) {
      parentLinks =
          await api.teamParentLinks(token: token!, teamId: activeTeam!.id);
      safetyAlerts =
          await api.teamSafetyAlerts(token: token!, teamId: activeTeam!.id);
    } else {
      parentLinks = [];
      safetyAlerts = [];
    }
    notifyListeners();
  }

  Future<void> refreshAnnouncements() async {
    if (token == null || activeTeam == null) return;
    announcements =
        await api.teamAnnouncements(token: token!, teamId: activeTeam!.id);
    if (canSendTeamTextAlerts) {
      textAlertReadiness = await api.teamTextAlertReadiness(
          token: token!, teamId: activeTeam!.id);
    } else {
      textAlertReadiness = null;
    }
    notifyListeners();
  }

  Future<void> refreshThreads() async {
    if (token == null || user == null) return;
    threads = await api.userThreads(token: token!, userId: user!.id);
    notifyListeners();
  }

  Future<void> refreshSafetyAlerts() async {
    if (token == null || activeTeam == null || !canManageMembers) return;
    safetyAlerts =
        await api.teamSafetyAlerts(token: token!, teamId: activeTeam!.id);
    notifyListeners();
  }

  Future<void> refreshWeightData({
    String? group,
    int? grade,
    String? weightClass,
  }) async {
    if (token == null || user == null || activeTeam == null) return;

    if (isAthlete) {
      final bundle = await api.fetchWeightPlan(
        token: token!,
        athleteId: user!.id,
        teamId: activeTeam!.id,
      );
      athleteWeightPlan = bundle.latestPlan;
      weightHistory = bundle.recentLogs;
      weightAlerts = bundle.activeAlerts;
      teamWeightDashboard = [];
      linkedAthletes = [];
      selectedLinkedAthlete = null;
    } else if (isParent) {
      linkedAthletes = await api.fetchLinkedAthletes(token: token!);
      if (linkedAthletes.isEmpty) {
        selectedLinkedAthlete = null;
        athleteWeightPlan = null;
        weightHistory = [];
        weightAlerts = [];
      } else {
        selectedLinkedAthlete = linkedAthletes.firstWhere(
          (item) => item.athleteId == selectedLinkedAthlete?.athleteId,
          orElse: () => linkedAthletes.first,
        );
        final bundle = await api.fetchWeightPlan(
          token: token!,
          athleteId: selectedLinkedAthlete!.athleteId,
          teamId: selectedLinkedAthlete!.teamId,
        );
        athleteWeightPlan = bundle.latestPlan;
        weightHistory = bundle.recentLogs;
        weightAlerts = bundle.activeAlerts;
      }
      teamWeightDashboard = [];
    } else if (canManageWeights) {
      teamWeightDashboard = await api.fetchTeamWeightDashboard(
        token: token!,
        teamId: activeTeam!.id,
        group: group,
        grade: grade,
        weightClass: weightClass,
      );
      weightAlerts =
          await api.fetchWeightAlerts(token: token!, teamId: activeTeam!.id);
      weightHistory = [];
      athleteWeightPlan = null;
      linkedAthletes = [];
      selectedLinkedAthlete = null;
    }
    notifyListeners();
  }

  Future<void> logWeight({
    required double weight,
    double? bodyFatPercentage,
    String? hydrationNote,
    String? comments,
  }) async {
    if (token == null || user == null || activeTeam == null) return;
    isBusy = true;
    notifyListeners();
    try {
      await api.logWeight(
        token: token!,
        payload: {
          'athlete_id': user!.id,
          'team_id': activeTeam!.id,
          'logged_at': DateTime.now().toIso8601String(),
          'weight': weight,
          'body_fat_percentage': bodyFatPercentage,
          'hydration_note': hydrationNote,
          'comments': comments,
        },
      );
      await refreshWeightData();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> calculateWeightPlan({
    required double currentWeight,
    double? bodyFatPercentage,
    required double targetWeightClass,
    required DateTime targetDate,
  }) async {
    if (token == null || user == null || activeTeam == null) return;
    isBusy = true;
    notifyListeners();
    try {
      await api.calculateWeightPlan(
        token: token!,
        payload: {
          'athlete_id': user!.id,
          'team_id': activeTeam!.id,
          'current_weight': currentWeight,
          'body_fat_percentage': bodyFatPercentage,
          'target_weight_class': targetWeightClass,
          'target_date': targetDate.toIso8601String().split('T').first,
        },
      );
      await refreshWeightData();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> selectParentAthlete(int athleteId) async {
    final linked = linkedAthletes.where((item) => item.athleteId == athleteId);
    if (linked.isEmpty || token == null) return;
    selectedLinkedAthlete = linked.first;
    notifyListeners();
    final bundle = await api.fetchWeightPlan(
      token: token!,
      athleteId: selectedLinkedAthlete!.athleteId,
      teamId: selectedLinkedAthlete!.teamId,
    );
    athleteWeightPlan = bundle.latestPlan;
    weightHistory = bundle.recentLogs;
    weightAlerts = bundle.activeAlerts;
    notifyListeners();
  }

  Future<MessageThreadDetailModel> loadThread(int threadId) async {
    if (token == null) {
      throw Exception('Missing session');
    }
    activeThread = await api.fetchThread(token: token!, threadId: threadId);
    notifyListeners();
    return activeThread!;
  }

  Future<void> sendAnnouncement({
    required String title,
    required String body,
    String audienceLabel = 'team',
    bool sendTextAlert = false,
  }) async {
    if (token == null || activeTeam == null) return;
    isBusy = true;
    notifyListeners();
    try {
      await api.sendAnnouncement(
        token: token!,
        teamId: activeTeam!.id,
        title: title,
        body: body,
        audienceLabel: audienceLabel,
        sendTextAlert: sendTextAlert,
      );
      await refreshAnnouncements();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<MessageThreadDetailModel> createThread({
    required String title,
    required String threadType,
    required List<int> participantUserIds,
    String? initialMessage,
  }) async {
    if (token == null || activeTeam == null) {
      throw Exception('Missing session');
    }
    isBusy = true;
    notifyListeners();
    try {
      final thread = await api.createThread(
        token: token!,
        teamId: activeTeam!.id,
        title: title,
        threadType: threadType,
        participantUserIds: participantUserIds,
      );
      activeThread = thread;
      if (initialMessage != null && initialMessage.trim().isNotEmpty) {
        await api.sendMessage(
            token: token!, threadId: thread.id, body: initialMessage.trim());
        activeThread =
            await api.fetchThread(token: token!, threadId: thread.id);
      }
      await refreshThreads();
      return activeThread!;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<MessageThreadDetailModel> sendThreadMessage({
    required int threadId,
    required String body,
  }) async {
    if (token == null) {
      throw Exception('Missing session');
    }
    isBusy = true;
    notifyListeners();
    try {
      await api.sendMessage(token: token!, threadId: threadId, body: body);
      activeThread = await api.fetchThread(token: token!, threadId: threadId);
      await refreshThreads();
      if (canManageMembers) {
        await refreshSafetyAlerts();
      }
      return activeThread!;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> acknowledgeSafetyAlert(int alertId) async {
    if (token == null || !canManageMembers) return;
    isBusy = true;
    notifyListeners();
    try {
      final updated =
          await api.acknowledgeSafetyAlert(token: token!, alertId: alertId);
      safetyAlerts = [
        for (final alert in safetyAlerts)
          if (alert.id == updated.id) updated else alert,
      ];
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void dismissPrivacyNotice() {
    if (privacyNotice == null) return;
    privacyNotice = null;
    notifyListeners();
  }

  ThemeData get theme {
    final primary = activeTeam?.primaryColor ?? '#D62828';
    final secondary = activeTeam?.secondaryColor ?? '#F77F00';
    final accent = activeTeam?.accentColor ?? '#FCBF49';
    final surface = activeTeam?.surfaceColor ?? '#15171C';
    return AppTheme.build(
      primary: AppTheme.hex(primary),
      secondary: AppTheme.hex(secondary),
      accent: AppTheme.hex(accent),
      surface: AppTheme.hex(surface),
    );
  }

  bool get needsTeamSetup {
    if (user == null) return false;
    final staffRoles = {'coach', 'admin'};
    return activeTeam == null && staffRoles.contains(user!.role);
  }

  bool get needsJoinTeam {
    if (user == null) return false;
    final nonStaffRoles = {'assistant_coach', 'athlete', 'parent'};
    return activeTeam == null && nonStaffRoles.contains(user!.role);
  }

  bool get canManageBranding {
    if (user == null) return false;
    return {'coach', 'assistant_coach', 'admin'}.contains(user!.role);
  }

  bool get hasOperatorAccess {
    final email = user?.email.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;
    return {
      'kenny.maynard@icloud.com',
      'coach@wrestlingos.com',
    }.contains(email);
  }

  bool get canManageMembers {
    if (user == null) return false;
    return {'coach', 'assistant_coach', 'admin'}.contains(user!.role);
  }

  bool get canCreateAnnouncements => canManageMembers;
  bool get canSendTeamTextAlerts {
    if (user == null) return false;
    return {'coach', 'admin'}.contains(user!.role);
  }

  bool get canManageWeights => canManageMembers;
  bool get canManageRevenue => hasOperatorAccess;
  bool get isAthlete => user?.role == 'athlete';
  bool get isParent => user?.role == 'parent';
  int get openSafetyAlertCount =>
      safetyAlerts.where((alert) => alert.isOpen).length;
  int get storeCartItemCount =>
      storeCart.values.fold(0, (total, qty) => total + qty);

  String? get currentMembershipStatus {
    if (user == null || activeTeam == null) return null;
    for (final member in activeTeam!.members) {
      if (member.user.id == user!.id) return member.status;
    }
    return null;
  }

  bool get needsApproval {
    return currentMembershipStatus == 'pending';
  }

  bool get needsOnboarding {
    return user != null &&
        activeTeam != null &&
        !needsApproval &&
        !onboardingComplete;
  }
}

String _resolveBaseUrl() {
  const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredBaseUrl.trim().isNotEmpty) {
    return configuredBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
  }
  if (kIsWeb) {
    final currentOrigin = Uri.base;
    final host = currentOrigin.host.isEmpty ? '127.0.0.1' : currentOrigin.host;
    final isLoopbackHost = host == 'localhost' || host == '127.0.0.1';

    // Prefer same-origin for proxied or HTTPS deployments so the browser
    // doesn't block requests before they leave the page.
    if (currentOrigin.scheme == 'https' || !isLoopbackHost) {
      return currentOrigin.origin;
    }

    return 'http://$host:8000';
  }
  if (kReleaseMode) {
    return 'https://api.piniqapp.com';
  }
  return 'http://127.0.0.1:8000';
}
