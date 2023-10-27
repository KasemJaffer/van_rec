import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:importer/data/data.dart';
import 'dart:io' show Platform;

import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:van_rec/shared/extensions.dart';

final _formatFull = DateFormat("EEE, MMM d, h:mm a");
final _formatTimeOnly = DateFormat("h:mm a");

class Dialogs {
  static Widget buildDatePicker(
    BuildContext context, {
    required String name,
    required int value,
    required ValueChanged<int> onChanged,
    String Function(DateTime value)? format,
  }) {
    final inDate = DateTime.fromMicrosecondsSinceEpoch(value);
    return TextField(
      controller: TextEditingController(
        text: format?.call(inDate) ?? DateFormat("yyyy-MM-dd").format(inDate),
      ),
      decoration: const InputDecoration(
        labelText: "Value",
        contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      onTap: () async {
        final date = await showDialog<DateTime?>(
          context: context,
          builder: (context) {
            return DatePickerDialog(
              initialDate: inDate,
              firstDate: DateTime.utc(DateTime.now().year - 30),
              lastDate: DateTime.utc(DateTime.now().year + 30),
            );
          },
        );
        if (date == null) return;

        onChanged.call(date.microsecondsSinceEpoch);
      },
    );
  }

  static Widget buildDropDownList<T>({
    required String name,
    required T value,
    required Iterable<T> values,
    required ValueChanged<T?> onChanged,
    Widget Function(T value)? builder,
    Widget? suffixIcon,
    double menuMaxHeight = 400,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down_rounded),
      elevation: 16,
      onChanged: onChanged,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      menuMaxHeight: menuMaxHeight,
      alignment: Alignment.center,
      isDense: true,
      decoration: InputDecoration(
        labelText: name,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        suffixIcon: suffixIcon,
      ),
      items: values.map<DropdownMenuItem<T>>((value) {
        return DropdownMenuItem<T>(
          value: value,
          child: builder?.call(value) ?? Text(value.toString()),
        );
      }).toList(),
    );
  }

