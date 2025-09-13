sealed class Result<T> {
  const Result();
  R map<R>({required R Function(T) ok, required R Function(AppException) err});
}
class Ok<T> extends Result<T> {
  final T value; const Ok(this.value);
  @override R map<R>({required R Function(T) ok, required R Function(AppException) err}) => ok(value);
}
class Err<T> extends Result<T> {
  final AppException error; const Err(this.error);
  @override R map<R>({required R Function(T) ok, required R Function(AppException) err}) => err(error);
}
