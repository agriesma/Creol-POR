(* The grammar of Creol.

   This is the input file is for use with the Menhir parser generator.
 *)

%{

(*i
 * CreolParser.mly -- A parser for Creol.
 *
 * This file is part of creoltools.
 *
 * Copyright (c) 2007, 2008 by Marcel Kyas
 *
 * The code in CreolCreolParser.mly has been generated by the menhir parser
 * generator.  In accordance with the Lesser General Public License,
 * the generated parser as well as its source file are distributed
 * under the terms of the GPL:
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
i*)

open Lexing
open Creol
open Expression
open Statement
open Method
open VarDecl

exception Error

(*
Print a short error message and abort
*)
let signal_error s m = Messages.error s.pos_fname s.pos_lnum m; exit 1

(*
A \ocwlowerid{super\_decl} is used to allow a more relaxed parsing
of contracts, implements, and inherits clauses.  The grammar allows
that these clauses occur in any order and even multiple times.  When
building the representation of a class or interface, these
\ocwlowerid{super\_decl} trees are recollected into single lists.
*)
type super_decl =
    Contracts of Inherits.t list
  | Implements of Inherits.t list
  | Inherits of Inherits.t list

let contracts l =
  List.flatten
    (List.fold_left (fun a -> function Contracts m -> m::a | _ -> a) [] l)

let implements l =
  List.flatten
    (List.fold_left (fun a -> function Implements m -> m::a | _ -> a) [] l)

let inherits l =
  List.flatten
    (List.fold_left (fun a -> function Inherits m -> m::a | _ -> a) [] l)

let upd_method_locs n w =
  List.map (fun x -> { x with With.methods =
      List.map (fun y -> { y with Method.location = n }) x.With.methods }) w

(* Make a new expression note from the lexical position. *)
let expression_note pos =
  Expression.make_note ~file:pos.pos_fname ~line:pos.pos_lnum ()

(* Make a new statement note from the lexical position. *)
let statement_note pos =
  Statement.make_note ~file:pos.pos_fname ~line:pos.pos_lnum ()

%}

%token EOF

(* Keywords *)
%token PRAGMA
%token CLASS CONTRACTS INHERITS IMPLEMENTS BEGIN END
%token INTERFACE DATATYPE
%token WHILE VAR WITH OP IN OUT FUN EXTERN
%token REQUIRES ENSURES INV  SOME FORALL EXISTS HISTORY
%token IF THEN ELSE SKIP RELEASE AWAIT POSIT NEW THIS NOW CALLER
%token AS DO FROM ASSERT PROVE

(* Symbols *)
%token EQEQ COMMA SEMI COLON BACKTICK ASSIGN
%token LBRACK RBRACK LPAREN RPAREN LBRACE RBRACE
%token HASH QUESTION BANG DOT AT
%token SUBTYPE SUPERTYPE
%token BOX MERGE PLUS MINUS TIMESTIMES TIMES PERCENT DIV
%token PREPEND CONCAT APPEND
%token EQ NE LT LE GT GE
%token TILDE AMPAMP BAR BARBAR HAT WEDGE VEE DLRARROW DARROW
%token BACKSLASH UNDERSCORE
%token <string> CID ID STRING
%token <bool> BOOL
%token <Big_int.big_int>  INT
%token <float> FLOAT
%token NIL NULL

(* %left COMMA *)
(* %left BAR *)
%left IN
%left DLRARROW
%left DARROW
%left HAT
%left BARBAR VEE
%left AMPAMP WEDGE
%right TILDE
%nonassoc EQ NE
%nonassoc LE LT GT GE
%left BACKSLASH
%left CONCAT
%right PREPEND
%left  APPEND
%left PLUS MINUS
%left TIMES DIV PERCENT
%left TIMESTIMES
%right UMINUS HASH

%start <Creol.Declaration.t list> main

%%

main:
      d = list(declaration) EOF { d }

declaration:
      d = classdecl { Declaration.Class d }
    | d = interfacedecl	{ Declaration.Interface d }
    | d = datatypedecl { Declaration.Datatype d }
    | d = functiondecl { Declaration.Function d }
    | error { signal_error $startpos "syntax error" }

