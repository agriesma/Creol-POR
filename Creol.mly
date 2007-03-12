(* Grammar file for Creol.

   This file is an input file to the menhir parser generator. *)

%token EOF
%token CLASS CONTRACTS INHERITS IMPLEMENTS BEGIN END INTERFACE
%token WITH OP VAR IN OUT
%token EQEQ COMMA SEMI COLON ASSIGN
%token RBRACK LBRACK LPAREN RPAREN LBRACE RBRACE
%token QUESTION BANG BOX MERGE DOT AT
(* %token DIAMOND *)
(* %token BAR *)
(* %token DOTDOT *)
%token IF THEN ELSE FI SKIP AWAIT WAIT NEW
%token AND OR XOR IFF NOT PLUS MINUS TIMES DIV EQ NE LT LE GT GE
%token <string> CID ID STRING
%token <int>  INT
%token <bool> BOOL
%token <float> FLOAT
%token NIL NULL

%nonassoc EQ NE
%left AND OR XOR IFF
%left LE LT GT GE
%left PLUS MINUS
%left TIMES DIV
%right NOT
%left SEMI
%left MERGE
%left BOX

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

open Creol
open Lexing

(** Provide a default annotation *)
let default pos = { note_fname = pos.pos_fname ; note_lineno = pos.pos_lnum;
	note_defs = StringSet.empty }

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
      d = classdecl { Class d }
    | d = interfacedecl	{ Interface d }

classdecl:
      CLASS n = CID;
        p = loption(delimited(LPAREN, separated_nonempty_list(COMMA, vardecl_no_init), RPAREN))
	i = loption(preceded(INHERITS, separated_nonempty_list(COMMA, inherits)))
	c = loption(preceded(CONTRACTS, separated_nonempty_list(COMMA, CID)))
	j = loption(preceded(IMPLEMENTS, separated_nonempty_list(COMMA, CID)))
	BEGIN a = loption(attributes) m = list(method_def) END {
      { cls_name = n; cls_parameters = p; cls_inherits = i;
	cls_contracts = c; cls_implements = j; cls_attributes = a;
	cls_methods = m } }
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
      WITH m = CID OP i = ID p = parameters_opt {
	match p with (ins, outs) ->
	  { meth_name = i; meth_coiface = Basic m; meth_inpars = ins;
	    meth_outpars = outs; meth_vars = []; meth_body = None} }
    | OP i = ID p = parameters_opt {
	match p with
	    (ins, outs) ->
	      { meth_name = i; meth_coiface = Basic ""; meth_inpars = ins;
		meth_outpars = outs; meth_vars = []; meth_body = None} }
    | WITH error
    | WITH CID error
    | WITH CID OP error
    | WITH CID OP ID error
    | OP error
    | OP ID error
	{ signal_error $startpos "syntax error in method declaration" }

parameters_opt:
      (* empty *) { ([], []) }
    | LPAREN ins = inputs RPAREN { (ins, []) }
    | LPAREN outs = outputs RPAREN { ([], outs) }
    | LPAREN ins = inputs SEMI outs = outputs RPAREN { (ins, outs) }

inputs:
      IN l = separated_nonempty_list(COMMA, vardecl_no_init) { l }
    | IN error
	{ signal_error $startpos "syntax error in method declaration" }

outputs:
      OUT l = separated_nonempty_list(COMMA, vardecl_no_init) { l }
    | OUT error
	{ signal_error $startpos "syntax error in method declaration" }

method_def:
      d = method_decl; EQEQ; a = loption(terminated(attributes, SEMI));
	s = statement ioption(SEMI)
    { { meth_name = d.meth_name; meth_coiface = d.meth_coiface;
	  meth_inpars = d.meth_inpars; meth_outpars = d.meth_outpars;
	  meth_vars = a; meth_body = Some s} }

