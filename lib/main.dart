import 'package:beaverlog_flutter/beaverlog_flutter.dart';
import 'package:decaf/constants/colors.dart';
import 'package:decaf/pages/home.dart';
import 'package:decaf/pages/settings.dart';
import 'package:decaf/utils/analytics.dart';
import 'package:decaf/widgets/add_caffeine_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final pageIndexProvider = StateProvider<int>((ref) => 0);

void main() async {
  await dotenv.load(fileName: ".env");
  
  BeaverLog().init(
    appId: dotenv.env['BEAVERLOG_APP_ID']!,
    publicKey: dotenv.env['BEAVERLOG_PK']!,
    host: 'https://beaverlog.deno.dev',
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bottom Navigation Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.caffeine,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.light,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  final List<Widget> _pages = const [HomePage(), SettingsPage()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(pageIndexProvider);

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddCaffeineModal(),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Wrap(
          children: [
            Theme(
              data: ThemeData(splashColor: Colors.transparent),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: selectedIndex,
                onTap:
                    (index) =>
                        ref.read(pageIndexProvider.notifier).state = index,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
