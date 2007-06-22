(*
 * CreolIO.mli -- Input and Output routines for Creol.
 *
 * This file is part of creolcomp
 *
 * Written and Copyright (c) 2007 by Marcel Kyas
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

(** Read and write Creol Programs.


    @author Marcel Kyas
    @version 0.0
    @since   0.0

  *)

open Creol

val from_channel : in_channel -> ('a, 'b, 'c) Declaration.t list

val from_file : string -> ('a, 'b, 'c) Declaration.t list

val from_files : string list -> ('a, 'b, 'c) Declaration.t list

val creol_to_xml : name: string ->
  stmt_handler: (XmlTextWriter.xmlwriter -> 'a -> unit) ->
  expr_handler: (XmlTextWriter.xmlwriter -> 'b -> unit) ->
  type_handler: (XmlTextWriter.xmlwriter -> 'c -> unit) ->
  tree: ('a, 'b, 'c) Declaration.t list -> unit
  (** Write a creol parse tree to XML.

      [name] is the name for the target file, where "-" is standard
      output.

      [stmt_handler] is a function for processing the notes associated to
      statements.

      [expr_handler] is a function for writing out the notes associated to
      expressions.

      [type_handler] is a function for writing out the notes associated to
      types.

      [tree] is the actual parse tree to write. *)
