class EndPoint {
  static const String baseUrl =
      "https://tableghat.com/catch/DistanceCalculator/public";
  static const String baseUrl2 = 'http://192.168.100.72:8000/api';
  static const String socketUrl = 'ws://192.168.100.72:4000';



  static const String ride = "$baseUrl2/rides/";
  static const String drivers = "$baseUrl2/drivers";

  static const String distance = "$baseUrl/distance-result";
  static const String login = "$baseUrl2/auth/login";
  static const String getDriver = "$baseUrl2/rides";
}



String? token;