  static Widget buildDropDownSearchableList<T>(
    BuildContext context, {
    required String name,
    required T value,
    required Iterable<T> values,
    required ValueChanged<T?> onChanged,
    DropdownSearchFilterFn<T>? filter,
    DropdownSearchCompareFn<T>? compareFn,
    Widget Function(T? value)? builder,
    Widget? suffixIcon,
    double menuMaxHeight = 400,
  }) {
    return Theme(
      data: context.theme.copyWith(),
      child: DropdownSearch<T>(
        filterFn: filter,
        selectedItem: value,
        items: values.toList(),
        autoValidateMode: AutovalidateMode.onUserInteraction,
        clearButtonProps: ClearButtonProps(isVisible: value != null),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: name,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
        onChanged: onChanged,
        compareFn: compareFn,
        popupProps: PopupProps.menu(
          showSearchBox: true,
          fit: FlexFit.loose,
          searchDelay: const Duration(),
          constraints: BoxConstraints(maxHeight: menuMaxHeight),
          searchFieldProps: const TextFieldProps(
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Search",
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          menuProps: const MenuProps(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          itemBuilder: (context, item, selected) {
            return ListTile(
              selected: selected,
              title: builder?.call(item) ?? Text(item.toString()),
            );
          },
        ),
        dropdownBuilder: (c, item) {
          return builder?.call(item) ?? Text(item.toString());
        },
      ),
    );
  }

  static Future<String?> showMessageDialog(
    BuildContext context, {
    /// can be String or Widget
    required dynamic message,
    String? title,
    IconData icon = Icons.info_outline_rounded,
    bool barrierDismissible = true,
    String buttonText = 'Close',
    String? firstOption,
    String? secondOption,
  }) {
    final contentWidget = SingleChildScrollView(
      child: ListBody(
        children: <Widget>[
          const SizedBox(height: 16),
          Icon(icon, size: 64),
          const SizedBox(height: 32),
          Text(
            title ?? "Error!",
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          message is String
              ? SelectableText(message, textAlign: TextAlign.start)
              : message as Widget,
        ],
      ),
    );

    if (!kIsWeb && Platform.isIOS) {
      return cupertino.showCupertinoDialog<String>(
        barrierDismissible: barrierDismissible,
        context: context,
        builder: (BuildContext context) {
          final actions = [
            cupertino.CupertinoDialogAction(
              child: Text(buttonText),
              onPressed: () {
                Navigator.of(context).pop(buttonText);
              },
            ),
            if (firstOption != null)
              cupertino.CupertinoDialogAction(
                child: Text(firstOption),
                onPressed: () {
                  Navigator.of(context).pop(firstOption);
                },
              ),
            if (secondOption != null)
              cupertino.CupertinoDialogAction(
                child: Text(secondOption),
                onPressed: () {
                  Navigator.of(context).pop(secondOption);
                },
              ),
          ];

          return cupertino.CupertinoAlertDialog(
            content: contentWidget,
            actions: actions.length > 2 ? actions.reversed.toList() : actions,
          );
        },
      );
    }

    return showDialog<String>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return AlertDialog(
          content: contentWidget,
          actionsOverflowButtonSpacing: 0,
          actionsOverflowDirection: VerticalDirection.up,
          actions: [
            TextButton(
              child: Text(buttonText.toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop(buttonText);
              },
            ),
            if (firstOption != null)
              TextButton(
                child: Text(firstOption.toUpperCase()),
                onPressed: () {
                  Navigator.of(context).pop(firstOption);
                },
              ),
            if (secondOption != null)
              TextButton(
                child: Text(secondOption.toUpperCase()),
                onPressed: () {
                  Navigator.of(context).pop(secondOption);
                },
              ),
          ],
        );
      },
    );
  }

  static showSnackBar(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  static Future<void> showExceptionDialog(
    BuildContext context, {
    required Object e,
    required StackTrace s,
    required Function() onRetry,
    Function()? onCancel,
    String? icon,
    bool barrierDismissible = true,
  }) async {
    if (e is TimeoutException) {
      final action = await showMessageDialog(
        context,
        barrierDismissible: barrierDismissible,
        // TODO: i18n.
        title: "No Internet Connection",
        // TODO: i18n.
        message:
            "The Internet connection appears to be offline. Please try again.",
        buttonText: barrierDismissible ? "Cancel" : "Retry",
        firstOption: barrierDismissible ? "Retry" : null,
      );
      if (action == "Retry") {
        onRetry.call();
      } else {
        onCancel?.call();
      }
    } else {
      var message = e.toString();
      if (e is Exception) {
        try {
          message = (e as dynamic).message as String;
        } catch (_) {}
      }
      String? title;
      if (e is Exception) {
        try {
          title = (e as dynamic).title as String;
        } catch (_) {}
      }
      final action = await showMessageDialog(
        context,
        title: title,
        barrierDismissible: barrierDismissible,
        message: message,
        buttonText: barrierDismissible ? "OK" : "Retry",
      );
      if (action == "Retry") {
        onRetry.call();
      } else {
        onCancel?.call();
      }
    }
  }

  static Future<String?> showUnverifiedEmail(BuildContext context) {
    return Dialogs.showMessageDialog(
      context,
      title: "Unverified Email Address",
      message:
          "Your email address needs to be verified before you can login.\n\n"
          "A new verification link has been sent to your email address. Please verify your email address first and try again.",
      buttonText: "OK",
    );
  }

  static Future<String?> showLinkSent(BuildContext context,
      {required String email}) {
    return Dialogs.showMessageDialog(
      context,
      title: "Link Sent",
      message: "A code to reset your password has been sent to: $email.",
      buttonText: "OK",
    );
  }

  static Future<String?> showNotAdmin(BuildContext context) {
    return Dialogs.showMessageDialog(
      context,
      title: "Not Admin",
      message:
          "To gain access, please contact one of the administrators or me at kasem@xtrava.co",
      buttonText: "OK",
    );
  }

  static Future share(
    BuildContext context, {
    required String subLoc,
    required MyEvent? event,
    ShareTarget? target,
  }) async {
    final title = event?.title;
    final centre = event?.centerName;
    final time = event == null
        ? null
        : "${_formatFull.format(event.start)} - ${_formatTimeOnly.format(event.end)}${event.allDay ? " (all day)" : ""}";

    if (!kIsWeb) {
      Share.share(
        event == null
            ? "https://vanrec.kasem.dev$subLoc"
            : 'Check out [$title] at $centre on $time https://vanrec.kasem.dev$subLoc',
        subject: event?.title,
      );
      return;
    }

    target?.share(
      context,
      url: "https://vanrec.kasem.dev$subLoc",
      text: event == null
          ? "Check out"
          : "Check out [$title] at $centre on $time",
      subject: title,
    );
  }
}

enum ShareTarget {
  whatsapp('WhatsApp', FontAwesomeIcons.whatsapp, Color(0xFF128C7E)),
  facebook('Facebook', FontAwesomeIcons.facebook, Color(0xFF4267B2)),
  email('Email', Icons.email_rounded, Color(0xFFDB4437)),
  twitter('Twitter', FontAwesomeIcons.twitter, Color(0xFF1DA1F2)),
  copy('Copy Link', Icons.copy_rounded, null);

  final String title;
  final IconData icon;
  final Color? color;

  const ShareTarget(this.title, this.icon, this.color);

  Future<void> share(
    BuildContext context, {
    required String url,
    required String text,
    String? subject,
  }) async {
    final urlEncoded = Uri.encodeComponent(url);
    final textEncoded = Uri.encodeComponent(text);
    Uri? uri;
    switch (this) {
      case ShareTarget.whatsapp:
        uri = Uri.parse(
            'https://api.whatsapp.com/send/?text=$textEncoded%20$urlEncoded');
        break;
      case ShareTarget.facebook:
        uri = Uri.parse(
            'https://www.facebook.com/sharer.php?u=$urlEncoded&t=$textEncoded');
        break;
      case ShareTarget.email:
        uri = Uri.parse(
            'mailto:?subject=$subject&body=$textEncoded%0A$urlEncoded');
        break;
      case ShareTarget.twitter:
        uri = Uri.parse(
            'https://www.twitter.com/intent/tweet?url=$urlEncoded&text=$textEncoded');
        break;
      case ShareTarget.copy:
        Clipboard.setData(ClipboardData(text: url));
        Dialogs.showSnackBar(context, message: 'Link copied to clipboard');
    }
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
