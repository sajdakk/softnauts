import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:softnauts/screens/activity/activity_details/activity_details_screen.dart';
import 'package:softnauts/softnauts.dart';

import 'cubit/activities_cubit.dart';

class ActivitiesBody extends StatefulWidget {
  const ActivitiesBody({
    super.key,
    required this.state,
  });

  final ActivitiesLoadedState state;

  @override
  State<ActivitiesBody> createState() => AactivitiesBodyState();
}

class AactivitiesBodyState extends State<ActivitiesBody> {
  final ScrollController _scrollController = ScrollController();

  bool _gettingMoreProducts = false;
  bool _scrollDown = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() => _onScroll(context));
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (UserScrollNotification notification) {
        final ScrollDirection direction = notification.direction;
        setState(() {
          if (direction == ScrollDirection.reverse) {
            _scrollDown = true;
          } else if (direction == ScrollDirection.forward) {
            _scrollDown = false;
          }
        });
        return true;
      },
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (BuildContext _, int index) => _activitiesCardBuilder(index, context),
        itemCount: widget.state.activitiesList.length,
        separatorBuilder: (BuildContext _, int __) => const Divider(
          color: Colors.deepPurple,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _activitiesCardBuilder(int index, BuildContext context) {
    final Activity activities = widget.state.activitiesList[index];

    return InkWell(
      key: ValueKey<String>('${activities.id}+ ${widget.state.favouritesIds.contains(activities.id)}'),
      highlightColor: Colors.transparent,
      splashColor: Colors.purple.withOpacity(0.2),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ActivityDetailsScreen(
            id: activities.id,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: () => _onHeartPress(context, activities.id),
              icon: widget.state.favouritesIds.contains(activities.id)
                  ? const Icon(
                      Icons.favorite_rounded,
                      color: Colors.purple,
                    )
                  : const Icon(
                      Icons.favorite_outline_rounded,
                      color: SnColors.textColor,
                    ),
            ),
            Expanded(
              child: Text(
                activities.displayName,
                overflow: TextOverflow.ellipsis,
                style: SnTextStyles.dMSansSmall14.copyWith(
                  color: SnColors.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onHeartPress(BuildContext context, int id) {
    final ActivitiesCubit cubit = context.read();

    if (widget.state.favouritesIds.contains(id)) {
      cubit.removeActivities(id);

      return;
    }

    cubit.addActivities(id);
  }

  Future<void> _onScroll(BuildContext context) async {
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll == 0 && !_gettingMoreProducts && _scrollDown) {
      BotToast.showLoading(backgroundColor: Colors.transparent);
      _gettingMoreProducts = true;
      final ActivitiesCubit cubit = context.read();

      await Future.wait<void>(
        <Future<void>>[
          cubit.getMoreActivities(),
          Future<dynamic>.delayed(const Duration(milliseconds: 50), () {}),
        ],
      );

      BotToast.closeAllLoading();
      _gettingMoreProducts = false;
    }
  }
}