classdecl:
      CLASS n = CID p = plist(vardecl_no_init) s = list(super_decl)
        pr = list(pragma)
	BEGIN
        a = list(terminated(attribute, ioption(SEMI)))
        aw = loption(anon_with_def) m = list(with_def)
        END
      { { Class.name = n; parameters = p; inherits = inherits s;
	  contracts = contracts s; implements = implements s;
	  attributes = List.flatten a;
          with_defs = upd_method_locs n (aw @ m);
	  pragmas = pr;
	  file  = $startpos.pos_fname; line = $startpos.pos_lnum } }
    | CLASS error
	{ signal_error $startpos "syntax error: invalid class name" }
    | CLASS CID error
	{ signal_error $startpos "syntax error in class declaration" }
    | CLASS CID plist(vardecl_no_init) list(super_decl)
        list(pragma) BEGIN error
	{ signal_error $startpos "syntax error in class body definition" }

super_decl:
      d = implements_decl { d }
    | d = contracts_decl { d }
    | d = inherits_decl { d }

contracts_decl:
      CONTRACTS l = separated_nonempty_list(COMMA, inherits)
        { (Contracts l) }
    | CONTRACTS error
	{ signal_error $startpos "syntax error in contracts list" }

implements_decl:
      IMPLEMENTS l = separated_nonempty_list(COMMA, inherits)
        { (Implements l) }
    | IMPLEMENTS error
	{ signal_error $startpos "syntax error in implements declaration" }

inherits_decl:
      INHERITS l = separated_nonempty_list(COMMA, inherits)
        { (Inherits l) }
    | INHERITS error
	{ signal_error $startpos "syntax error in inherits list" }

inherits:
    i = CID e = plist(expression)
        { (i, e) }

attribute:
      VAR l = separated_nonempty_list(COMMA, vardecl)
        { l }
    | VAR error
	{ signal_error $startpos "syntax error in attribute declaration" }

vardecl:
      v = vardecl_no_init
	{ v }
    | v = vardecl_no_init ASSIGN i = expression_or_new
	{ { v with VarDecl.init = Some i } }

vardecl_no_init:
      i = ID COLON t = creol_type
        { { VarDecl.name = i; VarDecl.var_type = t; VarDecl.init = None } }
    | ID error
	{ signal_error $startpos "syntax error in variable declaration" }
    | ID COLON error
	{ signal_error $startpos "syntax error in variable declaration" }

method_decl:
      OP i = ID p = parameters_opt
      r = ioption(preceded(REQUIRES, expression))
      e = ioption(preceded(ENSURES, expression))
      pr = list(pragma)
        { let r' = match r with
	    | None -> Expression.Bool (Expression.make_note (), true)
	    | Some x -> x
	  and e' = match e with
	    | None -> Expression.Bool (Expression.make_note (), true)
	    | Some x -> x
	  in
	    Method.make_decl i (fst p) (snd p) r' e'
	}
    | OP error
	{ signal_error $startpos "syntax error in method declaration" }
    | OP ID error
	{ signal_error $startpos "syntax error in method declaration" }

parameters_opt:
      (* empty *) { ([], []) }
    | LPAREN ins = inputs RPAREN { (ins, []) }
    | LPAREN outs = outputs RPAREN { ([], outs) }
    | LPAREN ins = inputs ioption(SEMI) outs = outputs RPAREN { (ins, outs) }

inputs:
      ioption(IN) l = separated_nonempty_list(COMMA, vardecl_no_init) { l }

outputs:
      OUT l = separated_nonempty_list(COMMA, vardecl_no_init) { l }

anon_with_def:
    l = nonempty_list(method_def) i = list(invariant)
    { [ { With.co_interface = Type.Internal; methods = l; invariants = i } ] }

with_def:
      WITH c = creol_type l = nonempty_list(method_def) i = list(invariant)
    { { With.co_interface = c;
	methods = List.map (Method.set_cointerface c) l;
	invariants = i } }

method_def:
      d = method_decl EQEQ
        a = list(terminated(attribute, SEMI)) s = statement
        { { d with Method.vars = List.flatten a; body = Some s} }
  |   d = method_decl EQEQ EXTERN s = STRING
        { { d with body = Some (Extern (statement_note $startpos, s)) } }
  |   method_decl EQEQ error
        { signal_error $startpos($3) "syntax error in method body" }

(* Interface Declaration *)

interfacedecl:
      INTERFACE n = CID plist(vardecl_no_init) i = list(inherits_decl)
        pr = list(pragma)
        BEGIN ioption(preceded(INV, expression)) w = list(with_decl) END
        { { Interface.name = n; inherits = inherits i;
	    with_decls = upd_method_locs n w; pragmas = pr } }
    | INTERFACE error
	{ signal_error $startpos "syntax error in interface declaration" }
    | INTERFACE CID error
	{ signal_error $startpos "syntax error in interface declaration" }

