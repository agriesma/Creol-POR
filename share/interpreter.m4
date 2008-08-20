include(macros.m4)dnl
dnl The usual header.
***
*** Reimplementation of the CREOL KIND
***
*** Copyright (c) 2007, 2008
***
*** Do NOT edit this file.  This file may be overwritten.  It has been
*** automatically generated from interpreter.m4 using m4.
***
*** This file has been generated from interpreter.m4 ($Revision$)
***
*** This program is free software; you can redistribute it and/or
*** modify it under the terms of the GNU General Public License as
*** published by the Free Software Foundation; either version 3 of the
*** License, or (at your option) any later version.
***
*** This program is distributed in the hope that it will be useful, but
*** WITHOUT ANY WARRANTY; without even the implied warranty of
*** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
*** General Public License for more details.
***
*** You should have received a copy of the GNU General Public License
*** along with this program.  If not, see <http://www.gnu.org/licenses/>.
***

ifdef(`MODELCHECK', `load model-checker .
')dnl
load creol-datatypes .


***************************************************************************
***
*** Signature of programs and states.
***
***************************************************************************

***
*** Binding variables to values.
***
ifdef(`FAILED-EXPERIMENTS',dnl
*** In Maude 2.3`,' MAP checks whether the variable is bound for each insert.
*** This check`,' however`,' is the main performance issue of the model
*** checker:  over 13% of the rewrites are for $hasMapping from MAP this
*** map implementation.  We could replace map with our own and making use
*** of the assumption`,' that insert behaves well in our case.
*** 
*** This is an experimental version`,' where we roll our own version of a
*** substitution.  It saves a lot of rewrites`,' but matching becomes much
*** more expensive with this version`,' which causes a substantial run-time
*** regression.
fmod CREOL-SUBST is
  protecting BOOL .
  protecting EXT-BOOL .
  protecting CREOL-DATATYPES .

  sort Binding Subst .
  subsort Binding < Subst .

  op _|->_ : Vid Data -> Binding [ctor] .
  op noSubst : -> Subst [ctor] .
  op _`,'_ : Subst Subst -> Subst [ctor assoc comm id: noSubst prec 121 `format' (d r os d)] .
  op undefined : -> [Data] [ctor] .
  
  vars A A' : Vid .
  vars D D' : Data .
  vars S1 S2  : Subst .

  op insert : Vid Data Subst -> Subst .
  eq insert(A`,' D`,' (S1`,' A |-> D')) =
     if $hasMapping(S1`,' A) then insert(A`,' D`,' S1)
     else (S1`,' A |-> D)
     fi .
  eq insert(A`,' D`,' S1) = (S1`,' A |-> D) [owise] .

  op $hasMapping : Subst Vid -> Bool .
  eq $hasMapping((S1`,' A |-> D)`,' A) = true .
  eq $hasMapping(S1`,' A) = false [owise] .

  *** Lazy composition operator for substitutions
  op _::_ : Subst Subst -> Subst [strat (0)] .

  *** Get a value
  op _[_] : Subst Vid -> [Data] [prec 23] .
  eq (S1 :: (S2`,' A |-> D))[ A ] = D .
  eq ((S1`,' A |-> D) :: S2)[ A ] = D .
  eq (S1`,' A |-> D)[A] = D .
  eq S1[A] = undefined [owise] .

  *** Composition operater for substitutions
  op compose : Subst Subst -> Subst .
  eq compose(S1`,' noSubst) = S1 .
  eq compose(noSubst`,' S2) = S2 .
  eq compose(S1`,' (S2`,' (A |-> D))) = compose(insert(A`,' D`,' S1)`,' S2) .
endfm
,dnl
*** Use MAP from prelude.  This seems to be the fastest solution.
***
fmod CREOL-SUBST is
  protecting CREOL-DATATYPES .
  extending MAP{Vid`,' Data} * (sort Map{Vid`,'Data} to Subst`,'
                              sort Entry{Vid`,'Data} to Binding`,'
                              op empty : -> Map{Vid`,'Data} to noSubst) .

  vars A A' : Vid .
  vars D D' : Data .
  vars S1 S2  : Subst .

  *** Lazy composition operator for substitutions
  op _::_ : Subst Subst -> Subst .
  eq (S1 :: S2)[A] = if $hasMapping(S2`,' A) then S2[A] else S1[A] fi .

  *** Composition operater for substitutions
  op compose : Subst Subst -> Subst .
  eq compose(S1`,' noSubst) = S1 .
  eq compose(noSubst`,' S2) = S2 .
  eq compose(S1`,' (S2`,' (A |-> D))) = compose(insert(A`,' D`,' S1)`,' S2) .
endfm
)


*** Creol Statements
***
*** The following module defines all elementary statements of Creol.
fmod CREOL-STATEMENT is

  protecting CREOL-DATA-VIDLIST .
  protecting CREOL-EXPRESSION .
  protecting CREOL-SUBST .

  *** SuspStmt is a statement which can be suspended.  It includes
  *** await, [] and ||| (the later two defined in CREOL-STM-LIST.
  sorts Stmt SuspStmt .
  subsort SuspStmt < Stmt .

  op skip : -> Stmt [ctor `format' (b o)] .
  op release : -> Stmt [ctor `format' (b o)] .
  op assign(_;_) : VidList ExprList -> Stmt [ctor `format' (b d o b o b o)] .
  op new(_;_;_) : Vid String ExprList -> Stmt [ctor `format' (b d o b o b o b o)] .
  op call(_;_;_;_) : Vid Expr String ExprList -> Stmt [ctor `format' (b d o b o b o b o b o)] . 
  op static(_;_;_;_) : Vid String String ExprList -> Stmt [ctor `format' (b d o b o b o b o b o)] . 
  op get(_;_)  : Vid VidList -> Stmt [ctor prec 39 `format' (b d o b o b o)] .
  op get(_;_)  : Label VidList -> Stmt [ctor ditto] .
  op await_ : Expr -> SuspStmt [ctor `format' (b o d)] .
  op posit_ : Expr -> SuspStmt [ctor `format' (b o d)] .
  op assert(_) : Expr -> Stmt [ctor `format' (b o d b o)] .
  op return(_) : ExprList -> Stmt [ctor `format' (c d o c o)] .
  op free(_) : Vid -> Stmt [ctor `format' (c d o c o)] .
  op tailcall(_;_) : String ExprList -> Stmt [ctor `format' (c d o c o c o)] .
  op tailcall(_;_;_) : String String ExprList -> Stmt [ctor `format' (c d o c o c o c o)] .

  op $cont(_) : Label -> Stmt [ctor `format' (c d o c o)] .
  op $accept(_) : Label -> Stmt [ctor `format' (c d o c o)] .

  --- multiple assignment
  ---
  --- For the model checker the following will be evaluated as an
  --- equation and the old rule is not confluent.

  op $assign(_;_) : VidList DataList -> Stmt  [`format' (c d o c o c o)] .

  --- This ``statement'' represents an assertion failure.  It 
  --- stops evaluation of the executing object at that point.
  op failure(_) : Expr -> [Stmt] [ctor `format' (r! d o r! o)] .

endfm

view Stmt from TRIV to CREOL-STATEMENT is
   sort Elt to Stmt .
endv



*** Specification of compound statements.
***
fmod CREOL-STM-LIST is
  protecting CREOL-STATEMENT .                
  protecting LIST{Stmt} * (sort List{Stmt} to StmtList,
                          sort NeList{Stmt} to NeStmtList,
			  op nil : -> List{Stmt} to noStmt,
			  op __ : List{Stmt} List{Stmt} -> List{Stmt} to _;_ [`format' (d r o d)]) .

  op if_th_el_fi : Expr NeStmtList NeStmtList -> Stmt [ctor `format' (b o b o b o b o)] . 
  op while_do_od : Expr NeStmtList -> Stmt [ctor `format' (b o b o b o)] .
  op _[]_  : NeStmtList NeStmtList -> SuspStmt [ctor comm assoc prec 45 `format' (d r d o d)] .
  op _|||_ : NeStmtList NeStmtList -> SuspStmt [ctor comm assoc prec 47 `format' (d r o d)] .
  op _MERGER_  : StmtList StmtList -> Stmt [ctor assoc `format' (d c! o d)] .

  var SL : StmtList .
  var NeSL : NeStmtList .
  var AL : VidList .
  var DL : DataList .
  var EL : ExprList .
  var B : Expr .

  *** Some simplifications:
  eq noStmt MERGER SL = SL .
  eq SL MERGER noStmt = SL .

  --- Optimize assignments.  This way we save reducing a skip.  Also note
  --- that the empty assignment is /not/ programmer syntax, it is inserted
  --- during run-time.
  eq assign(noVid ; emp) = noStmt .
  eq $assign(noVid ; emp) = noStmt .

endfm

fmod CREOL-PROCESS is

  protecting CREOL-STM-LIST .

  sort Process .

  op idle : -> Process [ctor `format' (!b o)] .  
  op notFound : -> Process [ctor `format' (!b o)] .  
  op {_|_} : Subst StmtList -> Process [ctor `format' (r o r o r o)] . 

  var L : Subst .
  eq { L | noStmt } = idle . --- if ".label" is needed this is dangerous!
  eq idle = { noSubst | noStmt } [nonexec metadata "Causes infinite loops."] .

endfm



*** Specifies a process pool, here a multiset of Processes
***
fmod CREOL-PROCESS-POOL is

  protecting CREOL-PROCESS .

  sort MProc .
  subsort Process < MProc .
  op noProc : -> MProc [ctor] .
  op _,_ : MProc MProc -> MProc
    [ctor assoc comm id: noProc prec 41 `format' (d r os d)] .

endfm



*** An inherits declaration
***
fmod CREOL-INHERIT is
  protecting CREOL-DATATYPES .
  sort Inh .

  op  _<_> : String  ExprList -> Inh [ctor prec 15] .

endfm

view Inh from TRIV to CREOL-INHERIT is
  sort Elt to Inh .
endv

fmod CREOL-METHOD is
  protecting CREOL-STM-LIST .
  sort Method .

  op <_: Method | Param:_, Att:_, Code:_> : 
    String VidList Subst StmtList -> Method [ctor
      `format' (c ! oc o d sc o d sc o d sc o c o)] .

endfm

view Method from TRIV to CREOL-METHOD is
  sort Elt to Method .
endv



include(`configuration.m4')



*** Now we proceed to define the family of eval functions.
mod `CREOL-EVAL' is

    protecting CREOL-CONFIGURATION .

    vars N N' : Nat .
    vars L L' : Label .
    vars E E' E'' : Expr .
    vars D D' : Data .
    var DL : DataList .
    var EL : ExprList .
    var NeEL : NeExprList .
    var ES : ExprSet .
    var NeES : NeExprSet .
    var DS : DataSet .
    var NeDS : NeDataSet .
    var A : Vid .
    vars Q C : String .
    vars S S' : Subst .
    var MM : MMsg .

    --- Check if a message is in the queue.
    op inqueue  : Label MMsg -> Bool .
    eq inqueue(L, noMsg) = false .
    eq inqueue(L, MM + comp(L', EL)) =
	  if L == L' then true else inqueue(L, MM) fi .

    vars ST ST' : Stmt . 
    vars SL SL1 SL2 : StmtList . 
    vars NeSL NeSL1 NeSL2 : NeStmtList .
    var AL : VidList .
    var M : ExprMap .
dnl
dnl Macros for dealing with enabledness and readyness in the timed and
dnl untimed cases.
dnl
ifdef(`TIME',dnl
    var T : Float .

    op evalGuard : Expr Subst MMsg Float -> Data .
    op evalGuardList : ExprList Subst MMsg Float -> DataList [strat (1 0 0 0 0)] .
    op evalGuardSet : ExprSet Subst MMsg Float -> DataSet [strat (1 0 0 0 0)] .
    op evalGuardMap : ExprMap Subst MMsg Float -> DataMap [strat (1 0 0 0 0)] .
    op enabled : NeStmtList Subst MMsg Float -> Bool .
    op ready : NeStmtList Subst MMsg Float -> Bool .
,dnl Untimed:

    op evalGuard : Expr Subst MMsg -> Data .
    op evalGuardList : ExprList Subst MMsg -> DataList [strat (1 0 0 0)] .
    op evalGuardSet : ExprSet Subst MMsg -> DataSet [strat (1 0 0 0)] .
    op evalGuardMap : ExprMap Subst MMsg -> DataMap [strat (1 0 0 0)] .
    op enabled : NeStmtList Subst MMsg -> Bool .
    op ready : NeStmtList Subst MMsg -> Bool .
)dnl

    eq EVALGUARD(D, S, MM, T) = D .
    eq EVALGUARD(now, S, MM, T) = ifdef(`TIME', time(T), time(0.0)) .
    eq EVALGUARD((Q @ C), (S :: S'), MM, T) =  S [Q] .
    eq EVALGUARD(Q, (S :: S'), MM, T) =  S' [Q] [nonexec] . *** XXX: Later
    eq EVALGUARD(A, S, MM, T) =  S [A] .
    eq EVALGUARD(Q (EL), S, MM, T) = Q ( EVALGUARDLIST(EL, S, MM, T) ) .
    eq EVALGUARD(?(A), S, MM, T) = bool(inqueue(S[A], MM)) .
    eq EVALGUARD(?(L), S, MM, T) = bool(inqueue(L, MM)) .
    eq EVALGUARD(list(EL), S, MM, T) = list(EVALGUARDLIST(EL, S, MM, T)) .
    eq EVALGUARD(set(ES), S, MM, T) = set(EVALGUARDSET(ES, S, MM, T)) .
    eq EVALGUARD(map(M), S, MM, T) = map(EVALGUARDMAP(M, S, MM, T)) .
    eq EVALGUARD(if E th E' el E'' fi, S, MM, T) =
      if EVALGUARD(E, S, MM, T) asBool
      then EVALGUARD(E', S, MM, T)
      else EVALGUARD(E'', S, MM, T) fi .

    --- Evaluate guard lists.  This is almost the same as evalList, but we
    --- had to adapt this to guards.
    eq EVALGUARDLIST(emp, S, MM, T) = emp .
    eq EVALGUARDLIST(DL, S, MM, T) = DL .   --- No need to evaluate.
    eq EVALGUARDLIST(E, S, MM, T) = EVALGUARD(E, S, MM, T) .
    eq EVALGUARDLIST(E :: NeEL, S, MM, T) =
      EVALGUARD(E, S, MM, T) :: EVALGUARDLIST(NeEL, S, MM, T) .

    eq EVALGUARDSET(emptyset, S, MM, T) = emptyset .
    eq EVALGUARDSET(DS, S, MM, T) = DS .  ---  No need to evaluate
    eq EVALGUARDSET(E, S, MM, T) = EVALGUARD(E, S, MM, T) .
    eq EVALGUARDSET(E : NeES, S, MM, T) =
    EVALGUARD(E, S, MM, T) : EVALGUARDSET(NeES, S, MM, T) .

    --- Evaluate a map.
    eq EVALGUARDMAP(empty, S, MM, T) = empty .
   eq EVALGUARDMAP((D |=> D', M), S, MM, T) =
     (D |=> D' , EVALGUARDMAP(M, S, MM, T)) .  --- No need to evaluate .
   eq EVALGUARDMAP((D |=> E', M), S, MM, T) =
     (D |=> EVALGUARD(E', S, MM, T) , EVALGUARDMAP(M, S, MM, T)) .
   eq EVALGUARDMAP((E |=> D', M), S, MM, T) =
     (EVALGUARD(E, S, MM, T) |=> D' , EVALGUARDMAP(M, S, MM, T)) .
   eq EVALGUARDMAP((E |=> E', M), S, MM, T) =
     (EVALGUARD(E, S, MM, T) |=> EVALGUARD(E', S, MM, T) ,
     EVALGUARDMAP(M, S, MM, T)) .

    --- Enabledness
    eq ENABLED((NeSL [] NeSL1) ; SL2,  S, MM, T) =
         ENABLED(NeSL, S, MM, T) or ENABLED(NeSL1, S, MM, T) .
    eq ENABLED((NeSL ||| NeSL1) ; SL2, S, MM, T) =
         ENABLED(NeSL, S, MM, T) or ENABLED(NeSL1, S, MM, T) .
    eq ENABLED((NeSL MERGER SL1) ; SL2, S, MM, T) = ENABLED(NeSL, S, MM, T) .
    eq ENABLED(await E ; SL2, S, MM, T) = EVALGUARD(E, S, MM, T) asBool .
dnl ifdef(`TIME',dnl
dnl  eq ENABLED(posit E ; SL2, S, MM, T) = EVALGUARD(E, S, MM, T) asBool .
dnl)dnl
    eq ENABLED(NeSL, S, MM, T) = true [owise] .

    --- The ready predicate holds, if a statement is ready for execution,
    --- i.e., the corresponding process may be waken up.
    eq READY((NeSL [] NeSL1) ; SL2, S, MM, T) =
          READY(NeSL, S, MM, T) or READY(NeSL1, S, MM, T) .
    eq READY((NeSL ||| NeSL1) ; SL2, S, MM, T) =
	  READY(NeSL, S, MM, T) or READY(NeSL1, S, MM, T) .
    eq READY((NeSL MERGER SL1) ; SL2, S, MM, T) = READY(NeSL, S, MM, T) .
    eq READY(get(A ; AL) ; SL2 , S, MM, T) = inqueue(S[A], MM) . 
    eq READY(get(L ; AL) ; SL2 , S, MM, T) = inqueue(L, MM) . 
    eq READY(NeSL, S, MM, T) = ENABLED(NeSL, S, MM, T) [owise] .

endm

include(`machine.m4')

ifdef(`MODELCHECK', include(`predicates.m4'))dnl

eof
