class EndPoint {
  static const String baseUrl =
      "https://tableghat.com/catch/DistanceCalculator/public";
  static const String baseUrl2 = 'http://192.168.100.47:8000/api';



  static const String ride = "$baseUrl2/rides/";
  static const String drivers = "$baseUrl2/drivers";

  static const String distance = "$baseUrl/distance-result";
  static const String login = "$baseUrl2/auth/login";
}



String? token;