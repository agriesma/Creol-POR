(* Grammar file for Creol.

   This file is an input file to the menhir parser generator. *)

%token EOF
%token CLASS CONTRACTS INHERITS IMPLEMENTS BEGIN END INTERFACE DATATYPE
%token VAR WITH OP IN OUT CONSTRUCTOR FUNCTION
%token REQUIRES ENSURES INV WHEN WHERE SOME FORALL EXISTS
%token IF THEN ELSE FI SKIP AWAIT WAIT NEW
%token FOR TO BY DO OD WHILE OF CASE AS
%token EXCEPTION RAISE TRY
%token EQEQ COMMA SEMI COLON DCOLON ASSIGN
%token RBRACK LBRACK
%token LPAREN RPAREN
%token LBRACE RBRACE
%token HASHHASH HASH QQUESTION QUESTION BANGBANG BANG DOTDOT DOT ATAT AT
%token LTLT GTGT SUBTYPE SUPERTYPE DLRARROW
%token DOLLAR PERCENT TICK BACKTICK
%token BOX DIAMOND MERGE
%token AND OR XOR IFF NOT PLUSPLUS PLUS MINUSMINUS MINUS
%token TIMESTIMES TIMES ARROW DARROW DIVDIV DIV EQ NE LT LE GT GE
%token AMP AMPAMP BAR BARBAR WEDGE VEE TILDE MODELS MAPSTO UNDERSCORE
%token HAT HATHAT BACKSLASH ASSERT PROVE
%token LAPPEND CONCAT RAPPEND
%token <string> CID ID STRING
%token <int>  INT
%token <bool> BOOL
%token <float> FLOAT
%token NIL NULL

%left COMMA
%left BAR
%left IFF
%left XOR
%left OR BARBAR VEE
%left AMP
%left AND AMPAMP WEDGE
%right NOT
%nonassoc EQ NE
%left LE LT GT GE
%left BACKSLASH
%right LAPPEND
%left CONCAT RAPPEND
%left PLUS MINUS
%left TIMES DIV
%right UMINUS HASH
%left BACKTICK

%start <'a list> main

%{
(* A parser for Creol.

   This file has been generated from Creol.mly

   Ceol.mly is part of creolcomp written by

   Marcel Kyas <kyas@ifi.uio.no> with contributions from
   Olaf Owe and Einar Broch Johnsen

   Copyright (c) 2007

   The code in CreolParser.mly has been generated by the menhir parser
   generator.  In accordance with the Lesser General Public License,
   the generated parser as well as its source file are distributed
   under the terms of the GPL:

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.
   
   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
   02111-1307, USA. *)

open Lexing
open Creol
open Expression
open Statement

exception Error

(** Print a short error message and abort *)
let signal_error s m =
  output_string stderr (s.pos_fname ^ ":" ^ (string_of_int s.pos_lnum) ^ ": " ^
			m ^ "\n");
  flush stderr;
  raise Error
%}
%%

main:
      d = declarations EOF { d }
    | EOF { [] }

declarations:
      d = declaration { [d] }
    | d = declaration l = declarations { d::l }

declaration:
      d = classdecl { Declaration.Class d }
    | d = interfacedecl	{ Declaration.Interface d }
    | d = exceptiondecl { Declaration.Exception d }
    | d = datatypedecl { Declaration.Datatype d }

classdecl:
      CLASS n = CID;
        p = loption(delimited(LPAREN, separated_nonempty_list(COMMA, vardecl_no_init), RPAREN))
	i = loption(preceded(INHERITS, separated_nonempty_list(COMMA, inherits)))
	c = loption(preceded(CONTRACTS, separated_nonempty_list(COMMA, CID)))
	j = loption(preceded(IMPLEMENTS, separated_nonempty_list(COMMA, CID)))
	BEGIN a = loption(attributes)
        aw = ioption(anon_with_def) m = list(with_def) END {
      { Class.name = n; Class.parameters = p; Class.inherits = i;
	Class.contracts = c; Class.implements = j; Class.attributes = a;
	Class.with_defs = match aw with None -> m | Some w -> w::m } }
    | CLASS error
    | CLASS CID error
	{ signal_error $startpos "syntax error in class declaration" }

%inline inherits:
    i = CID e = loption(delimited(LPAREN, separated_nonempty_list(COMMA, expression), RPAREN))
        { (i, e) }

attributes:
      VAR l = separated_nonempty_list(COMMA, vardecl) { l }
    | l1 = attributes ioption(SEMI) VAR l2 = separated_nonempty_list(COMMA, vardecl) { l1 @ l2 }
    | VAR error
	{ signal_error $startpos "syntax error in attribute declaration" }

vardecl:
      v = vardecl_no_init
	{ v }
    | v = vardecl_no_init ASSIGN i = expression
	{ { v with var_init = Some i } }

%inline vardecl_no_init:
      i = ID COLON t = creol_type { { var_name = i; var_type = t; var_init = None } }

