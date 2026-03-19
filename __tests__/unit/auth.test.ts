import { describe, test, expect } from 'bun:test';

// Example unit tests — replace with your own application logic
describe('Input validation helpers', () => {
  const isValidEmail = (email: string): boolean => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  };

  const isStrongPassword = (password: string): boolean => {
    return password.length >= 8;
  };

  describe('isValidEmail', () => {
    test('accepts a valid email', () => {
      expect(isValidEmail('user@example.com')).toBe(true);
    });

    test('accepts email with subdomain', () => {
      expect(isValidEmail('user@mail.example.com')).toBe(true);
    });

    test('rejects email without @', () => {
      expect(isValidEmail('userexample.com')).toBe(false);
    });

    test('rejects email without domain', () => {
      expect(isValidEmail('user@')).toBe(false);
    });

    test('rejects empty string', () => {
      expect(isValidEmail('')).toBe(false);
    });
  });

  describe('isStrongPassword', () => {
    test('accepts password with 8+ characters', () => {
      expect(isStrongPassword('securepassword')).toBe(true);
    });

    test('accepts password with exactly 8 characters', () => {
      expect(isStrongPassword('12345678')).toBe(true);
    });

    test('rejects short password', () => {
      expect(isStrongPassword('short')).toBe(false);
    });

    test('rejects empty password', () => {
      expect(isStrongPassword('')).toBe(false);
    });
  });
});
