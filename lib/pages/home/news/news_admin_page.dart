import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/models/announcements_data.dart';
import 'package:nkust_ap/models/login_response.dart';
import 'package:nkust_ap/pages/home/news/news_edit_page.dart';
import 'package:nkust_ap/res/app_icon.dart';
import 'package:nkust_ap/res/resource.dart' as Resource;
import 'package:nkust_ap/utils/app_localizations.dart';
import 'package:nkust_ap/utils/utils.dart';
import 'package:nkust_ap/widgets/hint_content.dart';
import 'package:nkust_ap/widgets/progress_dialog.dart';
import 'package:nkust_ap/widgets/yes_no_dialog.dart';
import 'package:sprintf/sprintf.dart';

enum _State { notLogin, loading, finish, error, empty, offline }

class NewsAdminPage extends StatefulWidget {
  static const String routerName = "/news/admin";
  final bool isAdmin;

  const NewsAdminPage({Key key, this.isAdmin = false}) : super(key: key);

  @override
  _NewsAdminPageState createState() => _NewsAdminPageState();
}

class _NewsAdminPageState extends State<NewsAdminPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  AppLocalizations app;

  _State state = _State.notLogin;

  AnnouncementsData announcementsResponse;

  bool isOffline = false;
  FocusNode usernameFocusNode;
  FocusNode passwordFocusNode;

  TextStyle get _editTextStyle => TextStyle(
        fontSize: 18.0,
        decorationColor: Resource.Colors.blueAccent,
      );

  @override
  void initState() {
    //FA.setCurrentScreen('ScorePage', 'score_page.dart');
    if (widget.isAdmin) {
      state = _State.loading;
      _getData();
    } else {
      usernameFocusNode = FocusNode();
      passwordFocusNode = FocusNode();
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(app.news),
        backgroundColor: Resource.Colors.blue,
      ),
      floatingActionButton: state == _State.notLogin
          ? null
          : FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () async {
                var success = await Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => NewsEditPage(
                      mode: Mode.add,
                    ),
                  ),
                );
                if (success is bool && success != null) {
                  if (success) {
                    _getData();
                  }
                }
              },
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _getData();
          return null;
        },
        child: _body(),
      ),
    );
  }

  _body() {
    switch (state) {
      case _State.notLogin:
        return _loginContent();
      case _State.loading:
        return Container(
            child: CircularProgressIndicator(), alignment: Alignment.center);
      case _State.empty:
      case _State.error:
        return FlatButton(
          onPressed: () {
            _getData();
          },
          child: HintContent(
            icon: AppIcon.classIcon,
            content: app.clickToRetry,
          ),
        );
      case _State.offline:
        return HintContent(
          icon: AppIcon.classIcon,
          content: app.noOfflineData,
        );
      default:
        return ListView.builder(
          itemBuilder: (_, index) {
            return _item(announcementsResponse.data[index]);
          },
          itemCount: announcementsResponse.data.length,
        );
    }
  }

  _loginContent() {
    Widget usernameTextField = TextField(
      maxLines: 1,
      controller: _username,
      textInputAction: TextInputAction.next,
      focusNode: usernameFocusNode,
      onSubmitted: (text) {
        usernameFocusNode.unfocus();
        FocusScope.of(context).requestFocus(passwordFocusNode);
      },
      decoration: InputDecoration(
        labelText: app.username,
      ),
      style: _editTextStyle,
    );
    Widget passwordTextField = TextField(
      obscureText: true,
      maxLines: 1,
      textInputAction: TextInputAction.send,
      controller: _password,
      focusNode: passwordFocusNode,
      onSubmitted: (text) {
        passwordFocusNode.unfocus();
        _login();
      },
      decoration: InputDecoration(
        labelText: app.password,
      ),
      style: _editTextStyle,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 32.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          usernameTextField,
          passwordTextField,
          SizedBox(height: 32.0),
          Container(
            width: double.infinity,
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(30.0),
                ),
              ),
              padding: EdgeInsets.all(14.0),
              onPressed: () async {
                _login();
              },
              color: Colors.white,
              child: Text(
                app.login,
                style: TextStyle(color: Resource.Colors.blue, fontSize: 18.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(Announcements item) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        radius: 12.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(
              item.title,
              style: TextStyle(fontSize: 18.0),
            ),
            trailing: IconButton(
              icon: Icon(
                AppIcon.cancel,
                color: Resource.Colors.red,
              ),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => YesNoDialog(
                    title: app.deleteNewsTitle,
                    contentWidget: Text(
                      "${app.deleteNewsContent}",
                      textAlign: TextAlign.center,
                    ),
                    leftActionText: app.back,
                    rightActionText: app.determine,
                    rightActionFunction: () {
                      Helper.instance.deleteAnnouncement(item).then((response) {
                        _scaffoldKey.currentState.showSnackBar(
                          SnackBar(
                            content: Text(app.deleteSuccess),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        _getData();
                      }).catchError((e) {
                        if (e is DioError) {
                          switch (e.type) {
                            case DioErrorType.RESPONSE:
                              Utils.showToast(context, e.response?.data ?? '');
                              break;
                            case DioErrorType.CANCEL:
                              break;
                            default:
                              Utils.handleDioError(context, e);
                              break;
                          }
                        } else {
                          throw e;
                        }
                      });
                    },
                  ),
                );
              },
            ),
            subtitle: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: Resource.Colors.grey, height: 1.3, fontSize: 16.0),
                  children: [
                    TextSpan(
                      text: '${app.weight}：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '${item.weight ?? 1}\n'),
                    TextSpan(
                      text: '${app.imageUrl}：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '${item.imgUrl}',
                      style: TextStyle(
                        color: Resource.Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Utils.launchUrl(item.imgUrl);
                        },
                    ),
                    TextSpan(
                      text: '\n${app.url}：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '${item.url}',
                      style: TextStyle(
                        color: Resource.Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Utils.launchUrl(item.url);
                        },
                    ),
                    TextSpan(
                      text: '\n${app.expireTime}：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '${item.expireTime?? app.noExpiration}\n'),
                    TextSpan(
                      text: '${app.description}：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '${item.description}'),
                  ],
                ),
              ),
            ),
          ),
        ),
        onTap: () async {
          var success = await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => NewsEditPage(
                mode: Mode.edit,
                announcement: item,
              ),
            ),
          );
          if (success is bool && success != null) {
            if (success) {
              _getData();
            }
          }
        },
      ),
    );
  }

  _getData() async {
    Helper.instance.getAllAnnouncements().then((announcementsResponse) {
      this.announcementsResponse = announcementsResponse;
      setState(() {
        state = announcementsResponse.data.length == 0
            ? _State.empty
            : _State.finish;
      });
    }).catchError((e) {
      setState(() {
        state = _State.error;
      });
    });
  }

  void _login() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      Utils.showToast(context, app.doNotEmpty);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => WillPopScope(
            child: ProgressDialog(app.logining),
            onWillPop: () async {
              return false;
            }),
        barrierDismissible: false,
      );
      Helper.instance
          .adminLogin(_username.text, _password.text)
          .then((LoginResponse response) async {
        Navigator.of(context, rootNavigator: true).pop();
        Utils.showToast(context, app.loginSuccess);
        setState(() {
          state = _State.loading;
          _getData();
        });
      }).catchError((e) {
        Navigator.of(context, rootNavigator: true).pop();
        if (e is DioError) {
          switch (e.type) {
            case DioErrorType.RESPONSE:
              Utils.showToast(context, app.loginFail);
              break;
            case DioErrorType.CANCEL:
              break;
            default:
              Utils.handleDioError(context, e);
              break;
          }
        } else {
          throw e;
        }
      });
    }
  }
}
