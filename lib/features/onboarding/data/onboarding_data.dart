import 'package:flutter/material.dart';

class OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final String? hint;

  const OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    this.hint,
  });
}

const List<OnboardingPage> onboardingPages = [
  OnboardingPage(
    icon: Icons.shield,
    iconColor: Colors.white,
    iconBackground: Colors.red,
    title: 'Welcome to AlertGuard',
    description:
        'AlertGuard lets you send an instant SOS alert '
        'to your emergency contacts — with your location '
        'and photos — in seconds.',
    hint: null,
  ),

  OnboardingPage(
    icon: Icons.contacts,
    iconColor: Colors.white,
    iconBackground: Colors.blue,
    title: 'Add Emergency Contacts',
    description:
        'Add up to 3 trusted people who will receive '
        'your SOS alerts. They need to verify on Telegram '
        'before they can receive alerts.',
    hint: 'You can add contacts from the Contacts tab after setup.',
  ),

  OnboardingPage(
    icon: Icons.telegram,
    iconColor: Colors.white,
    iconBackground: Color(0xFF229ED9),
    title: 'Verify via Telegram',
    description:
        'AlertGuard sends alerts through Telegram. '
        'Each contact must click your invite link and '
        'tap Start in the bot to activate their alerts.',
    hint:
        'Share the invite link from the Contacts tab — '
        'via WhatsApp, SMS, or any messaging app.',
  ),

  OnboardingPage(
    icon: Icons.volume_up,
    iconColor: Colors.white,
    iconBackground: Colors.orange,
    title: 'Three Ways to Trigger SOS',
    description:
        'You can trigger an alert three ways:\n\n'
        '📱  Triple press the volume button\n'
        '📳  Shake your phone Three times firmly\n'
        '🔴  Tap the SOS button in the app',
    hint:
        'You have 5 seconds to cancel after triggering. '
        'Enable Silent Mode to skip the countdown.',
  ),

  OnboardingPage(
    icon: Icons.science_outlined,
    iconColor: Colors.white,
    iconBackground: Colors.green,
    title: 'Test Before You Need It',
    description:
        'Use Test Mode to do a full SOS drill without '
        'notifying your real contacts. Connect your own '
        'Telegram in Settings to receive test alerts.',
    hint:
        'We strongly recommend testing the system '
        'before relying on it in a real emergency.',
  ),

  OnboardingPage(
    icon: Icons.check_circle,
    iconColor: Colors.white,
    iconBackground: Colors.green,
    title: "You're Almost Ready",
    description:
        "After this, you'll see a setup checklist on "
        'the home screen. Complete all steps to make '
        'sure AlertGuard works when you need it most.',
    hint: null,
  ),
];
