import gleam/float
import gleam/result
import gleeunit/should
import string/parser.{Parser}
import gleam/list

// TESTS -----------------------------------------------------------------------
pub fn currency_test() {
  let to_usd = fn(currency: Currency) -> Float {
    case currency.code {
      GBP -> currency.amount *. 1.38
      EUR -> currency.amount *. 1.17
      USD -> currency.amount
    }
  }
  let add = fn(a, b) { a +. b }
  let input = "$2.30, €3.24, £5.50, $4.13"

  parser.run(input, wallet_parser())
  |> result.map(list.map(_, to_usd))
  |> result.map(list.fold(_, 0.0, add))
  |> should.equal(Ok(17.8108))
}

// TYPES -----------------------------------------------------------------------
type Currency {
  Currency(code: CurrencyCode, amount: Float)
}

type CurrencyCode {
  GBP
  EUR
  USD
}

type Wallet =
  List(Currency)

// PARSERS ---------------------------------------------------------------------
fn currency_parser() -> Parser(Currency) {
  parser.succeed2(Currency)
  |> parser.keep(currency_code_parser())
  |> parser.keep(parser.float())
  // Consume any trailing whitespace after parsing the Currency.
  |> parser.drop(parser.spaces())
}

fn currency_code_parser() -> Parser(CurrencyCode) {
  parser.any()
  |> parser.then(fn(symbol) {
    case symbol {
      "£" -> parser.succeed(GBP)
      "€" -> parser.succeed(EUR)
      "$" -> parser.succeed(USD)
      _ -> parser.fail("Unknown currency symbol.")
    }
  })
}

fn wallet_parser() -> Parser(Wallet) {
  let separator =
    parser.string(",")
    |> parser.drop(parser.spaces())

  parser.many(currency_parser(), separator)
  |> parser.drop(parser.eof())
}
