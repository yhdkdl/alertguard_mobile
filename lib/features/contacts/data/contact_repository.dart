import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'contact_model.dart';

class ContactRepository {
  final Dio _dio = DioClient.instance;

  Future<List<ContactModel>> getContacts() async {
    final response = await _dio.get('/contacts/');
    return (response.data as List)
        .map((json) => ContactModel.fromJson(json))
        .toList();
  }

  Future<ContactModel> addContact({
    required String name,
    required String phoneNumber,
    required String relationship,
  }) async {
    final response = await _dio.post(
      '/contacts/',
      data: {
        'name': name,
        'phone_number': phoneNumber,
        'relationship': relationship,
      },
    );
    return ContactModel.fromJson(response.data);
  }

  Future<void> deleteContact(int id) async {
    await _dio.delete('/contacts/$id/');
  }
}
