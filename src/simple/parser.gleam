////
////
//// * **Types**
////    * [`Parser`](#Parser)
////    * [`Error`](#Error)
//// * **Ignoring Input**
////    * [`succeed`](#succeed)
////    * [`fail`](#fail)
////    * [`fail_with`](#fail_with)
//// * **Chaining Parsers**
////    * [`keep`](#keep)
////    * [`drop`](#drop)
//// * **Combinators**
////    * [`map`](#map)
////    * [`map2`](#map2)
////    * [`then`](#then)
////    * [`one_of`](#one_of)
//// * **Predicate Parsers**
////    * [`take_if`](#take_if)
////    * [`take_while`](#take_while)
////
////
////

import gleam/bool.{Bool}
import gleam/function
import gleam/list.{Continue, Stop}
import gleam/pair
import gleam/result.{Result, Nil}
import gleam/string.{String}


// TYPES -----------------------------------------------------------------------


/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam_simple_parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
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

/// <div style="text-align: right;">
///     <a href="https://github.com/pd-andy/gleam_simple_parser/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
///
///
/// <div style="text-align: right;">
///     <a href="#">
///         <small>Back to top ↑</small>
///     </a>
/// </div>
///
pub type Parser(a) {
    Parser(fn (String) -> Result(tuple(a, String), Error))
}


// RUNNING PARSERS -------------------------------------------------------------


/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn run (input: String, parser: Parser(a)) -> Result(a, Error) {
    runwrap(parser, input) |> result.map(pair.first)
}

/// A portmanteau of "run" and "unwrap", not "run" and "wrap". Unwraps a parser
/// function and then runs it against some input. Used internally to compensate
/// for the lack of function-argument pattern matching. 
fn runwrap (parser: Parser(a), input: String) -> Result(tuple(a, String), Error) {
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
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn succeed (value: a) -> Parser(a) {
    Parser(fn (input) {
        Ok(tuple(value, input))
    })
}

pub fn succeed2 (f: fn (a, b) -> c) -> Parser(fn (a) -> fn (b) -> c) {
    function.curry2(f) |> succeed
}

pub fn succeed3 (f: fn (a, b, c) -> d) -> Parser(fn (a) -> fn (b) -> fn (c) -> d) {
    function.curry3(f) |> succeed
}

pub fn succeed4 (f: fn (a, b, c, d) -> e) -> Parser(fn (a) -> fn (b) -> fn (c) -> fn (d) -> e) {
    function.curry4(f) |> succeed
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn fail (message: String) -> Parser(a) {
    Parser(fn (_) {
        Error(Custom(message))
    })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn fail_with (error: Error) -> Parser(a) {
    Parser(fn (_) {
        Error(error)
    })
}


// PRIMITIVE PARSERS -----------------------------------------------------------

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn any () -> Parser(String) {
    Parser(fn (input) {
        string.pop_grapheme(input)
            |> result.replace_error(EOF)
    })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn eof () -> Parser(Nil) {
    Parser(fn (input) {
        case string.is_empty(input) {
            True -> 
                Ok(tuple(Nil, input))

            False -> 
                Error(Expected("End of file", got: input))
        }
    })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn string (value: String) -> Parser(String) {
    let length = string.length(value)
    let expect = string.concat([ "A string that starts with '", value, "'"])

    Parser(fn (input) {
        case string.starts_with(input, value) {
            True ->
                Ok(tuple(value, string.drop_left(input, length)))
            
            False ->
                Error(Expected(expect, got: input))
        }
    })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn spaces () -> Parser(Nil) {
    take_while(fn (c) { c == " "})
        |> map(fn (_) { Nil })
}


// PREDICATE PARSERS -----------------------------------------------------------


/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn take_while (predicate: fn (String) -> Bool) -> Parser(String) {
    let recurse = fn (c) {
        take_while(predicate) 
            |> map (string.append(c, _))
    }

    Parser(fn (input) {
        case string.pop_grapheme(input) {
            Ok(tuple(char, rest)) ->
                case predicate(char) {
                    True ->
                        runwrap(recurse(char), rest)
                        
                    False ->
                        Ok(tuple("", input))
                }
            
            Error(Nil) ->
                Ok(tuple("", ""))
        }
    })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn take_if (predicate: fn (String) -> Bool) -> Parser(String) {
    Parser(fn (input) {
        case string.pop_grapheme(input) {
            Ok(tuple(char, rest)) ->
                case predicate(char) {
                    True ->
                        Ok(tuple(char, rest))
                        
                    False ->
                        Error(UnexpectedInput(input))
                }
            
            Error(Nil) ->
                Error(EOF)
        }
    })
}


// COMBINATORS -----------------------------------------------------------------


/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn then (parser: Parser(a), f: fn (a) -> Parser(b)) -> Parser(b) {
    Parser(fn (input) {
        runwrap(parser, input) |> result.then(fn (result) {
            let tuple(value, next_input) = result

            runwrap(f(value), next_input)
        })
    })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn map (parser: Parser(a), f: fn (a) -> b) -> Parser(b) {
    then(parser, fn (a) { f(a) |> succeed })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn map2 (parser_a: Parser(a), parser_b: Parser(b), f: fn (a, b) -> c) -> Parser(c) {
    then(parser_a, fn (a) { 
        map(parser_b, fn (b) { 
            f(a, b) 
        }) 
    })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn one_of (parsers: List(Parser(a))) -> Parser(a) {
    let initial_error = Error(BadParser(
        "The list of parsers supplied to one_of is empty, I will always fail!"
    ))

    Parser(fn (input) {
        list.fold_until(parsers, initial_error, fn (parser, _) {
            let result = runwrap(parser, input)

            case result.is_ok(result) {
                True ->
                    Stop(result)

                False ->
                    Continue(result)
            }
        })
    })
}


// CHAINING PARSERS ------------------------------------------------------------


/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn keep (mapper: Parser(fn (a) -> b), parser: Parser(a)) -> Parser(b) {
    map2(mapper, parser, fn (f, a) { 
        f(a) 
    })
}

/// <div style="text-align: right;">
///     <a href="https://github.com/xxx/yyy/issues">
///         <small>Spot a typo? Open an issue!</small>
///     </a>
/// </div>
///
/// 
///
/// <details>
///     <summary>Example:</summary>
///
///     import gleam/should
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
pub fn drop (keeper: Parser(a), ignorer: Parser(b)) -> Parser(a) {
    map2(keeper, ignorer, fn (a, _) { 
        a 
    })
}
