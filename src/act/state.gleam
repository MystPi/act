//// Combining `_state` functions with `do` is so common that we have this simple
//// module to make things easier.
////
//// If you were previously writing actions like this:
////
//// ```
//// import act.{do}
////
//// use state <- do(act.get_state())
//// use _ <- do(act.set_state("foo"))
//// use _ <- do(act.update_state(my_update_function))
//// ```
////
//// Using the `state` module you can write this instead:
////
//// ```
//// import act/state
////
//// use state <- state.get()
//// use <- state.set("foo")
//// use <- state.update(my_update_function)
//// ```
////
//// Ah, much better! The functions read very nicely and eliminate some visual
//// complexity.
////

import act.{type Action, do}

/// Equivalent of [`get_state`](../act.html#get_state).
///
pub fn get(f: fn(state) -> Action(b, state)) -> Action(b, state) {
  do(act.get_state(), f)
}

/// Equivalent of [`set_state`](../act.html#set_state).
///
pub fn set(state: state, f: fn() -> Action(b, state)) -> Action(b, state) {
  do(act.set_state(state), fn(_) { f() })
}

/// Equivalent of [`update_state`](../act.html#update_state).
///
pub fn update(
  updater: fn(state) -> state,
  f: fn() -> Action(b, state),
) -> Action(b, state) {
  do(act.update_state(updater), fn(_) { f() })
}
