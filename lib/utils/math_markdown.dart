import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'\$\$(.*?)\$\$|\$(.*?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isDisplay = match[1] != null;
    final math = match[1] ?? match[2];
    final el = md.Element.text('math', math ?? '');
    el.attributes['display'] = isDisplay.toString();
    parser.addNode(el);
    return true;
  }
}

class MathBuilder extends MarkdownElementBuilder {
  final double fontSize;
  final double verticalPadding;

  MathBuilder({this.fontSize = 16.0, this.verticalPadding = 8.0});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final isDisplay = element.attributes['display'] == 'true';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDisplay ? verticalPadding : 0.0),
      child: Math.tex(
        element.textContent,
        textStyle: preferredStyle?.copyWith(fontSize: fontSize),
        mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
        onErrorFallback: (err) => Text(element.textContent, style: preferredStyle?.copyWith(color: Colors.redAccent)),
      ),
    );
  }
}