import 'package:equatable/equatable.dart';

// Base Failure class
abstract class Failure extends Equatable {
  final String? message; // Added optional message property

  const Failure({this.message}); // Updated constructor

  @override
  List<Object?> get props => [message]; // Include message in props for comparison

  @override
  String toString() => message ?? 'An unexpected error occurred'; // Provide default message
}

// Specific failures can extend the base Failure class
// Example:
class ServerFailure extends Failure {
  const ServerFailure({String? message}) : super(message: message);
} // Failure from the server API

class NetworkFailure extends Failure {
  const NetworkFailure({String? message}) : super(message: message);
} // Failure related to device connectivity

class CacheFailure extends Failure {
  const CacheFailure({String? message}) : super(message: message);
} // Define specific failure for local cache issues

class InitialLoadFailure extends Failure {
  const InitialLoadFailure({String? message}) : super(message: message);
} // Failure during initial data load (remote + local)
