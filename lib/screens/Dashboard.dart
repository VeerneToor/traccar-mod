import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gpspro/localization/app_localizations.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:jiffy/jiffy.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:redux/redux.dart';

import 'package:gpspro/commons/traccar_mod/lib/traccar_gennissi.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late User user;
  List<Event> eventList = [];
  Map<int, Device> devices = new HashMap();
  var deviceId = [];
  bool isLoading = true;
  bool isEventLoading = true;
  late Locale myLocale;

  int online = 0, offline = 0, unknown = 0;

  @override
  initState() {
    super.initState();
  }

  void getDevice(ViewModel viewModel) {
    if (devices.isEmpty) {
      viewModel.devices!.forEach((key, element) {
        devices.putIfAbsent(element.id!, () => element);
        deviceId.add(element.id.toString());
        if (element.status == "online") {
          online++;
        } else if (element.status == "offline") {
          offline++;
        } else if (element.status == "unknown") {
          unknown++;
        }
      });
      isLoading = false;
    }
  }

  void setLocale(locale) async {
    await Jiffy.locale(locale);
  }

  @override
  Widget build(BuildContext context) {
    myLocale = Localizations.localeOf(context);

    setLocale(myLocale.languageCode);

    return StoreConnector<AppState, ViewModel>(
        converter: (Store<AppState> store) => ViewModel.create(store),
        builder: (BuildContext context, ViewModel viewModel) =>
            loadView(viewModel));
  }

  Widget loadView(ViewModel viewModel) {
    getDevice(viewModel);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('dashboard'),
            style: TextStyle(color: CustomColor.secondaryColor)),
      ),
      body: Scaffold(
        body: Column(
          children: <Widget>[
            Padding(padding: EdgeInsets.all(5)),
            Text(AppLocalizations.of(context)!.translate("deviceStatus"),
                style: TextStyle(fontSize: 17)),
            IntrinsicHeight(
              child: chart(),
            ),
            new Divider(height: 0.1),
            Padding(padding: EdgeInsets.all(5)),
            Text(AppLocalizations.of(context)!.translate("recentEvents"),
                style: TextStyle(fontSize: 17)),
            Expanded(child: loadEvents(viewModel))
          ],
        ),
      ),
    );
  }

  Widget loadEvents(ViewModel viewModel) {
    if (viewModel.events != null) {
      return ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: viewModel.events!.length,
          itemBuilder: (context, index) {
            final eventItem = viewModel.events![index];
            String result;
            if (eventItem.attributes!.containsKey("result")) {
              result = eventItem.attributes!["result"];
            } else {
              result = "";
            }
            return new InkWell(
                onTap: () {
                  Navigator.pushNamed(context, "/notificationMap",
                      arguments: ReportEventArgument(
                          eventItem.id!,
                          eventItem.positionId!,
                          eventItem.attributes!,
                          eventItem.type!,
                          viewModel.devices![eventItem.deviceId]!.name!));
                },
                child: Card(
                  elevation: 3.0,
                  child: Column(
                    children: <Widget>[
                      eventItem.deviceId != 0
                          ? new ListTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(
                                      viewModel
                                          .devices![eventItem.deviceId]!.name!,
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.60,
                                      child: new Text(
                                          Jiffy(eventItem.serverTime).fromNow(),
                                          style: TextStyle(fontSize: 10))),
                                ],
                              ),
                              subtitle: new Text(
                                AppLocalizations.of(context)!
                                            .translate(eventItem.type!) !=
                                        null
                                    ? AppLocalizations.of(context)!
                                            .translate(eventItem.type!) +
                                        result
                                    : eventItem.type! + result,
                                style: TextStyle(fontSize: 12.0),
                                maxLines: 2,
                              ),
                            )
                          : new ListTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(
                                    AppLocalizations.of(context)!
                                        .translate(eventItem.type!),
                                    style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                  ),
                                  new Text(
                                      Jiffy(eventItem.serverTime).fromNow(),
                                      style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            )
                    ],
                  ),
                ));
          });
    } else {
      return new Container();
    }
  }

  Widget chart() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        CircularPercentIndicator(
          radius: 90.0,
          lineWidth: 13.0,
          animation: true,
          percent: 0.7,
          center: new Text(
            online.toString(),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          footer: new Text(
            AppLocalizations.of(context)!.translate("online"),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Colors.green,
        ),
        CircularPercentIndicator(
          radius: 90.0,
          lineWidth: 13.0,
          animation: true,
          percent: 0.7,
          center: new Text(
            unknown.toString(),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          footer: new Text(
            AppLocalizations.of(context)!.translate("unknown"),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Colors.yellow,
        ),
        CircularPercentIndicator(
          radius: 90.0,
          lineWidth: 13.0,
          animation: true,
          percent: 0.7,
          center: new Text(
            offline.toString(),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          footer: new Text(
            AppLocalizations.of(context)!.translate("offline"),
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Colors.red,
        ),
      ],
    );
  }
}

class Task {
  String task;
  int taskvalue;
  Color colorval;

  Task(this.task, this.taskvalue, this.colorval);
}

class ReportEventArgument {
  final int eventId;
  final int positionId;
  final Map<String, dynamic> attributes;
  final String type;
  final String name;
  ReportEventArgument(
      this.eventId, this.positionId, this.attributes, this.type, this.name);
}
