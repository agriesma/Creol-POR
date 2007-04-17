dnl
dnl interpreter.m4 -- Source for modelchecker.maude and interpreter.maude
dnl
dnl Copyright (c) 2007 Marcel Kyas
dnl
dnl The purpose of this file is to create the files `interpreter.maude'
dnl and `modelchecker.maude'.  These files have to be processed with
dnl m4, with either one of `CREOL' or `MODELCHECK' defined.
dnl
changequote({|,|})dnl
dnl
dnl The macro STEP is used to indicate that the specified transition
dnl may be both an equation (this is the case for model checking,
dnl or a rule (in the interpreter).
dnl $1 is the pre-condition of the rule.
dnl $2 is the post-condition of the rule.
dnl $3 is an annotation.  It must not be empty, and usually contains at
dnl    least the label.
define({|STEP|},dnl
ifdef({|MODELCHECK|},
{|eq
  $1
  =
  $2
  $3 .|},
{|rl
  $1
  =>
  $2
  $3 .|}))dnl
dnl
dnl The macro CSTEP is used to indicate that the specified transition
dnl may be both a conditional equation (this is the case for model checking),
dnl or a conditional rule (in the interpreter).
dnl $1 is the pre-condition of the rule.
dnl $2 is the post-condition of the rule.
dnl $3 is the condition.
dnl $4 is an annotation.  It must not be empty, and usually contains at
dnl    least the label.
define({|CSTEP|},dnl
ifdef({|MODELCHECK|},
{|ceq
  $1
  =
  $2
  if $3
  $4 .|},
{|crl
  $1
  =>
  $2
  if $3
  $4 .|}))dnl
dnl The usual header.
***
ifdef({|MODELCHECK|},dnl
{|*** Modelchecker for Creol.|},dnl
{|*** Reimplementation of the CREOL interpreter, 2007|})
***
*** Copyright (c) 2007
***
*** Do NOT edit this file.  This file may be overwritten.  It has been
*** automatically generated from interpreter.m4 using m4.
***
*** This program is free software; you can redistribute it and/or
*** modify it under the terms of the GNU General Public License as
*** published by the Free Software Foundation; either version 2 of the
*** License, or (at your option) any later version.
***
*** This program is distributed in the hope that it will be useful, but
*** WITHOUT ANY WARRANTY; without even the implied warranty of
*** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
*** General Public License for more details.
***
*** You should have received a copy of the GNU General Public License
*** along with this program; if not, write to the Free Software
*** Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
*** 02111-1307, USA.
***

ifdef({|MODELCHECK|},{|in model-checker|})

*** Data types are in their own module.
load datatypes


***************************************************************************
***
*** Signature of programs and states.
***
***************************************************************************

*** Bound variables ***
fmod SUBST is
  protecting EXT-BOOL .
  protecting CREOL-DATA-SIG .
  protecting MAP{Aid, Data} * (sort Map{Aid, Data} to Subst,
                               op empty : -> Map{Aid, Data} to noSubst ) .

  vars A A' : Aid .
  vars D D' : Data .
  vars S1 S2  : Subst .

  *** Non-comm composition operator for substitutions
  op _#_ : Subst Subst -> Subst .
  eq S1 # noSubst = S1 .
  eq noSubst # S2 = S2 .
  eq (S1 {|#|} S2)[ A ] = if dom(A, S2) then S2[A] else S1[A] fi .

  op dom : Aid Subst -> Bool .
  eq dom(A, S1 # S2) = dom(A, S2) or-else dom(A, S1) .
  eq dom(A, (S1, A |-> D)) = true .
  eq dom(A, S1) = false [owise] .
endfm

fmod EVAL is
  protecting DATATYPES .
  protecting SUBST .

  var D : Data .
  var DL : DataList .
  vars E E' : Expr .
  var EL : ExprList .
  var NeEL : NeExprList .
  var A : Aid .
  var S : Subst .
  var F : String .
  var I : Int .
  var B : Bool .

  op eval : Data Subst -> Data .
  eq {|eval|}(D, S) = D .

  *** standard evaluation of expression
  op eval     : Expr Subst     -> Data .
  eq {|eval|}(A, S) =  S [A] .
  eq {|eval|}(F (EL), S) = F ( evalList(EL, S) ) .
  eq {|eval|}(list(EL), S) = list(evalList(EL, S)) .
  eq {|eval|}(pair(E,E'),S) = pair({|eval|}(E,S),{|eval|}(E',S)) .
  eq {|eval|}(setl(EL), S) = setl(evalList(EL, S)) .

  op evalList : DataList Subst -> DataList .
  eq evalList(emp, S) = emp .
  eq evalList(DL, S)= DL .

  op evalList : ExprList Subst -> DataList .
  eq evalList(E , S) = {|eval|}(E, S) .
  eq evalList(E {|#|} NeEL, S) = {|eval|}(E, S) {|#|} evalList(NeEL, S) .

endfm


fmod GUARDS is
  protecting EVAL .

  sorts NoGuard Guard Wait Return PureGuard . 
  subsorts Return Expr < PureGuard .
  subsorts NoGuard Wait PureGuard < Guard .

  vars E E' : Expr .
  var PG : PureGuard .

  op noGuard : -> NoGuard [ctor {|format|} (b o)] .
  op wait :    -> Wait [ctor {|format|} (b o)] .
  op _??  : Aid -> Return [ctor] .
  op _??  : Label -> Return [ctor] .
  op _&_ : Guard Guard -> Guard [ctor id: noGuard assoc comm prec 55] .
  op _&_ : PureGuard PureGuard -> PureGuard [ditto] .

  eq wait & wait = wait .
  eq PG & PG = PG .
  eq E & E' = "and" (E # E') .

endfm

fmod STATEMENTS is
  pr GUARDS .

  sorts Mid Cid Stm .
  subsort String < Mid Cid .

  op _._   : Expr Mid -> Mid [ctor prec 33] .
  op _@_   : Mid  Cid -> Mid [ctor prec 33] .
  op _@_   : Aid  Cid -> Mid [ctor prec 33] .

  op skip : -> Stm [ctor] .
  op _::=_ : AidList ExprList -> Stm [ctor prec 39] .
  op _::= new_(_) : Aid Cid ExprList -> Stm [ctor prec 37 {|format|} (d b d o d d d d)] .
  op _(_;_) : Mid ExprList AidList -> Stm [ctor prec 39] .
  op _!_(_) : Aid Mid ExprList -> Stm [ctor prec 39] .
  op _?(_)  : Aid AidList -> Stm [ctor prec 39] .
  op _?(_)  : Label AidList -> Stm [ctor prec 39] .
  op await_ : Guard    -> Stm [ctor] .
  op return : ExprList -> Stm [ctor {|format|} (c o)] .
  op free : AidList -> Stm [ctor {|format|} (c o)] .
  op bury : AidList -> Stm [ctor {|format|} (c o)] .
  op cont : Label -> Stm [ctor {|format|} (c o)] .
  op tailcall_(_) : Mid ExprList -> Stm [ctor {|format|} (c o c o c o)] .
  op accept : Label -> Stm [ctor {|format|} (c o)] .

  *** multiple assignment
  ***
  *** For the model checker the following will be evaluated as an
  *** equation and the old rule is not confluent.

  op _assign_ : AidList DataList -> Stm [ctor {|format|} (d c o d)] .

endfm

view Stm from TRIV to STATEMENTS is
   sort Elt to Stm .
endv

fmod STM-LIST is
  pr STATEMENTS .                
  protecting LIST{Stm} * (sort List{Stm} to StmList,
                          sort NeList{Stm} to NeStmList,
			  op nil : -> List{Stm} to noStm,
			  op __ : List{Stm} List{Stm} -> List{Stm} to _;_) .

  op if_th_el_fi : Expr StmList StmList -> Stm [ctor] . 
  op while_do_od : Expr StmList -> Stm [ctor] .
  op _[]_  : StmList StmList -> Stm [ctor comm assoc prec 45] .
  op _|||_ : StmList StmList -> Stm [ctor comm assoc prec 47] .
  op _MERGER_  : StmList StmList -> Stm [assoc] .

  var SL : StmList .
  var NeSL : NeStmList .
  var AL : AidList .
  var DL : DataList .
  var EL : ExprList .
  var B : Expr .
  var PG : PureGuard .

  *** Some simplifications:
  eq await noGuard ; NeSL = NeSL . *** could be SL
  eq noAid ::= emp = skip [nonexec] .
  ***  eq skip ; SL = SL . *** may affect ||| order 
  eq (noStm []  SL)  = SL . 
  eq (noStm ||| SL)  = SL . 
  eq (noStm MERGER SL)      = SL .
  eq (SL MERGER noStm)      = SL .

  *** Optimize assignments.  This way we save reducing a skip.  Also note
  *** That the empty assignment is /not/ programmer syntax, it is inserted
  *** during run-time.
  eq (AL ::= DL) = (AL assign DL) .
  eq (noAid assign emp) = noStm .
  eq (noAid ::= emp) = noStm .

  eq await (wait & PG) = await wait ; await PG .
  *** eq await (R & PG)= await R ; await PG . --- could be rule for confluence!

  sort Process .
  op idle : -> Process [{|format|} (!b o)] .  
  op _,_ : Subst StmList -> Process [ctor {|format|} (o r sbu o)] . 
  var L : Subst .
  eq (L, noStm) = idle . *** if "label" is needed this is dangerous!
  eq idle = (noSubst, noStm) [nonexec metadata "Will cause infinite loops."] .


  sorts NeMProc MProc .
  subsort Process < NeMProc < MProc .    *** Multiset of Processes
  op noProc : -> MProc [ctor] .
  op _++_ : MProc MProc -> MProc [ctor assoc comm id: noProc prec 41 {|format|} (d r os d)] .
  op _++_ : NeMProc MProc -> NeMProc [ctor ditto] .

endfm

*** CREOL classes ***
fmod CLASS is
  protecting STM-LIST .

  sorts    Class Mtd MMtd Inh InhList . *** inheritance list
  subsorts Inh < Expr .  
  subsorts Inh < InhList .

  op  _<_> : Cid  ExprList -> Inh [ctor prec 15] . *** initialised superclass
  op noInh : -> InhList [ctor] .
  op  _##_   : InhList InhList -> InhList [ctor assoc id: noInh] .

  var Ih : Inh . 
  var IL : InhList .
  var S : Subst . 
  var SL : StmList . 
  var MM : MMtd .
  var EL : ExprList .
  var O : Oid .
  var N : Nat .
  var AL : AidList .
  vars Q Q' : String .

  *** XXX: This looks dangerous or confusing for programmers.
  *** Why not: Ih ## IL ## Ih = IL ## Ih to have Ih initialised last?

  eq  Ih ## IL ## Ih = Ih ## IL .

  op <_: Mtdname | Param:_, Latt:_, Code:_> : 
    String AidList Subst StmList -> Mtd [ctor
      {|format|} (b d o d d sb o d sb o d sb o b o)] .

  subsort Mtd < MMtd .    *** Multiset of methods

  op noMtd : -> Mtd [ctor] .
  op _*_  : MMtd MMtd -> MMtd [ctor assoc comm id: noMtd {|format|} (d d ni d)] .

  op <_: Cl | Inh:_, Par:_, Att:_, Mtds:_, Ocnt:_> : 
    Cid InhList AidList Subst MMtd Nat -> Class 
     [{|format|} (ng d o d d  sg o d  sg o d  sg o d  sg++ oni o  gni o-- g o)] .

  op emptyClass : -> Class .
  eq emptyClass =
    < "NoClass" : Cl | Inh: noInh , Par: noAid, Att: noSubst, Mtds: noMtd ,
      Ocnt: 0 > .

  *** Class/method functions ***
  op get : String MMtd Oid Label ExprList -> Process .  *** fetches pair (code, vars)
  op _in_ : String MMtd -> Bool .  *** checks if Q is a declared 
                                *** method in the method multiset

  eq Q in noMtd = false .
  eq Q in (< Q' : Mtdname | Param: AL, Latt: S, Code: SL > * MM) = 
       if (Q == Q') then true else (Q in MM) fi .

  *** bind call to process
  var Lab : Label .
  eq get(Q, noMtd, O, Lab, EL) = noProc . 
  eq get(Q, < Q' : Mtdname | Param: AL, Latt: S, Code: SL > * MM, O, Lab, EL) = 
    if Q == Q' 
    then (insert("caller", O, insert("label", Lab, S)), (AL ::= EL) ; SL)
    else get(Q, MM, O, Lab, EL) fi .

endfm

*** CREOL objects ***
fmod OBJECT is
  protecting CLASS .

  sort Object .

  op <_:_ | Att:_, Pr:_, PrQ:_, Lcnt:_> : 
       Oid Cid Subst Process MProc Nat -> Object 
         [ctor {|format|} (nr d d g r d o  r++ ni o  r ni o  r s o--  r o)] .

  op noObj : -> Object [ctor] .

endfm

*** CREOL messages and queues ***
fmod COMMUNICATION is
  protecting OBJECT .

  sort Labels . *** list of labels
  subsort Label < Labels .

  sorts Body Msg MMsg Kid Queue .
  subsort Body < MMsg .

  op noMsg : -> MMsg [ctor] .
  op _+_ : MMsg MMsg -> MMsg [ctor assoc comm id: noMsg] . 

  op size : MMsg -> Nat .
  var M : Body .
  var MB : MMsg .
  eq size(M + MB) = 1 + size(MB) .
  eq size(noMsg) = 0 .

  *** INVOCATION and REPLY
  op invoc(_,_,_,_) : *** Nat Oid 
  Oid Label Mid DataList -> Body [ctor {|format|} (! o o o o o o o o o o)] .  
  op comp(_,_) : Label DataList -> Body [ctor {|format|} (! o o o o o o)] .  

  op _from_to_ : Body Oid Oid -> Msg [ctor {|format|} (o ! o ! o on)] .
  op error(_) : String -> [Msg] [ctor {|format|} (nnr r o! or onn)] .     *** error 
  op warning(_) : String -> [Msg] [ctor {|format|} (nnr! r! r! or onn)] .   *** warning 

  *** Method binding messages
  op bindMtd : Oid Oid Label String ExprList InhList -> Msg [ctor] . 
  ***Bind method request
  *** Given: caller callee method params (list of classes to look in)
  op boundMtd(_,_) : Oid Process -> Msg 
    [ctor {|format|} (!r r o o o !r on)] . *** binding result
  *** CONSIDER the call O.Q(I). bindMtd(O,Q,I,C S) trie to find Q in
  *** class C or superclasses, then in S. boundMtd(O,Mt) is the result.


  *** message queue
  op noDealloc :         -> Labels  [ctor] .
  op _^_ : Labels Labels -> Labels [ctor comm assoc id: noDealloc] .

  op noQu : -> Queue [ctor] .
  op <_: Qu | Size:_, Dealloc:_, Ev:_ > : Oid Nat Labels MMsg -> Queue 
                          [{|format|} (nm r o d d sm o d sm o d sm o m o)] .

endfm

*** STATE CONFIGURATION ***
fmod CONFIG is
  protecting OBJECT .
  protecting COMMUNICATION .

  sort Configuration .

  subsorts Object Msg Queue Class < Configuration .

  op noConf : -> Configuration [ctor] .
  op __ : Configuration Configuration -> Configuration
	[ctor assoc comm id: noConf {|format|} (d n d)] .
  op main : Cid ExprList -> Configuration .

  var C : Cid . var E : ExprList .
  eq main(C,E) = < ob("main") : "NoClass" | Att: noSubst, 
                 Pr: (noSubst, ("var" ::= new C(E))), PrQ: noProc, Lcnt: 0 > 
               < ob("main") : Qu | Size: 1, Dealloc: noDealloc,Ev: noMsg > .

endfm

*** AUXILIARY FUNCTIONS ***
fmod AUX-FUNCTIONS is

  protecting CONFIG .
  protecting CONVERSION .

  *** Check if a message is in the queue.
  op inqueue  : Label MMsg -> Bool .

  op enabledGuard : Guard   Subst MMsg -> Bool .
  op enabled      : StmList Subst MMsg -> Bool . *** eval guard 
  op ready        : StmList Subst MMsg -> Bool . *** eval guard 

  vars N N' : Nat .
  vars L L' : Label .
  vars E E' : Expr .
  var EL : ExprList .
  var A : Aid .
  var Q : String .
  vars G1 G2 : Guard .
  var S : Subst .
  var MM : MMsg .
  var C : Cid .

  *** Create a new fresh name for an object.
  op newId : Cid Nat -> Oid .
  eq newId(C, N)  = ob(C + string(N,10)) .

  eq inqueue(L, noMsg) = false .
  eq inqueue(L, comp(L', EL) + MM) = 
     if L == L' then true else inqueue(L, MM) fi .

  eq enabledGuard(noGuard, S, MM)   = true .
  eq enabledGuard(wait, S, MM)      = false .       *** Note: no wait in PrQ!
  eq enabledGuard(E, S, MM)         = {|eval|}(E, S) asBool .
  eq enabledGuard((A ??), S, MM)     = inqueue(S[A], MM) .
  eq enabledGuard((L ??), S, MM)     = inqueue(L, MM) .

  vars  ST ST' : Stm . 
  vars SL SL' : StmList . 
  var NeSL : NeStmList .

  eq enabled(SL [] SL',  S, MM) = enabled(SL, S, MM) or enabled(SL', S, MM) .
  eq enabled(SL ||| SL', S, MM) = enabled(SL, S, MM) or enabled(SL', S, MM) .
  eq enabled(await G1,   S, MM) = enabledGuard(G1,S,MM) .
  eq enabled((ST ; ST' ; SL),S, MM) = enabled(ST, S, MM) . 
  eq enabled(ST,    S, MM) = true [owise] . 

  eq ready(SL [] SL',  S, MM) = ready(SL, S, MM) or ready(SL', S, MM) .
  eq ready(SL ||| SL', S, MM) = ready(SL, S, MM) or ready(SL', S, MM) .
  eq ready(A ?(E),     S, MM) = inqueue(S[A], MM) . 
  eq ready(L ?(E),     S, MM) = inqueue(L, MM) . 
  eq ready((ST ; ST' ; SL), S, MM) = ready(ST, S, MM) . 
  eq ready(ST,         S, MM) = enabled(ST, S, MM) [owise] .

endfm

*** THE MACHINE ***
mod ifdef({|MODELCHECK|},CREOL-MODEL-CHECKER,INTERPRETER) is

  extending CREOL-DATA-SIG .

  protecting AUX-FUNCTIONS .

  vars O O' : Oid .
  vars C C' : Cid .
  vars A A' : Aid .
  var AL : AidList .
  var NeAL : NeAidList .
  var D : Data .
  var DL : DataList .
  var NeDL : NeDataList .
  vars E E' : Expr .
  vars EL EL' : ExprList .
  vars NeEL NeEL' : NeExprList .
  var ST : Stm .
  vars SL SL' SL'' : StmList .
  vars SL1 SL2 : NeStmList .
  vars P P' : Process .
  var W : MProc .
  vars S S' L L' : Subst .
  vars N F Sz : Nat .
  vars I I' : InhList .
  var MS : MMtd .
  vars Lab Lab' : Label .
  var LS : Labels .
  var MM : MMsg .
  var G : Guard .
  var M : Mid .
  var Q : String .
  var MsgBody : Body .

ifdef({|MODELCHECK|},dnl
{|  op label : Oid Oid Mid DataList -> Label [ctor] .
    eq caller(label(O, O', M, DL)) = O . |}
,dnl
{| op label(_,_) : Oid Nat -> Label [ctor {|format|} (d d ! d d o d)] .
   eq caller(label(O, N)) = O . |})

eq
  < O : C | Att: S, Pr: (L, AL ::= EL ; SL),
	    PrQ: W, Lcnt: N >
  =
  < O : C | Att: S, Pr: (L,((AL assign evalList(EL, (S {|#|} L))); SL)), 
	    PrQ: W, Lcnt: N > .

STEP(dnl
{|< O : C | Att: S, Pr: (L,( (A , NeAL assign D # NeDL) ; SL)), PrQ: W,
    Lcnt: N >|},
{|if dom(A,S) then
    < O : C | Att: insert(A, D, S), Pr: (L, (NeAL assign NeDL) ; SL), PrQ: W,
      Lcnt: N > 
  else
    < O : C | Att: S, Pr: (insert(A, D, L), (NeAL assign NeDL) ; SL), PrQ: W,
      Lcnt: N > 
  fi|},
{|[label assign]|})

STEP(dnl
{|< O : C | Att: S, Pr: (L,( (A assign D) ; SL)), PrQ: W, Lcnt: N >|},
{|if dom(A,S) then
    < O : C | Att: insert(A, D, S), Pr: (L, SL), PrQ: W, Lcnt: N > 
  else
    < O : C | Att: S, Pr: (insert(A, D, L), SL), PrQ: W, Lcnt: N > 
  fi|},
{|[label assign]|})

STEP(dnl
{|< O : C | Att: S, Pr: (L, skip ; SL), PrQ: W, Lcnt: N >|},
{|< O : C | Att: S, Pr: (L, SL), PrQ: W, Lcnt: N >|},
{|[label skip]|})


*** if_then_else ***
STEP(dnl
{|< O : C | Att: S, Pr: (L, if E th SL' el SL'' fi ; SL), PrQ: W, Lcnt: N >|},
{|if {|eval|}(E, (S {|#|} L)) asBool then
    < O : C | Att: S, Pr: (L, SL' ; SL), PrQ: W, Lcnt: N >
  else
    < O : C | Att: S, Pr: (L, SL'' ; SL), PrQ: W, Lcnt: N >
  fi|},
{|[label if-th]|})

*** while ***
*** During model checking we want to be able to observe infinite loops.
*** Therefore, this has to be a rule.
rl
  < O : C | Att: S, Pr: (L, while E do SL1 od ; SL2), PrQ: W, Lcnt: N >
  =>
  < O : C | Att: S,
            Pr: (L, (if E th (SL1 ; while E do SL1 od) el skip fi); SL2),
            PrQ: W, Lcnt: N >
  [label while]
  .

*** OBJECT CREATION
***
*** Using synchronous calls does not work for the model checker.
*** Expanding "init" (emp ; noAid) needs a label value, which we do
*** not have.  We reserve a label for our purposes.
STEP(dnl
{|< O : C | Att: S,Pr: (L, (A ::= new C' (EL)); SL),PrQ: W, Lcnt: N > 
  < C' : Cl | Inh: I , Par: AL, Att: S' , Mtds: MS , Ocnt: F >|},
{|< O : C | Att: S, Pr: (L, (A assign newId(C', F)); SL), PrQ: W, Lcnt: N >
  < C' : Cl | Inh: I , Par: AL, Att: S' , Mtds: MS , Ocnt: (F + 1) >
  < newId(C',F) : C' | Att: S, Pr: idle, PrQ: noProc, Lcnt: 1 >
  < newId(C',F) : Qu | Size: 10, Dealloc: noDealloc, Ev: noMsg > *** XXX: Currently hard-coded.
  findAttr(newId(C',F), I, S', 
    (AL assign evalList(EL, (S {|#|} L))),
    ((noSubst, ("Dummy" ! "init" (emp)) ; ("Dummy" ?(noAid)) ; ("Dummy" ! "run" (emp)) ; ("Dummy" ?(noAid)))))|},
{|[label new-object]|})


*** ATTRIBUTE inheritance with multiple inheritance
*** CMC assumes that all attributes names are (globally) different

op findAttr  : Oid InhList Subst StmList Process -> Msg [ctor {|format|} (n d)] .
op foundAttr : Oid Subst  StmList Process -> Msg [ctor {|format|} (n d)] .

eq findAttr(O, noInh, S, SL, P) = foundAttr(O, S, SL, P) .

*** Good thing we cannot use class names as variables in (at least in
*** the source language.  The name of the class will be used as the
*** name of the variable used to call the init routine.
***
*** XXX: Why is the call prepended, shouldn't it be appended?
eq
  findAttr(O,((C < EL >) {|##|} I),S, SL, (L', SL')) 
  < C : Cl | Inh: I', Par: AL, Att: L, Mtds: MS, Ocnt: F >
  =
  findAttr(O, I {|#|}{|#|} I',(L {|#|} S), (AL ::= EL) ; SL, 
           (L', ("Dummy" ! "init" @ C(emp)) ; ("Dummy" ?( noAid)) ; SL'))
  < C : Cl | Inh: I', Par: AL, Att: L, Mtds: MS, Ocnt: F > .

eq
  foundAttr(O, S', SL, (L', SL'))
  < O : C | Att: S, Pr: idle, PrQ: W, Lcnt: N >
  =
  < O : C | Att: ("this" |-> O, S'), Pr: (L', SL ; SL'), PrQ: W, Lcnt: N >
  .





*** Non-deterministic choice ***
*** Choice is comm, so [nondet] considers both SL1 and SL2.
CSTEP(dnl
{|< O : C | Att: S, Pr: (L, (SL1 [] SL2); SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >|},
{|< O : C | Att: S, Pr: (L, (SL1 ; SL)), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >|},
{| ready(SL1, (S # L), MM)|},
{|[label nondet]|})




*** Merge ***
*** Merge is comm, so [merge] considers both SL1 and SL2.
crl
  < O : C | Att: S, Pr: (L, (SL1 ||| SL2); SL), PrQ: W, Lcnt: N >  
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  =>
  < O : C | Att: S, Pr: (L, (SL1 MERGER SL2); SL), PrQ: W, Lcnt: N >  
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  if ready(SL1,(S {|#|} L), MM)
  [label merge] .

rl
  < O : C | Att: S,  Pr:  (L, ((ST ; SL') MERGER SL2); SL), PrQ: W, Lcnt: N >   
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  =>
  if enabled(ST,(S {|#|} L), MM) then
    < O : C | Att: S, Pr: (L, ((ST ; (SL' MERGER SL2)); SL)), PrQ: W, Lcnt: N >   
  else
    < O : C | Att: S, Pr: (L, ((ST ; SL') ||| SL2); SL), PrQ: W, Lcnt: N >   
  fi
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  [label merge-aux] .

STEP(dnl
{|< O : C | Att: S, Pr: (L, (cont(Lab) MERGER SL'); SL''), 
            PrQ: (L', ((Lab ?(A)); SL)) ++ W, Lcnt: F >|},
{|< O : C | Att: S, Pr: (L',((((Lab ?(A)) ; SL) MERGER SL'); SL'')), 
            PrQ: W, Lcnt: F >|},
{|[label continue2]|})

*** local call 
ceq
  < O : C | Att: S,Pr: (L, ((Lab ?(AL)); SL)),PrQ: W ++ (L', SL'),Lcnt: F >
  = 
  < O : C | Att: S,Pr: (L', SL' ; cont(Lab)),PrQ: W ++ (L,((Lab ?(AL)); SL)),
            Lcnt: F > 
  if (L'["label"] == Lab)
  [label local-call] .

*** local call within merge
ceq
  < O : C | Att: S,Pr: (L,(((Lab ?(AL)); SL) MERGER SL'')),
	    PrQ: W ++ (L', SL'), Lcnt: F >
  = 
  < O : C | Att: S,Pr: (L', SL'),
	    PrQ: W ++ (L, (((await Lab ??) ; (Lab ?(AL)); SL) MERGER SL'')),
	    Lcnt: F > 
  if (L'["label"] == Lab)
  [label local-call-in-merge] .

*** Suspension ***

CSTEP(dnl
{|< O : C | Att: S, Pr: (L,SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >|},
{|< O : C | Att: S, Pr: idle, PrQ: W ++ (L, SL), Lcnt: N > *** clear(SL)
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >|},
{|not enabled(SL, (S # L), MM)|},
{|[label suspend]|})

*** Guards ***

CSTEP(dnl
{|< O : C | Att: S, Pr: (L, await G ; SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >|},
{|< O : C | Att: S, Pr: (L,SL) , PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM > |},
{|enabledGuard(G, (S # L), MM)|},
{|[label guard]|})

*** Evaluate guards in suspended processes ***

*** Must be a rule, also in the interpreter.
crl
  < O : C | Att: S, Pr: idle, PrQ: (L,SL) ++ W, Lcnt: N > 
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  => 
  < O : C | Att: S, Pr: (L,SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  if ready(SL, (S {|#|} L), MM) 
  [label PrQ-ready] .


eq
  < O : C | Att: S, Pr: idle, PrQ: (L, await wait ; SL) ++ W, Lcnt: N >  
  =
  < O : C | Att: S, Pr: idle, PrQ: (L, SL) ++ W, Lcnt: N > [label wait] .

eq
  < O : C | Att: S, Pr: idle, PrQ: (L, ((await wait ; SL)[] SL'); SL'')++ W,  
    Lcnt: N >  
  =
  < O : C | Att: S, Pr: idle, PrQ: (L, (SL [] SL'); SL'') ++ W, Lcnt: N >
[label wait-nondet] .

eq
  < O : C | Att: S, Pr: idle, PrQ: (L,((await wait ; SL)||| SL'); SL'')++ W,  
    Lcnt: N >  
  =
  < O : C | Att: S, Pr: idle, PrQ: (L, (SL ||| SL'); SL'') ++ W, Lcnt: N >
  [label wait-merge] .





*** Optimization to avoid muiltiple lookups in the message queue for
*** the same guard
eq 
  < O : C | Att: S, Pr: P, PrQ: (L, await (Lab ?? & G); SL) ++ W, Lcnt: F > 
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM + comp(Lab, DL) >  
  =
  < O : C | Att: S,  Pr: P, PrQ: (L, await G ; SL) ++ W, Lcnt: F >    
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM + comp(Lab, DL) > .


***
*** Tail calls.
***
*** Fake the caller and the label and tag the label.  Since we do not
*** want to interleave, this can also be an equation.
STEP({|< O : C | Att: S, Pr: (L, tailcall M(EL) ; SL), PrQ: W, Lcnt: N >|},
{|< O : C | Att: S, Pr: (noSubst, accept(tag(L["label"]))), PrQ: W, Lcnt: N >
 bindMtd(O, O, tag(L["label"]), M, evalList(EL, (S # L)), C < emp >)
|},
{|[label tailcall]|})

*** If we receive the method body, the call is accepted and the label untagged.
crl
  < O : C | Att: S, Pr: (noSubst, accept(Lab)), PrQ: (L, SL) ++ W,
         Lcnt: N >
  =>
  < O : C | Att: S, Pr: (insert("label", tag(Lab), L), SL), PrQ: W, Lcnt: N >
  if L["label"] = Lab
  [label tailcall-accept]
  .





*** METHOD CALLS ***

*** receive invocation message ***
STEP({|< O : C | Att: S, Pr: P, PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM + invoc(O', Lab, Q, DL) >|},
{|< O : C | Att: S, Pr: P, PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
	 bindMtd(O, O', Lab, Q, DL, C < emp >)|},
{|[label receive-call-req]|})

*** Method binding with multiple inheritance
eq
  bindMtd(O, O', Lab, "run", EL, noInh)
  = 
  boundMtd(O,(("caller" |-> O', "label" |-> Lab), return(emp)))
  .


eq
  bindMtd(O, O', Lab, M, EL, (C < EL' >) {|#|}{|#|} I')
  < C : Cl | Inh: I , Par: AL, Att: S , Mtds: MS , Ocnt: F >
  =
  if (M in MS) then
    boundMtd(O,get(M,MS,O', Lab, EL)) 
  else
    bindMtd(O,O',Lab,M,EL, I {|##|} I')
  fi 
  < C : Cl | Inh: I , Par: AL, Att: S , Mtds: MS , Ocnt: F >
  .

STEP({|< O : Qu | Size: Sz, Dealloc: LS, Ev: MM + invoc(O', Lab, Q @ C, DL) >|},
{|< O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
    bindMtd(O, O', Lab, Q, DL, C < emp >)|},
{|[label receive-call-req]|})

STEP({|boundMtd(O, P') < O : C | Att: S, Pr: P, PrQ: W, Lcnt: N >|},
{|< O : C | Att: S, Pr: P, PrQ: W ++ P', Lcnt: N >|},
{|[label receive-call-bound]|})

rl
  < O : C | Att: S, Pr: (L, cont(Lab); SL), PrQ: (L',((Lab)?(AL); SL')) ++
    W, Lcnt: F >
  =>
  < O : C | Att: S, Pr: (L',(Lab)?(AL); SL'), PrQ: W, Lcnt: F >
  [label continue]
  .


ifdef({|MODELCHECK|},
{|***(
    The size of the queue is limited in the model checker, and we will
    therefore check whether there is room for the message in the queue,
    before sending.
  )***
  ceq
  < O : C | Att: S, Pr: (L, (A ! Q(EL)); SL), PrQ: W, Lcnt: F >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  =
  < O : C | Att: S, Pr: (insert(A, label(O, O, Q, evalList(EL, (S # L))), L), SL), PrQ: W, Lcnt: F >
  *** XXX: QUEUE
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM +
    invoc(O, label(O, O, Q, evalList(EL, (S # L))), Q, evalList(EL, (S # L))) >
  if size(MM) < Sz
|},dnl
{|rl
  < O : C | Att: S, Pr: (L, (A ! Q(EL)); SL), PrQ: W, Lcnt: N >
  =>
  < O : C | Att: S, Pr: (insert(A, label(O, N), L), SL), PrQ: W, Lcnt: N + 1 >
  invoc(O, label(O, N), Q, evalList(EL, (S # L))) from O to O
|})dnl
  [label local-async-reply]
  .

ifdef({|MODELCHECK|},dnl
{|eq
  < O : C | Att: S, Pr: (L, ( A ! Q @ C'(EL)); SL),PrQ: W, Lcnt: N >
  =
  < O : C | Att: S, Pr: (insert(A, label(O, O, Q, evalList(EL, (S # L))), L), SL), PrQ: W, Lcnt: N >
  invoc(O, label(O,O,Q @ C', evalList(EL, (S # L))), Q @ C',
        evalList(EL, (S # L))) from O to O
|},dnl
{|rl
  < O : C | Att: S, Pr: (L, ( A ! Q @ C'(EL)); SL), PrQ: W, Lcnt: N >
  =>
  < O : C | Att: S, Pr: (insert (A, label(O, N), L), SL), PrQ: W,
    Lcnt: (N + 1) >
  invoc(O, label(O, N), Q @ C', evalList(EL, (S # L))) from O to O
|})dnl
  [label local-async-qualified-req]
  .

ifdef({|MODELCHECK|},
{|eq
  < O : C | Att: S, Pr: (L, (A ! E . Q(EL)); SL), PrQ: W, Lcnt: N >
  =
  < O : C | Att: S, Pr: (insert(A, label(O, {|eval|}(E, (S # L)), Q, evalList(EL, (S # L))), L), SL), PrQ: W, Lcnt: N >
  invoc(O, label(O, {|eval|}(E, (S # L)), Q, evalList(EL, (S # L))), Q, evalList(EL, (S # L)))
    from O to {|eval|}(E, (S # L))
|},dnl
{|rl
  < O : C | Att: S, Pr: (L, (A ! E . Q(EL)); SL), PrQ: W, Lcnt: N >
  =>
  < O : C | Att: S, Pr: (insert(A, label(O, N), L), SL), PrQ: W, Lcnt: N + 1 >
  invoc(O, label(O, N), Q , evalList(EL, (S # L))) from O to eval(E, (S # L))
|})dnl
  [label remote-async-reply]
  .

*** Reduce sync. call  to async. call with reply 
*** XXX: This rule will eventually go away once the compiler does this
*** expansion.
eq < O : C | Att: S, Pr: (L, (M(EL ; AL)); SL), PrQ: W, Lcnt: N >
  =
ifdef({|MODELCHECK|},dnl
{|  < O : C | Att: S, Pr: (L, ("Dummy" ! M(EL)); ("Dummy" ?(AL)); SL), PrQ: W,  Lcnt: N >|},
{|  < O : C | Att: S, Pr: (L, ("Dummy" ! M(EL)); ("Dummy" ?(AL)); SL), PrQ: W,  Lcnt: N >|})
  .

*** emit reply message ***
STEP({|< O : C |  Att: S, Pr: (L, (return(EL)); SL), PrQ: W, Lcnt: N >|},
{|< O : C |  Att: S, Pr: (L, SL), PrQ: W, Lcnt: N >
  comp(L["label"], evalList(EL, (S # L))) from O to caller(L["label"])|},
{|[label return]|})

*** Optimization: reduce label to value only once
eq
  < O : C |  Att: S, Pr: (L, (A ?(AL)); SL), PrQ: W, Lcnt: N > 
  =
  < O : C |  Att: S, Pr: (L, ((L[A]) ?(AL)); SL), PrQ: W, Lcnt: N > .


*** Model checker behaves differently from interpreter in that receiving
*** and freeing of label variables will set the variable containing this
*** name to null.  This will save us some states.  In the model checker
*** it is /guaranteed/ that exactly one variable exists, which holds the
*** label value,
eq
  < O : C |  Att: S,
    Pr: ((ifdef({|MODELCHECK|}, {|A |-> Lab, L|}, L)),
         (Lab ? (AL)); SL), PrQ: W, Lcnt: F > 
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM + comp(Lab, DL) >
  = 
  < O : C |  Att: S,
    Pr: ((ifdef({|MODELCHECKER|}, {|A |-> null, L|}, L)),
         (AL assign DL); SL), PrQ: W, Lcnt: F > 
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  .

*** Transport rule: include new message in queue
STEP({|< O : Qu | Size: Sz, Dealloc: LS, Ev: MM > (MsgBody from O' to O)|},
  {|< O : Qu | Size: Sz, Dealloc: LS, Ev: MM + MsgBody >|},
  {|[label invoc-msg]|})

*** Free a label.
STEP({|< O : C | Att: S, Pr: (L, free(A) ; SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >|},
  {|< O : C | Att: S, Pr: (L,SL), PrQ: W, Lcnt: N > 
  < O : Qu | Size: Sz, Dealloc: ({|eval|}(A, (S # L)) ^ LS), Ev: MM >|},
  {|[label free]|})

*** Deallocate
eq
  < O : Qu | Size: Sz, Dealloc: (Lab ^ LS), Ev: comp(Lab , DL) + MM >
  =
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  [label deallocate] .

*** Bury a variable

eq
  < O : C | Att: S, Pr: ((L, (A |-> D)), bury(A) ; SL), PrQ: W, Lcnt: N > =
  < O : C | Att: S, Pr: (L, SL), PrQ: W, Lcnt: N >
  .

eq
  < O : C | Att: S, Pr: ((L, (A |-> D)), bury(A , NeAL) ; SL), PrQ: W,
    Lcnt: N > =
  < O : C | Att: S, Pr: (L, bury(NeAL) ; SL), PrQ: W, Lcnt: N >
  .

endm

ifdef({|MODELCHECK|},{|dnl
*** The predicates we can define on configurations.
mod CREOL-PREDICATES is
  protecting CREOL-MODEL-CHECKER .
  including SATISFACTION .
  including MODEL-CHECKER .
  subsort Configuration < State .
  ops objcnt maxobjcnt minobjcnt : Cid Nat -> Prop .
  op hasvalue : Oid Aid Data -> Prop .
  var A : Aid .
  var D : Data .
  var C : Cid .
  var O : Oid .
  vars S S' L L' : Subst .
  var P : Process .
  var Q : MProc .
  vars N N' : Nat .
  var c : Configuration .

  eq c < C : Cl | Inh: I:InhList, Par: AL:AidList, Att: S, Mtds: M:MMtd, Ocnt: N > |= objcnt(C, N') = N == N' .
  eq c < C : Cl | Inh: I:InhList, Par: AL:AidList, Att: S, Mtds: M:MMtd, Ocnt: N > |= maxobjcnt(C, N') = N <= N' .
  eq c < C : Cl | Inh: I:InhList, Par: AL:AidList, Att: S, Mtds: M:MMtd, Ocnt: N > |= minobjcnt(C, N') = N >= N' .
  eq c < O : C | Att: S, Pr: P, PrQ: Q, Lcnt: N > c |= hasvalue(O, A, D) = D == S[A] .

endm
|})dnl

eof
