import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:formataai/core/stores/theme_store.dart';

void main() {
  group('ThemeStore', () {
    late ThemeStore store;

    setUp(() {
      store = ThemeStore();
    });

    test('inicia com tema claro', () {
      expect(store.mode, ThemeMode.light);
      expect(store.isDark, false);
    });

    test('toggle alterna para escuro', () {
      store.toggle();
      expect(store.mode, ThemeMode.dark);
      expect(store.isDark, true);
    });

    test('toggle duplo volta para claro', () {
      store.toggle();
      store.toggle();
      expect(store.mode, ThemeMode.light);
      expect(store.isDark, false);
    });

    test('setMode define modo corretamente', () {
      store.setMode(ThemeMode.dark);
      expect(store.mode, ThemeMode.dark);
      expect(store.isDark, true);
    });

    test('setMode mesmo modo nao notifica', () {
      int count = 0;
      store.addListener(() => count++);

      store.setMode(ThemeMode.light);
      expect(count, 0);

      store.setMode(ThemeMode.dark);
      expect(count, 1);

      store.setMode(ThemeMode.dark);
      expect(count, 1);
    });

    test('toggle notifica listeners', () {
      int count = 0;
      store.addListener(() => count++);

      store.toggle();
      expect(count, 1);

      store.toggle();
      expect(count, 2);
    });
  });
}