interfacedecl:
      INTERFACE n = CID i = iface_inherits_opt BEGIN m = method_decls_opt END {
	{ iface_name = n; iface_inherits = i; iface_methods = m } }

iface_inherits_opt:
      (* empty *) { [] }
    | INHERITS l = separated_nonempty_list(COMMA, CID) { l }

method_decls_opt:
      (* empty *) { [] }
    | m = method_decls { m }

method_decls:
      m = method_decl { [m] }
    | m = method_decl l = method_decls { m::l }

(* Statements *)
statement:
      SKIP { Skip (default $startpos) }
    | t = delimited(LBRACK, separated_nonempty_list(COMMA, ID), RBRACK) ASSIGN
	e = delimited(LBRACK, separated_nonempty_list(COMMA, expression), RBRACK)
	{ Assign((default $startpos), t, e) }
    | t = ID ASSIGN e = expression { Assign((default $startpos), [t], [e]) }
    | t = ID ASSIGN NEW c = CID;
	l = delimited(LPAREN, separated_list(COMMA, expression), RPAREN)
        { New((default $startpos), t, c, l) }
    | IF e = expression THEN t = statement ELSE f = statement FI
        { If((default $startpos), e, t, f) }
    | IF e = expression THEN t = statement FI
        { If((default $startpos), e, t, Skip (default $startpos)) }
    | AWAIT g = guard { Await ((default $startpos), g) }
    | l = ioption(ID) BANG c = ioption(terminated(expression, DOT)) m = ID;
	LPAREN i = separated_list(COMMA, expression) RPAREN
	{ let caller = match c with
	    None -> Id ((default $startpos), "this")
	  | Some e -> e in
	      AsyncCall ((default $startpos), l, caller, m, i) }
    | l = ID QUESTION LPAREN o = separated_list(COMMA, ID) RPAREN
	{ Reply ((default $startpos), l, o) }
    | c = expression DOT; m = ID;
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, ID) RPAREN
	{ SyncCall ((default $startpos), c, m, i, o) }
    | m = ID l = ioption(preceded(AT, CID))
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, ID) RPAREN
	{ LocalSyncCall((default $startpos), m, l, None, i, o) }
    | LBRACE s = statement RBRACE { s }
    | l = statement SEMI r = statement { Sequence((default $startpos), l, r) }
    | l = statement MERGE r = statement { Merge((default $startpos), l, r) }
    | l = statement BOX r = statement { Choice((default $startpos), l, r) }
    | error { signal_error $startpos "syntax error in statement" }

guard:
      l = ID QUESTION { Label ((default $startpos), l) }
    | WAIT { Wait (default $startpos) }
    | l = ID QUESTION AND g = guard
        { Conjunction ((default $startpos), Label((default $startpos), l), g) }
    | e = expression { Condition ((default $startpos), e) }

expression:
      l = expression o = binop r = expression
        { Binary((default $startpos), o, l, r) }
    | NOT  e = expression { Unary((default $startpos), Not, e) }
    | MINUS e = expression %prec NOT { Unary((default $startpos), UMinus, e) }
    | f = ID LBRACK l = separated_nonempty_list(COMMA, expression) RBRACK
	{ FuncCall((default $startpos), f, l) }
    | i = INT { Int ((default $startpos), i) }
    | f = FLOAT { Float ((default $startpos), f) }
    | b = BOOL { Bool ((default $startpos), b) }
    | id = ID { Id ((default $startpos), id) }
    | s = STRING { String ((default $startpos), s) }
    | NIL { Nil (default $startpos) }
    | NULL { Null (default $startpos) }
    | LPAREN e = expression RPAREN { e }

%inline binop:
      AND { And }
    | OR { Or }
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

(* Poor mans types and type parameters *)
creol_type:
      t = CID
	{ Basic t }
    | t = CID LBRACK p = separated_nonempty_list(COMMA, creol_type) RBRACK
	{ Application(t, p) } 
    | CID LT error { signal_error $startpos "Error in type" }

%%