method_decl:
      OP i = ID p = parameters_opt
      ioption(preceded(REQUIRES, assertion))
      ioption(preceded(ENSURES, assertion))
      {
	match p with (ins, outs) ->
	  { meth_name = i; meth_inpars = ins;
	    meth_outpars = outs; meth_vars = []; meth_body = None} }
    | OP error
    | OP ID error
	{ signal_error $startpos "syntax error in method declaration" }

parameters_opt:
      (* empty *) { ([], []) }
    | LPAREN ins = inputs RPAREN { (ins, []) }
    | LPAREN outs = outputs RPAREN { ([], outs) }
    | LPAREN ins = inputs ioption(SEMI) outs = outputs RPAREN { (ins, outs) }

inputs:
      ioption(IN) l = separated_nonempty_list(COMMA, vardecl_no_init) { l }
    | error SEMI | error OUT
	{ signal_error $startpos "syntax error in method declaration" }

outputs:
      OUT l = separated_nonempty_list(COMMA, vardecl_no_init) { l }
    | error COMMA | error RPAREN
	{ signal_error $startpos "syntax error in method declaration" }

anon_with_def:
    l = nonempty_list(method_def) i = list(invariant)
    { { With.co_interface = None; With.methods = l; With.invariants = i } }

with_def:
      WITH m = CID l = nonempty_list(method_def) i = list(invariant)
    { { With.co_interface = Some m; With.methods = l; With.invariants = i } }

method_def:
      d = method_decl; EQEQ; a = loption(terminated(attributes, SEMI));
	s = statement (* ioption(SEMI) *)
    { { meth_name = d.meth_name; meth_inpars = d.meth_inpars;
	meth_outpars = d.meth_outpars; meth_vars = a; meth_body = Some s} }

interfacedecl:
      INTERFACE n = CID i = iface_inherits_opt BEGIN m = loption(with_decl) END
    { { Interface.name = n; Interface.inherits = i; Interface.methods = m } }

iface_inherits_opt:
      (* empty *) { [] }
    | INHERITS l = separated_nonempty_list(COMMA, CID) { l }

with_decl:
      WITH m = CID l = nonempty_list(method_decl) { l }


(* Exception declaration *)

exceptiondecl:
      EXCEPTION n = CID
        p = loption(delimited(LPAREN, separated_list(COMMA, vardecl_no_init), RPAREN))
	{ { Exception.name = n; Exception.parameters = p } }


(* Data type declaration *)

datatypedecl:
    DATATYPE n = CID loption(preceded(BY, separated_list(COMMA, CID))) BEGIN
      list(constructordecl) list(functiondecl) list(invariant) END
    { { Datatype.name = n } }

constructordecl:
    CONSTRUCTOR CID COLON loption(delimited(LPAREN, separated_nonempty_list(COMMA, creol_type), RPAREN))
    { () }

functiondecl:
    FUNCTION ID LPAREN separated_list(COMMA, vardecl_no_init) RPAREN
    COLON CID EQEQ expression
    { () }

(* Statements *)

statement:
      l = choice_statement r = ioption(preceded(MERGE, statement))
	{ match r with
	      None -> l
	    | Some s -> Merge((Note.make $startpos), l, s) }

choice_statement:
      l = statement_sequence r = ioption(preceded(BOX, choice_statement))
	{ match r with
	      None -> l
	    | Some s -> Choice((Note.make $startpos), l, s) }

statement_sequence:
      l = separated_nonempty_list(SEMI, basic_statement)
	{ Sequence((Note.make $startpos), l) }
    | error SEMI
	{ signal_error $startpos "syntax error in statement" }

basic_statement:
      SKIP
	{ Skip (Note.make $startpos) }
    | t = separated_nonempty_list(COMMA, lvalue) ASSIGN
          e = separated_nonempty_list(COMMA, expression_or_new)
	{ Assign((Note.make $startpos), t, e) }
    | AWAIT g = guard
	{ Await ((Note.make $startpos), g) }
    | l = ioption(ID) BANG callee = expression DOT m = ID
      LPAREN i = separated_list(COMMA, expression) RPAREN
	{ AsyncCall ((Note.make $startpos), l, callee, m, i) }
    | l = ioption(ID) BANG m = ID
      lb = ioption(preceded(AT, CID)) ub = ioption(preceded(LTLT, CID))
      LPAREN i = separated_list(COMMA, expression) RPAREN
	{ LocalAsyncCall ((Note.make $startpos), l, m, lb, ub, i) }
    | l = ID QUESTION LPAREN o = separated_list(COMMA, ID) RPAREN
	{ Reply ((Note.make $startpos), l, o) }
    | c = expression DOT; m = ID;
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, ID) RPAREN
	{ SyncCall ((Note.make $startpos), c, m, i, o) }
    | m = ID lb = ioption(preceded(AT, CID)) ub = ioption(preceded(LTLT, CID))
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, ID) RPAREN
	{ LocalSyncCall((Note.make $startpos), m, lb, ub, i, o) }
    | LBRACE s = statement RBRACE
	{ s }
    | IF e = expression THEN t = statement ELSE f = statement FI
        { If((Note.make $startpos), e, t, f) }
    | IF e = expression THEN t = statement FI
        { If((Note.make $startpos), e, t, Skip (Note.make $startpos)) }
    | FOR v = ID ASSIGN f = expression TO u = expression
	b = ioption(preceded(BY,expression))
	i = ioption(preceded(INV, assertion))
	DO s = statement OD
	{ Skip (Note.make $startpos) }
    | WHILE b = expression i = ioption(preceded(INV, assertion))
      DO s = statement OD
	{ While (Note.make $startpos, b, i, s) }
    | RAISE e = CID a = loption(delimited(LPAREN, separated_list(COMMA, expression), RPAREN))
	{ Skip (Note.make $startpos) }
    | TRY s = statement c = catchers END
	{ Skip (Note.make $startpos) }
    | ASSERT a = assertion
	{ Assert (Note.make $startpos, a) }
    | PROVE a = assertion
	{ Prove (Note.make $startpos, a) }
    | error ELSE | error FI | error OP | error WITH | error END | error EOF
	{ signal_error $startpos "syntax error in statement" }

