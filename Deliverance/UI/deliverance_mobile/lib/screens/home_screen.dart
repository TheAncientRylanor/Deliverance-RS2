import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/models/report_status_filter.dart';
import 'package:deliverance_mobile/models/search_models/report_search_object.dart';
import 'package:deliverance_mobile/models/search_result.dart';
import 'package:deliverance_mobile/providers/auth_provider.dart';
import 'package:deliverance_mobile/providers/report_provider.dart';
import 'package:deliverance_mobile/providers/user_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/api_constants.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/image_holder.dart';
import 'package:deliverance_mobile/widgets/report_card.dart';
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
  late ReportProvider _reportProvider;
  late SearchResult<Report> _reportList = SearchResult();
  final ReportSearchObject _reportSearchObject = ReportSearchObject(
    pageSize: 3,
    sortBy: "DateReported",
    status: ReportStatusFilter.active,
  );
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
    _reportProvider = context.read<ReportProvider>();
    super.initState();
  }

  void initValues() async {
    final token = AuthProvider.accesstoken ?? "";
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['nameid']?.toString() ?? "";
    try {
      List<dynamic> result = await Future.wait([
        _userProvider.getByUUID(userId),
        _reportProvider.get(filter: _reportSearchObject.toJson()),
      ]);
      if (!mounted) return;
      setState(() {
        _reportList = result[1];
        isLoading = false;
      });
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: initValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<UserProvider>().data?.username ?? '';
    return isLoading
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
                        "Hello, $username",
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    Text(
                      (_reportList.items?.isEmpty ?? true)
                          ? "No reports? Shame... The admin will be bored..."
                          : "Same issue again? Use these shortcuts here to skip few steps",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight(100),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        right: 20,
                        left: 30,
                        bottom: 100,
                        top: 50,
                      ),
                      child: Column(
                        spacing: 10,
                        children: [
                          for (Report report in _reportList.items ?? [])
                            ReportCard(
                              report: report,
                              initFunction: initValues,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
