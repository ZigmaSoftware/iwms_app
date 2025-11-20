// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

List<Welcome> welcomeFromJson(String str) => List<Welcome>.from(json.decode(str).map((x) => Welcome.fromJson(x)));

String welcomeToJson(List<Welcome> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Welcome {
    int id;
    String wardName;
    String zoneName;
    String cityName;
    String districtName;
    String stateName;
    String countryName;
    String propertyName;
    String subPropertyName;
    String uniqueId;
    String customerName;
    String contactNo;
    String buildingNo;
    String street;
    String area;
    String password;
    String pincode;
    String latitude;
    String longitude;
    String idProofType;
    String idNo;
    bool isDeleted;
    bool isActive;
    int userType;
    int ward;
    int zone;
    int city;
    int district;
    int state;
    int country;
    int property;
    int subProperty;

    Welcome({
        required this.id,
        required this.wardName,
        required this.zoneName,
        required this.cityName,
        required this.districtName,
        required this.stateName,
        required this.countryName,
        required this.propertyName,
        required this.subPropertyName,
        required this.uniqueId,
        required this.customerName,
        required this.contactNo,
        required this.buildingNo,
        required this.street,
        required this.area,
        required this.password,
        required this.pincode,
        required this.latitude,
        required this.longitude,
        required this.idProofType,
        required this.idNo,
        required this.isDeleted,
        required this.isActive,
        required this.userType,
        required this.ward,
        required this.zone,
        required this.city,
        required this.district,
        required this.state,
        required this.country,
        required this.property,
        required this.subProperty,
    });

    factory Welcome.fromJson(Map<String, dynamic> json) => Welcome(
        id: json["id"],
        wardName: json["ward_name"],
        zoneName: json["zone_name"],
        cityName: json["city_name"],
        districtName: json["district_name"],
        stateName: json["state_name"],
        countryName: json["country_name"],
        propertyName: json["property_name"],
        subPropertyName: json["sub_property_name"],
        uniqueId: json["unique_id"],
        customerName: json["customer_name"],
        contactNo: json["contact_no"],
        buildingNo: json["building_no"],
        street: json["street"],
        area: json["area"],
        password: json["password"],
        pincode: json["pincode"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        idProofType: json["id_proof_type"],
        idNo: json["id_no"],
        isDeleted: json["is_deleted"],
        isActive: json["is_active"],
        userType: json["user_type"],
        ward: json["ward"],
        zone: json["zone"],
        city: json["city"],
        district: json["district"],
        state: json["state"],
        country: json["country"],
        property: json["property"],
        subProperty: json["sub_property"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "ward_name": wardName,
        "zone_name": zoneName,
        "city_name": cityName,
        "district_name": districtName,
        "state_name": stateName,
        "country_name": countryName,
        "property_name": propertyName,
        "sub_property_name": subPropertyName,
        "unique_id": uniqueId,
        "customer_name": customerName,
        "contact_no": contactNo,
        "building_no": buildingNo,
        "street": street,
        "area": area,
        "password": password,
        "pincode": pincode,
        "latitude": latitude,
        "longitude": longitude,
        "id_proof_type": idProofType,
        "id_no": idNo,
        "is_deleted": isDeleted,
        "is_active": isActive,
        "user_type": userType,
        "ward": ward,
        "zone": zone,
        "city": city,
        "district": district,
        "state": state,
        "country": country,
        "property": property,
        "sub_property": subProperty,
    };
}
