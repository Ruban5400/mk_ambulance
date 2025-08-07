import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureField extends StatefulWidget {
  final String fieldName;
  final Map<String, dynamic> formValues;
  final Function(String?) onChanged;

  SignatureField({
    required this.fieldName,
    required this.formValues,
    required this.onChanged,
  });

  @override
  _SignatureFieldState createState() => _SignatureFieldState();
}

class _SignatureFieldState extends State<SignatureField> {
  late SignatureController _signatureController;
  String? _capturedSignature;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(penStrokeWidth: 2.0);
    _capturedSignature = widget.formValues[widget.fieldName];
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSignatureArea(),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (_capturedSignature == null) ...[
              ElevatedButton(
                onPressed: () async {
                  if (_signatureController.isNotEmpty) {
                    final signatureImage =
                    await _signatureController.toPngBytes();
                    if (signatureImage != null) {
                      String encoded = base64Encode(signatureImage);
                      setState(() {
                        _capturedSignature = encoded;
                        widget.onChanged(encoded);
                        widget.formValues[widget.fieldName] = encoded;
                      });
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please provide a signature.")),
                    );
                  }
                },
                child: Text("Capture Signature"),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () {
                  _signatureController.clear();
                  setState(() {
                    _capturedSignature = null;
                    widget.onChanged(null);
                    widget.formValues.remove(widget.fieldName);
                  });
                },
                child: Text("Clear Signature"),
              ),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureArea() {
    if (_capturedSignature != null) {
      return Container(
        padding: EdgeInsets.all(8),
        color: Colors.grey.shade200,
        child: Image.memory(
          base64Decode(_capturedSignature!),
          height: 150,
          fit: BoxFit.contain,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.grey.shade200, width: 1.0),
      ),
      child: Signature(
        controller: _signatureController,
        height: 200,
        width: double.infinity,
        backgroundColor: Colors.white,
      ),
    );
  }
}
