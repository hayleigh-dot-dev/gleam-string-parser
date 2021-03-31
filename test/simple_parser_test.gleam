import gleam/function
import gleam/int
import gleam/io
import gleam/result.{Nil}
import gleam/should
import gleam/string
import string/parser.{BadParser}


// IGNORING INPUT --------------------------------------------------------------

type Test {
    CurryTest(String, String)
}


pub fn succeed_test () {
    let parser = parser.succeed("Hello")

    case parser.run("foobarbaz", parser) {
        Ok(result) -> 
            result |> should.equal("Hello")

        Error(_) -> 
            should.fail()
    }

    let parser = parser.succeed( function.curry2(CurryTest) )
        |> parser.keep(parser.any())
        |> parser.keep(parser.any())

    parser.run("Hi", parser)
        |> should.equal(Ok(CurryTest("H", "i")))
}


// BASIC PARSERS ---------------------------------------------------------------


pub fn any_test () {
    let parser = parser.any()

    case parser.run("Hello world", parser) {
        Ok(result) -> 
            result |> should.equal("H")

        Error(_) -> 
            should.fail()
    }
}

pub fn eof_test () {
    let parser = parser.eof()

    case parser.run("", parser) {
        Ok(result) -> 
            result |> should.equal(Nil)

        Error(_) -> 
            should.fail()
    }
}


// PRIMITIVE PARSERS -----------------------------------------------------------


pub fn string_test () {
    let parser = parser.string("Hello")

    case parser.run("Hello world", parser) {
        Ok(result) -> 
            result |> should.equal("Hello")

        Error(_) -> 
            should.fail()
    }
}


// COMBINATORS -----------------------------------------------------------------


pub fn map_test () {
    let parser = parser.any() |> parser.map(string.repeat(_, 2))

    case parser.run("Hello world", parser) {
        Ok(result) -> 
            result |> should.equal("HH")

        Error(_) -> 
            should.fail()
    }
}

pub fn then_test () {
    let digit_parser = fn (digit) {
        case int.parse(digit) {
            Ok(d) -> 
                parser.succeed(d)

            Error(_) ->
                parser.fail_with(parser.Expected("a digit", got: digit))
        }
    }
    let parser = parser.any() |> parser.then(digit_parser)

    case parser.run("1", parser) {
        Ok(result) ->
            result |> should.equal(1)

        Error(_) ->
            should.fail()
    }
}

pub fn one_of_test () {
    let parser = parser.one_of([
        parser.string("Hello"),
        parser.string("world")
    ])

    case parser.run("Hello", parser) {
        Ok(result) ->
            result |> should.equal("Hello")

        Error(_) ->
            should.fail()
    }

    case parser.run("world", parser) {
        Ok(result) ->
            result |> should.equal("world")

        Error(_) ->
            should.fail()
    }

    // When an empty list is given to one_of we expect it to fail with a handy
    // message reminding us the list should be non-empty.
    case parser.run("Hello world", parser.one_of([])) {
        Ok(_) ->
            should.fail()

        Error(BadParser(message)) ->
            message |> should.equal("The list of parsers supplied to one_of is empty, I will always fail!")

        _ ->
            should.fail()
    }
}


// CHAINING PARSERS ------------------------------------------------------------


pub fn keep_test () {
    let parser =
        parser.succeed( function.curry2(string.append) )
            |> parser.keep(parser.any())
            |> parser.keep(parser.any())

    case parser.run("Hello world", parser) {
        Ok(result) ->
            result |> should.equal("He")

        Error(_) ->
            should.fail()
    }
}

pub fn drop_test () {
    let parser =
        parser.succeed( function.identity )
            |> parser.drop( parser.any() )
            |> parser.drop( parser.any() )
            |> parser.keep( parser.any() )

    case parser.run("Hello world", parser) {
        Ok(result) ->
            result |> should.equal("l")

        Error(_) ->
            should.fail()
    }
}


// PREDICATE PARSERS -----------------------------------------------------------


pub fn take_while_test () {
    let parser = 
        parser.succeed(function.identity)
            |> parser.drop( parser.take_while(fn (c) { c != " " }) )
            |> parser.drop( parser.any() )
            |> parser.keep( parser.take_while(fn (c) { c != " " }) )


    case parser.run("Hello world", parser) {
        Ok(result) -> {
            result |> should.equal("world")
        }

        Error(_) ->
            should.fail()
    }
}