catchers:
    nonempty_list(catch_clause)
    ioption(preceded(ELSE, statement))
    { }

catch_clause:
    WITH c = CID
         l = loption(delimited(LPAREN, separated_list(COMMA, ID), RPAREN))
         DO s = statement
    { }

lvalue:
     i = ID { i }

guard:
      l = ID QUESTION { Label ((Note.make $startpos), l) }
    | WAIT { Wait (Note.make $startpos) }
    | l = ID QUESTION AMP g = guard
        { Binary ((Note.make $startpos), GuardAnd,
		  Label((Note.make $startpos), l), g) }
    | e = expression { e }

expression_or_new:
      e = expression
	{ e }
    | NEW t = creol_type LPAREN a = separated_list(COMMA, expression) RPAREN
	{ New (Note.make $startpos, t, a) }

expression:
      l = expression o = binop r = expression
        { Binary((Note.make $startpos), o, l, r) }
    | NOT  e = expression { Unary((Note.make $startpos), Not, e) }
    | MINUS e = expression %prec UMINUS
	{ Unary((Note.make $startpos), UMinus, e) }
    | HASH e = expression
	{ Unary((Note.make $startpos), Length, e) }
    | e = expression BACKTICK i = ID
	{ FieldAccess ((Note.make $startpos), e, i) }
    | i = INT { Int ((Note.make $startpos), i) }
    | f = FLOAT { Float ((Note.make $startpos), f) }
    | b = BOOL { Bool ((Note.make $startpos), b) }
    | id = ID { Id ((Note.make $startpos), id) }
    | s = STRING { String ((Note.make $startpos), s) }
    | NIL { Nil (Note.make $startpos) }
    | NULL { Null (Note.make $startpos) }
    | LPAREN e = expression RPAREN { e }
    | f = function_name LPAREN l = separated_list(COMMA, expression) RPAREN
	{ FuncCall((Note.make $startpos), f, l) }
    | CASE expression OF separated_nonempty_list(BAR, case_decl) END
	{ Null (Note.make $startpos) }

%inline binop:
      AND { And }
    | AMP { And (* XXX *) }
    | AMPAMP { And (* XXX *) }
    | WEDGE { And (* XXX *) }
    | OR { Or }
    | BAR { Or (* XXX *) }
    | BARBAR { Or (* XXX *) }
    | VEE { Or (* XXX *) }
    | XOR { Ne }
    | IFF { Eq }
    | EQ { Eq }
    | NE { Ne }
    | LE { Le }
    | GE { Ge }
    | LT { Lt }
    | GT { Gt }
    | PLUS { Plus }
    | MINUS { Minus }
    | TIMES { Times }
    | DIV { Div }
    | LAPPEND { LAppend }
    | RAPPEND { RAppend }
    | CONCAT { Concat }
    | BACKSLASH { Project }

%inline function_name:
      f = ID { f }
    | AND { "and" }
    | OR { "or" }
    | XOR { "xor" }

%inline case_decl:
      pattern ARROW expression
	{ () }

pattern:
      ID
	{ () }
    | UNDERSCORE
	{ () }
    | pattern AS ID
	{ () }
    | LPAREN pattern RPAREN
	{ () }
    | CID pattern
	{ () }
    | pattern BAR pattern
	{ () }
    | pattern COMMA pattern
	{ () }
    | pattern LAPPEND pattern
	{ () }
    | pattern RAPPEND pattern
	{ () }

(* Poor mans types and type parameters *)
creol_type:
      t = CID
	{ Type.Basic t }
    | t = CID LBRACK p = separated_nonempty_list(COMMA, creol_type) RBRACK
	{ Type.Application(t, p) } 
    | CID LT error { signal_error $startpos "Error in type" }

(* Assertions. *)

invariant:
    INV a = assertion { a }

assertion:
    e = expression { e }

%%
