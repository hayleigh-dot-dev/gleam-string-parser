import gleam/bool.{Bool}
import gleam/float.{Float}
import gleam/function
import gleam/int
import gleam/list.{List}
import gleam/should
import gleam/string.{String}
import string/parser.{Parser}

// TESTS -----------------------------------------------------------------------
pub fn json_test() {
  let input = "{ \"foo\": 3.14, \"bar\": [ \"hello\", null ] }"
  let ast =
    JsonObject([
      #("foo", JsonNumber(3.14)),
      #("bar", JsonArray([JsonString("hello"), JsonNull])),
    ])

  parser.run(input, json_parser())
  |> should.equal(Ok(ast))
}

// TYPES -----------------------------------------------------------------------
type JSON {
  JsonArray(List(JSON))
  JsonBool(Bool)
  JsonNull
  JsonNumber(Float)
  JsonObject(List(#(String, JSON)))
  JsonString(String)
}

// PARSERS ---------------------------------------------------------------------
fn json_parser() -> Parser(JSON) {
  parser.one_of([
    // We need to use `parser.lazy` here because the array parser (and the
    // object one too) recursively call `json_parser()`. Without lazy this
    // would get stuck in an infinite evaluation loop at runtime!
    parser.lazy(fn() { json_array_parser() }),
    json_bool_parser(),
    json_null_parser(),
    json_number_parser(),
    parser.lazy(fn() { json_object_parser() }),
    json_string_parser(),
  ])
}

fn json_array_parser() -> Parser(JSON) {
  let separator =
    parser.spaces()
    |> parser.drop(parser.string(","))
    |> parser.drop(parser.spaces())

  parser.succeed(function.identity)
  |> parser.drop(parser.string("["))
  |> parser.drop(parser.spaces())
  |> parser.keep(parser.many(json_parser(), separator))
  |> parser.drop(parser.spaces())
  |> parser.drop(parser.string("]"))
  |> parser.map(JsonArray)
}

fn json_bool_parser() -> Parser(JSON) {
  parser.one_of([
    parser.succeed(True)
    |> parser.drop(parser.string("true"))
    |> parser.map(JsonBool),
    parser.succeed(False)
    |> parser.drop(parser.string("false"))
    |> parser.map(JsonBool),
  ])
}

fn json_null_parser() -> Parser(JSON) {
  parser.succeed(JsonNull)
  |> parser.drop(parser.string("null"))
}

fn json_number_parser() -> Parser(JSON) {
  parser.one_of([
    parser.float()
    |> parser.map(JsonNumber),
    parser.int()
    |> parser.map(int.to_float)
    |> parser.map(JsonNumber),
  ])
}

fn json_object_parser() -> Parser(JSON) {
  let pair = fn(a, b) { #(a, b) }

  let separator =
    parser.spaces()
    |> parser.drop(parser.string(","))
    |> parser.drop(parser.spaces())

  let key_parser =
    parser.succeed(function.identity)
    |> parser.drop(parser.string("\""))
    |> parser.keep(parser.take_while(fn(c) { c != "\"" }))
    |> parser.drop(parser.string("\""))

  let key_value_pair =
    parser.succeed2(pair)
    |> parser.keep(key_parser)
    |> parser.drop(parser.string(":"))
    |> parser.drop(parser.spaces())
    |> parser.keep(json_parser())

  parser.succeed(function.identity)
  |> parser.drop(parser.string("{"))
  |> parser.drop(parser.spaces())
  |> parser.keep(parser.many(key_value_pair, separator))
  |> parser.drop(parser.spaces())
  |> parser.drop(parser.string("}"))
  |> parser.map(JsonObject)
}

fn json_string_parser() -> Parser(JSON) {
  parser.succeed(function.identity)
  |> parser.drop(parser.string("\""))
  |> parser.keep(parser.take_while(fn(c) { c != "\"" }))
  |> parser.drop(parser.string("\""))
  |> parser.map(JsonString)
}
