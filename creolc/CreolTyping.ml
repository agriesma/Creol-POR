(*
 * CreolTyping.ml -- Type analysis for Creol.
 *
 * This file is part of creolcomp
 *
 * Written and Copyright (c) 2007
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

open Creol
open Expression
open Statement

exception TypeError of string * int * string


let typecheck tree: Declaration.t list =
  let cnt = ref 0 in
  let fresh_name () = let _ = incr cnt in "_" ^ (string_of_int !cnt) in
  let rec type_check_expression program cls gamma delta coiface =
    function
	This n ->
	  This (set_type n (Class.get_type cls))
      | Caller n ->
	  Caller (set_type n (Type.Basic coiface))
      | Null n ->
	  Null (set_type n (Type.Variable (fresh_name ())))
      | Nil n ->
	  Nil (set_type n (Type.Application ("List", [(Type.Variable (fresh_name ()))])))
      | Bool (n, value) ->
	  Bool (set_type n (Type.Basic "Bool"), value)
      | Int (n, value) ->
	  Int (set_type n (Type.Basic "Int"), value)
      | Float (n, value) ->
	  Float (set_type n (Type.Basic "Float"), value)
      | String (n, value) ->
	  String (set_type n (Type.Basic "String"), value)
      | Id (n, name) ->
	  let res =
	    try
	      Hashtbl.find delta name 
	    with
		Not_found ->
		  try
		    Hashtbl.find gamma name
		  with
		      Not_found ->
			raise (TypeError ((Expression.file n),
					 (Expression.line n),
					 name ^ " not declared"))
	  in
	    Id (set_type n res, name)
      | StaticAttr (n, name, cls) ->
	  (* FIXME: Here we should also check whether cls is the
	     current class name or inherited by the current class. *)
	  let res = Program.find_attr_decl program cls name in
	    StaticAttr (set_type n res.VarDecl.var_type, name, cls)
      | Unary (n, op, arg) ->
	  let narg =
	    type_check_expression program cls gamma delta coiface arg
	  in
	  let restype =
	    Type.result_type (Program.find_function program (string_of_unaryop op)
				(Type.Tuple (List.map get_type [narg]))).Operation.result_type
	  in
	    Unary (set_type n restype, op, narg)
      | Binary (n, op, arg1, arg2) ->
	  let narg1 =
	    type_check_expression program cls gamma delta coiface arg1
	  and narg2 =
	    type_check_expression program cls gamma delta coiface arg2
	  in
	  let restype =
	    (Program.find_function program (string_of_binaryop op)
				(Type.Tuple (List.map get_type [narg1; narg2]))).Operation.result_type
	  in
	    Binary (set_type n restype, op, narg1, narg2)
      | Expression.If (n, cond, iftrue, iffalse) ->
	  let ncond =
	    type_check_expression program cls gamma delta coiface cond
	  and niftrue =
	    type_check_expression program cls gamma delta coiface iftrue
	  and niffalse =
	    type_check_expression program cls gamma delta coiface iffalse
	  in
	    if (Expression.get_type ncond) = Type.boolean then
	      let restype =
		Program.meet program [get_type niftrue; get_type niffalse]
	      in
		Expression.If (set_type n restype, ncond, niftrue, niffalse)
	    else
	      raise (TypeError (Expression.file n, Expression.line n,
				"Condition must be boolean"))
      | FuncCall (n, name, args) ->
	  let nargs =
	    List.map (type_check_expression program cls gamma delta coiface)
	      args
	  in
	  let restype =
	    (Program.find_function program name (Type.Tuple (List.map get_type nargs))).Operation.result_type
	  in
	    FuncCall (set_type n restype, name, nargs)
      | Label (n, (Id (_, name) | SSAId(_, name, _) as l)) ->
	  if Hashtbl.mem delta name then
	    Label (set_type n (Type.Basic "Bool"), l)
	  else
	    raise (TypeError (Expression.file n, Expression.line n,
			    "Label " ^ name ^ " not declared"))
      | New (n, Type.Basic c, args) ->
	  let nargs =
	    List.map (type_check_expression program cls gamma delta coiface)
	      args
	  in
	    if
	      Program.subtype_p program
	        (Type.Tuple (List.map get_type nargs))
		(Type.Tuple (List.map (fun x -> x.VarDecl.var_type)
			      (Program.find_class program c).Class.parameters))
	    then
	      New (set_type n (Type.Intersection (get_interfaces (find_class program cls))), cls, nargs)
	    else
	      raise TypeError (get_file n, get_line n,
			      "Constructor argument mismatch")
      | Expression.Extern _ -> assert false
      | SSAId (n, name, version) ->
	  let res =
	    try
	      Hashtbl.find delta name 
	    with
		Not_found ->
		  try
		    Hashtbl.find gamma name
		  with
		      Not_found ->
			raise TypeError (get_file n, get_line n,
					name ^ " not declared")
	  in
	    SSAId (set_type n res, name, version)
      | Phi (n, args) ->
	  let nargs =
	    List.map (type_check_expression program cls gamma delta coiface)
	      args
	  in
	  let nty =
	    meet (List.map get_type nargs)
	  in
	    Phi (set_type n nty, nargs)
  and type_check_lhs program cls gamma delta coiface =
    function
	LhsVar (n, name) ->
	  let res =
	    try
	      Hashtbl.find delta name 
	    with
		Not_found ->
		  try
		    Hashtbl.find gamma name
		  with
		      Not_found ->
			raise TypeError (get_file n, get_line n,
					name ^ " not declared")
	  in
	    LhsVar (set_type n res, name)
      | LhsAttr (n, name, ty) ->
	  let res = find_attr_decl name program cls in
	    LhsAttr (set_type n res, name, cls)
      | LhsWildcard (n, None) ->
	  LhsWildcard(set_type n (Type.Basic "Data"), None)
      | LhsWildcard (n, Some cls) ->
	  LhsWildcard(set_type n ty, Some cls)
      | LhsSSAId (n, name, version) ->
	  let res =
	    try
	      Hashtbl.find delta name 
	    with
		Not_found ->
		  try
		    Hashtbl.find gamma name
		  with
		      Not_found ->
			raise TypeError (get_file n, get_line n,
					name ^ " not declared")
	  in
	    LhsSSAId (set_type n res, name, version)
  and type_check_statement program cls gamma delta coiface =
    function
	Skip n -> Skip n
      | Release n -> Release n
      | Assert (n, e) ->
	  Assert (n, type_check_expression program gamma delta coiface e)
      | Assign (n, lhs, rhs) ->
	  let nlhs = List.map (type_check_lhs) lhs
	  and nrhs = List.map (type_check_expression) rhs
	  in
	    if subtype_p (List.map get_lhs_type nrhs)
	      (List.map get_expression_type nlhs)
	    then
	      Assign (n, nlhs, nrhs)
	    else
	      raise TypeError (get_file n, get_line n, "Type mismatch")
      | Await (n, e) ->
	  Await (n, type_check_expression program gamma delta coiface e)
      | Posit (n, e) ->
	  Posit (n, type_check_expression program gamma delta coiface e)
      | AsyncCall (n, None, callee, meth, args) ->
	  let ncallee =
	    type_check_expression program gamma delte coiface callee
	  and nargs =
	    List.map (type_check_expression program gamma delta coiface) args
	  and co =
	    cointerface_of (find_iface program ncallee)
	  in
	    if (contracts_p cls co) &&
	      (find_in_iface meth co (List.map get_type nargs)
		  (Type.Basic "Data") (find_iface program ncallee))
	    then
	      (* A label value of none implies that the type if that
		 anonymous label is Label[Data]. *)
	      AsyncCall (n, None, ncallee, meth, nargs)
	    else
	      begin
		if ! contracts_p cls co then
		  raise TypeError (get_file n, get_line n,
				  "Class does not implement co-interace")
		else
		  raise TypeError (get_file n, get_line n,
				  "Interface does not provide method " ^ meth)
	      end
      | AsyncCall (n, Some label, callee, meth, args) ->
	  let ncallee =
	    type_check_expression program gamma delte coiface callee
	  and nargs =
	    List.map (type_check_expression program gamma delta coiface) args
	  and nlabel =
	    type_check_lhs program gamma delta coiface label
	  and co =
	    cointerface_of (find_iface program ncallee)
	  in
	    if (contracts_p cls co) &&
	      (find_in_iface meth co (List.map get_type nargs)
		  (get_type_from_label nlabel) (find_iface program ncallee))
	    then
	      AsyncCall (n, Some nlabel, ncallee, meth, nargs)
	    else
	      begin
		if ! contracts_p cls co then
		  raise TypeError (get_file n, get_line n,
				  "Class does not implement co-interace")
		else
		  raise TypeError (get_file n, get_line n,
				  "Interface does not provide method " ^ meth)
	      end
      | Reply (n, label, retvals) -> 
	  let nlabel =
	    type_check_lhs program gamma delta coiface label
	  and nretvals =
	    List.map (type_check_lhs program gamma delta coiface) retvals
	  in
	    if subtype_p (List.map get_lhs_type nouts)
	      (get_type_from_label nlabel)
	    then
	      Reply (n, nlabel, nretvals)
	    else
	      raise TypeError (get_file n, get_line n, "Type mismatch")
      | Free (n, args) -> assert false
      | LocalAsyncCall (n, None, meth, args) ->
	  let nargs =
	    List.map (type_check_expression program gamma delta coiface) args
	  in
	    if find_in_class cls meth (List.map get_type nargs)
	      (Type.Basic "Data")
	    then
	      (* A label value of none implies that the type if that
		 anonymous label is Label[Data]. *)
	      LocalAsyncCall (n, None, meth, nargs)
	    else
	      raise TypeError (get_file n, get_line n,
			      "Class does not provide method " ^ meth)
      | LocalAsyncCall (n, Some label, meth, args) ->
	  let nargs =
	    List.map (type_check_expression program gamma delta coiface) args
	  and nlabel =
	    type_check_lhs program gamma delta coiface label
	  in
	    if find_in_class cls meth (List.map get_type nargs)
	      (get_type_from_label nlabel)
	    then
	      LocalAsyncCall (n, Some nlabel, meth, nargs)
	    else
	      raise TypeError (get_file n, get_line n,
			      "Class does not provide method " ^ meth)
      | SyncCall (n, callee, meth, args, retvals) ->
	  let ncallee =
	    type_check_expression program gamma delte coiface callee
	  and nargs =
	    List.map (type_check_expression program gamma delta coiface) args
	  and nouts =
	    List.map (type_check_lhs program gamma delta coiface) retvals
	  and co =
	    cointerface_of (find_iface program ncallee)
	  in
	    if (contracts_p cls co) &&
	      (find_in_iface meth co (List.map get_type nargs)
		  (List.map get_lhs_type nouts) (find_iface program ncallee))
	    then
	      SyncCall (n, ncallee, meth, nargs, nouts)
	    else
	      begin
		if ! contracts_p cls co then
		  raise TypeError (get_file n, get_line n,
				  "Class does not implement co-interace")
		else
		  raise TypeError (get_file n, get_line n,
				  "Interface does not provide method " ^ meth)
	      end
      | AwaitSyncCall (n, callee, meth, args, retvals) ->
	  let ncallee =
	    type_check_expression program gamma delte coiface callee
	  and nargs =
	    List.map (type_check_expression program gamma delta coiface) args
	  and nouts =
	    List.map (type_check_lhs program gamma delta coiface) retvals
	  and co =
	    cointerface_of (find_iface program ncallee)
	  in
	    if (contracts_p cls co) &&
	      (find_in_iface meth co (List.map get_type nargs)
		  (List.map get_lhs_type nouts) (find_iface program ncallee))
	    then
	      AwaitSyncCall (n, ncallee, meth, nargs, nouts)
	    else
	      begin
		if ! contracts_p cls co then
		  raise TypeError (get_file n, get_line n,
				  "Class does not implement co-interace")
		else
		  raise TypeError (get_file n, get_line n,
				  "Interface does not provide method " ^ meth)
	      end	  
      | LocalSyncCall (n, meth, args, retvals) ->
	  let nargs =
	    List.map (type_check_expression program gamma delta coiface) args
	  and nouts =
	    List.map (type_check_lhs program gamma delta coiface) retvals
	  in
	    if (find_in_class cls meth (List.map get_type nargs)
		   (List.map get_lhs_type nouts))
	    then
	      LocalSyncCall (n, meth, nargs, nouts)
	    else
	      raise TypeError (get_file n, get_line n,
			      "Class does not provide method " ^ meth)
      | AwaitLocalSyncCall (n, meth, args, retvals) ->
	  let nargs =
	    List.map (type_check_expression program gamma delta coiface) args
	  and nouts =
	    List.map (type_check_lhs program gamma delta coiface) retvals
	  in
	    if (find_in_class cls meth (List.map get_type nargs)
		   (List.map get_lhs_type nouts))
	    then
	      AwaitLocalSyncCall (n, meth, nargs, nouts)
	    else
	      raise TypeError (get_file n, get_line n,
			      "Class does not provide method " ^ meth)
      | Tailcall _ -> assert false
      | If (n, cond, iftrue, iffalse) ->
	  If (n, type_check_expression program gamma delte coiface cond,
	     type_check_statement program gamma delta coiface iftrue,
	     type_check_statement program gamma delta coiface iffalse)
      | While (n, cond, body) ->
	  While (n, tyep_check_expression program gamma delte coiface cond,
		type_check_statement program gamma delta coiface body)
      | Sequence (n, s1, s2) ->
	  let ns1 = type_check_statement program gamma delta coiface s1 in
	  let ns2 = type_check_statement program gamma delta coiface s2 in
	    Sequence (n, ns1, ns2)
      | Merge (n, s1, s2) ->
	  Merge (n, type_check_statement program gamma delta coiface s1,
		type_check_statement program gamma delta coiface s2)
      | Choice (n, s1, s2) ->
	  Choice (n, type_check_statement program gamma delta coiface s1,
		 type_check_statement program gamma delta coiface s2)
      | Extern _ as s -> s
  and type_check_method program cls gamma coiface m =
    let d0 = Hashtbl.create 32 in
    let d1 = List.fold_left insert d0 m.Method.meth_inpars in
    let d2 = List.fold_left insert d1 m.Method.meth_outpars in
    let delta = List.fold_left insert d2 m.Method.meth_vars in
      match m with
	  None -> s
	| Some s -> type_check_statement program cls gamma delta coinface s
  and type_check_with_def program cls gamma w =
    List.iter (type_check_method program cls gamma w.With.co_interface)
      w.With.methods
  and type_check_class program cls =
    (* Compute the type environment within a class by adding first the class
       parameters to an empty hash table and then all attributes. *)
    let g1 = List.fold_left insert (Hashtbl.create 32) cls.Class.parameters in
    let gamma = List.fold_left insert g1 cls.Class.attributes in
      List.iter (type_check_with_def program cls gamma) cls.Class.with_defs
  and type_check_declaration program =
    function
	Declaration.Class c -> type_check_class program c
      | _ as d -> d
  in
      type_check_declaration tree
