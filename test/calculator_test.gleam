import gleam/int.{Int}
import gleam/result
import gleam/should
import simple/parser.{Parser}

pub fn calculator_test () {
    let parser = parser.one_of([
        make_op_parser(Add, "+"),
        make_op_parser(Sub, "-"),
        make_op_parser(Mul, "*"),
        make_op_parser(Divide, "/")
    ])

    parser.run("1 + 2", parser)
        |> result.map(eval)
        |> should.equal(Ok(3))

    parser.run("5    *2", parser)
        |> result.map(eval)
        |> should.equal(Ok(10))

    parser.run("10-2", parser)
        |> result.map(eval)
        |> should.equal(Ok(8))
}


//


type Op {
    Add(Int, Int)
    Sub(Int, Int)
    Mul(Int, Int)
    Divide(Int, Int)
}

fn eval (op: Op) -> Int {
    case op {
        Add(x, y) -> x + y
        Sub(x, y) -> x - y
        Mul(x, y) -> x * y
        Divide(x, y) -> x / y
    }
}


// PARSERS ---------------------------------------------------------------------


fn int_parser () -> Parser(Int) {
    let is_digit = fn (c) {
        case c {
            "0" | "1" | "2" | "3" | "4" -> True
            "5" | "6" | "7" | "8" | "9" -> True
            _ -> False
        }
    }

    parser.take_while(is_digit) 
        |> parser.map(int.parse)
        |> parser.then(fn (num) {
            case num {
                Ok(n) -> 
                    parser.succeed(n)

                Error(_) ->
                    parser.fail("Couldn't parse integer.")
            }
        })
}

fn make_op_parser (constructor: fn (Int, Int) -> Op, symbol: String) -> Parser(Op) {
    parser.succeed2(constructor)
        |> parser.keep(int_parser())
        |> parser.drop(parser.spaces())
        |> parser.drop(parser.string(symbol))
        |> parser.drop(parser.spaces())
        |> parser.keep(int_parser())
}
