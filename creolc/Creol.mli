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

(** Note of a statement and expession, as generated by the Parser.

    This signature is the minimum needed by compiler. *)
module Note :
  sig
    type t
    val make : Lexing.position -> t
      (** Create a new note *)
    val line : t -> int
      (** Get the line of a note *)
    val file : t -> string
      (** Get the file of a note *)
    val to_xml : XmlTextWriter.xmlwriter -> t -> unit
      (** Write a note to an XML file. *)
  end

(** Types *)
module Type :
  sig
    type 'c t = 
	(** A type as defined in Creol. *)
	Basic of 'c * string
	  (** A basic type. *)
	| Application of 'c * string * 'c t list
	    (** A type application. *)
	| Variable of 'c * string
	    (** A type variable. *)
	| Label of 'c

    val as_string : 'a t -> string
  end

module Pattern :
sig
  type ('a, 'b, 'c) t =
    { pattern: 'a; when_clause: 'b option; match_clause: 'c }
end
 

module Case :
sig

  type ('a, 'b, 'c, 'd) t =
    { what: 'a; cases: ('b, 'c, 'd) Pattern.t list }
end

module Try :
sig
  type ('a, 'b, 'c, 'd) t =
    { what: 'a; catches: ('b, 'c, 'd) Pattern.t list }
end



module Expression :
sig
  type ('a, 'c) t =
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
      | Tuple of 'a * ('a, 'c) t list
	  (** Tuple expression. *)
      | Cast of 'a * ('a, 'c) t * 'c Type.t
	  (** Re-type an expression.  Involves a run-time check *)
      | Index of 'a * ('a, 'c) t * ('a, 'c) t
	  (** Convenience for indexing a sequence/vector/array *)
      | FieldAccess of 'a * ('a, 'c) t * string
	  (** Access the field of a structure. *)
      | Unary of 'a * unaryop * ('a, 'c) t
	  (** A unary expression *)
      | Binary of 'a * binaryop * ('a, 'c) t * ('a, 'c) t
	  (** A binary expression *)
      | If of 'a * ('a, 'c) t * ('a, 'c) t * ('a, 'c) t
	  (** Conditional expression *)
      | Case of 'a * (('a, 'c) t, unit, ('a, 'c) t, ('a, 'c) t) Case.t
	  (** Case expression *)
      | Typecase of 'a * (('a, 'c) t, 'c Type.t, ('a, 'c) t, ('a, 'c) t) Case.t
	  (** Type case expression *)
      | FuncCall of 'a * string * ('a, 'c) t list
	  (** A call of a primitive function *)
      | Label of 'a * string
	  (** The label expression, permitted only in guards *)
      | New of 'a * 'c Type.t * ('a, 'c) t list
	  (** Object creation expression, permitted only as top nodes *)
  and unaryop =
      (** Definition of the different unary operator symbols *)
      Not
	(** The negation of boolean values *)
      | UMinus
	  (** Invert a floating point number or an integer. *)
      | Length
	  (** The length of an expression *)
  and binaryop =
      (** Definition of the different binary operator symbols *)
      Plus
      | Minus
      | Times
      | Div
      | Modulo
      | Exponent
      | Eq
      | Ne
      | Le
      | Lt
      | Ge
      | Gt
      | And
      | Or
      | Xor
      | Implies
      | Iff
      | Prepend
      | Append
      | Concat
      | Project
      | In
      | GuardAnd

  val string_of_binaryop : binaryop -> string

  val string_of_unaryop : unaryop -> string

  val note : ('a, 'c) t -> 'a
end

