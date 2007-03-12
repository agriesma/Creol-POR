(*
 * Creol.mli -- Definition and manipulation of Creol AST
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

(** Definition of the abstract syntax of Creol and a collection
    of functions for its manipulation.

    @author Marcel Kyas
    @version 0.0
    @since   0.0

 *)

module StringSet : sig
    type t
    val empty: t
  end 

type note = { note_fname: string; note_lineno: int; note_defs: StringSet.t }

val note_to_xml: XmlTextWriter.xmlwriter -> note -> unit

type creol_type = 
    (** A type as defined in Creol. *)
      Basic of string
	(** A basic type. *)
    | Application of string * creol_type list
	(** A type application. *)
    | Variable of string
	(** A type variable. *)

type 'a expression =
    (** Definition of the abstract syntax of Creol-expressions.

        The parameter 'a refers to a possible annotation of the
        element. *)
    Null of 'a
	(** Literal of the null pointer. *)
    | Nil of 'a
	(** Literal for an empty list. *)
    | Bool of 'a * bool
	(** A boolean literal. *)
    | Int of 'a * int
	(** An integer literal. *)
    | Float of 'a * float
	(** A floating point literal. *)
    | String of 'a * string
	(** A string literal. *)
    | Id of 'a * string
	(** An identifier, usually an attribute or a local variable name *)
    | Unary of 'a * unaryop * 'a expression
	(** A unary expression *)
    | Binary of 'a * binaryop * 'a expression * 'a expression
	(** A binary expression *)
    | FuncCall of 'a * string * 'a expression list
	(** A call of a primitive function *)
and unaryop =
	(** Definition of the different unary operator symbols *)
    Not
	(** The negation of boolean values *)
    | UMinus
	(** Invert a floating point number or an integer. *)
and binaryop =
	(** Definition of the different binary operator symbols *)
    Plus
    | Minus
    | Times
    | Div
    | Eq
    | Ne
    | Le
    | Lt
    | Ge
    | Gt
    | And
    | Or
    | Xor
    | Iff

type 'a guard =
    Wait of 'a
    | Label of 'a * string
    | Condition of 'a * 'a expression
    | Conjunction of 'a * 'a guard * 'a guard

type ('a, 'b) statement =
    (** Abstract syntax of statements in Creol.  The type parameter ['a]
	refers to the type of possible annotations. *)
    Skip of 'a
	(** A skip statement *)
    | Assign of 'a * string list * 'b expression list
	(** A multiple assignment statement.  Requires that the two lists
	    are of the same length. *)
    | Await of 'a * 'b guard
	(** An await statement. *)
    | New of 'a * string * string * 'b expression list
	(** Create a new object. *)
    | AsyncCall of 'a * string option * 'b expression * string *
	'b expression list
	(** Call a method asynchronously. *)
    | Reply of 'a * string * string list
	(** Receive the reply to an asynchronous call. *)
    | Free of 'a * string
	(** Release a label.  It is not usable after executing this statement
	    anymore. *)
    | SyncCall of 'a * 'b expression * string *
	'b expression list * string list
	(** Call a (remote) method synchronously. *)
    | LocalSyncCall of 'a * string * string option * string option *
	'b expression list * string list
	(** Call a local method synchronously. *)
    | If of 'a * 'b expression * ('a, 'b) statement * ('a, 'b) statement
	(** Conditional execution. *)
    | While of 'a * 'b expression * 'b expression * ('a, 'b) statement
	(** While loops. *)
    | Sequence of 'a * ('a, 'b) statement * ('a, 'b) statement
	(** Sequential composition *)
    | Merge of 'a * ('a, 'b) statement * ('a, 'b) statement
	(** Merge of statements *)
    | Choice of 'a * ('a, 'b) statement * ('a, 'b) statement
	(** Choice between statements *)

type 'a creol_vardecl =
    (** Abstract syntax representing a variable declaration. *)
    { var_name: string;
	(** Name of the variable. *)
      var_type: creol_type;
	(** Type of the variable. *)
      var_init: 'a expression option
	(** Expression used for initialisation. *)
    }

type ('a, 'b) creolmethod =
    (** Abstract syntax of a method declaration and definition. *)
    { meth_name: string;
	(** The name of the method. *)
      meth_coiface: creol_type;
	(** The co-interface of the method. *)
      meth_inpars: 'b creol_vardecl list;
	(** A list of input parameters. *)
      meth_outpars: 'b creol_vardecl list;
	(** A list of output parameters. *)
      meth_vars: 'b creol_vardecl list;
	(** A list of local variables. *)
      meth_body: ('a, 'b) statement option
	(** The method body. *)
    }

type 'a inherits = string * ('a expression list)

type ('a, 'b) classdecl =
    { cls_name: string;
      cls_parameters: 'b creol_vardecl list;
      cls_inherits: 'b inherits list;
      cls_contracts: string list;
      cls_implements: string list;
      cls_attributes: 'b creol_vardecl list;
      cls_methods: ('a, 'b) creolmethod list }

type  ('a, 'b) interfacedecl =
    { iface_name: string;
      iface_inherits: string list;
      iface_methods: ('a, 'b) creolmethod list }

type ('a, 'b) declaration =
    Class of ('a, 'b) classdecl
    | Interface of ('a, 'b) interfacedecl

val statement_note: ('a, 'b) statement -> 'a

val pretty_print: out_channel -> ('a, 'b) declaration list -> unit

val simplify: ('a, 'b) declaration list -> ('a, 'b) declaration list

val maude_of_creol: out_channel -> ('a, 'b) declaration list -> unit
