// lib/core/constants.dart

import 'package:flutter/material.dart';

// --- COLOR AND STYLE CONSTANTS ---
const Color kPrimaryColor = Color(0xFF1B5E20); // Deep green primary
const Color kAccentColor = Color(0xFF2E7D5A); // Emerald accent
const Color kSoftTintColor = Color(0xFFEAF6EB); // Soft green background

const Color kTextColor = Color(0xFF0D2F20); // Rich forest text
const Color kPlaceholderColor = Color(0xFF4E7A65); // Muted herb hints
const Color kContainerColor = kSoftTintColor; // Light container background
const Color kBorderColor = Color(0xFF9CC8AA); // Soft green border

// --- NEW ENUM FOR FILTERING (Shared by Bloc and UI) ---
enum VehicleFilter { all, running, idle, parked, noData }

// --- REUSABLE HELPER (No longer needed when we use GoRouter) ---
// The previously defined `createSlideUpRoute` function has been removed
// as GoRouter handles transitions efficiently using the routes configuration.
