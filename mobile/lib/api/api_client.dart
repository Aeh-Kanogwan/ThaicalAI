import 'dart:io';

import 'package:dio/dio.dart';

import '../config.dart';
import '../models/models.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Result of an auth call (register/login): token + user.
class AuthResult {
  final String token;
  final User user;
  const AuthResult({required this.token, required this.user});
}

/// Response of GET /me : user + profile + dailyGoal.
class MeResult {
  final User user;
  final Profile? profile;
  final DailyGoal? dailyGoal;
  const MeResult({required this.user, this.profile, this.dailyGoal});
}

/// Response of PUT /me/profile : profile + dailyGoal.
class ProfileResult {
  final Profile profile;
  final DailyGoal dailyGoal;
  const ProfileResult({required this.profile, required this.dailyGoal});
}

/// Typed HTTP client for the CalThai AI backend (docs/API_CONTRACT.md v1).
///
/// Handles: base URL resolution, Bearer auth interceptor, and error mapping
/// into [ApiException]. Endpoints below match the contract 1:1.
class ApiClient {
  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              contentType: Headers.jsonContentType,
              // We map non-2xx ourselves for uniform error handling.
              validateStatus: (status) => status != null && status < 500,
            )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  TokenStorage get tokenStorage => _tokenStorage;

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// POST /auth/register → 201 { token, user }
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final data = await _post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    final result = _authResultFrom(data);
    await _tokenStorage.write(result.token);
    return result;
  }

  /// POST /auth/login → 200 { token, user }
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    final result = _authResultFrom(data);
    await _tokenStorage.write(result.token);
    return result;
  }

  Future<void> logout() => _tokenStorage.clear();

  AuthResult _authResultFrom(Map<String, dynamic> data) {
    return AuthResult(
      token: data['token'] as String? ?? '',
      user: User.fromJson((data['user'] as Map).cast<String, dynamic>()),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile & goals
  // ---------------------------------------------------------------------------

  /// GET /me → { user, profile, dailyGoal }
  Future<MeResult> getMe() async {
    final data = await _get('/me');
    return MeResult(
      user: User.fromJson((data['user'] as Map).cast<String, dynamic>()),
      profile: data['profile'] != null
          ? Profile.fromJson((data['profile'] as Map).cast<String, dynamic>())
          : null,
      dailyGoal: data['dailyGoal'] != null
          ? DailyGoal.fromJson(
              (data['dailyGoal'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  /// PUT /me/profile → { profile, dailyGoal }
  Future<ProfileResult> updateProfile(Profile profile) async {
    final data = await _put('/me/profile', profile.toJson());
    return ProfileResult(
      profile: Profile.fromJson((data['profile'] as Map).cast<String, dynamic>()),
      dailyGoal: DailyGoal.fromJson(
          (data['dailyGoal'] as Map).cast<String, dynamic>()),
    );
  }

  // ---------------------------------------------------------------------------
  // Foods
  // ---------------------------------------------------------------------------

  /// GET /foods/search?q=&limit= → { items: Food[] }
  Future<List<Food>> searchFoods(String query, {int limit = 20}) async {
    final data = await _get('/foods/search', query: {
      'q': query,
      'limit': limit,
    });
    return ((data['items'] as List?) ?? const [])
        .map((e) => Food.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// GET /foods/:id → { food: Food }
  Future<Food> getFood(String id) async {
    final data = await _get('/foods/$id');
    return Food.fromJson((data['food'] as Map).cast<String, dynamic>());
  }

  // ---------------------------------------------------------------------------
  // AI Scan
  // ---------------------------------------------------------------------------

  /// POST /scan (multipart, field `image`) → ScanResult.
  /// Throws [ApiException] with isQuotaExceeded on HTTP 402.
  Future<ScanResult> scanImage(File imageFile) async {
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });
    final data = await _postRaw('/scan', form);
    return ScanResult.fromJson(data);
  }

  /// POST /scan with base64 payload (fallback if no file path, e.g. web).
  Future<ScanResult> scanBase64(String base64Image) async {
    final data = await _post('/scan', {'imageBase64': base64Image});
    return ScanResult.fromJson(data);
  }

  /// GET /scan/quota → Quota
  Future<Quota> getQuota() async {
    final data = await _get('/scan/quota');
    return Quota.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // Meal logs
  // ---------------------------------------------------------------------------

  /// POST /logs → 201 { log: MealLog }
  Future<MealLog> createLog(CreateLogRequest req) async {
    final data = await _post('/logs', req.toJson());
    return MealLog.fromJson((data['log'] as Map).cast<String, dynamic>());
  }

  /// GET /logs?date=YYYY-MM-DD → DayLog
  Future<DayLog> getDayLog(String date) async {
    final data = await _get('/logs', query: {'date': date});
    return DayLog.fromJson(data);
  }

  /// DELETE /logs/:id → 204
  Future<void> deleteLog(String id) async {
    await _delete('/logs/$id');
  }

  // ---------------------------------------------------------------------------
  // Water & exercise
  // ---------------------------------------------------------------------------

  /// POST /water → 201
  Future<void> logWater(int ml, {DateTime? loggedAt}) async {
    await _post('/water', {
      'ml': ml,
      if (loggedAt != null) 'loggedAt': loggedAt.toIso8601String(),
    });
  }

  /// GET /water?date= → { totalMl, entries[] }
  Future<int> getWaterTotal(String date) async {
    final data = await _get('/water', query: {'date': date});
    return (data['totalMl'] as num?)?.toInt() ?? 0;
  }

  /// POST /exercise → 201
  Future<void> logExercise({
    required String name,
    required int minutes,
    required int caloriesBurned,
    DateTime? loggedAt,
  }) async {
    await _post('/exercise', {
      'name': name,
      'minutes': minutes,
      'caloriesBurned': caloriesBurned,
      if (loggedAt != null) 'loggedAt': loggedAt.toIso8601String(),
    });
  }

  // ---------------------------------------------------------------------------
  // Weight tracker
  // ---------------------------------------------------------------------------

  /// POST /weight → 201
  Future<void> logWeight(double weightKg,
      {String? photoUrl, DateTime? loggedAt}) async {
    await _post('/weight', {
      'weightKg': weightKg,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (loggedAt != null) 'loggedAt': loggedAt.toIso8601String(),
    });
  }

  /// GET /weight?from=&to= → List<WeightEntry>
  Future<List<WeightEntry>> getWeightEntries({
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await _get('/weight', query: {
      if (from != null) 'from': _dateOnly(from),
      if (to != null) 'to': _dateOnly(to),
    });
    return ((data['entries'] as List?) ?? const [])
        .map((e) => WeightEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Internal HTTP helpers with uniform error mapping
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(path, data: body);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> _postRaw(String path, Object body) async {
    try {
      final res = await _dio.post(path, data: body);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.put(path, data: body);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> _delete(String path) async {
    try {
      final res = await _dio.delete(path);
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw _mapHttpError(res);
      }
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Verify 2xx, extract error envelope on 4xx, return JSON map on success.
  Map<String, dynamic> _unwrap(Response res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      final data = res.data;
      if (data is Map) return data.cast<String, dynamic>();
      return <String, dynamic>{};
    }
    throw _mapHttpError(res);
  }

  ApiException _mapHttpError(Response res) {
    final status = res.statusCode;
    final data = res.data;
    String code = 'HTTP_$status';
    String message = 'Something went wrong. Please try again.';
    if (data is Map && data['error'] is Map) {
      final err = (data['error'] as Map).cast<String, dynamic>();
      code = err['code'] as String? ?? code;
      message = err['message'] as String? ?? message;
    }
    return ApiException(statusCode: status, code: code, message: message);
  }

  ApiException _mapDioError(DioException e) {
    if (e.response != null) {
      return _mapHttpError(e.response!);
    }
    // Connectivity / timeout — used to trigger demo fallbacks in providers.
    return const ApiException(
      statusCode: null,
      code: 'NETWORK',
      message: 'Could not reach the server. Check your connection.',
    );
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
