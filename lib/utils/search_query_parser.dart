// ==========================================
// 検索クエリパーサー
// NOT, AND, OR の論理演算子をサポート
//
// 文法（優先度: NOT > AND > OR）:
//   expr  = term (OR term)*
//   term  = factor (AND factor)*
//   factor = NOT factor | atom
//   atom  = "(" expr ")" | TOKEN
//
// 使用例:
//   (NOT Chiarugi) OR Rigotti
//   ナイロン AND 紫 AND Lorree
//   Rigotti AND NOT 2506
// ==========================================

abstract class _Expr {
  bool evaluate(String text);
}

class _AtomExpr implements _Expr {
  final String token;
  _AtomExpr(this.token);

  @override
  bool evaluate(String text) =>
      text.toLowerCase().contains(token.toLowerCase());
}

class _NotExpr implements _Expr {
  final _Expr child;
  _NotExpr(this.child);

  @override
  bool evaluate(String text) => !child.evaluate(text);
}

class _AndExpr implements _Expr {
  final _Expr left;
  final _Expr right;
  _AndExpr(this.left, this.right);

  @override
  bool evaluate(String text) => left.evaluate(text) && right.evaluate(text);
}

class _OrExpr implements _Expr {
  final _Expr left;
  final _Expr right;
  _OrExpr(this.left, this.right);

  @override
  bool evaluate(String text) => left.evaluate(text) || right.evaluate(text);
}

// ==========================================
// トークナイザ
// ==========================================
enum _TokenKind { and, or, not, lparen, rparen, word, eof }

class _Token {
  final _TokenKind kind;
  final String value;
  _Token(this.kind, this.value);
}

List<_Token> _tokenize(String input) {
  final tokens = <_Token>[];
  int i = 0;
  while (i < input.length) {
    if (input[i] == ' ' || input[i] == '\t') {
      i++;
      continue;
    }
    if (input[i] == '(') {
      tokens.add(_Token(_TokenKind.lparen, '('));
      i++;
      continue;
    }
    if (input[i] == ')') {
      tokens.add(_Token(_TokenKind.rparen, ')'));
      i++;
      continue;
    }
    // 単語またはキーワードを読み取る
    final buf = StringBuffer();
    while (i < input.length &&
        input[i] != ' ' &&
        input[i] != '\t' &&
        input[i] != '(' &&
        input[i] != ')') {
      buf.write(input[i]);
      i++;
    }
    final word = buf.toString();
    if (word.toUpperCase() == 'AND') {
      tokens.add(_Token(_TokenKind.and, word));
    } else if (word.toUpperCase() == 'OR') {
      tokens.add(_Token(_TokenKind.or, word));
    } else if (word.toUpperCase() == 'NOT') {
      tokens.add(_Token(_TokenKind.not, word));
    } else if (word.isNotEmpty) {
      tokens.add(_Token(_TokenKind.word, word));
    }
  }
  tokens.add(_Token(_TokenKind.eof, ''));
  return tokens;
}

// ==========================================
// 再帰下降パーサ
// ==========================================
class _Parser {
  final List<_Token> _tokens;
  int _pos = 0;

  _Parser(this._tokens);

  _Token get _current => _tokens[_pos];

  _Token _consume() {
    final t = _tokens[_pos];
    _pos++;
    return t;
  }

  _Expr parse() {
    final expr = _parseOr();
    return expr;
  }

  _Expr _parseOr() {
    var left = _parseAnd();
    while (_current.kind == _TokenKind.or) {
      _consume(); // OR
      final right = _parseAnd();
      left = _OrExpr(left, right);
    }
    return left;
  }

  _Expr _parseAnd() {
    var left = _parseNot();
    while (_current.kind == _TokenKind.and) {
      _consume(); // AND
      final right = _parseNot();
      left = _AndExpr(left, right);
    }
    return left;
  }

  _Expr _parseNot() {
    if (_current.kind == _TokenKind.not) {
      _consume(); // NOT
      final child = _parseNot();
      return _NotExpr(child);
    }
    return _parseAtom();
  }

  _Expr _parseAtom() {
    if (_current.kind == _TokenKind.lparen) {
      _consume(); // (
      final expr = _parseOr();
      if (_current.kind == _TokenKind.rparen) {
        _consume(); // )
      }
      return expr;
    }
    if (_current.kind == _TokenKind.word) {
      final word = _consume().value;
      return _AtomExpr(word);
    }
    // 予期しないトークン（エラー対策: 常にtrueを返す空ノード）
    return _AtomExpr('');
  }
}

// ==========================================
// 公開API
// ==========================================
class SearchQueryParser {
  /// クエリ文字列をパースし、テキストを評価する関数を返す。
  /// クエリが空の場合は常に true を返す。
  /// パースに失敗した場合は単純な部分文字列検索にフォールバック。
  static bool Function(String text) compile(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return (_) => true;

    try {
      final tokens = _tokenize(trimmed);
      final expr = _Parser(tokens).parse();
      return (text) => expr.evaluate(text);
    } catch (_) {
      // フォールバック: 単純な部分一致
      return (text) => text.toLowerCase().contains(trimmed.toLowerCase());
    }
  }

  /// ヘルプテキスト（ユーザー向け）
  static const String helpText =
      '検索構文: AND / OR / NOT と括弧が使えます。\n'
      '例: ナイロン AND 紫  /  (NOT Chiarugi) OR Rigotti';
}
