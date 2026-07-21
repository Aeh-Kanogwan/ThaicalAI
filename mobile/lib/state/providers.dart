import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

/// Root providers wiring the API client into the Riverpod graph.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
