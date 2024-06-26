import 'dart:async';

import 'package:anki_visualizer/core/extensions.dart';
import 'package:anki_visualizer/models/date_range.dart';
import 'package:anki_visualizer/views/basic/padded_row.dart';
import 'package:flutter/material.dart';

import '../../core/functions.dart';
import '../../models/animation_preference.dart';
import '../../models/card_log.dart';
import '../basic/padded_column.dart';

class PreferenceForm extends StatefulWidget {
  final void Function(AnimationPreference) onPressConfirm;
  final List<CardLog> cardLogs;

  const PreferenceForm({super.key, required this.cardLogs, required this.onPressConfirm});

  @override
  State<PreferenceForm> createState() => _PreferenceFormState();
}

class _PreferenceFormState extends State<PreferenceForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController millisecondsController;
  late TextEditingController numColController;
  late Future<DateRange> cardLogsRange;
  DateRange? dateRange;

  @override
  void initState() {
    super.initState();
    final milliseconds = (widget.cardLogs.length * 8).roundTo(1000);
    const numCol = 20;
    millisecondsController = TextEditingController(text: "$milliseconds");
    numColController = TextEditingController(text: "$numCol");
    cardLogsRange = _calDateTimeRangeBoundary(widget.cardLogs);
    cardLogsRange.then((value) => dateRange = value);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: PaddedColumn(
        padding: 20,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Duration"),
              const SizedBox(width: 20),
              Flexible(
                child: SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: millisecondsController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      helperText: "How long for the entire animation",
                      helperStyle: Theme.of(context).textTheme.bodySmall,
                      suffixText: "ms",
                      suffixStyle: Theme.of(context).textTheme.displaySmall,
                    ),
                    validator: validatePositiveInteger,
                  ),
                ),
              ),
            ],
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     const Text("Number of columns"),
          //     const SizedBox(width: 20),
          //     Flexible(
          //       child: SizedBox(
          //         width: 400,
          //         child: TextFormField(
          //           controller: numColController,
          //           decoration: InputDecoration(
          //             helperText: "How many cards per row",
          //             helperStyle: Theme.of(context).textTheme.bodySmall,
          //           ),
          //           validator: validatePositiveInteger,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Date range"),
              const SizedBox(width: 20),
              Flexible(
                child: FutureBuilder(
                  future: cardLogsRange,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final range = snapshot.requireData;
                    return OutlinedButton(
                      onPressed: () => _pickDateRange(range.start.toDateTime(), range.end.toDateTime()),
                      child: PaddedRow(
                        padding: 10,
                        children: [
                          const Icon(Icons.calendar_month, size: 40),
                          Flexible(child: Text("$dateRange", overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          FractionallySizedBox(
            widthFactor: 0.5,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(textStyle: Theme.of(context).textTheme.displayLarge),
              onPressed: _submitForm,
              child: const Text("Confirm"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    millisecondsController.dispose();
    numColController.dispose();
    super.dispose();
  }

  void _pickDateRange(DateTime firstDate, DateTime lastDate) {
    showDateRangePicker(
      context: context,
      initialDateRange: dateRange?.toDateTimeRange(),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => FractionallySizedBox(
        widthFactor: 0.8,
        heightFactor: 0.8,
        child: Theme(
          data: ThemeData(
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.accent),
            // primaryColor: Colors.red,
          ),
          child: child ?? Container(),
        ),
      ),
    ).then((range) => setState(() {
          if (range != null) dateRange = DateRange.fromDateTimeRange(range);
        }));
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onPressConfirm(
        AnimationPreference(
          milliseconds: int.parse(millisecondsController.text),
          dateRange: dateRange!,
          numCol: int.parse(numColController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the information again')),
      );
    }
  }
}

Future<DateRange> _calDateTimeRangeBoundary(List<CardLog> cardLogs) {
  // this function is computationally expensive
  return Future.microtask(() {
    final sortedDates = cardLogs.map((e) => e.reviewsByDate.keys).expand((e) => e).toList();
    final start = sortedDates.first;
    final end = sortedDates.last;
    return DateRange(start: start, end: end);
  });
}
