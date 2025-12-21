import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class SajuPillar {
  final String title;
  final String gan;
  final String ji;
  final String tenRelation;
  final String hiddenStems;
  final String hiddenSipSins;
  final String elementGan; // 오행
  final String elementJi;

  SajuPillar({
    required this.title,
    required this.gan,
    required this.ji,
    required this.tenRelation,
    required this.hiddenStems,
    required this.hiddenSipSins,
    required this.elementGan,
    required this.elementJi,
  });
}

Color elementColor(String element) {
  switch (element) {
    case '木':
      return const Color(0xFF4CAF50); // sage green
    case '火':
      return const Color(0xFFF06292); // coral pink
    case '土':
      return const Color(0xFFFFD54F); // warm amber
    case '金':
      return const Color(0xFFB0BEC5); // silver gray
    case '水':
      return const Color(0xFF64B5F6); // cool blue
    default:
      return Colors.grey;
  }
}

class SajuGrid extends StatelessWidget {
  final List<SajuPillar> pillars;
  const SajuGrid({super.key, required this.pillars});

  
  Widget buildFixedHeightTextBlock(String text, double height) {
    final lines = text.split('\n');
    while (lines.length < 3) {
      lines.add(""); // 줄 수 맞추기
    }

    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: lines
            .map((line) => Text(
                  line,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5; // 4기둥 + 여유
    final boxSize = itemWidth * 0.7;
  //  final textBlockHeight = boxSize * 1.2;
  // boxSize 제한 추가
  final adjustedBoxSize = boxSize.clamp(60.0, 100.0); // 최소 60, 최대 100
  final textBlockHeight = adjustedBoxSize * 0.9;

    return Column(
      children: [
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: pillars.map((pillar) {
            return SizedBox(
              width: itemWidth,
              child: SingleChildScrollView (
                padding: const EdgeInsets.all(5),
                child : Column(
                  children: [
                    Text(
                      pillar.title,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)
                      ),
                    Text(
                      pillar.tenRelation,
                      style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.black87)
                    ),

                    // 천간
                    Container(
                      width: boxSize,
                      height: boxSize,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: elementColor(pillar.elementGan),
                        //color: elementColor(pillar.elementJi).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pillar.gan,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // 지지
                    Container(
                      width: boxSize,
                      height: boxSize,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: elementColor(pillar.elementJi).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pillar.ji,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // 지장간 십신 해석 (3줄 고정)
                  // Text(pillar.hiddenSipSins, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      pillar.hiddenSipSins,
                      style: GoogleFonts.notoSansKr(
                        fontSize : 12,
                        color: Colors.black87
                      ),
                    ),
                    // 지장간 간지 리스트 (3줄 고정)
                    buildFixedHeightTextBlock(pillar.hiddenStems, textBlockHeight),
                  ],
                ),
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}
