{
(* A lexer for Creol.

   This file has been generated from Creol.mly

   Ceol.mll is part of creolcomp written by

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

open CreolParser
open Lexing

exception Reserved of string * int * string

let update_loc lexbuf =
  let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <-
      { pos with pos_lnum = pos.pos_lnum + 1; pos_bol = pos.pos_cnum }

let reserved lexbuf =
  let pos = lexbuf.lex_curr_p in
    let tok = Lexing.lexeme lexbuf in
      raise (Reserved (pos.pos_fname, pos.pos_lnum, tok))
}
let COMMENT = '/' '/' [ ^ '\n' ]*
let FLOAT = ['0'-'9']+'.'['0'-'9']+('e' ('+'|'-')? ['0'-'9']+)
let CID = [ 'A'-'Z' ][ 'a'-'z' 'A'-'Z' ]*
let ID =  [ 'a'-'z' ][ 'a'-'z' 'A'-'Z' '0'-'9' ]*
let STRING = '"' [^ '\n' '"' ]* '"'
rule token = parse
      [' ' '\t'] { token lexbuf }
    | COMMENT { token lexbuf }
    | "/*" { c_style_comment lexbuf }
    | '\n' { update_loc lexbuf; token lexbuf }
    | "!!" { BANGBANG }
    | '!' { BANG }
	(* '"' *)
    | "##" { HASHHASH }
    | '#' { HASH }
    | '$' { DOLLAR }
    | '%' { PERCENT }
    | "&&" { AMPAMP }
    | '&' { AMP }
    | '\'' { TICK }
    | '(' { LPAREN }
    | ')' { RPAREN }
    | "**" { TIMESTIMES }
    | '*' { TIMES }
    | "++" { PLUSPLUS }
    | '+' { PLUS }
    | ',' { COMMA }
    | "->" { ARROW }
    | "-|" { LAPPEND }
    | "--" { MINUSMINUS }
    | '-' { MINUS }
    | ".." { DOTDOT }
    | '.' { DOT }
    | "/=" { NE }
    | "/\\" { WEDGE }
    | '/' { DIV }
	(* Digits 0 to 9 *)
    | "::" { DCOLON }
    | ":>" { SUPERTYPE }
    | ":=" { ASSIGN }
    | ':' { COLON }
    | ';' { SEMI }
    | "<=>" { DLRARROW }
    | "<=" { LE }
    | "<:" { SUBTYPE }
    | "<>" { DIAMOND }
    | "<<" { LTLT }
    | '<' { LT }
    | "=>" { DARROW }
    | "==" { EQEQ }
    | '=' { EQ }
    | ">=" { GE }
    | ">>" { GTGT }
    | ">" { GT }
    | "??" { QQUESTION }
    | '?' { QUESTION }
    | "@@" { ATAT }
    | '@' { AT }
	(* Upper case letters *)
    | "[]" { BOX }
    | '[' { LBRACK }
    | "\\/" { VEE }
    | '\\' { BACKSLASH }
    | ']' { RBRACK }
    | "^^" { HATHAT }
    | '^' { HAT }
    | '_' { UNDERSCORE }
    | '`' { BACKTICK }
	(* lower case letters *)
    | '{' { LBRACE }
    | "|||" { MERGE }
    | "|-|" { CONCAT }
    | "|-" { RAPPEND }
    | "|=" { MODELS }
    | "||" { BARBAR }
    | "|" { BAR }
    | '}' { RBRACE }
    | '~' { TILDE }
    | "assert" { ASSERT }
    | "await" { AWAIT }
    | "begin" { BEGIN }
    | "by" { BY }
    | "caller" { ID("caller") (* XXX: Should be special *) }
    | "case" { CASE }
    | "class" { CLASS }
    | "contracts" { CONTRACTS }
    | "ctor" { CONSTRUCTOR }
    | "datatype" { DATATYPE }
    | "do" { DO }
    | "else" { ELSE }
    | "end" { END }
    | "ensures" { ENSURES }
    | "exception" { EXCEPTION }
    | "exists" { EXISTS }
    | "extern" { EXTERN }
    | "false" { BOOL(false) }
    | "forall" { FORALL }
    | "for" { FOR }
    | "fun" { FUNCTION }
    | "history" { ID("history") (* XXX: Should be special *) }
    | "if" { IF }
    | "implements" { IMPLEMENTS }
    | "inherits" { INHERITS }
    | "interface" { INTERFACE }
    | "inv" { INV }
    | "in" { IN }
    | "new" { NEW }
    | "nil" { NIL }
    | "null" { NULL }
    | "of" { OF }
    | "op" { OP }
    | "out" { OUT }
    | "raise" { RAISE }
    | "release" { RELEASE }
    | "requires" { REQUIRES }
    | "skip" { SKIP }
    | "some" { SOME }
    | "then" { THEN }
    | "this" { ID("this") (* XXX: Should be special, too. *) }
    | "to" { TO }
    | "true" { BOOL(true) }
    | "try" { TRY }
    | "var" { VAR }
    | "when" { WHEN }
    | "with" { WITH }
    | FLOAT { FLOAT(float_of_string (Lexing.lexeme lexbuf)) }
    | ['0'-'9']+ { INT(int_of_string (Lexing.lexeme lexbuf)) }
    | CID { CID(Lexing.lexeme lexbuf) }
    | ID { ID(Lexing.lexeme lexbuf) }
    | STRING { let s = Lexing.lexeme lexbuf in STRING(String.sub s 1 ((String.length s) - 2)) }
    | eof { EOF }
and c_style_comment = parse
      "*/"	{ token lexbuf }
    | '\n' { update_loc lexbuf; c_style_comment lexbuf }
    | '*' { c_style_comment lexbuf }
    | [ ^ '\n' '*'] * { c_style_comment lexbuf }
