(*i A lexer for Creol.
 *
 * This file has been generated from Creol.mll
 *
 * Creol.mll is part of creoltools.
 *
 * Copyright (c) 2007 Marcel Kyas
 *
 * The code in CreolParser.mly has been generated by the menhir parser
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

(*s Creol's lexer.
*)
{
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
let NEWLINE = '\n' | '\r' | ( '\r' '\n' )
let COMMENT = (('/' '/') | ('-' '-')) ([ ^ '\n' '\r' ]*)
let FLOAT = ((['0'-'9']*'.'['0'-'9']+)|(['0'-'9']+'.'['0'-'9']*))('e' ('+'|'-')? ['0'-'9']+)?
let CID = [ 'A'-'Z' ] [ '_' 'a'-'z' 'A'-'Z' '0'-'9' ]*
let ID =  [ '_' 'a'-'z' ] [ '_' '\'' 'a'-'z' 'A'-'Z' '0'-'9' ]*
let STRING = '"' [^ '\n' '\r' '"' ]* '"'
rule token = parse
      [' ' '\t'] { token lexbuf }
    | COMMENT { token lexbuf }
    | "/*" { c_style_comment lexbuf }
    | NEWLINE { update_loc lexbuf; token lexbuf }
    | "!!" { reserved lexbuf }
    | '!' { BANG }
	(*i '"' i*)
    | '#' { HASH }
    | '$' { reserved lexbuf }
    | '%' { PERCENT }
    | "&&" { AMPAMP }
    | '&' { reserved lexbuf }
    | '(' { LPAREN }
    | ')' { RPAREN }
    | "**" { TIMESTIMES }
    | '*' { TIMES }
    | '+' { PLUS }
    | ',' { COMMA }
    | "->" { reserved lexbuf }
    | "-|" { PREPEND }
    | '-' { MINUS }
    | '.' { DOT }
    | "/=" { NE }
    | "/\\" { WEDGE }
    | '/' { DIV }
	(*i Digits 0 to 9 i*)
    | ":>" { SUPERTYPE }
    | ":=" { ASSIGN }
    | ':' { COLON }
    | ';' { SEMI }
    | "<=>" { DLRARROW }
    | "<=" { LE }
    | "<:" { SUBTYPE }
    | "<>" { reserved lexbuf }
    | '<' { LT }
    | "=>" { DARROW }
    | "==" { EQEQ }
    | '=' { EQ }
    | ">=" { GE }
    | ">" { GT }
    | '?' { QUESTION }
    | '@' { AT }
	(*i Upper case letters i*)
    | "[]" { BOX }
    | '[' { LBRACK }
    | "\\/" { VEE }
    | '\\' { BACKSLASH }
    | ']' { RBRACK }
    | '^' { HAT }
    | '_' { UNDERSCORE }
    | '`' { BACKTICK }
	(*i Lower case letters i*)
    | '{' { LBRACE }
    | "|||" { MERGE }
    | "|-|" { CONCAT }
    | "|-" { APPEND }
    | "||" { BARBAR }
    | "|" { BAR }
    | '}' { RBRACE }
    | '~' { TILDE }
    | "as" { AS }
    | "assert" { ASSERT }
    | "await" { AWAIT }
    | "begin" { BEGIN }
    | "by" { reserved lexbuf }
    | "caller" { CALLER }
    | "case" { reserved lexbuf }
    | "class" { CLASS }
    | "component" { reserved lexbuf }
    | "constant" { reserved lexbuf }
    | "contracts" { CONTRACTS }
    | "datatype" { DATATYPE }
    | "do" { DO }
    | "else" { ELSE }
    | "end" { END }
    | "ensures" { ENSURES }
    | "exception" { reserved lexbuf }
    | "exists" { EXISTS }
    | "exports" { reserved lexbuf }
    | "external" { EXTERN }
    | "false" { BOOL(false) }
    | "for" { reserved lexbuf }
    | "forall" { FORALL }
    | "from" { FROM }
    | "function" { FUN }
    | "history" { HISTORY }
    | "if" { IF }
    | "implements" { IMPLEMENTS }
    | "imports" { reserved lexbuf }
    | "in" { IN }
    | "inherits" { INHERITS }
    | "interface" { INTERFACE }
    | "inv" { INV }
    | "is" { reserved lexbuf }
    | "measure" { reserved lexbuf }
    | "method" { OP }
    | "new" { NEW }
    | "nil" { NIL }
    | "now" { NOW }
    | "null" { NULL }
    | "object" { reserved lexbuf }
    | "of" { reserved lexbuf }
    | "op" { OP }
    | "out" { OUT }
    | "posit" { POSIT }
    | "pragma" { PRAGMA }
    | "prove" { reserved lexbuf }
    | "provides" { reserved lexbuf }
    | "release" { RELEASE }
    | "requires" { REQUIRES }
    | "skip" { SKIP }
    | "signal" { reserved lexbuf }
    | "some" { SOME }
    | "then" { THEN }
    | "this" { THIS }
    | "throw" { reserved lexbuf }
    | "throws" { reserved lexbuf }
    | "true" { BOOL(true) }
    | "try" { reserved lexbuf }
    | "var" { VAR }
    | "volatile" { reserved lexbuf }
    | "when" { reserved lexbuf }
    | "where" { reserved lexbuf }
    | "while" { WHILE }
    | "with" { WITH }
    | FLOAT { FLOAT(float_of_string (Lexing.lexeme lexbuf)) }
    | ['0'-'9']+ { INT(Big_int.big_int_of_string (Lexing.lexeme lexbuf)) }
    | CID { CID(Lexing.lexeme lexbuf) }
    | ID { ID(Lexing.lexeme lexbuf) }
    | STRING
	{ let s = Lexing.lexeme lexbuf in
	    STRING(String.sub s 1 ((String.length s) - 2)) }
    | eof { EOF }
and c_style_comment = parse
      "*/"	{ token lexbuf }
    | NEWLINE { update_loc lexbuf; c_style_comment lexbuf }
    | '*' { c_style_comment lexbuf }
    | [ ^ '\n' '\r' '*'] * { c_style_comment lexbuf }
