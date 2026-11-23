import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';
    if (!EmailValidator.validate(value.trim())) return 'E‑mail inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';
    if (value.length < 6) return 'A senha deve ter ao menos 6 caracteres';
    return null;
  }
}
