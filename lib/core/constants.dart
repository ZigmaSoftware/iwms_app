// lib/core/constants.dart

import 'package:flutter/material.dart';

// --- COLOR AND STYLE CONSTANTS ---
const Color kPrimaryColor = Color(0xFF2E7D32); // Brand green primary
const Color kAccentColor = Color(0xFF66BB6A); // Lighter green accent
const Color kSoftTintColor = Color(0xFFE8F5E9); // Soft green background

const Color kTextColor = Color(0xFF1B5E20); // Deep green for light mode text
const Color kPlaceholderColor = Color(0xFF6B8F71); // Muted green for hints
const Color kContainerColor = kSoftTintColor; // Light container background
const Color kBorderColor = Color(0xFFCDE6D0); // Subtle green border

// --- NEW ENUM FOR FILTERING (Shared by Bloc and UI) ---
enum VehicleFilter { all, running, idle, parked, noData }

// --- REUSABLE HELPER (No longer needed when we use GoRouter) ---
// The previously defined `createSlideUpRoute` function has been removed
// as GoRouter handles transitions efficiently using the routes configuration.
