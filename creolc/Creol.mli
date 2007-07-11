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
	(** The abstract syntax of types in Creol. *)
	Basic of 'c * string
	  (** A basic type. *)
	| Variable of 'c * string
	    (** A type variable. *)
	| Application of 'c * string * 'c t list
	    (** A type application, e.g., [List[Int]]. *)
	| Tuple of 'c * 'c t list
	    (** The type of a tuple. *)
	| Function of 'c * 'c t list * 'c t
	    (** The type of a function.  The first component refers to
		the annotation of the function tupe, the second
		component is a tuple describing the domain and the
		last component is the (unique) type of the function's
		range. *)
	| Structure of 'c * 'c field list
	    (** The type of a structure. *)
	| Variant of 'c * 'c field list
	    (** The type of a variant. *)
	| Label of 'c * 'c t * 'c t list * 'c t list
	    (** The type of a label.

		This needs to be refined for type inference. *)
	| Intersection of 'c * 'c t list
	    (** The type is an intersection type.  Intersection types
		do not have concrete syntax. *)
	| Union of 'c * 'c t list
	    (** The type is a union type.  Union types do not have
		concrete syntax. *)
    and 'c field =
	(** The declaration of a field of a structure or a variant. *)
	{ field_note: 'c;     (** Type annotation of this field. *)
	  field_name: string; (** Name of this field. *)
	  field_type: 'c t    (** Type of this field *)
	}

    val as_string : 'c t -> string
  end

