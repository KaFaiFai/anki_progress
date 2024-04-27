import 'dart:math';

import 'package:anki_progress/core/values.dart';
import 'package:anki_progress/models/animation_preference.dart';
import 'package:anki_progress/models/card_log.dart';
import 'package:anki_progress/models/date_range.dart';
import 'package:anki_progress/services/database/entities/review.dart';
import 'package:anki_progress/views/basic/padded_row.dart';
import 'package:anki_progress/views/run_with_app_container.dart';
import 'package:flutter/material.dart' hide Card;

import '../../models/date.dart';

void main() {
  final cardLogs = List.generate(
    500,
    (index) => CardLog(
      "card $index",
      List.generate(
        20,
        (_) => Review(id: index, cid: 0, ease: 0, ivl: 0, lastIvl: 0, time: 0, type: 0),
      ),
    ),
  );
  final preference = AnimationPreference(
    milliseconds: 3000,
    dateRange: DateRange(start: Date.today(), end: Date.today()),
    numCol: 10,
  );
  runWithAppContainer(CardsGrid2(cardLogs: cardLogs, preference: preference));
}

class CardsGrid2 extends StatefulWidget {
  final List<CardLog> cardLogs;
  final AnimationPreference preference;

  const CardsGrid2({super.key, required this.cardLogs, required this.preference});

  @override
  State<CardsGrid2> createState() => CardsGrid2State();
}

class CardsGrid2State extends State<CardsGrid2> with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> animation;
  late final Duration animationDuration;
  late final Date start;
  late final Date end;

  @override
  void initState() {
    super.initState();
    animationDuration = Duration(milliseconds: widget.preference.milliseconds);
    animationController = AnimationController(duration: animationDuration, vsync: this)
      ..addListener(() {
        setState(() {});
      });
    animation = Tween(begin: 0.0, end: 1.0).animate(animationController);

    start = widget.preference.dateRange.start;
    end = widget.preference.dateRange.end;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      resetState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          PaddedRow(
            padding: 10,
            children: [
              Text(currentDate.toString()),
            ],
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 50,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: widget.cardLogs.map((e) => _CardProgress(cardLog: e, date: currentDate)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Date get currentDate {
    final diff = end.difference(start);
    return start.add((diff * animation.value).floor());
  }

  void resetState() {
    animationController.reset();
  }

  void playProgress() {
    /// start scrolling downward and move date forward
    animationController.forward();
  }
}

class _CardProgress extends StatelessWidget {
  final CardLog cardLog;
  final Date date;

  const _CardProgress({super.key, required this.cardLog, required this.date});

  @override
  Widget build(BuildContext context) {
    final Review? review = cardLog.reviews.where((e) => Date.fromTimestamp(milliseconds: e.id) == date).firstOrNull;
    final Color cardColor;
    final Color textColor;
    if (review == null) {
      final prevReviews = cardLog.reviews.where((e) => Date.fromTimestamp(milliseconds: e.id) < date);
      final prevReview = prevReviews.lastOrNull;
      final datePassed = prevReview == null ? 0 : date.difference(Date.fromTimestamp(milliseconds: prevReview.id));
      final value = datePassed;
      cardColor = Colors.amber.withAlpha(min(value, 255));
      textColor = Theme.of(context).colorScheme.onBackground;
    } else {
      final easeColorMap = {1: Values.againColor, 2: Values.hardColor, 3: Values.goodColor, 4: Values.easyColor};
      cardColor = easeColorMap[review.ease] ?? Colors.brown.withAlpha(50);
      textColor = Theme.of(context).colorScheme.background;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(cardLog.text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor)),
    );
  }
}