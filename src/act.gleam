//// Gleam is a functional programming language that does not support having
//// *mutable state*. As such, programmers often have to pass state around manually,
//// threading it through functions via arguments and return values. This can
//// become a bit repetitive and clumsy.
////
//// What if state could be 'threaded' through functions automatically, with a
//// nice API that resembles mutable state? This is the central idea of `act` and
//// the [`Action`](#Action) type.
////

// ---- IMPORTS ----------------------------------------------------------------

import gleam/list

// ---- TYPES ------------------------------------------------------------------

/// An action is simply a function that takes some state and returns a value and
/// a potentially updated state. Running an action is as simple as calling the
/// function with a state.
///
/// ```
/// import gleam/int
/// import act.{type Action}
///
/// fn increment(by num: Int) -> Action(String, Int) {
///   fn(state) {
///     #(state + num, "I added " <> int.to_string(by))
///   }
/// }
///
/// pub fn main() {
///   let initial_state = 0
///
///   initial_state
///   |> act.all([increment(by: 2), increment(by: 5), increment(by: 1)])
/// }
///
/// // -> #(8, ["I added 2", "I added 5", "I added 1"])
/// ```
///
/// As you can see, actions really are *just functions*! `act` simply provides a
/// nice API for creating and working with these functions.
///
pub type Action(result, state) =
  fn(state) -> #(state, result)

/// An action that returns a `Result`, meaning it may fail.
///
pub type ResultAction(ok, error, state) =
  Action(Result(ok, error), state)

// ---- RUNNING ----------------------------------------------------------------

/// Run an action with the given state. Since actions are just functions that can
/// be called like any other, you will typically never need this function except
/// to improve readability in situations where it's not obvious what's going on.
///
pub fn run(action: Action(result, state), with state: state) -> #(state, result) {
  action(state)
}

/// Run an action with the given state and return its result. This function is
/// the equivalent of `action(state).1` and may help improve readability.
///
pub fn eval(action: Action(result, state), with state: state) -> result {
  action(state).1
}

/// Run an action with the given state and return the final state, ignoring the
/// action's result. This function is the equivalent of `action(state).0` and
/// may help improve readability.
///
pub fn exec(action: Action(result, state), with state: state) -> state {
  action(state).0
}

// ---- CONSTRUCTORS -----------------------------------------------------------

