import 'package:equatable/equatable.dart';

// Base Failure class
abstract class Failure extends Equatable {
  // If you want to pass properties to the Failure, add them here.
  // For example: final String message;
  // const Failure([this.message = 'An unexpected error occurred']);

  const Failure([
    List properties = const <dynamic>[],
  ]); // Keep constructor for Equatable

  @override
  List<Object?> get props => []; // Adjust if properties are added
}

// Specific failures can extend the base Failure class
// Example:
// class ServerFailure extends Failure {}
class CacheFailure extends Failure {} // Define specific failure
