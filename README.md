<details>
<summary>Prerequisite knowledge</summary>

1. Dart is a programming language. Dart 3 is the third major release of Dart.
2. Dart 3 introduces records, which are basically tuples with optional labels.
3. Dart is a C-like language. `final` declares a variable with an inferred type.
4. Last section needs a bit of knowledge about propositional calculus and formal languages. Introducing those is beyond the scope of this article.

</details>

## Parentheses in Dart

Dart 3 introduces records into the language. `()` is an **empty record**. Using it can result in fun syntax:

```dart
final a = (); // empty record
final b = ((),); // record holding a single empty record
final c = ((), ()); // record holding two empty records
```

Notice how example `b` has a trailing comma. Single-element records require this comma to differentiate this record from a different expression, to be introduced in a moment.

Parentheses have a few more uses in Dart, but we will focus on only two more.

First of all, they are used to **group expressions** to indicate precedence:

```dart
final a = (1 + 2) * (3 - 4); // first add, then subtract, then multiply
final b = (123) + ((312)); // a no-op grouping of literals, equivalent to `123 + 321`
```

Mixing empty records and grouping we get a new expression:

```dart
final a = (()); // a no-op grouping of an empty record, equivalent to just `()`
final b = ((())); // same as above
```

So `((),)` is a record holding a single empty record but `(())` is just `()` so an empty record.

Finally one more usage for parentheses is **function call expressions**. Functions are first-class objects in Dart, so you call functions stored in variables:

```dart
final a = func(); // calls `func`
final b = returnFunc()(); // calls `returnFunc` and then calls the function that was returned
```

Mixing empty records with call expressions we get:

```dart
final a = func(()); // calls `func` with a single argument, the empty record
final b = func((),); // same as above
```

And finally bringing grouping into the mix we get:

```dart
final a = func((())); // calls `func` with a single no-op grouped empty record, equivalent to `func(())`
final b = func(((),)); // calls `func` with a single record holding a single empty record
```

This introduces all parenthesis usages we need to solve the problem at hand (problem which was not yet introduced).

## Call overload

Now we move onto three more Dart features that will be needed: callable objects, extensions, and optional parameters.

Similarly to how you can overload the `+` operator for your types, Dart allows you to **overload the call invocation**. This is done by implementing a method called `call`. This results in instances acting like functions:

```dart
class StringLength {
	StringLength(this.multiplier);

	final int multiplier;

	int call(String param) {
		return param.length * multiplier;
	}
}

final a = StringLength(3)('asd'); // constructs an instance of `StringLength` and calls this instance like a function
```

**Extensions** allow you to add new methods to existing types, most useful for types defined outside of your library:

```dart
extension on int {
	int negate() => -this; // `=>` is a shorthand for immediately returning a value
}

final a = 123.negate(); // calls the attached method `negate` with `this = 123`
```

What's more, you can use extensions to overload the call invocation:

```dart
extension on int {
	int call() => this * 2;
}

final a = 123(); // calls `123` as if it were a function
```

The final piece needed to complete the puzzle are **optional parameters**. These are parameters that can be provided, but don't have to.

```dart
extension on int {
	int call([int? multiplier]) {
		if (multiplier != null) {
			return this * multiplier;
		} else {
			return this;
		}
	}
}

final a = 123(); // calls `123` with `multiplier = null`
final b = 123(321); // calls `123` with `multiplier = 321`
```

## Bringing it all together

Now we can descend into madness:

```dart
extension on () {
  () call([()? _]) => ();
}

final a = (())()(())()(()())()(((()()))())(((())));
```

Perfectly valid Dart program using **all introduced concepts**. Let's break it down:

1. We overload the call invocation for empty records. This makes `final a = ()();` valid, first create an empty record then call it.
2. We accept an optional parameter whose type is an empty record. This makes `final a = ()(());` valid, first create an empty record then call it with an empty record.
3. We return an empty record. This makes `final a = ()()();` valid, the first `()` pair is an empty record, all following pairs are call expressions.
4. We sprinkle some grouping expressions. `final a = ((())())();` is equivalent to `final a = ()()();`.