with_decl:
      WITH c = creol_type l = nonempty_list(method_decl) i = list(invariant)
     { { With.co_interface = c;
	 methods = List.map (Method.set_cointerface c) l;
	 invariants = i } }
    | WITH error
	{ signal_error $startpos "syntax error in with block declaration" }
    | WITH CID error
	{ signal_error $startpos "syntax error in with block declaration" }


(* Data type declaration *)

datatypedecl:
    DATATYPE t = creol_type
      s = loption(preceded(FROM, separated_list(COMMA, creol_type)))
      pr = list(pragma)
    { { Datatype.name = t; supers = s; pragmas = pr } }

functiondecl:
    FUN n = id_or_op p = plist(vardecl_no_init) COLON t = creol_type
    pr = list(pragma) EQEQ e = expression
    { { Function.name = n; parameters = p; result_type = t; body = e;
        pragmas = pr } }
  | FUN n = id_or_op p = plist(vardecl_no_init) COLON t = creol_type
    pr = list(pragma) EQEQ EXTERN s = STRING
    { { Function.name = n; parameters = p; result_type = t;
	body = Expression.Extern (expression_note $startpos, s);
        pragmas = pr } }
  | FUN error
    { signal_error $startpos "syntax error in function declaration" }
  | FUN id_or_op error
    { signal_error $startpos "syntax error in function declaration" }
  | FUN id_or_op plist(vardecl_no_init) COLON error
    { signal_error $startpos "syntax error in function declaration" }
  | FUN id_or_op plist(vardecl_no_init) COLON creol_type list(pragma)
    EQEQ error
    { signal_error $startpos "syntax error in function declaration" }

id_or_op:
      i = ID { i }
    | TILDE	{ "~" }
    | MINUS	{ "-" }
    | HASH	{ "#" }
    | AMPAMP	{ "&&" }
    | WEDGE	{ "/\\" }
    | BARBAR	{ "||" }
    | VEE	{ "\\/" }
    | HAT	{ "^" }
    | DLRARROW	{ "<=>" }
    | DARROW	{ "=>" }
    | EQ	{ "=" }
    | NE	{ "/=" }
    | LE	{ "<=" }
    | GE	{ ">=" }
    | LT	{ "<" }
    | GT	{ ">" }
    | PLUS	{ "+" }
    | TIMES	{ "*" }
    | TIMESTIMES { "**" }
    | DIV	{ "/" }
    | PERCENT   { "%" }
    | PREPEND	{ "-|" }
    | APPEND	{ "|-" }
    | CONCAT	{ "|-|" }
    | BACKSLASH { "\\" }
    | IN	{ "in" }

(* Statements *)

statement:
      l = choice_statement r = ioption(preceded(MERGE, statement))
	{ match r with
	      None -> l
	    | Some s -> (*i Merge((statement_note $startpos), l, s) i*)
                  signal_error $startpos(r)
                        "Merge statements are currently not supported."
        }

choice_statement:
      l = statement_sequence r = ioption(preceded(BOX, choice_statement))
	{ match r with
	      None -> l
	    | Some s -> Choice((statement_note $startpos), l, s) }

statement_sequence:
      l = basic_statement r = ioption(preceded(SEMI, statement_sequence))
	{ match r with
	      None -> l
	    | Some s -> Sequence((statement_note $startpos), l, s) }

