////
//// * **Types**
////    * [`Parser`](#Parser)
////    * [`Error`](#Error)
//// * **Primitive parsers**
////    * [`any`](#any)
////    * [`eof`](#eof)
////    * [`string`](#string)
////    * [`spaces`](#spaces)
////    * [`whitespace`](#whitespace)
//// * **Working with wrapper types**
////    * [`optional`](#optional)
////    * [`from_option`](#from_option)
////    * [`from_result`](#from_result)
//// * **Ignoring input**
////    * [`succeed`](#succeed)
////    * [`succeed2`](#succeed2)
////    * [`succeed3`](#succeed3)
////    * [`succeed4`](#succeed4)
////    * [`fail`](#fail)
////    * [`fail_with`](#fail_with)
//// * **Chaining parsers**
////    * [`keep`](#keep)
////    * [`drop`](#drop)
//// * **Combinators**
////    * [`map`](#map)
////    * [`map2`](#map2)
////    * [`then`](#then)
////    * [`lazy`](#lazy)
////    * [`one_of`](#one_of)
//// * **Predicate parsers**
////    * [`take_if`](#take_if)
////    * [`take_while`](#take_while)
////    * [`take_if_and_while`](#take_if_and_while)
////

import gleam/bool.{Bool}
import gleam/float.{Float}
import gleam/function
import gleam/int.{Int}
import gleam/list.{Continue, Stop}
import gleam/option.{None, Option, Some}
import gleam/pair
import gleam/result.{Result}
import gleam/string.{String}

