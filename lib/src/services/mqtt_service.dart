import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MirrorTelemetry {
  final bool presence;
  final double distance;
  final int light;
  final String status;
  final bool led;

  MirrorTelemetry({
    required this.presence,
    required this.distance,
    required this.light,
    required this.status,
    required this.led,
  });

  factory MirrorTelemetry.fromJson(Map<String, dynamic> json) {
    return MirrorTelemetry(
      presence: json['presenca'] ?? false,
      distance: (json['distancia'] ?? -1).toDouble(),
      light: (json['luminosidade'] ?? 0).toInt(),
      status: json['status'] ?? 'aguardando',
      led: json['led'] ?? false,
    );
  }
}

class MqttService extends ChangeNotifier {
  static const String host = 'wss://broker.emqx.io:1883/mqtt';
  static const String telemetryTopic = 'velune/espelho/telemetria';
  static const String commandTopic = 'velune/espelho/comando';

  MqttBrowserClient? _client;

  MirrorTelemetry? telemetry;
  bool connected = false;
  String connectionMessage = 'Conectando ao espelho...';

  Future<void> connect() async {
    final clientId =
        'mirrify_web_${DateTime.now().millisecondsSinceEpoch}';

    final client = MqttBrowserClient(host, clientId);

    client.port = 8084;
    client.websocketProtocols = ['mqtt'];
    client.keepAlivePeriod = 30;
    client.logging(on: false);
    client.onConnected = () {
      connected = true;
      connectionMessage = 'Espelho conectado';
      notifyListeners();
    };
    client.onDisconnected = () {
      connected = false;
      connectionMessage = 'Espelho desconectado';
      notifyListeners();
    };

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    _client = client;

    try {
      await client.connect();
      if (client.connectionStatus?.state ==
          MqttConnectionState.connected) {
        connected = true;
        client.subscribe(telemetryTopic, MqttQos.atLeastOnce);

        client.updates?.listen((messages) {
          for (final message in messages) {
            final publish =
                message.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
                publish.payload.message);

            try {
              final data = jsonDecode(payload);
              telemetry = MirrorTelemetry.fromJson(data);
              notifyListeners();
            } catch (e) {
              debugPrint('Erro ao interpretar telemetria: $e');
            }
          }
        });

        connectionMessage = 'Espelho conectado';
        notifyListeners();
      }
    } catch (e) {
      connected = false;
      connectionMessage = 'Falha na conexão MQTT';
      debugPrint('MQTT: $e');
      client.disconnect();
      notifyListeners();
    }
  }

  void sendCommand(String command) {
    if (!connected || _client == null) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(command);

    _client!.publishMessage(
      commandTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void disconnect() {
    _client?.disconnect();
    connected = false;
    notifyListeners();
  }
}
