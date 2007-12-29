(*
 * TreeBury.ml -- Bury dead variables.
 *
 * This file is part of creoltools
 *
 * Written and Copyright (c) 2007 by Marcel Kyas
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

(*s Bury all variables holding dead values.

  Requires life ranges and defined ranges. *)

open Creol
open Expression
open Statement
open VarDecl
open Method

(* This function inserts bury statements for all variables at the
   point at which they die.

   \textbf{TO DO:} This function will often insert redundant bury
   statements.  The user may write \lstinline!v := null! and never
   read from \lstinline!v! thereafter.  Then \lstinline!v! is declared
   to be dead and a [Bury] node is generated, causing an additional
   \lstinline!v := null! in the output. *)

let optimize prg =
  let optimise_in_statement meth stmt =

    (* Append a bury statement. *)
    let prepend_bury s =
      let d = def s and l = life s in
      let r =
	IdSet.filter (fun v -> not (label_p meth v)) (IdSet.diff d l)
      in
	Messages.message 1 ((file s) ^ ": " ^ (string_of_int (line s)) ^
			      ": d = " ^ (string_of_idset d) ^
			      "; l = " ^ (string_of_idset l) ^
			      "; r = " ^ (string_of_idset r)) ;
	if IdSet.is_empty r then
	  s
	else
	  let r' =
	    IdSet.fold
	      (fun e a ->
		 assert (not (label_p meth e)) ;
		 LhsId (Expression.make_note (), e) :: a)
	      r []
	  in
	  let n = {(note s) with def = IdSet.diff d r; life = IdSet.diff l r }
	  in
	    assert (r' <> []) ;
	    Sequence (n, Bury (n, r'), s)
    in

    let rec work =
      function
	| Assign _ as s -> s
	| If (n, c, s1, s2) ->
	    let s1' = work s1 in
	    let s2' = work s2 in
	      If (n, c, s1', s2')
	| While (n, c, i, s) ->
	    let s' = work s in
	      While (n, c, i, s')
	| Sequence (n, s1, s2) ->
	    let s1' = work s1 in
	    let s2' = work s2 in
	      Sequence (n, s1', s2')
	| Choice (n, s1, s2) ->
	    let s1' = work s1 and s2' = work s2 in
	      Choice (n, s1', s2')
	| Merge (n, s1, s2) ->
	    let s1' = work s1 and s2' = work s2 in
	      Merge (n, s1', s2')
	| s -> prepend_bury s
    in
      work stmt
  in
  let optimise_in_method meth =
    match meth.Method.body with
	None ->
	  meth
      | Some body ->
	  { meth with Method.body = Some (optimise_in_statement meth body) }
  in
  let optimise_in_with w =
    { w with With.methods = List.map optimise_in_method w.With.methods }
  in
  let optimise_in_class c =
    { c with Class.with_defs = List.map optimise_in_with c.Class.with_defs }
  in
  let optimise_declaration =
    function
	Declaration.Class c -> Declaration.Class (optimise_in_class c)
      | d -> d
  in
    List.map optimise_declaration prg
