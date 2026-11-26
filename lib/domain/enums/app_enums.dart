import 'package:flutter/material.dart';

enum AuthProviderType {
  google('Google'),
  apple('Apple'),
  email('Email');

  const AuthProviderType(this.label);
  final String label;
}

enum JourneyCategory {
  dataScience('Data Science', Icons.insights_rounded),
  softwareEngineering('Software Engineering', Icons.terminal_rounded),
  cybersecurity('Cybersecurity', Icons.shield_outlined),
  productManagement('Product Management', Icons.layers_outlined),
  marketing('Marketing', Icons.campaign_outlined),
  entrepreneurship('Entrepreneurship', Icons.rocket_launch_outlined),
  personalDevelopment('Personal Development', Icons.psychology_outlined),
  languages('Languages', Icons.translate_rounded),
  fitness('Fitness', Icons.fitness_center_rounded),
  other('Other', Icons.explore_outlined);

  const JourneyCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum ResourceType {
  udemy('Udemy', Icons.ondemand_video_rounded),
  coursera('Coursera', Icons.school_outlined),
  youtube('YouTube', Icons.play_circle_outline_rounded),
  book('Book', Icons.menu_book_rounded),
  coachOrMentor('Coach or Mentor', Icons.record_voice_over_outlined),
  personalStudyPlan('Personal Study Plan', Icons.checklist_rtl_rounded),
  other('Other', Icons.link_rounded);

  const ResourceType(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum JourneyStatus {
  planned('Scheduled'),
  active('Active'),
  paused('Paused'),
  completed('Completed'),
  cancelled('Cancelled');

  const JourneyStatus(this.label);
  final String label;

  bool get isOpen =>
      this == JourneyStatus.active ||
      this == JourneyStatus.paused ||
      this == JourneyStatus.planned;
}

enum SessionStatus {
  planned('Planned'),
  inProgress('In Session'),
  completed('Completed'),
  missed('Missed'),
  suspended('Suspended');

  const SessionStatus(this.label);
  final String label;
}

enum SessionFeeling {
  difficult('Difficult', 'Showed up despite friction', Icons.terrain_rounded),
  okay('Okay', 'Steady forward step', Icons.trending_flat_rounded),
  good('Good', 'Solid, focused progress', Icons.thumb_up_off_alt_rounded),
  excellent('Excellent', 'Deep focus and clarity', Icons.bolt_rounded);

  const SessionFeeling(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
  final IconData icon;
}

enum PauseReason {
  vacation('Vacation'),
  illness('Illness'),
  familyCommitments('Family Commitments'),
  workCommitments('Work Commitments'),
  exams('Exams'),
  other('Other');

  const PauseReason(this.label);
  final String label;
}

enum WeeklyCompletionAnswer {
  yes('Yes', 'Completed all planned sessions'),
  partially('Partially', 'Completed some of my planned commitments'),
  no('No', 'Missed this week — resetting for next week');

  const WeeklyCompletionAnswer(this.label, this.subtitle);
  final String label;
  final String subtitle;
}

enum CompletionOutcome {
  yes('Yes', 'I achieved what I set out to finish'),
  partially('Partially', 'I made meaningful progress toward the goal'),
  notYet('Not Yet', 'Closing this chapter with lessons learned');

  const CompletionOutcome(this.label, this.subtitle);
  final String label;
  final String subtitle;
}

enum ReactionType {
  applause('Applause', '👏'),
  fire('Fire', '🔥'),
  strength('Strength', '💪'),
  celebration('Celebration', '🎉');

  const ReactionType(this.label, this.symbol);
  final String label;
  final String symbol;
}

enum FeedActivityType {
  sessionCompleted,
  consistencyStreak,
  weeklyCommitmentCompleted,
  progressShared,
  journeyCompleted,
}

enum LeagueTier {
  foundation('Foundation League'),
  momentum('Momentum League'),
  resolute('Resolute League'),
  vanguard('Vanguard League'),
  summit('Summit League');

  const LeagueTier(this.label);
  final String label;
}

enum QueueItemStatus {
  queued('Queued'),
  readyToStart('Ready to Start');

  const QueueItemStatus(this.label);
  final String label;
}

enum SyncState {
  synced('Synced'),
  pendingSync('Pending synchronisation'),
  offline('Offline');

  const SyncState(this.label);
  final String label;
}
