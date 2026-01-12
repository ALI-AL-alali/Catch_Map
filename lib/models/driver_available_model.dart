// class BidsResponse {
//   final bool success;
//   final BidsData data;
//
//   BidsResponse({
//     required this.success,
//     required this.data,
//   });
//
//   factory BidsResponse.fromJson(Map<String, dynamic> json) {
//     return BidsResponse(
//       success: json['success'],
//       data: BidsData.fromJson(json['data']),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'success': success,
//       'data': data.toJson(),
//     };
//   }
// }
// class BidsData {
//   final String rideId;
//   final List<Bid> bids;
//   final int count;
//
//   BidsData({
//     required this.rideId,
//     required this.bids,
//     required this.count,
//   });
//
//   factory BidsData.fromJson(Map<String, dynamic> json) {
//     return BidsData(
//       rideId: json['ride_id'].toString(),
//       bids: (json['bids'] as List)
//           .map((e) => Bid.fromJson(e))
//           .toList(),
//       count: json['count'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'ride_id': rideId,
//       'bids': bids.map((e) => e.toJson()).toList(),
//       'count': count,
//     };
//   }
// }
//
// class Bid {
//   final int id;
//   final int rideId;
//   final String price;
//   final bool isAccepted;
//   final String createdAt;
//   final Driver driver;
//   final dynamic customer;
//
//   Bid({
//     required this.id,
//     required this.rideId,
//     required this.price,
//     required this.isAccepted,
//     required this.createdAt,
//     required this.driver,
//     this.customer,
//   });
//
//   factory Bid.fromJson(Map<String, dynamic> json) {
//     return Bid(
//       id: json['id'],
//       rideId: json['ride_id'],
//       price: json['price'],
//       isAccepted: json['is_accepted'],
//       createdAt: json['created_at'],
//       driver: Driver.fromJson(json['driver']),
//       customer: json['customer'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'ride_id': rideId,
//       'price': price,
//       'is_accepted': isAccepted,
//       'created_at': createdAt,
//       'driver': driver.toJson(),
//       'customer': customer,
//     };
//   }
// }
//
// class Driver {
//   final int id;
//   final String name;
//
//   Driver({
//     required this.id,
//     required this.name,
//   });
//
//   factory Driver.fromJson(Map<String, dynamic> json) {
//     return Driver(
//       id: json['id'],
//       name: json['name'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//     };
//   }
// }
//
//