So while these are all just parenthesis, they represent three distinct functionalities.

## Problem of balanced parentheses

We can finally use the introduced tools to solve a real problem: balanced parentheses. Given a string containing only `(` and `)` characters does it have the following property: every close parenthesis appears after a corresponding open parenthesis and conversely. A few examples:

- `()()` - balanced
- `(())` - balanced
- `(()(()))` - balanced
- `())` - imbalanced, dangling close parenthesis
- `(` - imbalanced, open parenthesis is never closed
- `(()())(()` - imbalanced, open parenthesis is never closed

Notice how balanced parentheses look like valid Dart paren expressions, and imbalanced parentheses look like invalid Dart paren expressions (I am using 'Dart paren expression' to refer to the expression using only parentheses with the `call` extension overload on the empty record). Here, let's assume an empty string is not balanced, since it obviously wont be a valid expression. There seems to be an equivalence here, but before we prove this let's code up a function which will use this (_for now_) conjecture:

```dart
import 'dart:io';

void main() {
  print(areParenthesesBalanced("()()(())()(()())()(((()()))())((((((()))))))"));
}

bool areParenthesesBalanced(String s) {
	// sanity check if the input is up to assumptions
  if (!RegExp(r'^[\(\)]*$').hasMatch(s)) return false;

  final program = '''
extension on () {
  () call([()? _]) => ();
}

void main() {
  final _ = $s;
}
''';

  final file = File(
    Directory.systemTemp.createTempSync().path +
        Platform.pathSeparator +
        'main.dart',
  )..writeAsStringSync(program);
  final result = Process.runSync('dart', ['analyze', file.path]);

  return result.exitCode == 0;
}
```

We build source code for a program that will use these parentheses as an expression. We also define the `call` overload on `()`. We write this code to some file on OS' temp folder and run `dart analyze` on it. If analyzer reports no errors (exit code is zero), then the parentheses are balanced. Voilà.

## Bringing in a bit of rigor

I conjectured that all balanced strings of parentheses represent a valid Dart paren expression, and all imbalanced strings of parentheses represent an invalid Dart paren expression.

Let $b$ be a balanced string and $e$ be a valid Dart paren expression (then $\neg b$ is an imbalanced string and $\neg e$ is an invalid Dart paren expression). Then in propositional calculus our statement is: $(b \implies e) \land (\neg b \implies \neg e)$, simplifying it we see this is a pretty strong statement:

$$
\begin{align}
	(b \implies e) \land (\neg b \implies \neg e) &= (b \implies e) \land (\neg \neg b \lor \neg e) \\
	 &= (b \implies e) \land (b \lor \neg e) \\
	 &= (b \implies e) \land (\neg e \lor b) \\
	 &= (b \implies e) \land (e \implies b) \\
	 &= b \iff e \\
\end{align}
$$

<!-- katex does not support labeling align equations, so I have to manually refer to lines -->

At $(1)$ we use the rule $(b \implies e) \equiv (\neg b \lor e)$. In $(2)$ we cancel out two negations. In $(3)$ we swap logical or's operands (we can do that, logical or is commutative). Then we use the implication rule in $(4)$ and finally we use the definition of iff in $(5)$, namely $(b \iff e) \equiv ((b \implies e) \land (e \implies b))$.

This means that parentheses are balanced if and only if they form a valid Dart paren expression. Normally one would prove this by proving both implications, but here instead we will prove it by showing that the language of all balanced parentheses is equal to the language of all valid Dart paren expression. Equivalently, we will show that the grammars used to generate both are the same.

Let $B$ be the language of all balanced parentheses and let $G_b$ be its grammar (ie. the language generated by $G_b$ is $B$: $L(G_b) = B$). Similarly, let $E$ be the language of all valid Dart paren expressions and let $G_e$ be its grammar (ie. the language generated by $G_e$ is $E$: $L(G_e) = E$).

