sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;

  const Success({required this.data});
}

class Failure<T> extends Result<T> {
  final String err;

  const Failure({required this.err});
}
