import 'package:flutter/material.dart';
import 'package:subscription_track/screens/onboarding/onboarding_visuals.dart';

class OnboardingPageData {
  final Widget visual;
  final String title;
  final String subtitle;

  const OnboardingPageData({
    required this.visual,
    required this.title,
    required this.subtitle,
  });
}

final List<OnboardingPageData> onboardingPages = [
  const OnboardingPageData(
    visual: SubscriptionStackVisual(),
    title: 'รวมทุกการสมัครสมาชิก\nไว้ในที่เดียว',
    subtitle: 'ติดตามรายการชำระเงินประจำทั้งหมดได้อย่างง่ายดาย และบริหารค่าใช้จ่ายของคุณได้อย่างมีประสิทธิภาพ',
  ),
  const OnboardingPageData(
    visual: UnusedAlertVisual(),
    title: 'ค้นหาบริการที่ไม่ได้ใช้\nและลดค่าใช้จ่าย',
    subtitle: 'ระบบอัจฉริยะจะตรวจหาบริการที่คุณไม่ได้รับชมหรือใช้งาน เพื่อช่วยหยุดค่าใช้จ่ายที่ไม่จำเป็น',
  ),
  const OnboardingPageData(
    visual: RenewalAlertVisual(),
    title: 'แจ้งเตือนก่อนต่ออายุ\nหมดปัญหาค่าใช้จ่ายไม่คาดคิด',
    subtitle: 'รับการแจ้งเตือนอัตโนมัติก่อนถึงวันเรียกเก็บเงิน เพื่อให้คุณควบคุมค่าใช้จ่ายได้อย่างมั่นใจ',
  ),
];
