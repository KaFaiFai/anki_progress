import 'package:anki_progress/models/card_log.dart';
import 'package:anki_progress/services/database/entities/review.dart';
import 'package:flutter/material.dart' hide Card;

import '../../models/date.dart';

class CardsGrid extends StatefulWidget {
  final List<CardLog> cardLogs;

  const CardsGrid({super.key, required this.cardLogs});

  @override
  State<CardsGrid> createState() => _CardsGridState();
}

class _CardsGridState extends State<CardsGrid> with SingleTickerProviderStateMixin {
  late final ScrollController scrollController;
  late final AnimationController animationController;
  late final Animation<double> animation;
  late final Duration animationDuration;
  late final Date begin;
  late final Date end;

  @override
  void initState() {
    super.initState();
    animationDuration = Duration(milliseconds: widget.cardLogs.length * 30);

    scrollController = ScrollController();
    animationController = AnimationController(duration: animationDuration, vsync: this);
    animation = Tween(begin: 0.0, end: 1.0).animate(animationController)
      ..addListener(() {
        setState(() {});
      });
    _calBeginAndEndDate();

    // resetState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      playProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      scrollDirection: Axis.vertical,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 30,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: widget.cardLogs.length,
      itemBuilder: (BuildContext context, int index) => CardProgress(cardLog: widget.cardLogs[index], date: current),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    animationController.dispose();
    super.dispose();
  }

  Date get current {
    final diff = end.difference(begin);
    return begin.add((diff * animation.value).floor());
  }

  void resetState() {
    scrollController.jumpTo(0);
    animationController.reset();
  }

  void playProgress() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: animationDuration,
      curve: Curves.linear,
    );
    animationController.forward();
  }

  void _calBeginAndEndDate() {
    Date beginDate = Date.fromTimestamp(milliseconds: widget.cardLogs.first.reviews.first.id);
    Date endDate = Date.fromTimestamp(milliseconds: widget.cardLogs.first.reviews.first.id);
    for (final cl in widget.cardLogs) {
      for (final r in cl.reviews) {
        final curDate = Date.fromTimestamp(milliseconds: r.id);
        if (curDate.difference(beginDate) < 0) {
          beginDate = curDate;
        }
        if (curDate.difference(endDate) > 0) {
          endDate = curDate;
        }
      }
    }
    begin = beginDate;
    end = endDate;
  }
}

class CardProgress extends StatelessWidget {
  final CardLog cardLog;
  final Date date;

  const CardProgress({super.key, required this.cardLog, required this.date});

  @override
  Widget build(BuildContext context) {
    final Review? review = cardLog.reviews.where((e) => Date.fromTimestamp(milliseconds: e.id) == date).firstOrNull;
    final Color color;
    if (review == null) {
      color = Colors.yellow.withAlpha(50);
    } else {
      final easeColorMap = {1: Colors.red, 2: Colors.blue, 3: Colors.green, 4: Colors.blueGrey};
      color = easeColorMap[review.ease] ?? Colors.brown.withAlpha(50);
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(cardLog.text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
