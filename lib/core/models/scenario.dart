import 'package:flutter/material.dart';

class ScenarioModel {
  final String id;
  final String title;
  final String description;
  final String systemPrompt;
  final String openingLine;
  final IconData icon;

  const ScenarioModel({
    required this.id,
    required this.title,
    required this.description,
    required this.systemPrompt,
    required this.openingLine,
    required this.icon,
  });
}

const builtInScenarios = <ScenarioModel>[
  ScenarioModel(
    id: 'coffee_shop',
    title: 'Kafe Siparişi',
    description: 'A barista takes your order at a coffee shop.',
    systemPrompt: 'You are a friendly barista at a busy coffee shop in London. '
        'Stay in character. Keep the conversation realistic, polite, and short. '
        'Help the user practice ordering, asking about menu items, and small talk. '
        'Reply in English; if the learner is stuck, you may add a tiny Turkish hint in parentheses.',
    openingLine:
        'Hi there! Welcome to Brew & Co. What can I get started for you today?',
    icon: Icons.local_cafe_outlined,
  ),
  ScenarioModel(
    id: 'job_interview',
    title: 'İş Mülakatı',
    description: 'A recruiter interviews you for a junior role.',
    systemPrompt:
        'You are an HR recruiter conducting a friendly first-round interview '
        'for a junior software role. Ask one short question at a time and react '
        'naturally to the user\'s answers. Keep replies under three sentences.',
    openingLine:
        'Thanks for joining today. Could you start by telling me a little about yourself?',
    icon: Icons.work_outline,
  ),
  ScenarioModel(
    id: 'doctor',
    title: 'Doktor Randevusu',
    description: 'You visit a GP about a minor illness.',
    systemPrompt:
        'You are a calm, empathetic family doctor (GP). Ask the user about '
        'their symptoms, gently probe for details, and suggest reasonable next '
        'steps. Avoid heavy medical jargon. Keep replies short and supportive.',
    openingLine:
        'Hello, please come in and have a seat. So, what brings you in today?',
    icon: Icons.medical_services_outlined,
  ),
  ScenarioModel(
    id: 'small_talk',
    title: 'Tanışma',
    description: 'Casual small talk with a new acquaintance.',
    systemPrompt:
        'You are a friendly stranger at a coworking space lounge. Make light, '
        'curious small talk. Switch topics naturally (weather, weekend plans, '
        'work, hobbies). Keep replies short and inviting.',
    openingLine:
        'Hey! Mind if I sit here? It’s pretty crowded today, isn’t it?',
    icon: Icons.people_alt_outlined,
  ),
  ScenarioModel(
    id: 'airport',
    title: 'Havalimanı / Seyahat',
    description: 'Check-in and security at an international airport.',
    systemPrompt:
        'You are an airline check-in agent at an international airport. '
        'Help the user check in, answer baggage and boarding-time questions, '
        'and stay polite and efficient. Keep each turn under three sentences.',
    openingLine:
        'Good morning, may I see your passport and booking reference, please?',
    icon: Icons.flight_takeoff_outlined,
  ),
];
