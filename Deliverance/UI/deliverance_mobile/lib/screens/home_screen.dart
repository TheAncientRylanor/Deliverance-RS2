import 'package:deliverance_mobile/layouts/master_screen.dart';
import 'package:deliverance_mobile/providers/auth_provider.dart';
import 'package:deliverance_mobile/providers/user_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/api_constants.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/image_holder.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserProvider _userProvider;
  bool _initialized = false;
  bool isLoading = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _userProvider = Provider.of<UserProvider>(context, listen: false);
      _initialized = true;
      initValues();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void initValues() async {
    final token = AuthProvider.accesstoken ?? "";
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['nameid']?.toString() ?? "";
    final data = await _userProvider.getByUUID(userId);
    isLoading = false;
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<UserProvider>().data?.username ?? '';
    return MasterScreen(
      title: "Home",
      child: isLoading
          ? Center(
              child: globalLoadingSpinner(
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(200),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.0,
                          ),
                        ),
                        child: ClipOval(
                          child: buildProfileImage(
                            null,
                            _userProvider.data?.imagePath ?? "",
                            ApiConstants.baseUrl,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 40, bottom: 50),
                        child: Text(
                          "Hello, ${username}",
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                      Text(
                        "Same issue again? Use these shortcuts here to skip few steps",
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight(100),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          right: 20,
                          left: 30,
                          bottom: 60,
                          top: 50,
                        ),
                        child: Column(
                          spacing: 10,
                          children: [
                            Card(
                              elevation: 10,
                              shadowColor: Colors.black,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 150,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        spacing: 5,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Location: ",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight(100),
                                                ),
                                          ),
                                          Text(
                                            "Problem",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight(100),
                                                ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 50,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