/// Create an action that returns the given value and doesn't modify state.
///
/// ```
/// fn foo() -> Action(String, s) {
///   use _ <- do(update_something())
///   return("Updated!")
/// }
/// ```
///
pub fn return(result: result) -> Action(result, state) {
  fn(state) { #(state, result) }
}

/// Create an action that returns the given value wrapped in an `Ok`.
///
pub fn ok(value: ok) -> ResultAction(ok, error, state) {
  fn(state) { #(state, Ok(value)) }
}

/// Create an action that returns the given value wrapped in an `Error`.
///
pub fn error(value: error) -> ResultAction(ok, error, state) {
  fn(state) { #(state, Error(value)) }
}

// ---- STATE ------------------------------------------------------------------

/// Create an action that returns the current state. This is useful because
/// functions such as `do` do not pass the updated state to their callbacks.
///
/// ```
/// fn foo() -> Action(result, state) {
///   use original_state <- do(get_state())
///   use result <- do(some_action)
///   use new_state <- do(get_state())
///   // do something with the variables
/// }
/// ```
///
/// 💡 If you find yourself combining `_state` functions with `do` a lot, check
/// out the [`state`](./act/state.html) module!
///
pub fn get_state() -> Action(state, state) {
  fn(state) { #(state, state) }
}

/// Create an action that sets the current state to a new value, returning `Nil`.
///
/// ```
/// fn set_to_42() -> Action(String, Int) {
///   use Nil <- do(set_state(42))
///   return("The state is now 42! HAHAHAHA!!!")
/// }
/// ```
///
/// 💡 If you find yourself combining `_state` functions with `do` a lot, check
/// out the [`state`](./act/state.html) module!
///
pub fn set_state(state: state) -> Action(Nil, state) {
  fn(_) { #(state, Nil) }
}

/// Create an action that updates the current state with the given function and
/// returns `Nil`.
///
/// ```
/// fn increment_state(by: Int) -> Action(Nil, Int) {
///   update_state(fn(s) { s + by })
/// }
/// ```
///
/// 💡 If you find yourself combining `_state` functions with `do` a lot, check
/// out the [`state`](./act/state.html) module!
///
pub fn update_state(updater: fn(state) -> state) -> Action(Nil, state) {
  fn(state) { #(updater(state), Nil) }
}

// ---- MANIPULATIONS ----------------------------------------------------------

/// Transform the value produced by an action with the given function.
///
pub fn map(action: Action(a, state), f: fn(a) -> b) -> Action(b, state) {
  fn(state) {
    let #(state, result) = action(state)
    #(state, f(result))
  }
}

/// Transform the value produced by an action with the given function if it is
/// wrapped in an `Ok`, returning the `Error` otherwise.
///
pub fn map_ok(
  action: ResultAction(a, error, state),
  f: fn(a) -> b,
) -> ResultAction(b, error, state) {
  fn(state) {
    let #(state, result) = action(state)

    case result {
      Ok(a) -> #(state, Ok(f(a)))
      Error(e) -> #(state, Error(e))
    }
  }
}

/// Transform the error produced by an action with the given function if it is
/// wrapped in an `Error`, returning the `Ok` value otherwise.
///
pub fn map_error(
  action: ResultAction(ok, a, state),
  f: fn(a) -> b,
) -> ResultAction(ok, b, state) {
  fn(state) {
    let #(state, result) = action(state)

    case result {
      Error(e) -> #(state, Error(f(e)))
      Ok(a) -> #(state, Ok(a))
    }
  }
}

// ---- COMBINATORS ------------------------------------------------------------

/// Run the first action, passing its result to the `and_then` function which
/// returns another action. This is very useful for chaining multiple actions
/// together with `use` expressions.
///
/// ```
/// fn foo() -> Action(String, state) {
///   use a_result <- do(some_action)
///   use another_result <- do(another_action("blah"))
///   return(a_result <> another_result)
/// }
/// ```
///
/// Using `use` is of course optional.
///
/// ```
/// fn bar() -> Action(result, state) {
///   do(some_action, fn(result) {
///     io.debug(result)
///     return(result)
///   })
/// }
/// ```
///
/// 💡 If you find yourself combining `_state` functions with `do` a lot, check
/// out the [`state`](./act/state.html) module!
///
pub fn do(
  first_do: Action(a, state),
  and_then: fn(a) -> Action(b, state),
) -> Action(b, state) {
  fn(state) {
    let #(state, result) = first_do(state)
    and_then(result)(state)
  }
}

/// Like a combination of `do` and `result.try`. If the first action returns an
/// `Ok` value, the `and_then` function is called with that value and the action
/// that it returns is run. If the first action returns an `Error` value, the
/// `and_then` function is not called and the error is returned.
///
pub fn try(
  first_try: ResultAction(a, error, state),
  and_then: fn(a) -> ResultAction(b, error, state),
) -> ResultAction(b, error, state) {
  fn(state) {
    let #(state, result) = first_try(state)

    case result {
      Ok(a) -> and_then(a)(state)
      Error(e) -> #(state, Error(e))
    }
  }
}

/// Run a list of actions in sequence, returning a list of the results.
///
pub fn all(actions: List(Action(result, state))) -> Action(List(result), state) {
  list.map_fold(actions, _, fn(state, action) { action(state) })
}

/// Run a list of actions in sequence purely for updating state, ignoring their
/// results. This function runs faster than `all` since it doesn't have to
/// traverse the result list.
///
pub fn each(actions: List(Action(result, state))) -> Action(Nil, state) {
  fn(state) {
    #(list.fold(actions, state, fn(state, action) { action(state).0 }), Nil)
  }
}

/// Run a list of actions in sequence, stopping if an `Error` is encountered,
/// and returning a list of the results.
///
pub fn try_all(
  actions: List(ResultAction(ok, error, state)),
) -> ResultAction(List(ok), error, state) {
  fn(state) {
    list.fold_until(actions, #(state, Ok([])), fn(acc, action) {
      let assert #(state, Ok(results)) = acc

      case action(state) {
        #(new_state, Ok(result)) ->
          list.Continue(#(new_state, Ok([result, ..results])))
        #(new_state, Error(result)) -> list.Stop(#(new_state, Error(result)))
      }
    })
  }
  |> map_ok(list.reverse)
}

/// Run a list of actions in sequence purely for updating state, stopping if an
/// `Error` is encountered. This function runs faster than `try_all` since it
/// doesn't have to traverse the result list.
///
pub fn try_each(
  actions: List(ResultAction(ok, error, state)),
) -> ResultAction(Nil, error, state) {
  fn(state) {
    list.fold_until(actions, #(state, Ok(Nil)), fn(acc, action) {
      let #(state, nil_result) = acc

      case action(state) {
        #(new_state, Ok(_)) -> list.Continue(#(new_state, nil_result))
        #(new_state, Error(result)) -> list.Stop(#(new_state, Error(result)))
      }
    })
  }
}
