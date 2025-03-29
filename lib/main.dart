import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import necessary components for manual DI
import 'data/datasources/local/csv_local_data_source.dart';
import 'data/repositories/drug_repository_impl.dart';
import 'domain/repositories/drug_repository.dart';
import 'domain/usecases/get_all_drugs.dart';
import 'presentation/bloc/medicine_provider.dart';
import 'presentation/screens/main_screen.dart';

void main() {
  // Manual Dependency Injection Setup (Temporary)
  // 1. Data Source
  final CsvLocalDataSource csvLocalDataSource = CsvLocalDataSource();
  // 2. Repository
  final DrugRepository drugRepository = DrugRepositoryImpl(
    localDataSource: csvLocalDataSource,
  );
  // 3. Use Case
  final GetAllDrugs getAllDrugsUseCase = GetAllDrugs(drugRepository);

  runApp(
    MyApp(getAllDrugsUseCase: getAllDrugsUseCase),
  ); // Pass use case to MyApp
}

class MyApp extends StatelessWidget {
  final GetAllDrugs getAllDrugsUseCase; // Accept use case

  const MyApp({
    super.key,
    required this.getAllDrugsUseCase, // Require use case in constructor
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Provide the use case to the MedicineProvider
      create:
          (context) => MedicineProvider(getAllDrugsUseCase: getAllDrugsUseCase),
      child: MaterialApp(
        title: 'MediSwitch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Arial', // Consider using Noto Sans Arabic as per prompt
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
