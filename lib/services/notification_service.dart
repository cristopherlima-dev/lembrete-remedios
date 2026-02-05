// lib/services/notification_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (e) {
      print('Erro fuso horário: $e. Usando UTC.');
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notificação tocada: ${details.payload}');
      },
    );
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Pede permissão para mostrar notificações
      await androidPlugin.requestNotificationsPermission();

      // Pede explicitamente permissão para alarme exato
      // Isso é crucial para o Android 12+ não dar erro
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        print("Erro ao pedir permissão de alarme exato: $e");
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'medicamento_channel_v6', // Mudamos para v6 para garantir configuração limpa
      'Lembretes de Medicamentos',
      channelDescription: 'Notificações para lembrar de tomar medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      color: Colors.teal,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: '<b>$title</b>',
        htmlFormatContentTitle: true,
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now.add(const Duration(minutes: 1)))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      // VOLTAMOS AO MODO EXATO
      // Este modo garante que toca na hora certa, mas exige a permissão SCHEDULE_EXACT_ALARM
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // PRECISO
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("Agendado com PRECISÃO para: $scheduledDate");
    } catch (e) {
      print("Erro no agendamento exato: $e");
      // Se falhar (ex: permissão revogada), tentamos pedir a permissão novamente
      // ou lançamos o erro para o utilizador saber que algo está errado.
      throw Exception(
        "Erro de Permissão: O Android bloqueou o alarme exato. "
        "Verifique as configurações de 'Alarmes e Lembretes' do app.",
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
