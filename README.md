# 🎬 act

[![Package Version](https://img.shields.io/hexpm/v/act)](https://hex.pm/packages/act)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/act/)

Gleam is a functional programming language that does not support having _mutable state_. As such, programmers often have to pass state around manually, threading it through functions via arguments and return values. This can become a bit repetitive and clumsy.

What if state could be 'threaded' through functions automatically, with a nice API that resembles mutable state? This is the central idea of `act` and the [`Action`](https://hexdocs.pm/act/act#Action) type.

```gleam
type Action(result, state) = fn(state) -> #(state, result)
```

> `act` is inspired by the (now outdated) [gleam-eval](https://github.com/hayleigh-dot-dev/gleam-eval) package. `gleam-eval` is super cool, but only supports the `Result` type and was not created with Gleam's `use` feature in mind.

## Installation

```sh
gleam add act
```

## Docs & Example

Documentation can be found at <https://hexdocs.pm/act>. A simple example lives in [test/act_test.gleam](https://github.com/MystPi/act/blob/main/test/act_test.gleam).

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
