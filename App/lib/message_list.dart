import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secure_sms/app_controller.dart';
import 'package:secure_sms/device_info.dart';
import 'package:secure_sms/main.dart';

final processedMessagesProvider =
    AutoDisposeFutureProvider<Map<MiniDeviceInfo, List<MessageInfo>>?>(
  (ref) async {
    try {
      final processedMessages = <MiniDeviceInfo, List<MessageInfo>>{};
      final permission = await Permission.sms.request();

      if (permission.isDenied) {
        if (kDebugMode) {
          print('Permission denied');
        }
        return null;
      }

      final messages = await SmsQuery().getAllSms;

      final devices = getIt.get<AppController>().devices;

      final messagesDecrypted = await compute(
        processMessages,
        (messages: messages, devices: devices),
      );

      processedMessages.addAll(messagesDecrypted);
      return processedMessages;
    } catch (e) {
      return null;
    }
  },
);

class MiniDeviceInfo extends Equatable {
  const MiniDeviceInfo({
    required this.name,
    required this.phoneNumber,
  });

  final String name;
  final String phoneNumber;

  @override
  List<Object?> get props => [name, phoneNumber];
}

class MessageInfo extends Equatable {
  const MessageInfo({
    required this.body,
    required this.dateSent,
    required this.isEncrypted,
    required this.kind,
    required this.read,
  });

  final String body;
  final bool isEncrypted;
  final DateTime dateSent;
  final SmsMessageKind kind;
  final bool read;

  @override
  List<Object?> get props => [body, dateSent, isEncrypted, kind, read];
}

Future<Map<MiniDeviceInfo, List<MessageInfo>>> processMessages(
  ({List<SmsMessage> messages, List<RemoteDevice> devices}) info,
) async {
  final messagesByDevice = <MiniDeviceInfo, List<MessageInfo>>{};

  for (final message in info.messages) {
    for (final device in info.devices) {
      if (message.address == device.phoneNumber) {
        final miniDeviceInfo = MiniDeviceInfo(
          name: device.name,
          phoneNumber: device.phoneNumber,
        );
        if (messagesByDevice[miniDeviceInfo] == null) {
          messagesByDevice[miniDeviceInfo] = [];
        }

        // try to decrypt the message
        var body = message.body ?? '';

        final decryptedMessage = await decrypt(device.secretKey, body);

        if (decryptedMessage != null) {
          body = decryptedMessage;
        }

        messagesByDevice[miniDeviceInfo]!.add(
          MessageInfo(
            body: body,
            dateSent: message.date!,
            isEncrypted: decryptedMessage != null,
            kind: message.kind!,
            read: message.read!,
          ),
        );
      }
    }
  }

  // sort the messages by date
  for (final messages in messagesByDevice.values) {
    messages.sort((a, b) => b.dateSent.compareTo(a.dateSent));
  }

  return messagesByDevice;
}

class MessageListDrawer extends StatefulWidget {
  const MessageListDrawer({super.key});

  @override
  State<MessageListDrawer> createState() => _MessageListDrawerState();
}

class _MessageListDrawerState extends State<MessageListDrawer> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  Route<Widget> _onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      MessageList.routeName || '/' => const MessageList(),
      ChatList.routeName => ChatList(
          deviceInfo:
              (settings.arguments as (MiniDeviceInfo, List<MessageInfo>)?)!.$1,
          messages:
              (settings.arguments as (MiniDeviceInfo, List<MessageInfo>)?)!.$2,
        ),
      _ => throw StateError('Unexpected route name: ${settings.name}!')
    };

    return MaterialPageRoute(
      builder: (context) {
        return page;
      },
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Navigator(
        key: _navigatorKey,
        initialRoute: MessageList.routeName,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}

class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key});

  static const routeName = '/messages';

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  late final SmsQuery query;
  var _loading = false;
  final messagesByDevice = <MiniDeviceInfo, List<MessageInfo>>{};

  Future<void> getMessages() async {
    setState(() => _loading = true);

    final messages = await ref.read(processedMessagesProvider.future);

    if (messages != null) {
      messagesByDevice.addAll(messages);
      setState(() => _loading = false);
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getMessages();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 32,
                  bottom: 16,
                  left: 16,
                ),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.sms,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mensagens',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // display the messages here in a list
              Expanded(
                child: ListView.builder(
                  itemCount: messagesByDevice.keys.length,
                  itemBuilder: (context, index) {
                    final deviceInfo = messagesByDevice.keys.elementAt(index);
                    final lastMessage = messagesByDevice[deviceInfo]!.first;

                    final nonReadMessages = messagesByDevice[deviceInfo]!.fold(
                      0,
                      (previousValue, element) =>
                          previousValue + (element.read ? 0 : 1),
                    );

                    return ListTile(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          ChatList.routeName,
                          arguments: (deviceInfo, messagesByDevice[deviceInfo]),
                        );
                      },
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: deviceInfo.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' ~ ${deviceInfo.phoneNumber}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Text(
                        lastMessage.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatDate(lastMessage.dateSent),
                            style: TextStyle(
                              fontWeight: nonReadMessages > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: nonReadMessages > 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                            ),
                          ),
                          if (nonReadMessages > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Badge(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                label: Text(nonReadMessages.toString()),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}

class ChatList extends StatelessWidget {
  const ChatList({required this.messages, required this.deviceInfo, super.key});

  final List<MessageInfo> messages;
  final MiniDeviceInfo deviceInfo;

  static const routeName = '/messages/chat';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 32,
              bottom: 4,
              left: 8,
            ),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              children: [
                BackButton(
                  color: Theme.of(context).colorScheme.onPrimary,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                // Icon(
                //   Icons.sms,
                //   color: Theme.of(context).colorScheme.onPrimaryContainer,
                // ),
                const SizedBox(width: 4),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: deviceInfo.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '  ~ ${deviceInfo.phoneNumber}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // display the messages here in a list
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.kind == SmsMessageKind.received
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: message.kind == SmsMessageKind.received ? 0 : 64,
                      right: message.kind == SmsMessageKind.received ? 64 : 0,
                    ),
                    child: Card(
                      surfaceTintColor: message.kind == SmsMessageKind.received
                          ? Theme.of(context).colorScheme.tertiary
                          : null,
                      color: message.kind == SmsMessageKind.received
                          ? null
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (message.isEncrypted) ...[
                                  Icon(
                                    Icons.lock,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.6),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    message.body,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: message.kind !=
                                              SmsMessageKind.received
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              formatDate(message.dateSent),
                              style: TextStyle(
                                fontSize: 12,
                                color: (message.kind != SmsMessageKind.received
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface)
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inHours < 1) {
    if (difference.inMinutes < 1) {
      return 'agora';
    } else {
      return '${difference.inMinutes} min';
    }
  } else if (difference.inHours < 24) {
    return DateFormat('HH:mm').format(date);
  } else if (difference.inDays < 7) {
    return DateFormat('E').format(date).toLowerCase();
  } else if (date.year == now.year) {
    return DateFormat('d MMM').format(date);
  } else {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
