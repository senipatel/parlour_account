import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart'; // Package to check MIME type of the file

class BillPaymentEntryPage extends StatefulWidget {
  const BillPaymentEntryPage({super.key});

  @override
  BillPaymentEntryPageState createState() => BillPaymentEntryPageState();
}

class BillPaymentEntryPageState extends State<BillPaymentEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the form fields
  final TextEditingController _billAmountCashController = TextEditingController();
  final TextEditingController _billAmountOnlineController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // DateTime object to hold the selected date
  DateTime? _selectedDate;

  // Variables to hold the selected image file and its URL
  File? _imageFile;
  String? _imageUrl;

  final ImagePicker _picker = ImagePicker(); // Image picker instance

  // Function to handle form submission and store data in Firestore
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      var data = {
        'billAmountCash': _billAmountCashController.text,
        'billAmountOnline': _billAmountOnlineController.text,
        'description': _descriptionController.text,
        'date': _selectedDate?.toLocal().toString().split(' ')[0] ?? 'Not selected',
        'timestamp': Timestamp.now(),
      };

      // If there's an image, upload it to Firebase Storage
      if (_imageFile != null) {
        try {
          String fileName = DateTime.now().millisecondsSinceEpoch.toString(); // Unique file name
          Reference storageReference = FirebaseStorage.instance.ref().child('bill_images/$fileName');
          UploadTask uploadTask = storageReference.putFile(_imageFile!);

          // Wait for the upload to complete
          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

          // Get the image URL after upload is complete
          String imageUrl = await taskSnapshot.ref.getDownloadURL();

          // Add the image URL to the data model
          data['imageUrl'] = imageUrl;
        } catch (e) {
          print('Error uploading image: $e');
        }
      }

      // Store the data in Firestore under the 'BillPaymentEntry' collection
      try {
        await FirebaseFirestore.instance.collection('BillPaymentEntry').add(data);

        // Show success dialog
        _showSuccessDialog();
      } catch (e) {
        print('Error saving data: $e');
        _showErrorDialog();
      }
    }
  }

  // Function to show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Data Saved Successfully'),
          content: const Text('Your data has been successfully stored in Firestore.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the success dialog
                Navigator.pop(context); // Navigate back to Home screen (pop the BillPaymentEntry page)
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to show error dialog if data saving fails
  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to save data. Please try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the error dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to open the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to pick an image from the gallery or take a photo
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery); // Pick image from gallery
    if (pickedFile != null) {
      String? mimeType = lookupMimeType(pickedFile.path);  // Check MIME type

      // Check if the picked file is an image
      if (mimeType != null && mimeType.startsWith('image/')) {
        setState(() {
          _imageFile = File(pickedFile.path); // Store the picked image file
        });
      } else {
        // Show error if the file is not an image
        _showErrorDialog();
      }
    }
  }

  // Function to preview image on both mobile and web platforms
  Widget _buildImagePreview() {
    if (_imageFile != null) {
      if (kIsWeb) {
        // For Web: Use Image.network to display the image using the URL
        return Image.network(_imageUrl ?? '');  // Use the image URL obtained after upload
      } else {
        // For Mobile (Android/iOS): Use Image.file to display the selected image
        return Image.file(_imageFile!, height: 100, width: 100);
      }
    } else {
      return const Text('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill/Payment Entry'),
      ),
      body: SingleChildScrollView(  // Wrap the entire content with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _billAmountCashController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Amount (Cash)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the bill amount (cash)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _billAmountOnlineController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Amount (Online)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the bill amount (online)';
                    }
                    return null;
                  },
                ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        hintText: _selectedDate == null
                            ? 'Select Date'
                            : _selectedDate?.toLocal().toString().split(' ')[0],
                      ),
                      validator: (value) {
                        if (_selectedDate == null) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Image Picker (Button to select image)
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Pick Image'),
                ),
                const SizedBox(height: 20),

                // Display image preview (if selected)
                _buildImagePreview(),

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
