(*
 * BackendXML.ml -- Backend to XML
 *
 * This file is part of creoltools
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

let emit ~name ~stmt_handler ~expr_handler ~type_handler ~tree =
  let writer = XmlTextWriter.to_file name 0 in
  let rec creol_declaration_to_xml =
    function
	Declaration.Class c -> creol_class_to_xml c
      | Declaration.Interface i -> creol_interface_to_xml i
      | Declaration.Datatype d -> creol_datatype_to_xml d
      | Declaration.Exception e -> creol_exception_to_xml e
  and creol_exception_to_xml e =
    XmlTextWriter.start_element writer "creol:exception";
    XmlTextWriter.write_attribute writer "name" e.Exception.name;
    if e.Exception.parameters <> [] then
      begin
	XmlTextWriter.start_element writer "creol:parameters";
	List.iter (creol_vardecl_to_xml)
	  e.Exception.parameters;
	XmlTextWriter.end_element writer
      end ;
    XmlTextWriter.end_element writer
  and creol_datatype_to_xml d =
    XmlTextWriter.start_element writer "creol:datatype";
    creol_type_to_xml d.Datatype.name;
    XmlTextWriter.start_element writer "creol:supertypes";
    List.iter creol_type_to_xml d.Datatype.supers;
    XmlTextWriter.end_element writer ;
    List.iter creol_operation_to_xml d.Datatype.operations;
    XmlTextWriter.end_element writer
  and creol_operation_to_xml o =
    XmlTextWriter.start_element writer "creol:operation";
    XmlTextWriter.write_attribute writer "name" o.Operation.name;
    XmlTextWriter.start_element writer "creol:parameters";
    List.iter (creol_vardecl_to_xml) o.Operation.parameters;
    XmlTextWriter.end_element writer;
    XmlTextWriter.start_element writer "creol:resulttype";
    creol_type_to_xml o.Operation.result_type ;
    XmlTextWriter.end_element writer;
    XmlTextWriter.start_element writer "creol:body";
    creol_expression_to_xml o.Operation.body ;
    XmlTextWriter.end_element writer;
    XmlTextWriter.end_element writer
  and creol_class_to_xml c =
    XmlTextWriter.start_element writer "creol:class";
    XmlTextWriter.write_attribute writer "name" c.Class.name;
    XmlTextWriter.start_element writer "creol:parameters";
    List.iter (creol_vardecl_to_xml)
      c.Class.parameters;
    XmlTextWriter.end_element writer;
    XmlTextWriter.start_element writer "creol:inherits";
    List.iter (creol_inherits_to_xml) c.Class.inherits;
    XmlTextWriter.end_element writer;
    XmlTextWriter.start_element writer "creol:contracts";
    List.iter (creol_contracts_to_xml) c.Class.contracts;
    XmlTextWriter.end_element writer;
    XmlTextWriter.start_element writer "creol:implements";
    List.iter (creol_implements_to_xml) c.Class.implements;
    XmlTextWriter.end_element writer;
    XmlTextWriter.start_element writer "creol:attributes";
    List.iter (creol_vardecl_to_xml) c.Class.attributes;
    XmlTextWriter.end_element writer;
    List.iter (creol_with_to_xml)
      c.Class.with_defs;
    XmlTextWriter.end_element writer
  and creol_interface_to_xml i =
    XmlTextWriter.start_element writer "creol:interface";
    XmlTextWriter.write_attribute writer "name" i.Interface.name;
    XmlTextWriter.end_element writer
  and creol_with_to_xml w =
    XmlTextWriter.start_element writer "creol:with";
    begin
      match w.With.co_interface with
	  None -> XmlTextWriter.write_attribute writer "cointerface" "None"
	| Some i -> XmlTextWriter.write_attribute writer "cointerface" i
    end;
    List.iter (creol_method_to_xml)
      w.With.methods;
    XmlTextWriter.end_element writer
  and creol_inherits_to_xml (i, l) =
    XmlTextWriter.start_element writer "creol:inherits";
    XmlTextWriter.write_attribute writer "name" i;
    List.iter (creol_argument_to_xml) l;
    XmlTextWriter.end_element writer
  and creol_contracts_to_xml i =
    ()
  and creol_implements_to_xml i =
    ()
  and creol_method_to_xml m =
    XmlTextWriter.start_element writer "creol:method" ; 
    XmlTextWriter.write_attribute writer "name" m.meth_name;
    XmlTextWriter.start_element writer "creol:inputs" ; 
    List.iter (creol_vardecl_to_xml) m.meth_inpars;
    XmlTextWriter.end_element writer;
    XmlTextWriter.start_element writer "creol:outputs" ; 
    List.iter (creol_vardecl_to_xml) m.meth_outpars;
    XmlTextWriter.end_element writer;
    XmlTextWriter.start_element writer "creol:variables" ; 
    List.iter (creol_vardecl_to_xml) m.meth_vars;
    XmlTextWriter.end_element writer;
    (match m.meth_body with
	None -> ()
      | Some s -> XmlTextWriter.start_element writer "creol:body" ; 
	  creol_statement_to_xml s;
	  XmlTextWriter.end_element writer) ;
    XmlTextWriter.end_element writer
  and creol_statement_to_xml =
    function
	Statement.Skip a ->
	  XmlTextWriter.start_element writer "creol:skip" ; 
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Assert (a, e) ->
	  XmlTextWriter.start_element writer "creol:assert" ; 
	  creol_expression_to_xml e ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Assign (a, vs, es) ->
	  XmlTextWriter.start_element writer "creol:assign" ;
	  XmlTextWriter.start_element writer "creol:targets" ;
	  List.iter creol_lhs_to_xml vs ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:expressions" ;
	  List.iter (function e -> 
	    XmlTextWriter.start_element writer "creol:expression" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Await (a, g) -> 
	  XmlTextWriter.start_element writer "creol:await" ;
	  creol_expression_to_xml g ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Release a -> 
	  XmlTextWriter.start_element writer "creol:release" ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.AsyncCall (a, l, c, m, es) ->
	  XmlTextWriter.start_element writer "creol:asynccall" ;
	  (match l with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "label" n ) ;
	  XmlTextWriter.write_attribute writer "method" m ;
	  XmlTextWriter.start_element writer "creol:callee" ;
	  creol_expression_to_xml c ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:arguments" ;
	  List.iter (function e -> 
	    XmlTextWriter.start_element writer "creol:expression" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a  ;
          XmlTextWriter.end_element writer
      | Statement.Reply (a, l, is) ->
	  XmlTextWriter.start_element writer "creol:reply" ;
	  XmlTextWriter.write_attribute writer "label" l ;
	  XmlTextWriter.start_element writer "creol:results" ;
	  List.iter creol_lhs_to_xml is ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Free (a, l) ->
	  XmlTextWriter.start_element writer "creol:free" ;
	  XmlTextWriter.write_attribute writer "label" l ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.SyncCall (a, c, m, es, is) ->
	  XmlTextWriter.start_element writer "creol:synccall" ;
	  XmlTextWriter.write_attribute writer "method" m ;
	  XmlTextWriter.start_element writer "callee" ;
	  creol_expression_to_xml c ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:arguments" ;
	  List.iter (function e -> 
	    XmlTextWriter.start_element writer "creol:expression" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:results" ;
	  List.iter creol_lhs_to_xml is ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.AwaitSyncCall (a, c, m, es, is) ->
	  XmlTextWriter.start_element writer "creol:awaitsynccall" ;
	  XmlTextWriter.write_attribute writer "method" m ;
	  XmlTextWriter.start_element writer "callee" ;
	  creol_expression_to_xml c ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:arguments" ;
	  List.iter (function e -> 
	    XmlTextWriter.start_element writer "creol:expression" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:results" ;
	  List.iter creol_lhs_to_xml is ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.LocalAsyncCall (a, l, m, lb, ub, es) ->
	  XmlTextWriter.start_element writer "creol:localasynccall" ;
	  XmlTextWriter.write_attribute writer "method" m ;
	  (match l with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "label" n ) ;
	  (match lb with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "lower" n ) ;
	  (match ub with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "upper" n ) ;
	  XmlTextWriter.start_element writer "creol:arguments" ;
	  List.iter (function e -> 
	    XmlTextWriter.start_element writer "creol:expression" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.LocalSyncCall (a, m, l, u, es, is) ->
	  XmlTextWriter.start_element writer "creol:localsynccall" ;
	  XmlTextWriter.write_attribute writer "method" m ;
	  (match l with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "lower" n ) ;
	  (match u with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "upper" n ) ;
	  XmlTextWriter.start_element writer "creol:arguments" ;
	  List.iter (function e -> 
	    XmlTextWriter.start_element writer "creol:expression" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:results" ;
	  List.iter creol_lhs_to_xml is ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.AwaitLocalSyncCall (a, m, l, u, es, is) ->
	  XmlTextWriter.start_element writer "creol:awaitlocalsynccall" ;
	  XmlTextWriter.write_attribute writer "method" m ;
	  (match l with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "lower" n ) ;
	  (match u with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "upper" n ) ;
	  XmlTextWriter.start_element writer "creol:arguments" ;
	  List.iter (function e -> 
	    XmlTextWriter.start_element writer "creol:expression" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:results" ;
	  List.iter creol_lhs_to_xml is ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Tailcall (a, m, l, u, es) ->
	  XmlTextWriter.start_element writer "creol:tailcall" ;
	  XmlTextWriter.write_attribute writer "method" m ;
	  (match l with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "lower" n ) ;
	  (match u with
	      None -> ()
	    | Some n -> XmlTextWriter.write_attribute writer "upper" n ) ;
	  XmlTextWriter.start_element writer "creol:arguments" ;
	  List.iter (function e -> 
	    XmlTextWriter.start_element writer "creol:expression" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.If (a, c, t, f) ->
	  XmlTextWriter.start_element writer "creol:if" ;
	  XmlTextWriter.start_element writer "creol:condition" ;
	  creol_expression_to_xml c ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:then" ;
	  creol_statement_to_xml t ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:else" ;
	  creol_statement_to_xml f ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.While (a, c, i, d) ->
	  XmlTextWriter.start_element writer "creol:while" ;
	  XmlTextWriter.start_element writer "creol:condition" ;
	  creol_expression_to_xml c ;
          XmlTextWriter.end_element writer ;
	  begin
	    match i with
		None -> ()
	      | Some inv ->
		  XmlTextWriter.start_element writer "creol:invariant" ;
		  creol_expression_to_xml inv ;
		  XmlTextWriter.end_element writer ;
	  end ;
	  XmlTextWriter.start_element writer "creol:do" ;
	  creol_statement_to_xml d ;
          XmlTextWriter.end_element writer ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Sequence (a, s1, s2) ->
	  XmlTextWriter.start_element writer "creol:sequence" ;
	  creol_statement_to_xml s1;
	  creol_statement_to_xml s2;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Merge (a, f, n) ->
	  XmlTextWriter.start_element writer "creol:merge" ;
	  creol_statement_to_xml f ;
	  creol_statement_to_xml n ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Choice (a, f, n) ->
	  XmlTextWriter.start_element writer "creol:choice" ;
	  creol_statement_to_xml f ;
	  creol_statement_to_xml n ;
	  stmt_handler writer a ;
          XmlTextWriter.end_element writer
      | Statement.Extern (a, s) ->
	  XmlTextWriter.start_element writer "creol:extern" ;
	  XmlTextWriter.write_attribute writer "symbol" s ;
	  stmt_handler writer a ;
	  XmlTextWriter.end_element writer
  and creol_vardecl_to_xml v =
    XmlTextWriter.start_element writer "creol:vardecl";
    XmlTextWriter.write_attribute writer "name" v.var_name;
    creol_type_to_xml v.var_type;
    (match v.var_init with
	None -> ()
      | Some e -> creol_argument_to_xml e) ;
    XmlTextWriter.end_element writer
  and creol_argument_to_xml e =
    XmlTextWriter.start_element writer "creol:argument" ; 
    creol_expression_to_xml e;
    XmlTextWriter.end_element writer
  and creol_lhs_to_xml =
    function
        Expression.LhsVar (_, v) -> 
        XmlTextWriter.start_element writer "creol:variable" ;
        XmlTextWriter.write_attribute writer "name" v ;
        XmlTextWriter.end_element writer
      | Expression.LhsAttr (_, n, c) ->
        XmlTextWriter.start_element writer "creol:attribute" ;
        XmlTextWriter.write_attribute writer "name" n ;
        XmlTextWriter.end_element writer
      | Expression.LhsWildcard (_, None) ->
        XmlTextWriter.start_element writer "creol:wildcard" ;
        XmlTextWriter.end_element writer
      | Expression.LhsWildcard (_, Some c) ->
        XmlTextWriter.start_element writer "creol:wildcard" ;
	creol_type_to_xml c ;
        XmlTextWriter.end_element writer
  and creol_expression_to_xml =
    function
	Expression.Null a -> 
	  XmlTextWriter.start_element writer "creol:null" ; 
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Nil a -> 
	  XmlTextWriter.start_element writer "creol:nil" ; 
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Bool (a, v) -> 
	  XmlTextWriter.start_element writer "creol:bool" ; 
	  XmlTextWriter.write_attribute writer "value" (string_of_bool v) ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Int (a, v) -> 
	  XmlTextWriter.start_element writer "creol:int" ; 
	  XmlTextWriter.write_attribute writer "value" (string_of_int v) ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Float (a, v) -> 
	  XmlTextWriter.start_element writer "creol:float" ; 
	  XmlTextWriter.write_attribute writer "value" (string_of_float v) ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.String (a, v) -> 
	  XmlTextWriter.start_element writer "creol:string" ; 
	  XmlTextWriter.write_attribute writer "value" v ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Tuple(a, l) ->
	  XmlTextWriter.start_element writer "creol:tuple-literal" ;
	  List.iter (function e ->
	    XmlTextWriter.start_element writer "creol:element" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) l ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.ListLit(a, l) ->
	  XmlTextWriter.start_element writer "creol:list-literal" ; 
	  List.iter (function e ->
	    XmlTextWriter.start_element writer "creol:element" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) l ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.SetLit(a, l) ->
	  XmlTextWriter.start_element writer "creol:set-literal" ; 
	  List.iter (function e ->
	    XmlTextWriter.start_element writer "creol:element" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) l ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Id (a, v) -> 
	  XmlTextWriter.start_element writer "creol:identifier" ; 
	  XmlTextWriter.write_attribute writer "name" v ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.StaticAttr (a, n, c) ->
	  XmlTextWriter.start_element writer "creol:staticattr" ; 
	  XmlTextWriter.write_attribute writer "name" n ;
	  creol_type_to_xml c ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Unary (a, o, f) -> 
	  XmlTextWriter.start_element writer "creol:unary" ; 
	  XmlTextWriter.write_attribute writer "operator" 
	    (Expression.string_of_unaryop o) ;
	  XmlTextWriter.start_element writer "creol:argument" ;
	  creol_expression_to_xml f ;
          XmlTextWriter.end_element writer ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Binary (a, o, f, s) -> 
	  XmlTextWriter.start_element writer "creol:binary" ; 
	  XmlTextWriter.write_attribute writer "operator"
	    (Expression.string_of_binaryop o);
	  XmlTextWriter.start_element writer "creol:first" ;
	  creol_expression_to_xml f ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:second" ;
	  creol_expression_to_xml s ;
          XmlTextWriter.end_element writer ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.FuncCall (a, f, es) -> 
	  XmlTextWriter.start_element writer "creol:funccall" ; 
	  XmlTextWriter.write_attribute writer "name" f ;
	  XmlTextWriter.start_element writer "creol:arguments" ;
	  List.iter (function e ->
	    XmlTextWriter.start_element writer "creol:argument" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.FieldAccess (a, e, f) ->
	  XmlTextWriter.start_element writer "creol:fieldaccess" ; 
	  XmlTextWriter.write_attribute writer "name" f ;
	  creol_expression_to_xml e ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Label (a, l) ->
	  XmlTextWriter.start_element writer "creol:label" ;
	  XmlTextWriter.write_attribute writer "name" l;
	  expr_handler writer a ;
	  XmlTextWriter.end_element writer
      | Expression.New (a, c, es) ->
	  XmlTextWriter.start_element writer "creol:new" ;
	  XmlTextWriter.write_attribute writer "class" (Type.as_string c) ;
	  XmlTextWriter.start_element writer "creol:arguments" ;
	  List.iter (function e -> 
	    XmlTextWriter.start_element writer "expression" ;
	    creol_expression_to_xml e ;
            XmlTextWriter.end_element writer ) es ;
          XmlTextWriter.end_element writer ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.If (a, c, t, f) ->
	  XmlTextWriter.start_element writer "creol:if" ;
	  XmlTextWriter.start_element writer "creol:condition" ;
	  creol_expression_to_xml c ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:then" ;
	  creol_expression_to_xml t ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:else" ;
	  creol_expression_to_xml f ;
          XmlTextWriter.end_element writer ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
      | Expression.Extern (a, s) ->
	  XmlTextWriter.start_element writer "creol:extern" ; 
          XmlTextWriter.write_attribute writer "name" s ;
	  expr_handler writer a ;
          XmlTextWriter.end_element writer
  and creol_type_to_xml =
    function
	Type.Basic (a, s) ->
	  XmlTextWriter.start_element writer "creol:type" ; 
          XmlTextWriter.write_attribute writer "name" s ;
	  type_handler writer a ;
          XmlTextWriter.end_element writer
      | Type.Variable (a, s) ->
	  XmlTextWriter.start_element writer "creol:typevariable" ; 
          XmlTextWriter.write_attribute writer "name" s ;
	  type_handler writer a ;
          XmlTextWriter.end_element writer
      | Type.Application (a, s, l) ->
	  XmlTextWriter.start_element writer "creol:typeapplication" ; 
          XmlTextWriter.write_attribute writer "name" s ;
	  List.iter creol_type_to_xml l;
	  type_handler writer a ;
          XmlTextWriter.end_element writer
      | Type.Tuple(a, l) ->
	  XmlTextWriter.start_element writer "creol:tuple" ; 
	  List.iter creol_type_to_xml l;
	  type_handler writer a ;
          XmlTextWriter.end_element writer
      | Type.Function (a, dom, rng) ->
	  XmlTextWriter.start_element writer "creol:function-type" ; 
	  XmlTextWriter.start_element writer "creol:domain" ; 
	  List.iter creol_type_to_xml dom ;
          XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:range" ; 
	  creol_type_to_xml rng ;
          XmlTextWriter.end_element writer ;
	  type_handler writer a ;
          XmlTextWriter.end_element writer
      | Type.Structure (a, fields) ->
	  XmlTextWriter.start_element writer "creol:structure-type" ; 
	  List.iter (function x ->
	    XmlTextWriter.start_element writer "creol:field" ;
	    XmlTextWriter.write_attribute writer "name" x.Type.field_name ;
	    creol_type_to_xml x.Type.field_type ;
	    type_handler writer x.Type.field_note ;
	    XmlTextWriter.end_element writer) fields ;
	  type_handler writer a ;
          XmlTextWriter.end_element writer
      | Type.Variant (a, fields) ->
	  XmlTextWriter.start_element writer "creol:variabt-type" ; 
	  List.iter (function x ->
	    XmlTextWriter.start_element writer "creol:field" ;
	    XmlTextWriter.write_attribute writer "name" x.Type.field_name ;
	    creol_type_to_xml x.Type.field_type ;
	    type_handler writer x.Type.field_note ;
	    XmlTextWriter.end_element writer) fields ;
	  type_handler writer a ;
          XmlTextWriter.end_element writer
      | Type.Intersection (a, p) ->
	  XmlTextWriter.start_element writer "creol:intersection" ; 
	  List.iter creol_type_to_xml p ;
	  type_handler writer a ;
          XmlTextWriter.end_element writer
      | Type.Union (a, p) ->
	  XmlTextWriter.start_element writer "creol:union" ; 
	  List.iter creol_type_to_xml p ;
	  type_handler writer a ;
          XmlTextWriter.end_element writer	  
      | Type.Label (a, co, ins, outs) ->
	  XmlTextWriter.start_element writer "creol:label" ; 
	  XmlTextWriter.start_element writer "creol:cointerface" ; 
	  creol_type_to_xml co ;
	  XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:inputs" ; 
	  List.iter creol_type_to_xml ins ;
	  XmlTextWriter.end_element writer ;
	  XmlTextWriter.start_element writer "creol:outputs" ; 
	  List.iter creol_type_to_xml outs ;
	  XmlTextWriter.end_element writer ;
	  type_handler writer a ;
          XmlTextWriter.end_element writer
  in
    XmlTextWriter.set_indent writer true;
    XmlTextWriter.start_document writer None None None;
    XmlTextWriter.start_element writer "creol:creol";
    XmlTextWriter.write_attribute writer "version" "0.0";
    XmlTextWriter.write_attribute writer "exporter"
      (Version.package ^ " " ^ Version.version);
    List.iter (creol_declaration_to_xml) tree;
    XmlTextWriter.end_element writer;
    XmlTextWriter.end_document writer;
    XmlTextWriter.flush writer