import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/config/constants.dart';
import 'package:nkust_ap/models/models.dart';
import 'package:nkust_ap/pages/page.dart';
import 'package:nkust_ap/res/resource.dart' as Resource;
import 'package:nkust_ap/utils/app_localizations.dart';
import 'package:nkust_ap/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

var pictureUrl = "";

class DrawerBody extends StatefulWidget {
  final UserInfo userInfo;

  const DrawerBody({Key key, this.userInfo}) : super(key: key);

  @override
  DrawerBodyState createState() => new DrawerBodyState();
}

class DrawerBodyState extends State<DrawerBody> {
  SharedPreferences prefs;
  bool displayPicture = true;

  AppLocalizations app;

  bool isStudyExpanded = false;
  bool isBusExpanded = false;
  bool isLeaveExpanded = false;

  @override
  void initState() {
    super.initState();
    _getPreference();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _defaultStyle() => TextStyle(color: Resource.Colors.grey, fontSize: 16.0);

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              color: Color(0xff0071FF),
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  if (widget.userInfo == null) return;
                  if ((widget.userInfo.status == null
                          ? 200
                          : widget.userInfo.status) ==
                      200)
                    Navigator.of(context)
                        .push(UserInfoPageRoute(widget.userInfo));
                  else
                    Utils.showToast(widget.userInfo.message);
                },
                child: Stack(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      decoration: new BoxDecoration(
                        image: new DecorationImage(
                            image: new AssetImage(
                                "assets/images/drawer-backbroud.webp"),
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.bottomCenter),
                      ),
                      padding: EdgeInsets.all(20.0),
                      child: Flex(
                        direction: Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 40.0),
                          pictureUrl != "" && displayPicture
                              ? Hero(
                                  tag: Constants.TAG_STUDENT_PICTURE,
                                  child: Container(
                                    width: 72.0,
                                    height: 72.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: new DecorationImage(
                                        fit: BoxFit.fitWidth,
                                        image: CachedNetworkImageProvider(
                                          pictureUrl,
                                          errorListener: () {
                                            print('error');
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 72.0,
                                  height: 72.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.account_circle,
                                    color: Colors.white,
                                    size: 72.0,
                                  ),
                                ),
                          SizedBox(height: 16.0),
                          SizedBox(
                            height: 32.0,
                            child: Text(
                              widget.userInfo == null
                                  ? " \n "
                                  : "${widget.userInfo.studentNameCht}\n"
                                  "${widget.userInfo.studentId}",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 20.0,
                      right: 20.0,
                      child: Container(
                        child: Image.asset(
                          "assets/images/drawer-icon.webp",
                          width: 90.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ExpansionTile(
              onExpansionChanged: (bool) {
                setState(() {
                  isStudyExpanded = bool;
                });
              },
              leading: Icon(
                Icons.school,
                color: isStudyExpanded
                    ? Resource.Colors.blue
                    : Resource.Colors.grey,
              ),
              title: Text(app.courseInfo, style: _defaultStyle()),
              children: <Widget>[
                _subItem(Icons.class_, app.course, CoursePageRoute()),
                _subItem(Icons.assignment, app.score, ScorePageRoute()),
                _subItem(
                    Icons.apps, app.calculateUnits, CalculateUnitsPageRoute()),
              ],
            ),
            ExpansionTile(
              onExpansionChanged: (bool) {
                setState(() {
                  isLeaveExpanded = bool;
                });
              },
              leading: Icon(
                Icons.calendar_today,
                color: isLeaveExpanded
                    ? Resource.Colors.blue
                    : Resource.Colors.grey,
              ),
              title: Text(app.leave, style: _defaultStyle()),
              children: <Widget>[
                _subItem(
                    Icons.edit, app.leaveApply, LeavePageRoute(initIndex: 0)),
                _subItem(Icons.assignment, app.leaveRecords,
                    LeavePageRoute(initIndex: 1)),
              ],
            ),
            ExpansionTile(
              onExpansionChanged: (bool) {
                setState(() {
                  isBusExpanded = bool;
                });
              },
              leading: Icon(
                Icons.directions_bus,
                color:
                    isBusExpanded ? Resource.Colors.blue : Resource.Colors.grey,
              ),
              title: Text(app.bus, style: _defaultStyle()),
              children: <Widget>[
                _subItem(Icons.date_range, app.busReserve,
                    BusPageRoute(initIndex: 0)),
                _subItem(Icons.assignment, app.busReservations,
                    BusPageRoute(initIndex: 1)),
              ],
            ),
            _item(Icons.info, app.schoolInfo, SchoolInfoPageRoute()),
            _item(Icons.face, app.about, AboutUsPageRoute()),
            _item(Icons.settings, app.settings, SettingPageRoute()),
            ListTile(
              leading: Icon(
                Icons.power_settings_new,
                color: Resource.Colors.grey,
              ),
              onTap: () {
                Navigator.popUntil(
                    context, ModalRoute.withName(Navigator.defaultRouteName));
              },
              title: Text(app.logout, style: _defaultStyle()),
            ),
          ],
        ),
      ),
    );
  }

  _item(IconData icon, String title, MaterialPageRoute route) => ListTile(
        leading: Icon(icon, color: Resource.Colors.grey),
        title: Text(title, style: _defaultStyle()),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, route);
        },
      );

  _subItem(IconData icon, String title, MaterialPageRoute route) => ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 72.0),
        leading: Icon(icon, color: Resource.Colors.grey),
        title: Text(title, style: _defaultStyle()),
        onTap: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          if (route is BusPageRoute) {
            bool bus = prefs.getBool(Constants.PREF_BUS_ENABLE) ?? true;
            if (!bus) {
              Utils.showToast(app.canNotUseFeature);
              return;
            }
          }
          if (route is LeavePageRoute) {
            bool leave = prefs.getBool(Constants.PREF_LEAVE_ENABLE) ?? true;
            if (!leave) {
              Utils.showToast(app.canNotUseFeature);
              return;
            }
          }
          Navigator.of(context).pop();
          Navigator.of(context).push(route);
        },
      );

  _getUserPicture() {
    Helper.instance.getUsersPicture().then((url) {
      if (this.mounted) {
        setState(() {
          pictureUrl = url;
        });
      }
    }).catchError((e) {
      if (e is DioError) {
        switch (e.type) {
          case DioErrorType.RESPONSE:
            Utils.handleResponseError(context, 'getUserPicture', mounted, e);
            break;
          default:
            break;
        }
      } else {
        throw e;
      }
    });
  }

  _getPreference() async {
    prefs = await SharedPreferences.getInstance();
    if (!prefs.getBool(Constants.PREF_IS_OFFLINE_LOGIN)) {
      _getUserPicture();
    }
    setState(() {
      displayPicture = prefs.getBool(Constants.PREF_DISPLAY_PICTURE) ?? true;
    });
  }
}
