open! Core

(* Example with no [%expect] node at all *)

let%expect_test _ =
  print_string "hello\n";
  print_string "goodbye\n"
;;

(* Example with an [%expect] node that has no payload *)

let%expect_test _ =
  print_string "hello\n";
  print_string "goodbye\n";
  [%expect];
  ignore ("don't print" : string);
  [%expect]
;;
