import 'package:equatable/equatable.dart';

// Base Failure class
abstract class Failure extends Equatable {
  // If you want to pass properties to the Failure, add them here.
  // For example: final String message;
  // const Failure([this.message = 'An unexpected error occurred']);

  const Failure([
    List<Object> properties = const <Object>[],
  ]); // Keep constructor for Equatable

  @override
  List<Object?> get props => []; // Adjust if properties are added
}

// Specific failures can extend the base Failure class
// Example:
class ServerFailure extends Failure {} // Failure from the server API

class NetworkFailure
    extends Failure {} // Failure related to device connectivity

class CacheFailure
    extends Failure {} // Define specific failure for local cache issues

class InitialLoadFailure
    extends Failure {} // Failure during initial data load (remote + local)