### $G_b$ grammar

Let us start by showing $G_b$'s productions:

$$
\begin{aligned}
	S &\to A \text{ '(' } A \text{ ')'} \\
	A &\to A \text{ '(' } A \text{ ')'} \quad | \quad \varepsilon \\
\end{aligned}
$$

$S$ being the initial symbol of grammar, we can use it to derive every possible balanced string. The parentheses are always balanced (productions introduce parentheses in pairs), can be nested, and can appear side to side.

We can still simplify it a bit by getting rid of the $A$ production. The distinction between $S$ and $A$ exists only to disallow the empty string from being part of the language. To do that we will do a so called _"elimination of epsilon productions"_. This works by inlining cases where one would use the epsilon production:

$$
\begin{aligned}
	S &\to A \text{ '(' } A \text{ ')'} \quad | \quad \text{'(' } A \text{ ')'} \quad | \quad A \text{ '(' ')'} \quad | \quad \text{'(' ')'} \\
	A &\to A \text{ '(' } A \text{ ')'} \quad | \quad \text{'(' } A \text{ ')'} \quad | \quad A \text{ '(' ')'} \quad | \quad \text{'(' ')'} \\
\end{aligned}
$$

This results in two identical productions, so we can just stick to $S$:

$$
	S \to S \text{ '(' } S \text{ ')'} \quad | \quad \text{'(' } S \text{ ')'} \quad | \quad S \text{ '(' ')'} \quad | \quad \text{'(' ')'}
$$

### $G_e$ grammar

For $G_e$ we will define more productions, each encoding some semantics of a Dart paren expression.

First of all, we can generate the empty record

$$
	\text{Record} \to \text{'(' ')'}
$$

but we also can group any expression

$$
	\text{Group} \to \text{'(' } \text{Expression} \text{ ')'}
$$

but we can also invoke any expression (because every expression evaluates to an empty record), possibly with a single argument which is also an expression

$$
	\text{Invoke} \to \text{Expression} \text{ '(' ')'} \quad | \quad \text{Expression} \text{ '(' } \text{Expression} \text{ ')'}
$$

which concludes the three different uses of parentheses. The main production is:

$$
	\text{Expression} \to \text{Record} \quad | \quad \text{Group} \quad | \quad \text{Invoke}
$$

### $G_b \stackrel{?}{=} G_e$

We have $G_b$ and $G_e$. It is time to show that these are in fact equivalent. Lets firstly inline the whole $\text{Expression}$ production:

$$
\begin{aligned}
	\text{Expression} \to & \\
		& \text{'(' ')'} \\
		&| \quad \text{'(' } \text{Expression} \text{ ')'} \\
		&| \quad \text{Expression} \text{ '(' ')'} \quad | \quad \text{Expression} \text{ '(' } \text{Expression} \text{ ')'} \\
\end{aligned}
$$

And... That's it. Replacing $\text{Expression}$ with $S$ we can see that both productions are exactly the same. Thus, $G_b = G_e$, hence $B = E$, hence $b \iff e$ $\square$.

> I made a subtle assumption here: the grammar presented for both languages is correct. At no point did I prove that the presented grammars actually generate the languages in question.

These languages (or at this point, "this language") is not regular. One insightful consequence is that you cannot determine if a string of parentheses is balanced using a regular expression. The language is one class higher, it is context free (which is trivially proven by previously writing its context free grammar). Sketch of the proof that it is not regular: using the contraposition of the pumping lemma we consider the word $(^N)^N$ which is in the language, but pumping it only ever removes/adds open parenthesis making the string imbalanced which renders it outside of the language.

---

- Discussion on [Reddit](https://www.reddit.com/r/programming/comments/1339oal/solving_balanced_parentheses_problem_using_darts)
- Discussion on [Hacker news](https://news.ycombinator.com/item?id=35758247)
- Contribute corrections on [Github](https://github.com/shilangyu/balanced-parentheses-dart-3)
