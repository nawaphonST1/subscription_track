import { describe, it, expect } from 'vitest';
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { RegisterDto } from './register.dto';

describe('RegisterDto validation', () => {
  it('fails validation with 400-level error when security_pin is omitted', async () => {
    const dto = plainToInstance(RegisterDto, {
      email: 'user@example.com',
      password: 'Password123!',
      name: 'Test User',
    });

    const errors = await validate(dto);
    const pinError = errors.find((e) => e.property === 'security_pin');

    expect(pinError).toBeDefined();
    expect(pinError?.constraints).toHaveProperty('isNotEmpty');
  });

  it('fails validation when security_pin is not 6 digits', async () => {
    const dto = plainToInstance(RegisterDto, {
      email: 'user@example.com',
      password: 'Password123!',
      name: 'Test User',
      security_pin: '12345',
    });

    const errors = await validate(dto);
    const pinError = errors.find((e) => e.property === 'security_pin');

    expect(pinError).toBeDefined();
    expect(pinError?.constraints).toHaveProperty('matches');
  });

  it('fails validation when security_pin contains non-digit characters', async () => {
    const dto = plainToInstance(RegisterDto, {
      email: 'user@example.com',
      password: 'Password123!',
      name: 'Test User',
      security_pin: '12345a',
    });

    const errors = await validate(dto);
    const pinError = errors.find((e) => e.property === 'security_pin');

    expect(pinError).toBeDefined();
    expect(pinError?.constraints).toHaveProperty('matches');
  });

  it('passes validation when valid 6-digit security_pin is provided', async () => {
    const dto = plainToInstance(RegisterDto, {
      email: 'user@example.com',
      password: 'Password123!',
      name: 'Test User',
      security_pin: '984721',
    });

    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });
});