module Expression :
sig
  type ('b, 'c) t =
      (** Definition of the abstract syntax of Creol-expressions.
	  
          The parameter 'b refers to a possible annotation of the
          element. *)
      Null of 'b
	(** Literal of the null pointer. *)
      | Nil of 'b
	  (** Literal for an empty list. *)
      | Bool of 'b * bool
	  (** A boolean literal. *)
      | Int of 'b * int
	  (** An integer literal. *)
      | Float of 'b * float
	  (** A floating point literal. *)
      | String of 'b * string
	  (** A string literal. *)
      | Id of 'b * string
	  (** An identifier, usually an attribute or a local variable name *)
      | StaticAttr of 'b * string * 'c Type.t
	  (** Class-qualified access to an attribute value. *)
      | Tuple of 'b * ('b, 'c) t list
	  (** Tuple expression. *)
      | ListLit of 'b * ('b, 'c) t list
	  (** A list literal expression, enumerating its elements. *)
      | SetLit of 'b * ('b, 'c) t list
	  (** A set literal expression, enumerating its elements. *)
      | FieldAccess of 'b * ('b, 'c) t * string
	  (** Access the field of a structure. *)
      | Unary of 'b * unaryop * ('b, 'c) t
	  (** A unary expression *)
      | Binary of 'b * binaryop * ('b, 'c) t * ('b, 'c) t
	  (** A binary expression *)
      | If of 'b * ('b, 'c) t * ('b, 'c) t * ('b, 'c) t
	  (** Conditional expression *)
      | FuncCall of 'b * string * ('b, 'c) t list
	  (** A call of a primitive function *)
      | Label of 'b * string
	  (** The label expression, permitted only in guards *)
      | New of 'b * 'c Type.t * ('b, 'c) t list
	  (** Object creation expression, permitted only as top nodes *)
      | Extern of 'b * string
	  (** The body of a function which is defined externally, for
	      example, in Maude or C *)
  and ('b, 'c) lhs =
      (** These forms may occur on the left hand side of assignments *)
      LhsVar of 'b * string
	  (** An assignable variable. *)
    | LhsAttr of 'b * string * 'c Type.t
	  (** An assignable statically qualified class member. *)
    | LhsWildcard of 'b * 'c Type.t option
	  (** An expression which can accept any value. *)
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
      | Power
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

  val string_of_binaryop : binaryop -> string

  val prec_of_binaryop : binaryop -> (int * int)

  val string_of_unaryop : unaryop -> string

  val prec_of_unaryop : unaryop -> int

  val note : ('b, 'c) t -> 'b
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
      | Assign of 'a * ('b, 'c) Expression.lhs list * ('b, 'c) Expression.t list
	  (** A multiple assignment statement.  Requires that the two lists
	      are of the same length. *)
      | Await of 'a * ('b, 'c) Expression.t
	  (** An await statement. *)
      | AsyncCall of 'a * string option * ('b, 'c) Expression.t * string *
	  ('b, 'c) Expression.t list
	  (** Call a method asynchronously. *)
      | Reply of 'a * string * ('b, 'c) Expression.lhs list
	  (** Receive the reply to an asynchronous call. *)
      | Free of 'a * string
	  (** Release a label.  It is not usable after executing this statement
	      anymore. *)
      | SyncCall of 'a * ('b, 'c) Expression.t * string *
	  ('b, 'c) Expression.t list * ('b, 'c) Expression.lhs list
	  (** Call a (remote) method synchronously. *)
      | AwaitSyncCall of 'a * ('b, 'c) Expression.t * string *
	  ('b, 'c) Expression.t list * ('b, 'c) Expression.lhs list
	  (** Call a (remote) method synchronously. *)
      | LocalAsyncCall of 'a * string option * string * string option *
	  string option * ('b, 'c) Expression.t list
	  (** Call a local method synchronously. *)
      | LocalSyncCall of 'a * string * string option * string option *
	  ('b, 'c) Expression.t list * ('b, 'c) Expression.lhs list
	  (** Call a local method synchronously. *)
      | AwaitLocalSyncCall of 'a * string * string option * string option *
	  ('b, 'c) Expression.t list * ('b, 'c) Expression.lhs list
	  (** Call a local method synchronously. *)
      | Tailcall of 'a * string * string option * string option *
	  ('b, 'c) Expression.t list
	  (** Internal statement for eliminating tail calls. *)
      | If of 'a * ('b, 'c) Expression.t * ('a, 'b, 'c) t * ('a, 'b, 'c) t
	  (** Conditional execution. *)
      | While of 'a * ('b, 'c) Expression.t * ('b, 'c) Expression.t option *
	  ('a, 'b, 'c) t
	  (** While loops. *)
      | Sequence of 'a * ('a, 'b, 'c) t * ('a, 'b, 'c) t
	  (** Sequential composition *)
      | Merge of 'a * ('a, 'b, 'c) t * ('a, 'b, 'c) t
	  (** Merge of statements *)
      | Choice of 'a * ('a, 'b, 'c) t * ('a, 'b, 'c) t
	  (** Choice between statements *)
      | Extern of 'a * string
	  (** The method body or function body is defined externally.
	      This statement is not allowed to be composed. **)

  val note: ('a, 'b, 'c) t -> 'a

  val is_skip_p: ('a, 'b, 'c) t -> bool

  val normalize_sequences: ('a, 'b, 'c) t -> ('a, 'b, 'c) t
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
      with_decl: ('a, 'b, 'c) With.t list }

end





module Operation : sig

  type ('b, 'c) t = {
    name: string;
    parameters: ('b, 'c) creol_vardecl list;
    result_type: 'c Type.t;
    body: ('b, 'c) Expression.t
  }

end

(** Signature of a data type declaration. *)
module Datatype : sig

  type ('b, 'c) t = {
    name: 'c Type.t;
    supers: 'c Type.t list;
    operations: ('b, 'c) Operation.t list
  }

end





module Exception : sig

  type ('b, 'c) t = { name: string; parameters: ('b, 'c) creol_vardecl list }

end




module Declaration : sig

  type ('a, 'b, 'c) t =
      Class of ('a, 'b, 'c) Class.t
      | Interface of ('a, 'b, 'c) Interface.t
      | Datatype of ('b, 'c) Datatype.t
      | Exception of ('b, 'c) Exception.t

end



type ('a, 'b, 'c) program = ('a, 'b, 'c) Declaration.t list



val tailcall_successes : unit -> int

val optimise_tailcalls: ('a, 'b, 'c) Declaration.t list ->
  ('a, 'b, 'c) Declaration.t list
    (** Perform tail call optimisation.  *)

val find_definitions:
  (Note.t, 'b, 'c) Declaration.t list -> (Note.t, 'b, 'c) Declaration.t list

