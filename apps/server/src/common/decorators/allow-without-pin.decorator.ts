import { SetMetadata } from '@nestjs/common';

export const ALLOW_WITHOUT_PIN_KEY = 'allowWithoutPin';
export const AllowWithoutPin = () => SetMetadata(ALLOW_WITHOUT_PIN_KEY, true);
