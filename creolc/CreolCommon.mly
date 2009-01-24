(* The partial grammar of Creol: common declarations, expressions, and
   statements.

   This is the input file is for use with the Menhir parser generator.
 *)

%{

(*
 * CreolCode.mly -- A parser for common Creol productions.
 *
 * This file is part of creoltools.
 *
 * Copyright (c) 2007, 2008, 2009 by Marcel Kyas
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
 *)

%}

%%

%public super_decl:
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

%public inherits_decl:
      INHERITS l = separated_nonempty_list(COMMA, inherits)
        { (Inherits l) }
    | INHERITS error
	{ signal_error $startpos "syntax error in inherits list" }

inherits:
    n = CID a = plist(expression)
        { { Inherits.name = n; arguments = a } }

%public with_decl:
      WITH c = creol_type l = nonempty_list(method_decl) i = list(invariant)
        { { With.co_interface = c;
	    methods = List.map (Method.set_cointerface c) l; invariants = i;
            file  = $startpos.pos_fname; line = $startpos.pos_lnum } }
    | WITH error
	{ signal_error $startpos "syntax error in with block declaration" }
    | WITH CID error
	{ signal_error $startpos "syntax error in with block declaration" }

%public anon_with_def:
    l = nonempty_list(method_def) i = list(invariant)
    { [ { With.co_interface = Type.Internal; methods = l; invariants = i;
          file  = $startpos.pos_fname; line = $startpos.pos_lnum } ] }

%public with_def:
      WITH c = creol_type l = nonempty_list(method_def) i = list(invariant)
        { { With.co_interface = c;
	    methods = List.map (Method.set_cointerface c) l; invariants = i;
            file  = $startpos.pos_fname; line = $startpos.pos_lnum } }

%public attribute:
      VAR l = separated_nonempty_list(COMMA, vardecl)
        { l }
    | VAR error
	{ signal_error $startpos "syntax error in attribute declaration" }

vardecl:
      v = vardecl_no_init
	{ v }
    | v = vardecl_no_init ASSIGN i = expression_or_new
	{ { v with VarDecl.init = Some i } }

%public vardecl_no_init:
      i = id COLON t = creol_type
        { { VarDecl.name = i; var_type = t; init = None;
            file  = $startpos.pos_fname; line = $startpos.pos_lnum } }
    | id error
	{ signal_error $startpos "syntax error in variable declaration" }
    | id COLON error
	{ signal_error $startpos "syntax error in variable declaration" }

method_decl:
      METHOD i = id p = parameters_opt
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
              $startpos.pos_fname $startpos.pos_lnum
	}
    | METHOD error
	{ signal_error $startpos "syntax error in method declaration" }
    | METHOD id error
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

method_def:
      d = method_decl EQEQ
        a = list(terminated(attribute, SEMI)) s = statement
        { { d with Method.vars = List.flatten a; body = Some s} }
  |   d = method_decl EQEQ EXTERN s = STRING
        { { d with body = Some (Extern (statement_note $startpos, s)) } }
  |   method_decl EQEQ error
        { signal_error $startpos($3) "syntax error in method body" }


(* Work around keyword inflation *)
%public id_or_op:
      i = id { i }
    | TILDE	{ "~" }
    | HASH	{ "#" }
    | i = binop { i }


id:
      s = ID { s }
    | UPDATE { "update" }

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
    | l = id QUESTION LPAREN o = separated_list(COMMA, lhs) RPAREN
	{ Get (statement_note $startpos,
		 Id (expression_note $startpos, l), o) }
    | l = ioption(id) BANG callee = expression DOT m = id
      LPAREN i = separated_list(COMMA, expression) RPAREN
      s = ioption(preceded(AS, creol_type))
	{ AsyncCall ((statement_note $startpos), 
		     (match l with
                          None -> None
			| Some lab -> Some (LhsId (expression_note $startpos, lab))),
                    callee, m, Type.default_sig ~coiface:s (), i) }
    | l = ioption(id) BANG m = id b = bounds
      LPAREN i = separated_list(COMMA, expression) RPAREN
        { let l' =
	  match l with
              None -> None
	    | Some lab -> Some (LhsId (expression_note $startpos, lab))
	  in
	    LocalAsyncCall (statement_note $startpos, l', m,
			    Type.default_sig (), fst b, snd b, i)
	}
    | c = expression DOT m = id
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, lhs) RPAREN
      s = ioption(preceded(AS, creol_type))
	{ SyncCall ((statement_note $startpos), c, m, Type.default_sig ~coiface:s (),  i, o) }
    | m = id b = bounds
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, lhs) RPAREN
	{ LocalSyncCall(statement_note $startpos, m,
		        Type.default_sig (), fst b, snd b, i, o) }
    | AWAIT c = expression DOT; m = id;
	LPAREN i = separated_list(COMMA, expression) SEMI
	       o = separated_list(COMMA, lhs) RPAREN
      s = ioption(preceded(AS, creol_type))
	{ AwaitSyncCall (statement_note $startpos, c, m,
                         Type.default_sig ~coiface:s (), i, o) }
    | AWAIT m = id b = bounds
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
    | WHILE c = expression inv = ioption(preceded(INV, expression))
	ioption(measure) DO s = statement END
	{ match inv with
	      Some i -> While (statement_note $startpos, c, i, s)
	    | None ->
		While (statement_note $startpos, c,
		       Bool (expression_note $startpos, true), s) }
    | WHILE expression INV expression MEASURE expression BY id_or_op
	DO error
        { signal_error $startpos($10) "syntax error in while statement" }
    | WHILE expression INV expression DO error
        { signal_error $startpos($6) "syntax error in while statement" }
    | WHILE expression DO error
        { signal_error $startpos($4) "syntax error in while statement" }
    | WHILE error
        { signal_error $startpos($2) "syntax error in while condition" }
    | DO s = statement inv = ioption(preceded(INV, expression))
      ioption(measure) WHILE c = expression
	{ match inv with
	      Some i -> DoWhile (statement_note $startpos, c, i, s)
	    | None ->
		DoWhile (statement_note $startpos, c,
			 Bool(expression_note $startpos, true), s) }
    | DO error
        { signal_error $startpos($2) "syntax error in while statement" }
    | DO statement INV expression MEASURE expression BY id_or_op WHILE error
        { signal_error $startpos($10) "syntax error in while condition" }
    | DO statement INV expression WHILE error
        { signal_error $startpos($6) "syntax error in while condition" }
    | DO statement WHILE error
        { signal_error $startpos($4) "syntax error in while condition" }
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

