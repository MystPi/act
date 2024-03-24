//// This is a basic example of how to use `act`. Make sure to look up any
//// functions in the docs that you're unfamiliar with!

import gleam/io
import gleam/int
// The `Action` type and `do` function are imported unqualified since they are
// so common.
import act.{type Action, do}

// Our state is simply an integer that we'll increment. In a real program, this
// could be anything used as state—maybe a list or custom type.
type State =
  Int

// Here, `increment` is an action that returns Nil. That's because there's no
// real value that makes sense to return from the action. When an action only
// changes state and doesn't return a value, we return Nil. This is similiar
// to functions that only do side effects in Gleam, such as `io.println`.
fn increment(by num: Int) -> Action(Nil, State) {
  io.println("I'm gonna update the state...")
  use _ <- do(act.update_state(int.add(_, num)))
  io.println("...updated!")
  use state <- do(act.get_state())
  io.println("The state is now " <> int.to_string(state))
  act.return(Nil)
}

// `steps` is an action that returns an Int
fn steps() -> Action(Int, State) {
  use _ <- do(increment(by: 2))
  use _ <- do(increment(by: 3))
  use incremented <- do(act.get_state())
  io.println("Returning & resetting the state to 0...")
  use _ <- do(act.set_state(0))
  act.return(incremented)
}

pub fn main() {
  let initial_state = 4
  // Notice how we've called `steps` with two sets of parenthesis. This is on
  // purpose! `steps` is a function that *returns* a function (the action), so
  // we have to call the returned action too.
  let #(final_state, result) = steps()(initial_state)

  io.println("The result is " <> int.to_string(result))
  io.println("The state is " <> int.to_string(final_state))
}
