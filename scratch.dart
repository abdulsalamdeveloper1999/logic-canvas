void main() {
  final expando = Expando<String>();
  final list = [1, 2, 3];
  try {
    expando[list] = "hello";
    print("SUCCESS: ${expando[list]}");
  } catch (e) {
    print("ERROR: $e");
  }
}