module Statement: sig
  type ('a, 'b, 'c) t =
      (** Abstract syntax of statements in Creol.  The type parameter ['a]
	  refers to the type of possible annotations. *)
      Skip of 'a
	(** A skip statement *)
      | Release of 'a
	(** A release statement *)
      | Assert of 'a * ('b, 'c) Expression.t
	(** Check a condition at runtime. *)
      | Assign of 'a * string list * ('b, 'c) Expression.t list
	  (** A multiple assignment statement.  Requires that the two lists
	      are of the same length. *)
      | Await of 'a * ('b, 'c) Expression.t
	  (** An await statement. *)
      | AsyncCall of 'a * string option * ('b, 'c) Expression.t * string *
	  ('b, 'c) Expression.t list
	  (** Call a method asynchronously. *)
      | Reply of 'a * string * string list
	  (** Receive the reply to an asynchronous call. *)
      | Free of 'a * string
	  (** Release a label.  It is not usable after executing this statement
	      anymore. *)
      | SyncCall of 'a * ('b, 'c) Expression.t * string *
	  ('b, 'c) Expression.t list * string list
	  (** Call a (remote) method synchronously. *)
      | AwaitSyncCall of 'a * ('b, 'c) Expression.t * string *
	  ('b, 'c) Expression.t list * string list
	  (** Call a (remote) method synchronously. *)
      | LocalAsyncCall of 'a * string option * string * string option *
	  string option * ('b, 'c) Expression.t list
	  (** Call a local method synchronously. *)
      | LocalSyncCall of 'a * string * string option * string option *
	  ('b, 'c) Expression.t list * string list
	  (** Call a local method synchronously. *)
      | AwaitLocalSyncCall of 'a * string * string option * string option *
	  ('b, 'c) Expression.t list * string list
	  (** Call a local method synchronously. *)
      | Tailcall of 'a * string * string option * string option *
	  ('b, 'c) Expression.t list
	  (** Internal statement for eliminating tail calls. *)
      | If of 'a * ('b, 'c) Expression.t * ('a, 'b, 'c) t * ('a, 'b, 'c) t
	  (** Conditional execution. *)
      | While of 'a * ('b, 'c) Expression.t * ('b, 'c) Expression.t option *
	  ('a, 'b, 'c) t
	  (** While loops. *)
      | For of 'a * string * ('b, 'c) Expression.t * ('b, 'c) Expression.t *
	  ('b, 'c) Expression.t option * ('b, 'c) Expression.t option *
	  ('a, 'b, 'c) t
	  (** For loop *)
      | Raise of 'a * string * ('b, 'c) Expression.t list
	  (** Raising an exception *)
      | Try of 'a * ('a, 'b, 'c) t * ('a, 'b, 'c) catcher list
	  (** Try and catch exception *)
      | Case of 'a * (('b, 'c) Expression.t, unit, ('b, 'c) Expression.t, ('a, 'b, 'c) t) Case.t
	  (** Case statement *)
      | Typecase of 'a * (('b, 'c) Expression.t, 'c Type.t, ('b, 'c) Expression.t, ('a, 'b, 'c) t) Case.t
	  (** Type case statement *)
      | Sequence of 'a * ('a, 'b, 'c) t list
	  (** Sequential composition *)
      | Merge of 'a * ('a, 'b, 'c) t * ('a, 'b, 'c) t
	  (** Merge of statements *)
      | Choice of 'a * ('a, 'b, 'c) t * ('a, 'b, 'c) t
	  (** Choice between statements *)
      | Extern of 'a * string
	  (** The method body or function bopy is defined externally.
	      This statement is not allowed to be composed. **)
  and  ('a, 'b, 'c) catcher =
      { catch: string option;
	catch_parameters: string list;
	catch_statement: ('a, 'b, 'c) t}
  and ('a, 'b, 'c) typecase =
      { with_type: 'c Type.t option; with_statement: ('a, 'b, 'c) t }


  val note: ('a, 'b, 'c) t -> 'a
end



type ('b, 'c) creol_vardecl =
    (** Abstract syntax representing a variable declaration. *)
    { var_name: string;
	(** Name of the variable. *)
      var_type: 'c Type.t;
	(** Type of the variable. *)
      var_init: ('b, 'c) Expression.t option
	(** Expression used for initialisation. *)
    }

type ('a, 'b, 'c) creolmethod =
    (** Abstract syntax of a method declaration and definition. *)
    { meth_name: string;
	(** The name of the method. *)
      meth_inpars: ('b, 'c) creol_vardecl list;
	(** A list of input parameters. *)
      meth_outpars: ('b, 'c) creol_vardecl list;
	(** A list of output parameters. *)
      meth_vars: ('b, 'c) creol_vardecl list;
	(** A list of local variables. *)
      meth_body: ('a, 'b, 'c) Statement.t option
	(** The method body. *)
    }





(** Abstract syntax of a with clause.

    A with clause consists of a co-interface name, a list of methods
    and a sequence of invariants. *)
module With: sig

  type ('a, 'b, 'c) t = {
    co_interface: string option;
    methods: ('a, 'b, 'c) creolmethod list;
    invariants: ('b, 'c) Expression.t list
  }

end






module Class : sig

  type ('b, 'c) inherits = string * ('b, 'c) Expression.t list

  type ('a, 'b, 'c) t =
      { name: string;
	parameters: ('b, 'c) creol_vardecl list;
	inherits: ('b, 'c) inherits list;
	contracts: string list;
	implements: string list;
	attributes: ('b, 'c) creol_vardecl list;
	with_defs: ('a, 'b, 'c) With.t list }

end





module Interface : sig

  type ('a, 'b, 'c) t =
    { name: string;
      inherits: string list;
      with_decl: ('a, 'b, 'c) With.t option }

end





module Datatype : sig

  type ('a, 'b, 'c) t = {
    name: string
  }

end





module Exception : sig

  type ('b, 'c) t = { name: string; parameters: ('b, 'c) creol_vardecl list }

end




module Declaration : sig

  type ('a, 'b, 'c) t =
      Class of ('a, 'b, 'c) Class.t
      | Interface of ('a, 'b, 'c) Interface.t
      | Datatype of ('a, 'b, 'c) Datatype.t
      | Exception of ('b, 'c) Exception.t

end





module Maude :
sig
  type options = {
    mutable modelchecker: bool;
    mutable red_init: bool;
    mutable main: string option;
  }

  val of_creol: options: options -> out_channel: out_channel ->
    input: ('a, 'b, 'c) Declaration.t list -> unit
end




val lower: input: ('a, 'b, 'c) Declaration.t list ->
  copy_stmt_note: ('a -> 'a) ->
  expr_note_of_stmt_note: ('a -> 'b) ->
  copy_expr_note: ('b -> 'b) ->
  ('a, 'b, 'c) Declaration.t list
  (** Lower a Creol program to the "Core Creol" language.

      This function will destroy some statement and expression
      annotations.  Therefore, all semantic analysis performed before
      this function should be repeated after calling this function.

      This should only concern type inference, because all other
      analysis should be performed after this function.

      The following two invariant holds for this function:

      * A type correct program remains type correct and the
      annotations of unchanged statements are the same after
      reconstruction.

      * lower (lower tree) == lower tree *)

val tailcall_successes : unit -> int

val optimise_tailcalls: ('a, 'b, 'c) Declaration.t list ->
  ('a, 'b, 'c) Declaration.t list
    (** Perform tail call optimisation.  *)

val find_definitions:
  (Note.t, 'b, 'c) Declaration.t list -> (Note.t, 'b, 'c) Declaration.t list

val pretty_print: out_channel -> ('a, 'b, 'c) Declaration.t list -> unit
  (** Write a pretty-printed tree to [out_channel].

      The result of [lower] cannot be printed to a valid creol
      program.  The pretty-printed result can, however, be used for
      debugging. *)