basic_statement:
      SKIP
	{ Skip (statement_note $startpos) }
    | t = separated_nonempty_list(COMMA, lhs) ASSIGN
          e = separated_nonempty_list(COMMA, expression_or_new)
	{ Assign((statement_note $startpos), t, e) }
    | separated_nonempty_list(COMMA, lhs) ASSIGN error
	{ signal_error $startpos "syntax error in assignment" }
    | RELEASE
	{ Release (statement_note $startpos) }
    | AWAIT e = expression
	{ Await ((statement_note $startpos), e) }
    | AWAIT error
	{ signal_error $startpos "syntax error in await condition" }
    | POSIT e = expression
	{ Posit ((statement_note $startpos), e) }
    | POSIT error
	{ signal_error $startpos "syntax error in posit condition" }
    | l = ID QUESTION LPAREN o = separated_list(COMMA, lhs) RPAREN
	{ Get (statement_note $startpos,
		 Id (expression_note $startpos, l), o) }
    | l = ioption(ID) BANG callee = expression DOT m = ID
      LPAREN i = separated_list(COMMA, expression) RPAREN
      s = ioption(preceded(AS, creol_type))
	{ AsyncCall ((statement_note $startpos), 
		     (match l with
                          None -> None
			| Some lab -> Some (LhsId (expression_note $startpos, lab))),
                    callee, m, Type.default_sig ~coiface:s (), i) }
    | l = ioption(ID) BANG m = ID b = bounds
      LPAREN i = separated_list(COMMA, expression) RPAREN
        { let l' =
	  match l with
              None -> None
	    | Some lab -> Some (LhsId (expression_note $startpos, lab))
	  in
	    LocalAsyncCall (statement_note $startpos, l', m,
			    Type.default_sig (), fst b, snd b, i)
	}
    | c = expression DOT m = ID
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, lhs) RPAREN
      s = ioption(preceded(AS, creol_type))
	{ SyncCall ((statement_note $startpos), c, m, Type.default_sig ~coiface:s (),  i, o) }
    | m = ID b = bounds
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, lhs) RPAREN
      s = ioption(preceded(AS, creol_type))
	{ LocalSyncCall(statement_note $startpos, m,
		        Type.default_sig ~coiface:s (), fst b, snd b, i, o) }
    | AWAIT c = expression DOT; m = ID;
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, lhs) RPAREN
      s = ioption(preceded(AS, creol_type))
	{ AwaitSyncCall (statement_note $startpos, c, m,
                         Type.default_sig ~coiface:s (), i, o) }
    | AWAIT m = ID b = bounds
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, lhs) RPAREN
	{ AwaitLocalSyncCall(statement_note $startpos, m,
                             Type.default_sig (), fst b, snd b, i, o) }
    | BEGIN s = statement END
	{ s }
    | IF e = expression THEN t = statement ELSE f = statement END
        { If((statement_note $startpos), e, t, f) }
    | IF expression THEN statement ELSE error
        { signal_error $startpos($6) "syntax error in else block" }
    | IF e = expression THEN t = statement END
        { If((statement_note $startpos), e, t, Skip (statement_note $startpos)) }
    | IF expression THEN error
        { signal_error $startpos($4) "syntax error in if statement" }
    | WHILE c = expression inv = ioption(preceded(INV, expression)) DO
	s = statement END
	{ match inv with
	      Some i -> While (statement_note $startpos, c, i, s)
	    | None ->
		While (statement_note $startpos, c,
		       Bool (expression_note $startpos, true), s) }
    | WHILE expression INV expression DO error
        { signal_error $startpos($6) "syntax error in while statement" }
    | WHILE expression DO error
        { signal_error $startpos($4) "syntax error in while statement" }
    | WHILE expression INV error
        { signal_error $startpos($4) "syntax error in invariant" }
    | WHILE error
        { signal_error $startpos($2) "syntax error in while condition" }
    | DO s = statement inv = ioption(preceded(INV, expression))
      WHILE c = expression
	{ match inv with
	      Some i -> DoWhile (statement_note $startpos, c, i, s)
	    | None ->
		DoWhile (statement_note $startpos, c,
			 Bool(expression_note $startpos, true), s) }
    | ASSERT a = expression
	{ Assert (statement_note $startpos, a) }
    | ASSERT error
	{ signal_error $startpos($2) "syntax error in assertion" }
    | PROVE a = expression
	{ Prove (statement_note $startpos, a) }
    | PROVE error
	{ signal_error $startpos($2) "syntax error in assertion" }
    | expression error
	{ signal_error $startpos($2) "syntax error in statement" }

%inline bounds:
      (* empty *)                            { (None, None) }
    | SUPERTYPE lb = CID                     { (Some lb, None) }
    | SUBTYPE ub = CID                       { (None, Some ub) }
    | SUPERTYPE lb = CID SUBTYPE ub = CID    { (Some lb, Some ub) }
    | SUBTYPE ub = CID SUPERTYPE lb = CID    { (Some lb, Some ub) }

(* These expressions may occur on the left hand side of an assignment. *)
lhs:
      id = ID c = ioption(preceded(AT, creol_type))
	{ match c with
	      None -> LhsId (expression_note $startpos, id)
	    | Some cl -> LhsAttr (expression_note $startpos, id, cl) }
    | UNDERSCORE t = ioption(preceded(AS, creol_type))
	{ LhsWildcard (expression_note $startpos, t) }

