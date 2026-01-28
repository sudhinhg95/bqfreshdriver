class NotificationModel {
  int? id;
  String? title;
  String? description;
  String? imageFullUrl;
  String? createdAt;
  String? updatedAt;
  Data? data;

  NotificationModel({
    this.id,
    this.title,
    this.description,
    this.imageFullUrl,
    this.createdAt,
    this.updatedAt,
    this.data,
  });

  NotificationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    imageFullUrl = json['image_full_url'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['image_full_url'] = imageFullUrl;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? type;
  int? orderId;
  String? customerName;

  Data({this.type, this.orderId, this.customerName});

  Data.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    if (json.containsKey('order_id')) {
      final dynamic orderIdValue = json['order_id'];
      if (orderIdValue is int) {
        orderId = orderIdValue;
      } else if (orderIdValue != null) {
        orderId = int.tryParse(orderIdValue.toString());
      }
    }
    if (json.containsKey('customer_name')) {
      customerName = json['customer_name']?.toString();
    } else if (json.containsKey('customer')) {
      customerName = json['customer']?.toString();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    if (orderId != null) {
      data['order_id'] = orderId;
    }
    if (customerName != null) {
      data['customer_name'] = customerName;
    }
    return data;
  }
}