// TYPES -----------------------------------------------------------------------
/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam_simple_parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// A `Parser` is something that takes a string and attempts to transform it
/// into something else, often consuming some or all of the input in the process.
///
/// Parsers can be combined (that's why they're called parser combinators) to
/// parse more complex structures. You could write a JSON parser, or a CSV parser,
/// or even do fancy things like parsing and evaluating simple maths expressions.
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub opaque type Parser(a) {
  Parser(fn(String) -> Result(#(a, String), Error))
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam_simple_parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// A [`Parser`](#Parser) might fail for a number of reasons, so we enumerate
/// them here. The `Custom` constructor is useful when used in combination with
/// [`then`](#then) to give an explanation of why the parser is failing.
///
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub type Error {
  BadParser(String)
  Custom(String)
  EOF
  Expected(String, got: String)
  UnexpectedInput(String)
}

// RUNNING PARSERS -------------------------------------------------------------
/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Run a parser and get back its result. If the supplied parser doesn't entirely
/// consume its input, the remaining string is dropped, never to be seen again.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser
///
///     pub fn example () {
///         let parser = parser.any() |> parser.map(string.repeat(5))
///
///         parser.run("Hello world", parser)
///             |> should.equal(Ok("HHHHH"))
///
///         parser.run("", parser)
///             |> should.equal(Error(parser.EOF))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn run(input: String, parser: Parser(a)) -> Result(a, Error) {
  runwrap(parser, input)
  |> result.map(pair.first)
}

/// A portmanteau of "run" and "unwrap", not "run" and "wrap". Unwraps a parser
/// function and then runs it against some input. Used internally to compensate
/// for the lack of function-argument pattern matching. 
fn runwrap(parser: Parser(a), input: String) -> Result(#(a, String), Error) {
  let Parser(p) = parser
  p(input)
}

// BASIC PARSERS ---------------------------------------------------------------
/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam_simple_parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Ignore the input string and succeed with the given value. Commonly used in
/// combination with [`keep`](#keep) and [`drop`](#drop) by passing in a _function_
/// to succeed and then using [`keep`](#keep) to call that function with the
/// result of another parser. 
///
/// If that sounds a bit baffling, see the example below. It is a rewrite of
/// the example used for [`Parser`](#Parser) but one that is able to parse
/// _and ignore_ leading whitespace from the input.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser
///
///     pub fn example () {
///         let parser = parser.succeed(string.repeat(5))
///             |> parser.drop(parser.spaces())
///             |> parser.keep(parser.any())
///
///         parser.run("Hello world", parser)
///             |> should.equal(Ok("HHHHH"))
///
///         parser.run("   Hello world", parser)
///             |> should.equal(Ok("HHHHH"))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn succeed(value: a) -> Parser(a) {
  Parser(fn(input) { Ok(#(value, input)) })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Like [`succeed`](#succeed) but for a function that takes four arguments.
/// Functions in Gleam aren't automatically _curried_ like they are in languages
/// like Elm or Haskell, and that is problematic for our [`succeed`](#succeed)
/// parser to work correctly. To address this, [`succeed2`](#succeed2) takes a
/// function expecting **two** arguments, and calls `function.curry2` to turn
/// it into a sequence functions that are expecting one argument.
///
/// You could implement this yourself by doing `function.curry2(f) |> parser.succeed`
/// where `f` is the two-argument function you want to use.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser
///
///     pub fn example () {
///         let is_not_space = fn (c) { c != " " }
///         let parser = parser.succeed2(string.append)
///             |> parser.keep(parser.take_while(is_not_space))
///             |> parser.drop(parser.spaces())
///             |> parser.keep(parser.take_while(is_not_space))
///
///         parser.run("Hello world", parser)
///             |> should.equal(Ok("Helloworld"))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn succeed2(f: fn(a, b) -> c) -> Parser(fn(a) -> fn(b) -> c) {
  function.curry2(f)
  |> succeed
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Like [`succeed`](#succeed) but for a function that takes four arguments.
/// Functions in Gleam aren't automatically _curried_ like they are in languages
/// like Elm or Haskell, and that is problematic for our [`succeed`](#succeed)
/// parser to work correctly. To address this, [`succeed3`](#succeed3) takes a
/// function expecting **three** arguments, and calls `function.curry4` to turn
/// it into a sequence functions that are expecting one argument.
///
/// For an example of how this is used, take a look at the examples given for
/// [`succeed`](#succeed) and [`succeed2`](#succeed2).
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn succeed3(f: fn(a, b, c) -> d) -> Parser(fn(a) -> fn(b) -> fn(c) -> d) {
  function.curry3(f)
  |> succeed
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Like [`succeed`](#succeed) but for a function that takes four arguments.
/// Functions in Gleam aren't automatically _curried_ like they are in languages
/// like Elm or Haskell, and that is problematic for our [`succeed`](#succeed)
/// parser to work correctly. To address this, [`succeed4`](#succeed4) takes a
/// function expecting **four** arguments, and calls `function.curry4` to turn
/// it into a sequence functions that are expecting one argument.
///
/// For an example of how this is used, take a look at the examples given for
/// [`succeed`](#succeed) and [`succeed2`](#succeed2).
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn succeed4(
  f: fn(a, b, c, d) -> e,
) -> Parser(fn(a) -> fn(b) -> fn(c) -> fn(d) -> e) {
  function.curry4(f)
  |> succeed
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Create a [`Parser`](#Parser) that always fails regardless of the input. This
/// uses the `Custom` error constructor of the [`Error`](#Error) type. If you'd
/// like to return a more specific error, you can look at [`fail_with`](#fail_with)
/// instead.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import gleam/string
///     import string/parser.{Custom}
///
///     pub fn example () {
///         let is_not_space = fn (c) { c != " " }
///         let parse_four_letter_word = fn (s) {
///             case string.length(s) == 4 {
///                 True -> 
///                     parser.succeed(s)
///
///                 False -> 
///                     parser.fail("Expected a four letter word.")
///             }
///         }
///         let parser = parser.take_while(is_not_space)
///             |> parser.then(parse_four_letter_word)
///
///         parser.run("Hello world", parser)
///             |> should.equal(Error(Custom("Expected a four letter word.")))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn fail(message: String) -> Parser(a) {
  Parser(fn(_) { Error(Custom(message)) })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Create a [`Parser`](#Parser) that always fails regardless of the input. Unlike
/// [`fail`](#fail), you can use any of the constructors for the [`Error`](#Error)
/// type here.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import gleam/string
///     import string/parser.{Expected}
///
///     pub fn example () {
///         let is_not_space = fn (c) { c != " " }
///         let parse_four_letter_word = fn (s) {
///             case string.length(s) == 4 {
///                 True -> 
///                     parser.succeed(s)
///
///                 False ->
///                     parser.fail_with(Expected("A four letter word", got: s))
///             }
///         }
///         let parser = parser.take_while(is_not_space)
///             |> parser.then(parse_four_letter_word)
///
///         parser.run("Hello world", parser)
///             |> should.equal(Error(Expected("A four letter word", got: s))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn fail_with(error: Error) -> Parser(a) {
  Parser(fn(_) { Error(error) })
}

// PRIMITIVE PARSERS -----------------------------------------------------------
/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Parse a single grapheme from the input, it could be anything! If the input
/// is an empty string, this will _fail_ with the `EOF` error. 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser
///
///     pub fn example () {
///         let parser = parser.any()
///
///         parser.run("Hello world", parser)
///             |> should.equal(Ok("H"))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn any() -> Parser(String) {
  Parser(fn(input) {
    string.pop_grapheme(input)
    |> result.replace_error(EOF)
  })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// This parser only succeeds when the input is an empty string. Why is that
/// useful? You can use this in combination with your other parsers to ensure
/// that you've consumed **all** the input.  
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/function
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{Expected}
///
///     pub fn example () {
///         let parser = parser.succeed(function.identity)
///             |> parser.keep(parser.string("Hello"))
///             |> parser.drop(parser.eof())
///
///         parser.run("Hello", parser)
///             |> should.equal(Ok("Hello"))
///
///         parser.run("Hello world", parser)
///             |> should.equal(Error(Expected("End of file", got: " world")))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn eof() -> Parser(Nil) {
  Parser(fn(input) {
    case string.is_empty(input) {
      True -> Ok(#(Nil, input))

      False -> Error(Expected("End of file", got: input))
    }
  })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Parse an exact string from the input. If you were writing a programming
/// language parser, you might use this to parse keywords or symbols.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import gleam/string.{String}
///     import string/parser.{Expected}
///
///     type VariableDeclaration {
///         VariableDeclaration(var: String)
///     }
///
///     pub fn example () {
///         let is_not_space = fn (c) { c != " " }
///         let parser = parser.succeed(VariableDeclaration)
///             |> parser.drop(parser.string("var"))
///             |> parser.drop(parser.spaces())
///             |> parser.keep(parser.take_while(is_not_space))
///             |> parser.drop(parser.string(";"))
///
///         parser.run("var x;", parser)
///             |> should.equal(Ok(VariableDeclaration(var: "x")))
///
///         parser.run("let x;", parser)
///             |> should.equal(Error(Expected("var", got: "let x;")))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn string(value: String) -> Parser(String) {
  let length = string.length(value)
  let expect = string.concat(["A string that starts with '", value, "'"])

  Parser(fn(input) {
    case string.starts_with(input, value) {
      True -> Ok(#(value, string.drop_left(input, length)))

      False -> Error(Expected(expect, got: input))
    }
  })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Parse **zero or more** spaces in sequence. 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{Expected}
///
///     pub fn example () {
///         let parser = parser.succeed("No spaces required")
///             |> parser.drop(parser.string("Hello"))
///             |> parser.drop(parser.spaces())
///             |> parser.drop(parser.string("world"))
///
///         parser.run("Helloworld", parser)
///             |> should.equal(Ok("No spaces required"))
///
///         let is_space = fn (c) { c == " " }
///         let parser = parser.succeed("At least one space required")
///             |> parser.drop(parser.string("Hello"))
///             |> parser.drop(parser.take_if(is_space))
///             |> parser.drop(parser.spaces())
///             |> parser.drop(parser.string("world"))
///
///         parser.run("Helloworld", parser)
///             |> should.equal(Error(Expected(" ", got: "world")))
///
///         parser.run("Hello world", parser)
///             |> should.equal(Ok("At least one space required"))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn spaces() -> Parser(Nil) {
  take_while(fn(c) { c == " " })
  |> map(fn(_) { Nil })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Parse **zero or more** whitespace characters in sequence. Unlike [`spaces`](#spaces),
/// this parser also consumes newlines and tabs as well.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Nil, Ok, Error}
///     import gleam/should
///     import string/parser
///
///     pub fn example () {
///         let parser = parser.succeed(Nil)
///             |> parser.drop(parser.string("Hello"))
///             |> parser.drop(parser.whitespace())
///             |> parser.drop(parser.string("world"))
///
///         let input = "hello
///                      world"
///
///         parser.run(input, parser)
///             |> should.equal(Ok(Nil))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn whitespace() -> Parser(Nil) {
  take_while(fn(c) { c == " " || c == "\t" || c == "\n" })
  |> map(fn(_) { Nil })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// A simple integer parser. Under the hood it uses
/// [`gleam/int.parse`](https://hexdocs.pm/gleam_stdlib/gleam/int/#parse) but
/// it will only parse simple ints, no octals or hexadecimals and no scientific
/// notation either.
///
/// If you need something yourself you can always build it using the combinators
/// here, and [pull requests are always welcome](https://github.com/pd-andy/gleam-string-parser/pulls).
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{Expected}
///
///     pub fn example () {
///         let parser = parser.int() 
///             |> parser.map(fn (x) { x * 2 })
///
///         parser.run("25", parser)
///             |> should.equal(Ok(50))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn int() -> Parser(Int) {
  let is_digit = fn(c) {
    case c {
      "0" | "1" | "2" | "3" | "4" -> True
      "5" | "6" | "7" | "8" | "9" -> True
      _ -> False
    }
  }

  take_if_and_while(is_digit)
  |> map(int.parse)
  |> then(from_result)
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{Expected}
///
///     pub fn example () {
///
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn float() -> Parser(Float) {
  let is_digit = fn(c) {
    case c {
      "0" | "1" | "2" | "3" | "4" -> True
      "5" | "6" | "7" | "8" | "9" -> True
      _ -> False
    }
  }

  succeed2(fn(x, y) { string.concat([x, ".", y]) })
  |> keep(take_if_and_while(is_digit))
  |> drop(string("."))
  |> keep(take_if_and_while(is_digit))
  |> map(float.parse)
  |> then(from_result)
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Take a [`Parser`](#Parser) and turn it into an optional parser. If it fails,
/// instead of the parser reporting an error, we carry on and succeed with `None`.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{Expected}
///
///     pub fn example () {
///
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn optional(parser: Parser(a)) -> Parser(Option(a)) {
  Parser(fn(input) {
    runwrap(parser, input)
    |> result.map(pair.map_first(_, Some))
    |> result.unwrap(#(None, input))
    |> Ok
  })
}

// UNWRAPPING OTHER TYPES ------------------------------------------------------
/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{Expected}
///
///     pub fn example () {
///
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn from_option(value: Option(a)) -> Parser(a) {
  option.map(value, succeed)
  // TODO: This needs to be much nicer.
  |> option.unwrap(fail_with(UnexpectedInput("")))
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{Expected}
///
///     pub fn example () {
///
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn from_result(value: Result(a, x)) -> Parser(a) {
  result.map(value, succeed)
  // TODO: This needs to be much nicer.
  |> result.unwrap(fail_with(UnexpectedInput("")))
}

// PREDICATE PARSERS -----------------------------------------------------------
/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Pop a grapheme off the input string and test it against some predicate function.
/// If it passes, pop the next grapheme off and so on until the predicate test
/// fails. Join all the passing graphemes back together into a single string and
/// succeed with that result.
///
/// **This parser always succeeds**. If you use `[`take_while`](#take_while) to
/// parse an empty string, or if no graphemes pass the predicate, this will succeed
/// with an empty string of its own. 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser
///
///     pub fn example () {
///         let is_digit = fn (c) {
///             case c {
///                 "0" | "1" | "2" | "3" | "4" -> True
///                 "5" | "6" | "7" | "8" | "9" -> True
///                 _ -> False
///             }
///         }
///         let parser = parser.take_while(is_digit)
///
///         parser.run("1337", parser)
///             |> should.equal(Ok("1337"))
///
///         parser.run("Hello world", parser)
///             |> should.equal(Ok(""))
///
///         parser.run("", parser)
///             |> should.equal(Ok(""))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn take_while(predicate: fn(String) -> Bool) -> Parser(String) {
  let recurse = fn(c) {
    take_while(predicate)
    |> map(string.append(c, _))
  }

  Parser(fn(input) {
    case string.pop_grapheme(input) {
      Ok(#(char, rest)) ->
        case predicate(char) {
          True -> runwrap(recurse(char), rest)
          False -> Ok(#("", input))
        }

      Error(Nil) -> Ok(#("", ""))
    }
  })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// Pop a grapheme off the input and test it against some predicate function. If
/// it passes then succeed with that grapheme, otherwise **fail** with the
/// `UnexpectedInput` constructor of the [`Error`](#Error) type. This is in
/// contrast to [`take_while`](#take_while) which will always succeed even if no
/// graphemes pass the predicate.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{UnexpectedInput, EOF}
///
///     pub fn example () {
///         let is_digit = fn (c) {
///             case c {
///                 "0" | "1" | "2" | "3" | "4" -> True
///                 "5" | "6" | "7" | "8" | "9" -> True
///                 _ -> False
///             }
///         }
///         let parser = parser.take_while(is_digit)
///
///         parser.run("1337", parser)
///             |> should.equal(Ok("1"))
///
///         parser.run("Hello world", parser)
///             |> should.equal(Error(UnexpectedInput))
///
///         parser.run("", parser)
///             |> should.equal(Error(EOF))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn take_if(predicate: fn(String) -> Bool) -> Parser(String) {
  Parser(fn(input) {
    case string.pop_grapheme(input) {
      Ok(#(char, rest)) ->
        case predicate(char) {
          True -> Ok(#(char, rest))
          False -> Error(UnexpectedInput(input))
        }

      Error(Nil) -> Error(EOF)
    }
  })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// It's incredibly common to combine [`take_if`](#take_if) and [`take_while`](#take_while)
/// to create a parser that consumes _one or more_ graphemes. This does just that!
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{UnexpectedInput, EOF}
///
///     pub fn example () {
///         let is_digit = fn (c) {
///             case c {
///                 "0" | "1" | "2" | "3" | "4" -> True
///                 "5" | "6" | "7" | "8" | "9" -> True
///                 _ -> False
///             }
///         }
///         let parser = parser.take_if_and_while(is_digit)
///
///         parser.run("1337", parser)
///             |> should.equal(Ok("1337"))
///
///         parser.run("1", parser)
///             |> should.equal(Ok("1"))
///
///         parser.run("Hello world", parser)
///             |> should.equal(Error(UnexpectedInput))
///
///         parser.run("", parser)
///             |> should.equal(Error(EOF))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn take_if_and_while(predicate: fn(String) -> Bool) -> Parser(String) {
  succeed2(string.append)
  |> keep(take_if(predicate))
  |> keep(take_while(predicate))
}

// COMBINATORS -----------------------------------------------------------------
/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// A combinator that can take the result of one parser, and use it to create
/// a new parser. This follows the same pattern as 
/// [`gleam/option.then`](https://hexdocs.pm/gleam_stdlib/gleam/option/#then) or
/// [`gleam/result.then`](https://hexdocs.pm/gleam_stdlib/gleam/option/#then).
///
/// This is useful if you want to transform or validate a parsed value and fail
/// if something is wrong.
///
/// <details>
///     import gleam/int
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser.{UnexpectedInput}
///
///     pub fn example () {
///         let is_digit = fn (c) {
///             case c {
///                 "0" | "1" | "2" | "3" | "4" -> True
///                 "5" | "6" | "7" | "8" | "9" -> True
///                 _ -> False
///             }
///         }
///         let parse_digits = fn (digits) {
///             case int.parse(digits) {
///                 Ok(num) ->
///                     parser.succeed(num)
///
///                 Error(_) ->
///                     parser.fail_with(UnexpectedInput)
///         }
///
///         let parser = parser.take_while(is_digit)
///             |> parser.then(parse_digits)
///
///         parser.run("1337", parser)
///             |> should.equal(Ok(1337))
///
///         parser.run("Hello world", parser)
///             |> should.equal(Error(UnexpectedInput))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn then(parser: Parser(a), f: fn(a) -> Parser(b)) -> Parser(b) {
  Parser(fn(input) {
    runwrap(parser, input)
    |> result.then(fn(result) {
      let #(value, next_input) = result

      runwrap(f(value), next_input)
    })
  })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// A combinator that transforms a parsed value by applying a function to it and
/// returning a new [`Parser`](#Parser) with that transformed value. This follows
/// the same pattern as [`gleam/option.map`](https://hexdocs.pm/gleam_stdlib/gleam/option/#map)
/// or [`gleam/result.map`](https://hexdocs.pm/gleam_stdlib/gleam/result/#map).
///
/// <details>
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser
///
///     pub fn example () {
///         let parser = parser.any() |> parser.map(string.repeat(5))
///
///         parser.run("Hello world", parser)
///             |> should.equal(Ok("HHHHH"))
///
///         parser.run("", parser)
///             |> should.equal(Error(parser.EOF))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn map(parser: Parser(a), f: fn(a) -> b) -> Parser(b) {
  then(
    parser,
    fn(a) {
      f(a)
      |> succeed
    },
  )
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
///
///
/// <details>
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import string/parser
///
///     pub fn example () {
///
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn lazy(parser: fn() -> Parser(a)) -> Parser(a) {
  Parser(fn(input) { runwrap(parser(), input) })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// A combinator that combines two parsed values by applying a function to them
/// both and returning a new [`Parser`](#Parser) containing the combined value.
///
/// Fun fact, [`keep`](#keep) is defined using this combinator. 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import gleam/string
///     import string/parser
///
///     pub fn example () {
///         let parser = parser.map2(
///             parser.string("Hello"),
///             parser.string("world"),
///             fn (hello, world) {
///                 string.concat([ hello, " ", world ])
///             }
///         )
///
///         parser.run("Helloworld", parser)
///             |> should.equal(Ok("Hello world"))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn map2(
  parser_a: Parser(a),
  parser_b: Parser(b),
  f: fn(a, b) -> c,
) -> Parser(c) {
  then(parser_a, fn(a) { map(parser_b, fn(b) { f(a, b) }) })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// A combinator that tries a list of parsers in sequence until one succeeds. If
/// you pass in an empty list this parser will fail with the `BadParser` constructor
/// of the [`Error`](#Error) type.
///
/// <details>
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import gleam/string
///     import string/parser
///
///     pub fn example () {
///         let beam_lang = parser.oneOf(
///             parser.string("Erlang"),
///             parser.string("Elixir"),
///             parser.string("Gleam")
///         )
///         let parser = parser.succeed2(string.append)
///             |> parser.keep(parser.string("Hello "))
///             |> parser.keep(beam_lang)
///
///         parser.run("Hello Gleam", parser)
///             |> should.equal(Ok("Hello Gleam"))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn one_of(parsers: List(Parser(a))) -> Parser(a) {
  let initial_error =
    Error(BadParser(
      "The list of parsers supplied to one_of is empty, I will always fail!",
    ))

  Parser(fn(input) {
    list.fold_until(
      parsers,
      initial_error,
      fn(parser, _) {
        let result = runwrap(parser, input)

        case result.is_ok(result) {
          True -> Stop(result)

          False -> Continue(result)
        }
      },
    )
  })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
///
///
/// <details>
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import gleam/string
///     import string/parser
///
///     pub fn example () {
///
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn many(parser: Parser(a), separator: Parser(b)) -> Parser(List(a)) {
  let recurse = fn(value) {
    many(parser, separator)
    |> map(fn(vals) { [value, ..vals] })
  }

  Parser(fn(input) {
    case runwrap(
      parser
      |> drop(separator),
      input,
    ) {
      Ok(#(value, rest)) -> runwrap(recurse(value), rest)

      Error(_) ->
        case runwrap(parser, input) {
          Ok(#(value, rest)) -> Ok(#([value], rest))
          Error(_) -> Ok(#([], input))
        }
    }
  })
}

// CHAINING PARSERS ------------------------------------------------------------
/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// This is one of two combinators used in conjuction with [`succeed`](#succeed)
/// (the other being [`drop`](#drop)) that come together to form a nice pipeline
/// API for parsing.
///
/// The first argument is a _function_ wrapped up in a [`Parser`](#Parser), usually
/// created using [`succeed`](#succeed). The second argument is a parser for the
/// value we want to keep. This parser combines the two by applying that value 
/// to the function.
///
/// When you use one of the `succeed{N}` functions such as [`succeed2`](#succeed)
/// you'll get back a [`Parser`] for a function. You might then work out that you
/// can use `keep` again, and voila we have a neat declarative pipline parser
/// that describes what results we want to keep and how. 
///
/// The explanation is a bit wordy and compicated, but its useage is intuitive.
/// If you've been looking at the rest of the docs for this package, you'll already
/// have seen [`keep`](#keep) used all over the place.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import gleam/string.{String}
///     import gleam/int
///     import string/parser.{UnexpectedInput}
///
///     pub fn example () {
///         let digit_parser = parser.any() |> parser.then(fn (c) {
///             case int.parse(c) {
///                 Ok(num) -> parser.succeed(num)
///                 Error(_) -> parser.fail_with(UnexpectedInput)
///             }
///         })
///         
///         let parser = parser.succeed2(fn (x, y) { x + y })
///             |> parser.keep(digit_parser)
///             |> parser.drop(parser.spaces())
///             |> parser.drop(parser.string("+"))
///             |> parser.drop(parser.spaces())
///             |> parser.keep(digit_parser)
///
///         parser.run("1 + 3", parser)
///             |> should.equal(Ok(4))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn keep(mapper: Parser(fn(a) -> b), parser: Parser(a)) -> Parser(b) {
  map2(mapper, parser, fn(f, a) { f(a) })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam-string-parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// This is one of two combinators used in conjuction with [`succeed`](#succeed)
/// (the other being [`keep`](#keep)) that come together to form a nice pipeline
/// API for parsing.
///
/// This combinator runs two parsers in sequence, and then keeps the result of
/// the first parser while ignoring the result of the second. This allows us to
/// write parsers that enforce a particular structure from the input without
/// needing to _do_ anything with the result of those structural parsers.
///
/// Think of parsing JSON, for example. We need to parse opening and closing curly
/// braces to know it's a valid object, and we need to parse the separating colon
/// to differentiate between key and value. We need to parse these things, but
/// they're _structural_, we might want to parse a key/value pair into a Gleam
/// tuple; we don't care about the curly braces or colons but we need to know
/// they're there.
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/result.{Ok, Error}
///     import gleam/should
///     import gleam/string.{String}
///     import gleam/int
///     import string/parser.{UnexpectedInput}
///
///     pub fn example () {
///         let digit_parser = parser.any() |> parser.then(fn (c) {
///             case int.parse(c) {
///                 Ok(num) -> parser.succeed(num)
///                 Error(_) -> parser.fail_with(UnexpectedInput)
///             }
///         })
///         
///         let parser = parser.succeed2(fn (x, y) { x + y })
///             |> parser.keep(digit_parser)
///             |> parser.drop(parser.spaces())
///             |> parser.drop(parser.string("+"))
///             |> parser.drop(parser.spaces())
///             |> parser.keep(digit_parser)
///
///         parser.run("1 + 3", parser)
///             |> should.equal(Ok(4))
///     }
/// </details>
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub fn drop(keeper: Parser(a), ignorer: Parser(b)) -> Parser(a) {
  map2(keeper, ignorer, fn(a, _) { a })
}