expression_or_new:
      e = expression
	{ e }
    | NEW t = creol_type a = plist(expression)
	{ New (expression_note $startpos, t, a) }
    | NEW error
	{ signal_error $startpos "syntax error in new statement" }

expression:
      b = BOOL
	{ Bool (expression_note $startpos, b) }
    | i = INT
	{ Int (expression_note $startpos, i) }
    | f = FLOAT
	{ Float (expression_note $startpos, f) }
    | s = STRING
	{ String (expression_note $startpos, s) }
    | CALLER
	{ Caller (expression_note $startpos) }
    | NOW
	{ Now (expression_note $startpos) }
    | THIS
	{ This (expression_note $startpos) }
    | THIS AS i = CID
	{ QualifiedThis (expression_note $startpos, Type.Basic i) }
    | NIL
	{ Nil (expression_note $startpos) }
    | NULL
	{ Null (expression_note $startpos) }
    | HISTORY
	{ History (expression_note $startpos) }
    | id = ID c = ioption(preceded(AT, creol_type))
	{ match c with
	      None -> Id (expression_note $startpos, id)
	    | Some cl -> StaticAttr (expression_note $startpos, id, cl) }
    | l = ID QUESTION { Label (expression_note $startpos,
			       Id (expression_note $startpos, l)) }
    | LPAREN l = separated_list(COMMA, expression) RPAREN 
	{ match l with
	      [e] -> e
	    | _ -> Tuple (expression_note $startpos, l) }
    | LBRACK l = separated_list(COMMA, expression) RBRACK
	{ ListLit (expression_note $startpos, l) }
    | LBRACE e = separated_list(COMMA, expression) RBRACE
	{ SetLit (expression_note $startpos, e) }
    | LBRACE ID COLON creol_type BAR expression RBRACE
	{ Null (expression_note $startpos) }
    | l = expression o = binop r = expression
        { Binary(expression_note $startpos, o, l, r) }
    | TILDE e = expression
        { Unary(expression_note $startpos, Not, e) }
    | MINUS e = expression %prec UMINUS
	{ Unary(expression_note $startpos, UMinus, e) }
    | HASH e = expression
	{ Unary(expression_note $startpos, Length, e) }
    | f = function_name LPAREN l = separated_list(COMMA, expression) RPAREN
	{ FuncCall(expression_note $startpos, f, l) }
    | IF c = expression THEN t = expression ELSE f = expression END
        { Expression.If (expression_note $startpos, c, t, f) }
    | LPAREN SOME v = vardecl_no_init COLON e = expression RPAREN
	{ Choose (expression_note $startpos, v.VarDecl.name,
		  v.VarDecl.var_type, e) }
    | LPAREN FORALL v = vardecl_no_init COLON e = expression RPAREN
	{ Forall (expression_note $startpos, v.VarDecl.name,
		  v.VarDecl.var_type, e) }
    | LPAREN EXISTS v = vardecl_no_init COLON e = expression RPAREN
	{ Exists (expression_note $startpos, v.VarDecl.name, v.VarDecl.var_type, e) }

%inline binop:
      AMPAMP { And }
    | WEDGE { Wedge }
    | BARBAR { Or }
    | VEE { Vee }
    | HAT { Xor }
    | DLRARROW { Iff }
    | DARROW { Implies }
    | EQ { Eq }
    | NE { Ne }
    | LE { Le }
    | GE { Ge }
    | LT { Lt }
    | GT { Gt }
    | PLUS { Plus }
    | MINUS { Minus }
    | TIMES { Times }
    | TIMESTIMES { Power }
    | DIV { Div }
    | PERCENT { Modulo }
    | PREPEND { Prepend }
    | CONCAT { Concat }
    | APPEND { Append }
    | BACKSLASH { Project }
    | IN { In }

%inline function_name:
      f = ID { f }

(* Types *)

creol_type:
      t = CID
	{ Type.Basic t }
    | t = CID LBRACK p = separated_list(COMMA, creol_type) RBRACK
	{ Type.Application (t, p) }
    | BACKTICK v = ID
	{ Type.Variable v }
    | LBRACK d = separated_nonempty_list(COMMA, creol_type) RBRACK
	{ Type.Tuple d }

(* Invariants *)

invariant:
    INV e = expression { e }


(* Pragmatic information *)
pragma:
    PRAGMA n = CID v = plist(expression) ioption(SEMI)
	{ { Pragma.name = n; values = v } }

plist(X):
    l = loption(delimited(LPAREN, separated_list(COMMA, X), RPAREN))
        { l }   

%%
(* The trailer is currently empty *)
