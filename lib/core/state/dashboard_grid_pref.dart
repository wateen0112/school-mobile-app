import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared preference state for the admin "sections grid on dashboard" option.
/// Lives in core so both the settings page and the app shell can read it
/// without a feature-to-core dependency.
final ValueNotifier<bool> dashboardSectionsGrid = ValueNotifier<bool>(false);

const String _dashboardSectionsGridPrefKey = 'admin.sections_grid_on_dashboard';

Future<void> loadDashboardSectionsGridPref() async {
  final prefs = await SharedPreferences.getInstance();
  dashboardSectionsGrid.value =
      prefs.getBool(_dashboardSectionsGridPrefKey) ?? false;
}

void initDashboardSectionsGridPref(SharedPreferences prefs) {
  dashboardSectionsGrid.value = prefs.getBool(_dashboardSectionsGridPrefKey) ?? false;
}

Future<void> setDashboardSectionsGrid(bool value) async {
  dashboardSectionsGrid.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_dashboardSectionsGridPrefKey, value);
}