%inline measure:
      MEASURE expression BY id_or_op
	{ () }
(*
    | MEASURE expression BY error 
        { signal_error $startpos($4) "syntax error in order" }
    | MEASURE expression error 
        { signal_error $startpos($3) "keyword \"by\" expected" }
    | MEASURE error 
        { signal_error $startpos($2) "syntax error in measure" } *)

(* These expressions may occur on the left hand side of an assignment. *)
lhs:
      id = id c = ioption(preceded(AT, creol_type))
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

%public expression:
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
    | id = id c = ioption(preceded(AT, creol_type))
	{ match c with
	      None -> Id (expression_note $startpos, id)
	    | Some cl -> StaticAttr (expression_note $startpos, id, cl) }
    | l = id QUESTION { Label (expression_note $startpos,
			       Id (expression_note $startpos, l)) }
    | LPAREN l = separated_list(COMMA, expression) RPAREN 
	{ match l with
	      [e] -> e
	    | _ -> Tuple (expression_note $startpos, l) }
    | LBRACK l = separated_list(COMMA, expression) RBRACK
	{ ListLit (expression_note $startpos, l) }
    | LBRACE e = separated_list(COMMA, expression) RBRACE
	{ SetLit (expression_note $startpos, e) }
    | LBRACE id COLON expression BAR expression RBRACE
	{ Null (expression_note $startpos) }
    | LMAP l = separated_list(COMMA, binding) RMAP
	{ MapLit (expression_note $startpos, l) }
    | l = expression o = binop r = expression
        { FuncCall (expression_note $startpos, o, [l; r]) }
    | TILDE e = expression
        { FuncCall (expression_note $startpos, "~", [e]) }
    | MINUS e = expression %prec UMINUS
	{ FuncCall (expression_note $startpos, "-", [e]) }
    | HASH e = expression
	{ FuncCall (expression_note $startpos, "#", [e]) }
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
      AMPAMP { "&&" }
    | WEDGE { "/\\" }
    | BARBAR { "||" }
    | VEE { "\\/" }
    | HAT { "^" }
    | DLRARROW { "<=>" }
    | DARROW { "=>" }
    | EQ { "=" }
    | NE { "/=" }
    | LE { "<=" }
    | GE { ">=" }
    | LT { "<" }
    | GT { ">" }
    | PLUS { "+" }
    | MINUS { "-" }
    | TIMES { "*" }
    | TIMESTIMES { "**" }
    | DIV { "/" }
    | PERCENT { "%" }
    | PREPEND { "-|" }
    | CONCAT { "|-|" }
    | APPEND { "|-" }
    | BACKSLASH { "\\" }
    | IN { "in" }

%inline function_name:
      f = id { f }

binding:
      d = expression MAPSTO r = expression { (d, r) }


(* Types *)

%public creol_type:
      t = CID
	{ Type.Basic t }
    | t = CID LBRACK p = separated_list(COMMA, creol_type) RBRACK
	{ Type.Application (t, p) }
    | LBRACK d = separated_nonempty_list(COMMA, creol_type) RBRACK
	{ Type.Tuple d }
    | BACKTICK v = id
	{ Type.Variable v }

(* Invariants *)

%public invariant:
      INV e = expression
	{ e }
    | INV error
	{ signal_error $startpos "syntax error in invariant" }
	


(* Pragmatic information *)
%public pragma:
    PRAGMA n = CID v = plist(expression) ioption(SEMI)
	{ { Pragma.name = n; values = v } }

%public plist(X):
    l = loption(delimited(LPAREN, separated_list(COMMA, X), RPAREN))
        { l }   
