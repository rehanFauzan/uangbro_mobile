import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/transaction_provider.dart';
import 'screens/main_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Date Formatting
  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..init(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UangBro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const MainWrapper(),
    );
  }
}

