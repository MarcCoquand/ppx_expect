open! Base
open Types

module Payload_types = struct
  module Delimiter = struct
    (** Delimiters used when representing a string in source code *)
    type t =
      | Quote (** [Quote] represents a ["string"] *)
      | Tag of string (** [Tag "x"] represents a [{x|string|x}] *)
  end

  (** Payloads given as arguments to expectation AST nodes.

      ['a] is the structured runtime representation of the expectation, which may differ
      depending on the rules a node uses for formatting and checking for correctness.
  *)
  type 'a t =
    { contents : 'a
        (** The contents of the payload, representing the output expected at some point *)
    ; tag : Delimiter.t (** The delimiters used in the payload *)
    }

  (** The outcome produced by a single expect node when it is reached. [Pass] if the real
      output matches the expected output, otherwise [Fail s], where [s] is the real
      output. *)
  module Result = struct
    type 'a t =
      | Pass
      | Fail of 'a
  end

  module type Contents = sig
    (** The structured representations of the contents of expect nodes.
        It is implemented in two different ways:
        - [Exact]: fully whitespace-sensitive formatting ([[%expect_exact]])
        - [Pretty]: partially whitespace-insensitive formatting ([[%expect]] and friends).
    *)

    type t

    val compare : t -> t -> int

    val reconcile
      :  expect_node_formatting:Expect_node_formatting.t
      -> expected_output:t
      -> test_output:t
      -> t Result.t

    val of_located_string
      :  loc:Compact_loc.t option
           (** The location of the AST node representing the expression point from which the
          string was parsed, or [None] if the string was not parsed from a file *)
      -> string
      -> t

    val to_source_code_string
      :  expect_node_formatting:Expect_node_formatting.t
      -> indent:int option
      -> tag:Delimiter.t
           (** The formatting of the result is affected by [tag] in some cases, but does not
          include the [tag] itself. *)
      -> t
      -> string
  end

  module type Type = sig
    (** A [Payload.t] that contains some structured [Contents.t] as the [contents]. *)

    type 'a payload := 'a t

    module Contents : Contents

    type t = Contents.t payload

    val of_located_payload
      :  loc:Compact_loc.t option
           (** The location of the AST node representing the expression point from which the
          string was parsed, or [None] if the string was not parsed from a file *)
      -> string payload
      -> t

    val to_source_code_string
      :  expect_node_formatting:Expect_node_formatting.t
      -> indent:int option
      -> t
      -> string
  end
end

module type Payload = sig
  include module type of struct
    include Payload_types
  end
  [@@inline_doc]

  module Delimiter : sig
    include module type of struct
      include Payload_types.Delimiter
    end
    [@@inline_doc]

    (** The default delimiter ([Tag ""]) used for new strings in payloads; this represents
        a preference for [{|strings|}] *)
    val default : t
  end

  (** Add the default tags to a payload *)
  val default : 'a -> 'a t

  module Result : sig
    include module type of struct
      include Result
    end

    val compare : ('a -> 'a -> int) -> 'a t -> 'a t -> int
  end

  module Pretty : Type
  module Exact : Type
end
